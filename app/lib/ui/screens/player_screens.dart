// S7 미니 플레이어, S8 몰입 화면 (LP · 가사 · 대기열)
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:flutter/material.dart' hide RepeatMode;

import '../../core/api_client.dart';
import '../../domain/lyrics.dart';
import '../../domain/playback_state.dart';
import '../../domain/queue.dart';
import '../../platform/player_port.dart';
import '../scope.dart';
import '../ambient.dart';
import '../glass.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'download_screens.dart';

void openNowPlaying(BuildContext context) => Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => const NowPlayingScreen()),
    );

/// 재생 상태가 바뀔 때 다시 그린다
class _PlayerBuilder extends StatelessWidget {
  const _PlayerBuilder({required this.builder});
  final Widget Function(BuildContext, PlayerPort) builder;

  @override
  Widget build(BuildContext context) {
    final p = context.readApp().player;
    return ListenableBuilder(listenable: Listenable.merge([p.queueChanged, p.status, p.nowSource, p.errorMessage]), builder: (c, _) => builder(c, p));
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton(this.p);
  final PlayerPort p;

  @override
  Widget build(BuildContext context) {
    final st = p.status.value;
    if (st == PlaybackStatus.loading || st == PlaybackStatus.buffering) {
      return const SizedBox(width: 48, height: 48, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2.5, semanticsLabel: '불러오는 중')));
    }
    final playing = st == PlaybackStatus.playing;
    return IconButton(onPressed: playing ? p.pause : p.play, icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30), tooltip: playing ? '일시정지' : '재생');
  }
}

// ── S7 ──────────────────────────────────────────────────────────

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  /// 탭 막대 위에 뜬 유리 알약의 높이 (04장 §3.4)
  static const height = 64.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final g = context.glass;
    return _PlayerBuilder(builder: (context, p) {
      final t = p.currentTrack;
      if (t == null) return const SizedBox.shrink();
      final err = p.errorMessage.value;
      final hideArtist = context.textScale >= 1.5;
      // 받은 곡을 오프라인으로 재생 중이면 작은 오프라인 아이콘 (04장 S7)
      final offlineLocal = context.watchApp().offline && p.nowSource.value.local;
      return Glass(
        circle: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => openNowPlaying(context),
            child: Stack(children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: height),
                child: GestureDetector(
                  onHorizontalDragEnd: (d) {
                    final v = d.primaryVelocity ?? 0;
                    if (v < -200) p.skipToNext();
                    if (v > 200) p.skipToPrevious();
                  },
                  // 위로 끌기 → 몰입 화면 (04장 S7. 누르기와 같은 기능의 보조 수단)
                  onVerticalDragEnd: (d) {
                    if ((d.primaryVelocity ?? 0) < -200) openNowPlaying(context);
                  },
                  child: Row(children: [
                    const SizedBox(width: Space.sm),
                    Artwork(t.artworkId, size: 48, radius: 24, label: t.title),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Row(children: [
                          if (offlineLocal) Padding(padding: const EdgeInsets.only(right: 4), child: Icon(Icons.cloud_off, size: 14, color: g.onGlassMuted, semanticLabel: '오프라인, 받은 곡 재생 중')),
                          Flexible(child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium?.copyWith(color: g.onGlass))),
                        ]),
                        if (err != null)
                          Row(children: [Icon(Icons.error_outline, size: 16, color: c.danger), const SizedBox(width: 4), Flexible(child: Text(err, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: g.onGlass, fontSize: 13)))])
                        else if (p.nowSource.value.preparing)
                          Text('서버에서 준비 중', style: context.text.bodySmall?.copyWith(color: g.onGlassMuted))
                        else if (!hideArtist)
                          Text(artistNames(t), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall?.copyWith(color: g.onGlassMuted)),
                      ]),
                    ),
                    IconTheme.merge(data: IconThemeData(color: g.onGlass), child: _PlayButton(p)),
                    IconButton(onPressed: p.skipToNext, icon: Icon(Icons.skip_next_rounded, color: g.onGlass), tooltip: '다음 곡'),
                    const SizedBox(width: Space.xs),
                  ]),
                ),
              ),
              // 진행선: 알약 아래 가장자리 안쪽
              Positioned(
                left: 28, right: 28, bottom: 3,
                child: StreamBuilder<Duration>(
                  stream: p.position,
                  builder: (_, s) {
                    final pos = s.data?.inMilliseconds ?? 0;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(value: t.durationMs == 0 ? 0 : (pos / t.durationMs).clamp(0, 1), minHeight: 2.5, backgroundColor: g.onGlass.withValues(alpha: 0.12)),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      );
    });
  }
}

// ── S8 ──────────────────────────────────────────────────────────

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});
  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  int _pane = 0; // 0 LP, 1 가사, 2 대기열

  @override
  Widget build(BuildContext context) {
    // 몰입 화면은 테마와 관계없이 어두운 화면: 흐린 표지 + 가림막 위에 밝은 글자 (04장 §3.4)
    final off = context.glassOff;
    return Theme(
      data: buildTheme(Brightness.dark, glassOff: off),
      child: Builder(builder: (context) => _PlayerBuilder(builder: (context, p) {
        final t = p.currentTrack;
        final q = p.playQueue;
        if (t == null || q == null) {
          return const GlassScaffold(appBar: GlassAppBar(), body: EmptyState(title: '재생 중인 곡이 없습니다'));
        }
        final big = context.textScale >= 1.5;
        final size = MediaQuery.sizeOf(context);
        final landscape = size.width > size.height && size.width >= 600;
        Widget pane(int i) => switch (i) {
              0 => Center(child: _LpDisc(track: t, player: p)),
              1 => _LyricsPane(track: t, player: p, showDisc: !big),
              _ => _QueuePane(player: p),
            };
        final header = Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
          child: Row(children: [
            GlassIconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded), onPressed: () => Navigator.pop(context), tooltip: '닫기', size: 44, iconSize: 26),
            Expanded(
              child: Column(children: [
                Text('재생 중', style: context.text.bodySmall?.copyWith(color: context.glass.onGlassMuted, letterSpacing: 0.5)),
                if (q.context.name != null)
                  Text(q.context.name!, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: context.text.titleMedium),
              ]),
            ),
            const SizedBox(width: 44),
          ]),
        );
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(children: [
            Positioned.fill(child: _ArtBackdrop(track: t)),
            SafeArea(
              child: Column(children: [
                header,
                Expanded(
                  child: landscape
                      ? Row(children: [
                          Expanded(child: _controls(context, p, t, q, _LpDisc(track: t, player: p, fill: true), showPanes: false, landscape: true)),
                          Expanded(
                            child: Column(children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(Space.xl, Space.md, Space.xl, Space.sm),
                                child: GlassSegmented(labels: const ['가사', '대기열'], values: const [1, 2], selected: _pane == 0 ? 1 : _pane, onSelect: (v) => setState(() => _pane = v)),
                              ),
                              Expanded(child: pane(_pane == 0 ? 1 : _pane)),
                            ]),
                          ),
                        ])
                      : _controls(
                          context, p, t, q,
                          GestureDetector(
                            onHorizontalDragEnd: (d) {
                              final v = d.primaryVelocity ?? 0;
                              if (v < -300 && _pane < 2) setState(() => _pane++);
                              if (v > 300 && _pane > 0) setState(() => _pane--);
                            },
                            child: AnimatedSwitcher(duration: context.reduceMotion ? Duration.zero : Motion.base, child: KeyedSubtree(key: ValueKey(_pane), child: pane(_pane))),
                          ),
                          showPanes: true,
                        ),
                ),
              ]),
            ),
          ]),
        );
      })),
    );
  }

  /// 위쪽 구획 + 제목·탐색·재생 제어(+ 세로 화면이면 LP/가사/대기열 전환).
  /// 가로 화면은 LP를 제목 왼쪽에 둔다 — 세로로 쌓으면 휴대폰 가로 높이(약 400dp)에서 LP 자리가 남지 않았다(FN-19 실기기에서 발견)
  Widget _controls(BuildContext context, PlayerPort p, Track t, PlayQueue q, Widget top, {required bool showPanes, bool landscape = false}) {
    final c = context.colors;
    final g = context.glass;
    final status = <Widget>[
      if (p.errorMessage.value != null)
        Padding(
          padding: const EdgeInsets.all(Space.sm),
          // 사유와 "다음 곡" (04장 S8 오류). 자동으로 넘어가기 전 3초 동안 보인다
          child: Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: Space.sm, children: [
            Icon(Icons.error_outline, color: c.danger),
            Text(p.errorMessage.value!, style: TextStyle(color: g.onGlass)),
            TextButton(onPressed: p.skipToNext, child: const Text('다음 곡')),
          ]),
        )
      else if (p.nowSource.value.preparing)
        // 변환 대기 (04장 S8 로딩)
        Padding(
          padding: const EdgeInsets.all(Space.sm),
          child: Text('서버에서 재생용 파일을 준비 중입니다', textAlign: TextAlign.center, style: TextStyle(color: g.onGlassMuted)),
        ),
    ];
    final info = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Flexible(child: Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.displaySmall?.copyWith(fontSize: 24, height: 1.25))),
        TrackDownloadMark(t.id),
      ]),
      const SizedBox(height: 2),
      Text(artistNames(t), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: g.onGlassMuted, fontSize: 17)),
      if (p.nowSource.value.label.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: Space.sm),
          child: Glass(
            kind: GlassKind.thin,
            circle: true,
            padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 3),
            child: Text(p.nowSource.value.label, style: context.text.bodySmall?.copyWith(color: g.onGlass, fontWeight: FontWeight.w600)),
          ),
        ),
    ]);
    final controls = Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      IconButton(
        onPressed: () => p.setShuffle(!q.shuffle),
        icon: Icon(Icons.shuffle_rounded, color: q.shuffle ? c.accent : g.onGlassMuted),
        tooltip: q.shuffle ? '셔플 끄기' : '셔플 켜기',
      ),
      IconButton(onPressed: p.skipToPrevious, icon: Icon(Icons.skip_previous_rounded, size: 40, color: g.onGlass), tooltip: '이전 곡'),
      _BigPlayButton(p),
      IconButton(onPressed: p.skipToNext, icon: Icon(Icons.skip_next_rounded, size: 40, color: g.onGlass), tooltip: '다음 곡'),
      IconButton(
        onPressed: p.cycleRepeat,
        icon: Icon(q.repeat == RepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded, color: q.repeat == RepeatMode.off ? g.onGlassMuted : c.accent),
        tooltip: switch (q.repeat) { RepeatMode.off => '반복 꺼짐', RepeatMode.all => '전체 반복', RepeatMode.one => '한 곡 반복' },
      ),
    ]);
    return Column(children: [
      if (landscape)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 0),
            child: Row(children: [
              top,
              const SizedBox(width: Space.lg),
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [info, ...status])),
            ]),
          ),
        )
      else ...[
        Expanded(child: top),
        ...status,
        Padding(padding: const EdgeInsets.fromLTRB(Space.xl, Space.sm, Space.xl, 0), child: Row(children: [Expanded(child: info)])),
      ],
      const SizedBox(height: Space.sm),
      _SeekBar(player: p, durationMs: t.durationMs),
      // 재생 제어 줄은 세 구획에서 항상 같은 자리 (04장 S8)
      controls,
      if (showPanes)
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xxl, Space.md, Space.xxl, Space.md),
          child: GlassSegmented(labels: const ['LP', '가사', '대기열'], selected: _pane, onSelect: (v) => setState(() => _pane = v)),
        )
      else
        const SizedBox(height: Space.md),
    ]);
  }
}

/// 몰입 화면 재생 버튼: 큰 유리 원
class _BigPlayButton extends StatelessWidget {
  const _BigPlayButton(this.p);
  final PlayerPort p;

  @override
  Widget build(BuildContext context) {
    final st = p.status.value;
    if (st == PlaybackStatus.loading || st == PlaybackStatus.buffering) {
      return const SizedBox(width: 76, height: 76, child: Padding(padding: EdgeInsets.all(22), child: CircularProgressIndicator(strokeWidth: 3, semanticsLabel: '불러오는 중')));
    }
    final playing = st == PlaybackStatus.playing;
    return GlassIconButton(
      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
      onPressed: playing ? p.pause : p.play,
      tooltip: playing ? '일시정지' : '재생',
      size: 76,
      iconSize: 42,
    );
  }
}

/// 몰입 화면 배경: 표지를 크게 흐리고 가림막을 깐다. 가림막 세기는 표지 밝기로 정해 글자 대비를 지킨다(04장 §3.4).
/// 표지가 없거나 투명도 줄이기면 배경 덩어리/단색
class _ArtBackdrop extends StatefulWidget {
  const _ArtBackdrop({required this.track});
  final Track track;
  @override
  State<_ArtBackdrop> createState() => _ArtBackdropState();
}

class _ArtBackdropState extends State<_ArtBackdrop> {
  Future<File?>? _file;
  String? _for;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(_ArtBackdrop old) {
    super.didUpdateWidget(old);
    _load();
  }

  void _load() {
    if (_loaded && _for == widget.track.artworkId) return;
    _loaded = true;
    _for = widget.track.artworkId;
    _file = widget.track.artworkId == null ? Future.value(null) : context.readApp().player.cachedArtwork(widget.track.artworkId, 256);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watchApp();
    if (context.glassOff) return ColoredBox(color: context.colors.bg);
    final scrim = scrimFor(app.ambient.luma ?? 0.2);
    return FutureBuilder<File?>(
      future: _file,
      builder: (context, s) {
        final f = s.data;
        final art = f == null
            ? const AmbientBackdrop(child: SizedBox.expand())
            : RepaintBoundary(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60, tileMode: TileMode.mirror),
                  child: Transform.scale(scale: 1.4, child: Image.file(f, fit: BoxFit.cover, width: double.infinity, height: double.infinity, gaplessPlayback: true)),
                ),
              );
        return Stack(fit: StackFit.expand, children: [
          ColoredBox(color: context.colors.bg),
          AnimatedSwitcher(duration: context.reduceMotion ? Duration.zero : Motion.slow, child: KeyedSubtree(key: ValueKey(f?.path), child: art)),
          ColoredBox(color: Colors.black.withValues(alpha: f == null ? 0.25 : scrim)),
          // 아래쪽(글자·조작부)을 조금 더 어둡게
          const DecoratedBox(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.center, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0x40000000)])),
          ),
        ]);
      },
    );
  }
}

class _SeekBar extends StatefulWidget {
  const _SeekBar({required this.player, required this.durationMs});
  final PlayerPort player;
  final int durationMs;
  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    return StreamBuilder<Duration?>(
      stream: p.duration,
      builder: (_, ds) {
        // 플레이어가 길이를 보고하면 그 값, 그 전에는 곡 길이 (03장 §4.3)
        final total = max(1, ds.data?.inMilliseconds ?? widget.durationMs);
        return StreamBuilder<Duration>(
          stream: p.position,
          builder: (_, ps) {
            final pos = _drag ?? (ps.data?.inMilliseconds ?? 0).clamp(0, total).toDouble();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              child: Column(children: [
                Semantics(
                  label: '재생 위치',
                  value: '${formatMs(pos.toInt())} / ${formatMs(total)}',
                  // 스크린리더에서 10초 단위 증감 (04장 §4)
                  // increase/decrease 동작에는 바뀐 값 설명이 함께 있어야 한다(없으면 접근성 트리가 깨짐 — 위젯 테스트에서 발견)
                  increasedValue: formatMs(min(total, pos.toInt() + 10000)),
                  decreasedValue: formatMs(max(0, pos.toInt() - 10000)),
                  onIncrease: () => p.seek(Duration(milliseconds: min(total, pos.toInt() + 10000))),
                  onDecrease: () => p.seek(Duration(milliseconds: max(0, pos.toInt() - 10000))),
                  child: Slider(
                    value: pos,
                    max: total.toDouble(),
                    label: formatMs(pos.toInt()),
                    divisions: null,
                    onChanged: (v) => setState(() => _drag = v),
                    onChangeEnd: (v) {
                      p.seek(Duration(milliseconds: v.toInt()));
                      setState(() => _drag = null);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                  child: Row(children: [
                    Text(formatMs(pos.toInt()), style: context.text.bodySmall),
                    const Spacer(),
                    Text('-${formatMs(total - pos.toInt())}', style: context.text.bodySmall),
                  ]),
                ),
              ]),
            );
          },
        );
      },
    );
  }
}

/// LP 원반 (04장 §4 LpDisc). 재생 중 1회전 약 1.8초, 일시정지 시 감속 정지. 동작 줄이기면 정지 상태 고정.
class _LpDisc extends StatefulWidget {
  const _LpDisc({required this.track, required this.player, this.fill = false});
  final Track track;
  final PlayerPort player;

  /// 주어진 자리를 채운다(가로 화면). 아니면 화면 크기 기준
  final bool fill;
  @override
  State<_LpDisc> createState() => _LpDiscState();
}

class _LpDiscState extends State<_LpDisc> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    final playing = p.status.value == PlaybackStatus.playing;
    if (playing && !context.reduceMotion) {
      if (!_spin.isAnimating) _spin.repeat();
    } else if (_spin.isAnimating) {
      _spin.stop();
    }
    if (widget.fill) {
      return LayoutBuilder(builder: (context, box) {
        final size = max(0.0, min(box.maxHeight, MediaQuery.sizeOf(context).width * 0.22));
        return _disc(context, size);
      });
    }
    return _disc(context, min(MediaQuery.sizeOf(context).width * 0.75, MediaQuery.sizeOf(context).height * 0.38));
  }

  Widget _disc(BuildContext context, double size) {
    final p = widget.player;
    final playing = p.status.value == PlaybackStatus.playing;
    return Semantics(
      button: true,
      label: playing ? 'LP, 눌러서 일시정지' : 'LP, 눌러서 재생',
      child: GestureDetector(
        onTap: playing ? p.pause : p.play,
        child: Stack(alignment: Alignment.center, children: [
          RotationTransition(
            turns: _spin,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0xFF2A2A2A), Color(0xFF0A0A0A), Color(0xFF1C1C1C), Color(0xFF050505)], stops: [0.3, 0.55, 0.8, 1]),
                boxShadow: [BoxShadow(color: Color(0x80000000), blurRadius: 40, offset: Offset(0, 16))],
              ),
              alignment: Alignment.center,
              child: CustomPaint(
                painter: _GroovePainter(),
                child: SizedBox(
                  width: size, height: size,
                  child: Center(child: ClipOval(child: Artwork(widget.track.artworkId, size: size * 0.38, radius: size, label: widget.track.title))),
                ),
              ),
            ),
          ),
          // 고정된 빛 반사(회전하지 않음) — 유리 같은 광택 (04장 §3.4)
          IgnorePointer(
            child: Container(
              width: size, height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x33FFFFFF)),
                gradient: const SweepGradient(
                  colors: [Color(0x00FFFFFF), Color(0x1FFFFFFF), Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0x14FFFFFF), Color(0x00FFFFFF)],
                  stops: [0.0, 0.12, 0.25, 0.5, 0.62, 0.75],
                ),
              ),
            ),
          ),
          if (p.status.value == PlaybackStatus.loading || p.status.value == PlaybackStatus.buffering)
            SizedBox(width: size * 0.42, height: size * 0.42, child: const CircularProgressIndicator(strokeWidth: 3)),
        ]),
      ),
    );
  }
}

/// LP 홈 무늬: 가는 동심원
class _GroovePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (var f = 0.24; f < 0.97; f += 0.022) {
      paint.color = Color.fromARGB(f * 1000 % 3 < 1.5 ? 26 : 14, 255, 255, 255);
      canvas.drawCircle(c, r * f, paint);
    }
  }

  @override
  bool shouldRepaint(_GroovePainter old) => false;
}

/// 3단 가사 (04장 S8 가사, LyricLine)
class _LyricsPane extends StatefulWidget {
  const _LyricsPane({required this.track, required this.player, required this.showDisc});
  final Track track;
  final PlayerPort player;
  final bool showDisc;
  @override
  State<_LyricsPane> createState() => _LyricsPaneState();
}

/// 가사 끝의 출처 표기 (04장 S8, 05장 §8.4): 종류, 출처 이름, 이용 조건
typedef _Credit = ({String kind, String text});

String _creditText(LyricsVariant v) {
  final name = v.source_.name;
  final base = switch (v.source_.type) {
    LyricsVariantSourceTypeEnum.generated => '서버 자동 생성 · 사람이 확인하지 않음',
    _ when name != null && name.isNotEmpty => name,
    LyricsVariantSourceTypeEnum.sidecar => '서버의 가사 파일',
    LyricsVariantSourceTypeEnum.embedded => '음원에 포함된 가사',
    LyricsVariantSourceTypeEnum.user => '직접 입력',
    _ => '외부 제공',
  };
  final note = v.source_.licenseNote;
  return note == null || note.isEmpty ? base : '$base ($note)';
}

class _LyricsPaneState extends State<_LyricsPane> {
  Future<(AlignedLyrics, int)>? _f;
  List<_Credit> _credits = const [];
  String? _loadedFor;
  // 칩 선택은 설정에 기억한다 (04장 S8·S10 가사 기본 표시)
  late bool _pron = context.readApp().prefs.lyricsPronunciation;
  late bool _trans = context.readApp().prefs.lyricsTranslation;
  bool _userScrolled = false;
  final _scroll = ScrollController();
  final _keys = <int, GlobalKey>{};
  int _last = -2;
  StreamSubscription<Duration>? _sub;
  int _current = -1;
  int _offset = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensure();
  }

  @override
  void didUpdateWidget(_LyricsPane old) {
    super.didUpdateWidget(old);
    _ensure();
  }

  void _ensure() {
    if (_loadedFor == widget.track.id) return;
    _loadedFor = widget.track.id;
    _userScrolled = false;
    _keys.clear();
    final app = context.readApp();
    final trackId = widget.track.id;
    // 오프라인이면 다운로드 때 저장한 가사 사본, 온라인이면 서버 (실패하면 사본) — 03장 §5.6
    Future<Lyrics> load() async {
      final saved = await app.library?.lyrics(trackId);
      if (app.offline && saved != null) return saved.lyrics;
      try {
        return await app.api!.call((a) => a.getLyricsApi().getLyrics(trackId: trackId));
      } catch (e) {
        if (saved != null && ApiException.from(e).status == null) return saved.lyrics;
        rethrow;
      }
    }
    _f = load().then((l) {
      _offset = l.offsetMs;
      _credits = [for (final v in l.variants) if (v.lines.isNotEmpty) (kind: v.kind.value, text: _creditText(v))];
      return (
        align([
          for (final v in l.variants)
            LyricVariantData(kind: v.kind.value, synced: v.synced, sourceName: v.source_.name, lines: [for (final x in v.lines) LyricLineData(x.tMs, x.text)]),
        ]),
        l.offsetMs,
      );
    });
    _sub?.cancel();
    final reduceMotion = context.reduceMotion;
    _sub = widget.player.position.listen((pos) async {
      final r = await _f;
      if (r == null || !mounted) return;
      final i = r.$1.currentIndex(pos.inMilliseconds, _offset);
      if (i != _current) setState(() => _current = i);
      if (i != _last && !_userScrolled && i >= 0) {
        _last = i;
        final ctx = _keys[i]?.currentContext;
        // 현재 줄을 화면 위 1/3 지점에 맞춰 자동 스크롤
        if (ctx != null && ctx.mounted) Scrollable.ensureVisible(ctx, alignment: 0.33, duration: reduceMotion ? Duration.zero : Motion.base);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _adjustOffset(int delta) async {
    _offset += delta;
    setState(() {});
    try {
      await context.readApp().api!.call((a) => a.getLyricsApi().putLyricsOffset(trackId: widget.track.id, putLyricsOffsetRequest: PutLyricsOffsetRequest(offsetMs: _offset)));
    } catch (_) {
      // 보정값 저장 실패는 화면 동작을 막지 않는다
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FutureBuilder<(AlignedLyrics, int)>(
      future: _f,
      builder: (context, s) {
        if (s.hasError) return ErrorState(error: s.error!, onRetry: () => setState(() => _loadedFor = null));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final lyrics = s.data!.$1;
        if (lyrics.rows.isEmpty) return const EmptyState(title: '가사가 없습니다', icon: Icons.lyrics_outlined);
        return Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: Row(children: [
              const FilterChip(label: Text('원문'), selected: true, onSelected: null),
              const SizedBox(width: Space.sm),
              _chip(context, '발음', _pron, lyrics.hasPronunciation, (v) {
                setState(() => _pron = v);
                context.readApp().prefs.update(lyricsPronunciation: v);
              }),
              const SizedBox(width: Space.sm),
              _chip(context, '번역', _trans, lyrics.hasTranslation, (v) {
                setState(() => _trans = v);
                context.readApp().prefs.update(lyricsTranslation: v);
              }),
              const Spacer(),
              PopupMenuButton<int>(
                tooltip: '동기화 보정',
                icon: const Icon(Icons.more_vert),
                onSelected: _adjustOffset,
                itemBuilder: (_) => [
                  PopupMenuItem(enabled: false, child: Text('보정 ${(_offset / 1000).toStringAsFixed(1)}초')),
                  const PopupMenuItem(value: 100, child: Text('가사 0.1초 늦게')),
                  const PopupMenuItem(value: -100, child: Text('가사 0.1초 빠르게')),
                ],
              ),
            ]),
          ),
          if (!lyrics.synced) Text('시간 정보가 없는 가사', style: TextStyle(color: c.textMuted)),
          Expanded(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (_) {
                if (!_userScrolled) setState(() => _userScrolled = true);
                return false;
              },
              // 가사 글자 크기 보정 (04장 S10): 시스템 글자 배율에 곱한다. 가사에만 적용
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(context.textScale * context.watchApp().prefs.lyricsScale)),
                // 위·아래 가장자리에서 가사가 서서히 사라진다 (04장 §3.4) — 제목·조작부와 겹쳐 보이지 않게
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (r) => const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
                    stops: [0, 0.08, 0.88, 1],
                  ).createShader(r),
                  child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.xxl),
                itemCount: lyrics.rows.length + 1,
                itemBuilder: (context, i) {
                  if (i == lyrics.rows.length) return _creditsFooter(context);
                  final row = lyrics.rows[i];
                  final key = _keys[i] ??= GlobalKey();
                  final active = lyrics.synced && i == _current;
                  final past = lyrics.synced && i < _current;
                  final color = !lyrics.synced || active ? c.text : past ? c.textMuted : c.text.withValues(alpha: 0.75);
                  return InkWell(
                    key: key,
                    // 줄을 누르면 그 시각으로 탐색
                    onTap: row.tMs == null ? null : () => widget.player.seek(Duration(milliseconds: row.tMs! + _offset)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Space.sm),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(row.original, style: (active ? LyricStyles.active : LyricStyles.normal).copyWith(color: active ? c.accent : color)),
                        if (_pron && row.pronunciation != null) Text(row.pronunciation!, style: LyricStyles.sub.copyWith(color: color)),
                        if (_trans && row.translation != null) Text(row.translation!, style: LyricStyles.sub.copyWith(color: c.textMuted)),
                      ]),
                    ),
                  );
                },
              ),
              ),
              ),
            ),
          ),
          if (_userScrolled && lyrics.synced)
            TextButton.icon(onPressed: () => setState(() { _userScrolled = false; _last = -2; }), icon: const Icon(Icons.my_location), label: const Text('현재 줄로')),
        ]);
      },
    );
  }

  /// 발음·번역 칩. 그 가사가 없으면 비활성이고, 눌러도 이유를 알려 준다 (04장 S8)
  Widget _chip(BuildContext context, String label, bool on, bool available, ValueChanged<bool> onChanged) {
    final chip = FilterChip(label: Text(label), selected: on && available, onSelected: available ? onChanged : null);
    if (available) return chip;
    return Semantics(
      hint: '이 곡에는 $label 가사가 없습니다',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('이 곡에는 $label 가사가 없습니다'))),
        child: chip,
      ),
    );
  }

  Widget _creditsFooter(BuildContext context) {
    const labels = {'original': '가사', 'pronunciation_ko': '발음', 'translation_ko': '번역'};
    final shown = [
      for (final c in _credits)
        if (c.kind == 'original' || (c.kind == 'pronunciation_ko' && _pron) || (c.kind == 'translation_ko' && _trans)) c,
    ];
    if (shown.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Space.xl),
      child: Text(
        [for (final c in shown) '${labels[c.kind] ?? c.kind} 출처: ${c.text}'].join('\n'),
        style: context.text.bodySmall?.copyWith(color: context.colors.textMuted),
      ),
    );
  }
}

/// 대기열 (04장 S8): 지금 재생 중 / 다음에 재생 / 이어서
class _QueuePane extends StatelessWidget {
  const _QueuePane({required this.player});
  final PlayerPort player;

  @override
  Widget build(BuildContext context) {
    final q = player.playQueue!;
    final c = context.colors;
    // 오프라인: 받지 않은 곡은 흐리게 + "오프라인에서 건너뜀" (04장 S8)
    final app = context.watchApp();
    final playable = app.offline && app.downloads != null ? {for (final d in app.downloads!.rows.value) if (d.playable) d.trackId} : null;
    Widget row(QueueItem item, {bool removable = true}) {
      final t = player.trackOf(item.trackId);
      final skipped = playable != null && !playable.contains(item.trackId);
      final tile = ListTile(
        enabled: !skipped,
        leading: Opacity(opacity: skipped ? 0.4 : 1, child: Artwork(t?.artworkId, size: 40, label: t?.title)),
        title: Text(t?.title ?? '알 수 없는 곡', maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: t == null ? null : Text(skipped ? '오프라인에서 건너뜀' : artistNames(t), maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () => player.jumpTo(item.queueItemId),
      );
      if (!removable) return tile;
      return Dismissible(
        key: ValueKey(item.queueItemId),
        background: Container(color: c.surfaceAlt, alignment: Alignment.centerRight, padding: const EdgeInsets.all(Space.lg), child: const Icon(Icons.delete_outline)),
        onDismissed: (_) {
          player.removeItem(item.queueItemId);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${t?.title ?? '곡'}을(를) 대기열에서 뺐습니다'),
            action: SnackBarAction(label: '실행 취소', onPressed: player.undoRemove),
          ));
        },
        child: tile,
      );
    }

    final cont = q.continuing;
    return ListView(children: [
      if (q.upNext.isNotEmpty || cont.isNotEmpty)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (d) => AlertDialog(
                  title: const Text('대기열을 비울까요?'),
                  content: const Text('지금 재생 중인 곡만 남습니다.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('취소')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('비우기'))],
                ),
              );
              if (ok == true) player.clearUpcoming();
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('대기열 비우기'),
          ),
        ),
      Padding(padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 0), child: Text('지금 재생 중', style: context.text.titleMedium)),
      if (q.current != null) row(q.current!, removable: false),
      if (q.upNext.isNotEmpty) ...[
        Padding(padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, 0), child: Text('다음에 재생', style: context.text.titleMedium)),
        for (final it in q.upNext) row(it),
      ],
      Padding(padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, 0), child: Text(q.context.name == null ? '이어서 재생' : '이어서: ${q.context.name}', style: context.text.titleMedium)), // 이름 없는 맥락이면 "이어서:"만 남지 않게
      if (cont.isEmpty) const Padding(padding: EdgeInsets.all(Space.lg), child: Text('이어서 재생할 곡이 없습니다')),
      if (cont.isNotEmpty)
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorderItem: player.moveContinuing,
          children: [for (final it in cont) KeyedSubtree(key: ValueKey(it.queueItemId), child: row(it))],
        ),
      const SizedBox(height: Space.xl),
    ]);
  }
}
