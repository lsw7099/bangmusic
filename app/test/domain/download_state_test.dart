// 다운로드 상태 기계 (03장 §5.3~5.5, §5.7, §5.9) — P4 수용 기준 "모든 전이, 재시작 대조표" (L0)
import 'package:bangmusic/domain/download_state.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime.utc(2026, 10, 3, 12);

Download dl({DlState state = DlState.queued, int done = 0, int? total = 1000, String? sha = 'ab', String? rid = 'ren_1', String? mv = 'mv1', String? file, bool locked = false, bool stale = false, int attempts = 0, bool integrityRetried = false, DateTime? notBefore}) =>
    Download(
      id: 'dl_1', trackId: 'trk_1', quality: 'original', state: state, bytesDone: done, bytesTotal: total, sha256: sha,
      renditionId: rid, mediaVersion: mv, ext: 'flac', fileName: file, locked: locked, stale: stale, attempts: attempts,
      integrityRetried: integrityRetried, notBefore: notBefore,
    );

Resolved resolved({bool ready = true, String rid = 'ren_1', String mv = 'mv1', int size = 1000, String? sha = 'ab'}) =>
    Resolved(renditionId: rid, mediaVersion: mv, ready: ready, sizeBytes: size, sha256: sha, etag: '"e"', ext: 'flac');

Step run(Download d, DlEvent e) => apply(d, e, now);

void main() {
  group('정상 경로 queued → resolving → (preparing) → downloading → verifying → completed', () {
    test('시작하면 렌디션 결정', () {
      final s = run(dl(rid: null, mv: null), const Start());
      expect(s.next!.state, DlState.resolving);
      expect(s.effects, [isA<ResolveRendition>()]);
    });

    test('준비 중(202)이면 preparing + 다시 조회, 준비되면 downloading', () {
      final p = run(dl(state: DlState.resolving, rid: null, mv: null), Resolved(renditionId: 'ren_1', mediaVersion: 'mv1', ready: false, retryAfter: const Duration(seconds: 5)));
      expect(p.next!.state, DlState.preparing);
      expect((p.effects.single as PollRendition).after, const Duration(seconds: 5));
      final r = run(p.next!, resolved());
      expect(r.next!.state, DlState.downloading);
      expect((r.effects.single as StartTransfer).fromByte, 0);
      expect(r.next!.sha256, 'ab');
      expect(r.next!.bytesTotal, 1000);
    });

    test('진행률, 전송 끝 → 검증', () {
      final d = run(dl(state: DlState.downloading), const Progress(400)).next!;
      expect(d.bytesDone, 400);
      final v = run(d, const TransferDone(1000));
      expect(v.next!.state, DlState.verifying);
      expect((v.effects.single as VerifyPart).refetchSha, false);
    });

    test('검증 통과 → 저장 전 이동, 이동 후 completed (§5.9 쓰기 순서)', () {
      final v = run(dl(state: DlState.verifying, done: 1000), const VerifyResult(size: 1000, sha256Actual: 'AB'));
      expect(v.next!.state, DlState.verifying, reason: '옮기기 전에는 completed가 아니다');
      expect(v.effects, [isA<MoveToMedia>()]);
      expect(v.next!.verified, Verified.full);
      final c = run(v.next!, const Moved('trk_1/ren_1.flac'));
      expect(c.next!.state, DlState.completed);
      expect(c.next!.fileName, 'trk_1/ren_1.flac');
      expect(c.next!.playable, isTrue);
    });
  });

  group('검증 (§5.5)', () {
    test('해시 불일치: 처음부터 1회 재시도, 두 번째면 failed(integrity_mismatch)', () {
      final first = run(dl(state: DlState.verifying, done: 1000), const VerifyResult(size: 1000, sha256Actual: 'ff'));
      expect(first.next!.state, DlState.queued);
      expect(first.next!.bytesDone, 0);
      expect(first.effects, [isA<DeletePart>()]);
      final second = run(first.next!.copyWith(state: DlState.verifying), const VerifyResult(size: 1000, sha256Actual: 'ff'));
      expect(second.next!.state, DlState.failed);
      expect(second.next!.errorCode, 'integrity_mismatch');
      expect(second.effects, [isA<DeletePart>()]);
    });

    test('크기 불일치도 무결성 실패', () {
      expect(run(dl(state: DlState.verifying), const VerifyResult(size: 999, sha256Actual: 'ab')).next!.state, DlState.queued);
    });

    test('서버 해시가 없으면 다시 조회, 끝내 없으면 크기만 검증(size_only)', () {
      final v = run(dl(state: DlState.downloading, sha: null), const TransferDone(1000));
      expect((v.effects.single as VerifyPart).refetchSha, true);
      final later = run(v.next!, const VerifyResult(size: 1000, sha256Actual: 'cd', serverSha256: 'cd'));
      expect(later.next!.verified, Verified.full);
      final none = run(v.next!, const VerifyResult(size: 1000, sha256Actual: 'cd'));
      expect(none.next!.verified, Verified.sizeOnly);
      final wrong = run(v.next!, const VerifyResult(size: 1000, sha256Actual: 'cd', serverSha256: 'ee'));
      expect(wrong.next!.state, DlState.queued);
    });

    test('불완전 파일은 재생 대상이 아니다 (§5.1)', () {
      for (final s in DlState.values.where((s) => s != DlState.completed)) {
        expect(dl(state: s, file: 'trk_1/ren_1.flac').playable, isFalse, reason: s.wire);
      }
      expect(dl(state: DlState.completed, file: 'x', locked: true).playable, isFalse, reason: '잠긴 완료본');
    });
  });

  group('중단·재개 (§5.4)', () {
    test('같은 렌디션이면 bytes_done에서 이어받기', () {
      final r = run(dl(state: DlState.resolving, done: 400), resolved());
      expect((r.effects.single as StartTransfer).fromByte, 400);
    });

    test('다시 결정했더니 다른 렌디션·버전이면 부분 파일을 버리고 처음부터', () {
      final r = run(dl(state: DlState.resolving, done: 400), resolved(rid: 'ren_2', mv: 'mv2'));
      expect(r.next!.bytesDone, 0);
      expect(r.effects.first, isA<DeletePart>());
      expect((r.effects.last as StartTransfer).fromByte, 0);
    });

    test('206 대신 200: 부분 파일 버리고 처음부터', () {
      final r = run(dl(state: DlState.downloading, done: 400), const RangeIgnored());
      expect(r.next!.bytesDone, 0);
      expect(r.effects, [isA<DeletePart>(), isA<StartTransfer>()]);
    });

    test('410 rendition_superseded: 부분 삭제 → resolving, 옛 바이트를 잇지 않는다', () {
      final r = run(dl(state: DlState.downloading, done: 400), const Failed('rendition_superseded'));
      expect(r.next!.state, DlState.resolving);
      expect(r.next!.bytesDone, 0);
      expect(r.next!.renditionId, isNull);
      expect(r.effects, [isA<CancelTransfer>(), isA<DeletePart>(), isA<ResolveRendition>()]);
    });

    test('401 ticket_expired: 새 URL로 같은 오프셋', () {
      final r = run(dl(state: DlState.downloading, done: 400), const Failed('ticket_expired'));
      expect(r.next!.state, DlState.resolving);
      expect(r.next!.bytesDone, 400);
      final again = run(r.next!, resolved());
      expect((again.effects.single as StartTransfer).fromByte, 400);
    });

    test('네트워크·5xx: 5s, 30s, 2m, 10m 백오프 후 5회째 failed', () {
      var d = dl(state: DlState.downloading, done: 100);
      final waits = <Duration>[];
      for (var i = 0; i < 4; i++) {
        final s = run(d, const Failed('network'));
        expect(s.next!.state, DlState.queued);
        waits.add(s.next!.notBefore!.difference(now));
        expect(s.effects.whereType<WakeAt>().single.at, s.next!.notBefore);
        expect(run(s.next!, const Start()).next!.state, DlState.queued, reason: '재시도 시각 전에는 시작하지 않는다');
        expect(apply(s.next!, const Start(), s.next!.notBefore!).next!.state, DlState.resolving);
        d = s.next!.copyWith(state: DlState.downloading);
      }
      expect(waits, retryBackoff);
      final last = run(d, const Failed('network'));
      expect(last.next!.state, DlState.failed);
      expect(last.next!.errorCode, 'network');
      expect(last.next!.bytesDone, 100, reason: '부분 파일은 남겨 재시도 때 이어받는다');
    });

    test('Retry-After가 백오프보다 길면 그만큼 기다린다', () {
      final s = run(dl(state: DlState.resolving), const Failed('transcode_queue_full', retryAfter: Duration(minutes: 1)));
      expect(s.next!.notBefore, now.add(const Duration(minutes: 1)));
    });

    test('재시도할 수 없는 서버 오류는 바로 failed', () {
      for (final code in ['media_missing', 'unsupported_source', 'transcode_failed', 'no_playable_format', 'not_found', 'forbidden']) {
        final s = run(dl(state: DlState.resolving), Failed(code));
        expect(s.next!.state, DlState.failed, reason: code);
        expect(s.next!.errorCode, code);
      }
    });

    test('완료본에는 실패가 오지 않는다', () {
      final d = dl(state: DlState.completed, file: 'f');
      expect(run(d, const Failed('network')).next, same(d));
    });
  });

  group('조건 대기 (§5.7, §5.10)', () {
    test('Blocked → waiting_*, 전송 중이면 취소, Unblocked → 즉시 queued', () {
      for (final w in [DlState.waitingNetwork, DlState.waitingWifi, DlState.waitingSpace]) {
        final s = run(dl(state: DlState.downloading, done: 300), Blocked(w));
        expect(s.next!.state, w);
        expect(s.effects, [isA<CancelTransfer>()]);
        expect(s.next!.bytesDone, 300, reason: '.part 유지');
        final u = run(s.next!.copyWith(notBefore: now.add(const Duration(minutes: 9))), Unblocked(w));
        expect(u.next!.state, DlState.queued);
        expect(u.next!.notBefore, isNull, reason: '연결 복귀는 즉시 재개 (§5.4)');
        expect(run(s.next!, Unblocked(w == DlState.waitingWifi ? DlState.waitingSpace : DlState.waitingWifi)).next!.state, w, reason: '다른 조건이 풀려도 그대로');
      }
    });

    test('쓰기 중 공간 부족 → waiting_space (부분 유지), 연결 끊김 → waiting_network', () {
      expect(run(dl(state: DlState.downloading, done: 5), const Failed('disk_full')).next!.state, DlState.waitingSpace);
      expect(run(dl(state: DlState.downloading, done: 5), const Failed('offline')).next!.bytesDone, 5);
      expect(run(dl(state: DlState.downloading), const Failed('offline')).next!.state, DlState.waitingNetwork);
    });

    test('시작 조건: 연결, Wi-Fi 전용, 여유 500MB, 저장 한도', () {
      const mb = 1024 * 1024;
      DlState? c({bool online = true, bool wifi = true, bool wifiOnly = true, int? free = 10000 * mb, int? size = 10 * mb, int used = 0, int? limit}) =>
          conditionFor(online: online, onWifi: wifi, wifiOnly: wifiOnly, freeBytes: free, sizeBytes: size, usedBytes: used, limitBytes: limit);
      expect(c(), isNull);
      expect(c(online: false), DlState.waitingNetwork);
      expect(c(wifi: false), DlState.waitingWifi);
      expect(c(wifi: false, wifiOnly: false), isNull);
      expect(c(free: 509 * mb), DlState.waitingSpace, reason: '여유 − 크기 < 500MB');
      expect(c(free: 510 * mb), isNull);
      expect(c(used: 95 * mb, limit: 100 * mb), DlState.waitingSpace);
      expect(c(used: 90 * mb, limit: 100 * mb), isNull);
      expect(c(free: null), isNull, reason: '여유 공간을 알 수 없으면 막지 않는다(쓰기 중 오류로 처리)');
    });
  });

  group('사용자 조작', () {
    test('일시중지는 어느 진행 상태에서나, 재개는 queued로', () {
      for (final s in [DlState.queued, DlState.resolving, DlState.preparing, DlState.downloading, DlState.waitingNetwork, DlState.waitingWifi, DlState.waitingSpace, DlState.waitingLogin]) {
        final p = run(dl(state: s), const UserPause());
        expect(p.next!.state, DlState.paused, reason: s.wire);
        expect(p.effects.whereType<CancelTransfer>().length, s == DlState.downloading ? 1 : 0);
        expect(run(p.next!, const UserResume()).next!.state, DlState.queued);
      }
      for (final s in [DlState.completed, DlState.failed, DlState.verifying]) {
        expect(run(dl(state: s), const UserPause()).next!.state, s, reason: s.wire);
      }
    });

    test('일시중지 상태에서는 연결 끊김·실패가 상태를 바꾸지 않는다 (원인을 뭉치지 않음)', () {
      final p = dl(state: DlState.paused);
      expect(run(p, const Blocked(DlState.waitingNetwork)).next!.state, DlState.paused);
      expect(run(p, const Failed('network')).next!.state, DlState.paused);
      expect(run(p, const Start()).next!.state, DlState.paused);
    });

    test('실패 재시도는 횟수를 초기화', () {
      final r = run(dl(state: DlState.failed, attempts: 5, integrityRetried: true), const UserRetry());
      expect(r.next!.state, DlState.queued);
      expect(r.next!.attempts, 0);
      expect(r.next!.integrityRetried, isFalse);
      expect(r.next!.errorCode, isNull);
    });

    test('취소: 행을 먼저 지우고 파일은 저장 후 (§5.9)', () {
      final c = run(dl(state: DlState.downloading), const UserCancel());
      expect(c.next, isNull);
      expect(c.effects, [isA<CancelTransfer>(), isA<RemoveRow>(), isA<DeletePart>()]);
      final done = run(dl(state: DlState.completed, file: 'trk_1/ren_1.flac'), const UserCancel());
      expect(done.effects.whereType<DeleteMedia>().single.fileName, 'trk_1/ren_1.flac');
    });
  });

  group('완료본 버전 교체 (§5.4)', () {
    test('서버 버전이 다르면 stale, 계속 재생 가능', () {
      final s = run(dl(state: DlState.completed, file: 'f'), const ServerVersion('mv2'));
      expect(s.next!.stale, isTrue);
      expect(s.next!.playable, isTrue);
      expect(run(dl(state: DlState.completed, file: 'f'), const ServerVersion('mv1')).next!.stale, isFalse);
    });

    test('stale 완료본의 "새 버전 받기"는 별도 다운로드 (옛 파일은 새 파일 완료 후 지움)', () {
      final s = run(dl(state: DlState.completed, file: 'f', stale: true), const UserRetry());
      expect(s.effects, [isA<FetchNewVersion>()]);
      expect(s.next!.state, DlState.completed);
    });

    test('받는 중에 버전이 바뀌면 처음부터 다시 결정', () {
      final s = run(dl(state: DlState.downloading, done: 300), const ServerVersion('mv2'));
      expect(s.next!.state, DlState.queued);
      expect(s.next!.bytesDone, 0);
      expect(s.effects, [isA<CancelTransfer>(), isA<DeletePart>()]);
    });
  });

  group('세션·접근 (§5.8)', () {
    test('세션 만료: 진행 중은 waiting_login, 완료본은 그대로 재생 가능', () {
      final s = run(dl(state: DlState.downloading), const SessionExpired());
      expect(s.next!.state, DlState.waitingLogin);
      expect(s.effects, [isA<CancelTransfer>()]);
      expect(run(dl(state: DlState.completed, file: 'f'), const SessionExpired()).next!.playable, isTrue);
      expect(run(s.next!, const Unblocked(DlState.waitingLogin)).next!.state, DlState.queued);
    });

    test('접근 취소·로그아웃 보관: 잠금(완료본도 재생 불가), 잠긴 동안 사건 무시, 재로그인 시 해제', () {
      final c = run(dl(state: DlState.completed, file: 'f'), const Lock()).next!;
      expect(c.locked, isTrue);
      expect(c.playable, isFalse);
      final p = run(dl(state: DlState.downloading), const Lock());
      expect(p.next!.state, DlState.queued);
      expect(p.effects, [isA<CancelTransfer>()]);
      expect(run(p.next!, const Start()).next!.state, DlState.queued, reason: '잠긴 행은 시작하지 않는다');
      expect(run(c, const Unlock()).next!.playable, isTrue);
      expect(run(dl(state: DlState.waitingLogin, locked: true), const Unlock()).next!.state, DlState.queued);
      expect(run(c, const UserCancel()).next, isNull, reason: '잠긴 항목도 이 기기에서 삭제할 수 있다');
    });
  });

  group('재시작 대조표 (§5.9)', () {
    Step rc(Download d, {int? part, int? media, bool running = false, bool done = false}) =>
        reconcile(d, partSize: part, mediaSize: media, engineRunning: running, engineDone: done);

    test('DB downloading인데 엔진에 작업 없음 → .part 크기에서 재개', () {
      final s = rc(dl(state: DlState.downloading, done: 100), part: 640);
      expect(s.next!.bytesDone, 640);
      expect((s.effects.single as StartTransfer).fromByte, 640);
      expect(rc(dl(state: DlState.downloading, done: 100)).effects.single, isA<StartTransfer>().having((e) => e.fromByte, 'from', 100),
          reason: '.part가 없으면 기록된 위치 (백그라운드 패키지의 이어받기 정보)');
      expect(rc(dl(state: DlState.downloading)).effects.single, isA<StartTransfer>().having((e) => e.fromByte, 'from', 0));
    });

    test('엔진 작업이 살아 있으면 그대로', () {
      expect(rc(dl(state: DlState.downloading), part: 10, running: true).effects, isEmpty);
    });

    test('엔진은 완료, DB는 downloading → verifying 후 검증', () {
      final s = rc(dl(state: DlState.downloading), part: 1000, done: true);
      expect(s.next!.state, DlState.verifying);
      expect(s.effects.single, isA<VerifyPart>());
    });

    test('DB verifying → 검증 재실행(멱등)', () {
      expect(rc(dl(state: DlState.verifying), part: 1000).effects.single, isA<VerifyPart>());
    });

    test('verifying인데 .part는 없고 완료본이 있다(옮긴 뒤 저장 전에 죽음) → completed', () {
      final s = rc(dl(state: DlState.verifying), media: 1000);
      expect(s.next!.state, DlState.completed);
      expect(s.next!.fileName, 'trk_1/ren_1.flac');
      expect(rc(dl(state: DlState.verifying)).next!.state, DlState.queued, reason: '둘 다 없으면 처음부터');
    });

    test('DB completed인데 파일 없음/크기 다름 → 사유를 남기고 다시 받기', () {
      final missing = rc(dl(state: DlState.completed, file: 'trk_1/ren_1.flac'));
      expect(missing.next!.state, DlState.queued);
      expect(missing.next!.errorCode, 'file_missing');
      expect(missing.next!.fileName, isNull);
      final wrong = rc(dl(state: DlState.completed, file: 'trk_1/ren_1.flac'), media: 10);
      expect(wrong.effects.whereType<DeleteMedia>(), isNotEmpty);
      expect(rc(dl(state: DlState.completed, file: 'trk_1/ren_1.flac'), media: 1000).effects, isEmpty);
    });

    test('DB resolving/preparing → 렌디션 결정부터', () {
      expect(rc(dl(state: DlState.resolving)).next!.state, DlState.queued);
      expect(rc(dl(state: DlState.preparing)).next!.state, DlState.queued);
    });

    test('나머지 상태는 그대로', () {
      for (final s in [DlState.queued, DlState.paused, DlState.failed, DlState.waitingNetwork, DlState.waitingWifi, DlState.waitingSpace, DlState.waitingLogin]) {
        expect(rc(dl(state: s), part: 5).effects, isEmpty, reason: s.wire);
      }
    });

    test('고아 파일: DB에 없는 .part와 media 파일은 지운다', () {
      final rows = [dl(state: DlState.completed, file: 'trk_1/ren_1.flac'), dl(state: DlState.verifying).copyWith(), Download(id: 'dl_2', trackId: 'trk_2', quality: 'original')];
      final o = orphans(rows: rows, partIds: ['dl_1', 'dl_9'], mediaFiles: ['trk_1/ren_1.flac', 'trk_3/ren_3.mp3']);
      expect(o.parts, ['dl_9']);
      expect(o.media, ['trk_3/ren_3.mp3']);
    });
  });

  test('상태 저장값 (03장 §5.2)', () {
    for (final s in DlState.values) {
      expect(DlState.parse(s.wire), s);
    }
    expect(DlState.waitingNetwork.wire, 'waiting_network');
  });
}
