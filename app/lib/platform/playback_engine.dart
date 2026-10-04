// 재생 엔진 (01장 §2.5 PlaybackEngine, 03장 §6). just_audio(ExoPlayer) + audio_service(미디어 세션·알림).
// 대기열 진행은 UI가 아니라 이 핸들러에서 한다(03장 §6.6) — 화면이 없어도 곡 전환이 이어진다.
// 앱 코드는 audio_service·just_audio를 직접 부르지 않고 이 파일의 BangPlayer만 쓴다(교체 가능하게).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../data/download_engine.dart';
import '../data/library_store.dart';
import '../domain/audio_focus.dart';
import '../domain/playback_state.dart';
import '../domain/queue.dart';
import 'player_port.dart';

export 'player_port.dart' show NowSource, PlayerPort;

/// Android 플랫폼 디코더로 재생할 수 있다고 가정하는 형식 (01장 §2.7). ALAC·WAV 등은 서버가 변환한다.
/// [확인 필요] P3 실기기 형식 표로 확정.
final androidAccept = [
  for (final (c, k) in [('mp3', 'mp3'), ('m4a', 'aac'), ('flac', 'flac'), ('ogg', 'vorbis'), ('ogg', 'opus')]) FormatSpec(container: c, codec: k),
];

class BangPlayer extends BaseAudioHandler with SeekHandler implements PlayerPort {
  BangPlayer._(this._player);

  /// 위젯 테스트용: 오디오 서비스를 띄우지 않는다
  @visibleForTesting
  factory BangPlayer.forTest() => BangPlayer._(AudioPlayer());

  static Future<BangPlayer> create() async {
    return AudioService.init(
      builder: () => BangPlayer._(AudioPlayer(handleInterruptions: false)),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'bangmusic.playback',
        androidNotificationChannelName: '재생',
        androidStopForegroundOnPause: true,
      ),
    );
  }

  final AudioPlayer _player;
  ApiClient? _api;
  DownloadEngine? _downloads;
  Future<void> Function(PlayEvent)? _onPlayEvent;
  Future<String?> Function()? _streamQuality;

  /// 지금 곡을 받은 파일로 재생 중인가 (재생 기록 source=offline)
  bool _playingLocal = false;
  PlayQueue? _queue;
  final Map<String, Track> _tracks = {};
  final _random = Random();

  /// 화면에 보이는 상태
  @override
  final ValueNotifier<PlaybackStatus> status = ValueNotifier<PlaybackStatus>(PlaybackStatus.idle);
  @override
  final ValueNotifier<int> queueChanged = ValueNotifier<int>(0);
  @override
  final ValueNotifier<NowSource> nowSource = ValueNotifier<NowSource>(const NowSource(null));
  @override
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);
  PauseReason? pauseReason;

  @override
  Stream<Duration> get position => _player.positionStream;
  @override
  Stream<Duration?> get duration => _player.durationStream;
  Stream<Duration> get buffered => _player.bufferedPositionStream;
  Duration get currentPosition => _player.position;
  @override
  PlayQueue? get playQueue => _queue;
  @override
  Track? trackOf(String id) => _tracks[id];
  @override
  Track? get currentTrack => _queue?.current == null ? null : _tracks[_queue!.current!.trackId];

  StreamSubscription<PlayerState>? _stateSub;
  Timer? _saveTimer;
  late SkipGuard _guard;
  int _loadSeq = 0;

  /// 곡을 불러오는 동안 사용자가 일시정지했으면 그 불러오기 번호. 불러오기가 끝나도 자동 재생하지 않는다.
  /// (곡이 넘어가는 순간 누른 일시정지가 무시되던 결함 — 실기기에서 발견)
  int _pausedDuringLoad = -1;

  // 재생 기록 (03장 §6.9): 탐색으로 건너뛴 구간은 넣지 않는다
  DateTime? _startedAt;
  int _playedMs = 0;
  bool _actuallyPlayed = false; // 이번 불러오기에서 소리가 실제로 났는가
  Duration _lastPos = Duration.zero;

  bool _ducked = false;
  bool _focusWired = false;

  /// 오디오 세션·포커스 (03장 §6.5). just_audio 기본 처리는 덕킹 신호를 무시해서,
  /// 통화를 덕킹으로 보내는 기기(삼성)에서 통화 중에도 음악이 소리 없이 흘러갔다(실기기에서 발견).
  Future<void> _wireFocus() async {
    if (_focusWired) return;
    _focusWired = true;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    session.interruptionEventStream.listen((e) async {
      final ev = e.begin
          ? switch (e.type) { AudioInterruptionType.pause => FocusEvent.lossTransient, AudioInterruptionType.duck => FocusEvent.lossDuck, AudioInterruptionType.unknown => FocusEvent.lossPermanent }
          : (e.type == AudioInterruptionType.duck ? FocusEvent.duckEnded : FocusEvent.regained);
      if (!e.begin && e.type == AudioInterruptionType.unknown) return; // 영구 상실은 끝나도 재개하지 않는다
      await _applyFocus(ev);
    });
    session.becomingNoisyEventStream.listen((_) => _applyFocus(FocusEvent.noisy));
  }

  Future<bool> _inCall() async {
    if (!Platform.isAndroid) return false;
    try {
      final m = await AndroidAudioManager().getMode();
      return m == AndroidAudioHardwareMode.ringtone || m == AndroidAudioHardwareMode.inCall || m == AndroidAudioHardwareMode.inCommunication;
    } catch (_) {
      return false;
    }
  }

  Future<void> _applyFocus(FocusEvent ev) async {
    final action = decideFocus(ev, playing: _player.playing, reason: pauseReason, ducked: _ducked, inCall: await _inCall());
    switch (action) {
      case DoNothing():
        return;
      case PauseFor(:final reason):
        pauseReason = reason;
        await _player.pause();
        _save();
      case Duck():
        _ducked = true;
        await _player.setVolume(0.3);
      case Unduck():
        _ducked = false;
        await _player.setVolume(1);
      case Resume(:final afterCall):
        if (afterCall) {
          // 통화가 끝날 때까지 기다린다. 그 사이 사용자가 조작하면(사유가 바뀌면) 그만둔다.
          for (var i = 0; i < 4 * 3600 && pauseReason == PauseReason.focusTransient; i++) {
            await Future<void>.delayed(const Duration(seconds: 1));
            if (!await _inCall()) break;
          }
        }
        if (pauseReason == PauseReason.focusTransient) await play();
    }
  }

  /// 로그인 뒤 연결. 저장된 대기열을 복원하되 자동 재생하지 않는다(03장 §6.7).
  @override
  Future<void> attach(ApiClient api, {LibraryStore? library, DownloadEngine? downloads, Future<void> Function(PlayEvent)? onPlayEvent, Future<String?> Function()? streamQuality}) async {
    _api = api;
    _streamQuality = streamQuality;
    _downloads = downloads;
    _onPlayEvent = onPlayEvent;
    await _wireFocus();
    _stateSub ??= _player.playerStateStream.listen(_onPlayerState);
    _player.positionStream.listen(_accumulate);
    _player.playbackEventStream.listen(_broadcast, onError: (Object e, StackTrace _) => _onStreamError(e));
    _saveTimer ??= Timer.periodic(const Duration(seconds: 5), (_) => _save());
    await _restore();
  }

  @override
  Future<void> detach() async {
    await stop();
    _api = null;
    _downloads = null;
    _onPlayEvent = null;
    _queue = null;
    _tracks.clear();
    queueChanged.value++;
  }

  String get _prefsKey => 'queue.${_api?.profile.serverId}';

  // ── 대기열 ─────────────────────────────────────────────────────

  @override
  Future<void> playTracks(List<Track> tracks, {required QueueContext context, int start = 0, bool? shuffle}) async {
    if (tracks.isEmpty) return;
    for (final t in tracks) {
      _tracks[t.id] = t;
    }
    final ids = [for (final t in tracks) t.id];
    final q = _queue;
    _queue = q == null
        ? PlayQueue.fromTracks(context, ids, start: start, shuffle: shuffle ?? false, random: _random)
        : q.replaceWith(context, ids, start: start);
    if (shuffle != null && _queue!.shuffle != shuffle) _queue!.setShuffle(shuffle);
    _guard = SkipGuard(ids.length);
    queueChanged.value++;
    await _load(autoplay: true);
  }

  @override
  void playNext(List<Track> tracks) {
    for (final t in tracks) {
      _tracks[t.id] = t;
    }
    _queue?.playNext([for (final t in tracks) t.id]);
    queueChanged.value++;
    _save();
  }

  @override
  void addToEnd(List<Track> tracks) {
    for (final t in tracks) {
      _tracks[t.id] = t;
    }
    _queue?.addToEnd([for (final t in tracks) t.id]);
    queueChanged.value++;
    _save();
  }

  Map<String, Object?>? _undo;
  String? _undoCurrent;

  @override
  Future<void> removeItem(String queueItemId) async {
    final q = _queue;
    if (q == null) return;
    _undo = q.checkpoint();
    _undoCurrent = q.current?.queueItemId;
    final wasCurrent = q.remove(queueItemId);
    if (wasCurrent) _undo = null; // 지금 곡을 뺀 것은 되돌리지 않는다
    queueChanged.value++;
    if (wasCurrent) await _load(autoplay: _player.playing);
    _save();
  }

  @override
  Future<void> jumpTo(String queueItemId) async {
    _finishHistory(completed: false);
    _queue?.jumpTo(queueItemId);
    queueChanged.value++;
    await _load(autoplay: true);
  }

  @override
  @override
  void undoRemove() {
    final q = _queue;
    final snap = _undo;
    _undo = null;
    if (q == null || snap == null || q.current?.queueItemId != _undoCurrent) return;
    q.rollback(snap);
    queueChanged.value++;
    _save();
  }

  @override
  void clearUpcoming() {
    _undo = null;
    _queue?.clearUpcoming();
    queueChanged.value++;
    _save();
  }

  @override
  void setShuffle(bool on) {
    _queue?.setShuffle(on);
    queueChanged.value++;
    _broadcast(null);
    _save();
  }

  @override
  void cycleRepeat() {
    final q = _queue;
    if (q == null) return;
    q.repeat = RepeatMode.values[(q.repeat.index + 1) % RepeatMode.values.length];
    queueChanged.value++;
    _broadcast(null);
    _save();
  }

  @override
  void moveContinuing(int from, int to) {
    _queue?.moveContinuing(from, to);
    queueChanged.value++;
    _save();
  }

  // ── 미디어 세션 명령 (알림·잠금화면·블루투스) ────────────────────

  @override
  Future<void> play() async {
    if (_queue?.current == null) return;
    if (!await (await AudioSession.instance).setActive(true)) {
      pauseReason = PauseReason.focusLoss; // 포커스를 얻지 못하면 재생하지 않고 멈춤 유지
      return;
    }
    pauseReason = null;
    _pausedDuringLoad = -1;
    if (_player.audioSource == null) {
      await _load(autoplay: true);
      return;
    }
    await _player.play();
  }

  @override
  Future<void> pause() async {
    pauseReason = PauseReason.user;
    _pausedDuringLoad = _loadSeq;
    await _player.pause();
    _save();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _advance(user: true);

  @override
  Future<void> skipToPrevious() async {
    final q = _queue;
    if (q == null) return;
    final pos = _player.position.inMilliseconds;
    _finishHistory(completed: false);
    final r = q.previous(pos);
    queueChanged.value++;
    if (r is PlayItem && pos > 3000 && r.item == q.current && _player.audioSource != null) {
      await _player.seek(Duration.zero); // 같은 곡 처음으로 — 다시 받지 않는다
      _beginHistory();
      return;
    }
    await _load(autoplay: true);
  }

  @override
  Future<void> stop() async {
    _finishHistory(completed: false);
    await _player.stop();
    status.value = PlaybackStatus.idle;
    await super.stop();
  }

  // ── 내부 ───────────────────────────────────────────────────────

  Future<void> _advance({required bool user}) async {
    final q = _queue;
    if (q == null) return;
    _finishHistory(completed: !user);
    final r = q.next(user: user);
    queueChanged.value++;
    if (r is Ended) {
      await _player.pause();
      await _player.seek(Duration.zero);
      status.value = PlaybackStatus.ended;
      _save();
      return;
    }
    await _load(autoplay: true);
  }

  void _onPlayerState(PlayerState s) {
    if (s.processingState == ProcessingState.completed) {
      unawaited(_advance(user: false));
      return;
    }
    if (status.value == PlaybackStatus.loading && s.processingState == ProcessingState.idle) return;
    status.value = switch (s.processingState) {
      ProcessingState.loading || ProcessingState.buffering => s.playing ? PlaybackStatus.buffering : PlaybackStatus.loading,
      ProcessingState.ready => s.playing ? PlaybackStatus.playing : PlaybackStatus.paused,
      _ => status.value,
    };
  }

  /// 소스 결정 → URL 설정 → 재생. 재생할 수 없으면 건너뛴다(03장 §6.4).
  Future<void> _load({required bool autoplay, Duration start = Duration.zero}) async {
    final api = _api;
    final item = _queue?.current;
    if (api == null || item == null) return;
    final seq = ++_loadSeq;
    errorMessage.value = null;
    status.value = PlaybackStatus.loading;
    nowSource.value = const NowSource(null);
    _broadcastMedia(item.trackId);
    try {
      // 받은 파일이 있으면 그것 (03장 §6.4: 다운로드본 우선, 재생 시 크기 재확인은 엔진이 한다)
      final local = await _downloads?.playableFile(item.trackId);
      if (seq != _loadSeq) return;
      if (local != null) {
        _playingLocal = true;
        final dot = local.path.lastIndexOf('.');
        nowSource.value = NowSource(null, localFormat: dot < 0 ? 'audio' : local.path.substring(dot + 1));
        await _player.setAudioSource(AudioSource.file(local.path), initialPosition: start);
      } else {
        _playingLocal = false;
        final r = await _resolve(api, item.trackId, seq);
        if (seq != _loadSeq) return; // 그새 다른 곡으로 넘어감
        nowSource.value = NowSource(r);
        await _player.setAudioSource(AudioSource.uri(Uri.parse('${api.baseUrl}${r.mediaUrl}')), initialPosition: start);
      }
      _guard.played();
      _beginHistory();
      if (autoplay && _pausedDuringLoad != seq && await (await AudioSession.instance).setActive(true)) {
        pauseReason = null;
        unawaited(_player.play());
      } else {
        status.value = PlaybackStatus.paused;
      }
      _save();
    } catch (e) {
      if (seq != _loadSeq) return;
      final msg = _describe(e);
      errorMessage.value = msg;
      status.value = PlaybackStatus.error;
      debugPrint('재생 불가 ${item.trackId}: $e');
      // 복원(자동 재생 아님) 중에는 건너뛰지 않는다 — 오프라인으로 앱을 열었을 때 대기열을 훑어 버리지 않게
      if (!autoplay) {
        status.value = PlaybackStatus.paused;
        return;
      }
      if (_guard.skippedShouldStop()) {
        errorMessage.value = '재생할 수 있는 곡이 없습니다 ($msg)';
        status.value = PlaybackStatus.paused;
        pauseReason = PauseReason.error;
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 3)); // 04장 S8: 사유를 3초 보인 뒤 다음 곡
      if (seq == _loadSeq) await _advance(user: true);
    }
  }

  Future<Rendition> _resolve(ApiClient api, String trackId, int seq) async {
    final quality = _streamQuality == null ? 'original' : await _streamQuality!();
    if (quality == null) throw StateError('셀룰러에서 스트리밍이 꺼져 있습니다 (설정 → 재생)');
    var res = await api.api.getMediaApi().resolveRendition(
          trackId: trackId,
          renditionRequest: RenditionRequest(purpose: RenditionRequestPurposeEnum.stream, quality: quality, accept: androidAccept),
        );
    var r = res.data!;
    final deadline = DateTime.now().add(const Duration(seconds: 60)); // 02장 §5: 상한 60초 후 "준비 지연"
    while (r.state == RenditionStateEnum.preparing) {
      nowSource.value = const NowSource(null, preparing: true);
      if (DateTime.now().isAfter(deadline)) throw StateError('준비 지연');
      await Future<void>.delayed(Duration(seconds: (r.retryAfterS ?? 2).clamp(1, 10)));
      if (seq != _loadSeq) throw StateError('취소됨');
      res = await api.api.getMediaApi().getRendition(renditionId: r.id);
      r = res.data!;
    }
    if (r.state != RenditionStateEnum.ready || r.mediaUrl == null) throw StateError(r.errorCode ?? '재생 불가');
    return r;
  }

  /// 재생 도중 오류(티켓 만료·연결 끊김): 렌디션을 다시 받아 같은 위치에서 이어 간다 (03장 §4.4, §4.7)
  Future<void> _onStreamError(Object e) async {
    final api = _api;
    final r = nowSource.value.rendition;
    if (api == null || r == null || _playingLocal) return;
    final pos = _player.position;
    try {
      final fresh = (await api.api.getMediaApi().getRendition(renditionId: r.id)).data!;
      await _player.setAudioSource(AudioSource.uri(Uri.parse('${api.baseUrl}${fresh.mediaUrl}')), initialPosition: pos);
      await _player.play();
    } catch (err) {
      final ae = ApiException.from(err);
      if (ae.code == 'rendition_superseded') {
        await _load(autoplay: true, start: pos); // 원본이 바뀜 → 다시 결정
      } else {
        errorMessage.value = _describe(err);
      }
    }
  }

  String _describe(Object e) {
    final ae = e is ApiException ? e : ApiException.from(e);
    return switch (ae.code) {
      'media_missing' => '서버에 파일이 없습니다',
      _ when (ae.kind == ApiErrorKind.unreachable || ae.kind == ApiErrorKind.timeout) && _downloads != null => '오프라인에서는 재생할 수 없는 곡입니다 (다운로드되지 않음)',
      'no_playable_format' => '이 기기에서 재생할 수 없는 형식입니다',
      'storage_unavailable' => '서버의 음악 저장소에 연결할 수 없습니다',
      'transcode_failed' || 'unsupported_source' => '서버에서 변환하지 못했습니다',
      'transcode_queue_full' => '서버가 바쁩니다',
      _ => ae.kind == ApiErrorKind.unreachable || ae.kind == ApiErrorKind.timeout ? '서버에 연결할 수 없습니다' : (e is StateError ? e.message : '재생할 수 없습니다'),
    };
  }

  // ── 미디어 세션 상태 ─────────────────────────────────────────

  void _broadcast(PlaybackEvent? _) {
    final q = _queue;
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.skipToPrevious, if (_player.playing) MediaControl.pause else MediaControl.play, MediaControl.skipToNext],
      systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: switch (_player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      shuffleMode: q?.shuffle == true ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
      repeatMode: switch (q?.repeat) { RepeatMode.one => AudioServiceRepeatMode.one, RepeatMode.all => AudioServiceRepeatMode.all, _ => AudioServiceRepeatMode.none },
    ));
  }

  /// 잠금화면 표지는 티켓 URL이 아니라 로컬 캐시 파일 (02장 §1.4)
  Future<void> _broadcastMedia(String trackId) async {
    final t = _tracks[trackId];
    if (t == null) return;
    MediaItem item(Uri? art) => MediaItem(
          id: trackId,
          title: t.title,
          artist: t.artists.map((a) => a.name).join(', '),
          album: t.album?.title,
          duration: Duration(milliseconds: t.durationMs),
          artUri: art,
        );
    mediaItem.add(item(null));
    final file = await cachedArtwork(t.artworkId, 512);
    if (file != null && _queue?.current?.trackId == trackId) mediaItem.add(item(Uri.file(file.path)));
  }

  /// 표지 파일 캐시 (Authorization 헤더로 받는다)
  @override
  Future<File?> cachedArtwork(String? artworkId, int size) async {
    final api = _api;
    if (artworkId == null || api == null) return null;
    final saved = _downloads?.artworkFile(artworkId, size);
    if (saved != null) return saved;
    final dir = Directory('${(await getApplicationCacheDirectory()).path}/artwork/${api.profile.serverId}');
    final f = File('${dir.path}/$artworkId-$size.jpg');
    if (await f.exists()) return f;
    try {
      await dir.create(recursive: true);
      final tmp = File('${f.path}.part');
      await api.dio.download('/artwork/$artworkId', tmp.path, queryParameters: {'size': size});
      await tmp.rename(f.path);
      return f;
    } catch (_) {
      return null;
    }
  }

  // ── 재생 기록 (03장 §6.9) ────────────────────────────────────

  void _beginHistory() {
    _startedAt = DateTime.now().toUtc();
    _playedMs = 0;
    _actuallyPlayed = false;
    _lastPos = _player.position;
  }

  void _accumulate(Duration pos) {
    final d = (pos - _lastPos).inMilliseconds;
    // 재생 중 자연스러운 진행만 더한다 (탐색 점프는 제외)
    if (_player.playing && d > 0 && d < 2000) _playedMs += d;
    if (_player.playing) _actuallyPlayed = true;
    _lastPos = pos;
  }

  void _finishHistory({required bool completed}) {
    final api = _api;
    final item = _queue?.current;
    final started = _startedAt;
    _startedAt = null;
    // 기존 BangMusic 규칙: 불러와 재생이 시작된 곡은 들은 길이와 무관하게 1회. 일시정지로 복원만 하고 재생하지 않은 곡은 보내지 않는다.
    if (api == null || item == null || started == null || !_actuallyPlayed) return;
    final ctx = _queue!.context;
    final ev = PlayEvent(
      eventId: _uuid(),
      trackId: item.trackId,
      startedAt: started,
      playedMs: _playedMs,
      completed: completed,
      source_: _playingLocal ? PlayEventSource_Enum.offline : PlayEventSource_Enum.stream,
      context: PlayEventContext(type: PlayEventContextTypeEnum.values.firstWhere((v) => v.value == ctx.type.name, orElse: () => PlayEventContextTypeEnum.queue), id: ctx.id),
    );
    final sink = _onPlayEvent;
    unawaited(sink != null ? sink(ev) : _sendHistory(api, ev));
  }

  /// 전송 실패분은 기기에 쌓아 두었다가 다음에 같이 보낸다(같은 event_id → 서버가 중복 제거, FN-22)
  Future<void> _sendHistory(ApiClient api, PlayEvent ev) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'history.pending.${api.profile.serverId}';
    final pending = [for (final s in prefs.getStringList(key) ?? <String>[]) s, jsonEncode(ev.toJson())];
    try {
      await api.api.getHistoryApi().postPlayEvents(
            postPlayEventsRequest: PostPlayEventsRequest(events: [for (final s in pending.take(500)) PlayEvent.fromJson(jsonDecode(s) as Map<String, dynamic>)]),
          );
      await prefs.setStringList(key, pending.skip(500).toList());
    } catch (_) {
      await prefs.setStringList(key, pending);
    }
  }

  String _uuid() {
    String h(int n) => List.generate(n, (_) => _random.nextInt(16).toRadixString(16)).join();
    return '${h(8)}-${h(4)}-4${h(3)}-${(8 + _random.nextInt(4)).toRadixString(16)}${h(3)}-${h(12)}';
  }

  // ── 저장·복원 (03장 §6.7) ────────────────────────────────────

  Future<void> _save() async {
    final q = _queue;
    if (q == null || _api == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode({
      'queue': q.toJson(),
      'position_ms': _player.position.inMilliseconds,
      'tracks': {for (final id in {...q.baseItems.map((e) => e.trackId), ...q.upNext.map((e) => e.trackId)}) if (_tracks[id] != null) id: _tracks[id]!.toJson()},
    }));
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_prefsKey);
    if (s == null) return;
    try {
      final j = jsonDecode(s) as Map<String, dynamic>;
      for (final MapEntry(:key, :value) in (j['tracks'] as Map<String, dynamic>).entries) {
        _tracks[key] = Track.fromJson(value as Map<String, dynamic>);
      }
      _queue = PlayQueue.fromJson((j['queue'] as Map).cast(), random: _random);
      _guard = SkipGuard(_queue!.baseItems.length);
      queueChanged.value++;
      // 자동 재생하지 않는다: 일시정지 상태로 마지막 위치(최대 5초 전)
      await _load(autoplay: false, start: Duration(milliseconds: (j['position_ms'] as int?) ?? 0));
    } catch (e) {
      debugPrint('대기열 복원 실패: $e');
      await prefs.remove(_prefsKey);
    }
  }
}
