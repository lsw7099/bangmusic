// 디자인 토큰 (04장 §3). 값은 독자적으로 정한 것이며 특정 상용 서비스를 본뜨지 않는다(05장 §8.7).
// 유리 재질(§3.4)의 토큰은 glass.dart. 여기서는 Material 구성요소들을 유리 모양으로 맞춘다.
import 'package:flutter/material.dart';

import 'glass.dart';

class BangColors extends ThemeExtension<BangColors> {
  const BangColors({
    required this.bg, required this.surface, required this.surfaceAlt, required this.outline, required this.text,
    required this.textMuted, required this.textDisabled, required this.accent, required this.onAccent, required this.accentSoft,
    required this.success, required this.warning, required this.danger,
  });

  final Color bg, surface, surfaceAlt, outline, text, textMuted, textDisabled, accent, onAccent, accentSoft, success, warning, danger;

  static const light = BangColors(
    bg: Color(0xFFFBF8F7), surface: Color(0xFFFFFFFF), surfaceAlt: Color(0xFFF3EDEC), outline: Color(0xFFE1D7D6),
    text: Color(0xFF1C1718), textMuted: Color(0xFF6B5F61), textDisabled: Color(0xFFA89D9E), accent: Color(0xFFD7263D),
    onAccent: Color(0xFFFFFFFF), accentSoft: Color(0xFFFBE3E6), success: Color(0xFF1E7A46), warning: Color(0xFF9A5B00), danger: Color(0xFFB3261E),
  );

  static const dark = BangColors(
    bg: Color(0xFF121011), surface: Color(0xFF1E1A1B), surfaceAlt: Color(0xFF2A2526), outline: Color(0xFF3A3435),
    text: Color(0xFFF4EEEE), textMuted: Color(0xFFB5A9AB), textDisabled: Color(0xFF6E6466), accent: Color(0xFFFF6B7D),
    onAccent: Color(0xFF2A0A0F), accentSoft: Color(0xFF40161C), success: Color(0xFF5BD08A), warning: Color(0xFFF2B34C), danger: Color(0xFFFF8A80),
  );

  @override
  BangColors copyWith() => this;

  @override
  BangColors lerp(ThemeExtension<BangColors>? other, double t) => t < 0.5 ? this : (other as BangColors? ?? this);
}

/// 간격 (dp)
class Space {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, xxl = 32.0;
}

class Radii {
  static const sm = 8.0, md = 12.0, lg = 20.0, xl = 28.0;
}

class Motion {
  static const fast = Duration(milliseconds: 120), base = Duration(milliseconds: 220), slow = Duration(milliseconds: 360);
}

/// 글자 (04장 §3.2). 크기 단위는 sp, 시스템 글자 배율을 따른다. 기기 기본 글꼴.
TextTheme _textTheme(Color text) => TextTheme(
      displaySmall: TextStyle(fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w700, color: text),
      titleLarge: TextStyle(fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w700, color: text),
      bodyLarge: TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400, color: text),
      titleMedium: TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w600, color: text),
      bodySmall: TextStyle(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w400, color: text),
    );

class LyricStyles {
  static const active = TextStyle(fontSize: 22, height: 32 / 22, fontWeight: FontWeight.w700);
  static const normal = TextStyle(fontSize: 18, height: 28 / 18, fontWeight: FontWeight.w500);
  static const sub = TextStyle(fontSize: 14, height: 22 / 14, fontWeight: FontWeight.w400);
}

/// [glassOff]: 투명도 줄이기(설정·시스템 고대비) — 유리 대신 불투명 면 (04장 §3.4)
ThemeData buildTheme(Brightness b, {bool glassOff = false}) {
  final c = b == Brightness.light ? BangColors.light : BangColors.dark;
  final g = b == Brightness.light ? GlassTokens.light : GlassTokens.dark;
  final scheme = ColorScheme(
    brightness: b, primary: c.accent, onPrimary: c.onAccent, secondary: c.accent, onSecondary: c.onAccent,
    error: c.danger, onError: c.onAccent, surface: c.surface, onSurface: c.text,
    surfaceContainerHighest: c.surfaceAlt, outline: c.outline, primaryContainer: c.accentSoft, onPrimaryContainer: c.text,
    // 선택된 칩·분할 버튼 글자(onSecondaryContainer)와 보조 글자(onSurfaceVariant)를 토큰으로 — 기본값은 대비 1.2:1이었다
    secondaryContainer: c.accentSoft, onSecondaryContainer: c.text, onSurfaceVariant: c.textMuted,
  );
  // 떠 있는 면(시트·대화상자): 흐림 없이 그리므로 채움을 더 짙게. 투명도 줄이기면 불투명 surface
  final floatFill = glassOff ? c.surface : (b == Brightness.light ? const Color(0xEBFFFFFF) : const Color(0xF01A1617));
  final cardFill = glassOff ? c.surface : g.thinFill;
  final rim = glassOff ? c.outline : g.rimTop.withValues(alpha: b == Brightness.light ? 0.9 : 0.16);
  final pill = const StadiumBorder();
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    textTheme: _textTheme(c.text),
    extensions: [c],
    // 상단 막대: 처음엔 투명, 내용이 밑으로 지나가면 유리 채움(흐림은 GlassAppBar의 뒤 흐림)
    appBarTheme: AppBarTheme(
      backgroundColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.scrolledUnder) ? (glassOff ? c.surface : g.thickFill) : Colors.transparent),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: c.text,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w700, color: c.text),
    ),
    // 카드: 얇은 유리(흐림 없음) + 가장자리 빛
    cardTheme: CardThemeData(elevation: 0, color: cardFill, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg), side: BorderSide(color: rim))),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: floatFill, surfaceTintColor: Colors.transparent, showDragHandle: true, dragHandleColor: c.textMuted,
      shape: RoundedRectangleBorder(side: BorderSide(color: rim), borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.xl))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: floatFill, surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(side: BorderSide(color: rim), borderRadius: BorderRadius.circular(Radii.xl)),
    ),
    popupMenuTheme: PopupMenuThemeData(color: floatFill, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(side: BorderSide(color: rim), borderRadius: BorderRadius.circular(Radii.lg))),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: b == Brightness.light ? const Color(0xF02A2526) : const Color(0xF0F4EEEE),
      contentTextStyle: TextStyle(color: b == Brightness.light ? const Color(0xFFF4EEEE) : const Color(0xFF1C1718), fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: glassOff ? c.surfaceAlt : g.thinFill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.lg), borderSide: BorderSide(color: rim)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.lg), borderSide: BorderSide(color: rim)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.lg), borderSide: BorderSide(color: c.accent, width: 2)),
    ),
    // 칩 체크는 본문색. 글자색은 색 체계(onSecondaryContainer 등)로 정한다 — labelStyle을 덮어쓰면 글꼴·크기 지정을 잃었다(상태 갤러리에서 발견)
    chipTheme: ChipThemeData(
      selectedColor: glassOff ? c.accentSoft : g.lens, backgroundColor: glassOff ? c.surfaceAlt : g.thinFill,
      side: BorderSide(color: rim), shape: pill, showCheckmark: true, checkmarkColor: c.text,
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: pill, minimumSize: const Size(48, 48), padding: const EdgeInsets.symmetric(horizontal: Space.xl))),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: pill, minimumSize: const Size(48, 48), padding: const EdgeInsets.symmetric(horizontal: Space.xl),
        backgroundColor: cardFill, foregroundColor: c.text, side: BorderSide(color: rim),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: pill)),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: cardFill, selectedBackgroundColor: glassOff ? c.accentSoft : g.lens,
        foregroundColor: c.text, selectedForegroundColor: c.text, side: BorderSide(color: rim), shape: pill,
      ),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 5, activeTrackColor: c.accent, inactiveTrackColor: c.text.withValues(alpha: 0.18),
      thumbColor: c.accent, overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
    ),
    dividerTheme: DividerThemeData(color: c.outline.withValues(alpha: 0.6), thickness: 1),
    listTileTheme: const ListTileThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Radii.md)))),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent, linearTrackColor: c.text.withValues(alpha: 0.12)),
    navigationBarTheme: NavigationBarThemeData(backgroundColor: c.surface, indicatorColor: c.accentSoft),
    materialTapTargetSize: MaterialTapTargetSize.padded, // 최소 48dp
  );
}

extension BangTheme on BuildContext {
  BangColors get colors => Theme.of(this).extension<BangColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;
  double get textScale => MediaQuery.textScalerOf(this).scale(1);
}
