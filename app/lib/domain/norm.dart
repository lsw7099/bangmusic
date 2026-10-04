// 검색 정규화 (01장 §4.6). 서버 server/src/norm.ts와 같은 규칙 — 오프라인 로컬 검색(03장 §5.6)이 서버 검색과 같은 결과를 내도록.
// NFKC → 소문자 → 가타카나를 히라가나로 → 공백 축약.
import 'package:unorm_dart/unorm_dart.dart' as unorm;

String norm(String input) {
  final s = unorm.nfkc(input).toLowerCase();
  final out = StringBuffer();
  for (final cp in s.runes) {
    // 가타카나 ァ(30A1)~ヶ(30F6) → 히라가나 (0x60 차이). ー(30FC)는 그대로 둔다.
    out.writeCharCode(cp >= 0x30a1 && cp <= 0x30f6 ? cp - 0x60 : cp);
  }
  return out.toString().replaceAll(RegExp(r'\s+', unicode: true), ' ').trim();
}
