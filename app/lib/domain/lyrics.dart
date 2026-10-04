// 3단 가사 (04장 LyricLine, S8 가사). 서버가 이미 LRC를 줄 단위로 해석해 주므로(02장 Lyrics)
// 앱은 세 종류를 한 줄 묶음으로 맞추고 현재 줄을 찾는다. 순수 Dart.
// 맞추기 규칙은 기존 Windows BangMusic의 lyrics-core.js mergeTranslation을 따른다:
// 시간 있는 번역은 시각 차 0.35초 미만, 시간 없는 번역은 원문과 줄 수가 같을 때만 순서대로.

class LyricLineData {
  const LyricLineData(this.tMs, this.text);
  final int? tMs;
  final String text;
}

class LyricVariantData {
  const LyricVariantData({required this.kind, required this.synced, required this.lines, this.sourceName});
  final String kind; // original | pronunciation_ko | translation_ko
  final bool synced;
  final List<LyricLineData> lines;
  final String? sourceName;
}

/// 화면의 한 줄 묶음: 원문 + (있으면) 발음·번역
class LyricRow {
  const LyricRow(this.tMs, this.original, this.pronunciation, this.translation);
  final int? tMs;
  final String original;
  final String? pronunciation;
  final String? translation;
}

class AlignedLyrics {
  const AlignedLyrics(this.rows, this.synced, this.hasPronunciation, this.hasTranslation);
  final List<LyricRow> rows;
  final bool synced;
  final bool hasPronunciation;
  final bool hasTranslation;

  static const empty = AlignedLyrics([], false, false, false);

  /// 위치(ms)에서 현재 줄. 보정값이 양수면 가사를 늦춘다(02장 Lyrics.offset_ms). 첫 줄 전이면 -1.
  int currentIndex(int positionMs, int offsetMs) {
    if (!synced || rows.isEmpty) return -1;
    final t = positionMs - offsetMs;
    var lo = 0;
    var hi = rows.length - 1;
    var ans = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if ((rows[mid].tMs ?? 0) <= t) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return ans;
  }
}

/// 발음·번역 줄을 원문 줄에 붙인다. 시간이 있으면 시각 차 [toleranceMs] 미만, 없으면 줄 수가 같을 때만 순서대로.
AlignedLyrics align(List<LyricVariantData> variants, {int toleranceMs = 350}) {
  LyricVariantData? find(String k) {
    for (final v in variants) {
      if (v.kind == k) return v;
    }
    return null;
  }

  final orig = find('original');
  final pron = find('pronunciation_ko');
  final tr = find('translation_ko');
  if (orig == null || orig.lines.isEmpty) return AlignedLyrics.empty;

  String? match(LyricVariantData? v, int index, int? t) {
    if (v == null || v.lines.isEmpty) return null;
    if (orig.synced && v.synced && t != null) {
      // 기존 앱: 시각 차가 0.35초 "미만"인 첫 줄
      for (final l in v.lines) {
        if (l.tMs != null && (l.tMs! - t).abs() < toleranceMs) return l.text;
      }
      return null;
    }
    if (v.synced) return null; // 원문에 시간이 없으면 시간 있는 번역을 순서로 붙이지 않는다
    // 시간 없는 번역은 줄 수가 같을 때만 (아니면 엉뚱한 줄에 붙지 않게 비워 둔다)
    return v.lines.length == orig.lines.length ? v.lines[index].text : null;
  }

  final rows = <LyricRow>[
    for (var i = 0; i < orig.lines.length; i++)
      LyricRow(orig.lines[i].tMs, orig.lines[i].text, match(pron, i, orig.lines[i].tMs), match(tr, i, orig.lines[i].tMs)),
  ];
  return AlignedLyrics(rows, orig.synced, pron != null && pron.lines.isNotEmpty, tr != null && tr.lines.isNotEmpty);
}
