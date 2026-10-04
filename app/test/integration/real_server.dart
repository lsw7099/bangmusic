// L1 통합 테스트 공통: tools/e2e/app-test-server.mts로 실제 로컬 서버(합성 음원)를 띄우고 로그인한다.
// Node 24와 FFmpeg(FFMPEG/FFPROBE 또는 PATH)가 없으면 skip 사유를 돌려준다.
import 'dart:convert';
import 'dart:io';

import 'package:bangmusic/core/api_client.dart';
import 'package:bangmusic/core/session.dart';
import 'package:bangmusic/platform/secure_store.dart';
import 'package:flutter_test/flutter_test.dart';

class RealServer {
  RealServer._(this._process, this.baseUrl, this.username, this.password);
  final Process _process;
  final String baseUrl;
  final String username;
  final String password;
  int _install = 0;

  static Future<(RealServer?, String?)> start() async {
    final script = File('../tools/e2e/app-test-server.mts');
    if (!script.existsSync()) return (null, '서버 스크립트 없음');
    final Process p;
    try {
      p = await Process.start('node', [script.absolute.path], workingDirectory: script.parent.parent.parent.absolute.path);
    } catch (e) {
      return (null, 'node 실행 불가: $e');
    }
    final err = StringBuffer();
    p.stderr.transform(utf8.decoder).listen(err.write);
    final line = await p.stdout.transform(utf8.decoder).transform(const LineSplitter()).firstWhere((l) => l.startsWith('{'), orElse: () => '')
        .timeout(const Duration(seconds: 60), onTimeout: () => '');
    if (line.isEmpty) {
      p.kill();
      return (null, '서버 시작 실패: $err');
    }
    final j = jsonDecode(line) as Map<String, dynamic>;
    return (RealServer._(p, j['base_url'] as String, j['username'] as String, j['password'] as String), null);
  }

  /// 로그인할 때마다 다른 설치 ID (같은 ID로 다시 로그인하면 서버가 이전 세션을 끊는다 — 기기당 세션 하나)
  Future<ApiClient> login({String? baseUrl}) async {
    final url = baseUrl ?? this.baseUrl;
    _install++;
    final probe = await probeServer(url);
    expect(probe, isA<ProbeOk>(), reason: '$probe');
    final (t, si) = await loginToServer(probe as ProbeOk, username, password, '00000000-0000-4000-8000-${_install.toString().padLeft(12, '0')}', 'L1 테스트 $_install');
    final profile = ServerProfile(serverId: si.serverId, baseUrl: url, serverName: si.name, userId: t.user.id, username: t.user.username, installationId: 'i$_install');
    return ApiClient(profile: profile, vault: TokenVault(MemorySecureStore()), tokens: Tokens(t.accessToken, t.accessExpiresAt, t.refreshToken));
  }

  Future<void> stop() async {
    await _process.stdin.close();
    await _process.exitCode.timeout(const Duration(seconds: 20), onTimeout: () {
      _process.kill();
      return -1;
    });
  }
}
