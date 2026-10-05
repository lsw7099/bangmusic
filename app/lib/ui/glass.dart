// 유리 재질 (04장 §3.4). 재질 개념만 참고하고 특정 서비스의 아이콘·배치를 옮기지 않는다(05장 §8.7).
// - 두꺼운 유리: 뒤 내용 흐림 + 반투명 채움 + 가장자리 빛 + 그림자 → 떠 있는 조작부(탭 막대·미니 플레이어·상단 막대·시트)
// - 얇은 유리: 흐림 없이 반투명 채움 + 가장자리 빛 → 카드·구획(목록마다 흐리면 느리다)
// - 투명도 줄이기(설정 또는 시스템 고대비): 불투명 surface + outline 1dp
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'ambient.dart';
import 'scope.dart';
import 'tokens.dart';

/// 유리 토큰. 채움 불투명도는 "뒤에 흰색·검정이 비쳐도 글자 대비 4.5:1"로 정했다(test/ui/contrast_test.dart)
class GlassTokens {
  const GlassTokens({
    required this.thickFill, required this.thinFill, required this.rimTop, required this.rimBottom,
    required this.shadow, required this.onGlass, required this.onGlassMuted, required this.lens,
  });

  final Color thickFill, thinFill, rimTop, rimBottom, shadow, onGlass, onGlassMuted, lens;

  static const blur = 28.0;
  static const radius = 28.0;
  static const pill = 999.0;
  static const float = 12.0;

  static const light = GlassTokens(
    thickFill: Color(0xB8FFFFFF), // 흰색 72%
    thinFill: Color(0x8CFFFFFF), // 흰색 55%
    rimTop: Color(0xE6FFFFFF), rimBottom: Color(0x33FFFFFF),
    shadow: Color(0x1A000000),
    onGlass: Color(0xFF1C1718), onGlassMuted: Color(0xFF4A4042),
    lens: Color(0x33D7263D),
  );

  static const dark = GlassTokens(
    thickFill: Color(0xC71A1617), // 78%
    thinFill: Color(0x12FFFFFF), // 흰색 7%
    rimTop: Color(0x47FFFFFF), rimBottom: Color(0x0AFFFFFF),
    shadow: Color(0x66000000),
    onGlass: Color(0xFFF4EEEE), onGlassMuted: Color(0xFFCFC4C6),
    lens: Color(0x40FF6B7D),
  );
}

extension GlassContext on BuildContext {
  GlassTokens get glass => Theme.of(this).brightness == Brightness.dark ? GlassTokens.dark : GlassTokens.light;

  /// 투명도 줄이기: 설정 또는 시스템 고대비
  bool get glassOff {
    final scope = getInheritedWidgetOfExactType<AppScope>();
    final pref = scope?.notifier?.prefs.reduceTransparency ?? false;
    return pref || MediaQuery.maybeHighContrastOf(this) == true;
  }
}

enum GlassKind { thick, thin }

class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.kind = GlassKind.thick, this.radius = GlassTokens.radius, this.padding, this.fill, this.circle = false});

  final Widget child;
  final GlassKind kind;
  final double radius;
  final EdgeInsetsGeometry? padding;

  /// 채움색을 바꿀 때 (예: 강조 렌즈)
  final Color? fill;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final r = circle ? BorderRadius.circular(GlassTokens.pill) : BorderRadius.circular(radius);
    final content = padding == null ? child : Padding(padding: padding!, child: child);
    if (context.glassOff) {
      final c = context.colors;
      return Container(
        decoration: BoxDecoration(color: c.surface, borderRadius: r, border: Border.all(color: c.outline)),
        child: content,
      );
    }
    final painted = CustomPaint(
      painter: _GlassPainter(fill: fill ?? (kind == GlassKind.thick ? g.thickFill : g.thinFill), rimTop: g.rimTop, rimBottom: g.rimBottom, radius: r),
      child: content,
    );
    if (kind == GlassKind.thin) return painted;
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: r, boxShadow: [BoxShadow(color: g.shadow, blurRadius: 24, offset: const Offset(0, 8))]),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: GlassTokens.blur, sigmaY: GlassTokens.blur), child: painted),
      ),
    );
  }
}

/// 채움 + 위쪽 빛(안쪽 그라데이션) + 가장자리 빛 1dp
class _GlassPainter extends CustomPainter {
  _GlassPainter({required this.fill, required this.rimTop, required this.rimBottom, required this.radius});
  final Color fill, rimTop, rimBottom;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = radius.toRRect(rect);
    canvas.drawRRect(rr, Paint()..color = fill);
    // 위쪽이 살짝 밝은 광택
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.center,
          colors: [rimTop.withValues(alpha: rimTop.a * 0.18), rimTop.withValues(alpha: 0)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rr.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [rimTop, rimBottom]).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassPainter old) => old.fill != fill || old.rimTop != rimTop || old.radius != radius;
}

/// 모든 화면의 바탕: 배경 덩어리 위에 내용. 쪽(route)마다 불투명하게 그려 전환 중 겹쳐 보이지 않는다.
/// 상단 막대는 처음엔 투명, 스크롤하면 두꺼운 유리(테마의 appBarTheme + [GlassAppBarBackground]).
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({super.key, this.appBar, this.body, this.floatingActionButton, this.bottomNavigationBar, this.underAppBar = false});
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  /// 내용이 상단 막대 밑으로 흘러가게 (목록 화면). 아니면 막대 아래에서 시작
  final bool underAppBar;

  @override
  Widget build(BuildContext context) => AmbientBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: underAppBar,
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
        ),
      );
}

/// 상단 막대 뒤 흐림. 채움색은 테마(appBarTheme.backgroundColor, 스크롤되면 유리 채움)가 정한다
class GlassAppBarBackground extends StatelessWidget {
  const GlassAppBarBackground({super.key});
  @override
  Widget build(BuildContext context) {
    if (context.glassOff) return const SizedBox.expand();
    return ClipRect(child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: GlassTokens.blur, sigmaY: GlassTokens.blur), child: const SizedBox.expand()));
  }
}

/// 유리 알약 버튼 (보조 동작). 주 동작은 FilledButton(강조색 알약)
class GlassButton extends StatelessWidget {
  const GlassButton({super.key, required this.onPressed, required this.child, this.icon, this.tooltip});
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final fg = onPressed == null ? context.colors.textDisabled : g.onGlass;
    return Glass(
      kind: GlassKind.thin,
      circle: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              child: DefaultTextStyle.merge(
                style: context.text.titleMedium?.copyWith(color: fg),
                child: IconTheme.merge(
                  data: IconThemeData(color: fg, size: 20),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) ...[Icon(icon), const SizedBox(width: Space.sm)], child]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 유리 원 아이콘 버튼 (몰입 화면 재생 버튼 등)
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onPressed, required this.tooltip, this.size = 56, this.iconSize = 28, this.fill});
  final Widget icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;
  final double iconSize;
  final Color? fill;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          label: tooltip,
          excludeSemantics: true,
          child: Glass(
            circle: true,
            fill: fill,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: SizedBox(width: size, height: size, child: Center(child: IconTheme.merge(data: IconThemeData(size: iconSize, color: context.glass.onGlass), child: icon))),
              ),
            ),
          ),
        ),
      );
}

/// 유리 상단 막대: 처음엔 투명, 내용이 밑으로 지나가면 흐림 + 유리 채움(테마)
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({super.key, this.leading, this.title, this.actions, this.centerTitle, this.bottom, this.automaticallyImplyLeading = true});
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final bool? centerTitle;
  final PreferredSizeWidget? bottom;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) => AppBar(
        leading: leading,
        title: title,
        actions: actions,
        centerTitle: centerTitle,
        bottom: bottom,
        automaticallyImplyLeading: automaticallyImplyLeading,
        flexibleSpace: const GlassAppBarBackground(),
      );
}

/// 떠 있는 유리 탭 막대 (04장 §3.4). 선택된 탭은 알약 안의 렌즈가 미끄러져 옮겨 간다.
/// 선택 표시는 렌즈 + 굵은 글자(색만으로 전달하지 않음). 글자색은 본문색 — 뒤에 무엇이 비쳐도 대비 유지.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, required this.selected, required this.onSelect, required this.items});
  final int selected;
  final ValueChanged<int> onSelect;

  /// (아이콘, 선택 아이콘, 이름)
  final List<(Widget, Widget, String)> items;

  static const height = 64.0;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final n = items.length;
    return Glass(
      circle: true,
      child: SizedBox(
        height: height,
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth / n;
          return Stack(children: [
            AnimatedPositioned(
              duration: context.reduceMotion ? Duration.zero : Motion.base,
              curve: Curves.easeOutCubic,
              left: w * selected + 4, top: 4, bottom: 4, width: w - 8,
              child: DecoratedBox(decoration: ShapeDecoration(color: context.glassOff ? context.colors.accentSoft : g.lens, shape: const StadiumBorder())),
            ),
            Row(children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == selected,
                    label: '${items[i].$3}, 탭 ${i + 1}/$n',
                    excludeSemantics: true,
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => onSelect(i),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        IconTheme.merge(data: IconThemeData(color: g.onGlass, size: 24), child: i == selected ? items[i].$2 : items[i].$1),
                        const SizedBox(height: 2),
                        Text(items[i].$3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, height: 1.2, color: i == selected ? g.onGlass : g.onGlassMuted, fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500)),
                      ]),
                    ),
                  ),
                ),
            ]),
          ]);
        }),
      ),
    );
  }
}

/// 유리 알약 분할 버튼: 선택 항목 아래로 렌즈가 미끄러진다. 선택은 렌즈 + 굵은 글자로 표시
class GlassSegmented extends StatelessWidget {
  const GlassSegmented({super.key, required this.labels, required this.selected, required this.onSelect, this.values});
  final List<String> labels;

  /// 각 칸의 값 (없으면 0..n-1)
  final List<int>? values;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final vals = values ?? List.generate(labels.length, (i) => i);
    final idx = vals.indexOf(selected).clamp(0, labels.length - 1);
    return Glass(
      kind: GlassKind.thin,
      circle: true,
      child: SizedBox(
        height: 44,
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth / labels.length;
          return Stack(children: [
            AnimatedPositioned(
              duration: context.reduceMotion ? Duration.zero : Motion.base,
              curve: Curves.easeOutCubic,
              left: w * idx + 3, top: 3, bottom: 3, width: w - 6,
              child: DecoratedBox(decoration: ShapeDecoration(color: context.glassOff ? context.colors.accentSoft : g.lens, shape: const StadiumBorder())),
            ),
            Row(children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == idx,
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => onSelect(vals[i]),
                      child: Center(
                        child: Text(labels[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: g.onGlass, fontSize: 15, fontWeight: i == idx ? FontWeight.w700 : FontWeight.w500)),
                      ),
                    ),
                  ),
                ),
            ]),
          ]);
        }),
      ),
    );
  }
}

/// 슬리버 목록을 얇은 유리 카드에 담는다 (앨범·플레이리스트 곡 목록)
class GlassSliverCard extends StatelessWidget {
  const GlassSliverCard({super.key, required this.sliver});
  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    final off = context.glassOff;
    final g = context.glass;
    final c = context.colors;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      sliver: DecoratedSliver(
        decoration: BoxDecoration(
          color: off ? c.surface : g.thinFill,
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(color: off ? c.outline : g.rimTop.withValues(alpha: Theme.of(context).brightness == Brightness.light ? 0.9 : 0.16)),
        ),
        sliver: SliverPadding(padding: const EdgeInsets.symmetric(vertical: Space.sm), sliver: sliver),
      ),
    );
  }
}

/// 설정처럼 제목 + 항목 묶음이 이어지는 목록: 제목([isHeader])마다 아래 항목들을 얇은 유리 카드로 묶는다
List<Widget> glassGroups(List<Widget> items, bool Function(Widget) isHeader) {
  final out = <Widget>[];
  var group = <Widget>[];
  void flush() {
    if (group.isEmpty) return;
    final g = group;
    out.add(Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      child: Glass(kind: GlassKind.thin, radius: Radii.xl, padding: const EdgeInsets.symmetric(vertical: Space.xs), child: Column(children: g)),
    ));
    group = <Widget>[];
  }
  for (final w in items) {
    if (isHeader(w)) {
      flush();
      out.add(w);
    } else if (w is SizedBox) {
      flush();
      out.add(w);
    } else {
      group.add(w);
    }
  }
  flush();
  return out;
}
