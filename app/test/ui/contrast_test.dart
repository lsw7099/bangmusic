// 대비 측정 (04장 §3: 본문 4.5:1, 큰 글자·아이콘 3:1 이상 — P5 수용 기준 "대비 측정 통과").
// WCAG 2.x 상대 휘도로 실제 화면에서 쓰는 글자·배경 조합을 라이트·다크 모두 계산한다. textDisabled는 비활성 표시라 WCAG 예외.
import 'dart:math';

import 'package:bangmusic/ui/ambient.dart';
import 'package:bangmusic/ui/glass.dart';
import 'package:bangmusic/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

double _channel(double c) => c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
double luminance(Color c) => 0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);
double contrast(Color a, Color b) {
  final (x, y) = (luminance(a), luminance(b));
  return (max(x, y) + 0.05) / (min(x, y) + 0.05);
}

/// (글자, 배경, 최소 대비, 어디에 쓰나)
List<(String, Color, Color, double)> pairs(BangColors c) => [
      // 본문 글자 4.5
      ('text / bg', c.text, c.bg, 4.5),
      ('text / surface', c.text, c.surface, 4.5),
      ('text / surfaceAlt (입력란·칩)', c.text, c.surfaceAlt, 4.5),
      ('text / accentSoft (배너·선택 칩)', c.text, c.accentSoft, 4.5),
      ('textMuted / bg (보조 문구)', c.textMuted, c.bg, 4.5),
      ('textMuted / surface (미니 플레이어 아티스트)', c.textMuted, c.surface, 4.5),
      ('textMuted / surfaceAlt', c.textMuted, c.surfaceAlt, 4.5),
      ('accent / bg (재생 중 제목·글자 버튼)', c.accent, c.bg, 4.5),
      ('accent / surface', c.accent, c.surface, 4.5),
      // accent / accentSoft는 라이트 4.07:1 → 강조 배경 위 글자는 본문색을 쓴다(배너 버튼). 이 조합은 쓰지 않는다
      ('onAccent / accent (채운 버튼)', c.onAccent, c.accent, 4.5),
      ('danger / bg (오류·실패 문구)', c.danger, c.bg, 4.5),
      ('danger / surface', c.danger, c.surface, 4.5),
      ('success / bg (완료 문구)', c.success, c.bg, 4.5),
      ('warning / bg (대기·업데이트 문구)', c.warning, c.bg, 4.5),
      // 아이콘·큰 글자 3.0
      ('accent 아이콘 / surface', c.accent, c.surface, 3.0),
      ('textMuted 아이콘 / accentSoft', c.textMuted, c.accentSoft, 3.0),
      ('success 아이콘 / surface', c.success, c.surface, 3.0),
      ('warning 아이콘 / surface', c.warning, c.surface, 3.0),
      ('danger 아이콘 / accentSoft', c.danger, c.accentSoft, 3.0),
    ];

void main() {
  for (final (name, c) in [('라이트', BangColors.light), ('다크', BangColors.dark)]) {
    test('$name 테마 대비', () {
      final fails = <String>[];
      final lines = <String>[];
      for (final (label, fg, bg, need) in pairs(c)) {
        final r = contrast(fg, bg);
        lines.add('${r.toStringAsFixed(2).padLeft(6)}  (≥$need)  $label');
        if (r < need) fails.add('$label: ${r.toStringAsFixed(2)} < $need');
      }
      // ignore: avoid_print
      print('── $name\n${lines.join('\n')}');
      expect(fails, isEmpty);
    });
  }

  widgetContrast();
  glassContrast();

  test('측정 함수 검증: 흑백 21:1, 같은 색 1:1, 04장 §3의 "accent ≈ 4.9:1(흰 배경)"', () {
    expect(contrast(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(contrast(Colors.white, Colors.white), 1);
    expect(contrast(BangColors.light.accent, Colors.white), closeTo(4.9, 0.15));
  });
}

/// 실제로 그려진 글자색 (테마 기본값이 토큰과 다르게 칠하는 경우를 잡는다)
Color _painted(WidgetTester t, String text) => t.renderObject<RenderParagraph>(find.text(text)).text.style!.color!;

void widgetContrast() {
  for (final (name, b, c) in [('라이트', Brightness.light, BangColors.light), ('다크', Brightness.dark, BangColors.dark)]) {
    testWidgets('$name: 선택된 칩·채운 버튼·글자 버튼의 실제 글자 대비', (t) async {
      await t.pumpWidget(MaterialApp(
        theme: buildTheme(b),
        home: Scaffold(
          backgroundColor: c.bg,
          body: Column(children: [
            ChoiceChip(label: const Text('선택됨'), selected: true, onSelected: (_) {}),
            ChoiceChip(label: const Text('선택 안 됨'), selected: false, onSelected: (_) {}),
            FilledButton(onPressed: () {}, child: const Text('채운 버튼')),
            TextButton(onPressed: () {}, child: const Text('글자 버튼')),
          ]),
        ),
      ));
      expect(contrast(_painted(t, '선택됨'), c.accentSoft), greaterThanOrEqualTo(4.5), reason: '선택된 칩');
      expect(contrast(_painted(t, '선택 안 됨'), c.surfaceAlt), greaterThanOrEqualTo(4.5), reason: '선택 안 된 칩');
      expect(contrast(_painted(t, '채운 버튼'), c.accent), greaterThanOrEqualTo(4.5), reason: '채운 버튼');
      expect(contrast(_painted(t, '글자 버튼'), c.bg), greaterThanOrEqualTo(4.5), reason: '글자 버튼');
    });
  }
}

/// sRGB 알파 합성 (화면이 실제로 섞는 방식)
Color over(Color top, Color under) {
  final a = top.a;
  return Color.from(alpha: 1, red: top.r * a + under.r * (1 - a), green: top.g * a + under.g * (1 - a), blue: top.b * a + under.b * (1 - a));
}

/// 04장 §3.4 유리 재질의 대비 보장
void glassContrast() {
  for (final (name, b, c, g) in [('라이트', Brightness.light, BangColors.light, GlassTokens.light), ('다크', Brightness.dark, BangColors.dark, GlassTokens.dark)]) {
    test('$name: 떠 있는 유리 위 글자는 뒤에 흰색·검정이 비쳐도 4.5:1 (탭 막대·미니 플레이어·배너)', () {
      for (final under in [Colors.white, Colors.black]) {
        final face = over(g.thickFill, under);
        expect(contrast(g.onGlass, face), greaterThanOrEqualTo(4.5), reason: 'onGlass / 유리(뒤 $under)');
        expect(contrast(g.onGlassMuted, face), greaterThanOrEqualTo(4.5), reason: 'onGlassMuted / 유리(뒤 $under)');
      }
    });

    test('$name: 배경 덩어리 + 얇은 유리 카드 위 본문·보조 글자 4.5:1 (덩어리 색은 어떤 표지에서 왔든)', () {
      // 덩어리는 clampForTheme을 거친다. 색상환을 돌며 가장 나쁜 경우를 찾는다
      var worst = 99.0;
      for (var hue = 0; hue < 360; hue += 15) {
        for (final sat in [0.2, 1.0]) {
          for (final light in [0.0, 0.5, 1.0]) {
            final blob = clampForTheme(HSLColor.fromAHSL(1, hue.toDouble(), sat, light).toColor(), b);
            final ground = over(blob.withValues(alpha: blobAlpha(b == Brightness.dark)), c.bg);
            for (final face in [ground, over(g.thinFill, ground)]) {
              worst = min(worst, min(contrast(c.text, face), contrast(c.textMuted, face)));
            }
          }
        }
      }
      // ignore: avoid_print
      print('$name 덩어리 위 최저 대비 ${worst.toStringAsFixed(2)}');
      expect(worst, greaterThanOrEqualTo(4.5));
    });
  }

  test('몰입 화면: 표지 밝기에 맞춘 가림막 위 흰 글자·보조 글자 4.5:1, 강조 아이콘 3:1', () {
    final g = GlassTokens.dark;
    for (var v = 0; v <= 255; v += 5) {
      final art = Color.fromARGB(255, v, v, v);
      final scrim = scrimFor(luminance(art));
      final face = over(Colors.black.withValues(alpha: scrim), art);
      expect(contrast(g.onGlass, face), greaterThanOrEqualTo(4.5), reason: '회색 $v, 가림막 $scrim');
      expect(contrast(g.onGlassMuted, face), greaterThanOrEqualTo(4.5), reason: '보조 글자, 회색 $v');
      expect(contrast(BangColors.dark.accent, face), greaterThanOrEqualTo(3.0), reason: '셔플·반복 켜짐 아이콘, 회색 $v');
    }
  });
}
