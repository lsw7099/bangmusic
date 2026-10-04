// 기존 Windows BangMusic(v0.4.6) 테스트 이식 (L0). 출처: Documents/ChatGPT/음악 플레이어/test/
// 설계 규칙과 다르면 이 테스트가 우선한다 (CLAUDE.md, 03장 §6.3).
import 'dart:math';

import 'package:bangmusic/domain/lyrics.dart';
import 'package:bangmusic/domain/queue.dart';
import 'package:flutter_test/flutter_test.dart';

/// 기존 nextIndex(queue, index, opts)를 새 대기열로 흉내 낸다: 결과 인덱스(-1 = 끝)
int nextIndex(List<String> q, int index, {String repeat = 'off', bool shuffle = false, bool automatic = false, double Function()? random}) {
  if (q.isEmpty) return -1;
  final rnd = random == null ? Random(0) : _FixedRandom(random);
  final queue = PlayQueue.fromTracks(const QueueContext(ContextType.adhoc), q, start: index, repeat: RepeatMode.values.byName(repeat), random: rnd);
  if (shuffle) queue.setShuffle(true);
  final r = queue.next(user: !automatic);
  return switch (r) { PlayItem(:final item) => q.indexOf(item.trackId), Ended() => -1 };
}

class _FixedRandom implements Random {
  _FixedRandom(this.f);
  final double Function() f;
  @override
  int nextInt(int max) => (f() * max).floor().clamp(0, max - 1);
  @override
  double nextDouble() => f();
  @override
  bool nextBool() => f() >= 0.5;
}

void main() {
  test('core.test.cjs: queue handles end, repeat one, repeat all, manual next and shuffle without repeating current', () {
    final q = ['a', 'b', 'c'];
    expect(nextIndex(q, 2), -1);
    expect(nextIndex(q, 2, repeat: 'all'), 0);
    expect(nextIndex(q, 1, repeat: 'one', automatic: true), 1);
    expect(nextIndex(q, 1, repeat: 'one', automatic: false), 2);
    for (final random in [() => 0.0, () => 0.99]) {
      expect(nextIndex(q, 1, shuffle: true, random: random), isNot(1));
    }
    expect(nextIndex([], 0, repeat: 'all'), -1);
  });

  test('기존 구현(nextIndex): repeat=one에서 마지막 곡의 수동 다음은 끝', () {
    expect(nextIndex(['a', 'b', 'c'], 2, repeat: 'one', automatic: false), -1);
  });

  test('management.test.cjs: 다음에 재생은 현재 곡 바로 뒤, 맨 뒤 추가는 끝 (같은 곡 중복 허용)', () {
    final q = PlayQueue.fromTracks(const QueueContext(ContextType.adhoc), ['a', 'b']);
    q.playNext(['c']);
    expect([q.current!.trackId, ...q.upNext.map((e) => e.trackId), ...q.continuing.map((e) => e.trackId)], ['a', 'c', 'b']);
    q.addToEnd(['b']);
    expect([q.current!.trackId, ...q.upNext.map((e) => e.trackId), ...q.continuing.map((e) => e.trackId)], ['a', 'c', 'b', 'b']);
    expect(q.current!.trackId, 'a', reason: '편집해도 현재 곡은 그대로');
  });

  group('lyrics.test.cjs 이식', () {
    LyricVariantData v(String kind, List<(int?, String)> lines, {required bool synced}) =>
        LyricVariantData(kind: kind, synced: synced, lines: [for (final (t, s) in lines) LyricLineData(t, s)]);

    test('activeIndex (보정값 부호: 기존 correction=+0.5초 ⇔ 계약 offset_ms=-500)', () {
      // 서버가 해석한 결과: [{2.5 光}, {4.7 風\n空}, {6.5 ''}, {8.75 風}]
      final a = align([v('original', [(2500, '光'), (4700, '風\n空'), (6500, ''), (8750, '風')], synced: true)]);
      expect(a.currentIndex(2000, 0), -1);
      expect(a.currentIndex(4700, 0), 1);
      expect(a.currentIndex(4300, -500), 1);
      expect(a.currentIndex(99000, 0), 3);
      expect(a.currentIndex(3000, 0), 0);
    });

    test('Korean translation aligns by time; unmatched plain translations are not assigned incorrectly', () {
      final original = v('original', [(1000, '風'), (3000, '空')], synced: true);
      final timed = align([original, v('translation_ko', [(1000, '바람'), (3000, '하늘')], synced: true)]);
      expect(timed.rows.map((r) => r.translation), ['바람', '하늘']);
      final plainOne = align([original, v('translation_ko', [(null, '하나만')], synced: false)]);
      expect(plainOne.rows.map((r) => r.translation), [null, null]);
    });
  });
}
