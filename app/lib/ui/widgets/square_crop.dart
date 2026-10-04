// 플레이리스트 표지: 고른 사진의 가운데를 정사각형으로 잘라 PNG로 (04장 S6 "사진 선택 → 정사각 자르기 → 업로드").
// [P5 결정] 자르기 화면 대신 가운데 자동 자르기 — 패키지를 더 들이지 않는다. 서버는 비율을 유지한 채 줄이기만 한다.
// 서버 한도(5MB)를 넘으면 더 작게 다시 만든다. 메타데이터(EXIF 위치 등)는 다시 그리면서 사라지고, 서버도 다시 인코딩한다.
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

const maxCoverBytes = 5 * 1024 * 1024;

Future<Uint8List> squareCropPng(Uint8List bytes, {int maxSide = 1000}) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final src = (await codec.getNextFrame()).image;
  try {
    var side = min(min(src.width, src.height), maxSide);
    while (true) {
      final out = await _crop(src, side);
      if (out.length <= maxCoverBytes || side <= 300) return out;
      side = (side * 0.75).round();
    }
  } finally {
    src.dispose();
  }
}

Future<Uint8List> _crop(ui.Image src, int side) async {
  final s = min(src.width, src.height).toDouble();
  final from = ui.Rect.fromLTWH((src.width - s) / 2, (src.height - s) / 2, s, s);
  final rec = ui.PictureRecorder();
  ui.Canvas(rec).drawImageRect(src, from, ui.Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()), ui.Paint()..filterQuality = ui.FilterQuality.high);
  final img = await rec.endRecording().toImage(side, side);
  try {
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    img.dispose();
  }
}
