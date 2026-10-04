// 가사 정렬·현재 줄, 재생 상태 규칙 (L0)
import 'package:bangmusic/domain/lyrics.dart';
import 'package:bangmusic/domain/playback_state.dart';
import 'package:flutter_test/flutter_test.dart';

LyricVariantData v(String kind, List<(int?, String)> lines, {bool synced = true}) =>
    LyricVariantData(kind: kind, synced: synced, lines: [for (final (t, s) in lines) LyricLineData(t, s)]);

void main() {
  group('가사 정렬', () {
    test('같은 시각의 발음·번역을 원문 줄에 붙인다 (허용 오차 안)', () {
      final a = align([
        v('original', [(0, '夜明け'), (10000, '空')]),
        v('pronunciation_ko', [(0, '요아케'), (10200, '소라')]),
        v('translation_ko', [(10000, '하늘')]),
      ]);
      expect(a.rows.length, 2);
      expect(a.rows[0].pronunciation, '요아케');
      expect(a.rows[0].translation, isNull, reason: '0초 번역 없음');
      expect(a.rows[1].pronunciation, '소라');
      expect(a.rows[1].translation, '하늘');
      expect(a.hasPronunciation && a.hasTranslation, isTrue);
    });

    test('동기 정보가 없으면 순서대로 짝짓고 현재 줄이 없다', () {
      final a = align([
        v('original', [(null, '一'), (null, '二')], synced: false),
        v('translation_ko', [(null, '하나'), (null, '둘')], synced: false),
      ]);
      expect(a.rows[1].translation, '둘');
      expect(a.currentIndex(50000, 0), -1);
    });

    test('원문이 없으면 빈 가사', () {
      expect(align([v('translation_ko', [(0, 'x')])]).rows, isEmpty);
    });

    test('현재 줄과 보정값(양수면 가사를 늦춘다)', () {
      final a = align([v('original', [(1000, 'a'), (5000, 'b'), (9000, 'c')])]);
      expect(a.currentIndex(500, 0), -1);
      expect(a.currentIndex(1000, 0), 0);
      expect(a.currentIndex(8999, 0), 1);
      expect(a.currentIndex(9500, 0), 2);
      expect(a.currentIndex(5100, 250), 0, reason: '250ms 늦추면 5.1초는 아직 첫 줄');
      expect(a.currentIndex(4900, -250), 1);
    });
  });

  group('재생 상태', () {
    test('자동 재개는 일시 포커스 상실 후 포커스 복귀일 때만 (03장 §6.5)', () {
      expect(shouldAutoResume(PauseReason.focusTransient, focusRegained: true), isTrue);
      for (final r in [PauseReason.user, PauseReason.focusLoss, PauseReason.noisy, PauseReason.error, null]) {
        expect(shouldAutoResume(r, focusRegained: true), isFalse, reason: '$r');
      }
    });

    test('건너뛰기 폭주 방지: 연속 5곡 또는 한 바퀴 (03장 §6.4)', () {
      final g = SkipGuard(20);
      for (var i = 0; i < 4; i++) {
        expect(g.skippedShouldStop(), isFalse);
      }
      expect(g.skippedShouldStop(), isTrue);
      final small = SkipGuard(3);
      small.skippedShouldStop();
      small.played();
      expect(small.skippedShouldStop(), isFalse);
      expect(small.skippedShouldStop(), isFalse);
      expect(small.skippedShouldStop(), isTrue, reason: '대기열 3곡 한 바퀴');
    });
  });
}
