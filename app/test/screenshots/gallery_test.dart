// 화면×상태 갤러리 (P5 수용 기준 "화면×상태 매트릭스 체크리스트 전 항목 확인(스크린샷 첨부)").
// 가짜 서버·가짜 플레이어로 04장 각 화면 표의 상태를 만들어 휴대폰 크기(360×780dp)로 그리고 PNG로 저장한다.
// 글꼴: Noto Sans KR(Windows 글꼴, OFL — 그림을 만들 때만 쓰고 앱에는 넣지 않는다), Flutter SDK의 Material 아이콘.
// 실행: flutter test --tags screenshots test/screenshots/gallery_test.dart
//   → docs/status/evidence/p5-gallery/*.png, index.md
@Tags(['screenshots'])
library;

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bangmusic/core/api_client.dart';
import 'package:bangmusic/core/session.dart';
import 'package:bangmusic/data/download_engine.dart';
import 'package:bangmusic/data/library_store.dart';
import 'package:bangmusic/domain/download_state.dart';
import 'package:bangmusic/domain/playback_state.dart';
import 'package:bangmusic/domain/queue.dart';
import 'package:bangmusic/main.dart';
import 'package:bangmusic/platform/player_port.dart';
import 'package:bangmusic/platform/secure_store.dart';
import 'package:bangmusic/platform/transfer_port.dart';
import 'package:bangmusic/ui/app_state.dart';
import 'package:bangmusic/ui/scope.dart';
import 'package:bangmusic/ui/screens/browse_screens.dart';
import 'package:bangmusic/ui/screens/connect_screen.dart';
import 'package:bangmusic/ui/screens/download_screens.dart';
import 'package:bangmusic/ui/screens/player_screens.dart';
import 'package:bangmusic/ui/screens/purchase_screen.dart';
import 'package:bangmusic/ui/screens/settings_screen.dart';
import 'package:bangmusic/ui/shell.dart';
import 'package:bangmusic/ui/tokens.dart';
import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui/fakes.dart';

const outDir = '../docs/status/evidence/p5-gallery';
final _index = <String>[];

Future<void> _loadFonts() async {
  final flutterRoot = File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path; // …/flutter/bin/cache/dart-sdk/bin/dart(.exe)
  Future<void> load(String family, String path) async {
    final f = File(path);
    if (!f.existsSync()) return;
    final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    await loader.load();
  }

  const noto = r'C:\Windows\Fonts\NotoSansKR-VF.ttf';
  for (final family in ['Roboto', 'NotoSansKR', '.SF UI Text']) {
    await load(family, noto);
  }
  await load('MaterialIcons', '$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf');
}

class Snap {
  Snap(this.t);
  final WidgetTester t;
  final key = GlobalKey();

  /// 360×780dp 휴대폰 (가로면 780×360), 글자 배율
  Future<void> show(Widget app, {bool landscape = false, double textScale = 1, Brightness brightness = Brightness.light}) async {
    // flutter_test는 그림자를 검은 실선으로 그린다(debugDisableShadows). 실제 모양을 보려고 끈다 — reset()에서 되돌린다
    debugDisableShadows = false;
    t.view.devicePixelRatio = 3;
    t.view.physicalSize = landscape ? const Size(2340, 1080) : const Size(1080, 2340);
    t.platformDispatcher.textScaleFactorTestValue = textScale;
    t.platformDispatcher.platformBrightnessTestValue = brightness;
    // 장면마다 새 키 — 앞 장면의 스크롤 위치·상태를 이어받지 않게
    await t.pumpWidget(RepaintBoundary(key: key, child: KeyedSubtree(key: UniqueKey(), child: app)));
    await settle();
  }

  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> save(String name, String screen, String state) async {
    await settle();
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await t.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 0.5 * t.view.devicePixelRatio); // 1.5배 = 540×1170
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final f = File('$outDir/$name.png')..createSync(recursive: true);
      f.writeAsBytesSync(png!.buffer.asUint8List());
    });
    _index.add('| $screen | $state | ![$name]($name.png) |');
  }

  void reset() {
    debugDisableShadows = true;
    t.view.reset();
    t.platformDispatcher.clearTextScaleFactorTestValue();
    t.platformDispatcher.clearPlatformBrightnessTestValue();
  }
}

const profile = ServerProfile(serverId: 'srv_T', baseUrl: 'https://music.example.net', serverName: '우리집 음악', userId: 'usr_1', username: 'siwon', displayName: '시원', installationId: 'i');

(AppState, FakePlayer, FakeServer) makeApp({FakeServer? server, LibraryStore? library, DownloadEngine? downloads}) {
  final s = server ?? FakeServer();
  final dio = Dio(BaseOptions(baseUrl: 'http://fake/v1'))..httpClientAdapter = s;
  final client = ApiClient(profile: profile, vault: TokenVault(MemorySecureStore()), tokens: Tokens('bma_x', DateTime(2030), 'bmr_x'), dio: dio);
  final player = FakePlayer();
  final app = AppState(player: player, store: MemorySecureStore())..debugActivate(profile, client, library: library, downloads: downloads);
  return (app, player, s);
}

Widget wrap(AppState app, Widget home, {Brightness brightness = Brightness.light}) => AppScope(
      state: app,
      child: MaterialApp(debugShowCheckedModeBanner: false, theme: buildTheme(Brightness.light), darkTheme: buildTheme(Brightness.dark), themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light, home: home),
    );

Map<String, Object?> trk(String id, String title, {String? albumId, String? album, int no = 1, String state = 'available', List<String> lyrics = const []}) =>
    {...track(id, title, albumId: albumId, album: album, no: no, state: state), 'has_lyrics': lyrics};

FakeServer catalog() {
  final s = FakeServer();
  final tracks = [
    trk('trk_1', '夜明けのうた', albumId: 'alb_1', album: '合成アルバム', no: 1, lyrics: ['original', 'pronunciation_ko', 'translation_ko']),
    trk('trk_2', '光の中へ', albumId: 'alb_1', album: '合成アルバム', no: 2),
    trk('trk_3', '새벽 공기', albumId: 'alb_1', album: '合成アルバム', no: 3),
    trk('trk_4', '静かな夜', albumId: 'alb_1', album: '合成アルバム', no: 4),
  ];
  s.json('GET /home', {
    'playlists': [playlist('pl_1', '드라이브', count: 12), playlist('pl_2', '잠들기 전', count: 8)],
    'recent_tracks': tracks,
    'top_tracks': tracks,
    'recently_added_albums': [album('alb_1', '合成アルバム', count: 4), album('alb_2', '한글 앨범'), album('alb_3', '형식 모음', count: 9)],
  });
  s.json('GET /albums', page([album('alb_1', '合成アルバム', count: 4), album('alb_2', '한글 앨범'), album('alb_3', '형식 모음', count: 9), album('alb_4', '길이 모음', count: 4)]));
  s.json('GET /albums/alb_1', {...album('alb_1', '合成アルバム', count: 4), 'tracks': tracks});
  s.json('GET /tracks', page(tracks));
  s.json('GET /artists', page([{'id': 'art_1', 'name': '합성 악단', 'album_count': 3, 'track_count': 17}, {'id': 'art_2', 'name': 'テスト楽団', 'album_count': 1, 'track_count': 4}]));
  s.json('GET /playlists', page([playlist('pl_1', '드라이브', count: 12), playlist('pl_2', '잠들기 전', count: 8)]));
  s.json('GET /playlists/pl_1', playlist('pl_1', '드라이브', count: 3, version: 4));
  s.json('GET /playlists/pl_1/items', {
    'items': [
      {'item_id': 'pli_1', 'available': true, 'track': tracks[0], 'added_at': '2026-10-03T00:00:00Z'},
      {'item_id': 'pli_2', 'available': false, 'added_at': '2026-10-03T00:00:00Z'},
      {'item_id': 'pli_3', 'available': true, 'track': tracks[2], 'added_at': '2026-10-03T00:00:00Z'},
    ],
    'next_cursor': null,
    'version': 4,
  });
  s.json('GET /tracks/trk_1/lyrics', {
    'track_id': 'trk_1', 'version': 1, 'offset_ms': 0,
    'variants': [
      {'kind': 'original', 'language': 'ja', 'synced': true, 'lines': [{'t_ms': 0, 'text': '夜明けの1番目のことば'}, {'t_ms': 4000, 'text': '夜明けの2番目のことば'}, {'t_ms': 8000, 'text': '夜明けの3番目のことば'}], 'source': {'type': 'sidecar', 'name': '서버의 .lrc 파일', 'license_note': null}},
      {'kind': 'pronunciation_ko', 'language': 'ko', 'synced': true, 'lines': [{'t_ms': 0, 'text': '요아케노 이치반메노 코토바'}, {'t_ms': 4000, 'text': '요아케노 니반메노 코토바'}, {'t_ms': 8000, 'text': '요아케노 산반메노 코토바'}], 'source': {'type': 'generated', 'name': '자동 생성 (형태소 분석, 오프라인)', 'license_note': null}},
      {'kind': 'translation_ko', 'language': 'ko', 'synced': true, 'lines': [{'t_ms': 0, 'text': '새벽의 첫 번째 말'}, {'t_ms': 4000, 'text': '새벽의 두 번째 말'}, {'t_ms': 8000, 'text': '새벽의 세 번째 말'}], 'source': {'type': 'sidecar', 'name': '서버의 .ko.lrc 파일', 'license_note': null}},
    ],
  });
  s.json('GET /tracks/trk_2/lyrics', {'track_id': 'trk_2', 'version': 0, 'offset_ms': 0, 'variants': <Object>[]});
  s.json('GET /tracks/trk_3/lyrics', {
    'track_id': 'trk_3', 'version': 1, 'offset_ms': 0,
    'variants': [
      {'kind': 'original', 'language': 'ko', 'synced': false, 'lines': [{'t_ms': null, 'text': '새벽 공기의 첫 줄'}, {'t_ms': null, 'text': '새벽 공기의 둘째 줄'}], 'source': {'type': 'embedded', 'name': null, 'license_note': '음원 태그'}},
    ],
  });
  s.on('GET /search', (o) => {
        'query_normalized': o.queryParameters['q'],
        'tracks': page(tracks.take(3).toList()),
        'albums': page([album('alb_1', '合成アルバム', count: 4)]),
        'artists': page([{'id': 'art_2', 'name': 'テスト楽団'}]),
        'playlists': page([playlist('pl_1', '드라이브', count: 12)]),
      });
  return s;
}

Map<String, Object?> problem(int status, String code) => {'type': 'about:blank', 'title': code, 'status': status, 'code': code, 'request_id': 'req_01TEST'};

Future<void> playQueue(FakePlayer p) async {
  final s = catalog();
  final tracks = [for (final t in (s.routes['GET /tracks']!(RequestOptions()) as Map)['items'] as List) Track.fromJson((t as Map).cast())];
  await p.playTracks(tracks, context: const QueueContext(ContextType.album, 'alb_1', '合成アルバム'));
  p.status.value = PlaybackStatus.playing;
  p.nowSource.value = const NowSource(null, localFormat: 'flac');
}

DownloadEngine engineFor(LibraryStore store) => DownloadEngine(store: store, transfer: HttpTransfer(), conditions: _NoConditions(), accept: const []);

class _NoConditions implements DeviceConditions {
  @override
  Future<({bool online, bool wifi})> network() async => (online: true, wifi: true);
  @override
  Stream<void> get changes => const Stream.empty();
  @override
  Future<int?> freeBytes(Directory dir) async => 30 * 1024 * 1024 * 1024;
}

List<Download> sampleDownloads() => [
      const Download(id: 'd1', trackId: 'trk_1', quality: 'original', state: DlState.downloading, bytesTotal: 6000000, bytesDone: 3720000),
      const Download(id: 'd2', trackId: 'trk_2', quality: 'original', state: DlState.preparing),
      const Download(id: 'd3', trackId: 'trk_3', quality: 'original', state: DlState.waitingWifi),
      const Download(id: 'd4', trackId: 'trk_4', quality: 'original', state: DlState.failed, errorCode: 'integrity_mismatch'),
      const Download(id: 'd5', trackId: 'trk_5', quality: 'original', state: DlState.completed, bytesTotal: 4200000, fileName: 'x', stale: true),
      const Download(id: 'd6', trackId: 'trk_6', quality: 'original', state: DlState.completed, bytesTotal: 734000, fileName: 'y'),
      const Download(id: 'd7', trackId: 'trk_7', quality: 'original', state: DlState.waitingSpace, bytesTotal: 5000000),
    ];

Future<LibraryStore> seededStore(WidgetTester t, Directory dir) async {
  final store = (await t.runAsync(() => LibraryStore.openForTest(dir)))!;
  final s = catalog();
  await t.runAsync(() async {
    await store.putAlbum(AlbumDetail.fromJson(s.routes['GET /albums/alb_1']!(RequestOptions()) as Map<String, dynamic>));
    await store.putTracks([
      for (final (id, title) in [('trk_5', '형식 flac-24'), ('trk_6', '라이브러리2 곡 1'), ('trk_7', '길이 300초')]) Track.fromJson(trk(id, title)),
    ]);
    for (final id in ['trk_1', 'trk_2']) {
      final r = await store.request(id, 'original', RequestKind.album, 'alb_1', newId: () => 'dl_$id');
      await store.saveDownload(r.download.copyWith(state: DlState.completed, fileName: '$id.flac', bytesTotal: 700000, renditionId: 'ren_$id', mediaVersion: 'v1'));
    }
  });
  return store;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await _loadFonts();
    final d = Directory(outDir);
    if (d.existsSync()) d.deleteSync(recursive: true);
  });
  tearDownAll(() {
    File('$outDir/index.md').writeAsStringSync([
      '# P5 화면×상태 갤러리',
      '',
      '생성: `flutter test --tags screenshots test/screenshots/gallery_test.dart` (가짜 서버·가짜 플레이어, 360×780dp, 1.5배 저장). 수준 L1.',
      '',
      '| 화면 | 상태 | 그림 |',
      '| --- | --- | --- |',
      ..._index,
    ].join('\n'));
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── S1 ───────────────────────────────────────────────
  Future<void> connect(WidgetTester t, String name, String state, ProbeResult r, {String? address, double scale = 1, List<ServerProfile> saved = const []}) async {
    final snap = Snap(t);
    final app = AppState(player: FakePlayer(), store: MemorySecureStore())..profiles = saved;
    await snap.show(wrap(app, ConnectScreen(probe: (_) async => r)), textScale: scale);
    if (address != null) {
      await t.enterText(find.byType(TextField), address);
      await t.tap(find.text('서버 확인'));
    }
    await snap.save(name, 'S1 서버 연결', state);
    snap.reset();
  }

  ServerInfo info({bool setup = false, int minClient = 0, int minor = 0}) => ServerInfo(
        serverId: 'srv_T', name: '우리집 음악', product: ServerInfoProductEnum.bangmusicServer, version: '0.1.0',
        api: ServerInfoApi(major: 1, minor: minor), minClientApiMinor: minClient, features: const [], limits: const {}, setupRequired: setup);

  testWidgets('S1', (t) async {
    await connect(t, 's1-01-first', '첫 실행(빈 목록 = 이 화면)', ProbeOk(info(), 'https://music.example.net'));
    await connect(t, 's1-02-card', '서버 확인 카드 → 로그인', ProbeOk(info(), 'https://music.example.net'), address: 'music.example.net');
    await connect(t, 's1-03-unreachable', '오류: 연결 불가', ProbeFailed(ApiException(kind: ApiErrorKind.unreachable)), address: 'music.example.net');
    await connect(t, 's1-04-certificate', '오류: 인증서', ProbeFailed(ApiException(kind: ApiErrorKind.certificate)), address: 'music.example.net');
    await connect(t, 's1-05-not-bangmusic', '오류: BangMusic 서버 아님', ProbeFailed(ApiException(kind: ApiErrorKind.notBangmusic)), address: 'example.com');
    await connect(t, 's1-06-local-network', '오류: 로컬 네트워크 권한 없음', ProbeFailed(ApiException(kind: ApiErrorKind.localNetworkDenied)), address: '192.168.0.10:8080');
    await connect(t, 's1-07-setup', '오류: 초기 설정 필요', ProbeOk(info(setup: true), 'https://music.example.net'), address: 'music.example.net');
    await connect(t, 's1-08-server-old', '버전 불일치: 서버 낮음', ProbeIncompatible(Incompatibility.serverTooOld, info()), address: 'music.example.net');
    await connect(t, 's1-09-app-old', '버전 불일치: 앱 낮음', ProbeIncompatible(Incompatibility.appTooOld, info(minClient: 9)), address: 'music.example.net');
    await connect(t, 's1-10-saved', '등록된 서버 목록', ProbeOk(info(), 'x'),
        saved: [const ServerProfile(serverId: 'srv_B', baseUrl: 'http://192.168.1.173:8081', serverName: '두 번째 서버', userId: 'u', username: 'tester2', installationId: 'i')]);
    await connect(t, 's1-11-big-text', '큰 글씨 2.0', ProbeOk(info(), 'https://music.example.net'), address: 'music.example.net', scale: 2.0);

    // 로그인 실패: 5회 실패 후 대기 시간
    final snap = Snap(t);
    var app = AppState(player: FakePlayer(), store: MemorySecureStore());
    await snap.show(wrap(app, ConnectScreen(
      probe: (_) async => ProbeOk(info(), 'https://music.example.net'),
      signIn: (_, _, _) async => throw ApiException(kind: ApiErrorKind.server, status: 429, code: 'rate_limited', retryAfter: 300),
    )));
    await t.enterText(find.byType(TextField), 'music.example.net');
    await t.tap(find.text('서버 확인'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).at(0), 'siwon');
    await t.enterText(find.byType(TextField).at(1), 'password');
    await t.tap(find.text('로그인'));
    await snap.save('s1-12-login-failed', 'S1 서버 연결', '오류: 로그인 실패(5회 후 대기 시간)');
    // 오프라인 + 저장된 서버 → 오프라인으로 계속
    app = AppState(player: FakePlayer(), store: MemorySecureStore())
      ..profiles = [const ServerProfile(serverId: 'srv_B', baseUrl: 'http://192.168.1.173:8081', serverName: '두 번째 서버', userId: 'u', username: 'tester2', installationId: 'i')]
      ..deviceOnline = false;
    await snap.show(wrap(app, const ConnectScreen()));
    await snap.save('s1-13-offline', 'S1 서버 연결', '오프라인(저장된 서버는 오프라인으로 계속)');
    snap.reset();
  });

  // ── S2·공통 배너 ─────────────────────────────────────────
  testWidgets('S2', (t) async {
    final snap = Snap(t);
    var (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const Shell()));
    await snap.save('s2-01-home', 'S2 홈', '기본');
    await snap.show(wrap(app, const Shell(), brightness: Brightness.dark), brightness: Brightness.dark);
    await snap.save('s2-02-home-dark', 'S2 홈', '다크 테마');
    (app, _, _) = makeApp(server: FakeServer()..json('GET /home', {'playlists': <Object>[], 'recent_tracks': <Object>[], 'top_tracks': <Object>[], 'recently_added_albums': <Object>[]}));
    await snap.show(wrap(app, const Shell()));
    await snap.save('s2-03-empty', 'S2 홈', '빈 목록(서버에 음악 없음)');
    (app, _, _) = makeApp(server: FakeServer()..on('GET /home', (_) => (500, problem(500, 'internal'))));
    await snap.show(wrap(app, const Shell()));
    await snap.save('s2-04-error', 'S2 홈', '오류');
    (app, _, _) = makeApp(server: catalog()..json('GET /home', {'playlists': <Object>[], 'recent_tracks': <Object>[], 'top_tracks': <Object>[], 'recently_added_albums': [album('alb_1', '合成アルバム', count: 4)]}));
    await snap.show(wrap(app, const Shell()));
    await snap.save('s2-07-first-playlist', 'S2 홈', '빈 목록: 플레이리스트 없음("첫 플레이리스트 만들기")');
    (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const Shell()), textScale: 2.0);
    await snap.save('s2-05-big-text', 'S2 홈', '큰 글씨 2.0');
    snap.reset();
  });

  testWidgets('공통 배너·전체 화면', (t) async {
    final snap = Snap(t);
    var (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const Shell()));
    app.api!.status.value = SessionStatus.expired;
    await snap.save('c-01-expired', '공통', '세션 만료 배너');
    (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const Shell()));
    app.api!.reachable.value = false;
    await snap.save('c-02-unreachable', '공통', '서버 연결 불가 배너');
    (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const Shell()));
    app.debugSetDeviceOnline(false);
    await snap.save('c-03-offline', '공통', '오프라인 배너');
    (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const Shell()));
    app.api!.serverNotice.value = 'maintenance';
    await snap.save('c-04-maintenance', '공통', '서버 점검 배너');
    (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const Shell()));
    app.api!.serverNotice.value = 'client_too_old';
    await snap.save('c-05-update', '공통', '앱 업데이트 필요 배너');
    (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const Shell()));
    app.api!.serverChanged.value = true;
    await snap.save('c-06-server-changed', '공통', '같은 주소 다른 서버 배너');
    (app, _, _) = makeApp(server: catalog());
    await snap.show(AppScope(state: app, child: const BangMusicApp()));
    app.api!.status.value = SessionStatus.revoked;
    await snap.save('c-07-revoked', '공통', '접근 취소 전체 화면');
    snap.reset();
  });

  // ── S3·S4 ───────────────────────────────────────────
  testWidgets('S3', (t) async {
    final snap = Snap(t);
    var (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const LibraryScreen()));
    await snap.save('s3-01-albums', 'S3 라이브러리', '앨범 2열 격자');
    await t.tap(find.text('곡'));
    await snap.save('s3-02-tracks', 'S3 라이브러리', '곡 목록');
    await t.tap(find.text('아티스트'));
    await snap.save('s3-03-artists', 'S3 라이브러리', '아티스트');
    (app, _, _) = makeApp(server: FakeServer()..json('GET /albums', page([]))..json('GET /playlists', page([])));
    await snap.show(wrap(app, const LibraryScreen()));
    await t.tap(find.text('플레이리스트'));
    await snap.save('s3-04-empty', 'S3 라이브러리', '빈 목록(+ 새 플레이리스트)');
    (app, _, _) = makeApp(server: FakeServer()..on('GET /albums', (_) => (500, problem(500, 'internal'))));
    await snap.show(wrap(app, const LibraryScreen()));
    await snap.save('s3-05-error', 'S3 라이브러리', '오류(첫 페이지)');
    (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const LibraryScreen()), textScale: 2.0);
    await snap.save('s3-06-big-text', 'S3 라이브러리', '큰 글씨 2.0(격자 → 1열)');
    snap.reset();
  });

  testWidgets('S3 오프라인·S4 오프라인', (t) async {
    final dir = (await t.runAsync(() => Directory.systemTemp.createTemp('bm_gallery')))!;
    final store = await seededStore(t, dir);
    final engine = engineFor(store);
    engine.rows.value = (await t.runAsync(store.downloads))!;
    final snap = Snap(t);
    final (app, player, _) = makeApp(server: catalog(), library: store, downloads: engine);
    app.debugSetDeviceOnline(false);
    await snap.show(wrap(app, const LibraryScreen()));
    await snap.save('s3-07-offline', 'S3 라이브러리', '오프라인("다운로드한 항목만" 자동)');
    await snap.show(wrap(app, const Shell()));
    await snap.save('s2-06-offline', 'S2 홈', '오프라인(받은 음악)');
    await snap.show(wrap(app, const SearchScreen()));
    await t.enterText(find.byType(TextField), 'よあけ');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await snap.save('s4-05-offline', 'S4 검색', '오프라인(로컬 검색)');
    await snap.show(wrap(app, const AlbumScreen(albumId: 'alb_1', title: '合成アルバム')));
    await snap.save('s5-03-offline', 'S5 앨범', '오프라인(다운로드한 n곡 재생)');
    // 받은 곡(trk_1·2)을 오프라인에서 재생 중, 대기열의 trk_3·4는 받지 않음
    await playQueue(player);
    await snap.show(wrap(app, const Shell()));
    await snap.save('s7-06-offline', 'S7 미니 플레이어', '오프라인(받은 곡 재생 중 아이콘)');
    await snap.show(wrap(app, const NowPlayingScreen()));
    await t.tap(find.text('대기열'));
    await snap.save('s8-12-offline-queue', 'S8 몰입 화면', '오프라인(받지 않은 곡 흐림 + 오프라인에서 건너뜀)');
    snap.reset();
    await t.runAsync(() async {
      await store.close();
      await dir.delete(recursive: true);
    });
  });

  // ── P5 매트릭스 △ 보충: 정착 전 상태(로딩)와 드문 조건 ─────────────
  testWidgets('보충 상태', (t) async {
    final snap = Snap(t);
    // S2 로딩: 응답을 붙잡아 둔다
    final hold = Completer<Object>();
    var (app, player, _) = makeApp(server: FakeServer()..on('GET /home', (_) => hold.future));
    await snap.show(wrap(app, const Shell()));
    await snap.save('s2-08-loading', 'S2 홈', '로딩(자리표시자)');
    hold.complete({'playlists': <Object>[], 'recent_tracks': <Object>[], 'top_tracks': <Object>[], 'recently_added_albums': <Object>[]});

    // S3 다음 페이지 실패
    final paging = FakeServer()
      ..json('GET /albums', page([]))
      ..on('GET /tracks', (o) => o.queryParameters['cursor'] == null
          ? page([for (var i = 0; i < 14; i++) trk('trk_p$i', '앞쪽 곡 ${i + 1}')], 'CUR1')
          : (500, problem(500, 'internal')));
    (app, player, _) = makeApp(server: paging);
    await snap.show(wrap(app, const LibraryScreen()));
    await t.tap(find.text('곡'));
    await snap.settle();
    await t.drag(find.byType(Scrollable).last, const Offset(0, -3000));
    await snap.save('s3-08-next-page-error', 'S3 라이브러리', '오류: 다음 페이지 실패(목록 끝 다시 시도)');

    // S4 로딩: 이전 결과를 흐리게 유지
    final slow = Completer<Object>();
    final search = catalog();
    final first = search.routes['GET /search']!;
    search.on('GET /search', (o) => o.queryParameters['q'] == '夜明けの' ? slow.future : first(o));
    (app, player, _) = makeApp(server: search);
    await snap.show(wrap(app, const SearchScreen()));
    await t.enterText(find.byType(TextField), '夜明け');
    await snap.settle();
    await t.enterText(find.byType(TextField), '夜明けの');
    await snap.save('s4-07-loading', 'S4 검색', '로딩(이전 결과 흐리게)');
    slow.complete(first(RequestOptions(queryParameters: {'q': '夜明けの'})));

    // S8 대기열 빈 목록: 곡 하나만
    (app, player, _) = makeApp(server: catalog());
    await player.playTracks([Track.fromJson(trk('trk_1', '夜明けのうた', albumId: 'alb_1', album: '合成アルバム'))], context: const QueueContext(ContextType.adhoc));
    player.status.value = PlaybackStatus.playing;
    await snap.show(wrap(app, const NowPlayingScreen()));
    await t.tap(find.text('대기열'));
    await snap.save('s8-11-queue-empty', 'S8 몰입 화면', '빈 목록: 대기열(이어서 재생할 곡 없음)');

    // S10 세션 목록: 로딩 · 이 기기만 · 오류
    final sess = Completer<Object>();
    (app, player, _) = makeApp(server: FakeServer()..on('GET /sessions', (_) => sess.future));
    await snap.show(wrap(app, const SessionsScreen()));
    await snap.save('s10-07-sessions-loading', 'S10 설정', '세션 목록 로딩');
    sess.complete({'items': [{'id': 'ses_1', 'device_name': 'Galaxy S26', 'platform': 'android', 'app_version': '0.1.0', 'created_at': '2026-10-01T00:00:00Z', 'last_seen_at': '2026-10-04T08:00:00Z', 'current': true}]});
    await snap.save('s10-08-sessions-only-me', 'S10 설정', '세션 목록: 이 기기만("다른 기기 없음")');
    (app, player, _) = makeApp(server: FakeServer()..on('GET /sessions', (_) => (500, problem(500, 'internal'))));
    await snap.show(wrap(app, const SessionsScreen()));
    await snap.save('s10-09-sessions-error', 'S10 설정', '세션 목록 오류(다시 시도)');
    snap.reset();
  });

  testWidgets('S4', (t) async {
    final snap = Snap(t);
    SharedPreferences.setMockInitialValues({'search.recent': ['夜明け', '새벽', 'ガラス']});
    var (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const SearchScreen()));
    await snap.save('s4-01-recent', 'S4 검색', '입력 전(최근 검색어)');
    await t.enterText(find.byType(TextField), '夜明け');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await snap.save('s4-02-results', 'S4 검색', '결과');
    (app, _, _) = makeApp(server: FakeServer()..json('GET /search', {'query_normalized': 'zz', 'tracks': page([]), 'albums': page([]), 'artists': page([]), 'playlists': page([])}));
    await snap.show(wrap(app, const SearchScreen()));
    await t.enterText(find.byType(TextField), 'zz');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await snap.save('s4-03-empty', 'S4 검색', '빈 목록');
    (app, _, _) = makeApp(server: FakeServer()..on('GET /search', (_) => (500, problem(500, 'internal'))));
    await snap.show(wrap(app, const SearchScreen()));
    await t.enterText(find.byType(TextField), 'x');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await snap.save('s4-04-error', 'S4 검색', '오류');
    (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const SearchScreen()), textScale: 2.0);
    await t.enterText(find.byType(TextField), '夜明け');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await snap.save('s4-06-big-text', 'S4 검색', '큰 글씨 2.0');
    snap.reset();
  });

  // ── S5·S6 ───────────────────────────────────────────
  testWidgets('S5 S6', (t) async {
    final snap = Snap(t);
    var (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const AlbumScreen(albumId: 'alb_1', title: '合成アルバム')));
    await snap.save('s5-01-album', 'S5 앨범', '기본');
    (app, _, _) = makeApp(server: FakeServer()..on('GET /albums/alb_x', (_) => (404, problem(404, 'not_found'))));
    await snap.show(wrap(app, const AlbumScreen(albumId: 'alb_x', title: '사라진 앨범')));
    await snap.save('s5-02-404', 'S5 앨범', '오류 404');
    (app, _, _) = makeApp(server: catalog());
    app.api!.status.value = SessionStatus.expired;
    await snap.show(wrap(app, const AlbumScreen(albumId: 'alb_1', title: '合成アルバム')));
    await snap.save('s5-04-expired', 'S5 앨범', '세션 만료(다운로드 버튼 없음)');
    (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const AlbumScreen(albumId: 'alb_1', title: '合成アルバム')), textScale: 2.0);
    await snap.save('s5-05-big-text', 'S5 앨범', '큰 글씨 2.0');

    final pl = Playlist.fromJson(playlist('pl_1', '드라이브', count: 3, version: 4));
    (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, PlaylistScreen(playlist: pl)));
    await snap.save('s6-01-playlist', 'S6 플레이리스트', '기본(재생할 수 없는 곡 포함)');
    await t.scrollUntilVisible(find.text('편집'), 200);
    await t.tap(find.text('편집'));
    await snap.save('s6-02-edit', 'S6 플레이리스트', '편집 모드');
    (app, _, _) = makeApp(server: FakeServer()..json('GET /playlists/pl_9', playlist('pl_9', '빈 목록'))..json('GET /playlists/pl_9/items', {...page([]), 'version': 1}));
    await snap.show(wrap(app, PlaylistScreen(playlist: Playlist.fromJson(playlist('pl_9', '빈 목록')))));
    await snap.save('s6-03-empty', 'S6 플레이리스트', '빈 목록');
    final conflict = catalog()..on('POST /playlists/pl_1/edits', (_) => (412, problem(412, 'version_conflict')));
    (app, _, _) = makeApp(server: conflict);
    await snap.show(wrap(app, PlaylistScreen(playlist: pl)));
    await t.scrollUntilVisible(find.text('편집'), 200);
    await t.tap(find.text('편집'));
    await snap.settle();
    await t.scrollUntilVisible(find.byTooltip('夜明けのうた 빼기'), 200);
    await t.tap(find.byTooltip('夜明けのうた 빼기'));
    await snap.save('s6-04-conflict', 'S6 플레이리스트', '충돌(다른 기기에서 변경)');
    snap.reset();
  });

  // ── S7·S8 ───────────────────────────────────────────
  testWidgets('S7 S8', (t) async {
    final snap = Snap(t);
    var (app, player, _) = makeApp(server: catalog());
    await playQueue(player);
    await snap.show(wrap(app, const Shell()));
    await snap.save('s7-01-mini', 'S7 미니 플레이어', '재생 중(다운로드본)');
    player.status.value = PlaybackStatus.loading;
    player.nowSource.value = const NowSource(null, preparing: true);
    await snap.save('s7-02-preparing', 'S7 미니 플레이어', '로딩·서버에서 준비 중');
    player.status.value = PlaybackStatus.error;
    player.errorMessage.value = '서버의 음악 저장소에 연결할 수 없습니다';
    await snap.save('s7-03-error', 'S7 미니 플레이어', '오류');
    player.errorMessage.value = null;
    player.status.value = PlaybackStatus.playing;
    player.nowSource.value = const NowSource(null, localFormat: 'flac');
    await snap.show(wrap(app, const Shell()), textScale: 1.6);
    await snap.save('s7-04-big-text', 'S7 미니 플레이어', '큰 글씨 1.6(아티스트 줄 숨김)');

    await snap.show(wrap(app, const NowPlayingScreen()));
    await snap.save('s8-01-lp', 'S8 몰입 화면', 'LP');
    await t.tap(find.text('가사'));
    await snap.save('s8-02-lyrics', 'S8 몰입 화면', '3단 가사');
    await t.tap(find.text('대기열'));
    await snap.save('s8-03-queue', 'S8 몰입 화면', '대기열');
    await t.tap(find.text('LP'));
    player.status.value = PlaybackStatus.error;
    player.errorMessage.value = '서버에 파일이 없습니다';
    await snap.save('s8-04-error', 'S8 몰입 화면', '오류(사유 + 다음 곡)');
    player.errorMessage.value = null;
    player.status.value = PlaybackStatus.playing;
    await player.skipToNext(); // 가사 없는 곡
    await snap.show(wrap(app, const NowPlayingScreen()));
    await t.tap(find.text('가사'));
    await snap.save('s8-05-no-lyrics', 'S8 몰입 화면', '빈 목록: 가사 없음');
    await player.skipToNext(); // 원문만 있는 곡: 발음·번역 칩 비활성, 끝에 출처
    await snap.show(wrap(app, const NowPlayingScreen()));
    await t.tap(find.text('가사'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilterChip, '발음'));
    await snap.save('s8-09-lyrics-source', 'S8 몰입 화면', '발음 없음(칩 비활성 + 이유) · 가사 출처 표기');
    await player.skipToPrevious();
    await player.skipToPrevious();
    player.status.value = PlaybackStatus.loading;
    player.nowSource.value = const NowSource(null, preparing: true);
    await snap.show(wrap(app, const NowPlayingScreen()));
    await snap.save('s8-10-preparing', 'S8 몰입 화면', '로딩: 서버에서 재생용 파일 준비 중');
    player.status.value = PlaybackStatus.playing;
    player.nowSource.value = const NowSource(null, localFormat: 'flac');
    await snap.show(wrap(app, const NowPlayingScreen()), landscape: true);
    await snap.save('s8-06-landscape', 'S8 몰입 화면', '가로 화면(LP·제어 | 가사)');
    await snap.show(wrap(app, const NowPlayingScreen()), textScale: 2.0);
    await snap.save('s8-07-big-text', 'S8 몰입 화면', '큰 글씨 2.0');
    await snap.show(wrap(app, const NowPlayingScreen(), brightness: Brightness.dark), brightness: Brightness.dark);
    await snap.save('s8-08-dark', 'S8 몰입 화면', '다크 테마');
    (app, player, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const Shell()));
    await snap.save('s7-05-empty', 'S7 미니 플레이어', '대기열 없음(숨김)');
    snap.reset();
  });

  // ── S9 ─────────────────────────────────────────────
  testWidgets('S9', (t) async {
    final dir = (await t.runAsync(() => Directory.systemTemp.createTemp('bm_gallery9')))!;
    final store = (await t.runAsync(() => LibraryStore.openForTest(dir)))!;
    await t.runAsync(() => store.putTracks([
          for (final (id, title) in [('trk_1', '夜明けのうた'), ('trk_2', '光の中へ'), ('trk_3', '새벽 공기'), ('trk_4', '静かな夜'), ('trk_5', '형식 flac-24'), ('trk_6', '라이브러리2 곡 1'), ('trk_7', '길이 300초')])
            Track.fromJson(trk(id, title)),
        ]));
    final engine = engineFor(store);
    final snap = Snap(t);
    var (app, _, _) = makeApp(server: catalog(), library: store, downloads: engine);
    await snap.show(wrap(app, const DownloadsScreen()));
    await snap.save('s9-01-empty', 'S9 다운로드', '빈 목록');
    engine.rows.value = sampleDownloads();
    await snap.settle();
    await snap.save('s9-02-states', 'S9 다운로드', '진행 중·확인 필요·완료 (상태 문구 1:1)');
    engine.rows.value = [for (final d in sampleDownloads()) d.state == DlState.completed ? d : d.copyWith(state: DlState.waitingLogin)];
    await snap.save('s9-03-expired', 'S9 다운로드', '세션 만료(로그인 필요)');
    engine.rows.value = [for (final d in sampleDownloads()) d.copyWith(locked: true)];
    await snap.save('s9-04-revoked', 'S9 다운로드', '접근 취소(잠김)');
    engine.rows.value = [for (final d in sampleDownloads()) d.state == DlState.completed ? d : d.copyWith(state: DlState.waitingNetwork)];
    await snap.save('s9-05-offline', 'S9 다운로드', '오프라인(네트워크 연결 대기)');
    engine.rows.value = sampleDownloads();
    await snap.show(wrap(app, const DownloadsScreen()), textScale: 2.0);
    await snap.save('s9-06-big-text', 'S9 다운로드', '큰 글씨 2.0(버튼 다음 줄)');
    snap.reset();
    await t.runAsync(() async {
      await store.close();
      await dir.delete(recursive: true);
    });
  });

  // ── S10·S11 ────────────────────────────────────────
  testWidgets('S10 S11', (t) async {
    final snap = Snap(t);
    var (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const SettingsScreen()));
    await snap.save('s10-01-settings', 'S10 설정', '기본(서버 구획)');
    await t.scrollUntilVisible(find.text('개인정보'), 500);
    await snap.save('s10-02-settings-more', 'S10 설정', '재생·가사·화면·개인정보');
    (app, _, _) = makeApp(server: catalog());
    app.api!.reachable.value = false;
    await snap.show(wrap(app, const SettingsScreen()));
    await snap.save('s10-03-offline', 'S10 설정', '오프라인(서버 항목 비활성)');
    (app, _, _) = makeApp(server: catalog());
    app.api!.status.value = SessionStatus.expired;
    await snap.show(wrap(app, const SettingsScreen()));
    await snap.save('s10-04-expired', 'S10 설정', '세션 만료(다시 로그인)');
    await t.tap(find.text('다시 로그인'));
    await snap.save('s10-05-relogin', 'S10 설정', '재로그인 시트(서버 고정)');
    (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const SettingsScreen()), textScale: 2.0);
    await snap.save('s10-06-big-text', 'S10 설정', '큰 글씨 2.0');
    (app, _, _) = makeApp(server: catalog());
    await snap.show(wrap(app, const PurchaseScreen()));
    await snap.save('s11-01-purchase', 'S11 구매', '판매 방식 미정(구매 버튼 비활성)');
    await t.tap(find.text('구매 복원'));
    await snap.save('s11-02-restore', 'S11 구매', '복원 결과(스토어 연결 불가)');
    (app, _, _) = makeApp(server: catalog());
    app.debugSetDeviceOnline(false);
    await snap.show(wrap(app, const PurchaseScreen()));
    await snap.save('s11-03-offline', 'S11 구매', '오프라인');
    snap.reset();
  });
}
