// FN-22 (L1): 오프라인 중 쌓인 재생 기록·플레이리스트 편집이 복귀 후 중복 없이 반영된다 — 실제 로컬 서버.
// 확인은 서버의 내 데이터 내보내기(GET /me/export: 재생 기록 전체·플레이리스트 항목)로 한다.
// 응답을 받지 못해 같은 편집·기록을 다시 보내는 경우(같은 Idempotency-Key·event_id)도 시험한다.
@Tags(['integration'])
library;

import 'dart:io';

import 'package:bangmusic/core/api_client.dart';
import 'package:bangmusic/data/library_store.dart';
import 'package:bangmusic/data/offline_sync.dart';
import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:flutter_test/flutter_test.dart';

import 'real_server.dart';

void main() {
  RealServer? server;
  String? skip;

  setUpAll(() async {
    (server, skip) = await RealServer.start();
  });
  tearDownAll(() async => server?.stop());

  Future<Map<String, dynamic>> export(ApiClient api) async => (await api.dio.get<Map<String, dynamic>>('/me/export')).data!;

  test('FN-22: 오프라인 편집·재생 기록이 복귀 후 한 번씩만 반영 (다시 보내도 중복 없음, 다른 기기 편집과 충돌 시 재시도)', () async {
    if (skip != null) {
      markTestSkipped(skip!);
      return;
    }
    final phone = await server!.login();
    final other = await server!.login(); // 같은 계정의 다른 기기
    final tracks = (await phone.call((x) => x.getCatalogApi().listTracks(limit: 10))).items.where((t) => t.state == TrackStateEnum.available).toList();
    expect(tracks.length, greaterThanOrEqualTo(4));
    final pl = await phone.call((x) => x.getPlaylistsApi().createPlaylist(
          createPlaylistRequest: CreatePlaylistRequest(name: 'FN-22 오프라인 편집', trackIds: [tracks[0].id]),
          idempotencyKey: '11111111-1111-4111-8111-000000000001',
        ));
    final before = (await export(phone))['play_events'] as List;

    final dir = await Directory.systemTemp.createTemp('bm_fn22');
    final store = await LibraryStore.openForTest(dir);
    try {
      // ── 오프라인: 편집 2건과 재생 기록 3건이 쌓인다
      final ops1 = <Map<String, Object?>>[{'op': 'add', 'track_ids': [tracks[1].id]}];
      final ops2 = <Map<String, Object?>>[{'op': 'add', 'track_ids': [tracks[2].id], 'after_item_id': null}];
      await store.addPendingOp(pl.id, ops1, '22222222-2222-4222-8222-000000000001');
      await store.addPendingOp(pl.id, ops2, '22222222-2222-4222-8222-000000000002');
      PlayEvent ev(int i) => PlayEvent.fromJson({
            'event_id': '33333333-3333-4333-8333-00000000000$i', 'track_id': tracks[i].id, 'started_at': '2026-10-03T0$i:00:00Z',
            'played_ms': 1000 * i, 'completed': i.isOdd, 'source': 'offline', 'context': {'type': 'playlist', 'id': pl.id},
          });
      for (var i = 1; i <= 3; i++) {
        await store.addPlayEvent(ev(i));
      }
      // 그사이 다른 기기가 같은 플레이리스트를 편집했다 → 오프라인 편집은 버전 충돌 후 최신 버전으로 반영돼야 한다
      final cur = await other.call((x) => x.getPlaylistsApi().getPlaylist(playlistId: pl.id));
      await other.editPlaylist(pl.id, cur.version, [{'op': 'add', 'track_ids': [tracks[3].id]}], idempotencyKey: '44444444-4444-4444-8444-000000000001');

      // ── 복귀
      final r1 = await OfflineSync(api: phone, store: store).run();
      expect(r1.opsSent, 2, reason: '$r1');
      expect(r1.eventsSent, 3);

      // ── 응답을 받지 못한 것처럼 같은 편집·기록을 다시 보낸다
      await store.addPendingOp(pl.id, ops1, '22222222-2222-4222-8222-000000000001');
      for (var i = 1; i <= 3; i++) {
        await store.addPlayEvent(ev(i));
      }
      final r2 = await OfflineSync(api: phone, store: store).run();
      expect(r2.interrupted, isFalse, reason: '$r2');

      final ex = await export(phone);
      final history = (ex['play_events'] as List).cast<Map<String, dynamic>>();
      final mine = history.where((e) => (e['event_id'] as String).startsWith('33333333')).toList();
      expect(mine.length, 3, reason: '같은 event_id는 한 번만');
      expect(history.length, before.length + 3);
      expect(mine.every((e) => e['source'] == 'offline'), isTrue);
      final items = ((ex['playlists'] as List).cast<Map<String, dynamic>>().firstWhere((p) => p['id'] == pl.id)['items'] as List).cast<Map<String, dynamic>>();
      final ids = [for (final i in items) i['track_id']];
      // 맨 앞 추가(ops2) → 원래 곡 → 다른 기기 추가 → 오프라인 추가(ops1). 다시 보낸 ops1은 늘지 않는다
      expect(ids, [tracks[2].id, tracks[0].id, tracks[3].id, tracks[1].id]);
      // ignore: avoid_print
      print('FN-22: 편집 ${r1.opsSent}건 반영(충돌 후 재시도 포함), 재전송 시 중복 0, 재생 기록 ${mine.length}건(중복 0), 항목 순서 $ids');
    } finally {
      await store.close();
      await dir.delete(recursive: true);
    }
  });
}
