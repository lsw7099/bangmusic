// S3 라이브러리 격자·큰 글씨·새 플레이리스트, S4 최근 검색어·모두 보기 (04장 S3·S4, P5)
import 'package:bangmusic/ui/screens/browse_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Map<String, Object?> searchResult(String q) => {
      'query_normalized': q,
      'tracks': page([for (var i = 0; i < 5; i++) track('trk_$i', '검색곡 $i')], 'CUR'),
      'albums': page([album('alb_1', '검색 앨범')]),
      'artists': page([]),
      'playlists': page([]),
    };

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('S3 라이브러리', () {
    testWidgets('앨범은 2열 격자 (두 앨범이 한 줄)', (t) async {
      final s = FakeServer()..json('GET /albums', page([album('alb_1', '왼쪽 앨범'), album('alb_2', '오른쪽 앨범')]));
      await pumpApp(t, const LibraryScreen(), server: s);
      final left = t.getTopLeft(find.text('왼쪽 앨범'));
      final right = t.getTopLeft(find.text('오른쪽 앨범'));
      expect(left.dy, right.dy, reason: '같은 줄');
      expect(right.dx, greaterThan(left.dx));
    });

    testWidgets('큰 글씨(1.3 이상)면 격자 대신 1열 목록', (t) async {
      final s = FakeServer()..json('GET /albums', page([album('alb_1', '왼쪽 앨범'), album('alb_2', '오른쪽 앨범')]));
      t.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(t, const LibraryScreen(), server: s);
      expect(t.getTopLeft(find.text('오른쪽 앨범')).dy, greaterThan(t.getTopLeft(find.text('왼쪽 앨범')).dy), reason: '위아래로');
      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('플레이리스트 칩에서 + 로 새 플레이리스트', (t) async {
      var created = false;
      final s = FakeServer()
        ..json('GET /albums', page([]))
        ..on('GET /playlists', (_) => page([if (created) playlist('pl_new', '새 목록')]))
        ..on('POST /playlists', (o) {
          created = true;
          return playlist('pl_new', '새 목록');
        });
      await pumpApp(t, const LibraryScreen(), server: s);
      await t.tap(find.text('플레이리스트'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('새 플레이리스트'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), '새 목록');
      await t.tap(find.text('만들기'));
      await t.pumpAndSettle();
      expect(s.requests, contains('POST /playlists'));
      expect(find.text('새 목록'), findsWidgets);
    });

    testWidgets('다운로드 기능이 없으면(시험 환경) "다운로드한 항목만" 칩을 보이지 않는다', (t) async {
      final s = FakeServer()..json('GET /albums', page([]));
      await pumpApp(t, const LibraryScreen(), server: s);
      expect(find.text('다운로드한 항목만'), findsNothing);
    });
  });

  group('S4 검색', () {
    Future<FakeServer> search(WidgetTester t) async {
      final s = FakeServer()..on('GET /search', (o) => searchResult(o.queryParameters['q'] as String));
      await pumpApp(t, const SearchScreen(), server: s);
      await t.enterText(find.byType(TextField), '夜明け');
      await t.testTextInput.receiveAction(TextInputAction.search);
      await t.pump(const Duration(milliseconds: 350));
      await t.pumpAndSettle();
      return s;
    }

    testWidgets('검색한 말은 최근 검색어에 남고, 지우면 목록에 다시 보이며 개별·전체 삭제', (t) async {
      await search(t);
      await t.tap(find.byTooltip('지우기'));
      await t.pumpAndSettle();
      expect(find.text('최근 검색어'), findsOneWidget);
      expect(find.text('夜明け'), findsOneWidget);
      expect((await SharedPreferences.getInstance()).getStringList('search.recent'), ['夜明け']);
      await t.tap(find.byTooltip('‘夜明け’ 지우기'));
      await t.pumpAndSettle();
      expect(find.text('최근 검색어'), findsNothing);
    });

    testWidgets('"곡 모두 보기"는 한 유형만 커서로 요청한다', (t) async {
      final s = await search(t);
      await t.tap(find.text('곡 모두 보기'));
      await t.pumpAndSettle();
      final all = s.requests.where((r) => r.startsWith('GET /search') && r.contains('types=track')).toList();
      expect(all, isNotEmpty);
      expect(find.text('‘夜明け’ · 곡'), findsOneWidget);
    });
  });
}
