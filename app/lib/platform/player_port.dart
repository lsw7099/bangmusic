// 화면이 쓰는 재생 기능 (01장 §2.5 PlaybackEngine 경계). 실제 구현은 BangPlayer(just_audio + audio_service).
// 화면은 이 인터페이스만 알아서, 재생 패키지를 바꾸거나 테스트에서 가짜로 바꿀 수 있다.
import 'dart:io';

import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../data/download_engine.dart';
import '../data/library_store.dart';
import '../domain/playback_state.dart';
import '../domain/queue.dart';

/// 지금 재생 중인 곡의 실제 제공 형식 (04장 S8 음질 꼬리표)
class NowSource {
  const NowSource(this.rendition, {this.preparing = false, this.localFormat});
  final Rendition? rendition;
  final bool preparing;

  /// 다운로드한 파일을 재생 중이면 그 형식 (예: flac)
  final String? localFormat;
  bool get local => localFormat != null;

  String get label {
    if (localFormat != null) return '${localFormat!.toUpperCase()} · 다운로드됨';
    final r = rendition;
    if (r == null) return preparing ? '서버에서 준비 중' : '';
    final fmt = (r.codec ?? r.container ?? '').toUpperCase();
    return r.profile == 'original' ? '$fmt 원본' : '${r.profile.replaceAll('aac_', 'AAC ')} · 변환';
  }
}

abstract interface class PlayerPort {
  ValueListenable<int> get queueChanged;
  ValueListenable<PlaybackStatus> get status;
  ValueListenable<NowSource> get nowSource;
  ValueListenable<String?> get errorMessage;
  Stream<Duration> get position;
  Stream<Duration?> get duration;

  PlayQueue? get playQueue;
  Track? get currentTrack;
  Track? trackOf(String id);

  /// 로그인 뒤 연결. library·downloads가 있으면 받은 파일을 먼저 재생하고(03장 §6.4), 재생 기록은 onPlayEvent로 넘긴다.
  /// streamQuality: 스트리밍 음질을 정한다. null을 돌려주면 스트리밍하지 않는다(셀룰러 스트리밍 꺼짐, 04장 S10).
  Future<void> attach(ApiClient api, {LibraryStore? library, DownloadEngine? downloads, Future<void> Function(PlayEvent)? onPlayEvent, Future<String?> Function()? streamQuality});
  Future<void> detach();

  Future<void> playTracks(List<Track> tracks, {required QueueContext context, int start, bool? shuffle});
  void playNext(List<Track> tracks);
  void addToEnd(List<Track> tracks);
  Future<void> removeItem(String queueItemId);

  /// 바로 전에 뺀 곡을 같은 자리로 되돌린다 (대기열 실행 취소, 04장 S8). 그새 곡이 바뀌었으면 하지 않는다
  void undoRemove();

  /// 대기열 비우기 (04장 S8): 지금 곡만 남긴다
  void clearUpcoming();
  Future<void> jumpTo(String queueItemId);
  void moveContinuing(int from, int to);
  void setShuffle(bool on);
  void cycleRepeat();

  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> skipToNext();
  Future<void> skipToPrevious();

  /// 표지 파일 캐시 (Authorization 헤더로 받는다)
  Future<File?> cachedArtwork(String? artworkId, int size);
}
