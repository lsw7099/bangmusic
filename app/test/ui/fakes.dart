// 위젯 테스트용 가짜: 소리 없는 플레이어(실제 도메인 대기열 사용), 경로별 JSON을 돌려주는 가짜 서버.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bangmusic/core/api_client.dart';
import 'package:bangmusic/core/session.dart';
import 'package:bangmusic/data/download_engine.dart';
import 'package:bangmusic/data/library_store.dart';
import 'package:bangmusic/domain/playback_state.dart';
import 'package:bangmusic/domain/queue.dart';
import 'package:bangmusic/platform/player_port.dart';
import 'package:bangmusic/platform/secure_store.dart';
import 'package:bangmusic/platform/store_port.dart';
import 'package:bangmusic/ui/app_state.dart';
import 'package:bangmusic/ui/scope.dart';
import 'package:bangmusic/ui/tokens.dart';
import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_test/flutter_test.dart';

class FakePlayer implements PlayerPort {
  @override
  final ValueNotifier<int> queueChanged = ValueNotifier(0);
  @override
  final ValueNotifier<PlaybackStatus> status = ValueNotifier(PlaybackStatus.idle);
  @override
  final ValueNotifier<NowSource> nowSource = ValueNotifier(const NowSource(null));
  @override
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final _pos = StreamController<Duration>.broadcast();
  @override
  Stream<Duration> get position => _pos.stream;
  @override
  Stream<Duration?> get duration => const Stream.empty();

  PlayQueue? _q;
  final tracks = <String, Track>{};
  final calls = <String>[];

  @override
  PlayQueue? get playQueue => _q;
  @override
  Track? get currentTrack => _q?.current == null ? null : tracks[_q!.current!.trackId];
  @override
  Track? trackOf(String id) => tracks[id];

  void _changed() => queueChanged.value++;

  @override
  Future<void> attach(ApiClient api, {LibraryStore? library, DownloadEngine? downloads, Future<void> Function(PlayEvent)? onPlayEvent, Future<String?> Function()? streamQuality}) async {}
  @override
  Future<void> detach() async {}

  @override
  Future<void> playTracks(List<Track> list, {required QueueContext context, int start = 0, bool? shuffle}) async {
    calls.add('playTracks ${context.type.name}:${context.id} start=$start shuffle=$shuffle n=${list.length}');
    for (final t in list) {
      tracks[t.id] = t;
    }
    _q = PlayQueue.fromTracks(context, [for (final t in list) t.id], start: start, shuffle: shuffle ?? false);
    status.value = PlaybackStatus.playing;
    _changed();
  }

  @override
  void playNext(List<Track> list) {
    for (final t in list) {
      tracks[t.id] = t;
    }
    _q?.playNext([for (final t in list) t.id]);
    calls.add('playNext ${list.map((t) => t.id).join(',')}');
    _changed();
  }

  @override
  void addToEnd(List<Track> list) {
    for (final t in list) {
      tracks[t.id] = t;
    }
    _q?.addToEnd([for (final t in list) t.id]);
    calls.add('addToEnd');
    _changed();
  }

  @override
  Future<void> removeItem(String id) async {
    _undo = _q?.checkpoint();
    _q?.remove(id);
    calls.add('remove');
    _changed();
  }

  @override
  Future<void> jumpTo(String id) async {
    _q?.jumpTo(id);
    calls.add('jumpTo');
    _changed();
  }

  Map<String, Object?>? _undo;
  @override
  void undoRemove() {
    if (_undo != null) _q?.rollback(_undo!);
    _undo = null;
    calls.add('undoRemove');
    _changed();
  }

  @override
  void clearUpcoming() {
    _q?.clearUpcoming();
    calls.add('clearUpcoming');
    _changed();
  }

  @override
  void moveContinuing(int from, int to) {
    _q?.moveContinuing(from, to);
    _changed();
  }

  @override
  void setShuffle(bool on) {
    _q?.setShuffle(on);
    calls.add('shuffle $on');
    _changed();
  }

  @override
  void cycleRepeat() {
    final q = _q!;
    q.repeat = RepeatMode.values[(q.repeat.index + 1) % 3];
    calls.add('repeat ${q.repeat.name}');
    _changed();
  }

  @override
  Future<void> play() async {
    calls.add('play');
    status.value = PlaybackStatus.playing;
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    status.value = PlaybackStatus.paused;
  }

  @override
  Future<void> seek(Duration p) async => calls.add('seek ${p.inMilliseconds}');
  @override
  Future<void> skipToNext() async {
    calls.add('next');
    _q?.next(user: true);
    _changed();
  }

  @override
  Future<void> skipToPrevious() async {
    calls.add('previous');
    _q?.previous(0);
    _changed();
  }

  @override
  Future<File?> cachedArtwork(String? artworkId, int size) async => null;

  void emitPosition(Duration d) => _pos.add(d);
}

/// 경로("GET /tracks")별 응답. 값은 JSON 또는 (상태, JSON) 또는 요청을 받아 응답을 만드는 함수.
class FakeServer implements HttpClientAdapter {
  FakeServer({this.serverId = 'srv_T'});

  /// GET /server가 돌려줄 server_id (앱은 토큰을 붙이기 전에 이것을 확인한다, 03장 §5.2)
  String serverId;
  final routes = <String, Object Function(RequestOptions)>{};
  final requests = <String>[];

  /// 요청별 Authorization 헤더 (토큰이 어디로 갔는지 확인용)
  final auth = <String, String?>{};

  void on(String route, Object Function(RequestOptions) f) => routes[route] = f;
  void json(String route, Object body) => routes[route] = (_) => body;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final path = o.uri.path.replaceFirst('/v1', '');
    final key = '${o.method} $path';
    requests.add('$key${o.uri.query.isEmpty ? '' : '?${o.uri.query}'}');
    auth[key] = o.headers['Authorization'] as String?;
    if (key == 'GET /server' && !routes.containsKey(key)) {
      return ResponseBody.fromString(jsonEncode({
        'server_id': serverId, 'name': '시험', 'product': 'bangmusic-server', 'version': '0.1.0', 'api': {'major': 1, 'minor': 0},
        'min_client_api_minor': 0, 'features': <String>[], 'limits': <String, int>{}, 'setup_required': false,
      }), 200, headers: {Headers.contentTypeHeader: ['application/json']});
    }
    final f = routes[key];
    if (f == null) {
      return ResponseBody.fromString(jsonEncode({'type': 'about:blank', 'title': 'x', 'status': 404, 'code': 'not_found'}), 404,
          headers: {Headers.contentTypeHeader: ['application/problem+json']});
    }
    // 처리기가 Future를 돌려주면 기다린다 (로딩 상태를 붙잡아 두는 시험용)
    final r0 = f(o);
    final r = r0 is Future ? await r0 : r0;
    final (status, body) = r is (int, Object) ? r : (200, r);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {Headers.contentTypeHeader: ['application/json']});
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> track(String id, String title, {String? album, String? albumId, int no = 1, String state = 'available', int ms = 180000}) => {
      'id': id, 'title': title, 'title_sort': null, 'artists': [{'id': 'art_1', 'name': '합성 악단'}],
      'album': albumId == null ? null : {'id': albumId, 'title': album ?? '앨범'}, 'disc_no': 1, 'track_no': no, 'duration_ms': ms,
      'year': 2026, 'genre': null, 'artwork_id': null, 'media_version': 'v1', 'state': state, 'has_lyrics': <String>[], 'updated_at': '2026-10-03T00:00:00Z',
    };

Map<String, Object?> album(String id, String title, {int count = 2}) => {
      'id': id, 'title': title, 'album_artist': {'id': 'art_1', 'name': '합성 악단'}, 'year': 2026, 'artwork_id': null, 'track_count': count, 'duration_ms': 360000,
    };

Map<String, Object?> playlist(String id, String name, {int count = 0, int version = 1}) => {
      'id': id, 'name': name, 'description': null, 'artwork_id': null, 'mosaic_artwork_ids': <String>[], 'version': version, 'item_count': count,
      'duration_ms': 0, 'created_at': '2026-10-03T00:00:00Z', 'updated_at': '2026-10-03T00:00:00Z',
    };

Map<String, Object?> page(List<Object?> items, [String? next]) => {'items': items, 'next_cursor': next};

/// 로그인한 상태의 앱 화면을 띄운다
Future<(AppState, FakePlayer, FakeServer)> pumpApp(WidgetTester t, Widget home, {FakeServer? server, StorePort? purchases}) async {
  final srv = server ?? FakeServer();
  final dio = Dio(BaseOptions(baseUrl: 'http://fake/v1'))..httpClientAdapter = srv;
  const profile = ServerProfile(serverId: 'srv_T', baseUrl: 'http://fake', serverName: '시험', userId: 'usr_1', username: 'siwon', displayName: '시원', installationId: 'i');
  final client = ApiClient(profile: profile, vault: TokenVault(MemorySecureStore()), tokens: Tokens('bma_x', DateTime(2030), 'bmr_x'), dio: dio);
  final player = FakePlayer();
  final state = AppState(player: player, store: MemorySecureStore(), purchases: purchases)..debugActivate(profile, client);
  if (purchases != null) await state.entitlement.load();
  await t.pumpWidget(AppScope(state: state, child: MaterialApp(theme: buildTheme(Brightness.light), home: home)));
  await t.pumpAndSettle();
  return (state, player, srv);
}

/// 스토어 가짜: 상품 하나, 구매하면 바로 purchased (또는 지정한 결과)
class FakeStore implements StorePort {
  FakeStore({this.state = PurchaseState.notPurchased});
  PurchaseState state;
  StoreResult? next;
  int buys = 0;
  final _changes = StreamController<PurchaseState>.broadcast();

  /// 화면 밖에서 상태가 바뀜 (보류 중 결제 완료 등)
  void push(PurchaseState s) {
    state = s;
    _changes.add(s);
  }

  @override
  Stream<PurchaseState> get changes => _changes.stream;
  @override
  Future<PurchaseState> cachedState() async => state;
  @override
  Future<StoreProduct?> product() async => const StoreProduct(id: 'bangmusic_unlock', title: 'BangMusic', description: '전체 기능', price: '₩5,900');
  @override
  Future<StoreResult> buy() async {
    buys++;
    final r = next ?? const StoreOk(PurchaseState.purchased);
    if (r case StoreOk(state: final s)) state = s;
    return r;
  }

  @override
  Future<StoreResult> restore() async => state == PurchaseState.purchased ? StoreOk(state) : const StoreNothingToRestore();
}
