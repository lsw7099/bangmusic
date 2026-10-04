// 03장 §6.3 셔플·반복·곡 전환 규칙 (L0). 난수는 고정 시드.
// [확인 필요] 기존 BangMusic 셔플/반복 테스트를 받으면 여기에 이식하고 다른 점을 기록한다.
import 'dart:math';

import 'package:bangmusic/domain/queue.dart';
import 'package:flutter_test/flutter_test.dart';

const ctx = QueueContext(ContextType.album, 'alb_1', '앨범');
final tracks = ['a', 'b', 'c', 'd', 'e'];

PlayQueue make({int start = 0, bool shuffle = false, RepeatMode repeat = RepeatMode.off, int seed = 1}) {
  var n = 0;
  return PlayQueue.fromTracks(ctx, tracks, start: start, shuffle: shuffle, repeat: repeat, random: Random(seed), newId: () => 'q${n++}');
}

String? cur(PlayQueue q) => q.current?.trackId;
String? played(Advance a) => switch (a) { PlayItem(:final item) => item.trackId, Ended() => null };

void main() {
  group('기본 진행', () {
    test('다음 곡은 원래 순서, 끝에서 반복 꺼짐이면 Ended + 마지막 곡에 머문다', () {
      final q = make(start: 3);
      expect(played(q.next(user: false)), 'e');
      final end = q.next(user: false);
      expect(end, isA<Ended>());
      expect((end as Ended).item?.trackId, 'e');
      expect(cur(q), 'e');
    });

    test('repeat=all: 끝에서 처음으로', () {
      final q = make(start: 4, repeat: RepeatMode.all);
      expect(played(q.next(user: false)), 'a');
    });

    test('repeat=one: 자동 진행은 같은 곡, 사용자 다음은 실제 다음 곡', () {
      final q = make(start: 1, repeat: RepeatMode.one);
      expect(played(q.next(user: false)), 'b');
      expect(played(q.next(user: true)), 'c');
    });

    test('이전 곡: 3초 초과면 처음으로, 이하면 이전 곡, 첫 곡이면 처음으로', () {
      final q = make(start: 2);
      expect(played(q.previous(3001)), 'c');
      expect(cur(q), 'c');
      expect(played(q.previous(3000)), 'b');
      q.previous(0);
      expect(played(q.previous(0)), 'a', reason: '첫 곡에서는 처음으로');
    });
  });

  group('다음에 재생 (up_next)', () {
    test('FIFO, 셔플과 무관, 끝나면 원래 다음 곡으로', () {
      final q = make(start: 0, shuffle: true);
      final after = q.continuing.first.trackId;
      q.playNext(['x', 'y']);
      expect(played(q.next(user: false)), 'x');
      expect(played(q.next(user: false)), 'y');
      expect(played(q.next(user: false)), after);
    });

    test('다음에 재생 중 이전 곡 → 원래 위치의 곡', () {
      final q = make(start: 1);
      q.playNext(['x']);
      q.next(user: true);
      expect(cur(q), 'x');
      expect(played(q.previous(0)), 'b');
    });

    test('새 컨텍스트로 바꿔도 다음에 재생 목록은 유지', () {
      final q = make();
      q.playNext(['x']);
      final r = q.replaceWith(const QueueContext(ContextType.playlist, 'pl_1'), ['p', 'q'], start: 0);
      expect(r.upNext.map((e) => e.trackId), ['x']);
      expect(played(r.next(user: false)), 'x');
      expect(played(r.next(user: false)), 'q');
    });
  });

  group('셔플', () {
    test('켜면 현재 곡이 맨 앞, 나머지는 섞임, 재생 곡은 그대로', () {
      final q = make(start: 2);
      q.setShuffle(true);
      expect(cur(q), 'c');
      final order = [cur(q), ...q.continuing.map((e) => e.trackId)];
      expect(order.first, 'c');
      expect(order.toSet(), tracks.toSet());
      expect(order, isNot(['c', 'a', 'b', 'd', 'e']), reason: '시드 1에서 섞인 순서');
    });

    test('끄면 원래 순서로 돌아가고 커서는 현재 곡의 원래 위치', () {
      final q = make(start: 2, shuffle: true);
      q.next(user: true);
      final now = cur(q)!;
      q.setShuffle(false);
      expect(cur(q), now);
      expect(q.continuing.map((e) => e.trackId), tracks.sublist(tracks.indexOf(now) + 1));
    });

    test('같은 시드면 같은 순서 (주입 가능한 난수원)', () {
      final a = make(shuffle: true, seed: 7).continuing.map((e) => e.trackId).toList();
      final b = make(shuffle: true, seed: 7).continuing.map((e) => e.trackId).toList();
      expect(a, b);
    });

    test('repeat=all + 셔플: 한 바퀴 뒤 다시 섞되 방금 곡이 첫 곡이 아니다', () {
      for (var seed = 0; seed < 50; seed++) {
        final q = make(shuffle: true, repeat: RepeatMode.all, seed: seed);
        String? last;
        for (var i = 0; i < 4; i++) {
          last = played(q.next(user: false));
        }
        final first = played(q.next(user: false));
        expect(first, isNot(last), reason: 'seed $seed');
      }
    });
  });

  group('편집', () {
    test('현재 곡 삭제 → true(호출자가 다음 곡 재생), 커서는 다음 곡', () {
      final q = make(start: 1);
      final id = q.current!.queueItemId;
      expect(q.remove(id), isTrue);
      expect(cur(q), 'c');
    });

    test('앞쪽 곡 삭제는 현재 곡을 바꾸지 않는다', () {
      final q = make(start: 2);
      expect(q.remove(q.baseItems.first.queueItemId), isFalse);
      expect(cur(q), 'c');
      expect(played(q.previous(0)), 'b');
    });

    test('같은 곡이 두 번 있어도 항목 ID로 구별', () {
      final q = make();
      q.addToEnd(['a']);
      final ids = q.baseItems.where((e) => e.trackId == 'a').map((e) => e.queueItemId).toList();
      expect(ids.length, 2);
      q.remove(ids.last);
      expect(q.baseItems.where((e) => e.trackId == 'a').length, 1);
      expect(cur(q), 'a');
    });

    test('이어서 목록 순서 바꾸기, 비우기', () {
      final q = make();
      q.moveContinuing(0, 3); // b를 e 뒤로
      expect(q.continuing.map((e) => e.trackId), ['c', 'd', 'e', 'b']);
      q.playNext(['x']);
      q.clearUpcoming();
      expect(q.continuing, isEmpty);
      expect(q.upNext, isEmpty);
      expect(cur(q), 'a');
    });
  });

  group('저장·복원 (03장 §6.7)', () {
    test('JSON 왕복 후 같은 상태', () {
      final q = make(start: 1, shuffle: true, repeat: RepeatMode.all);
      q.playNext(['x']);
      q.next(user: true);
      final r = PlayQueue.fromJson(q.toJson());
      expect(cur(r), cur(q));
      expect(r.continuing.map((e) => e.trackId), q.continuing.map((e) => e.trackId));
      expect(r.shuffle, isTrue);
      expect(r.repeat, RepeatMode.all);
      expect(played(r.next(user: false)), played(q.next(user: false)));
    });

    test('손상된 저장값은 FormatException', () {
      final j = make().toJson();
      j['order'] = [0, 0, 1, 2, 3];
      expect(() => PlayQueue.fromJson(j), throwsFormatException);
    });
  });

  group('실행 취소·비우기 (04장 S8)', () {
    test('뺀 곡을 실행 취소하면 같은 자리·같은 항목 ID로 돌아온다', () {
      final q = PlayQueue.fromTracks(const QueueContext(ContextType.adhoc), ['a', 'b', 'c', 'd']);
      q.playNext(['x']);
      final snap = q.checkpoint();
      final b = q.continuing.firstWhere((i) => i.trackId == 'b');
      q.remove(b.queueItemId);
      final x = q.upNext.single;
      q.remove(x.queueItemId);
      expect(q.continuing.map((i) => i.trackId), ['c', 'd']);
      q.rollback(snap);
      expect(q.upNext.map((i) => i.queueItemId), [x.queueItemId]);
      expect(q.continuing.map((i) => i.queueItemId).toList()[0], b.queueItemId);
      expect(q.current!.trackId, 'a');
    });

    test('대기열 비우기: 지금 곡만 남고 다음 곡은 끝', () {
      final q = PlayQueue.fromTracks(const QueueContext(ContextType.adhoc), ['a', 'b', 'c'], start: 1);
      q.playNext(['x']);
      q.clearUpcoming();
      expect(q.current!.trackId, 'b');
      expect(q.upNext, isEmpty);
      expect(q.continuing, isEmpty);
      expect(q.next(user: false), isA<Ended>());
    });
  });
}
