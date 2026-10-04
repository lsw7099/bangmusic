// API 클라이언트 (02장 §1.2, §2.2) — 가짜 서버 대상 (L1)
import 'dart:convert';
import 'dart:io';

import 'package:bangmusic/core/api_client.dart';
import 'package:bangmusic/core/server_address.dart';
import 'package:bangmusic/core/session.dart';
import 'package:bangmusic/platform/secure_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// 경로별 응답을 바꿀 수 있는 가짜 서버
class FakeServer {
  late HttpServer _s;
  final calls = <String>[];
  Map<String, Object?> serverInfo = {
    'server_id': 'srv_TEST', 'name': '시험', 'product': 'bangmusic-server', 'version': '0.1.0', 'api': {'major': 1, 'minor': 0},
    'min_client_api_minor': 0, 'features': <String>[], 'limits': <String, int>{}, 'setup_required': false,
  };
  String validAccess = 'bma_new';
  String refreshMode = 'ok'; // ok | expired | revoked | down
  int refreshDelayMs = 50;

  String get base => 'http://127.0.0.1:${_s.port}';

  Future<void> start() async {
    _s = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _s.listen((req) async {
      final path = req.uri.path;
      calls.add('${req.method} $path');
      final res = req.response;
      Future<void> json(int status, Object body) async {
        res.statusCode = status;
        res.headers.contentType = ContentType('application', status >= 400 ? 'problem+json' : 'json', charset: 'utf-8');
        res.write(jsonEncode(body));
        await res.close();
      }

      Map<String, Object?> problem(int status, String code) => {'type': 'about:blank', 'title': 'x', 'status': status, 'code': code, 'request_id': 'req_t'};
      if (path == '/v1/server') return json(200, serverInfo);
      if (path == '/v1/auth/refresh') {
        await Future<void>.delayed(Duration(milliseconds: refreshDelayMs));
        return switch (refreshMode) {
          'expired' => json(401, problem(401, 'refresh_expired')),
          'revoked' => json(401, problem(401, 'session_revoked')),
          'down' => json(503, problem(503, 'maintenance')),
          _ => json(200, {
              'session_id': 'ses_1', 'access_token': validAccess, 'access_expires_at': '2030-01-01T00:00:00Z',
              'refresh_token': 'bmr_rotated', 'refresh_expires_at': '2030-01-01T00:00:00Z', 'user': {'id': 'usr_1', 'username': 'u', 'role': 'member'},
            }),
        };
      }
      if (path == '/v1/me') {
        final auth = req.headers.value('authorization');
        if (auth == 'Bearer revoked') return json(401, problem(401, 'session_revoked'));
        if (auth != 'Bearer $validAccess') return json(401, problem(401, 'access_expired'));
        return json(200, {'id': 'usr_1', 'username': 'u', 'role': 'member', 'libraries': <Object>[]});
      }
      return json(404, problem(404, 'not_found'));
    });
  }

  Future<void> stop() => _s.close(force: true);
}

ApiClient client(FakeServer s, {String access = 'bma_old'}) => ApiClient(
      profile: ServerProfile(serverId: 'srv_TEST', baseUrl: s.base, serverName: '시험', userId: 'usr_1', username: 'u', installationId: 'i'),
      vault: TokenVault(MemorySecureStore()),
      tokens: Tokens(access, DateTime(2030), 'bmr_old'),
    );

void main() {
  late FakeServer s;
  setUp(() async {
    s = FakeServer();
    await s.start();
  });
  tearDown(() => s.stop());

  test('단일 비행: 동시 요청 3개가 401을 받아도 갱신은 한 번, 모두 재시도 성공', () async {
    final c = client(s);
    final results = await Future.wait([for (var i = 0; i < 3; i++) c.call((a) => a.getMeApi().getMe())]);
    expect(results.length, 3);
    expect(s.calls.where((x) => x == 'POST /v1/auth/refresh').length, 1);
    expect(c.accessToken, 'bma_new');
    expect(c.status.value, SessionStatus.active);
  });

  test('refresh_expired → 세션 만료 (재로그인 필요, 다운로드는 유지)', () async {
    s.refreshMode = 'expired';
    final c = client(s);
    await expectLater(c.call((a) => a.getMeApi().getMe()), throwsA(isA<ApiException>()));
    expect(c.status.value, SessionStatus.expired);
  });

  test('session_revoked → 접근 취소', () async {
    s.refreshMode = 'revoked';
    final c = client(s);
    await expectLater(c.call((a) => a.getMeApi().getMe()), throwsA(isA<ApiException>()));
    expect(c.status.value, SessionStatus.revoked);
    final direct = client(s, access: 'revoked');
    await expectLater(direct.call((a) => a.getMeApi().getMe()), throwsA(isA<ApiException>()));
    expect(direct.status.value, SessionStatus.revoked, reason: '일반 요청의 session_revoked도');
  });

  test('네트워크 오류·5xx는 세션 만료가 아니다 (02장 §1.2)', () async {
    s.refreshMode = 'down';
    final c = client(s);
    await expectLater(c.call((a) => a.getMeApi().getMe()), throwsA(isA<ApiException>()));
    expect(c.status.value, SessionStatus.active);
    await s.stop();
    final e = await c.call((a) => a.getMeApi().getMe()).then<ApiException?>((_) => null, onError: (Object e) => e as ApiException);
    expect(e!.kind, ApiErrorKind.unreachable);
    expect(c.status.value, SessionStatus.active);
    await s.start(); // tearDown용
  });

  group('서버 확인 (02장 §2.2)', () {
    test('정상', () async => expect(await probeServer(s.base), isA<ProbeOk>()));
    test('서버 major가 다르면 지원 안 함', () async {
      s.serverInfo['api'] = {'major': 2, 'minor': 0};
      expect((await probeServer(s.base) as ProbeIncompatible).reason, Incompatibility.unsupportedMajor);
    });
    test('서버가 앱 최소값을 넘으면 앱 업데이트 필요', () async {
      s.serverInfo['min_client_api_minor'] = 99;
      expect((await probeServer(s.base) as ProbeIncompatible).reason, Incompatibility.appTooOld);
    });
    test('BangMusic이 아닌 서버', () async {
      s.serverInfo['product'] = 'something-else';
      final r = await probeServer(s.base);
      expect(r, isA<ProbeFailed>());
      expect((r as ProbeFailed).error.kind, ApiErrorKind.notBangmusic);
    });
    test('닿지 않는 주소', () async {
      final r = await probeServer('http://127.0.0.1:1');
      expect((r as ProbeFailed).error.kind, ApiErrorKind.unreachable);
    });
  });

  group('주소 정규화 (04장 S1)', () {
    test('스킴이 없으면 https, 끝의 / 와 /v1 제거', () {
      expect((normalizeServerAddress('music.example.net/', allowCleartext: false) as AddressOk).baseUrl, 'https://music.example.net');
      expect((normalizeServerAddress('https://h:8443/v1/', allowCleartext: false) as AddressOk).baseUrl, 'https://h:8443');
    });
    test('릴리스에서 http는 거부, 디버그에서는 허용', () {
      expect(normalizeServerAddress('http://192.168.0.2:8080', allowCleartext: false), isA<AddressError>());
      expect((normalizeServerAddress('http://192.168.0.2:8080', allowCleartext: true) as AddressOk).baseUrl, 'http://192.168.0.2:8080');
    });
    test('사용자 정보가 든 주소는 거부', () => expect(normalizeServerAddress('https://u:p@h', allowCleartext: false), isA<AddressError>()));
  });

  test('소켓이 EPERM으로 거부되면 로컬 네트워크 권한 없음으로 분류 (Android 17 타깃, 01장 §2.6)', () {
    final e = DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError,
        error: const SocketException('connect', osError: OSError('Operation not permitted', 1)));
    expect(ApiException.from(e).kind, ApiErrorKind.localNetworkDenied);
    final refused = DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError,
        error: const SocketException('connect', osError: OSError('Connection refused', 111)));
    expect(ApiException.from(refused).kind, ApiErrorKind.unreachable, reason: '서버가 꺼진 것과는 구분');
  });
}
