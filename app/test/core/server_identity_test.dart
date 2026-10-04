// 같은 주소, 다른 server_id (03장 §5.2, FN-21): 토큰을 붙인 요청·리프레시를 보내지 않는다.
import 'package:bangmusic/core/api_client.dart';
import 'package:bangmusic/core/session.dart';
import 'package:bangmusic/platform/secure_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ui/fakes.dart';

void main() {
  late FakeServer server;
  late ApiClient api;

  setUp(() {
    server = FakeServer();
    server.json('GET /me', {'id': 'usr_1'});
    final dio = Dio(BaseOptions(baseUrl: 'http://fake/v1'))..httpClientAdapter = server;
    const profile = ServerProfile(serverId: 'srv_T', baseUrl: 'http://fake', serverName: '시험', userId: 'usr_1', username: 'u', installationId: 'i');
    api = ApiClient(profile: profile, vault: TokenVault(MemorySecureStore()), tokens: Tokens('bma_secret', DateTime(2030), 'bmr_secret'), dio: dio);
  });

  Future<Object?> me() async {
    try {
      return await api.dio.get<Object>('/me');
    } catch (e) {
      return ApiException.from(e);
    }
  }

  test('같은 서버면 신원을 한 번 확인한 뒤 토큰을 붙여 보낸다', () async {
    await me();
    await me();
    expect(server.requests.where((r) => r == 'GET /server').length, 1, reason: '확인은 한 번');
    expect(server.auth['GET /server'], isNull, reason: '신원 확인에는 토큰을 붙이지 않는다');
    expect(server.auth['GET /me'], 'Bearer bma_secret');
    expect(api.serverChanged.value, isFalse);
  });

  test('server_id가 다르면 토큰을 붙인 요청을 보내지 않는다', () async {
    server.serverId = 'srv_OTHER';
    final r = await me();
    expect(r, isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.serverMismatch));
    expect(server.requests, ['GET /server'], reason: '신원 확인 외에는 아무것도 나가지 않았다');
    expect(api.serverChanged.value, isTrue);
    await expectLater(api.refresh(), throwsA(isA<ApiException>()));
    expect(server.requests.any((r) => r.contains('/auth/refresh')), isFalse, reason: '리프레시 토큰도 보내지 않는다');
  });

  test('연결이 끊겼다 돌아오면 다시 확인한다 (그사이 같은 주소에 다른 서버가 올라온 경우)', () async {
    await me();
    expect(server.auth['GET /me'], 'Bearer bma_secret');
    server.on('GET /me', (o) => throw DioException.connectionError(requestOptions: o, reason: 'down'));
    await me();
    expect(api.reachable.value, isFalse);
    server.serverId = 'srv_IMPOSTOR';
    server.json('GET /me', {'id': 'x'});
    server.auth.clear();
    server.requests.clear();
    final r = await me();
    expect(r, isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.serverMismatch));
    expect(server.requests, ['GET /server']);
    expect(server.auth.values.whereType<String>(), isEmpty);
  });

  test('신원 확인 자체가 실패하면(연결 안 됨) 토큰을 보내지 않고 연결 실패로', () async {
    server.on('GET /server', (o) => throw DioException.connectionError(requestOptions: o, reason: 'down'));
    final r = await me();
    expect(r, isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.unreachable));
    expect(server.requests, ['GET /server']);
    expect(api.reachable.value, isFalse);
  });
}
