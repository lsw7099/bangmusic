// S10 설정 상태 (04장 S10): 오프라인이면 서버 항목 비활성, 세션 만료면 "다시 로그인", 점검 배너, 로컬 설정 반영
import 'package:bangmusic/core/session.dart';
import 'package:bangmusic/ui/screens/settings_screen.dart';
import 'package:bangmusic/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ListTile tile(WidgetTester t, String title) => t.widget<ListTile>(find.ancestor(of: find.text(title), matching: find.byType(ListTile)).first);

  testWidgets('온라인: 서버 항목 사용 가능, 구획 7개(서버·재생·다운로드는 다운로드 엔진이 있을 때·가사·화면·개인정보·앱)', (t) async {
    await pumpApp(t, const SettingsScreen());
    expect(tile(t, '내 기기 세션').enabled, isTrue);
    expect(tile(t, '비밀번호 변경').enabled, isTrue);
    for (final s in ['재생', '가사', '화면', '개인정보', '앱']) {
      await t.scrollUntilVisible(find.text(s), 300);
      expect(find.text(s), findsOneWidget, reason: s);
    }
    await t.pumpAndSettle();
  });

  testWidgets('서버에 닿지 않으면 서버가 필요한 항목은 비활성 + 안내, 로컬 설정은 그대로', (t) async {
    final (app, _, _) = await pumpApp(t, const SettingsScreen());
    app.api!.reachable.value = false;
    await t.pumpAndSettle();
    expect(tile(t, '내 기기 세션').enabled, isFalse);
    expect(tile(t, '비밀번호 변경').enabled, isFalse);
    expect(find.text('온라인에서 사용할 수 있습니다'), findsWidgets);
    await t.scrollUntilVisible(find.text('재생 기록 삭제 (서버)'), 300);
    expect(tile(t, '재생 기록 삭제 (서버)').enabled, isFalse);
    expect(tile(t, '서버 계정 삭제').enabled, isFalse);
    await t.scrollUntilVisible(find.text('테마'), -300);
    expect(tile(t, '테마').enabled, isTrue, reason: '로컬 설정');
  });

  testWidgets('세션 만료면 서버 구획 맨 위에 "다시 로그인", 누르면 시트(서버 고정·사용자 이름 채움)', (t) async {
    final (app, _, _) = await pumpApp(t, const SettingsScreen());
    app.api!.status.value = SessionStatus.expired;
    await t.pumpAndSettle();
    expect(find.text('다시 로그인'), findsOneWidget);
    await t.tap(find.text('다시 로그인'));
    await t.pumpAndSettle();
    expect(find.text('http://fake'), findsWidgets, reason: '어느 서버인지 보인다');
    expect(find.widgetWithText(TextField, 'siwon'), findsOneWidget, reason: '사용자 이름이 채워져 있다');
  });

  testWidgets('테마를 고르면 바로 반영되고 저장된다', (t) async {
    final (app, _, _) = await pumpApp(t, const SettingsScreen());
    await t.scrollUntilVisible(find.text('테마'), 300);
    await t.tap(find.text('테마'));
    await t.pumpAndSettle();
    await t.tap(find.text('다크').last);
    await t.pumpAndSettle();
    expect(app.prefs.themeMode, ThemeMode.dark);
    expect((await SharedPreferences.getInstance()).getString('ui.theme'), 'dark');
  });

  testWidgets('서버 점검(503 maintenance)이면 배너, 끝나면 사라진다', (t) async {
    final s = FakeServer()..on('GET /me', (_) => (503, {'type': 'about:blank', 'title': 'x', 'status': 503, 'code': 'maintenance'}));
    final (app, _, _) = await pumpApp(t, const Scaffold(body: Column(children: [StatusBanner()])), server: s);
    // 직접 보내는 요청은 실제 시간에서 (가짜 시계 안에서 기다리면 멈춘다)
    await t.runAsync(() async {
      try {
        await app.api!.dio.get<Object>('/me');
      } catch (_) {}
    });
    await t.pumpAndSettle();
    expect(find.textContaining('서버 점검 중입니다'), findsOneWidget);
    s.json('GET /me', {'id': 'usr_1'});
    await t.runAsync(() => app.api!.dio.get<Object>('/me'));
    await t.pumpAndSettle();
    expect(find.textContaining('서버 점검 중입니다'), findsNothing);
    await app.close(); // 점검 재확인 타이머 정리
  });
}
