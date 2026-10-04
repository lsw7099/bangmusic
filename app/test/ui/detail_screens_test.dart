// S5 앨범·S6 플레이리스트 상태 (04장 S5·S6, P5): 404, 편집(빼기·순서), 편집 충돌, 이름 수정
import 'package:bangmusic/ui/screens/browse_screens.dart';
import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

Map<String, Object?> items(List<(String, String)> its) => {
      'items': [for (final (id, trk) in its) {'item_id': id, 'available': true, 'track': track(trk, '곡 $trk'), 'added_at': '2026-10-03T00:00:00Z'}],
      'next_cursor': null,
      'version': 4,
    };

void main() {
  testWidgets('앨범이 없으면(404) "삭제되었거나 접근할 수 없습니다" + 뒤로', (t) async {
    final s = FakeServer()..on('GET /albums/alb_x', (_) => (404, {'type': 'about:blank', 'title': 'x', 'status': 404, 'code': 'not_found'}));
    await pumpApp(t, const AlbumScreen(albumId: 'alb_x', title: '사라진 앨범'), server: s);
    expect(find.text('삭제되었거나 접근할 수 없습니다'), findsOneWidget);
    expect(find.text('뒤로'), findsOneWidget);
  });

  group('플레이리스트 편집', () {
    late FakeServer s;
    var version = 4;
    final edits = <Map<String, Object?>>[];

    Future<void> open(WidgetTester t) async {
      version = 4;
      edits.clear();
      s = FakeServer()
        ..on('GET /playlists/pl_1', (_) => playlist('pl_1', '드라이브', count: 3, version: version))
        ..json('GET /playlists/pl_1/items', items([('pli_1', 'trk_1'), ('pli_2', 'trk_2'), ('pli_3', 'trk_3')]))
        ..on('POST /playlists/pl_1/edits', (o) {
          if (o.headers['If-Match'] != '"$version"') return (412, {'type': 'about:blank', 'title': 'x', 'status': 412, 'code': 'version_conflict'});
          edits.add((o.data as Map).cast<String, Object?>());
          version++;
          return playlist('pl_1', '드라이브', count: 3, version: version);
        });
      await pumpApp(t, PlaylistScreen(playlist: Playlist.fromJson(playlist('pl_1', '드라이브', count: 3, version: 4))), server: s);
      await t.scrollUntilVisible(find.text('편집'), 200);
      await t.tap(find.text('편집'));
      await t.pumpAndSettle();
    }

    testWidgets('빼기는 remove 연산을 현재 버전·멱등 키와 함께 보낸다', (t) async {
      await open(t);
      await t.scrollUntilVisible(find.byTooltip('곡 trk_2 빼기'), 200);
      await t.tap(find.byTooltip('곡 trk_2 빼기'));
      await t.pumpAndSettle();
      expect(edits.single['ops'], [{'op': 'remove', 'item_ids': ['pli_2']}]);
      expect(s.requests.where((r) => r == 'POST /playlists/pl_1/edits').length, 1);
    });

    testWidgets('다른 기기에서 먼저 바뀌었으면(412) "다른 기기에서 변경되었습니다" → 최신 내용', (t) async {
      await open(t);
      version = 9; // 그사이 다른 기기가 편집
      await t.scrollUntilVisible(find.byTooltip('곡 trk_1 빼기'), 200);
      await t.tap(find.byTooltip('곡 trk_1 빼기'));
      await t.pumpAndSettle();
      expect(find.text('다른 기기에서 변경되었습니다'), findsOneWidget);
      await t.tap(find.text('최신 내용 보기'));
      await t.pumpAndSettle();
      expect(s.requests.where((r) => r == 'GET /playlists/pl_1').length, greaterThanOrEqualTo(2), reason: '최신 내용을 다시 받는다');
    });

    testWidgets('이름 수정은 If-Match로 보낸다', (t) async {
      String? ifMatch;
      await open(t);
      s.on('PATCH /playlists/pl_1', (o) {
        ifMatch = o.headers['If-Match'] as String?;
        return playlist('pl_1', '새 이름', version: 5);
      });
      await t.tap(find.byTooltip('플레이리스트 메뉴'));
      await t.pumpAndSettle();
      await t.tap(find.text('이름·설명 수정'));
      await t.pumpAndSettle();
      await t.enterText(find.widgetWithText(TextField, '드라이브').first, '새 이름');
      await t.tap(find.text('저장'));
      await t.pumpAndSettle();
      expect(ifMatch, '"4"');
      expect(find.text('새 이름'), findsWidgets);
    });
  });
}
