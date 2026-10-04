// AppState 프로필 저장·복원 (01장 §6, FN-21). 실기기 결함 회귀: P3 → P4 업데이트 후 두 번째 실행에서 로그인이 풀림.
import 'dart:convert';

import 'package:bangmusic/core/session.dart';
import 'package:bangmusic/platform/secure_store.dart';
import 'package:bangmusic/ui/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const p = ServerProfile(serverId: 'srv_A', baseUrl: 'https://a.example', serverName: 'A', userId: 'usr_1', username: 'u', installationId: 'i');
  const q = ServerProfile(serverId: 'srv_B', baseUrl: 'https://b.example', serverName: 'B', userId: 'usr_2', username: 'v', installationId: 'i');

  Future<AppState> start(MemorySecureStore secure) async {
    final s = AppState(player: FakePlayer(), store: secure);
    await s.load();
    return s;
  }

  test('P3 형식(profile.active에 JSON)에서 옮긴 뒤 다시 실행해도 로그인 유지', () async {
    SharedPreferences.setMockInitialValues({'profile.active': jsonEncode(p.toJson())});
    final secure = MemorySecureStore();
    await TokenVault(secure).save('srv_A', Tokens('bma_x', DateTime(2030), 'bmr_x'));
    final first = await start(secure);
    expect(first.profile?.serverId, 'srv_A');
    final second = await start(secure); // 앱을 다시 켬
    expect(second.profile?.serverId, 'srv_A', reason: '옮긴 프로필 목록이 저장되어 있어야 한다');
    expect(second.profiles.map((x) => x.serverId), ['srv_A']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profile.active'), 'srv_A');
  });

  test('여러 서버 프로필: 활성 프로필과 목록이 다시 실행해도 그대로 (FN-21)', () async {
    SharedPreferences.setMockInitialValues({
      'profiles': [jsonEncode(p.toJson()), jsonEncode(q.toJson())],
      'profile.active': 'srv_B',
    });
    final secure = MemorySecureStore();
    await TokenVault(secure).save('srv_A', Tokens('bma_a', DateTime(2030), 'bmr_a'));
    await TokenVault(secure).save('srv_B', Tokens('bma_b', DateTime(2030), 'bmr_b'));
    final s = await start(secure);
    expect(s.profile?.serverId, 'srv_B');
    expect(s.api?.accessToken, 'bma_b', reason: '서버마다 자기 토큰');
    expect(await s.switchTo(p), isTrue);
    expect(s.api?.accessToken, 'bma_a');
    final again = await start(secure);
    expect(again.profile?.serverId, 'srv_A', reason: '마지막으로 고른 서버');
    expect(again.profiles.length, 2);
  });

  test('토큰이 없는 프로필로는 전환하지 않는다 (로그인 화면으로)', () async {
    SharedPreferences.setMockInitialValues({'profiles': [jsonEncode(p.toJson()), jsonEncode(q.toJson())], 'profile.active': 'srv_A'});
    final secure = MemorySecureStore();
    await TokenVault(secure).save('srv_A', Tokens('bma_a', DateTime(2030), 'bmr_a'));
    final s = await start(secure);
    expect(await s.switchTo(q), isFalse);
    expect(s.profile?.serverId, 'srv_A');
  });
}
