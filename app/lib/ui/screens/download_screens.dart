// S9 다운로드 관리 (04장 S9)와 다운로드 표시·버튼. 상태 문구는 03장 §5.3 상태와 1:1.
import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:flutter/material.dart';

import '../../data/download_engine.dart';
import '../../data/library_store.dart';
import '../../domain/download_state.dart';
import '../../domain/queue.dart';
import '../glass.dart';
import '../scope.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import '../widgets/purchase_gate.dart';
import '../../core/entitlement.dart';
import 'browse_screens.dart';

/// 실패 사유 (04장 S9 오류 상태: 네트워크 / 서버에 파일 없음 / 무결성 불일치 / 저장 공간 / 서버가 바쁨)
String downloadReason(String? code) => switch (code) {
      null => '',
      'network' || 'offline' || 'io_error' => '네트워크',
      'media_missing' || 'not_found' => '서버에 파일 없음',
      'integrity_mismatch' => '무결성 불일치',
      'file_missing' || 'file_corrupt' => '파일 없음',
      'disk_full' => '저장 공간',
      'transcode_queue_full' || 'server_error' => '서버가 바쁨',
      'transcode_failed' || 'unsupported_source' || 'no_playable_format' => '서버에서 변환하지 못함',
      'forbidden' => '권한 없음',
      _ => code,
    };

/// 상태 문구 (04장 S9: "대기 중", "서버에서 준비 중", "받는 중 62%", … "실패: 사유")
String downloadStatusText(Download d) {
  if (d.locked) return '잠김';
  return switch (d.state) {
    DlState.queued when d.errorCode == 'file_missing' || d.errorCode == 'file_corrupt' => '다시 받는 중: 파일 없음',
    DlState.queued when d.notBefore != null => '다시 시도 대기: ${downloadReason(d.errorCode)}',
    DlState.queued || DlState.resolving => '대기 중',
    DlState.preparing => '서버에서 준비 중',
    DlState.downloading => d.bytesTotal == null || d.bytesTotal == 0 ? '받는 중' : '받는 중 ${(d.bytesDone * 100 / d.bytesTotal!).clamp(0, 100).floor()}%',
    DlState.paused => '일시중지됨',
    DlState.waitingWifi => 'Wi-Fi 연결 대기',
    DlState.waitingNetwork => '네트워크 연결 대기',
    DlState.waitingSpace => '저장 공간 부족',
    DlState.waitingLogin => '로그인 필요',
    DlState.verifying => '확인 중',
    DlState.completed => d.stale ? '완료 · 업데이트 있음' : '완료',
    DlState.failed => '실패: ${downloadReason(d.errorCode)}',
  };
}

String formatBytes(int? b) {
  if (b == null) return '';
  if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
  if (b < 1024 * 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
  return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}

bool _inProgress(Download d) => !d.locked && d.state != DlState.completed && d.state != DlState.failed;
bool _needsAttention(Download d) => d.locked || d.state == DlState.failed || (d.state == DlState.completed && d.stale);

/// 다운로드 탭 아이콘: 진행 중 개수 배지, 실패가 있으면 경고 점 (04장 §2)
class DownloadsTabIcon extends StatelessWidget {
  const DownloadsTabIcon({super.key, required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final engine = context.watchApp().downloads;
    final icon = Icon(selected ? Icons.download : Icons.download_outlined);
    if (engine == null) return icon;
    return ValueListenableBuilder<List<Download>>(
      valueListenable: engine.rows,
      builder: (_, rows, _) {
        final n = rows.where(_inProgress).length;
        final failed = rows.any((d) => d.state == DlState.failed);
        if (n == 0 && !failed) return icon;
        return Badge(
          label: n > 0 ? Text('$n') : null,
          smallSize: 8,
          backgroundColor: failed ? context.colors.danger : null,
          child: icon,
        );
      },
    );
  }
}

/// 곡 행 끝의 다운로드 표시 (완료 ✓, 진행 중 원형 진행률, 실패 !)
class TrackDownloadMark extends StatelessWidget {
  const TrackDownloadMark(this.trackId, {super.key});
  final String trackId;

  @override
  Widget build(BuildContext context) {
    final engine = context.watchApp().downloads;
    if (engine == null) return const SizedBox.shrink();
    return ValueListenableBuilder<List<Download>>(
      valueListenable: engine.rows,
      builder: (_, rows, _) {
        final mine = rows.where((d) => d.trackId == trackId).toList();
        if (mine.isEmpty) return const SizedBox.shrink();
        final c = context.colors;
        final done = mine.where((d) => d.state == DlState.completed).firstOrNull;
        final d = done ?? mine.first;
        final Widget mark;
        if (d.locked) {
          mark = Icon(Icons.lock, size: 16, color: c.textMuted, semanticLabel: '다운로드 잠김');
        } else if (d.state == DlState.completed) {
          mark = Icon(Icons.download_done, size: 16, color: c.accent, semanticLabel: '다운로드됨');
        } else if (d.state == DlState.failed) {
          mark = Icon(Icons.error_outline, size: 16, color: c.danger, semanticLabel: '다운로드 실패');
        } else {
          final v = d.state == DlState.downloading && (d.bytesTotal ?? 0) > 0 ? d.bytesDone / d.bytesTotal! : null;
          mark = Semantics(label: downloadStatusText(d), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, value: v)));
        }
        return Padding(padding: const EdgeInsets.only(left: Space.xs), child: mark);
      },
    );
  }
}

/// 앨범·플레이리스트 머리의 다운로드 버튼 (고정 묶음 켜기/끄기 + 진행 요약)
class GroupDownloadButton extends StatefulWidget {
  const GroupDownloadButton({super.key, required this.kind, required this.refId, required this.trackIds});
  final RequestKind kind;
  final String refId;
  final List<String> trackIds;
  @override
  State<GroupDownloadButton> createState() => _GroupDownloadButtonState();
}

class _GroupDownloadButtonState extends State<GroupDownloadButton> {
  bool? _pinned;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lib = context.readApp().library;
    lib?.isPinned(widget.kind, widget.refId).then((v) {
      if (mounted) setState(() => _pinned = v);
    });
  }

  Future<void> _toggle() async {
    final app = context.readApp();
    final engine = app.downloads;
    if (engine == null) return;
    setState(() => _busy = true);
    try {
      if (_pinned == true) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('다운로드를 삭제할까요?'),
            content: const Text('이 기기에서 지웁니다. 다른 플레이리스트·앨범이 같은 곡을 받아 두었다면 그 곡은 남습니다.'),
            actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('취소')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('삭제'))],
          ),
        );
        if (ok != true) return;
        await engine.removeGroup(widget.kind, widget.refId);
        _pinned = false;
      } else {
        if (!await ensureCan(context, Feature.download)) return;
        if (widget.kind == RequestKind.album) {
          await engine.downloadAlbum(widget.refId);
        } else {
          await engine.downloadPlaylist(widget.refId);
        }
        _pinned = true;
        if (mounted && app.downloadSettings.wifiOnly) {
          final net = await app.services?.conditions.network();
          if (mounted && net != null && !net.wifi) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wi-Fi에 연결되면 받습니다 (설정에서 바꿀 수 있습니다)')));
          }
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('다운로드를 시작하지 못했습니다. 서버 연결을 확인하세요.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watchApp().downloads;
    if (engine == null) return const SizedBox.shrink();
    return ValueListenableBuilder<List<Download>>(
      valueListenable: engine.rows,
      builder: (_, rows, _) {
        final ids = widget.trackIds.toSet();
        final mine = rows.where((d) => ids.contains(d.trackId)).toList();
        final done = {for (final d in mine) if (d.state == DlState.completed) d.trackId}.length;
        final label = _pinned == true
            ? (done >= ids.length ? '다운로드됨' : '받는 중 $done/${ids.length}')
            : '다운로드';
        return OutlinedButton.icon(
          onPressed: _busy || _pinned == null ? null : _toggle,
          icon: Icon(_pinned == true ? Icons.download_done : Icons.download),
          label: Text(label),
        );
      },
    );
  }
}

// ── S9 다운로드 관리 ───────────────────────────────────────────

enum _Sort { recent, size }

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});
  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  _Sort _sort = _Sort.recent;
  final _selected = <String>{};
  Map<String, Track> _tracks = {};
  Set<String> _known = {};
  int _doneSeen = -1;
  ({int used, int? free})? _space;

  Future<void> _refreshMeta(List<Download> rows) async {
    final app = context.readApp();
    final lib = app.library;
    if (lib == null) return;
    final ids = rows.map((d) => d.trackId).toSet();
    final done = rows.where((d) => d.state == DlState.completed).length;
    if (ids.difference(_known).isEmpty && _space != null && done == _doneSeen) return;
    _known = ids;
    _doneSeen = done;
    final tracks = await lib.tracksByIds(ids);
    final used = await lib.usedBytes();
    final free = await app.services?.conditions.freeBytes(lib.root);
    if (!mounted) return;
    setState(() {
      _tracks = tracks;
      _space = (used: used, free: free);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watchApp();
    final engine = app.downloads;
    if (engine == null) {
      return const GlassScaffold(body: EmptyState(title: '다운로드', message: '이 환경에서는 다운로드를 쓸 수 없습니다.', icon: Icons.download_outlined));
    }
    return ValueListenableBuilder<List<Download>>(
      valueListenable: engine.rows,
      builder: (context, rows, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _refreshMeta(rows));
        final progress = rows.where(_inProgress).toList();
        final attention = rows.where(_needsAttention).toList();
        // rows는 요청한 순서(로컬 DB created_at 순 + 새로 추가한 것). 최근순은 그 역순
        // (다운로드 ID는 무작위라 ID로 정렬하면 순서가 섞인다 — 실기기에서 발견)
        var done = rows.where((d) => d.state == DlState.completed && !d.locked).toList();
        if (_sort == _Sort.size) {
          done.sort((a, b) => (b.bytesTotal ?? 0).compareTo(a.bytesTotal ?? 0));
        } else {
          done = done.reversed.toList();
        }
        final selecting = _selected.isNotEmpty;
        return GlassScaffold(
          appBar: GlassAppBar(
            title: Text(selecting ? '${_selected.length}개 선택' : '다운로드'),
            leading: selecting ? IconButton(onPressed: () => setState(_selected.clear), icon: const Icon(Icons.close), tooltip: '선택 취소') : null,
            actions: [
              if (selecting)
                IconButton(onPressed: () => _deleteSelected(engine), icon: const Icon(Icons.delete_outline), tooltip: '선택한 다운로드 삭제')
              else
                PopupMenuButton<_Sort>(
                  tooltip: '정렬',
                  icon: const Icon(Icons.sort),
                  onSelected: (v) => setState(() => _sort = v),
                  itemBuilder: (_) => const [PopupMenuItem(value: _Sort.recent, child: Text('최근순')), PopupMenuItem(value: _Sort.size, child: Text('크기순'))],
                ),
            ],
          ),
          body: rows.isEmpty
              ? EmptyState(
                  title: '다운로드한 음악이 없습니다',
                  message: '앨범이나 플레이리스트에서 다운로드 버튼을 누르세요',
                  icon: Icons.download_outlined,
                )
              : ListView(children: glassGroups([
                  // 사용량은 목록에서 바로 센다(완료될 때마다 갱신). 기기 여유만 따로 묻는다
                  _SpaceBar(
                    space: (used: rows.where((d) => d.state == DlState.completed).fold<int>(0, (s, d) => s + (d.bytesTotal ?? 0)), free: _space?.free),
                    limit: app.downloadSettings.limitBytes,
                  ),
                  if (progress.isNotEmpty) ...[
                    _Header('진행 중', trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      TextButton(onPressed: engine.pauseAll, child: const Text('전체 일시중지')),
                      TextButton(onPressed: engine.resumeAll, child: const Text('전체 재개')),
                    ])),
                    for (final d in progress) _row(context, engine, d),
                  ],
                  if (attention.isNotEmpty) ...[
                    const _Header('확인 필요'),
                    if (attention.any((d) => d.locked))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                        child: Text('잠긴 항목은 서버 접근이 취소되었거나 로그아웃하며 보관한 것입니다. 같은 계정으로 다시 로그인하면 풀립니다.',
                            style: TextStyle(color: context.colors.textMuted)),
                      ),
                    for (final d in attention) _row(context, engine, d),
                  ],
                  if (done.isNotEmpty) ...[
                    _Header('완료 ${done.length}곡 · ${formatBytes(done.fold<int>(0, (s, d) => s + (d.bytesTotal ?? 0)))}'),
                    for (final d in done) _row(context, engine, d, selectable: true),
                  ],
                  const SizedBox(height: Space.xxl),
                ], (w) => w is _Header || w is _SpaceBar)),
        );
      },
    );
  }

  Widget _row(BuildContext context, DownloadEngine engine, Download d, {bool selectable = false}) {
    final t = _tracks[d.trackId];
    final title = t?.title ?? '곡';
    final c = context.colors;
    final selected = _selected.contains(d.id);
    final status = downloadStatusText(d);
    final sub = [status, if (d.state == DlState.completed) formatBytes(d.bytesTotal), if (t != null) artistNames(t)].where((s) => s.isNotEmpty).join(' · ');
    final actions = <Widget>[
      // 잠긴 항목은 다시 로그인하기 전에는 받을 수 없다 — 삭제만 (상태 갤러리에서 발견)
      if (!d.locked && (d.state == DlState.failed || (d.state == DlState.completed && d.stale)))
        IconButton(onPressed: () => engine.retry(d.id), icon: const Icon(Icons.refresh), tooltip: d.stale ? '새 버전 받기' : '다시 시도'),
      if (_inProgress(d) && d.state != DlState.paused) IconButton(onPressed: () => engine.pause(d.id), icon: const Icon(Icons.pause), tooltip: '일시중지'),
      if (!d.locked && d.state == DlState.paused) IconButton(onPressed: () => engine.resume(d.id), icon: const Icon(Icons.play_arrow), tooltip: '재개'),
      IconButton(onPressed: () => engine.cancel(d.id), icon: const Icon(Icons.delete_outline), tooltip: '삭제'),
    ];
    final big = context.textScale >= 1.3;
    final progress = !d.locked && d.state == DlState.downloading && (d.bytesTotal ?? 0) > 0 ? d.bytesDone / d.bytesTotal! : null;
    return Column(children: [
      ListTile(
        selected: selected,
        leading: selectable && _selected.isNotEmpty
            ? Checkbox(value: selected, onChanged: (_) => setState(() => selected ? _selected.remove(d.id) : _selected.add(d.id)))
            : Artwork(t?.artworkId, size: 48, label: title),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(sub, style: TextStyle(color: !d.locked && d.state == DlState.failed ? c.danger : c.textMuted)),
        // 큰 글씨: 버튼은 행 끝이 아니라 다음 줄로 (04장 S9)
        trailing: big || selectable ? null : Row(mainAxisSize: MainAxisSize.min, children: actions),
        onLongPress: selectable ? () => setState(() => _selected.add(d.id)) : null,
        onTap: () {
          if (_selected.isNotEmpty && selectable) {
            setState(() => selected ? _selected.remove(d.id) : _selected.add(d.id));
          } else if (d.playable && t != null) {
            playTracks(context, [t], 0, const QueueContext(ContextType.adhoc, null, '다운로드'));
          }
        },
      ),
      if (progress != null) Padding(padding: const EdgeInsets.symmetric(horizontal: Space.lg), child: LinearProgressIndicator(value: progress)),
      if (big && !selectable) Align(alignment: Alignment.centerRight, child: Wrap(children: actions)),
    ]);
  }

  Future<void> _deleteSelected(DownloadEngine engine) async {
    final ids = [..._selected];
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('${ids.length}곡의 다운로드를 삭제할까요?'),
        actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('취소')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('삭제'))],
      ),
    );
    if (ok != true) return;
    for (final id in ids) {
      await engine.cancel(id);
    }
    setState(() {
      _selected.clear();
      _space = null;
    });
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title, {this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.sm, Space.xs),
        child: Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(title, style: context.text.titleMedium),
          ?trailing,
        ]),
      );
}

/// 상단 저장 공간 막대: BangMusic 사용량 / 한도 / 기기 여유 (04장 S9)
class _SpaceBar extends StatelessWidget {
  const _SpaceBar({required this.space, required this.limit});
  final ({int used, int? free}) space;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final s = space;
    final total = limit ?? (s.free == null ? null : s.used + s.free!);
    final text = [
      '사용 ${formatBytes(s.used)}',
      limit != null ? '한도 ${formatBytes(limit)}' : '한도 없음',
      if (s.free != null) '기기 여유 ${formatBytes(s.free)}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (total != null && total > 0) LinearProgressIndicator(value: (s.used / total).clamp(0, 1), minHeight: 6, borderRadius: BorderRadius.circular(3)),
        const SizedBox(height: Space.xs),
        Text(text, style: context.text.bodySmall?.copyWith(color: context.colors.textMuted)),
      ]),
    );
  }
}
