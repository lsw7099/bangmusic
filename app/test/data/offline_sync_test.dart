// 연결 복귀 동기화 (03장 §6.8, FN-22) — 모의 서버. 실제 서버 대상은 integration/offline_sync_real_server_test.dart (L1)
import 'dart:convert';
import 'dart:io';

import 'package:bangmusic/core/api_client.dart';
import 'package:bangmusic/core/session.dart';
import 'package:bangmusic/data/library_store.dart';
import 'package:bangmusic/data/offline_sync.dart';
import 'package:bangmusic/platform/secure_store.dart';
import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ui/fakes.dart' as f;

void main() {
  late Directory dir;
  late LibraryStore store;
  late f.FakeServer server;
  late ApiClient api;
  late OfflineSync sync;
  var version = 3;
  final edits = <Map<String, Object?>>[];
  final posted = <String>[];

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bm_sync');
    store = await LibraryStore.openForTest(dir);
    server = f.FakeServer();
    version = 3;
    edits.clear();
    posted.clear();
    server.on('GET /playlists/pl_1', (_) => f.playlist('pl_1', '드라이브', version: version));
    server.on('POST /playlists/pl_1/edits', (o) {
      final ifMatch = o.headers['If-Match'];
      if (ifMatch != '"$version"') return (412, {'type': 'about:blank', 'title': 'x', 'status': 412, 'code': 'version_conflict'});
      edits.add({'key': o.headers['Idempotency-Key'], ...(o.data as Map).cast<String, Object?>()});
      version++;
      return f.playlist('pl_1', '드라이브', version: version);
    });
    server.json('GET /playlists/pl_1/items', f.page([]));
    server.on('POST /history/events', (o) {
      final body = o.data is String ? jsonDecode(o.data as String) as Map : o.data as Map;
      for (final e in body['events'] as List) {
        posted.add((e as Map)['event_id'] as String);
      }
      return {'accepted': (body['events'] as List).length, 'duplicates': 0, 'rejected': <Object>[]};
    });
    final dio = Dio(BaseOptions(baseUrl: 'http://fake/v1'))..httpClientAdapter = server;
    const profile = ServerProfile(serverId: 'srv_T', baseUrl: 'http://fake', serverName: '시험', userId: 'usr_1', username: 'u', installationId: 'i');
    api = ApiClient(profile: profile, vault: TokenVault(MemorySecureStore()), tokens: Tokens('bma_x', DateTime(2030), 'bmr_x'), dio: dio);
    sync = OfflineSync(api: api, store: store);
  });

  tearDown(() async {
    await store.close();
    await dir.delete(recursive: true);
  });

  PlayEvent ev(String id) => PlayEvent.fromJson({'event_id': id, 'track_id': 'trk_1', 'started_at': '2026-10-03T00:00:00Z', 'played_ms': 1000, 'completed': true, 'source': 'offline'});

  test('오프라인 편집은 순서대로, 오프라인 때 정한 Idempotency-Key로, 현재 버전에 보낸다', () async {
    await store.addPendingOp('pl_1', [{'op': 'add', 'track_ids': ['trk_1']}], 'key-1');
    await store.addPendingOp('pl_1', [{'op': 'remove', 'item_ids': ['pli_9']}], 'key-2');
    final r = await sync.run();
    expect(r.opsSent, 2);
    expect(edits.map((e) => e['key']), ['key-1', 'key-2']);
    expect((edits.first['ops'] as List).single, {'op': 'add', 'track_ids': ['trk_1']});
    expect(await store.pendingOps(), isEmpty);
  });

  test('버전 충돌(412)이면 최신 버전으로 한 번 다시 (02장 §4)', () async {
    await store.addPendingOp('pl_1', [{'op': 'add', 'track_ids': ['trk_1']}], 'key-1');
    var first = true;
    server.on('GET /playlists/pl_1', (_) {
      // 처음 조회한 버전과 보낼 때 버전이 다르다(다른 기기가 그새 편집)
      final v = first ? version - 1 : version;
      first = false;
      return f.playlist('pl_1', '드라이브', version: v);
    });
    final r = await sync.run();
    expect(r.opsSent, 1);
    expect(edits.length, 1);
  });

  test('플레이리스트가 지워졌으면(404) 그 편집은 버리고 다음으로', () async {
    await store.addPendingOp('pl_gone', [{'op': 'add', 'track_ids': ['trk_1']}], 'key-x');
    await store.addPendingOp('pl_1', [{'op': 'add', 'track_ids': ['trk_2']}], 'key-1');
    final r = await sync.run();
    expect(r.opsDropped, 1);
    expect(r.opsSent, 1);
    expect(await store.pendingOps(), isEmpty);
  });

  test('연결이 끊기면 멈추고 남은 것은 다음에 같은 순서로', () async {
    await store.addPendingOp('pl_1', [{'op': 'add', 'track_ids': ['trk_1']}], 'key-1');
    await store.addPendingOp('pl_1', [{'op': 'add', 'track_ids': ['trk_2']}], 'key-2');
    await store.addPlayEvent(ev('e1'));
    server.on('GET /playlists/pl_1', (_) => throw DioException.connectionError(requestOptions: RequestOptions(), reason: 'offline'));
    final r = await sync.run();
    expect(r.interrupted, isTrue);
    expect((await store.pendingOps()).map((o) => o.key), ['key-1', 'key-2']);
    expect((await store.pendingPlayEvents()).length, 1, reason: '재생 기록도 보내지 않음(편집이 먼저)');
    server.on('GET /playlists/pl_1', (_) => f.playlist('pl_1', '드라이브', version: version));
    final again = await sync.run();
    expect(again.opsSent, 2);
    expect(again.eventsSent, 1);
  });

  test('재생 기록은 500개씩 보내고 보낸 것만 지운다, 같은 기록을 두 번 보내지 않는다', () async {
    for (var i = 0; i < 1203; i++) {
      await store.addPlayEvent(ev('e$i'));
    }
    final r = await sync.run();
    expect(r.eventsSent, 1203);
    expect(posted.length, 1203);
    expect(posted.toSet().length, 1203);
    expect(await store.pendingPlayEvents(), isEmpty);
    expect((await sync.run()).eventsSent, 0);
  });

  test('동시에 여러 번 불려도 한 번만 돈다', () async {
    await store.addPlayEvent(ev('e1'));
    await Future.wait([sync.run(), sync.run(), sync.run()]);
    expect(posted, ['e1']);
  });

  test('곡이 끝날 때는 재생 기록만 보낸다 (대기 편집·묶음 동기화는 하지 않음)', () async {
    await store.addPendingOp('pl_1', [{'op': 'add', 'track_ids': ['trk_1']}], 'key-1');
    await store.addPlayEvent(ev('e1'));
    await sync.sendPlayEvents();
    expect(posted, ['e1']);
    expect(edits, isEmpty);
    expect((await store.pendingOps()).length, 1, reason: '편집은 연결 복귀 동기화에서');
    expect(server.requests.where((r) => r.startsWith('GET /playlists')), isEmpty);
  });
}
