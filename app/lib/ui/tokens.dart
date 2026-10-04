// 디자인 토큰 (04장 §3). 값은 독자적으로 정한 것이며 특정 상용 서비스를 본뜨지 않는다(05장 §8.7).
import 'package:flutter/material.dart';

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
  static const sm = 8.0, md = 12.0, lg = 20.0;
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

ThemeData buildTheme(Brightness b) {
  final c = b == Brightness.light ? BangColors.light : BangColors.dark;
  final scheme = ColorScheme(
    brightness: b, primary: c.accent, onPrimary: c.onAccent, secondary: c.accent, onSecondary: c.onAccent,
    error: c.danger, onError: c.onAccent, surface: c.surface, onSurface: c.text,
    surfaceContainerHighest: c.surfaceAlt, outline: c.outline, primaryContainer: c.accentSoft, onPrimaryContainer: c.text,
    // 선택된 칩·분할 버튼 글자(onSecondaryContainer)와 보조 글자(onSurfaceVariant)를 토큰으로 — 기본값은 대비 1.2:1이었다
    secondaryContainer: c.accentSoft, onSecondaryContainer: c.text, onSurfaceVariant: c.textMuted,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    textTheme: _textTheme(c.text),
    extensions: [c],
    // 그림자 대신 surface + outline 1dp (04장 §3.3 elevation.sheet)
    cardTheme: CardThemeData(elevation: 0, color: c.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md), side: BorderSide(color: c.outline))),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: c.surface, shape: RoundedRectangleBorder(side: BorderSide(color: c.outline), borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.lg)))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: c.surfaceAlt, border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide.none)),
    // 칩 체크는 본문색. 글자색은 색 체계(onSecondaryContainer 등)로 정한다 — labelStyle을 덮어쓰면 글꼴·크기 지정을 잃었다(상태 갤러리에서 발견)
    chipTheme: ChipThemeData(
      selectedColor: c.accentSoft, backgroundColor: c.surfaceAlt, side: BorderSide.none, showCheckmark: true, checkmarkColor: c.text,
    ),
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
