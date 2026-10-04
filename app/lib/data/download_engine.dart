// 다운로드 엔진 (01장 §2.5 DownloadEngine, 03장 §5). 상태 전이는 domain/download_state.dart의 순수 함수가 정하고,
// 이 클래스는 그 효과(렌디션 결정, 전송, 검증, 이동, 삭제)를 실행하고 저장한다.
// 쓰기 순서(§5.9): MoveToMedia는 저장 전, DeletePart·DeleteMedia는 저장(행 삭제) 후.
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/session.dart';
import '../domain/download_state.dart';
import '../platform/transfer_port.dart';
import 'library_store.dart';

/// 기기 조건 (연결, Wi-Fi, 여유 공간). 기기 구현은 platform/device_conditions.dart, 테스트는 가짜.
abstract interface class DeviceConditions {
  Future<({bool online, bool wifi})> network();
  Stream<void> get changes;
  Future<int?> freeBytes(Directory dir);
}

class DownloadSettings {
  DownloadSettings({this.wifiOnly = true, this.limitBytes, this.concurrency = 2, this.quality = 'original', this.autoUpdate = true});

  /// Wi-Fi에서만 받기 (기본 켜짐, 03장 §5.10)
  bool wifiOnly;

  /// 저장 한도 (null = 제한 없음, 03장 §5.7)
  int? limitBytes;

  /// 동시 다운로드 수 1~4 (기본 2, 03장 §5.4)
  int concurrency;
  String quality;

  /// 서버에 새 버전이 생기면 자동으로 받기 (03장 §5.4 2단계). 기본 켜짐 — Wi-Fi 전용·저장 한도 조건은 그대로 따른다
  bool autoUpdate;
}

class DownloadEngine {
  DownloadEngine({
    required this.store,
    required this.transfer,
    required this.conditions,
    required this.accept,
    DownloadSettings? settings,
    DateTime Function()? clock,
  })  : settings = settings ?? DownloadSettings(),
        _clock = clock ?? (() => DateTime.now().toUtc());

  final LibraryStore store;
  final TransferPort transfer;
  final DeviceConditions conditions;
  final List<FormatSpec> accept;
  final DownloadSettings settings;
  final DateTime Function() _clock;

  ApiClient? _api;
  final _rows = <String, Download>{};

  /// 이번 실행에서 받은 렌디션 URL (저장하지 않는다 — 02장 media_url)
  final _urls = <String, String>{};
  final _timers = <String, Timer>{};
  final _subs = <StreamSubscription<Object?>>[];
  final _random = Random.secure();
  bool _started = false;
  bool _pumping = false;
  bool _pumpAgain = false;

  /// 화면이 보는 목록 (S9). 저장소가 원본이고 이것은 그 거울이다
  final rows = ValueNotifier<List<Download>>(const []);

  /// 테스트: 모든 비동기 처리가 끝났는지 기다릴 수 있게
  Future<void> _tail = Future.value();

  // ── 시작·연결 ─────────────────────────────────────────────

  /// 앱 시작 시: 대조(§5.9) → 고아 정리 → 대기열 진행. api가 없으면(오프라인 시작) 재생용 목록만 연다.
  Future<void> start({ApiClient? api}) async {
    if (_started) return;
    _started = true;
    _api = api;
    for (final d in await store.downloads()) {
      _rows[d.id] = d;
    }
    _subs.add(transfer.updates.listen(_onTransfer));
    _subs.add(conditions.changes.listen((_) => _onConditions()));
    if (api != null) _watchSession(api);
    await _reconcileAll();
    _publish();
    await _onConditions();
  }

  /// 프로필 전환·로그아웃·종료: 진행 중 전송을 멈춘다(받은 바이트는 .part에 남아 다음에 이어받는다)
  Future<void> dispose() async {
    _disposed = true;
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    for (final id in await transfer.running()) {
      await transfer.cancel(id);
    }
    for (final s in _subs) {
      await s.cancel();
    }
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    _api?.status.removeListener(_onSession);
    // 저장소를 닫기 전에 진행 중인 결정·검증·사본 저장이 끝나기를 기다린다 (닫힌 DB에 쓰지 않게)
    while (_background.isNotEmpty) {
      await Future.wait([..._background]);
    }
    await settle();
  }

  bool _disposed = false;
  final _background = <Future<void>>{};

  /// 엔진 밖에서 도는 비동기 작업을 등록한다 (dispose가 기다린다). 오류는 기록만 한다.
  void _bg(Future<void> f) {
    if (_disposed) return;
    late final Future<void> tracked;
    tracked = f.catchError((Object e) => debugPrint('다운로드 엔진 작업 오류: $e')).whenComplete(() => _background.remove(tracked));
    _background.add(tracked);
  }

  /// 오프라인으로 시작했다가 로그인 정보가 생겼을 때
  void attachApi(ApiClient api) {
    _api = api;
    _watchSession(api);
    unawaited(_onConditions());
  }

  void _watchSession(ApiClient api) {
    api.status.removeListener(_onSession);
    api.status.addListener(_onSession);
  }

  void _onSession() {
    final s = _api?.status.value;
    final DlEvent? e = switch (s) {
      SessionStatus.expired => const SessionExpired(),
      SessionStatus.revoked => const Lock(),
      SessionStatus.active => const Unblocked(DlState.waitingLogin),
      _ => null,
    };
    if (e == null) return;
    _enqueue(() async {
      for (final d in [..._rows.values]) {
        await _dispatch(d.id, e);
      }
    });
    if (s == SessionStatus.active) _pump();
  }

  /// 같은 사용자로 다시 로그인: 잠금 해제 (§5.8)
  Future<void> unlockAll() => _enqueue(() async {
        for (final d in [..._rows.values]) {
          if (d.locked) await _dispatch(d.id, const Unlock());
        }
      }).then((_) => _pump());

  /// 접근 취소·로그아웃 보관 (§5.8)
  Future<void> lockAll() => _enqueue(() async {
        for (final d in [..._rows.values]) {
          await _dispatch(d.id, const Lock());
        }
      });

  /// 로그아웃 기본값: 이 기기의 다운로드 삭제 (§5.8)
  Future<void> deleteAll() => _enqueue(() async {
        for (final d in [..._rows.values]) {
          await _dispatch(d.id, const UserCancel());
        }
        for (final g in await store.groups()) {
          await store.unpinGroup(g.kind, g.refId);
        }
      });

  /// 테스트: 시계를 옮긴 뒤 재시도 대기 항목을 다시 살핀다
  @visibleForTesting
  void kick() => _pump();

  /// 모든 대기 작업이 끝날 때까지 (테스트·종료용)
  @visibleForTesting
  Future<void> settle() async {
    Future<void> last;
    do {
      last = _tail;
      await last;
      await Future<void>.delayed(Duration.zero);
    } while (!identical(last, _tail));
  }

  // ── 요청 ─────────────────────────────────────────────────

  String _newId() {
    String h(int n) => List.generate(n, (_) => _random.nextInt(16).toRadixString(16)).join();
    return 'dl_${h(16)}';
  }

  /// 곡 다운로드 (사본을 먼저 저장한다 — 오프라인 화면이 비지 않게, §5.6). quality가 없으면 지금 설정
  Future<void> downloadTracks(List<Track> tracks, RequestKind kind, String refId, {String? quality}) => _enqueue(() async {
        await store.putTracks(tracks);
        for (final t in tracks) {
          final r = await store.request(t.id, quality ?? settings.quality, kind, refId, newId: _newId);
          if (r.created) _rows[r.download.id] = r.download;
        }
        _publish();
      }).then((_) => _pump());

  /// 앨범 전체 (고정 묶음: 새 곡이 생기면 자동으로 받는다)
  Future<void> downloadAlbum(String albumId) async {
    final api = _requireApi();
    final a = await api.call((x) => x.getCatalogApi().getAlbum(albumId: albumId));
    await store.putAlbum(a);
    await store.putArtists([if (a.albumArtist != null) a.albumArtist!, for (final t in a.tracks) ...t.artists]);
    await store.pinGroup(RequestKind.album, albumId, settings.quality);
    await downloadTracks([for (final t in a.tracks) if (t.state == TrackStateEnum.available) t], RequestKind.album, albumId);
    _bg(_saveArtwork(a.artworkId));
  }

  /// 플레이리스트 전체 (항목 순서·표지 포함)
  Future<void> downloadPlaylist(String playlistId) async {
    final api = _requireApi();
    final p = await api.call((x) => x.getPlaylistsApi().getPlaylist(playlistId: playlistId));
    final items = await _allPlaylistItems(api, playlistId);
    await store.putPlaylist(p, items);
    await store.pinGroup(RequestKind.playlist, playlistId, settings.quality);
    await downloadTracks([for (final i in items) if (i.available && i.track != null) i.track!], RequestKind.playlist, playlistId);
    _bg(_saveArtwork(p.artworkId));
  }

  Future<List<PlaylistItem>> _allPlaylistItems(ApiClient api, String id) async {
    final out = <PlaylistItem>[];
    String? cursor;
    do {
      final page = await api.call((x) => x.getPlaylistsApi().listPlaylistItems(playlistId: id, cursor: cursor, limit: 200));
      out.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    return out;
  }

  /// 묶음 다운로드 해제: 다른 곳이 요구하지 않는 곡만 지운다 (§5.4)
  Future<void> removeGroup(RequestKind kind, String refId) => _enqueue(() async {
        await store.unpinGroup(kind, refId);
        for (final d in await store.release(kind, refId)) {
          await _dispatch(d.id, const UserCancel());
        }
      });

  Future<void> removeTrack(String trackId) => _enqueue(() async {
        for (final d in [..._rows.values.where((d) => d.trackId == trackId)]) {
          await _dispatch(d.id, const UserCancel());
        }
      });

  Future<void> pause(String id) => _enqueue(() => _dispatch(id, const UserPause())).then((_) => _pump());
  Future<void> resume(String id) => _enqueue(() => _dispatch(id, const UserResume())).then((_) => _pump());
  Future<void> retry(String id) => _enqueue(() => _dispatch(id, const UserRetry())).then((_) => _pump());
  Future<void> cancel(String id) => _enqueue(() => _dispatch(id, const UserCancel())).then((_) => _pump());

  Future<void> pauseAll() => _enqueue(() async {
        for (final d in [..._rows.values]) {
          await _dispatch(d.id, const UserPause());
        }
      });

  Future<void> resumeAll() => _enqueue(() async {
        for (final d in [..._rows.values.where((d) => d.state == DlState.paused)]) {
          await _dispatch(d.id, const UserResume());
        }
      }).then((_) => _pump());

  /// 동기화: 고정 묶음의 새 곡 받기, 서버 버전 비교로 stale 표시 (§5.4)
  Future<void> syncGroups() async {
    final api = _api;
    if (api == null) return;
    for (final g in await store.groups()) {
      try {
        final tracks = switch (g.kind) {
          RequestKind.album => await () async {
              final a = await api.call((x) => x.getCatalogApi().getAlbum(albumId: g.refId));
              await store.putAlbum(a);
              return a.tracks;
            }(),
          RequestKind.playlist => await () async {
              final p = await api.call((x) => x.getPlaylistsApi().getPlaylist(playlistId: g.refId));
              final items = await _allPlaylistItems(api, g.refId);
              await store.putPlaylist(p, items);
              return [for (final i in items) if (i.available && i.track != null) i.track!];
            }(),
          RequestKind.track => <Track>[],
        };
        await noteServerVersions(tracks);
        // 고정할 때의 음질로 (지금 설정을 쓰면 음질을 바꾸는 순간 받은 묶음 전체를 새 음질로 또 받았다 — P6 실기기)
        await downloadTracks([for (final t in tracks) if (t.state == TrackStateEnum.available) t], g.kind, g.refId, quality: g.quality);
      } catch (e) {
        final ae = ApiException.from(e);
        if (ae.status == 404) {
          // 서버에서 사라짐: 다운로드본은 "서버에 없음"으로 유지 (§5.4 4단계) — 고정만 푼다
          await store.unpinGroup(g.kind, g.refId);
        }
      }
    }
  }

  /// 서버에서 본 곡들의 현재 media_version (탐색·동기화 응답)
  Future<void> noteServerVersions(Iterable<Track> tracks) => _enqueue(() async {
        final byTrack = {for (final t in tracks) t.id: t.mediaVersion};
        for (final d in [..._rows.values]) {
          final mv = byTrack[d.trackId];
          if (mv != null) await _dispatch(d.id, ServerVersion(mv));
        }
        if (!settings.autoUpdate) return;
        // 자동 업데이트: stale 완료본마다, 같은 곡·음질의 새 받기가 아직 없으면 시작
        for (final d in [..._rows.values.where((d) => d.state == DlState.completed && d.stale && !d.locked)]) {
          final pending = _rows.values.any((o) => o.id != d.id && o.trackId == d.trackId && o.quality == d.quality && o.state != DlState.completed);
          if (!pending) await _dispatch(d.id, const UserRetry());
        }
      }).then((_) => _pump());

  ApiClient _requireApi() => _api ?? (throw ApiException(kind: ApiErrorKind.unreachable));

  // ── 재생 쪽에서 묻는 것 ──────────────────────────────────────

  /// 재생할 완료본 파일 (§5.5: 재생 시작 시 크기 재확인, 다르면 file_corrupt로 바꾸고 null → 스트리밍)
  Future<File?> playableFile(String trackId) async {
    final d = await store.playableFor(trackId);
    if (d == null) return null;
    final f = store.mediaFile(d.fileName!);
    final size = await f.exists() ? await f.length() : null;
    if (size != null && (d.bytesTotal == null || size == d.bytesTotal)) return f;
    await _enqueue(() async {
      final cur = _rows[d.id] ?? d;
      final next = cur.copyWith(state: DlState.queued, bytesDone: 0, fileName: null, errorCode: 'file_corrupt');
      _rows[d.id] = next;
      await store.saveDownload(next);
      if (size != null) await _deleteQuietly(f);
      _publish();
    });
    _pump();
    return null;
  }

  // ── 실행기 ───────────────────────────────────────────────

  /// 엔진의 모든 상태 변경은 한 줄로 직렬화한다(전송 갱신과 사용자 조작이 엇갈리지 않게)
  Future<void> _enqueue(Future<void> Function() job) {
    final next = _tail.then((_) => job()).catchError((Object e, StackTrace st) {
      debugPrint('다운로드 엔진 오류: $e\n$st');
    });
    _tail = next;
    return next;
  }

  Future<void> _dispatch(String id, DlEvent e) async {
    final d = _rows[id];
    if (d == null) return;
    final step = apply(d, e, _clock());
    await _commit(d, step);
  }

  Future<void> _commit(Download before, Step step) async {
    final next = step.next;
    // 저장 전 효과
    for (final ef in step.effects) {
      if (ef is CancelTransfer) await transfer.cancel(before.id);
      if (ef is MoveToMedia && next != null) {
        final moved = await _move(next);
        if (moved == null) {
          await _save(next.copyWith(state: DlState.queued, bytesDone: 0, errorCode: 'io_error'));
          return;
        }
        await _save(next);
        await _dispatch(next.id, Moved(moved));
        return;
      }
    }
    // 저장
    if (next == null || step.effects.any((e) => e is RemoveRow)) {
      _rows.remove(before.id);
      _urls.remove(before.id);
      _timers.remove(before.id)?.cancel();
      await store.deleteDownload(before.id);
    } else {
      await _save(next);
    }
    _publish();
    // 저장 후 효과
    for (final ef in step.effects) {
      switch (ef) {
        case DeletePart():
          await _deleteQuietly(store.partFile(before.id));
        case DeleteMedia(:final fileName):
          if (fileName.isNotEmpty) await _deleteQuietly(store.mediaFile(fileName));
        case ResolveRendition():
          _bg(_resolve(before.id));
        case PollRendition(:final after):
          _timers[before.id]?.cancel();
          _timers[before.id] = Timer(after, () => _bg(_poll(before.id)));
        case StartTransfer(:final fromByte):
          await _startTransfer(next ?? before, fromByte);
        case VerifyPart(:final refetchSha):
          _bg(_verify(before.id, refetchSha));
        case WakeAt(:final at):
          _timers[before.id]?.cancel();
          _timers[before.id] = Timer(at.difference(_clock()) + const Duration(milliseconds: 50), _pump);
        case FetchNewVersion():
          final fresh = await store.requestNewVersion(before, newId: _newId);
          _rows[fresh.id] = fresh;
          _publish();
          _pump();
        case CancelTransfer() || MoveToMedia() || RemoveRow():
          break;
      }
    }
    // 자리가 났거나 다시 대기열에 들어갔으면 다음 항목을 시작한다
    if (next != null && !next.state.active) _pump();
    if (next?.state == DlState.completed) _bg(_afterCompleted(next!));
  }

  Future<void> _save(Download d) async {
    _rows[d.id] = d;
    await store.saveDownload(d);
  }

  void _publish() {
    final list = _rows.values.toList();
    rows.value = list;
  }

  Future<void> _deleteQuietly(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// `.part` → `media/<track>/<rendition>.<ext>` (같은 파일시스템 rename)
  Future<String?> _move(Download d) async {
    final name = mediaPath(d);
    final dest = store.mediaFile(name);
    try {
      await dest.parent.create(recursive: true);
      await store.partFile(d.id).rename(dest.path);
      return name;
    } catch (e) {
      debugPrint('완료본 이동 실패: $e');
      return null;
    }
  }

  // ── 대기열 진행 ──────────────────────────────────────────

  Future<void> _onConditions() async {
    final net = await conditions.network();
    final free = await conditions.freeBytes(store.root);
    final used = await _committedBytes();
    await _enqueue(() async {
      for (final d in [..._rows.values.where((d) => d.state.waiting && !d.locked)]) {
        if (d.state == DlState.waitingLogin) continue;
        final c = conditionFor(online: net.online, onWifi: net.wifi, wifiOnly: settings.wifiOnly, freeBytes: free, sizeBytes: d.bytesTotal, usedBytes: used, limitBytes: settings.limitBytes);
        if (c != d.state) await _dispatch(d.id, Unblocked(d.state));
      }
      // 진행 중인 항목도 연결 조건을 다시 본다. 전송 패키지의 소식만 믿으면, OS가 Wi-Fi 조건 작업을 멈춘 뒤
      // 아무 소식이 없어 "받는 중"에 멈춰 있었다(FN-15 실기기). 공간 조건은 시작할 때만 본다(이미 받는 중인 바이트는 센 상태).
      for (final d in [..._rows.values.where((d) => d.state.active && d.state != DlState.verifying && !d.locked)]) {
        final c = conditionFor(online: net.online, onWifi: net.wifi, wifiOnly: settings.wifiOnly, freeBytes: null, sizeBytes: null, usedBytes: 0, limitBytes: null);
        if (c != null) await _dispatch(d.id, Blocked(c));
      }
    });
    _pump();
  }

  /// 빈 자리만큼 queued 항목을 시작한다
  void _pump() {
    if (_disposed) return;
    if (_pumping) {
      _pumpAgain = true;
      return;
    }
    _pumping = true;
    unawaited(_enqueue(() async {
      do {
        _pumpAgain = false;
        if (_api == null) break;
        if (_api!.status.value == SessionStatus.expired) {
          for (final d in [..._rows.values.where((d) => d.state == DlState.queued)]) {
            await _dispatch(d.id, const SessionExpired());
          }
          break;
        }
        final net = await conditions.network();
        final free = await conditions.freeBytes(store.root);
        var used = await _committedBytes();
        final now = _clock();
        var active = _rows.values.where((d) => d.state.active).length;
        final queued = _rows.values.where((d) => d.state == DlState.queued && !d.locked).toList();
        for (final d in queued) {
          if (active >= settings.concurrency.clamp(1, 4)) break;
          if (d.notBefore != null && now.isBefore(d.notBefore!)) continue;
          final c = conditionFor(online: net.online, onWifi: net.wifi, wifiOnly: settings.wifiOnly, freeBytes: free, sizeBytes: d.bytesTotal, usedBytes: used, limitBytes: settings.limitBytes);
          if (c != null) {
            await _dispatch(d.id, Blocked(c));
            continue;
          }
          await _dispatch(d.id, const Start());
          active++;
          used += d.bytesTotal ?? 0;
        }
      } while (_pumpAgain);
      _pumping = false;
    }).whenComplete(() => _pumping = false));
  }

  // ── 효과 구현 ────────────────────────────────────────────

  Future<void> _resolve(String id) async {
    final api = _api;
    final d = _rows[id];
    if (api == null || d == null) return;
    try {
      final r = await api.call((x) => x.getMediaApi().resolveRendition(
            trackId: d.trackId,
            renditionRequest: RenditionRequest(purpose: RenditionRequestPurposeEnum.download, quality: d.quality, accept: accept),
          ));
      await _enqueue(() => _resolved(id, r));
    } catch (e) {
      await _enqueue(() => _dispatch(id, _failure(e)));
    }
  }

  Future<void> _poll(String id) async {
    final api = _api;
    final d = _rows[id];
    if (api == null || d == null || d.renditionId == null || d.state != DlState.preparing) return;
    try {
      final r = await api.call((x) => x.getMediaApi().getRendition(renditionId: d.renditionId!));
      await _enqueue(() => _resolved(id, r));
    } catch (e) {
      await _enqueue(() => _dispatch(id, _failure(e)));
    }
  }

  Future<void> _resolved(String id, Rendition r) async {
    if (r.state == RenditionStateEnum.failed) {
      await _dispatch(id, Failed(r.errorCode ?? 'transcode_failed'));
      return;
    }
    if (r.mediaUrl != null) _urls[id] = r.mediaUrl!;
    await _dispatch(id, Resolved(
      renditionId: r.id, mediaVersion: r.mediaVersion, ready: r.state == RenditionStateEnum.ready, sizeBytes: r.sizeBytes, sha256: r.sha256,
      etag: r.etag, ext: r.container, retryAfter: r.retryAfterS == null ? null : Duration(seconds: r.retryAfterS!.clamp(1, 30)),
    ));
  }

  /// 저장 한도에 넣어 셀 바이트: 완료본 + 지금 받는 중인 다른 곡(크기를 아는 것) (03장 §5.7)
  Future<int> _committedBytes({String? except}) async {
    var n = await store.usedBytes();
    for (final r in _rows.values) {
      if (r.id != except && r.state.active && r.state != DlState.verifying) n += r.bytesTotal ?? 0;
    }
    return n;
  }

  Future<void> _startTransfer(Download d, int from) async {
    // 크기는 렌디션을 결정한 뒤에야 안다 → 받기 직전에 공간·한도를 다시 판단한다
    // (결정 전 크기 0으로만 판단해 한도가 무시되던 결함 — 실기기에서 발견)
    final net = await conditions.network();
    final c = conditionFor(
      online: net.online, onWifi: net.wifi, wifiOnly: settings.wifiOnly, freeBytes: await conditions.freeBytes(store.root),
      sizeBytes: (d.bytesTotal ?? 0) - from, usedBytes: await _committedBytes(except: d.id), limitBytes: settings.limitBytes,
    );
    if (c != null) {
      await _dispatch(d.id, Blocked(c));
      return;
    }
    final api = _api;
    final url = _urls[d.id];
    if (api == null || url == null) {
      // 이번 실행에서 받은 URL이 없다(재시작 직후): 티켓을 다시 받는다
      unawaited(_enqueue(() => _dispatch(d.id, const Failed('ticket_expired'))));
      return;
    }
    await transfer.start(
      downloadId: d.id, url: Uri.parse('${api.baseUrl}$url'), part: store.partFile(d.id), fromByte: from, etag: d.etag,
      wifiOnly: settings.wifiOnly, title: (await store.track(d.trackId))?.title,
    );
  }

  Future<void> _verify(String id, bool refetchSha) async {
    final d = _rows[id];
    if (d == null) return;
    final part = store.partFile(id);
    try {
      final (size, hash) = await compute(_hashFile, part.path);
      String? serverSha;
      if (refetchSha && _api != null && d.renditionId != null) {
        try {
          serverSha = (await _api!.call((x) => x.getMediaApi().getRendition(renditionId: d.renditionId!))).sha256;
        } catch (_) {}
      }
      await _enqueue(() => _dispatch(id, VerifyResult(size: size, sha256Actual: hash, serverSha256: serverSha)));
    } catch (_) {
      // .part가 없다: 처음부터
      await _enqueue(() => _dispatch(id, const VerifyResult(size: -1, sha256Actual: '')));
    }
  }

  void _onTransfer(TransferUpdate u) {
    unawaited(_enqueue(() async {
      switch (u) {
        case TransferProgress(:final bytesDone):
          final d = _rows[u.downloadId];
          if (d == null || d.state != DlState.downloading) return;
          // 진행률은 메모리만 갱신하고 1MB마다 저장한다
          final next = d.copyWith(bytesDone: bytesDone);
          _rows[d.id] = next;
          if (bytesDone - d.bytesDone > 1024 * 1024 || bytesDone < d.bytesDone) await store.saveDownload(next);
          _publish();
        case TransferRestarted():
          await _dispatch(u.downloadId, const Progress(0));
        case TransferComplete():
          final f = store.partFile(u.downloadId);
          final size = await f.exists() ? await f.length() : 0;
          await _dispatch(u.downloadId, TransferDone(size));
        case TransferFailed(:final code, :final retryAfter):
          if (code == 'network' && !(await conditions.network()).online) {
            await _dispatch(u.downloadId, const Failed('offline'));
          } else {
            await _dispatch(u.downloadId, Failed(code, retryAfter: retryAfter));
          }
      }
    }));
  }

  DlEvent _failure(Object e) {
    final ae = ApiException.from(e);
    if (ae.status == 401 && ae.code == 'refresh_expired') return const Failed('refresh_expired');
    if (ae.kind == ApiErrorKind.unreachable || ae.kind == ApiErrorKind.timeout) return const Failed('network');
    if (ae.kind == ApiErrorKind.serverMismatch) return const Failed('offline'); // 다른 서버: 연결 대기로 (토큰은 나가지 않았다)
    return Failed(ae.code ?? failureCode(ae.status), retryAfter: ae.retryAfter == null ? null : Duration(seconds: ae.retryAfter!));
  }

  // ── 재시작 대조 (§5.9) ──────────────────────────────────

  Future<void> _reconcileAll() async {
    final running = await transfer.running();
    for (final d in [..._rows.values]) {
      final part = store.partFile(d.id);
      final partSize = await part.exists() ? await part.length() : null;
      final media = d.fileName ?? (d.renditionId == null ? null : mediaPath(d));
      final mf = media == null ? null : store.mediaFile(media);
      final mediaSize = mf != null && await mf.exists() ? await mf.length() : null;
      final engineDone = d.state == DlState.downloading && partSize != null && d.bytesTotal != null && partSize == d.bytesTotal && !running.contains(d.id);
      final step = reconcile(d, partSize: partSize, mediaSize: mediaSize, engineRunning: running.contains(d.id), engineDone: engineDone);
      if (!identical(step.next, d) || step.effects.isNotEmpty) await _commit(d, step);
    }
    // 고아 파일
    final parts = <String>[];
    if (await store.tmpDir.exists()) {
      await for (final f in store.tmpDir.list()) {
        final name = f.uri.pathSegments.last;
        if (name.endsWith('.part')) parts.add(name.substring(0, name.length - 5));
      }
    }
    final media = <String>[];
    if (await store.mediaDir.exists()) {
      await for (final f in store.mediaDir.list(recursive: true)) {
        if (f is File) media.add(f.path.substring(store.mediaDir.path.length + 1).replaceAll(r'\', '/'));
      }
    }
    final o = orphans(rows: _rows.values, partIds: parts, mediaFiles: media);
    for (final p in o.parts) {
      await _deleteQuietly(store.partFile(p));
    }
    for (final m in o.media) {
      await _deleteQuietly(store.mediaFile(m));
    }
  }

  // ── 완료 후: 옛 버전 정리, 가사·표지 사본 (§5.4, §5.6) ──────────

  Future<void> _afterCompleted(Download d) async {
    await _enqueue(() async {
      for (final old in [..._rows.values.where((o) => o.id != d.id && o.trackId == d.trackId && o.quality == d.quality && o.state == DlState.completed)]) {
        // 새 파일이 completed가 된 뒤에 옛 파일과 행을 지운다 (재생 중이어도 Android는 열린 파일을 끝까지 읽는다)
        await _dispatch(old.id, const UserCancel());
      }
    });
    final api = _api;
    if (api == null) return;
    try {
      final res = await api.api.getLyricsApi().getLyrics(trackId: d.trackId);
      if (res.data != null) await store.putLyrics(res.data!, res.headers.value('etag'));
    } catch (_) {
      // 가사 없음·연결 실패: 다음 동기화 때
    }
    final t = await store.track(d.trackId);
    await _saveArtwork(t?.artworkId);
  }

  /// 목록용(256)과 몰입 화면용(1024) 두 크기 (§5.6)
  Future<void> _saveArtwork(String? artworkId) async {
    final api = _api;
    if (artworkId == null || api == null) return;
    final dir = Directory('${store.root.path}/artwork');
    for (final size in [256, 1024]) {
      final f = File('${dir.path}/${artworkId}_$size.jpg');
      if (await f.exists()) continue;
      try {
        await dir.create(recursive: true);
        final tmp = File('${f.path}.part');
        await api.dio.download('/artwork/$artworkId', tmp.path, queryParameters: {'size': size});
        await tmp.rename(f.path);
      } catch (_) {}
    }
  }

  /// 저장된 표지 (오프라인 화면용)
  File? artworkFile(String? artworkId, int size) {
    if (artworkId == null) return null;
    final s = size <= 256 ? 256 : 1024;
    final f = File('${store.root.path}/artwork/${artworkId}_$s.jpg');
    return f.existsSync() ? f : null;
  }
}

/// UI 스레드 밖에서 크기와 SHA-256 (§5.5). 엔진 객체를 잡지 않도록 최상위 함수
Future<(int, String)> _hashFile(String path) async {
  final f = File(path);
  final digest = await sha256.bind(f.openRead()).first;
  return (await f.length(), digest.toString());
}
