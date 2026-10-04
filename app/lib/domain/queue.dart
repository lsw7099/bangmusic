// 재생 대기열 (03장 §6.2~6.3). Flutter·플랫폼에 의존하지 않는 순수 Dart.
// 기존 Windows BangMusic의 nextIndex 테스트(test/core.test.cjs)를 이식했다(test/domain/queue_test.dart). 규칙이 다르면 기존 테스트를 따른다.
// 기존 앱과 다른 점: 셔플은 매번 무작위로 고르는 대신 순열(Fisher–Yates)이다(03장 §6.3). 기존 테스트가 요구하는
// "셔플 다음 곡은 현재 곡이 아니다"는 그대로 만족한다.
import 'dart:math';

enum RepeatMode { off, all, one }

enum ContextType { album, playlist, artist, search, library, adhoc }

class QueueContext {
  const QueueContext(this.type, [this.id, this.name]);
  final ContextType type;
  final String? id;
  final String? name;

  Map<String, Object?> toJson() => {'type': type.name, 'id': id, 'name': name};
  static QueueContext fromJson(Map<String, Object?> j) =>
      QueueContext(ContextType.values.byName(j['type']! as String), j['id'] as String?, j['name'] as String?);
}

/// 같은 곡이 여러 번 들어갈 수 있으므로 항목은 queueItemId로 구별한다.
class QueueItem {
  const QueueItem(this.queueItemId, this.trackId);
  final String queueItemId;
  final String trackId;

  Map<String, Object?> toJson() => {'q': queueItemId, 't': trackId};
  static QueueItem fromJson(Map<String, Object?> j) => QueueItem(j['q']! as String, j['t']! as String);
  @override
  String toString() => 'QueueItem($trackId)';
}

/// 다음 곡 결정 결과
sealed class Advance {
  const Advance();
}

/// 이 항목을 처음부터 재생
class PlayItem extends Advance {
  const PlayItem(this.item);
  final QueueItem item;
}

/// 대기열 끝 (반복 꺼짐): 마지막 곡에 머물고 위치 0
class Ended extends Advance {
  const Ended(this.item);
  final QueueItem? item;
}

class PlayQueue {
  PlayQueue._(this.context, this._base, this._order, this._cursor, this._upNext, this._playingUpNext, this.shuffle, this.repeat, this._random, this._newId);

  /// 컨텍스트(앨범·플레이리스트 등)에서 대기열을 만든다. [start]는 base 안의 인덱스.
  factory PlayQueue.fromTracks(QueueContext context, List<String> trackIds,
      {int start = 0, bool shuffle = false, RepeatMode repeat = RepeatMode.off, Random? random, String Function()? newId, List<QueueItem> upNext = const []}) {
    final rnd = random ?? Random();
    final ids = newId ?? _uuidish(rnd);
    final base = [for (final t in trackIds) QueueItem(ids(), t)];
    final q = PlayQueue._(context, base, List<int>.generate(base.length, (i) => i), base.isEmpty ? 0 : start.clamp(0, base.length - 1),
        List.of(upNext), null, false, repeat, rnd, ids);
    if (shuffle) q.setShuffle(true);
    return q;
  }

  QueueContext context;
  final List<QueueItem> _base;
  List<int> _order;
  int _cursor;
  final List<QueueItem> _upNext;
  QueueItem? _playingUpNext; // "다음에 재생"에서 꺼내 재생 중인 항목
  bool shuffle;
  RepeatMode repeat;
  final Random _random;
  final String Function() _newId;

  bool get isEmpty => _base.isEmpty && _upNext.isEmpty && _playingUpNext == null;

  QueueItem? get current => _playingUpNext ?? (_base.isEmpty ? null : _base[_order[_cursor]]);

  /// 화면의 "다음에 재생" 목록
  List<QueueItem> get upNext => List.unmodifiable(_upNext);

  /// 화면의 "이어서: 컨텍스트" 목록 (현재 곡 다음부터 재생 순서대로)
  List<QueueItem> get continuing => [for (var i = _cursor + 1; i < _order.length; i++) _base[_order[i]]];

  /// 원래(컨텍스트) 순서의 전체 목록
  List<QueueItem> get baseItems => List.unmodifiable(_base);

  // ── 곡 전환 ──────────────────────────────────────────────────

  /// 다음 곡. [user]=true(사용자가 다음 버튼)면 repeat=one이어도 실제 다음 곡으로 간다.
  Advance next({required bool user}) {
    final cur = current;
    if (cur == null) return const Ended(null);
    if (!user && repeat == RepeatMode.one) return PlayItem(cur);
    if (_upNext.isNotEmpty) {
      _playingUpNext = _upNext.removeAt(0);
      return PlayItem(_playingUpNext!);
    }
    final wasUpNext = _playingUpNext != null;
    _playingUpNext = null;
    if (_base.isEmpty) return Ended(cur);
    if (_cursor + 1 < _order.length) {
      _cursor++;
      return PlayItem(current!);
    }
    // 대기열 끝
    // 기존 앱: repeat=one에서 사용자가 마지막 곡의 다음을 누르면 끝(-1). 처음으로 돌아가는 것은 repeat=all뿐
    if (repeat == RepeatMode.all) {
      final last = wasUpNext ? null : _order[_cursor];
      if (shuffle) {
        _order = _shuffled(List<int>.generate(_base.length, (i) => i));
        // 방금 곡이 새 순서의 첫 곡이 되지 않게
        if (last != null && _order.length > 1 && _order.first == last) {
          final j = 1 + _random.nextInt(_order.length - 1);
          _order[0] = _order[j];
          _order[j] = last;
        }
      }
      _cursor = 0;
      return PlayItem(current!);
    }
    if (wasUpNext) {
      // "다음에 재생" 곡이 마지막이었다 → 원래 마지막 곡에 머문다
      return Ended(current);
    }
    return Ended(cur);
  }

  /// 이전 곡: 3초 넘게 들었으면 현재 곡 처음으로, 아니면 이전 곡. 첫 곡이면 처음으로.
  Advance previous(int positionMs) {
    final cur = current;
    if (cur == null) return const Ended(null);
    if (positionMs > 3000) return PlayItem(cur);
    if (_playingUpNext != null) {
      _playingUpNext = null;
      return PlayItem(current!);
    }
    if (_cursor > 0) _cursor--;
    return PlayItem(current!);
  }

  /// 대기열에서 특정 항목으로 바로 이동 (대기열 화면에서 누름)
  Advance jumpTo(String queueItemId) {
    final u = _upNext.indexWhere((x) => x.queueItemId == queueItemId);
    if (u >= 0) {
      _playingUpNext = _upNext.removeAt(u);
      return PlayItem(_playingUpNext!);
    }
    final i = _order.indexWhere((o) => _base[o].queueItemId == queueItemId);
    if (i < 0) throw ArgumentError('대기열에 없는 항목: $queueItemId');
    _playingUpNext = null;
    _cursor = i;
    return PlayItem(current!);
  }

  // ── 셔플·반복 ────────────────────────────────────────────────

  /// 켜기: 현재 곡을 맨 앞에 두고 나머지를 Fisher–Yates로 섞는다(재생은 끊기지 않는다).
  /// 끄기: 원래 순서로 되돌리고 커서를 현재 곡의 원래 위치로.
  void setShuffle(bool on) {
    if (_base.isEmpty) {
      shuffle = on;
      return;
    }
    final curBase = _order[_cursor];
    if (on) {
      final rest = [for (var i = 0; i < _base.length; i++) if (i != curBase) i];
      _order = [curBase, ..._shuffled(rest)];
      _cursor = 0;
    } else {
      _order = List<int>.generate(_base.length, (i) => i);
      _cursor = curBase;
    }
    shuffle = on;
  }

  List<int> _shuffled(List<int> xs) {
    for (var i = xs.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final t = xs[i];
      xs[i] = xs[j];
      xs[j] = t;
    }
    return xs;
  }

  // ── 편집 ─────────────────────────────────────────────────────

  /// "다음에 재생": 셔플과 무관하게 현재 곡 바로 뒤(FIFO)
  void playNext(List<String> trackIds) => _upNext.addAll([for (final t in trackIds) QueueItem(_newId(), t)]);

  /// "맨 뒤에 추가"
  void addToEnd(List<String> trackIds) {
    for (final t in trackIds) {
      _base.add(QueueItem(_newId(), t));
      _order.add(_base.length - 1);
    }
  }

  /// 항목 삭제. 현재 곡을 지우면 true를 돌려주며 호출자는 다음 곡으로 넘어가야 한다(커서는 이미 다음 곡).
  bool remove(String queueItemId) {
    final u = _upNext.indexWhere((x) => x.queueItemId == queueItemId);
    if (u >= 0) {
      _upNext.removeAt(u);
      return false;
    }
    if (_playingUpNext?.queueItemId == queueItemId) {
      _playingUpNext = null;
      return true;
    }
    final b = _base.indexWhere((x) => x.queueItemId == queueItemId);
    if (b < 0) return false;
    final pos = _order.indexOf(b);
    final wasCurrent = pos == _cursor && _playingUpNext == null;
    _base.removeAt(b);
    _order = [for (final o in _order) if (o != b) (o > b ? o - 1 : o)];
    if (pos < _cursor) _cursor--;
    if (_cursor >= _order.length) _cursor = _order.isEmpty ? 0 : _order.length - 1;
    return wasCurrent;
  }

  /// 되돌리기용 사본 (대기열에서 뺀 곡 실행 취소, 04장 S8). 같은 항목 ID를 그대로 되살린다.
  Map<String, Object?> checkpoint() => toJson();

  void rollback(Map<String, Object?> checkpoint) {
    final o = PlayQueue.fromJson(checkpoint, random: _random, newId: _newId);
    _base
      ..clear()
      ..addAll(o._base);
    _order = [...o._order];
    _cursor = o._cursor;
    _upNext
      ..clear()
      ..addAll(o._upNext);
    _playingUpNext = o._playingUpNext;
    shuffle = o.shuffle;
    repeat = o.repeat;
  }

  /// "이어서" 목록 안에서 순서 바꾸기. from/to는 [continuing]의 인덱스.
  void moveContinuing(int from, int to) {
    final a = _cursor + 1 + from;
    final b = _cursor + 1 + to;
    if (a >= _order.length || b >= _order.length || a < 0 || b < 0) throw RangeError('범위 밖');
    final v = _order.removeAt(a);
    _order.insert(b, v);
  }

  /// "다음에 재생" 목록 안에서 순서 바꾸기
  void moveUpNext(int from, int to) {
    final v = _upNext.removeAt(from);
    _upNext.insert(to, v);
  }

  /// 대기열 비우기 (현재 곡은 남긴다)
  void clearUpcoming() {
    _upNext.clear();
    final cur = current;
    if (cur == null) return;
    if (_playingUpNext != null) {
      _base.clear();
      _order = [];
      _cursor = 0;
      return;
    }
    _base
      ..clear()
      ..add(cur);
    _order = [0];
    _cursor = 0;
  }

  /// 새 컨텍스트로 교체. "다음에 재생" 목록은 유지한다(묻지 않는다).
  PlayQueue replaceWith(QueueContext context, List<String> trackIds, {int start = 0}) =>
      PlayQueue.fromTracks(context, trackIds, start: start, shuffle: shuffle, repeat: repeat, random: _random, newId: _newId, upNext: _upNext);

  // ── 저장·복원 (03장 §6.7) ────────────────────────────────────

  Map<String, Object?> toJson() => {
        'v': 1,
        'context': context.toJson(),
        'base': [for (final b in _base) b.toJson()],
        'order': _order,
        'cursor': _cursor,
        'up_next': [for (final u in _upNext) u.toJson()],
        'playing_up_next': _playingUpNext?.toJson(),
        'shuffle': shuffle,
        'repeat': repeat.name,
      };

  static PlayQueue fromJson(Map<String, Object?> j, {Random? random, String Function()? newId}) {
    final rnd = random ?? Random();
    final base = [for (final b in j['base']! as List) QueueItem.fromJson((b as Map).cast())];
    final order = [for (final o in j['order']! as List) o as int];
    if (order.length != base.length || !(order.toSet().length == base.length && order.every((o) => o >= 0 && o < base.length))) {
      throw const FormatException('손상된 대기열');
    }
    final pun = j['playing_up_next'];
    return PlayQueue._(
      QueueContext.fromJson((j['context']! as Map).cast()),
      base,
      order,
      base.isEmpty ? 0 : (j['cursor']! as int).clamp(0, base.length - 1),
      [for (final u in j['up_next']! as List) QueueItem.fromJson((u as Map).cast())],
      pun == null ? null : QueueItem.fromJson((pun as Map).cast()),
      j['shuffle']! as bool,
      RepeatMode.values.byName(j['repeat']! as String),
      rnd,
      newId ?? _uuidish(rnd),
    );
  }
}

String Function() _uuidish(Random r) => () {
      String h(int n) => List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
      return '${h(8)}-${h(4)}-4${h(3)}-${(8 + r.nextInt(4)).toRadixString(16)}${h(3)}-${h(12)}';
    };
