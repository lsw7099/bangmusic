// 배경 덩어리 (04장 §3.4 배경 층). 지금 재생 중인 곡의 표지에서 색 3개를 뽑아 흐린 덩어리로 깐다.
// 계속 움직이는 효과는 두지 않는다(배터리) — 곡이 바뀌면 0.8초에 걸쳐 색만 바뀐다.
// 명도 범위를 고정해 그 위 글자 대비를 보장한다(다크: 어둡게, 라이트: 옅게).
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../platform/player_port.dart';
import 'glass.dart';
import 'scope.dart';
import 'tokens.dart';

/// 표지 픽셀(RGBA)에서 대표색 최대 3개. 채도·명도가 너무 낮은 픽셀은 빼고, 색상환 12칸 중 무게가 큰 칸의 평균.
List<Color> paletteFromPixels(Uint8List rgba) {
  final weight = List<double>.filled(12, 0);
  final sum = List.generate(12, (_) => [0.0, 0.0, 0.0]);
  for (var i = 0; i + 3 < rgba.length; i += 4) {
    if (rgba[i + 3] < 128) continue;
    final c = Color.fromARGB(255, rgba[i], rgba[i + 1], rgba[i + 2]);
    final hsv = HSVColor.fromColor(c);
    if (hsv.saturation < 0.18 || hsv.value < 0.15) continue;
    final b = (hsv.hue / 30).floor() % 12;
    final w = hsv.saturation * hsv.value;
    weight[b] += w;
    sum[b][0] += rgba[i] * w;
    sum[b][1] += rgba[i + 1] * w;
    sum[b][2] += rgba[i + 2] * w;
  }
  final order = List.generate(12, (i) => i)..sort((a, b) => weight[b].compareTo(weight[a]));
  return [
    for (final b in order.take(3))
      if (weight[b] > 0) Color.fromARGB(255, (sum[b][0] / weight[b]).round(), (sum[b][1] / weight[b]).round(), (sum[b][2] / weight[b]).round()),
  ];
}

/// 표지 픽셀의 평균 상대 휘도(0~1, WCAG 공식). 몰입 화면 가림막 세기를 정한다
double lumaFromPixels(Uint8List rgba) {
  var sum = 0.0;
  var n = 0;
  double lin(int v) {
    final x = v / 255;
    return x <= 0.03928 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4).toDouble();
  }
  for (var i = 0; i + 3 < rgba.length; i += 4) {
    sum += 0.2126 * lin(rgba[i]) + 0.7152 * lin(rgba[i + 1]) + 0.0722 * lin(rgba[i + 2]);
    n++;
  }
  return n == 0 ? 0.2 : sum / n;
}

/// 몰입 화면 가림막(검정) 불투명도: 가림막을 지난 배경의 휘도가 0.07 이하가 되게(흰 글자 4.5:1 이상, 보조 글자 #CFC4C6도 4.5:1).
/// 범위 0.35~0.85. 흐린 배경은 평균에 가까우므로 평균 휘도로 정한다
double scrimFor(double luma) => (1 - 0.07 / max(luma, 0.0001)).clamp(0.35, 0.85);

/// 덩어리 색을 테마 범위로 누른다: 다크는 명도 0.12~0.20·채도 ≤0.55, 라이트는 명도 0.88~0.95·채도 ≤0.6.
/// 어떤 표지 색이든 그 위(얇은 유리 포함) 본문·보조 글자가 4.5:1 이상이 되는 범위(test/ui/contrast_test.dart가 색상환 전체로 확인)
Color clampForTheme(Color c, Brightness b) {
  final h = HSLColor.fromColor(c);
  final dark = b == Brightness.dark;
  final s = h.saturation.clamp(0.0, dark ? 0.55 : 0.6);
  final l = dark ? h.lightness.clamp(0.12, 0.20) : h.lightness.clamp(0.88, 0.95);
  return h.withSaturation(s).withLightness(l).toColor();
}

/// 덩어리 불투명도 (대비 시험과 같은 값)
double blobAlpha(bool dark) => dark ? 0.55 : 0.60;

/// 재생 중인 곡이 바뀔 때 표지 색을 다시 뽑는다
class AmbientPalette extends ChangeNotifier {
  AmbientPalette(this.player) {
    player.queueChanged.addListener(_onChange);
    _onChange();
  }

  final PlayerPort player;
  final _cache = <String, (List<Color>, double)>{};
  String? _artworkId;
  List<Color> colors = const [];

  /// 지금 표지의 평균 휘도 (표지가 없으면 null)
  double? luma;

  void _onChange() {
    final id = player.currentTrack?.artworkId;
    if (id == _artworkId) return;
    _artworkId = id;
    if (id == null) {
      _set(const [], null);
      return;
    }
    final hit = _cache[id];
    if (hit != null) {
      _set(hit.$1, hit.$2);
      return;
    }
    unawaited(_load(id));
  }

  Future<void> _load(String id) async {
    try {
      final File? f = await player.cachedArtwork(id, 96);
      if (f == null) return;
      final codec = await ui.instantiateImageCodec(await f.readAsBytes(), targetWidth: 24, targetHeight: 24);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      frame.image.dispose();
      if (data == null) return;
      final px = data.buffer.asUint8List();
      final p = paletteFromPixels(px);
      final l = lumaFromPixels(px);
      _cache[id] = (p, l);
      if (_artworkId == id) _set(p, l);
    } catch (_) {
      // 표지를 못 읽으면 기본 색 그대로
    }
  }

  void _set(List<Color> c, double? l) {
    colors = c;
    luma = l;
    notifyListeners();
  }

  @override
  void dispose() {
    player.queueChanged.removeListener(_onChange);
    super.dispose();
  }
}

/// 바탕색 + 덩어리 3개. 투명도 줄이기면 단색 bg
class AmbientBackdrop extends StatelessWidget {
  const AmbientBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (context.glassOff) return ColoredBox(color: c.bg, child: child);
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    final palette = scope?.notifier?.ambient;
    if (palette == null) return _paint(context, const [], child);
    return ListenableBuilder(listenable: palette, builder: (context, _) => _paint(context, palette.colors, child));
  }

  Widget _paint(BuildContext context, List<Color> from, Widget child) {
    final c = context.colors;
    final b = Theme.of(context).brightness;
    // 표지가 없으면 강조색 계열 셋
    final base = from.isEmpty ? [c.accent, const Color(0xFF7A4CC2), const Color(0xFF2E7DBE)] : [...from, ...from, ...from].take(3).toList();
    final blobs = [for (final x in base) clampForTheme(x, b)];
    return TweenAnimationBuilder<_Blobs>(
      tween: _BlobsTween(end: _Blobs(blobs)),
      duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, v, child) => CustomPaint(painter: _AmbientPainter(bg: c.bg, blobs: v.colors, dark: b == Brightness.dark), child: child),
      child: child,
    );
  }
}

class _Blobs {
  const _Blobs(this.colors);
  final List<Color> colors;
}

class _BlobsTween extends Tween<_Blobs> {
  _BlobsTween({super.end});
  @override
  _Blobs lerp(double t) {
    final a = begin?.colors ?? end!.colors;
    final e = end!.colors;
    return _Blobs([for (var i = 0; i < e.length; i++) Color.lerp(i < a.length ? a[i] : e[i], e[i], t)!]);
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({required this.bg, required this.blobs, required this.dark});
  final Color bg;
  final List<Color> blobs;
  final bool dark;

  // 덩어리 자리(화면 비율)와 반지름(긴 변 비율). 고정 — 화면마다 같은 모양이라 전환이 자연스럽다
  static const _spots = [(0.15, 0.08, 0.75), (0.95, 0.38, 0.65), (0.30, 0.92, 0.70)];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = bg);
    final longest = size.longestSide;
    for (var i = 0; i < blobs.length && i < _spots.length; i++) {
      final (x, y, r) = _spots[i];
      final center = Offset(size.width * x, size.height * y);
      final radius = longest * r;
      final color = blobs[i].withValues(alpha: blobAlpha(dark));
      canvas.drawCircle(
        center,
        radius,
        Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.bg != bg || old.dark != dark || !_same(old.blobs, blobs);

  static bool _same(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

