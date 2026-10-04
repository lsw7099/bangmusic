// 다운로드 엔진 (03장 §5.3~5.9). 가짜 API(FakeServer) + 로컬 HTTP 미디어 서버(Range·ETag, 연결 끊기·Range 무시·410·401 주입)
// + 호스트 SQLite + HttpTransfer. 실제 서버 대상 FN-03은 download_real_server_test.dart (L1).
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:bangmusic/core/api_client.dart';
import 'package:bangmusic/core/session.dart';
import 'package:bangmusic/data/download_engine.dart';
import 'package:bangmusic/data/library_store.dart';
import 'package:bangmusic/domain/download_state.dart';
import 'package:bangmusic/platform/secure_store.dart';
import 'package:bangmusic/platform/transfer_port.dart';
import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ui/fakes.dart' as f;

/// Range·ETag를 지원하는 미디어 서버. 장애를 한 번씩 주입할 수 있다.
class MediaServer {
  late HttpServer http;
  final files = <String, List<int>>{};
  final etags = <String, String>{};
  final ranges = <String?>[];
  int? dropAfter;

  /// dropAfter 바이트를 보낸 뒤 끊지 않고 멈춘다 (조용히 죽은 연결)
  bool stall = false;
  final _held = <Socket>[];
  bool ignoreRange = false;
  int? forceStatus;
  int requests = 0;

  /// 응답을 이만큼 늦춘다 (전송 중 상태를 관찰하려고)
  Duration delay = Duration.zero;

  Future<void> close() async {
    for (final s in _held) {
      s.destroy();
    }
    await http.close(force: true);
  }

  Future<void> start() async {
    http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    http.listen(_handle);
  }

  String get base => 'http://127.0.0.1:${http.port}';

  Future<void> _handle(HttpRequest req) async {
    requests++;
    final path = req.uri.path;
    ranges.add(req.headers.value('range'));
    final res = req.response;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (forceStatus != null) {
      res.statusCode = forceStatus!;
      forceStatus = null;
      await res.close();
      return;
    }
    final bytes = files[path];
    if (bytes == null || req.uri.queryParameters['mt'] == null) {
      res.statusCode = 404;
      await res.close();
      return;
    }
    var start = 0;
    final range = req.headers.value('range');
    final ifRange = req.headers.value('if-range');
    if (range != null && !ignoreRange && (ifRange == null || ifRange == etags[path])) {
      start = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
      res.statusCode = 206;
      res.headers.set('content-range', 'bytes $start-${bytes.length - 1}/${bytes.length}');
    }
    res.headers.set('etag', etags[path] ?? '"e"');
    res.contentLength = bytes.length - start;
    final body = bytes.sublist(start);
    if (dropAfter != null) {
      final n = dropAfter!;
      dropAfter = null;
      final socket = await res.detachSocket();
      socket.add(body.sublist(0, n));
      await socket.flush();
      if (stall) {
        stall = false;
        _held.add(socket);
        return;
      }
      await socket.close();
      return;
    }
    res.add(body);
    await res.close();
  }
}

class FakeConditions implements DeviceConditions {
  bool online = true;
  bool wifi = true;
  int? free = 50 * 1024 * 1024 * 1024;
  final _changes = StreamController<void>.broadcast();
  void changed() => _changes.add(null);
  @override
  Future<({bool online, bool wifi})> network() async => (online: online, wifi: wifi);
  @override
  Stream<void> get changes => _changes.stream;
  @override
  Future<int?> freeBytes(Directory dir) async => free;
}

/// 첫 시작에서는 절반을 쓰고 아무 소식도 주지 않는다(OS가 멈춘 작업을 잃은 패키지). 두 번째부터는 끝까지 쓴다.
class SilentTransfer implements TransferPort {
  SilentTransfer(this.bytes);
  final List<int> bytes;
  final starts = <int>[];
  final cancelled = <String>[];
  final _updates = StreamController<TransferUpdate>.broadcast();

  @override
  Stream<TransferUpdate> get updates => _updates.stream;

  @override
  Future<Set<String>> running() async => {};

  @override
  Future<void> cancel(String downloadId) async => cancelled.add(downloadId);

  @override
  Future<void> start({required String downloadId, required Uri url, required File part, required int fromByte, String? etag, required bool wifiOnly, String? title}) async {
    starts.add(fromByte);
    await part.parent.create(recursive: true);
    if (starts.length == 1) {
      await part.writeAsBytes(bytes.sublist(0, bytes.length ~/ 2));
      _updates.add(TransferProgress(downloadId, bytes.length ~/ 2));
      return;
    }
    await part.writeAsBytes(bytes);
    _updates.add(TransferProgress(downloadId, bytes.length));
    _updates.add(TransferComplete(downloadId));
  }
}

List<int> randomBytes(int n, int seed) {
  final r = Random(seed);
  return List.generate(n, (_) => r.nextInt(256));
}

void main() {
  late Directory dir;
  late LibraryStore store;
  late MediaServer media;
  late f.FakeServer api;
  late ApiClient client;
  late FakeConditions cond;
  late DownloadEngine engine;
  var now = DateTime.utc(2026, 10, 3, 12);
  var renditionCalls = 0;

  /// 렌디션 응답 상태 (테스트가 바꾼다)
  late Map<String, Map<String, Object?>> renditions;

  Map<String, Object?> rendition(String trackId, String rid, List<int> bytes, {String state = 'ready', String mv = 'v1', String? sha, bool nullSha = false}) {
    final path = '/media/$rid';
    media.files[path] = bytes;
    media.etags[path] = '"$rid-$mv"';
    return {
      'id': rid, 'track_id': trackId, 'media_version': mv, 'profile': 'original', 'state': state, 'mime': 'audio/flac', 'container': 'flac', 'codec': 'flac',
      'size_bytes': bytes.length, 'duration_ms': 1000, 'sha256': nullSha ? null : (sha ?? sha256.convert(bytes).toString()), 'etag': '"$rid-$mv"',
      'seekable': true, 'media_url': '$path?mt=ticket', 'ticket_expires_at': '2026-10-04T00:00:00Z', 'error_code': null, 'retry_after_s': state == 'preparing' ? 1 : null,
    };
  }

  DownloadEngine newEngine({TransferPort? transfer}) => DownloadEngine(
        store: store, transfer: transfer ?? HttpTransfer(idleTimeout: const Duration(seconds: 1)), conditions: cond, accept: [FormatSpec(container: 'flac', codec: 'flac')], clock: () => now,
      );

  setUp(() async {
    now = DateTime.utc(2026, 10, 3, 12);
    renditionCalls = 0;
    dir = await Directory.systemTemp.createTemp('bm_engine');
    store = await LibraryStore.openForTest(dir);
    media = MediaServer();
    await media.start();
    api = f.FakeServer();
    renditions = {};
    api.on('POST /tracks/trk_1/renditions', (_) {
      renditionCalls++;
      return renditions['trk_1']!;
    });
    api.on('POST /tracks/trk_2/renditions', (_) {
      renditionCalls++;
      return renditions['trk_2']!;
    });
    api.on('GET /renditions/ren_1', (_) => renditions['trk_1']!);
    api.json('GET /tracks/trk_1/lyrics', {'track_id': 'trk_1', 'version': 1, 'offset_ms': 0, 'variants': <Object>[]});
    api.json('GET /albums/alb_1', {...f.album('alb_1', '앨범'), 'tracks': [f.track('trk_1', '하나', albumId: 'alb_1'), f.track('trk_2', '둘', albumId: 'alb_1', no: 2)]});
    final dio = Dio(BaseOptions(baseUrl: '${media.base}/v1'))..httpClientAdapter = api;
    final profile = ServerProfile(serverId: 'srv_T', baseUrl: media.base, serverName: '시험', userId: 'usr_1', username: 'u', installationId: 'i');
    client = ApiClient(profile: profile, vault: TokenVault(MemorySecureStore()), tokens: Tokens('bma_x', DateTime(2030), 'bmr_x'), dio: dio);
    cond = FakeConditions();
    engine = newEngine();
  });

  tearDown(() async {
    await engine.dispose();
    await store.close();
    await media.close();
    await dir.delete(recursive: true);
  });

  Future<void> waitFor(bool Function() ok, {Duration timeout = const Duration(seconds: 10)}) async {
    final end = DateTime.now().add(timeout);
    while (!ok()) {
      if (DateTime.now().isAfter(end)) fail('시간 초과: ${engine.rows.value}');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    await engine.settle();
  }

  Download row(String trackId) => engine.rows.value.firstWhere((d) => d.trackId == trackId);
  bool isState(String trackId, DlState s) => engine.rows.value.any((d) => d.trackId == trackId && d.state == s);
  Track track(String id) => Track.fromJson(f.track(id, id, albumId: 'alb_1'));

  Future<void> retryNow() async {
    now = now.add(const Duration(hours: 1));
    engine.kick();
  }

  test('정상: 결정 → 받기 → 검증 → 완료본만 media/에, 가사 사본 저장 (§5.5, §5.6)', () async {
    final bytes = randomBytes(300000, 1);
    renditions['trk_1'] = rendition('trk_1', 'ren_1', bytes);
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => isState('trk_1', DlState.completed));
    final d = row('trk_1');
    expect(d.fileName, 'trk_1/ren_1.flac');
    expect(d.verified, Verified.full);
    final file = await engine.playableFile('trk_1');
    expect(sha256.convert(await file!.readAsBytes()).toString(), sha256.convert(bytes).toString());
    expect(await store.partFile(d.id).exists(), isFalse, reason: '.part는 옮겨졌다');
    await waitFor(() => true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(await store.lyrics('trk_1'), isNotNull);
    expect(api.requests.where((r) => r.startsWith('POST /tracks/trk_1/renditions')).length, 1);
  });

  test('FN-03 (모의 서버): 전송 중 연결이 끊긴 뒤 Range로 이어받아 SHA-256 일치', () async {
    final bytes = randomBytes(400000, 2);
    renditions['trk_1'] = rendition('trk_1', 'ren_1', bytes);
    media.dropAfter = 150000;
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => row('trk_1').state == DlState.queued && row('trk_1').errorCode == 'network');
    expect(row('trk_1').notBefore, now.add(retryBackoff.first));
    final kept = await store.partFile(row('trk_1').id).length();
    expect(kept, inInclusiveRange(1, 150000), reason: '받은 만큼 .part에 남는다');
    await retryNow();
    await waitFor(() => isState('trk_1', DlState.completed));
    expect(media.ranges.last, 'bytes=$kept-');
    final file = await engine.playableFile('trk_1');
    expect(sha256.convert(await file!.readAsBytes()).toString(), sha256.convert(bytes).toString());
  });

  test('조용히 멈춘 연결은 무응답 시간 초과로 끊고 이어받는다', () async {
    final bytes = randomBytes(200000, 24);
    renditions['trk_1'] = rendition('trk_1', 'ren_1', bytes);
    media.dropAfter = 60000;
    media.stall = true;
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => row('trk_1').errorCode == 'network');
    final kept = await store.partFile(row('trk_1').id).length();
    expect(kept, greaterThan(0));
    await retryNow();
    await waitFor(() => isState('trk_1', DlState.completed));
    expect(media.ranges.last, 'bytes=$kept-');
    expect(sha256.convert(await (await engine.playableFile('trk_1'))!.readAsBytes()).toString(), sha256.convert(bytes).toString());
  });

  test('서버가 Range를 무시하고 200을 주면 처음부터 다시 써서 완료 (§5.4)', () async {
    final bytes = randomBytes(200000, 3);
    renditions['trk_1'] = rendition('trk_1', 'ren_1', bytes);
    media.dropAfter = 50000;
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => row('trk_1').errorCode == 'network');
    media.ignoreRange = true;
    await retryNow();
    await waitFor(() => isState('trk_1', DlState.completed));
    final file = await engine.playableFile('trk_1');
    expect(await file!.length(), 200000);
    expect(sha256.convert(await file.readAsBytes()).toString(), sha256.convert(bytes).toString());
  });

  test('410 rendition_superseded: 옛 바이트를 버리고 새 렌디션으로 처음부터 (§5.4)', () async {
    final old = randomBytes(200000, 4);
    renditions['trk_1'] = rendition('trk_1', 'ren_1', old);
    media.dropAfter = 80000;
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => row('trk_1').errorCode == 'network');
    final fresh = randomBytes(150000, 5);
    renditions['trk_1'] = rendition('trk_1', 'ren_2', fresh, mv: 'v2');
    media.forceStatus = 410; // 옛 URL로 이어받기 시도 → 410
    await retryNow();
    await waitFor(() => isState('trk_1', DlState.completed));
    expect(row('trk_1').renditionId, 'ren_2');
    final file = await engine.playableFile('trk_1');
    expect(sha256.convert(await file!.readAsBytes()).toString(), sha256.convert(fresh).toString());
  });

  test('401 티켓 만료: 렌디션을 다시 받아 같은 오프셋에서 (§5.4)', () async {
    final bytes = randomBytes(200000, 6);
    renditions['trk_1'] = rendition('trk_1', 'ren_1', bytes);
    media.dropAfter = 70000;
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => row('trk_1').errorCode == 'network');
    final kept = await store.partFile(row('trk_1').id).length();
    media.forceStatus = 401;
    await retryNow();
    await waitFor(() => isState('trk_1', DlState.completed));
    expect(media.ranges.last, 'bytes=$kept-', reason: '새 티켓으로 같은 위치에서');
    expect(renditionCalls, 3, reason: '처음, 재시도, 티켓 만료 후');
  });

  test('해시 불일치 두 번이면 failed(integrity_mismatch), 재생 대상 아님 (§5.5)', () async {
    final bytes = randomBytes(100000, 7);
    renditions['trk_1'] = rendition('trk_1', 'ren_1', bytes, sha: 'deadbeef');
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => isState('trk_1', DlState.failed));
    expect(row('trk_1').errorCode, 'integrity_mismatch');
    expect(await engine.playableFile('trk_1'), isNull);
    expect(await store.mediaDir.list(recursive: true).where((e) => e is File).isEmpty, isTrue, reason: '불완전·불일치 파일은 media/에 없다');
    expect(media.requests, 2, reason: '처음부터 1회 재시도');
  });

  test('서버 해시가 아직 없으면 다시 조회, 끝내 없으면 크기만 검증 (§5.5)', () async {
    final bytes = randomBytes(50000, 8);
    renditions['trk_1'] = rendition('trk_1', 'ren_1', bytes, nullSha: true);
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => isState('trk_1', DlState.completed));
    expect(row('trk_1').verified, Verified.sizeOnly);
  });

  test('서버 변환 대기(202 preparing) 후 받기', () async {
    final bytes = randomBytes(50000, 9);
    renditions['trk_1'] = rendition('trk_1', 'ren_1', bytes, state: 'preparing');
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => isState('trk_1', DlState.preparing));
    renditions['trk_1'] = rendition('trk_1', 'ren_1', bytes);
    await waitFor(() => isState('trk_1', DlState.completed), timeout: const Duration(seconds: 5));
  });

  test('조건: 오프라인·Wi-Fi 없음·공간 부족이면 대기, 풀리면 즉시 진행 (§5.7)', () async {
    renditions['trk_1'] = rendition('trk_1', 'ren_1', randomBytes(50000, 10));
    cond.online = false;
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => isState('trk_1', DlState.waitingNetwork));
    cond.online = true;
    cond.wifi = false;
    cond.changed();
    await waitFor(() => isState('trk_1', DlState.waitingWifi));
    cond.wifi = true;
    cond.free = 100 * 1024 * 1024;
    cond.changed();
    await waitFor(() => isState('trk_1', DlState.waitingSpace));
    cond.free = 5 * 1024 * 1024 * 1024;
    cond.changed();
    await waitFor(() => isState('trk_1', DlState.completed));
  });

  test('저장 한도를 넘으면 새 다운로드는 대기, 받은 파일은 지우지 않는다, 한도를 올리면 이어서 (§5.7)', () async {
    renditions['trk_1'] = rendition('trk_1', 'ren_1', randomBytes(60000, 11));
    renditions['trk_2'] = rendition('trk_2', 'ren_2', randomBytes(60000, 12));
    engine.settings.limitBytes = 100000;
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => isState('trk_1', DlState.completed));
    // 크기는 렌디션을 결정해야 안다 → 결정 후 전송 시작 직전에 다시 판단해야 한다(실기기에서 한도가 무시되던 결함)
    await engine.downloadTracks([track('trk_2')], RequestKind.track, 'trk_2');
    await waitFor(() => isState('trk_2', DlState.waitingSpace));
    expect(media.ranges.length, 1, reason: '두 번째 곡은 받기 시작하지 않았다');
    expect(isState('trk_1', DlState.completed), isTrue, reason: '받은 파일은 그대로');
    engine.settings.limitBytes = 200000;
    cond.changed();
    await waitFor(() => isState('trk_2', DlState.completed));
  });

  test('동시에 받는 곡도 한도에 넣어 센다 (둘 다 시작하면 한도를 넘는 경우)', () async {
    renditions['trk_1'] = rendition('trk_1', 'ren_1', randomBytes(60000, 25));
    renditions['trk_2'] = rendition('trk_2', 'ren_2', randomBytes(60000, 26));
    engine.settings.limitBytes = 100000;
    media.delay = const Duration(milliseconds: 300);
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1'), track('trk_2')], RequestKind.album, 'alb_1');
    await waitFor(() => engine.rows.value.where((d) => d.state == DlState.completed).length == 1 && engine.rows.value.any((d) => d.state == DlState.waitingSpace));
    expect(await store.usedBytes(), 60000);
  });

  test('앨범 다운로드: 사본 저장, 동시 2개, 한 곡을 플레이리스트와 공유 (§5.4, §5.6)', () async {
    renditions['trk_1'] = rendition('trk_1', 'ren_1', randomBytes(80000, 13));
    renditions['trk_2'] = rendition('trk_2', 'ren_2', randomBytes(80000, 14));
    await engine.start(api: client);
    await engine.downloadAlbum('alb_1');
    await waitFor(() => isState('trk_1', DlState.completed) && isState('trk_2', DlState.completed));
    expect((await store.downloadedAlbums()).single.id, 'alb_1');
    expect((await store.albumTracks('alb_1')).length, 2);
    await engine.downloadTracks([track('trk_1')], RequestKind.playlist, 'pl_1');
    await engine.settle();
    expect(engine.rows.value.length, 2, reason: '같은 곡은 파일 하나');
    await engine.removeGroup(RequestKind.album, 'alb_1');
    await engine.settle();
    expect(engine.rows.value.map((d) => d.trackId), ['trk_1'], reason: '플레이리스트가 요구하는 곡은 남는다');
    expect(await engine.playableFile('trk_2'), isNull);
    expect(await store.isPinned(RequestKind.album, 'alb_1'), isFalse);
  });

  test('재시작 대조 (§5.9): 받던 중 앱 종료 → 다음 실행에서 .part 크기부터 이어받기, 고아 파일 정리', () async {
    final bytes = randomBytes(300000, 15);
    renditions['trk_1'] = rendition('trk_1', 'ren_1', bytes);
    media.delay = const Duration(milliseconds: 50);
    media.dropAfter = 120000;
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => row('trk_1').errorCode == 'network');
    // 앱 종료: DB는 downloading으로 남았다고 가정 (진행률 저장 직후 죽음)
    final d = row('trk_1');
    final kept = await store.partFile(d.id).length();
    await engine.dispose();
    await store.saveDownload(d.copyWith(state: DlState.downloading, bytesDone: 100000, notBefore: null));
    await File('${store.tmpDir.path}/dl_orphan.part').writeAsBytes([1, 2, 3]);
    await File('${store.mediaDir.path}/trk_9/ren_9.flac').create(recursive: true);
    engine = newEngine();
    await engine.start(api: client);
    await waitFor(() => isState('trk_1', DlState.completed));
    expect(media.ranges.last, 'bytes=$kept-', reason: 'DB의 bytes_done(100000)이 아니라 .part 실제 크기');
    expect(sha256.convert(await (await engine.playableFile('trk_1'))!.readAsBytes()).toString(), sha256.convert(bytes).toString());
    expect(await File('${store.tmpDir.path}/dl_orphan.part').exists(), isFalse);
    expect(await File('${store.mediaDir.path}/trk_9/ren_9.flac').exists(), isFalse);
  });

  test('재시작 대조: 완료인데 파일이 없으면 사유를 남기고 다시 받는다', () async {
    final bytes = randomBytes(40000, 16);
    renditions['trk_1'] = rendition('trk_1', 'ren_1', bytes);
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => isState('trk_1', DlState.completed));
    await engine.dispose();
    await store.mediaFile(row('trk_1').fileName!).delete();
    cond.online = false; // 다시 받기가 바로 끝나지 않게
    engine = newEngine();
    await engine.start(api: client);
    await engine.settle();
    expect(row('trk_1').errorCode, 'file_missing');
    expect(await engine.playableFile('trk_1'), isNull);
    cond.online = true;
    cond.changed();
    await waitFor(() => isState('trk_1', DlState.completed));
  });

  test('재생 시 크기가 다르면 file_corrupt로 바꾸고 스트리밍으로 (§5.5)', () async {
    renditions['trk_1'] = rendition('trk_1', 'ren_1', randomBytes(40000, 17));
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => isState('trk_1', DlState.completed));
    cond.online = false;
    await store.mediaFile(row('trk_1').fileName!).writeAsBytes([1, 2, 3]);
    expect(await engine.playableFile('trk_1'), isNull);
    await engine.settle();
    expect(row('trk_1').errorCode, 'file_corrupt');
  });

  test('세션 만료: 진행 중은 로그인 대기, 완료본은 재생 가능. 접근 취소: 잠금 (§5.8)', () async {
    renditions['trk_1'] = rendition('trk_1', 'ren_1', randomBytes(40000, 18));
    renditions['trk_2'] = rendition('trk_2', 'ren_2', randomBytes(40000, 19));
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => isState('trk_1', DlState.completed));
    cond.online = false;
    await engine.downloadTracks([track('trk_2')], RequestKind.track, 'trk_2');
    await waitFor(() => isState('trk_2', DlState.waitingNetwork));
    client.status.value = SessionStatus.expired;
    await engine.settle();
    cond.online = true;
    cond.changed();
    await engine.settle();
    expect(row('trk_2').state, isNot(DlState.completed));
    expect(await engine.playableFile('trk_1'), isNotNull, reason: '세션 만료에도 재생');
    client.status.value = SessionStatus.active;
    await waitFor(() => isState('trk_2', DlState.completed));
    client.status.value = SessionStatus.revoked;
    await engine.settle();
    expect(await engine.playableFile('trk_1'), isNull, reason: '접근 취소면 잠금');
    expect(engine.rows.value.every((d) => d.locked), isTrue);
    await engine.unlockAll();
    expect(await engine.playableFile('trk_1'), isNotNull, reason: '같은 사용자로 다시 로그인하면 해제');
  });

  test('취소·로그아웃 삭제: 행을 지우고 파일도 지운다', () async {
    renditions['trk_1'] = rendition('trk_1', 'ren_1', randomBytes(40000, 20));
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => isState('trk_1', DlState.completed));
    final file = store.mediaFile(row('trk_1').fileName!);
    await engine.deleteAll();
    expect(engine.rows.value, isEmpty);
    expect(await store.downloads(), isEmpty);
    expect(await file.exists(), isFalse);
  });

  test('자동 업데이트(기본 켜짐): 서버 버전이 바뀌면 새 버전을 저절로 받고 옛 파일을 지운다 (§5.4)', () async {
    renditions['trk_1'] = rendition('trk_1', 'ren_1', randomBytes(40000, 27));
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => isState('trk_1', DlState.completed));
    final oldFile = store.mediaFile(row('trk_1').fileName!);
    final fresh = randomBytes(30000, 28);
    renditions['trk_1'] = rendition('trk_1', 'ren_4', fresh, mv: 'v2');
    await engine.noteServerVersions([Track.fromJson({...f.track('trk_1', 'x'), 'media_version': 'v2'})]);
    await waitFor(() => engine.rows.value.length == 1 && row('trk_1').renditionId == 'ren_4' && row('trk_1').state == DlState.completed);
    expect(await oldFile.exists(), isFalse);
  });

  test('완료본 버전 교체: stale 표시, 새 버전 받기 완료 후 옛 파일 삭제 (§5.4) — 자동 업데이트 끔', () async {
    engine.settings.autoUpdate = false;
    renditions['trk_1'] = rendition('trk_1', 'ren_1', randomBytes(40000, 21));
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => isState('trk_1', DlState.completed));
    final oldFile = store.mediaFile(row('trk_1').fileName!);
    await engine.noteServerVersions([Track.fromJson({...f.track('trk_1', 'x'), 'media_version': 'v2'})]);
    expect(row('trk_1').stale, isTrue);
    expect(await engine.playableFile('trk_1'), isNotNull, reason: '옛 파일 계속 재생');
    final fresh = randomBytes(30000, 22);
    renditions['trk_1'] = rendition('trk_1', 'ren_3', fresh, mv: 'v2');
    await engine.retry(row('trk_1').id);
    await waitFor(() => engine.rows.value.length == 1 && row('trk_1').renditionId == 'ren_3' && row('trk_1').state == DlState.completed);
    expect(await oldFile.exists(), isFalse);
    expect(sha256.convert(await (await engine.playableFile('trk_1'))!.readAsBytes()).toString(), sha256.convert(fresh).toString());
  });

  test('일시중지·재개', () async {
    renditions['trk_1'] = rendition('trk_1', 'ren_1', randomBytes(40000, 23));
    cond.online = false;
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => isState('trk_1', DlState.waitingNetwork));
    await engine.pause(row('trk_1').id);
    cond.online = true;
    cond.changed();
    await engine.settle();
    expect(row('trk_1').state, DlState.paused, reason: '일시중지는 연결 복귀로 풀리지 않는다');
    await engine.resume(row('trk_1').id);
    await waitFor(() => isState('trk_1', DlState.completed));
  });

  test('받는 중 Wi-Fi가 끊기면 전송을 멈추고 Wi-Fi 대기, 돌아오면 바로 이어 완료 (FN-15 실기기에서 발견)', () async {
    // 실기기: OS가 Wi-Fi 조건 작업을 멈춘 뒤 패키지가 아무 소식도 주지 않아 "받는 중"에 멈춰 있었다.
    // 가짜 전송은 첫 시작에서 절반만 쓰고 침묵한다(작업을 잃은 패키지).
    final bytes = randomBytes(100000, 25);
    renditions['trk_1'] = rendition('trk_1', 'ren_1', bytes);
    final lost = SilentTransfer(bytes);
    await engine.dispose();
    engine = newEngine(transfer: lost);
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => row('trk_1').state == DlState.downloading && row('trk_1').bytesDone > 0);
    cond.wifi = false; // 셀룰러는 남아 있다
    cond.changed();
    await waitFor(() => isState('trk_1', DlState.waitingWifi));
    expect(lost.cancelled, [row('trk_1').id], reason: '패키지에 남은 작업을 멈춘다');
    cond.wifi = true;
    cond.changed();
    await waitFor(() => isState('trk_1', DlState.completed));
    expect(lost.starts, [0, 50000], reason: '받아 둔 위치부터 다시 시작');
    expect(sha256.convert(await (await engine.playableFile('trk_1'))!.readAsBytes()).toString(), sha256.convert(bytes).toString());
  });

  test('다운로드 음질을 바꿔도 동기화는 이미 받은 앨범을 새 음질로 다시 받지 않는다 (P6 실기기에서 발견)', () async {
    renditions['trk_1'] = rendition('trk_1', 'ren_1', randomBytes(30000, 26));
    renditions['trk_2'] = rendition('trk_2', 'ren_2', randomBytes(30000, 27));
    await engine.start(api: client);
    await engine.downloadAlbum('alb_1');
    await waitFor(() => isState('trk_1', DlState.completed) && isState('trk_2', DlState.completed));
    engine.settings.quality = 'aac_256';
    await engine.syncGroups();
    await engine.settle();
    expect(engine.rows.value.map((d) => d.quality).toSet(), {'original'}, reason: '묶음은 고정할 때의 음질을 따른다');
    expect(engine.rows.value, hasLength(2));
  });

  test('재시도할 수 없는 서버 오류(media_missing)는 바로 실패', () async {
    api.on('POST /tracks/trk_1/renditions', (_) => (404, {'type': 'about:blank', 'title': 'x', 'status': 404, 'code': 'media_missing'}));
    await engine.start(api: client);
    await engine.downloadTracks([track('trk_1')], RequestKind.track, 'trk_1');
    await waitFor(() => isState('trk_1', DlState.failed));
    expect(row('trk_1').errorCode, 'media_missing');
  });
}
