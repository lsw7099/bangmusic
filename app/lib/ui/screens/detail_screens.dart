// S5 앨범 · S6 플레이리스트 (04장 S5·S6). browse_screens.dart의 일부(part) — 공용 비공개 도우미를 같이 쓴다.
// 로컬 우선(04장 §1-4): 로컬 사본이 있으면 먼저 그리고, 서버 응답으로 갱신한다(상단 얇은 진행선).
// 갱신 실패 + 로컬 사본 있음 → 목록 유지 + 스낵바 "새로 고치지 못했습니다" (04장 §5).
part of 'browse_screens.dart';

// ── 공통 머리 ────────────────────────────────────────────────────

/// 스크롤하면 표지가 줄어들고 이름·재생 버튼이 상단 막대에 고정된다 (04장 S5)
class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({
    required this.title, required this.artworkId, required this.info, required this.onPlay, required this.onShuffle,
    required this.slivers, this.extra = const [], this.actions = const [], this.refreshing = false, this.note,
  });
  final String title;
  final String? artworkId;
  final String info;
  final VoidCallback? onPlay;
  final VoidCallback? onShuffle;
  final List<Widget> extra;
  final List<Widget> actions;
  final List<Widget> slivers;
  final bool refreshing;

  /// 버튼 아래 한 줄 (오프라인 "다운로드한 n곡 재생", 동기화 대기 등)
  final Widget? note;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cover = min(w * 0.6, 320.0);
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: cover + kToolbarHeight + Space.lg,
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            if (onPlay != null) IconButton(onPressed: onPlay, icon: const Icon(Icons.play_circle_fill), tooltip: '$title 재생'),
            ...actions,
          ],
          bottom: refreshing ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator(minHeight: 2)) : null,
          flexibleSpace: FlexibleSpaceBar(
            background: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: kToolbarHeight),
                child: Center(child: Artwork(artworkId, size: cover, radius: Radii.lg, label: title)),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.lg),
            child: Column(children: [
              Text(title, style: context.text.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: Space.xs),
              Text(info, style: TextStyle(color: context.colors.textMuted), textAlign: TextAlign.center),
              const SizedBox(height: Space.lg),
              // 큰 글씨에서는 버튼 줄이 여러 행으로 (Wrap)
              Wrap(spacing: Space.md, runSpacing: Space.sm, alignment: WrapAlignment.center, children: [
                FilledButton.icon(onPressed: onPlay, icon: const Icon(Icons.play_arrow), label: const Text('재생')),
                OutlinedButton.icon(onPressed: onShuffle, icon: const Icon(Icons.shuffle), label: const Text('셔플')),
                ...extra,
              ]),
              if (note != null) Padding(padding: const EdgeInsets.only(top: Space.sm), child: note),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: Divider(height: 1)),
        ...slivers,
        const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
      ]),
    );
  }
}

/// 오프라인이면 재생·셔플은 받은 곡만 대상 — 버튼 아래 "다운로드한 n곡 재생" (04장 S5)
Widget? _offlineNote(BuildContext context, List<Track> tracks) {
  final app = context.watchApp();
  final engine = app.downloads;
  if (!app.offline || engine == null) return null;
  return ValueListenableBuilder<List<Download>>(
    valueListenable: engine.rows,
    builder: (_, rows, _) {
      final ids = {for (final d in rows) if (d.playable) d.trackId};
      final n = tracks.where((t) => ids.contains(t.id)).length;
      return Text('오프라인 · 다운로드한 $n곡 재생', style: TextStyle(color: context.colors.textMuted));
    },
  );
}

/// 404: "삭제되었거나 접근할 수 없습니다" + 뒤로 (04장 S5 오류)
Widget _loadError(BuildContext context, String title, Object error, VoidCallback retry) {
  final ae = ApiException.from(error);
  final body = ae.status == 404
      ? EmptyState(title: '삭제되었거나 접근할 수 없습니다', icon: Icons.link_off, actionLabel: '뒤로', action: () => Navigator.of(context).maybePop())
      : ErrorState(error: error, onRetry: retry);
  return Scaffold(appBar: AppBar(title: Text(title)), body: body);
}

// ── S5 앨범 ──────────────────────────────────────────────────────

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key, required this.albumId, required this.title});
  final String albumId;
  final String title;
  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  AlbumDetail? _a;
  Object? _error;
  bool _refreshing = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final app = context.readApp();
    final lib = app.library;
    setState(() => _error = null);
    // 1. 로컬 사본
    if (lib != null && _a == null) {
      final a = await lib.album(widget.albumId);
      if (a != null) {
        final tracks = await lib.albumTracks(widget.albumId);
        if (mounted && _a == null) setState(() => _a = AlbumDetail.fromJson({...a.toJson(), 'tracks': [for (final t in tracks) t.toJson()]}));
      }
    }
    if (app.offline) {
      if (_a == null && mounted) setState(() => _error = ApiException(kind: ApiErrorKind.unreachable));
      return;
    }
    // 2. 서버
    if (mounted) setState(() => _refreshing = true);
    try {
      final a = await app.api!.call((x) => x.getCatalogApi().getAlbum(albumId: widget.albumId));
      // 받아 둔 앨범이면 사본·버전을 최신으로 (§5.4 stale 표시)
      if (lib != null && await lib.isPinned(RequestKind.album, a.id)) await lib.putAlbum(a);
      unawaited(app.downloads?.noteServerVersions(a.tracks));
      if (mounted) setState(() => _a = a);
    } catch (e) {
      if (!mounted) return;
      if (_a != null) {
        _snack(context, '새로 고치지 못했습니다');
      } else {
        setState(() => _error = e);
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _a;
    if (a == null && _error != null) return _loadError(context, widget.title, _error!, _load);
    if (a == null) return Scaffold(appBar: AppBar(title: Text(widget.title)), body: const SkeletonList());
    final app = context.watchApp();
    final ctx = QueueContext(ContextType.album, a.id, a.title);
    final available = [for (final t in a.tracks) if (t.state == TrackStateEnum.available) t];
    return _DetailScaffold(
      title: a.title,
      artworkId: a.artworkId,
      info: [a.albumArtist?.name, if (a.year != null) '${a.year}', '${a.trackCount}곡', formatMs(a.durationMs ?? 0)].whereType<String>().join(' · '),
      onPlay: () => playTracks(context, a.tracks, 0, ctx, shuffle: false),
      onShuffle: () => playTracks(context, a.tracks, 0, ctx, shuffle: true),
      refreshing: _refreshing,
      note: _offlineNote(context, a.tracks),
      // 세션 만료면 다운로드 버튼 비활성 (04장 S5)
      extra: [if (app.session != SessionStatus.expired) GroupDownloadButton(kind: RequestKind.album, refId: a.id, trackIds: [for (final t in available) t.id])],
      slivers: [
        SliverList.builder(
          itemCount: a.tracks.length,
          itemBuilder: (context, i) => _TrackTile(a.tracks[i], () => playTracks(context, a.tracks, i, ctx), number: a.tracks[i].trackNo ?? i + 1),
        ),
      ],
    );
  }
}

// ── S6 플레이리스트 ──────────────────────────────────────────────

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key, required this.playlist});
  final Playlist playlist;

  static Future<List<PlaylistItem>> _allItems(AppState app, String id) async {
    // 오프라인이거나 서버에 닿지 않으면 로컬 사본 (오프라인 편집 반영분 포함, 03장 §6.8)
    final lib = app.library;
    Future<List<PlaylistItem>?> local() async {
      if (lib == null || await lib.playlist(id) == null) return null;
      return _localItems(lib, id);
    }
    if (app.offline) return await local() ?? (throw ApiException(kind: ApiErrorKind.unreachable));
    try {
      return await _serverItems(app, id);
    } catch (e) {
      final l = await local();
      if (l != null && ApiException.from(e).status == null) return l;
      rethrow;
    }
  }

  static Future<List<PlaylistItem>> _localItems(LibraryStore lib, String id) async =>
      [for (final e in await lib.playlistTracks(id)) PlaylistItem.fromJson({'item_id': e.itemId, 'available': true, 'track': e.track.toJson()})];

  static Future<List<PlaylistItem>> _serverItems(AppState app, String id) async {
    final out = <PlaylistItem>[];
    String? c;
    do {
      final p = await app.api!.call((a) => a.getPlaylistsApi().listPlaylistItems(playlistId: id, cursor: c, limit: 200));
      out.addAll(p.items);
      c = p.nextCursor;
    } while (c != null);
    unawaited(app.downloads?.noteServerVersions([for (final i in out) if (i.track != null) i.track!]));
    return out;
  }

  static Future<void> playAll(BuildContext context, Playlist p) async {
    final items = await _allItems(context.readApp(), p.id);
    final tracks = [for (final i in items) if (i.available && i.track != null) i.track!];
    if (context.mounted && tracks.isNotEmpty) await playTracks(context, tracks, 0, QueueContext(ContextType.playlist, p.id, p.name));
  }

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late Playlist _p = widget.playlist;
  List<PlaylistItem>? _items;
  Object? _error;
  bool _refreshing = false;
  bool _started = false;
  bool _editing = false;

  /// 오프라인 편집이 서버 반영을 기다리는 중 (03장 §6.8)
  bool _pendingSync = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final app = context.readApp();
    final lib = app.library;
    setState(() => _error = null);
    if (lib != null) {
      final pending = (await lib.pendingOps()).any((o) => o.playlistId == _p.id);
      if (_items == null && await lib.playlist(_p.id) != null) {
        final local = await PlaylistScreen._localItems(lib, _p.id);
        if (mounted && _items == null) setState(() => _items = local);
      }
      if (mounted) setState(() => _pendingSync = pending);
    }
    if (app.offline) {
      if (_items == null && mounted) setState(() => _error = ApiException(kind: ApiErrorKind.unreachable));
      return;
    }
    if (mounted) setState(() => _refreshing = true);
    try {
      final p = await app.api!.call((x) => x.getPlaylistsApi().getPlaylist(playlistId: _p.id));
      final items = await PlaylistScreen._serverItems(app, _p.id);
      if (lib != null && await lib.playlist(p.id) != null) await lib.putPlaylist(p, items);
      if (!mounted) return;
      setState(() {
        _p = p;
        _items = items;
      });
    } catch (e) {
      if (!mounted) return;
      if (_items != null) {
        _snack(context, '새로 고치지 못했습니다');
      } else {
        setState(() => _error = e);
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// 편집 연산 적용 (add/remove/move). 온라인이면 서버(If-Match + Idempotency-Key), 아니면 로컬 반영 + 대기열 (03장 §6.8)
  Future<void> _apply(List<Map<String, Object?>> ops) async {
    final app = context.readApp();
    final lib = app.library;
    if (app.offline) {
      if (lib == null) return;
      await lib.addPendingOp(_p.id, ops, _uuid());
      await lib.applyLocalOps(_p.id, ops);
      final items = await PlaylistScreen._localItems(lib, _p.id);
      if (!mounted) return;
      setState(() {
        _items = items;
        _pendingSync = true;
      });
      return;
    }
    try {
      final p = await app.api!.editPlaylist(_p.id, _p.version, ops, idempotencyKey: _uuid());
      final items = await PlaylistScreen._serverItems(app, _p.id);
      if (lib != null && await lib.playlist(p.id) != null) await lib.putPlaylist(p, items);
      if (!mounted) return;
      setState(() {
        _p = p;
        _items = items;
      });
    } catch (e) {
      final ae = ApiException.from(e);
      if (!mounted) return;
      if (ae.status == 412) {
        await _conflict();
      } else {
        _snack(context, describeError(ae).$1);
        await _load(); // 화면을 서버 상태로 되돌린다
      }
    }
  }

  /// 편집 충돌 (04장 S6): "다른 기기에서 변경되었습니다" + 최신 내용 보기
  Future<void> _conflict() async {
    await showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('다른 기기에서 변경되었습니다'),
        content: const Text('이 플레이리스트가 그사이 다른 곳에서 바뀌었습니다. 최신 내용을 불러온 뒤 다시 편집하세요.'),
        actions: [FilledButton(onPressed: () => Navigator.pop(d), child: const Text('최신 내용 보기'))],
      ),
    );
    _items = null;
    await _load();
  }

  Future<void> _rename() async {
    final api = context.readApp().api!;
    final v = await showFormDialog(context, title: '이름·설명 수정', submitLabel: '저장', fields: [
      DialogField('이름', initial: _p.name, maxLength: 200),
      DialogField('설명', initial: _p.description ?? '', maxLength: 2000, maxLines: 3),
    ]);
    if (v == null || v[0].trim().isEmpty) return;
    final (n, ds) = (v[0].trim(), v[1].trim());
    try {
      final p = await api.call((x) => x.getPlaylistsApi().updatePlaylist(
            playlistId: _p.id, ifMatch: '"${_p.version}"', updatePlaylistRequest: UpdatePlaylistRequest(name: n, description: ds)));
      if (mounted) setState(() => _p = p);
    } catch (e) {
      if (!mounted) return;
      if (ApiException.from(e).status == 412) return _conflict();
      _snack(context, describeError(ApiException.from(e)).$1);
    }
  }

  /// 표지 변경: 시스템 사진 선택기 → 가운데 정사각 자르기 → 업로드 (저장소 전체 권한 없음, 04장 S6)
  Future<void> _changeCover() async {
    final api = context.readApp().api!;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    try {
      final png = await squareCropPng(await picked.readAsBytes());
      final p = await api.putPlaylistCover(_p.id, _p.version, png, 'image/png');
      if (mounted) setState(() => _p = p);
    } catch (e) {
      if (!mounted) return;
      final ae = ApiException.from(e);
      if (ae.status == 412) return _conflict();
      _snack(context, ae.status == 400 ? '이 사진은 표지로 쓸 수 없습니다' : describeError(ae).$1);
    }
  }

  Future<void> _removeCover() async {
    final api = context.readApp().api!;
    try {
      await api.call((x) => x.getPlaylistsApi().deletePlaylistCover(playlistId: _p.id));
      await _load();
    } catch (e) {
      if (mounted) _snack(context, describeError(ApiException.from(e)).$1);
    }
  }

  Future<void> _delete() async {
    final api = context.readApp().api!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('‘${_p.name}’을 삭제할까요?'),
        content: const Text('플레이리스트만 지워집니다. 곡은 라이브러리에 그대로 있습니다.'),
        actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('취소')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('삭제'))],
      ),
    );
    if (ok != true) return;
    try {
      await api.call((x) => x.getPlaylistsApi().deletePlaylist(playlistId: _p.id));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      if (ApiException.from(e).status == 412) return _conflict();
      _snack(context, describeError(ApiException.from(e)).$1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items == null && _error != null) return _loadError(context, _p.name, _error!, _load);
    final app = context.watchApp();
    final online = !app.offline;
    final expired = app.session == SessionStatus.expired;
    final tracks = [for (final i in items ?? const <PlaylistItem>[]) if (i.available && i.track != null) i.track!];
    final ctx = QueueContext(ContextType.playlist, _p.id, _p.name);
    final c = context.colors;
    return _DetailScaffold(
      title: _p.name,
      artworkId: playlistCover(_p),
      info: '${items?.length ?? _p.itemCount}곡 · ${formatMs(_p.durationMs)}',
      onPlay: tracks.isEmpty ? null : () => playTracks(context, tracks, 0, ctx, shuffle: false),
      onShuffle: tracks.isEmpty ? null : () => playTracks(context, tracks, 0, ctx, shuffle: true),
      refreshing: _refreshing,
      note: _pendingSync
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.sync, size: 16, color: c.warning),
              const SizedBox(width: Space.xs),
              Flexible(child: Text('편집이 서버 반영을 기다리는 중입니다', style: TextStyle(color: c.textMuted))),
            ])
          : _offlineNote(context, tracks),
      extra: [
        if (tracks.isNotEmpty && !expired) GroupDownloadButton(kind: RequestKind.playlist, refId: _p.id, trackIds: [for (final t in tracks) t.id]),
        if (!expired && items != null)
          OutlinedButton.icon(
            onPressed: () => setState(() => _editing = !_editing),
            icon: Icon(_editing ? Icons.check : Icons.edit),
            label: Text(_editing ? '완료' : '편집'),
          ),
      ],
      actions: [
        if (online && !expired)
          PopupMenuButton<String>(
            tooltip: '플레이리스트 메뉴',
            onSelected: (v) => switch (v) { 'rename' => _rename(), 'cover' => _changeCover(), 'uncover' => _removeCover(), _ => _delete() },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'rename', child: Text('이름·설명 수정')),
              const PopupMenuItem(value: 'cover', child: Text('표지 변경')),
              if (_p.artworkId != null) const PopupMenuItem(value: 'uncover', child: Text('표지 삭제')),
              const PopupMenuItem(value: 'delete', child: Text('플레이리스트 삭제')),
            ],
          ),
      ],
      slivers: [
        if (items == null) const SliverToBoxAdapter(child: SkeletonList()),
        if (items != null && items.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              title: '아직 곡이 없습니다',
              message: '곡의 더보기(점 세 개) 메뉴에서 “플레이리스트에 추가”를 고르세요.',
              actionLabel: '곡 찾기',
              action: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen())),
            ),
          ),
        if (items != null && _editing)
          // 편집: 끌어서 순서 변경(손잡이), 삭제. 서버 연산은 move/remove (02장 §4)
          SliverReorderableList(
            itemCount: items.length,
            onReorderItem: (from, at) {
              final moved = items[from];
              final rest = [...items]..removeAt(from);
              setState(() => _items = [...rest]..insert(at, moved));
              _apply([{'op': 'move', 'item_id': moved.itemId, 'after_item_id': at == 0 ? null : rest[at - 1].itemId}]);
            },
            itemBuilder: (context, i) {
              final it = items[i];
              final title = it.track?.title ?? '재생할 수 없는 곡';
              return Material(
                key: ValueKey(it.itemId),
                child: ListTile(
                  leading: ReorderableDragStartListener(index: i, child: Icon(Icons.drag_handle, semanticLabel: '$title 순서 바꾸기')),
                  title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: it.available ? null : TextStyle(color: c.textDisabled)),
                  subtitle: it.track == null ? null : Text(artistNames(it.track!)),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: '$title 빼기',
                    onPressed: () {
                      setState(() => _items = [...items]..removeAt(i));
                      _apply([{'op': 'remove', 'item_ids': [it.itemId]}]);
                    },
                  ),
                ),
              );
            },
          ),
        if (items != null && !_editing)
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final it = items[i];
              if (it.available && it.track != null) return _TrackTile(it.track!, () => playTracks(context, tracks, tracks.indexOf(it.track!), ctx));
              // 접근할 수 없는 곡: 흐리게, 삭제만 가능 (04장 S6)
              return ListTile(
                leading: const Icon(Icons.block),
                title: Text('재생할 수 없는 곡', style: TextStyle(color: c.textDisabled)),
                subtitle: const Text('편집에서 뺄 수 있습니다'),
              );
            },
          ),
      ],
    );
  }
}
