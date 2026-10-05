// 탭 셸 (04장 §2). 탭마다 독립된 화면 스택. 현재 탭을 다시 누르면 루트로.
// 뒤로 가기: 스택 한 단계 → 탭 루트면 홈 탭 → 홈 루트면 앱을 백그라운드로(재생은 계속).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ambient.dart';
import 'glass.dart';
import 'scope.dart';
import 'screens/browse_screens.dart';
import 'screens/download_screens.dart';
import 'screens/player_screens.dart';
import 'tokens.dart';
import 'widgets/common.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  final _navs = List.generate(4, (_) => GlobalKey<NavigatorState>());

  static const _tabs = [
    (Icons.home_outlined, Icons.home, '홈'),
    (Icons.library_music_outlined, Icons.library_music, '라이브러리'),
    (Icons.search, Icons.search, '검색'),
    (Icons.download_outlined, Icons.download, '다운로드'),
  ];

  /// 루트 화면에서 탭을 다시 누름 → 맨 위로 (04장 §2)
  final _reselect = List.generate(4, (_) => ValueNotifier<int>(0));

  Widget _root(int i) => _TabRoot(
        reselect: _reselect[i],
        child: switch (i) {
          0 => const HomeScreen(),
          1 => const LibraryScreen(),
          2 => const SearchScreen(),
          _ => const DownloadsScreen(),
        },
      );

  @override
  void initState() {
    super.initState();
    // 마지막 탭 복원 (04장 §2). 각 탭의 화면 스택 복원은 하지 않는다 — P5 보고 "남은 일"
    SharedPreferences.getInstance().then((p) {
      final t = p.getInt('ui.tab');
      if (t != null && t >= 0 && t < 4 && mounted) setState(() => _tab = t);
    });
  }

  @override
  void dispose() {
    for (final n in _reselect) {
      n.dispose();
    }
    super.dispose();
  }

  void _select(int i) {
    if (i == _tab) {
      final nav = _navs[i].currentState;
      if (nav != null && nav.canPop()) {
        nav.popUntil((r) => r.isFirst); // 스택이 깊으면 루트로
      } else if (i == 2) {
        SearchScreen.requestFocus(); // 검색 탭 루트: 검색창에 초점
      } else {
        _reselect[i].value++; // 이미 루트: 맨 위로
      }
    } else {
      setState(() => _tab = i);
      SharedPreferences.getInstance().then((p) => p.setInt('ui.tab', i));
    }
  }

  Future<void> _back() async {
    final nav = _navs[_tab].currentState!;
    if (nav.canPop()) {
      nav.pop();
    } else if (_tab != 0) {
      setState(() => _tab = 0);
    } else {
      await SystemNavigator.pop(); // 백그라운드로 (재생 서비스는 계속)
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    // 다운로드 탭: 진행 중 개수 배지, 실패가 있으면 경고 점 (04장 §2)
    Widget icon(int i, bool selected) => i == 3 ? DownloadsTabIcon(selected: selected) : Icon(selected ? _tabs[i].$2 : _tabs[i].$1);
    final player = context.readApp().player;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => didPop ? null : _back(),
      child: AmbientBackdrop(
        child: Material(
          type: MaterialType.transparency,
          child: ListenableBuilder(
            listenable: player.queueChanged,
            builder: (context, _) {
              final mq = MediaQuery.of(context);
              final hasMini = player.currentTrack != null;
              // 떠 있는 조작부(04장 §3.4): 탭 막대(+ 미니 플레이어)가 내용 위에 뜬다 → 그만큼 내용 아래 여백
              final float = GlassTokens.float;
              final cluster = (wide ? 0.0 : GlassTabBar.height + float) + (hasMini ? MiniPlayer.height + (wide ? float : Space.sm) : 0) + float;
              final body = IndexedStack(
                index: _tab,
                children: [
                  for (var i = 0; i < 4; i++)
                    Navigator(key: _navs[i], onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => _root(i))),
                ],
              );
              final content = Column(children: [
                const StatusBanner(),
                Expanded(
                  child: Builder(builder: (context) {
                    // 배너가 상태 표시줄 자리를 이미 썼으면 아래 화면은 위 여백을 다시 넣지 않는다
                    final banner = StatusBanner.visible(context);
                    return MediaQuery(
                      data: mq.copyWith(padding: mq.padding.copyWith(top: banner ? 0 : mq.padding.top, bottom: mq.padding.bottom + cluster)),
                      child: wide
                          ? Row(children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(float, (banner ? 0 : mq.padding.top) + float, 0, mq.padding.bottom + float),
                                child: Glass(
                                  kind: GlassKind.thin,
                                  child: NavigationRail(
                                    backgroundColor: Colors.transparent,
                                    selectedIndex: _tab,
                                    onDestinationSelected: _select,
                                    labelType: NavigationRailLabelType.all,
                                    indicatorColor: context.glassOff ? context.colors.accentSoft : context.glass.lens,
                                    destinations: [for (var i = 0; i < _tabs.length; i++) NavigationRailDestination(icon: icon(i, false), selectedIcon: icon(i, true), label: Text(_tabs[i].$3))],
                                  ),
                                ),
                              ),
                              Expanded(child: body),
                            ])
                          : body,
                    );
                  }),
                ),
              ]);
              return Stack(children: [
                Positioned.fill(child: content),
                Positioned(
                  left: wide ? 120 : float,
                  right: float,
                  bottom: mq.padding.bottom + float,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (hasMini) const MiniPlayer(),
                    if (hasMini && !wide) const SizedBox(height: Space.sm),
                    if (!wide)
                      GlassTabBar(
                        selected: _tab,
                        onSelect: _select,
                        items: [for (var i = 0; i < _tabs.length; i++) (icon(i, false), icon(i, true), _tabs[i].$3)],
                      ),
                  ]),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

/// 탭 루트: 다시 누르면 그 탭 화면의 주 스크롤을 맨 위로 올린다
class _TabRoot extends StatefulWidget {
  const _TabRoot({required this.reselect, required this.child});
  final ValueNotifier<int> reselect;
  final Widget child;
  @override
  State<_TabRoot> createState() => _TabRootState();
}

class _TabRootState extends State<_TabRoot> {
  @override
  void initState() {
    super.initState();
    widget.reselect.addListener(_top);
  }

  @override
  void dispose() {
    widget.reselect.removeListener(_top);
    super.dispose();
  }

  void _top() {
    final c = PrimaryScrollController.maybeOf(context);
    if (c != null && c.hasClients) c.animateTo(0, duration: context.reduceMotion ? Duration.zero : Motion.base, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
