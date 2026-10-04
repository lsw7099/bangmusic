// 다운로드 상태 기계 (03장 §5.3~5.5, §5.7, §5.9). Flutter·플랫폼에 의존하지 않는 순수 Dart.
// (행, 사건) → (새 행, 효과 목록). 파일·네트워크·DB 작업은 효과로만 나타나고 DownloadEngine이 실행한다.
// 쓰기 순서 규칙(§5.9): 파일을 최종 위치로 옮긴 뒤에 completed를 저장하고, 행을 지운 뒤에 파일을 지운다.
// → 효과마다 저장 전(before)/저장 후(after)를 정해 둔다.

enum DlState {
  queued,
  resolving,
  preparing,
  downloading,
  paused,
  waitingNetwork,
  waitingWifi,
  waitingSpace,
  waitingLogin,
  verifying,
  completed,
  failed;

  /// DB 저장값 (03장 §5.2 snake_case)
  String get wire => switch (this) {
        waitingNetwork => 'waiting_network',
        waitingWifi => 'waiting_wifi',
        waitingSpace => 'waiting_space',
        waitingLogin => 'waiting_login',
        _ => name,
      };
  static DlState parse(String s) => values.firstWhere((v) => v.wire == s);

  /// 엔진이 지금 일을 하고 있는 상태 (동시 다운로드 수에 센다)
  bool get active => this == resolving || this == preparing || this == downloading || this == verifying;
  bool get waiting => this == waitingNetwork || this == waitingWifi || this == waitingSpace || this == waitingLogin;
}

/// 검증 수준 (§5.5): 서버가 해시를 끝내 주지 않으면 크기만
enum Verified { full, sizeOnly }

/// 자동 재시도 간격 (§5.4): 5회째 실패하면 failed
const retryBackoff = [Duration(seconds: 5), Duration(seconds: 30), Duration(minutes: 2), Duration(minutes: 10)];
const maxAttempts = 5;

/// 항상 남겨 두는 기기 여유 공간 (§5.7)
const reserveBytes = 500 * 1024 * 1024;

class Download {
  const Download({
    required this.id,
    required this.trackId,
    required this.quality,
    this.state = DlState.queued,
    this.renditionId,
    this.mediaVersion,
    this.bytesTotal,
    this.bytesDone = 0,
    this.sha256,
    this.etag,
    this.ext,
    this.errorCode,
    this.attempts = 0,
    this.integrityRetried = false,
    this.notBefore,
    this.stale = false,
    this.locked = false,
    this.verified,
    this.fileName,
  });

  final String id;
  final String trackId;

  /// 요청한 음질 (`original`, `aac_256` …) — 03장 §5.2의 profile
  final String quality;
  final DlState state;
  final String? renditionId;
  final String? mediaVersion;
  final int? bytesTotal;
  final int bytesDone;

  /// 서버가 준 SHA-256. 아직 계산 전이면 null (§5.5)
  final String? sha256;
  final String? etag;

  /// 저장 확장자 (렌디션 컨테이너)
  final String? ext;

  /// failed의 사유, 또는 재시도 대기 중인 직전 실패 사유
  final String? errorCode;
  final int attempts;
  final bool integrityRetried;

  /// 자동 재시도 대기: 이 시각 전에는 시작하지 않는다
  final DateTime? notBefore;

  /// 완료본이 서버의 새 버전보다 옛것 (§5.4)
  final bool stale;

  /// 접근 취소·로그아웃 보관 (§5.8): 재생·진행 불가
  final bool locked;
  final Verified? verified;

  /// 완료본의 media/ 아래 상대 경로
  final String? fileName;

  static const _keep = Object();

  Download copyWith({
    DlState? state,
    Object? renditionId = _keep,
    Object? mediaVersion = _keep,
    Object? bytesTotal = _keep,
    int? bytesDone,
    Object? sha256 = _keep,
    Object? etag = _keep,
    Object? ext = _keep,
    Object? errorCode = _keep,
    int? attempts,
    bool? integrityRetried,
    Object? notBefore = _keep,
    bool? stale,
    bool? locked,
    Object? verified = _keep,
    Object? fileName = _keep,
  }) =>
      Download(
        id: id,
        trackId: trackId,
        quality: quality,
        state: state ?? this.state,
        renditionId: renditionId == _keep ? this.renditionId : renditionId as String?,
        mediaVersion: mediaVersion == _keep ? this.mediaVersion : mediaVersion as String?,
        bytesTotal: bytesTotal == _keep ? this.bytesTotal : bytesTotal as int?,
        bytesDone: bytesDone ?? this.bytesDone,
        sha256: sha256 == _keep ? this.sha256 : sha256 as String?,
        etag: etag == _keep ? this.etag : etag as String?,
        ext: ext == _keep ? this.ext : ext as String?,
        errorCode: errorCode == _keep ? this.errorCode : errorCode as String?,
        attempts: attempts ?? this.attempts,
        integrityRetried: integrityRetried ?? this.integrityRetried,
        notBefore: notBefore == _keep ? this.notBefore : notBefore as DateTime?,
        stale: stale ?? this.stale,
        locked: locked ?? this.locked,
        verified: verified == _keep ? this.verified : verified as Verified?,
        fileName: fileName == _keep ? this.fileName : fileName as String?,
      );

  /// 재생 대상인가 (§5.1, §5.5): DB의 completed 행만, 잠기지 않은 것만
  bool get playable => state == DlState.completed && !locked && fileName != null;

  @override
  String toString() => 'Download($trackId, ${state.wire}, $bytesDone/$bytesTotal, err=$errorCode, try=$attempts)';
}

/// 완료본의 media/ 아래 상대 경로 (03장 §5.2: `media/<track_id>/<rendition_id>.<ext>`)
String mediaPath(Download d) => '${d.trackId}/${d.renditionId}.${d.ext ?? 'bin'}';

// ── 사건 ─────────────────────────────────────────────────────────

sealed class DlEvent {
  const DlEvent();
}

/// 엔진이 이 항목을 시작한다 (조건 확인은 [conditionFor]가 먼저)
class Start extends DlEvent {
  const Start();
}

/// 시작 조건이 맞지 않는다: waiting_network / waiting_wifi / waiting_space
class Blocked extends DlEvent {
  const Blocked(this.waitState);
  final DlState waitState;
}

/// 조건이 풀렸다 (연결 복귀, Wi-Fi, 공간 확보, 재로그인)
class Unblocked extends DlEvent {
  const Unblocked(this.waitState);
  final DlState waitState;
}

/// 렌디션 결정·조회 결과
class Resolved extends DlEvent {
  const Resolved({required this.renditionId, required this.mediaVersion, required this.ready, this.sizeBytes, this.sha256, this.etag, this.ext, this.retryAfter});
  final String renditionId;
  final String mediaVersion;
  final bool ready;
  final int? sizeBytes;
  final String? sha256;
  final String? etag;
  final String? ext;
  final Duration? retryAfter;
}

class Progress extends DlEvent {
  const Progress(this.bytesDone);
  final int bytesDone;
}

/// 전송이 끝났다 (.part 크기)
class TransferDone extends DlEvent {
  const TransferDone(this.partSize);
  final int partSize;
}

/// 서버가 Range를 무시하고 200을 줬다 (§5.4): 부분 파일을 버리고 처음부터
class RangeIgnored extends DlEvent {
  const RangeIgnored();
}

/// 검증 결과 (§5.5). sha256Actual은 계산한 값, serverSha256은 다시 조회한 서버 해시(처음에 null이었던 경우)
class VerifyResult extends DlEvent {
  const VerifyResult({required this.size, required this.sha256Actual, this.serverSha256});
  final int size;
  final String sha256Actual;
  final String? serverSha256;
}

/// 최종 위치로 옮기기 성공 (저장 전 효과의 결과)
class Moved extends DlEvent {
  const Moved(this.fileName);
  final String fileName;
}

/// 실패. code는 서버 오류 코드 또는 앱 코드(network, server_busy, disk_full …)
class Failed extends DlEvent {
  const Failed(this.code, {this.retryAfter});
  final String code;
  final Duration? retryAfter;
}

class UserPause extends DlEvent {
  const UserPause();
}

class UserResume extends DlEvent {
  const UserResume();
}

/// 실패 항목 재시도, 또는 stale 완료본 "새 버전 받기"
class UserRetry extends DlEvent {
  const UserRetry();
}

class UserCancel extends DlEvent {
  const UserCancel();
}

/// 동기화에서 본 서버의 현재 media_version (§5.4 완료본 버전 교체)
class ServerVersion extends DlEvent {
  const ServerVersion(this.mediaVersion);
  final String mediaVersion;
}

/// 세션 만료 (§5.8)
class SessionExpired extends DlEvent {
  const SessionExpired();
}

/// 접근 취소 또는 로그아웃 "보관" (§5.8)
class Lock extends DlEvent {
  const Lock();
}

/// 같은 사용자로 다시 로그인 (§5.8)
class Unlock extends DlEvent {
  const Unlock();
}

// ── 효과 ─────────────────────────────────────────────────────────

sealed class Effect {
  const Effect();
}

/// POST /tracks/{id}/renditions (purpose=download)
class ResolveRendition extends Effect {
  const ResolveRendition();
}

/// 렌디션 상태를 after 뒤에 다시 조회 (202 preparing)
class PollRendition extends Effect {
  const PollRendition(this.after);
  final Duration after;
}

/// .part에 from 바이트부터 이어받기 (Range + If-Range)
class StartTransfer extends Effect {
  const StartTransfer(this.fromByte);
  final int fromByte;
}

class CancelTransfer extends Effect {
  const CancelTransfer();
}

/// 크기·해시 계산 (UI 스레드 밖). 서버 해시가 없었으면 다시 조회해 같이 돌려준다
class VerifyPart extends Effect {
  const VerifyPart({required this.refetchSha});
  final bool refetchSha;
}

/// 저장 전: `.part` → `media/<track>/<rendition>.<ext>` (같은 파일시스템 rename)
class MoveToMedia extends Effect {
  const MoveToMedia();
}

/// 저장 후: 부분 파일 삭제
class DeletePart extends Effect {
  const DeletePart();
}

/// 저장 후: 완료본 삭제
class DeleteMedia extends Effect {
  const DeleteMedia(this.fileName);
  final String fileName;
}

/// 저장 시 행을 지운다 (사용자 취소)
class RemoveRow extends Effect {
  const RemoveRow();
}

/// 이 시각에 다시 깨워 달라 (자동 재시도)
class WakeAt extends Effect {
  const WakeAt(this.at);
  final DateTime at;
}

/// 새 버전 받기를 별도 다운로드로 시작 (§5.4 2단계 — 엔진이 같은 곡의 새 행을 만든다)
class FetchNewVersion extends Effect {
  const FetchNewVersion();
}

class Step {
  const Step(this.next, [this.effects = const []]);

  /// null이면 행 삭제
  final Download? next;
  final List<Effect> effects;

  @override
  String toString() => 'Step($next, $effects)';
}

// ── 전이 ─────────────────────────────────────────────────────────

/// 재시도할 수 없는 서버 오류 (§5.4, 02장 오류 코드)
const _fatal = {'media_missing', 'unsupported_source', 'transcode_failed', 'no_playable_format', 'not_found', 'forbidden'};

/// 사건 하나를 적용한다. 받을 수 없는 사건은 아무것도 바꾸지 않는다(Step(d)).
Step apply(Download d, DlEvent e, DateTime now) {
  // 잠긴 행은 잠금 해제·취소만 받는다
  if (d.locked && e is! Unlock && e is! UserCancel) return Step(d);
  switch (e) {
    case Start():
      if (d.state != DlState.queued) return Step(d);
      if (d.notBefore != null && now.isBefore(d.notBefore!)) return Step(d);
      return Step(d.copyWith(state: DlState.resolving, notBefore: null), const [ResolveRendition()]);

    case Blocked(:final waitState):
      if (d.state == DlState.completed || d.state == DlState.failed || d.state == DlState.paused || d.state == DlState.verifying) return Step(d);
      final cancel = d.state == DlState.downloading ? const [CancelTransfer()] : const <Effect>[];
      return Step(d.copyWith(state: waitState), cancel);

    case Unblocked(:final waitState):
      if (d.state != waitState) return Step(d);
      // 연결 복귀 이벤트는 즉시 재개 (§5.4): 재시도 대기를 지운다
      return Step(d.copyWith(state: DlState.queued, notBefore: null));

    case Resolved():
      if (d.state != DlState.resolving && d.state != DlState.preparing) return Step(d);
      // 다른 렌디션·버전이면 이어 붙이지 않는다 (§5.4: 옛 바이트에 새 바이트를 잇는 경로는 없다)
      final changed = d.renditionId != null && (d.renditionId != e.renditionId || d.mediaVersion != e.mediaVersion);
      final base = d.copyWith(
        renditionId: e.renditionId, mediaVersion: e.mediaVersion, bytesTotal: e.sizeBytes,
        sha256: e.sha256, etag: e.etag, ext: e.ext, bytesDone: changed ? 0 : d.bytesDone,
      );
      if (!e.ready) return Step(base.copyWith(state: DlState.preparing), [if (changed) const DeletePart(), PollRendition(e.retryAfter ?? const Duration(seconds: 2))]);
      return Step(base.copyWith(state: DlState.downloading), [if (changed) const DeletePart(), StartTransfer(changed ? 0 : d.bytesDone)]);

    case Progress(:final bytesDone):
      if (d.state != DlState.downloading) return Step(d);
      return Step(d.copyWith(bytesDone: bytesDone));

    case TransferDone(:final partSize):
      if (d.state != DlState.downloading) return Step(d);
      return Step(d.copyWith(state: DlState.verifying, bytesDone: partSize), [VerifyPart(refetchSha: d.sha256 == null)]);

    case RangeIgnored():
      if (d.state != DlState.downloading) return Step(d);
      return Step(d.copyWith(bytesDone: 0), const [DeletePart(), StartTransfer(0)]);

    case VerifyResult():
      if (d.state != DlState.verifying) return Step(d);
      final expected = d.sha256 ?? e.serverSha256;
      final sizeOk = d.bytesTotal == null || e.size == d.bytesTotal;
      final hashOk = expected == null || expected.toLowerCase() == e.sha256Actual.toLowerCase();
      if (sizeOk && hashOk) {
        return Step(d.copyWith(sha256: expected, verified: expected == null ? Verified.sizeOnly : Verified.full), const [MoveToMedia()]);
      }
      // 불일치: 처음부터 1회 재시도, 다시 불일치면 failed(integrity_mismatch) (§5.5)
      if (!d.integrityRetried) {
        return Step(d.copyWith(state: DlState.queued, bytesDone: 0, integrityRetried: true, errorCode: 'integrity_mismatch'), const [DeletePart()]);
      }
      return Step(d.copyWith(state: DlState.failed, bytesDone: 0, errorCode: 'integrity_mismatch'), const [DeletePart()]);

    case Moved(:final fileName):
      if (d.state != DlState.verifying) return Step(d);
      return Step(d.copyWith(state: DlState.completed, fileName: fileName, bytesDone: d.bytesTotal ?? d.bytesDone, errorCode: null, attempts: 0, notBefore: null, stale: false));

    case Failed(:final code, :final retryAfter):
      return _failed(d, code, retryAfter, now);

    case UserPause():
      if (d.state == DlState.completed || d.state == DlState.failed || d.state == DlState.paused || d.state == DlState.verifying) return Step(d);
      return Step(d.copyWith(state: DlState.paused), [if (d.state == DlState.downloading) const CancelTransfer()]);

    case UserResume():
      if (d.state != DlState.paused) return Step(d);
      return Step(d.copyWith(state: DlState.queued, notBefore: null));

    case UserRetry():
      if (d.state == DlState.failed) return Step(d.copyWith(state: DlState.queued, attempts: 0, integrityRetried: false, notBefore: null, errorCode: null));
      if (d.state == DlState.completed && d.stale) return Step(d, const [FetchNewVersion()]);
      return Step(d);

    case UserCancel():
      return Step(null, [
        if (d.state == DlState.downloading) const CancelTransfer(),
        const RemoveRow(),
        const DeletePart(),
        if (d.fileName != null) DeleteMedia(d.fileName!),
      ]);

    case ServerVersion(:final mediaVersion):
      if (d.mediaVersion == null || d.mediaVersion == mediaVersion) return Step(d);
      // 완료본은 계속 재생 가능, "업데이트 있음" (§5.4)
      if (d.state == DlState.completed) return Step(d.copyWith(stale: true));
      // 진행 중이면 옛 바이트를 버리고 다시 결정
      if (d.state == DlState.failed) return Step(d);
      return Step(d.copyWith(state: DlState.queued, bytesDone: 0, renditionId: null, mediaVersion: null, notBefore: null),
          [if (d.state == DlState.downloading) const CancelTransfer(), const DeletePart()]);

    case SessionExpired():
      if (d.state == DlState.completed || d.state == DlState.failed || d.state == DlState.paused) return Step(d);
      return Step(d.copyWith(state: DlState.waitingLogin), [if (d.state == DlState.downloading) const CancelTransfer()]);

    case Lock():
      if (d.locked) return Step(d);
      final stop = d.state == DlState.downloading;
      final next = d.state == DlState.completed || d.state == DlState.failed || d.state == DlState.paused ? d.state : DlState.queued;
      return Step(d.copyWith(locked: true, state: next), [if (stop) const CancelTransfer()]);

    case Unlock():
      final s = d.state == DlState.waitingLogin ? DlState.queued : d.state;
      return Step(d.copyWith(locked: false, state: s));
  }
}

Step _failed(Download d, String code, Duration? retryAfter, DateTime now) {
  if (d.state == DlState.completed || d.state == DlState.failed || d.state == DlState.paused || d.state.waiting) return Step(d);
  final stop = [if (d.state == DlState.downloading) const CancelTransfer()];
  switch (code) {
    // 원본이 바뀌어 옛 렌디션이 무효 (§5.4): 부분 파일을 버리고 다시 결정
    case 'rendition_superseded':
      return Step(d.copyWith(state: DlState.resolving, bytesDone: 0, renditionId: null, mediaVersion: null), [...stop, const DeletePart(), const ResolveRendition()]);
    // 티켓 만료 (§5.4): 새 URL로 같은 오프셋에서
    case 'ticket_expired':
      return Step(d.copyWith(state: DlState.resolving), [...stop, const ResolveRendition()]);
    case 'disk_full':
      return Step(d.copyWith(state: DlState.waitingSpace), stop); // .part 유지 (§5.7)
    case 'offline':
      return Step(d.copyWith(state: DlState.waitingNetwork), stop);
    case 'refresh_expired':
      return Step(d.copyWith(state: DlState.waitingLogin), stop);
  }
  if (_fatal.contains(code)) return Step(d.copyWith(state: DlState.failed, errorCode: code), stop);
  // 네트워크·5xx·서버 바쁨: 백오프 후 재시도, 5회째면 failed
  final attempts = d.attempts + 1;
  if (attempts >= maxAttempts) return Step(d.copyWith(state: DlState.failed, errorCode: code, attempts: attempts), stop);
  var wait = retryBackoff[attempts - 1];
  if (retryAfter != null && retryAfter > wait) wait = retryAfter;
  final at = now.add(wait);
  return Step(d.copyWith(state: DlState.queued, errorCode: code, attempts: attempts, notBefore: at), [...stop, WakeAt(at)]);
}

// ── 시작 조건 (§5.7, §5.10) ──────────────────────────────────────

/// 시작해도 되면 null, 아니면 기다릴 상태
DlState? conditionFor({
  required bool online,
  required bool onWifi,
  required bool wifiOnly,
  required int? freeBytes,
  required int? sizeBytes,
  required int usedBytes,
  required int? limitBytes,
}) {
  if (!online) return DlState.waitingNetwork;
  if (wifiOnly && !onWifi) return DlState.waitingWifi;
  final size = sizeBytes ?? 0; // 크기를 모르면(결정 전) 여유 공간 기준만
  if (freeBytes != null && freeBytes - size < reserveBytes) return DlState.waitingSpace;
  if (limitBytes != null && usedBytes + size > limitBytes) return DlState.waitingSpace;
  return null;
}

// ── 앱 재시작 대조 (§5.9) ────────────────────────────────────────

/// 행 하나의 대조. partSize/mediaSize는 실제 파일 크기(없으면 null).
/// engineRunning: 백그라운드 엔진에 이 항목의 전송 작업이 살아 있음, engineDone: 엔진이 전송을 끝냈다고 알림.
Step reconcile(Download d, {required int? partSize, required int? mediaSize, required bool engineRunning, required bool engineDone}) {
  switch (d.state) {
    case DlState.downloading:
      if (engineDone && partSize != null) return Step(d.copyWith(state: DlState.verifying, bytesDone: partSize), [VerifyPart(refetchSha: d.sha256 == null)]);
      if (engineRunning) return Step(d);
      // 작업이 사라졌다: .part 크기에서 이어받는다. .part가 없으면(백그라운드 패키지는 자기 임시 파일에 받는다)
      // 기록된 위치를 넘겨 패키지의 이어받기 정보를 쓰게 한다 — 이을 수 없으면 전송 쪽이 처음부터 시작한다
      final from = partSize ?? d.bytesDone;
      return Step(d.copyWith(bytesDone: from), [StartTransfer(from)]);
    case DlState.verifying:
      if (partSize == null) {
        // 옮긴 뒤 completed를 저장하기 전에 죽었다: 완료본이 있으면 다시 검증할 필요 없이 완료
        if (mediaSize != null && (d.bytesTotal == null || mediaSize == d.bytesTotal)) {
          return Step(d.copyWith(state: DlState.completed, fileName: mediaPath(d), errorCode: null, attempts: 0));
        }
        return Step(d.copyWith(state: DlState.queued, bytesDone: 0));
      }
      return Step(d, [VerifyPart(refetchSha: d.sha256 == null)]); // 멱등
    case DlState.completed:
      if (mediaSize == null || (d.bytesTotal != null && mediaSize != d.bytesTotal)) {
        // 파일 없음·크기 다름: 사유를 남기고 다시 받는다 (03장 §5.3 P4 결정)
        return Step(d.copyWith(state: DlState.queued, bytesDone: 0, fileName: null, errorCode: 'file_missing', stale: false),
            [if (mediaSize != null) DeleteMedia(d.fileName ?? '')]);
      }
      return Step(d);
    case DlState.resolving:
    case DlState.preparing:
      return Step(d.copyWith(state: DlState.queued)); // 렌디션 결정부터 (멱등 API)
    default:
      return Step(d);
  }
}

/// 디스크에 있지만 DB에 없는 파일 (§5.9): 지울 목록
({List<String> parts, List<String> media}) orphans({required Iterable<Download> rows, required Iterable<String> partIds, required Iterable<String> mediaFiles}) {
  final ids = {for (final r in rows) r.id};
  final files = {for (final r in rows) if (r.fileName != null) r.fileName!};
  // 검증 중에 옮겨진 파일(행은 verifying, 파일은 media/)은 대조가 완료로 바꾸므로 지우지 않는다
  final expected = {for (final r in rows) if (r.renditionId != null) mediaPath(r)};
  return (
    parts: [for (final p in partIds) if (!ids.contains(p)) p],
    media: [for (final m in mediaFiles) if (!files.contains(m) && !expected.contains(m)) m],
  );
}
