// 탭 동작 (04장 §2, P5): 루트에서 탭을 다시 누르면 맨 위로, 검색 탭은 검색창 초점, 마지막 탭 복원
import 'package:bangmusic/ui/glass.dart';
import 'package:bangmusic/ui/shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

FakeServer longHome() => FakeServer()
  ..json('GET /home', {
    'playlists': <Object>[],
    'recent_tracks': <Object>[],
    'top_tracks': [for (var i = 0; i < 5; i++) track('trk_$i', '곡 $i')],
    'recently_added_albums': [for (var i = 0; i < 8; i++) album('alb_$i', '앨범 $i')],
  })
  ..json('GET /albums', page([for (var i = 0; i < 30; i++) album('alb_$i', '앨범 $i')]));

/// 탭 막대(좁은 화면) 또는 레일(폭 600dp 이상)의 탭 — 화면 제목과 이름이 같아서
Finder tab(String label) => find.descendant(of: find.byWidgetPredicate((w) => w is GlassTabBar || w is NavigationRail), matching: find.text(label));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('루트에서 현재 탭을 다시 누르면 맨 위로', (t) async {
    t.view.physicalSize = const Size(1080, 1400);
    addTearDown(t.view.reset);
    await pumpApp(t, const Shell(), server: longHome());
    await t.tap(tab('라이브러리'));
    await t.pumpAndSettle();
    final list = find.byType(Scrollable).last;
    await t.drag(list, const Offset(0, -2000));
    await t.pumpAndSettle();
    final pos = t.state<ScrollableState>(list).position;
    expect(pos.pixels, greaterThan(0));
    await t.tap(tab('라이브러리'));
    await t.pumpAndSettle();
    expect(t.state<ScrollableState>(find.byType(Scrollable).last).position.pixels, 0);
  });

  testWidgets('검색 탭을 다시 누르면 검색창에 초점', (t) async {
    await pumpApp(t, const Shell(), server: longHome());
    await t.tap(tab('검색'));
    await t.pumpAndSettle();
    final field = find.byType(TextField);
    expect(t.widget<TextField>(field).focusNode!.hasFocus, isFalse, reason: '자동 초점은 다시 눌렀을 때만');
    await t.tap(tab('검색'));
    await t.pumpAndSettle();
    expect(t.widget<TextField>(field).focusNode!.hasFocus, isTrue);
  });

  testWidgets('마지막으로 고른 탭을 기억했다가 다시 연다', (t) async {
    await pumpApp(t, const Shell(), server: longHome());
    await t.tap(tab('다운로드'));
    await t.pumpAndSettle();
    expect((await SharedPreferences.getInstance()).getInt('ui.tab'), 3);
  });
}
