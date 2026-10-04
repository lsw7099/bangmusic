// 연결 복귀 동기화 (03장 §6.8, FN-22): 대기 중인 플레이리스트 편집을 순서대로 → 재생 기록 일괄 → 다운로드 묶음.
// 중복 없이: 편집은 Idempotency-Key(오프라인 때 정한 값)를 그대로 보내고, 재생 기록은 event_id로 서버가 거른다.
import 'package:bangmusic_api/bangmusic_api.dart';

import '../core/api_client.dart';
import 'download_engine.dart';
import 'library_store.dart';

class SyncReport {
  int opsSent = 0;
  int opsDropped = 0;
  int eventsSent = 0;
  bool interrupted = false;
  @override
  String toString() => 'SyncReport(ops=$opsSent, dropped=$opsDropped, events=$eventsSent, interrupted=$interrupted)';
}

class OfflineSync {
  OfflineSync({required this.api, required this.store, this.downloads});

  final ApiClient api;
  final LibraryStore store;
  final DownloadEngine? downloads;
  Future<SyncReport>? _running;

  /// 동시에 여러 번 불려도 한 번만 돈다
  Future<SyncReport> run() => _running ??= _run().whenComplete(() => _running = null);

  /// 재생 기록만 보낸다 (곡이 끝날 때마다 — 전체 동기화는 연결 복귀 때만)
  Future<void> sendPlayEvents() async {
    if (_running != null) return; // 전체 동기화가 곧 보낸다
    await _sendEvents(SyncReport());
  }

  bool _networkError(ApiException e) => e.kind == ApiErrorKind.unreachable || e.kind == ApiErrorKind.timeout || (e.status != null && e.status! >= 500);

  Future<SyncReport> _run() async {
    final report = SyncReport();
    // 1. 플레이리스트 편집 (02장 §4: 버전 충돌이면 최신 버전으로 한 번 다시)
    for (final op in await store.pendingOps()) {
      try {
        Playlist result;
        try {
          final current = await api.call((x) => x.getPlaylistsApi().getPlaylist(playlistId: op.playlistId));
          result = await api.editPlaylist(op.playlistId, current.version, op.ops, idempotencyKey: op.key);
        } on ApiException catch (e) {
          if (e.status != 412) rethrow;
          final current = await api.call((x) => x.getPlaylistsApi().getPlaylist(playlistId: op.playlistId));
          result = await api.editPlaylist(op.playlistId, current.version, op.ops, idempotencyKey: op.key);
        }
        await store.removeOp(op.seq);
        report.opsSent++;
        await _refreshPlaylist(result);
      } on ApiException catch (e) {
        if (_networkError(e) || e.status == 401) {
          report.interrupted = true;
          return report; // 다음 연결 때 같은 순서로 다시
        }
        // 플레이리스트가 지워졌거나(404) 항목이 사라지는 등 다시 보내도 안 되는 편집은 버린다
        await store.removeOp(op.seq);
        report.opsDropped++;
      }
    }
    // 2. 재생 기록
    if (!await _sendEvents(report)) return report;
    // 3. 고정 묶음의 새 곡·새 버전
    await downloads?.syncGroups();
    return report;
  }

  /// 500개씩 보낸다. 연결 문제로 멈추면 false
  Future<bool> _sendEvents(SyncReport report) async {
    while (true) {
      final events = await store.pendingPlayEvents(limit: 500);
      if (events.isEmpty) break;
      try {
        await api.call((x) => x.getHistoryApi().postPlayEvents(postPlayEventsRequest: PostPlayEventsRequest(events: events)));
        // 받아들인 것·중복·거절 모두 다시 보낼 이유가 없다
        await store.removePlayEvents(events.map((e) => e.eventId));
        report.eventsSent += events.length;
      } on ApiException catch (e) {
        if (e.status == 400) {
          await store.removePlayEvents(events.map((e) => e.eventId)); // 형식 오류는 다시 보내도 같다
          continue;
        }
        report.interrupted = true;
        return false;
      }
    }
    return true;
  }

  /// 편집한 플레이리스트의 로컬 사본을 서버 기준으로 교체 (임시 local_ 항목 ID 정리)
  Future<void> _refreshPlaylist(Playlist p) async {
    if (await store.playlist(p.id) == null) return;
    final items = <PlaylistItem>[];
    String? cursor;
    do {
      final page = await api.call((x) => x.getPlaylistsApi().listPlaylistItems(playlistId: p.id, cursor: cursor, limit: 200));
      items.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    await store.putPlaylist(p, items);
  }
}
