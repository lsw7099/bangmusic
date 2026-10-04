// FN-21 회귀: 서버(프로필)를 바꾸면 화면이 새 서버 내용으로 다시 그려진다 — 이전 서버에서 받은 홈이 남아 있던 결함(실기기에서 발견).
import 'package:bangmusic/core/api_client.dart';
import 'package:bangmusic/core/session.dart';
import 'package:bangmusic/main.dart';
import 'package:bangmusic/platform/secure_store.dart';
import 'package:bangmusic/ui/app_state.dart';
import 'package:bangmusic/ui/scope.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

Map<String, Object?> home(String title) => {
      'playlists': <Object>[], 'recent_tracks': [track('trk_$title', title)], 'top_tracks': <Object>[], 'recently_added_albums': <Object>[],
    };

ApiClient client(FakeServer s, ServerProfile p) => ApiClient(
      profile: p, vault: TokenVault(MemorySecureStore()), tokens: Tokens('bma_x', DateTime(2030), 'bmr_x'),
      dio: Dio(BaseOptions(baseUrl: 'http://fake/v1'))..httpClientAdapter = s,
    );

void main() {
  testWidgets('서버를 바꾸면 홈을 새 서버에서 다시 받는다 (이전 서버 내용이 남지 않음)', (t) async {
    const a = ServerProfile(serverId: 'srv_A', baseUrl: 'http://a', serverName: 'A', userId: 'usr_1', username: 'lsw', installationId: 'i');
    const b = ServerProfile(serverId: 'srv_B', baseUrl: 'http://b', serverName: 'B', userId: 'usr_2', username: 'tester2', installationId: 'i');
    final sa = FakeServer(serverId: 'srv_A')..json('GET /home', home('A서버곡'));
    final sb = FakeServer(serverId: 'srv_B')..json('GET /home', home('B서버곡'));
    final state = AppState(player: FakePlayer(), store: MemorySecureStore())..debugActivate(a, client(sa, a));
    await t.pumpWidget(AppScope(state: state, child: const BangMusicApp()));
    await t.pumpAndSettle();
    expect(find.text('A서버곡'), findsWidgets);

    state.debugActivate(b, client(sb, b)); // 서버 전환
    await t.pumpAndSettle();
    expect(find.text('B서버곡'), findsWidgets);
    expect(find.text('A서버곡'), findsNothing, reason: '이전 서버 내용이 남으면 안 된다');
    expect(find.textContaining('tester2'), findsWidgets);
    expect(sb.requests.any((r) => r.startsWith('GET /home')), isTrue, reason: '새 서버에서 받았다');
  });
}
