// FN-21 (L1): 서버 프로필 2개를 오갈 때 다운로드·로컬 DB가 섞이지 않고, 주소는 같은데 server_id가 다른 서버에는
// 토큰이 전송되지 않는다. 실제 로컬 서버 2대 + 요청 헤더를 기록하는 HTTP 중계(같은 주소를 다른 서버로 바꿔 붙이기 위함).
@Tags(['integration'])
library;

import 'dart:io';

import 'package:bangmusic/core/api_client.dart';
import 'package:bangmusic/data/download_engine.dart';
import 'package:bangmusic/data/library_store.dart';
import 'package:bangmusic/domain/download_state.dart';
import 'package:bangmusic/platform/secure_store.dart';
import 'package:bangmusic/platform/transfer_port.dart';
import 'package:bangmusic/ui/app_state.dart';
import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui/fakes.dart';
import 'real_server.dart';

/// 요청을 target으로 넘기며 (대상, 경로, Authorization 유무)를 기록한다. target을 바꾸면 "같은 주소에 다른 서버"
class RecordingProxy {
  late HttpServer _server;
  final _client = HttpClient();
  String target;
  final log = <({String target, String path, bool auth})>[];
  RecordingProxy(this.target);

  Future<String> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
    return 'http://127.0.0.1:${_server.port}';
  }

  Future<void> _handle(HttpRequest req) async {
    final t = target;
    log.add((target: t, path: req.uri.path, auth: req.headers.value('authorization') != null));
    final out = await _client.openUrl(req.method, Uri.parse('$t${req.uri}'));
    req.headers.forEach((name, values) {
      if (name != 'host') out.headers.set(name, values);
    });
    await out.addStream(req);
    final res = await out.close();
    req.response.statusCode = res.statusCode;
    res.headers.forEach((name, values) {
      if (name != 'transfer-encoding') req.response.headers.set(name, values);
    });
    await req.response.addStream(res);
    await req.response.close();
  }

  Future<void> close() async {
    await _server.close(force: true);
    _client.close(force: true);
  }
}

class OkConditions implements DeviceConditions {
  @override
  Future<({bool online, bool wifi})> network() async => (online: true, wifi: true);
  @override
  Stream<void> get changes => const Stream.empty();
  @override
  Future<int?> freeBytes(Directory dir) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  RealServer? a;
  RealServer? b;
  String? skip;

  setUpAll(() async {
    HttpOverrides.global = null; // 위젯 바인딩이 막아 둔 실제 HTTP를 쓴다
    (a, skip) = await RealServer.start();
    if (skip == null) (b, skip) = await RealServer.start();
  });
  tearDownAll(() async {
    await a?.stop();
    await b?.stop();
  });

  test('FN-21: 서버 둘을 오가도 다운로드가 섞이지 않고, 같은 주소의 다른 서버에는 토큰을 보내지 않는다', () async {
    if (skip != null) {
      markTestSkipped(skip!);
      return;
    }
    SharedPreferences.setMockInitialValues({});
    final root = await Directory.systemTemp.createTemp('bm_fn21');
    final proxy = RecordingProxy(a!.baseUrl);
    final addressA = await proxy.start(); // 앱이 아는 A의 주소
    final app = AppState(
      player: FakePlayer(),
      store: MemorySecureStore(),
      services: AppServices(
        transfer: () async => HttpTransfer(idleTimeout: const Duration(seconds: 5)),
        conditions: OkConditions(),
        openStore: (sid, uid) => LibraryStore.openIn(Directory('${root.path}/$sid/$uid')), // 파일 DB (다시 열어도 남는다)
      ),
    );
    try {
      await app.load();
      Future<ProbeOk> probe(String url) async => (await probeServer(url)) as ProbeOk;

      // ── A에 로그인해 한 곡 받기
      await app.signIn(await probe(addressA), a!.username, a!.password);
      final serverA = app.profile!.serverId;
      final trackA = (await app.api!.call((x) => x.getCatalogApi().listTracks(limit: 5))).items.firstWhere((t) => t.state == TrackStateEnum.available);
      await app.downloads!.downloadTracks([trackA], RequestKind.track, trackA.id);
      final end = DateTime.now().add(const Duration(seconds: 60));
      while (!app.downloads!.rows.value.any((d) => d.state == DlState.completed)) {
        if (DateTime.now().isAfter(end)) fail('A 다운로드 시간 초과: ${app.downloads!.rows.value}');
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      // ── B로 (서버 추가)
      await app.signIn(await probe(b!.baseUrl), b!.username, b!.password);
      final serverB = app.profile!.serverId;
      expect(serverB, isNot(serverA));
      expect(app.profiles.map((p) => p.serverId).toSet(), {serverA, serverB});
      expect(app.downloads!.rows.value, isEmpty, reason: 'B에는 A의 다운로드가 보이지 않는다');
      expect(await app.library!.playableFor(trackA.id), isNull);

      // ── 다시 A로: 받은 곡 그대로
      expect(await app.switchTo(app.profiles.firstWhere((p) => p.serverId == serverA)), isTrue);
      expect(app.downloads!.rows.value.where((d) => d.state == DlState.completed).map((d) => d.trackId), [trackA.id]);
      expect(await app.downloads!.playableFile(trackA.id), isNotNull);

      // ── 같은 주소에 다른 서버(B)가 올라옴 (A 재설치·주소 재사용·위장). 앱을 다시 연 것과 같게 A를 다시 활성화한다
      proxy.target = b!.baseUrl;
      final profileA = app.profiles.firstWhere((p) => p.serverId == serverA);
      expect(await app.switchTo(app.profiles.firstWhere((p) => p.serverId == serverB)), isTrue);
      final before = proxy.log.length;
      expect(await app.switchTo(profileA), isTrue);
      Object? err;
      try {
        await app.api!.call((x) => x.getCatalogApi().listTracks(limit: 1));
      } catch (e) {
        err = e;
      }
      expect(err, isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.serverMismatch));
      await app.syncNow(); // 연결 복귀 동기화도 토큰을 내보내지 않아야 한다
      await app.downloads!.settle();
      final toB = proxy.log.sublist(before).where((r) => r.target == b!.baseUrl).toList();
      expect(toB.where((r) => r.auth), isEmpty, reason: 'B로 간 요청에는 Authorization이 없어야 한다: $toB');
      expect(app.serverChanged, isTrue);
      expect(app.offline, isTrue, reason: '받은 음악으로 화면을 그린다');
      // ignore: avoid_print
      print('FN-21: A·B 다운로드 분리, A 복귀 시 유지, 주소 재사용 시 B로 간 요청 ${toB.length}건 모두 토큰 없음 (${toB.map((r) => r.path).toSet()})');
    } finally {
      await app.close();
      await proxy.close();
      await root.delete(recursive: true);
    }
  });
}
