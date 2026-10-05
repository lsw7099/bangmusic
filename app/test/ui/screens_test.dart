// S2~S8 화면 위젯 테스트 (L1, 가짜 서버·소리 없는 플레이어)
import 'package:bangmusic/core/session.dart';
import 'package:bangmusic/domain/queue.dart';
import 'package:bangmusic/main.dart';
import 'package:bangmusic/platform/player_port.dart';
import 'package:bangmusic/platform/secure_store.dart';
import 'package:bangmusic/ui/app_state.dart';
import 'package:bangmusic/ui/scope.dart';
import 'package:bangmusic/ui/screens/browse_screens.dart';
import 'package:bangmusic/ui/screens/player_screens.dart';
import 'package:bangmusic/ui/shell.dart';
import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

FakeServer albumServer() {
  final s = FakeServer();
  s.json('GET /home', {
    'playlists': <Object>[],
    'recent_tracks': <Object>[],
    'top_tracks': [track('trk_t1', '많이 들은 곡 하나')],
    'recently_added_albums': [album('alb_1', '첫 앨범')],
  });
  s.json('GET /albums/alb_1', {
    ...album('alb_1', '첫 앨범', count: 3),
    'tracks': [
      track('trk_1', '첫 곡', albumId: 'alb_1', no: 1),
      track('trk_2', '사라진 곡', albumId: 'alb_1', no: 2, state: 'missing'),
      track('trk_3', '셋째 곡', albumId: 'alb_1', no: 3),
    ],
  });
  return s;
}

/// 바깥 목록을 스크롤해 찾는다 (긴 목록의 아래쪽은 아직 그려지지 않았다)
/// LP가 도는 화면은 멈추지 않으므로 정해진 만큼만 진행한다
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> scrollTo(WidgetTester t, Finder f) => t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);

void main() {
  group('S2 홈', () {
    testWidgets('구획 표시: 많이 들은 곡, 최근 추가한 앨범 (빈 구획은 숨김)', (t) async {
      await pumpApp(t, const HomeScreen(), server: albumServer());
      expect(find.textContaining('시원'), findsOneWidget, reason: '인사에 표시 이름');
      expect(find.text('많이 들은 곡'), findsOneWidget);
      expect(find.text('최근 추가한 앨범'), findsOneWidget);
      expect(find.text('최근 들은 곡'), findsNothing);
    });

    testWidgets('플레이리스트가 없으면 주인공 자리에 "첫 플레이리스트 만들기" (04장 S2)', (t) async {
      final s = albumServer()..json('POST /playlists', playlist('pl_new', '새 목록'));
      await pumpApp(t, const HomeScreen(), server: s);
      await t.tap(find.text('첫 플레이리스트 만들기'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), '새 목록');
      await t.tap(find.text('만들기'));
      await t.pumpAndSettle();
      expect(s.requests.where((r) => r.startsWith('POST /playlists')), hasLength(1));
      expect(s.requests.where((r) => r.startsWith('GET /home')), hasLength(2), reason: '만든 뒤 홈을 다시 받는다');
    });

    testWidgets('라이브러리가 비면 안내', (t) async {
      final s = FakeServer()..json('GET /home', {'playlists': <Object>[], 'recent_tracks': <Object>[], 'top_tracks': <Object>[], 'recently_added_albums': <Object>[]});
      await pumpApp(t, const HomeScreen(), server: s);
      expect(find.text('서버에 음악이 없습니다'), findsOneWidget);
    });

    testWidgets('서버 오류면 다시 시도할 수 있는 오류 화면', (t) async {
      final s = FakeServer()..on('GET /home', (_) => (503, {'type': 'about:blank', 'title': 'x', 'status': 503, 'code': 'maintenance', 'request_id': 'req_1'}));
      await pumpApp(t, const HomeScreen(), server: s);
      expect(find.text('서버 점검 중입니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
      expect(find.text('자세히'), findsOneWidget, reason: '오류 코드와 request_id');
      // 다시 시도: setState에 Future를 돌려주면 디버그 단언이 터졌다 (P5 갤러리 점검에서 발견)
      await t.tap(find.text('다시 시도'));
      await t.pumpAndSettle();
      expect(s.requests.where((r) => r.startsWith('GET /home')), hasLength(2));
    });
  });

  group('S5 앨범', () {
    testWidgets('재생·셔플은 앨범 컨텍스트로, 누락 곡은 빼고 재생', (t) async {
      final (_, player, _) = await pumpApp(t, const HomeScreen(), server: albumServer());
      await t.tap(find.text('첫 앨범'));
      await t.pumpAndSettle();
      await scrollTo(t, find.text('셋째 곡'));
      expect(find.text('셋째 곡'), findsOneWidget);
      await t.tap(find.text('재생'));
      await t.pumpAndSettle();
      expect(player.calls.last, 'playTracks album:alb_1 start=0 shuffle=false n=2');
      await t.tap(find.text('셔플'));
      await t.pumpAndSettle();
      expect(player.calls.last, 'playTracks album:alb_1 start=0 shuffle=true n=2');
    });

    testWidgets('곡을 누르면 그 곡부터, 누락 곡은 누를 수 없다', (t) async {
      final semantics = t.ensureSemantics();
      final (_, player, _) = await pumpApp(t, const AlbumScreen(albumId: 'alb_1', title: '첫 앨범'), server: albumServer());
      await scrollTo(t, find.text('셋째 곡'));
      await t.tap(find.text('셋째 곡'));
      await t.pumpAndSettle();
      expect(player.calls.last, 'playTracks album:alb_1 start=1 shuffle=null n=2', reason: '누락 곡을 뺀 목록에서 두 번째');
      final before = player.calls.length;
      await scrollTo(t, find.text('사라진 곡'));
      await t.tap(find.text('사라진 곡'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(player.calls.length, before);
      expect(find.bySemanticsLabel(RegExp('사라진 곡.*재생할 수 없음')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('⋮ → 다음에 재생', (t) async {
      final (_, player, _) = await pumpApp(t, const AlbumScreen(albumId: 'alb_1', title: '첫 앨범'), server: albumServer());
      await scrollTo(t, find.text('첫 곡'));
      await t.ensureVisible(find.byTooltip('더 보기').first); // 표지 그림자 여유만큼 머리글이 커져 버튼이 화면 끝에 걸린다
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('더 보기').first);
      await t.pumpAndSettle();
      await t.tap(find.text('다음에 재생'));
      await t.pumpAndSettle();
      expect(player.calls.last, 'playNext trk_1');
      expect(find.text('다음에 재생합니다'), findsOneWidget);
    });
  });

  group('S3 라이브러리', () {
    testWidgets('곡 목록: 끝에 가까워지면 다음 페이지를 커서로 요청', (t) async {
      final s = FakeServer();
      s.on('GET /tracks', (o) {
        final c = o.queryParameters['cursor'];
        if (c == null) return page([for (var i = 0; i < 12; i++) track('trk_a$i', '앞 곡 $i')], 'CUR1');
        return page([for (var i = 0; i < 3; i++) track('trk_b$i', '뒤 곡 $i')]);
      });
      s.json('GET /albums', page([]));
      await pumpApp(t, const LibraryScreen(), server: s);
      await t.tap(find.text('곡'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(find.text('뒤 곡 2'), 300, scrollable: find.byType(Scrollable).last);
      expect(s.requests.where((r) => r.startsWith('GET /tracks')).length, 2);
      expect(s.requests.any((r) => r.contains('cursor=CUR1')), isTrue);
    });
  });

  group('S4 검색', () {
    testWidgets('300ms 디바운스: 빠르게 고쳐 써도 마지막 질의만 보낸다', (t) async {
      final s = FakeServer();
      s.on('GET /search', (o) => {
            'query_normalized': o.queryParameters['q'],
            'tracks': page([track('trk_s', '夜明けのうた')]),
            'albums': page([]), 'artists': page([]), 'playlists': page([]),
          });
      await pumpApp(t, const SearchScreen(), server: s);
      await t.enterText(find.byType(TextField), 'よ');
      await t.pump(const Duration(milliseconds: 100));
      await t.enterText(find.byType(TextField), 'よあ');
      await t.pump(const Duration(milliseconds: 100));
      await t.enterText(find.byType(TextField), 'よあけ');
      await t.pump(const Duration(milliseconds: 299));
      expect(s.requests.where((r) => r.startsWith('GET /search')), isEmpty);
      await t.pump(const Duration(milliseconds: 2));
      await t.pumpAndSettle();
      final searches = s.requests.where((r) => r.startsWith('GET /search')).toList();
      expect(searches.length, 1);
      expect(Uri.decodeQueryComponent(searches.single), contains('q=よあけ'));
      expect(find.text('夜明けのうた'), findsOneWidget);
    });

    testWidgets('결과가 없으면 질의어와 함께 안내', (t) async {
      final s = FakeServer()..json('GET /search', {'query_normalized': 'zz', 'tracks': page([]), 'albums': page([]), 'artists': page([]), 'playlists': page([])});
      await pumpApp(t, const SearchScreen(), server: s);
      await t.enterText(find.byType(TextField), 'zz');
      await t.pump(const Duration(milliseconds: 350));
      await t.pumpAndSettle();
      expect(find.text('‘zz’에 대한 결과가 없습니다'), findsOneWidget);
    });
  });

  group('S6 플레이리스트', () {
    testWidgets('재생할 수 없는 항목은 자리표시자, 재생은 가능한 곡만', (t) async {
      final s = FakeServer()..json('GET /playlists/pl_1', playlist('pl_1', '드라이브', count: 3, version: 4));
      s.json('GET /playlists/pl_1/items', {
        'items': [
          {'item_id': 'pli_1', 'available': true, 'track': track('trk_1', '첫 곡'), 'added_at': '2026-10-03T00:00:00Z'},
          {'item_id': 'pli_2', 'available': false, 'added_at': '2026-10-03T00:00:00Z'},
          {'item_id': 'pli_3', 'available': true, 'track': track('trk_3', '셋째 곡'), 'added_at': '2026-10-03T00:00:00Z'},
        ],
        'next_cursor': null,
        'version': 4,
      });
      final (_, player, _) = await pumpApp(t, PlaylistScreen(playlist: Playlist.fromJson(playlist('pl_1', '드라이브', count: 3))), server: s);
      await scrollTo(t, find.text('재생할 수 없는 곡'));
      expect(find.text('재생할 수 없는 곡'), findsOneWidget);
      await scrollTo(t, find.text('재생'));
      await t.tap(find.text('재생'));
      await t.pumpAndSettle();
      expect(player.calls.last, 'playTracks playlist:pl_1 start=0 shuffle=false n=2');
    });
  });

  group('S7 미니 플레이어 · S8 몰입 화면', () {
    Future<FakePlayer> withQueue(WidgetTester t, Widget home) async {
      final (_, player, _) = await pumpApp(t, home, server: FakeServer()
        ..json('GET /tracks/trk_1/lyrics', {
          'track_id': 'trk_1', 'version': 1, 'offset_ms': 0,
          'variants': [
            {'kind': 'original', 'language': 'ja', 'synced': true, 'source': {'type': 'sidecar', 'name': '서버의 .lrc 파일'}, 'lines': [{'t_ms': 0, 'text': '夜明け'}, {'t_ms': 10000, 'text': '空'}]},
            {'kind': 'pronunciation_ko', 'language': 'ko', 'synced': true, 'source': {'type': 'sidecar'}, 'lines': [{'t_ms': 0, 'text': '요아케'}, {'t_ms': 10000, 'text': '소라'}]},
          ],
        }));
      await player.playTracks([Track.fromJson(track('trk_1', '첫 곡')), Track.fromJson(track('trk_2', '둘째 곡')), Track.fromJson(track('trk_3', '셋째 곡'))],
          context: const QueueContext(ContextType.album, 'alb_1', '첫 앨범'));
      await settle(t);
      return player;
    }

    testWidgets('미니 플레이어: 대기열 없으면 숨김, 있으면 곡·버튼', (t) async {
      final (_, player, _) = await pumpApp(t, const Scaffold(body: SizedBox.expand(), bottomNavigationBar: MiniPlayer()));
      expect(find.byTooltip('다음 곡'), findsNothing);
      await player.playTracks([Track.fromJson(track('trk_1', '첫 곡'))], context: const QueueContext(ContextType.adhoc));
      await settle(t);
      expect(find.text('첫 곡'), findsOneWidget);
      await t.tap(find.byTooltip('일시정지'));
      await t.pump();
      expect(player.calls.last, 'pause');
      await t.tap(find.byTooltip('다음 곡'));
      await t.pump();
      expect(player.calls.last, 'next');
    });

    testWidgets('몰입 화면: 셔플·반복 버튼, 대기열 구획', (t) async {
      final player = await withQueue(t, const NowPlayingScreen());
      // 머리글: "재생 중" + 맥락 이름 (04장 §3.4 몰입 화면)
      expect(find.text('재생 중'), findsOneWidget);
      expect(find.text('첫 앨범'), findsOneWidget);
      await t.tap(find.byTooltip('셔플 켜기'));
      await t.pump();
      expect(player.calls.last, 'shuffle true');
      await t.tap(find.byTooltip('반복 꺼짐'));
      await t.pump();
      expect(player.calls.last, 'repeat all');
      player.playNext([Track.fromJson(track('trk_x', '끼워 넣은 곡'))]);
      await t.tap(find.text('대기열'));
      await settle(t);
      expect(find.text('지금 재생 중'), findsOneWidget);
      expect(find.text('다음에 재생'), findsOneWidget);
      expect(find.text('끼워 넣은 곡'), findsOneWidget);
      expect(find.text('이어서: 첫 앨범'), findsOneWidget);
    });

    testWidgets('가로 화면(휴대폰 891×411dp)에서도 LP가 보인다 (FN-19, 실기기에서 LP가 사라졌음)', (t) async {
      t.view.devicePixelRatio = 3.5;
      t.view.physicalSize = const Size(3120, 1440);
      t.view.padding = const FakeViewPadding(top: 84, bottom: 168); // 상태 표시줄 24dp, 탐색 막대 48dp
      addTearDown(t.view.reset);
      final player = await withQueue(t, const NowPlayingScreen());
      player.nowSource.value = const NowSource(null, localFormat: 'flac'); // "FLAC · 다운로드됨" 줄
      await settle(t);
      final lp = t.getSize(find.bySemanticsLabel(RegExp('^LP')));
      expect(lp.height, greaterThanOrEqualTo(120), reason: 'LP 지름(dp)');
      expect(find.text('가사'), findsOneWidget, reason: '오른쪽 구획');
      expect(t.takeException(), isNull, reason: '넘침 없음');
    });

    testWidgets('가사: 원문+발음, 번역이 없으면 번역 칩 비활성', (t) async {
      await withQueue(t, const NowPlayingScreen());
      await t.tap(find.text('가사'));
      await settle(t);
      expect(find.text('夜明け'), findsOneWidget);
      expect(find.text('요아케'), findsOneWidget);
      final trans = t.widget<FilterChip>(find.widgetWithText(FilterChip, '번역'));
      expect(trans.onSelected, isNull);
      await t.tap(find.widgetWithText(FilterChip, '발음'));
      await settle(t);
      expect(find.text('요아케'), findsNothing, reason: '발음 줄을 끄면 숨김');
    });

    testWidgets('가사: 비활성 칩을 누르면 이유, 가사 끝에 출처 (04장 S8)', (t) async {
      await withQueue(t, const NowPlayingScreen());
      await t.tap(find.text('가사'));
      await settle(t);
      await t.tap(find.widgetWithText(FilterChip, '번역'));
      await settle(t);
      expect(find.text('이 곡에는 번역 가사가 없습니다'), findsOneWidget);
      // 이름이 없는 출처는 종류로 표시한다
      expect(find.text('가사 출처: 서버의 .lrc 파일\n발음 출처: 서버의 가사 파일'), findsOneWidget);
    });

    testWidgets('변환 대기면 몰입 화면에 "서버에서 재생용 파일을 준비 중입니다" (04장 S8)', (t) async {
      final player = await withQueue(t, const NowPlayingScreen());
      player.nowSource.value = const NowSource(null, preparing: true);
      await settle(t);
      expect(find.text('서버에서 재생용 파일을 준비 중입니다'), findsOneWidget);
    });
  });

  group('공통 상태 (04장 §5)', () {
    testWidgets('세션 만료면 배너', (t) async {
      final (state, _, _) = await pumpApp(t, const Shell(), server: albumServer());
      expect(find.textContaining('다시 로그인이 필요합니다'), findsNothing);
      state.api!.status.value = SessionStatus.expired;
      await t.pumpAndSettle();
      expect(find.textContaining('다시 로그인이 필요합니다'), findsOneWidget);
    });

    testWidgets('접근 취소면 전체 화면 안내', (t) async {
      final (state, _, _) = await pumpApp(t, const SizedBox(), server: albumServer());
      await t.pumpWidget(AppScope(state: state, child: const BangMusicApp()));
      await t.pumpAndSettle();
      state.api!.status.value = SessionStatus.revoked;
      await t.pumpAndSettle();
      expect(find.text('이 기기의 접근이 취소되었습니다'), findsOneWidget);
    });

    testWidgets('탭 셸: 탭마다 스택 유지, 현재 탭을 다시 누르면 루트로', (t) async {
      await pumpApp(t, const Shell(), server: albumServer()..json('GET /albums', page([album('alb_1', '첫 앨범')])));
      await t.tap(find.text('첫 앨범').first);
      await t.pumpAndSettle();
      expect(find.text('재생'), findsOneWidget, reason: '앨범 화면');
      await t.tap(find.text('검색'));
      await t.pumpAndSettle();
      await t.tap(find.text('홈'));
      await t.pumpAndSettle();
      expect(find.text('재생'), findsOneWidget, reason: '탭을 바꿨다 와도 보던 화면');
      await t.tap(find.text('홈'));
      await t.pumpAndSettle();
      expect(find.text('재생'), findsNothing, reason: '현재 탭 다시 누르기 → 루트');
      expect(find.text('최근 추가한 앨범'), findsOneWidget);
    });
  });

  test('AppState 생성에 실제 오디오 서비스가 필요 없다', () {
    expect(() => AppState(player: FakePlayer(), store: MemorySecureStore()), returnsNormally);
  });
}
