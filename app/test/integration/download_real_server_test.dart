// FN-03 (L1, 05장 §9.4): 실제 로컬 서버(합성 음원)에서 전송 중 연결을 끊고 이어받은 다운로드의 SHA-256이
// 같은 렌디션을 따로 처음부터 받은 것과 일치한다. 서버는 tools/e2e/app-test-server.mts가 띄운다.
// 연결 끊기는 앱과 서버 사이의 TCP 중계가 한다(첫 대용량 응답을 중간에 끊음).
// 실행: FFMPEG/FFPROBE 환경 변수(또는 PATH)와 Node 24가 있어야 한다. 없으면 건너뛴다.
@Tags(['integration'])
library;

import 'dart:async';
import 'dart:io';

import 'package:bangmusic/core/api_client.dart';
import 'package:bangmusic/data/download_engine.dart';
import 'package:bangmusic/data/library_store.dart';
import 'package:bangmusic/domain/download_state.dart';
import 'package:bangmusic/platform/playback_engine.dart' show androidAccept;
import 'package:bangmusic/platform/transfer_port.dart';
import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'real_server.dart';

/// 앱 ↔ 서버 TCP 중계. arm()한 뒤 처음으로 cutAfter 바이트를 넘긴 서버→앱 연결을 그 자리에서 끊는다.
class CuttingProxy {
  CuttingProxy(this.targetPort);
  final int targetPort;
  late ServerSocket _server;
  int? _cutAfter;
  bool cut = false;

  Future<int> start() async {
    _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_relay);
    return _server.port;
  }

  void arm(int cutAfter) => _cutAfter = cutAfter;

  Future<void> _relay(Socket client) async {
    final upstream = await Socket.connect(InternetAddress.loopbackIPv4, targetPort);
    var sent = 0;
    var dead = false; // 이 연결을 끊었으면 뒤따르는 바이트는 버린다
    client.listen(upstream.add, onDone: () => upstream.destroy(), onError: (Object _) => upstream.destroy());
    upstream.listen((data) {
      if (dead) return;
      final limit = _cutAfter;
      if (!cut && limit != null && sent + data.length > limit) {
        cut = true;
        dead = true;
        client.add(data.sublist(0, limit - sent));
        unawaited(client.flush().whenComplete(() {
          client.destroy();
          upstream.destroy();
        }));
        return;
      }
      sent += data.length;
      client.add(data);
    }, onDone: () => client.destroy(), onError: (Object _) => client.destroy());
  }

  Future<void> close() => _server.close();
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
  RealServer? server;
  String? skip;

  setUpAll(() async {
    (server, skip) = await RealServer.start();
  });
  tearDownAll(() async => server?.stop());

  /// 같은 렌디션을 중계 없이 처음부터 받은 SHA-256 (기준값)
  Future<String> referenceSha(ApiClient direct, String trackId, String quality) async {
    var r = await direct.call((x) => x.getMediaApi().resolveRendition(
          trackId: trackId, renditionRequest: RenditionRequest(purpose: RenditionRequestPurposeEnum.download, quality: quality, accept: androidAccept)));
    for (var i = 0; r.state == RenditionStateEnum.preparing && i < 120; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      r = await direct.call((x) => x.getMediaApi().getRendition(renditionId: r.id));
    }
    final c = HttpClient();
    final res = await (await c.getUrl(Uri.parse('${direct.baseUrl}${r.mediaUrl}'))).close();
    final digest = await sha256.bind(res).first;
    c.close();
    return digest.toString();
  }

  Future<void> runCase(String quality) async {
    if (skip != null) {
      markTestSkipped(skip!);
      return;
    }
    final base = server!.baseUrl;
    final direct = await server!.login();
    final tracks = (await direct.call((x) => x.getCatalogApi().listTracks(limit: 100))).items.where((t) => t.state == TrackStateEnum.available).toList()
      ..sort((a, b) => b.durationMs.compareTo(a.durationMs));
    final track = tracks.first;
    // 크기를 알아 중간에서 끊는다
    var r = await direct.call((x) => x.getMediaApi().resolveRendition(
          trackId: track.id, renditionRequest: RenditionRequest(purpose: RenditionRequestPurposeEnum.download, quality: quality, accept: androidAccept)));
    for (var i = 0; r.state == RenditionStateEnum.preparing && i < 120; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      r = await direct.call((x) => x.getMediaApi().getRendition(renditionId: r.id));
    }
    expect(r.state, RenditionStateEnum.ready);
    final size = r.sizeBytes!;
    expect(size, greaterThan(20000), reason: '중간에서 끊을 만큼 커야 한다');

    final proxy = CuttingProxy(Uri.parse(base).port);
    final proxyPort = await proxy.start();
    final viaProxy = await server!.login(baseUrl: 'http://127.0.0.1:$proxyPort');
    final dir = await Directory.systemTemp.createTemp('bm_fn03');
    final store = await LibraryStore.openForTest(dir);
    final engine = DownloadEngine(store: store, transfer: HttpTransfer(idleTimeout: const Duration(seconds: 5)), conditions: OkConditions(), accept: androidAccept,
        settings: DownloadSettings(quality: quality));
    try {
      await engine.start(api: viaProxy);
      proxy.arm(size ~/ 2);
      await engine.downloadTracks([track], RequestKind.track, track.id);
      final end = DateTime.now().add(const Duration(seconds: 90));
      while (!engine.rows.value.any((d) => d.state == DlState.completed || d.state == DlState.failed)) {
        if (DateTime.now().isAfter(end)) fail('시간 초과: ${engine.rows.value}');
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      await engine.settle();
      final d = engine.rows.value.single;
      expect(d.state, DlState.completed, reason: '$d');
      expect(proxy.cut, isTrue, reason: '전송 중에 연결이 끊겼어야 한다');
      final file = (await engine.playableFile(track.id))!;
      final got = sha256.convert(await file.readAsBytes()).toString();
      expect(await file.length(), size);
      expect(got, await referenceSha(direct, track.id, quality), reason: '이어받은 파일 = 처음부터 받은 파일');
      if (d.sha256 != null) expect(got, d.sha256, reason: '서버가 준 해시와도 일치');
      // ignore: avoid_print
      print('FN-03 $quality: ${track.title} $size B, 끊긴 뒤 이어받기, sha256=$got, 검증=${d.verified?.name}');
    } finally {
      await engine.dispose();
      await store.close();
      await proxy.close();
      await dir.delete(recursive: true);
    }
  }

  test('FN-03: 원본 다운로드를 중간에 끊고 이어받아 SHA-256 일치', () => runCase('original'), timeout: const Timeout(Duration(minutes: 3)));
  test('FN-03: 서버 변환본(aac_128)도 같은 방식으로 일치', () => runCase('aac_128'), timeout: const Timeout(Duration(minutes: 3)));
}
