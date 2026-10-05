// 탐색 화면: S2 홈, S3 라이브러리, S4 검색, S5 앨범, S6 플레이리스트, 아티스트.
import 'dart:async';
import 'dart:math';

import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/session.dart';
import '../../data/library_store.dart';
import '../../domain/download_state.dart';
import '../../domain/queue.dart';
import '../app_state.dart';
import '../glass.dart';
import '../scope.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';
import '../widgets/paged_list.dart';
import '../widgets/square_crop.dart';
import '../widgets/purchase_gate.dart';
import '../../core/entitlement.dart';
import 'download_screens.dart';
import 'settings_screen.dart';

part 'detail_screens.dart';

// ── 공통 동작 ────────────────────────────────────────────────────

/// 업로드 표지, 없으면 곡 표지 모자이크의 첫 장
String? playlistCover(Playlist p) => p.artworkId ?? ((p.mosaicArtworkIds?.isNotEmpty ?? false) ? p.mosaicArtworkIds!.first : null);

Future<void> playTracks(BuildContext context, List<Track> tracks, int start, QueueContext ctx, {bool? shuffle}) async {
  final app = context.readApp();
  var playable = tracks.where((t) => t.state != TrackStateEnum.missing).toList();
  // 오프라인: 스트리밍 전용 곡은 대기열에서 뺀다 (03장 §6.8)
  if (app.offline && app.library != null) {
    final local = await app.library!.playableTrackIds();
    playable = playable.where((t) => local.contains(t.id)).toList();
    if (playable.isEmpty && context.mounted) _snack(context, '오프라인에서는 받은 곡만 재생할 수 있습니다');
  }
  if (playable.isEmpty || !context.mounted) return;
  final s = playable.indexWhere((t) => t.id == tracks[start].id);
  await context.readApp().player.playTracks(playable, context: ctx, start: s < 0 ? 0 : s, shuffle: shuffle);
}

void showTrackActions(BuildContext context, Track t) {
  final app = context.readApp();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true, // 높이를 내용에 맞추되 화면을 넘으면 스크롤 (작은 화면·큰 글씨에서 넘침 — 위젯 테스트에서 발견)
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: Artwork(t.artworkId, size: 40, label: t.title), title: Text(t.title), subtitle: Text(artistNames(t))),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.queue_play_next), title: const Text('다음에 재생'), onTap: () {
          app.player.playNext([t]);
          Navigator.pop(sheet);
          _snack(context, '다음에 재생합니다');
        }),
        ListTile(leading: const Icon(Icons.playlist_add), title: const Text('대기열에 추가'), onTap: () {
          app.player.addToEnd([t]);
          Navigator.pop(sheet);
          _snack(context, '대기열 끝에 추가했습니다');
        }),
        ListTile(leading: const Icon(Icons.library_add), title: const Text('플레이리스트에 추가'), onTap: () {
          Navigator.pop(sheet);
          addToPlaylist(context, [t]);
        }),
        if (app.downloads case final engine?)
          ValueListenableBuilder<List<Download>>(
            valueListenable: engine.rows,
            builder: (_, rows, _) => rows.any((d) => d.trackId == t.id)
                ? ListTile(leading: const Icon(Icons.delete_outline), title: const Text('다운로드 삭제'), onTap: () {
                    Navigator.pop(sheet);
                    engine.removeTrack(t.id);
                  })
                : ListTile(leading: const Icon(Icons.download), title: const Text('다운로드'), enabled: !app.offline, onTap: () async {
                    Navigator.pop(sheet);
                    if (await ensureCan(context, Feature.download)) await engine.downloadTracks([t], RequestKind.track, t.id);
                  }),
          ),
        if (t.album != null)
          ListTile(leading: const Icon(Icons.album), title: const Text('앨범으로 이동'), onTap: () {
            Navigator.pop(sheet);
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AlbumScreen(albumId: t.album!.id, title: t.album!.title)));
          }),
        for (final a in t.artists)
          ListTile(leading: const Icon(Icons.person), title: Text('${a.name}(으)로 이동'), onTap: () {
            Navigator.pop(sheet);
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ArtistScreen(artistId: a.id, name: a.name)));
          }),
      ])),
    ),
  );
}

void _snack(BuildContext context, String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

/// 오프라인 편집: 로컬 사본에 바로 반영하고 대기열에 쌓는다. 연결되면 같은 Idempotency-Key로 보낸다 (03장 §6.8, FN-22)
Future<void> _addOffline(BuildContext context, AppState app, List<Track> tracks) async {
  final lib = app.library!;
  final local = await lib.playlists();
  if (!context.mounted) return;
  final chosen = await showModalBottomSheet<Playlist?>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: ListView(shrinkWrap: true, children: [
        const ListTile(leading: Icon(Icons.cloud_off), title: Text('오프라인'), subtitle: Text('받아 둔 플레이리스트에만 추가할 수 있습니다. 연결되면 서버에 반영합니다.')),
        for (final p in local) ListTile(leading: Artwork(playlistCover(p), size: 40, label: p.name), title: Text(p.name), onTap: () => Navigator.pop(sheet, p)),
      ]),
    ),
  );
  if (chosen == null) return;
  final ops = <Map<String, Object?>>[{'op': 'add', 'track_ids': [for (final t in tracks) t.id]}];
  await lib.addPendingOp(chosen.id, ops, _uuid());
  await lib.applyLocalOps(chosen.id, ops, tracks: tracks);
  if (context.mounted) _snack(context, '추가했습니다. 연결되면 서버에 반영합니다');
}

Future<void> addToPlaylist(BuildContext context, List<Track> tracks) async {
  final app = context.readApp();
  if (app.offline && app.library != null) return _addOffline(context, app, tracks);
  final api = app.api!;
  final PlaylistPage page;
  try {
    page = await api.call((a) => a.getPlaylistsApi().listPlaylists(limit: 200));
  } catch (e) {
    if (!context.mounted) return;
    if (app.offline && app.library != null) return _addOffline(context, app, tracks);
    _snack(context, describeError(ApiException.from(e)).$1);
    return;
  }
  if (!context.mounted) return;
  final chosen = await showModalBottomSheet<Playlist?>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: ListView(shrinkWrap: true, children: [
        ListTile(leading: const Icon(Icons.add), title: const Text('새 플레이리스트'), onTap: () => Navigator.pop(sheet)),
        for (final p in page.items) ListTile(leading: Artwork(playlistCover(p), size: 40, label: p.name), title: Text(p.name), subtitle: Text('${p.itemCount}곡'), onTap: () => Navigator.pop(sheet, p)),
      ]),
    ),
  );
  if (!context.mounted) return;
  try {
    if (chosen == null) {
      final name = await _askName(context);
      if (name == null) return;
      await api.call((a) => a.getPlaylistsApi().createPlaylist(
            createPlaylistRequest: CreatePlaylistRequest(name: name, trackIds: [for (final t in tracks) t.id]),
            idempotencyKey: _uuid(),
          ));
    } else {
      await api.editPlaylist(chosen.id, chosen.version, [{'op': 'add', 'track_ids': [for (final t in tracks) t.id]}], idempotencyKey: _uuid());
    }
    if (context.mounted) _snack(context, '플레이리스트에 추가했습니다');
  } catch (e) {
    if (context.mounted) _snack(context, describeError(ApiException.from(e)).$1);
  }
}

Future<String?> _askName(BuildContext context) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      title: const Text('새 플레이리스트'),
      content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: '이름')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('취소')),
        FilledButton(onPressed: () => Navigator.pop(d, c.text.trim().isEmpty ? null : c.text.trim()), child: const Text('만들기')),
      ],
    ),
  );
}

/// 이름을 묻고 빈 플레이리스트를 만든다 (라이브러리 + 버튼, 홈의 "첫 플레이리스트 만들기"). 만들었으면 true
Future<bool> createPlaylistFlow(BuildContext context, ApiClient api) async {
  final name = await _askName(context);
  if (name == null || !context.mounted) return false;
  try {
    await api.call((a) => a.getPlaylistsApi().createPlaylist(createPlaylistRequest: CreatePlaylistRequest(name: name, trackIds: const []), idempotencyKey: _uuid()));
    if (context.mounted) _snack(context, '‘$name’ 플레이리스트를 만들었습니다');
    return true;
  } catch (e) {
    if (context.mounted) _snack(context, describeError(ApiException.from(e)).$1);
    return false;
  }
}

String _uuid() {
  final n = DateTime.now().microsecondsSinceEpoch;
  final r = (n * 2654435761) & 0xffffffff;
  String h(int v, int len) => v.toRadixString(16).padLeft(len, '0').substring(0, len);
  return '${h(r, 8)}-${h(n & 0xffff, 4)}-4${h(n >> 16, 3)}-a${h(r >> 4, 3)}-${h(n, 12).padLeft(12, '0')}';
}

/// 트랙 하나 + 재생 중 표시
class _TrackTile extends StatelessWidget {
  const _TrackTile(this.t, this.onTap, {this.number});
  final Track t;
  final VoidCallback onTap;
  final int? number;

  @override
  Widget build(BuildContext context) {
    final app = context.watchApp();
    final player = app.player;
    final engine = app.downloads;
    Widget row(bool available, String? status) => ValueListenableBuilder<int>(
          valueListenable: player.queueChanged,
          builder: (_, _, _) => TrackRow(
            track: t, onTap: onTap, leadingNumber: number, playing: player.currentTrack?.id == t.id, available: available,
            badge: TrackDownloadMark(t.id), statusLabel: status, onMore: () => showTrackActions(context, t),
          ),
        );
    if (engine == null) return row(true, null);
    return ValueListenableBuilder<List<Download>>(
      valueListenable: engine.rows,
      builder: (_, rows, _) {
        final mine = rows.where((d) => d.trackId == t.id).toList();
        final playable = mine.any((d) => d.playable);
        final status = mine.isEmpty ? null : (playable ? '다운로드됨' : downloadStatusText(mine.first));
        // 오프라인: 받지 않은 곡은 흐리게, 재생 불가 (03장 §5.6)
        return row(!app.offline || playable, status);
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.child, {this.onMore, this.card = false});
  final String title;
  final Widget child;

  /// 곡 목록 같은 세로 목록은 얇은 유리 카드에 담는다 (04장 §3.4)
  final bool card;

  /// "모두 보기" (04장 S2·S4)
  final VoidCallback? onMore;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.xl, Space.sm, Space.sm),
          // 큰 글씨에서는 제목과 "모두 보기"가 두 줄로 나뉜다 (Wrap)
          child: Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, runSpacing: Space.xs, children: [
            Semantics(header: true, child: Text(title, style: context.text.titleLarge)),
            if (onMore != null) TextButton(onPressed: onMore, child: Text('$title 모두 보기')),
          ]),
        ),
        if (card)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            child: Glass(kind: GlassKind.thin, radius: Radii.xl, padding: const EdgeInsets.symmetric(vertical: Space.sm), child: child),
          )
        else
          child,
      ]);
}

/// 가로 카드 줄의 높이: 표지 + 제목 2줄 + 보조 1줄을 글자 배율에 맞춰 (고정 높이 금지, 04장 §5 큰 글씨)
double cardRowHeight(BuildContext context, double cover) {
  final scale = context.textScale;
  return cover + Space.sm + scale * (2 * 24 + 18) + Space.sm;
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.artworkId, required this.title, required this.subtitle, required this.onTap, this.width = 140, this.onPlay});
  final String? artworkId;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onPlay;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(width > 200 ? Radii.xl : Radii.lg),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8))],
                ),
                child: Artwork(artworkId, size: width, radius: width > 200 ? Radii.xl : Radii.lg, label: title),
              ),
              if (onPlay != null)
                Positioned(
                  right: Space.md, bottom: Space.md,
                  child: GlassIconButton(icon: const Icon(Icons.play_arrow_rounded), onPressed: onPlay, tooltip: '$title 재생', size: 52, iconSize: 30),
                ),
            ]),
            const SizedBox(height: Space.sm),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall?.copyWith(color: context.colors.textMuted)),
          ]),
        ),
      );
}

// ── S2 홈 ────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<Home>? _home;
  bool _wasOffline = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final offline = context.readApp().offline;
    // 처음 한 번, 그리고 오프라인에서 돌아왔을 때만 다시 받는다 (앱 상태가 바뀔 때마다 받지 않게)
    if (_home == null || (_wasOffline && !offline)) _home = _load();
    _wasOffline = offline;
  }

  // FutureBuilder가 듣기 전에 실패해도 '처리 안 된 오류'로 올라가지 않게 ignore() (오류는 FutureBuilder가 그대로 받는다)
  Future<Home> _load() => context.readApp().api!.call((a) => a.getCatalogApi().getHome(limit: 12))..ignore();

  String _greeting(AppState app) {
    final h = DateTime.now().hour;
    final when = h < 6 ? '편안한 밤이에요' : h < 12 ? '좋은 아침이에요' : h < 18 ? '좋은 오후예요' : '좋은 저녁이에요';
    final name = app.profile?.displayName ?? app.profile?.username ?? '';
    return name.isEmpty ? when : '$when, $name';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watchApp();
    final w = MediaQuery.sizeOf(context).width;
    final big = context.textScale >= 1.3;
    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(_greeting(app)),
        actions: [IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())), icon: const Icon(Icons.account_circle_outlined), tooltip: '설정')],
      ),
      body: app.offline ? const _OfflineHome() : FutureBuilder<Home>(
        future: _home,
        builder: (context, s) {
          if (s.hasError) return ErrorState(error: s.error!, onRetry: () => setState(() { _home = _load(); }));
          if (!s.hasData) return const SkeletonList();
          final h = s.data!;
          final empty = h.playlists.isEmpty && h.recentTracks.isEmpty && h.topTracks.isEmpty && h.recentlyAddedAlbums.isEmpty;
          return RefreshIndicator(
            onRefresh: () async {
              final f = _load();
              setState(() { _home = f; });
              await f;
            },
            child: ListView(children: [
              if (empty) const EmptyState(title: '서버에 음악이 없습니다', message: '서버에 라이브러리를 등록하고 스캔하세요.'),
              // 플레이리스트가 없으면 주인공 자리에 만들기 카드 (04장 S2 빈 목록)
              if (!empty && h.playlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(Space.lg),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(Space.lg),
                      leading: Icon(Icons.playlist_add_rounded, size: 32, color: context.colors.accent),
                      title: const Text('첫 플레이리스트 만들기'),
                      subtitle: const Text('좋아하는 곡을 모아 두고 한 번에 받아 두세요.'),
                      onTap: () async {
                        if (await createPlaylistFlow(context, context.readApp().api!) && mounted) setState(() { _home = _load(); });
                      },
                    ),
                  ),
                ),
              if (h.playlists.isNotEmpty)
                SizedBox(
                  height: cardRowHeight(context, w * (big ? 0.88 : 0.72) - Space.lg) + Space.xl,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(Space.lg),
                    itemCount: h.playlists.length,
                    separatorBuilder: (_, _) => const SizedBox(width: Space.md),
                    itemBuilder: (_, i) {
                      final p = h.playlists[i];
                      return _CoverCard(
                        width: w * (big ? 0.88 : 0.72) - Space.lg,
                        artworkId: playlistCover(p),
                        title: p.name,
                        subtitle: '${p.itemCount}곡',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlaylistScreen(playlist: p))),
                        onPlay: () => PlaylistScreen.playAll(context, p),
                      );
                    },
                  ),
                ),
              if (h.recentTracks.isNotEmpty)
                _Section('최근 들은 곡', SizedBox(
                  height: cardRowHeight(context, 140),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                    itemCount: h.recentTracks.length,
                    separatorBuilder: (_, _) => const SizedBox(width: Space.md),
                    itemBuilder: (_, i) {
                      final t = h.recentTracks[i];
                      return _CoverCard(artworkId: t.artworkId, title: t.title, subtitle: artistNames(t), onTap: () => playTracks(context, h.recentTracks, i, const QueueContext(ContextType.adhoc, null, '최근 들은 곡')));
                    },
                  ),
                )),
              if (h.topTracks.isNotEmpty)
                _Section('많이 들은 곡', card: true, Column(children: [
                  for (var i = 0; i < h.topTracks.length && i < 5; i++)
                    _TrackTile(h.topTracks[i], () => playTracks(context, h.topTracks, i, const QueueContext(ContextType.adhoc, null, '많이 들은 곡')), number: i + 1),
                ])),
              if (h.recentlyAddedAlbums.isNotEmpty)
                _Section('최근 추가한 앨범', SizedBox(
                  height: cardRowHeight(context, 140),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                    itemCount: h.recentlyAddedAlbums.length,
                    separatorBuilder: (_, _) => const SizedBox(width: Space.md),
                    itemBuilder: (_, i) {
                      final a = h.recentlyAddedAlbums[i];
                      return _CoverCard(artworkId: a.artworkId, title: a.title, subtitle: a.albumArtist?.name ?? '', onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AlbumScreen(albumId: a.id, title: a.title))));
                    },
                  ),
                )),
              const SizedBox(height: Space.xxl),
            ]),
          );
        },
      ),
    );
  }
}

/// 오프라인 홈 (03장 §5.6, §6.8): 받아 둔 플레이리스트·앨범·곡을 로컬 DB에서 바로 그린다
class _OfflineHome extends StatelessWidget {
  const _OfflineHome();

  @override
  Widget build(BuildContext context) {
    final app = context.watchApp();
    final lib = app.library!;
    return ValueListenableBuilder<List<Download>>(
      valueListenable: app.downloads!.rows,
      builder: (context, _, _) => FutureBuilder(
        future: Future.wait([lib.playlists(), lib.downloadedAlbums(), lib.downloadedTracks()]),
        builder: (context, s) {
          if (!s.hasData) return const SizedBox.shrink();
          final playlists = s.data![0] as List<Playlist>;
          final albums = s.data![1] as List<Album>;
          final tracks = s.data![2] as List<Track>;
          if (tracks.isEmpty) {
            return const EmptyState(title: '받아 둔 음악이 없습니다', message: '연결되어 있을 때 앨범이나 플레이리스트에서 다운로드 버튼을 누르면 오프라인에서도 들을 수 있습니다.', icon: Icons.cloud_off);
          }
          return ListView(children: [
            if (playlists.isNotEmpty)
              _Section('플레이리스트', card: true, Column(children: [
                for (final p in playlists)
                  ListTile(leading: Artwork(playlistCover(p), size: 48, label: p.name), title: Text(p.name),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlaylistScreen(playlist: p)))),
              ])),
            if (albums.isNotEmpty)
              _Section('받은 앨범', SizedBox(
                height: cardRowHeight(context, 140),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                  itemCount: albums.length,
                  separatorBuilder: (_, _) => const SizedBox(width: Space.md),
                  itemBuilder: (_, i) {
                    final a = albums[i];
                    return _CoverCard(artworkId: a.artworkId, title: a.title, subtitle: a.albumArtist?.name ?? '',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AlbumScreen(albumId: a.id, title: a.title))));
                  },
                ),
              )),
            _Section('받은 곡 ${tracks.length}', card: true, Column(children: [
              for (var i = 0; i < tracks.length; i++) _TrackTile(tracks[i], () => playTracks(context, tracks, i, const QueueContext(ContextType.library, null, '받은 곡'))),
            ])),
            const SizedBox(height: Space.xxl),
          ]);
        },
      ),
    );
  }
}

// ── S3 라이브러리 ────────────────────────────────────────────────

enum _Kind { playlists, albums, artists, tracks }

/// 격자 칸의 표지 카드 (폭은 칸에 맞춘다, 04장 §4 CoverCard M)
class _GridCard extends StatelessWidget {
  const _GridCard({required this.artworkId, required this.title, required this.subtitle, required this.onTap});
  final String? artworkId;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) => InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              DecoratedBox(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(Radii.lg), boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 14, offset: Offset(0, 6))]),
                child: Artwork(artworkId, size: box.maxWidth, radius: Radii.lg, label: title),
              ),
              const SizedBox(height: Space.sm),
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodySmall?.copyWith(color: context.colors.textMuted)),
            ]),
          ),
      );
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  _Kind _kind = _Kind.albums;
  String _trackSort = 'title';

  /// "다운로드한 항목만" (04장 S3). null이면 자동: 오프라인이면 켜짐(해제 가능)
  bool? _downloadedOnly;
  int _created = 0;

  /// 오프라인 아티스트: 받은 곡에 나오는 아티스트 (곡 수 포함)
  static Future<List<Artist>> _offlineArtists(LibraryStore lib, {required bool onlyPlayable}) async {
    final counts = <String, (ArtistRef, int)>{};
    for (final t in onlyPlayable ? await lib.downloadedTracks() : await lib.allTracks()) {
      for (final a in t.artists) {
        final c = counts[a.id];
        counts[a.id] = (a, (c?.$2 ?? 0) + 1);
      }
    }
    return [for (final (a, n) in counts.values) Artist.fromJson({'id': a.id, 'name': a.name, 'track_count': n})]..sort((x, y) => x.name.compareTo(y.name));
  }

  Future<void> _newPlaylist(ApiClient api) async {
    if (await createPlaylistFlow(context, api) && mounted) setState(() => _created++); // 목록을 새로 받는다
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watchApp();
    final api = app.api!;
    final lib = app.library;
    final offline = app.offline && lib != null;
    // 받은 것만 보기: 오프라인이면 기본 켜짐. 다운로드 기능이 없으면(시험 환경 등) 쓸 수 없다
    final onlyDownloaded = lib != null && (_downloadedOnly ?? offline);
    final local = offline || onlyDownloaded; // 로컬 사본에서 그린다
    final grid = context.textScale < 1.3; // 큰 글씨면 격자 → 1열 목록 (04장 §5)
    final mode = '$offline-$onlyDownloaded-$grid';
    const labels = {_Kind.playlists: '플레이리스트', _Kind.albums: '앨범', _Kind.artists: '아티스트', _Kind.tracks: '곡'};
    final filteredEmpty = EmptyState(
      title: '다운로드한 항목이 없습니다',
      message: offline ? '연결되어 있을 때 앨범이나 플레이리스트에서 다운로드 버튼을 누르세요.' : '필터를 끄면 서버의 전체 목록을 봅니다.',
      icon: Icons.download_outlined,
      actionLabel: '필터 끄기',
      action: () => setState(() => _downloadedOnly = false),
    );
    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text('라이브러리'),
        actions: [
          if (_kind == _Kind.tracks && !local)
            PopupMenuButton<String>(
              tooltip: '정렬',
              icon: const Icon(Icons.sort),
              onSelected: (v) => setState(() => _trackSort = v),
              itemBuilder: (_) => const [PopupMenuItem(value: 'title', child: Text('제목순')), PopupMenuItem(value: 'added_at_desc', child: Text('최근 추가순')), PopupMenuItem(value: 'album', child: Text('앨범순'))],
            ),
        ],
      ),
      floatingActionButton: _kind == _Kind.playlists && !offline
          ? FloatingActionButton(onPressed: () => _newPlaylist(api), tooltip: '새 플레이리스트', child: const Icon(Icons.add))
          : null,
      body: Column(children: [
        // 칩 줄은 가로 스크롤 (큰 글씨에서도 줄바꿈하지 않는다, 04장 S3)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          child: Row(children: [
            for (final k in _Kind.values)
              Padding(padding: const EdgeInsets.only(right: Space.sm), child: ChoiceChip(label: Text(labels[k]!), selected: _kind == k, onSelected: (_) => setState(() => _kind = k))),
            if (lib != null)
              FilterChip(
                avatar: const Icon(Icons.download_done, size: 18),
                label: const Text('다운로드한 항목만'),
                selected: onlyDownloaded,
                onSelected: (v) => setState(() => _downloadedOnly = v),
              ),
          ]),
        ),
        Expanded(
          child: switch (_kind) {
            _Kind.tracks => PagedList<Track>(
                key: ValueKey('tracks-$_trackSort-$mode'),
                load: (c) async {
                  if (local) return (onlyDownloaded ? await lib.downloadedTracks() : await lib.allTracks(), null);
                  final p = await api.call((a) => a.getCatalogApi().listTracks(cursor: c, sort: _trackSort));
                  return (p.items, p.nextCursor);
                },
                empty: onlyDownloaded ? filteredEmpty : const EmptyState(title: '곡이 없습니다'),
                itemBuilder: (context, t, i, all) => _TrackTile(t, () => playTracks(context, all, i, const QueueContext(ContextType.library, null, '라이브러리'))),
              ),
            _Kind.albums => PagedList<Album>(
                key: ValueKey('albums-$mode'),
                columns: grid ? 2 : 1,
                load: (c) async {
                  if (local) return (onlyDownloaded ? await lib.downloadedAlbums() : await lib.allAlbums(), null);
                  final p = await api.call((a) => a.getCatalogApi().listAlbums(cursor: c));
                  return (p.items, p.nextCursor);
                },
                empty: onlyDownloaded ? filteredEmpty : const EmptyState(title: '앨범이 없습니다'),
                itemBuilder: (context, al, _, _) {
                  void open() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AlbumScreen(albumId: al.id, title: al.title)));
                  final sub = [al.albumArtist?.name, if (al.year != null) '${al.year}', '${al.trackCount}곡'].whereType<String>().join(' · ');
                  if (grid) return _GridCard(artworkId: al.artworkId, title: al.title, subtitle: sub, onTap: open);
                  return ListTile(leading: Artwork(al.artworkId, size: 56, label: al.title), title: Text(al.title, maxLines: 2, overflow: TextOverflow.ellipsis), subtitle: Text(sub), onTap: open);
                },
              ),
            _Kind.artists => PagedList<Artist>(
                key: ValueKey('artists-$mode'),
                load: (c) async {
                  if (local) return (await _offlineArtists(lib, onlyPlayable: onlyDownloaded), null);
                  final p = await api.call((a) => a.getCatalogApi().listArtists(cursor: c));
                  return (p.items, p.nextCursor);
                },
                empty: onlyDownloaded ? filteredEmpty : const EmptyState(title: '아티스트가 없습니다'),
                itemBuilder: (context, ar, _, _) => ListTile(
                  leading: CircleAvatar(child: Text(ar.name.characters.first)),
                  title: Text(ar.name),
                  subtitle: Text(local ? '${onlyDownloaded ? '받은 곡' : '곡'} ${ar.trackCount ?? 0}' : '앨범 ${ar.albumCount ?? 0} · 곡 ${ar.trackCount ?? 0}'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ArtistScreen(artistId: ar.id, name: ar.name))),
                ),
              ),
            _Kind.playlists => PagedList<Playlist>(
                key: ValueKey('playlists-$mode-$_created'),
                columns: grid ? 2 : 1,
                load: (c) async {
                  if (local) return (await lib.playlists(), null); // 받아 둔(고정한) 플레이리스트
                  final p = await api.call((a) => a.getPlaylistsApi().listPlaylists(cursor: c));
                  return (p.items, p.nextCursor);
                },
                empty: onlyDownloaded
                    ? filteredEmpty
                    : const EmptyState(title: '플레이리스트가 없습니다', message: '+ 버튼으로 만들거나, 곡의 더보기(점 세 개) 메뉴에서 추가하세요.'),
                itemBuilder: (context, p, _, _) {
                  void open() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlaylistScreen(playlist: p)));
                  if (grid) return _GridCard(artworkId: playlistCover(p), title: p.name, subtitle: '${p.itemCount}곡', onTap: open);
                  return ListTile(leading: Artwork(playlistCover(p), size: 56, label: p.name), title: Text(p.name), subtitle: Text('${p.itemCount}곡'), onTap: open);
                },
              ),
          },
        ),
      ]),
    );
  }
}

// ── S4 검색 ──────────────────────────────────────────────────────

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  /// 검색 탭을 다시 눌렀을 때 검색창에 초점 (04장 §2)
  static void requestFocus() => _SearchScreenState.focusRequests.value++;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _q = TextEditingController();
  Timer? _debounce;
  CancelToken? _cancel;
  SearchResult? _result;
  Object? _error;
  bool _loading = false;
  final _focus = FocusNode();

  /// 최근 검색어 (기기 로컬, 04장 S4). 최신이 앞, 최대 20개
  List<String> _recent = const [];
  static const _recentKey = 'search.recent';

  /// 셸이 검색 탭을 다시 눌렀을 때 검색창에 초점을 준다 (04장 §2)
  static final focusRequests = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    focusRequests.addListener(_focusRequested);
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _recent = p.getStringList(_recentKey) ?? const []);
    });
  }

  void _focusRequested() => _focus.requestFocus();

  Future<void> _remember(String q) async {
    if (q.isEmpty) return;
    final next = [q, ..._recent.where((x) => x != q)].take(20).toList();
    setState(() => _recent = next);
    await (await SharedPreferences.getInstance()).setStringList(_recentKey, next);
  }

  Future<void> _forget(String? q) async {
    final next = q == null ? <String>[] : _recent.where((x) => x != q).toList();
    setState(() => _recent = next);
    await (await SharedPreferences.getInstance()).setStringList(_recentKey, next);
  }

  @override
  void dispose() {
    focusRequests.removeListener(_focusRequested);
    _debounce?.cancel();
    _cancel?.cancel();
    _q.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed(String _) {
    // 입력기 조합 중에는 요청하지 않는다 (04장 S4)
    if (_q.value.composing.isValid && !_q.value.composing.isCollapsed) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _search); // 02장 §3: 300ms 디바운스, 이전 요청 취소
  }

  Future<void> _search() async {
    final q = _q.text.trim();
    _cancel?.cancel();
    if (q.isEmpty) {
      setState(() => _result = null);
      return;
    }
    final token = _cancel = CancelToken();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final app = context.readApp();
      // 오프라인: 받은 곡·앨범을 서버와 같은 정규화로 찾는다 (03장 §5.6)
      if (app.offline && app.library != null) {
        final lib = app.library!;
        final tracks = await lib.searchTracks(q, limit: 50);
        final albums = await lib.searchAlbums(q);
        final r = SearchResult.fromJson({
          'query_normalized': q,
          'tracks': {'items': [for (final t in tracks) t.toJson()], 'next_cursor': null},
          'albums': {'items': [for (final a in albums) a.toJson()], 'next_cursor': null},
        });
        if (mounted && !token.isCancelled) setState(() => _result = r);
        return;
      }
      final r = await app.api!.call((a) => a.getCatalogApi().search(q: q, limit: 10, cancelToken: token));
      if (mounted && !token.isCancelled) setState(() => _result = r);
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      if (mounted && !token.isCancelled) setState(() => _error = e);
    } finally {
      if (mounted && !token.isCancelled) setState(() => _loading = false);
    }
  }

  void _openAll(String type, String title) {
    final q = _q.text.trim();
    _remember(q);
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SearchAllScreen(query: q, type: type, title: title)));
  }

  /// 결과를 누르면 그 검색어를 최근 검색어에 남긴다
  VoidCallback _then(VoidCallback f) => () {
        _remember(_q.text.trim());
        f();
      };

  @override
  Widget build(BuildContext context) {
    final r = _result;
    final offline = context.watchApp().offline;
    final nothing = r != null && (r.tracks?.items.isEmpty ?? true) && (r.albums?.items.isEmpty ?? true) && (r.artists?.items.isEmpty ?? true) && (r.playlists?.items.isEmpty ?? true);
    final Widget idle = _recent.isEmpty
        ? const EmptyState(title: '검색', message: '가나·전각/반각 차이는 서버가 맞춰 줍니다.', icon: Icons.search)
        : ListView(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.sm, 0),
              child: Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Semantics(header: true, child: Text('최근 검색어', style: context.text.titleMedium)),
                TextButton(onPressed: () => _forget(null), child: const Text('전체 삭제')),
              ]),
            ),
            for (final q in _recent)
              ListTile(
                leading: const Icon(Icons.history),
                title: Text(q),
                onTap: () {
                  _q.text = q;
                  _search();
                },
                trailing: IconButton(onPressed: () => _forget(q), icon: const Icon(Icons.close), tooltip: '‘$q’ 지우기'),
              ),
          ]);
    return GlassScaffold(
      appBar: GlassAppBar(
        title: TextField(
          controller: _q,
          focusNode: _focus,
          onChanged: _changed,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) {
            _search();
            _remember(_q.text.trim());
          },
          decoration: InputDecoration(
            hintText: '곡, 앨범, 아티스트, 플레이리스트',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _q.text.isEmpty ? null : IconButton(onPressed: () { _q.clear(); _search(); }, icon: const Icon(Icons.clear), tooltip: '지우기'),
          ),
        ),
      ),
      body: Column(children: [
        // 오프라인: 로컬 검색으로 전환했다는 표시 (04장 S4)
        if (offline)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 0),
            child: Row(children: [
              Icon(Icons.download_done, size: 18, color: context.colors.textMuted),
              const SizedBox(width: Space.sm),
              Expanded(child: Text('다운로드한 음악에서 검색 중', style: TextStyle(color: context.colors.textMuted))),
            ]),
          ),
        Expanded(child: Opacity(
        opacity: _loading ? 0.5 : 1, // 이전 결과는 흐리게 유지
        child: _error != null
            ? ErrorState(error: _error!, onRetry: _search)
            : r == null
                ? idle
                : nothing
                    ? EmptyState(title: '‘${_q.text}’에 대한 결과가 없습니다', message: '철자를 확인하세요.', icon: Icons.search_off)
                    : ListView(children: [
                        if (r.tracks?.items.isNotEmpty ?? false)
                          _Section('곡', Column(children: [
                            for (var i = 0; i < r.tracks!.items.length && i < 5; i++)
                              _TrackTile(r.tracks!.items[i], _then(() => playTracks(context, r.tracks!.items, i, QueueContext(ContextType.search, null, '‘${_q.text}’ 검색')))),
                          ]), onMore: offline || r.tracks!.items.length < 5 ? null : () => _openAll('track', '곡')),
                        if (r.albums?.items.isNotEmpty ?? false)
                          _Section('앨범', Column(children: [
                            for (final al in r.albums!.items)
                              ListTile(leading: Artwork(al.artworkId, size: 48, label: al.title), title: Text(al.title), subtitle: Text(al.albumArtist?.name ?? ''),
                                  onTap: _then(() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AlbumScreen(albumId: al.id, title: al.title))))),
                          ]), onMore: offline ? null : () => _openAll('album', '앨범')),
                        if (r.artists?.items.isNotEmpty ?? false)
                          _Section('아티스트', Column(children: [
                            for (final ar in r.artists!.items)
                              ListTile(leading: CircleAvatar(child: Text(ar.name.characters.first)), title: Text(ar.name),
                                  onTap: _then(() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ArtistScreen(artistId: ar.id, name: ar.name))))),
                          ]), onMore: offline ? null : () => _openAll('artist', '아티스트')),
                        if (r.playlists?.items.isNotEmpty ?? false)
                          _Section('플레이리스트', card: true, Column(children: [
                            for (final p in r.playlists!.items)
                              ListTile(leading: Artwork(playlistCover(p), size: 48, label: p.name), title: Text(p.name), subtitle: Text('${p.itemCount}곡'),
                                  onTap: _then(() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlaylistScreen(playlist: p))))),
                          ]), onMore: offline ? null : () => _openAll('playlist', '플레이리스트')),
                      ]),
        )),
      ]),
    );
  }
}

/// 검색 "모두 보기" (04장 S4): 한 유형만, 커서 페이지
class SearchAllScreen extends StatelessWidget {
  const SearchAllScreen({super.key, required this.query, required this.type, required this.title});
  final String query;
  final String type;
  final String title;

  @override
  Widget build(BuildContext context) {
    final api = context.readApp().api!;
    Future<SearchResult> page(String? c) => api.call((a) => a.getCatalogApi().search(q: query, types: type, cursor: c, limit: 50));
    final ctx = QueueContext(ContextType.search, null, '‘$query’ 검색');
    return GlassScaffold(
      appBar: GlassAppBar(title: Text('‘$query’ · $title')),
      body: switch (type) {
        'track' => PagedList<Track>(
            load: (c) async => switch (await page(c)) { final r => (r.tracks?.items ?? <Track>[], r.tracks?.nextCursor) },
            empty: const EmptyState(title: '결과가 없습니다', icon: Icons.search_off),
            itemBuilder: (context, t, i, all) => _TrackTile(t, () => playTracks(context, all, i, ctx)),
          ),
        'album' => PagedList<Album>(
            load: (c) async => switch (await page(c)) { final r => (r.albums?.items ?? <Album>[], r.albums?.nextCursor) },
            empty: const EmptyState(title: '결과가 없습니다', icon: Icons.search_off),
            itemBuilder: (context, al, _, _) => ListTile(leading: Artwork(al.artworkId, size: 48, label: al.title), title: Text(al.title), subtitle: Text(al.albumArtist?.name ?? ''),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AlbumScreen(albumId: al.id, title: al.title)))),
          ),
        'artist' => PagedList<Artist>(
            load: (c) async => switch (await page(c)) { final r => (r.artists?.items ?? <Artist>[], r.artists?.nextCursor) },
            empty: const EmptyState(title: '결과가 없습니다', icon: Icons.search_off),
            itemBuilder: (context, ar, _, _) => ListTile(leading: CircleAvatar(child: Text(ar.name.characters.first)), title: Text(ar.name),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ArtistScreen(artistId: ar.id, name: ar.name)))),
          ),
        _ => PagedList<Playlist>(
            load: (c) async => switch (await page(c)) { final r => (r.playlists?.items ?? <Playlist>[], r.playlists?.nextCursor) },
            empty: const EmptyState(title: '결과가 없습니다', icon: Icons.search_off),
            itemBuilder: (context, p, _, _) => ListTile(leading: Artwork(playlistCover(p), size: 48, label: p.name), title: Text(p.name), subtitle: Text('${p.itemCount}곡'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlaylistScreen(playlist: p)))),
          ),
      },
    );
  }
}

// ── 아티스트 ────────────────────────────────────────────────────

class ArtistScreen extends StatelessWidget {
  const ArtistScreen({super.key, required this.artistId, required this.name});
  final String artistId;
  final String name;

  @override
  Widget build(BuildContext context) {
    final app = context.watchApp();
    final api = app.api!;
    final off = app.offline && app.library != null;
    return GlassScaffold(
      appBar: GlassAppBar(title: Text(name)),
      body: PagedList<Album>(
        key: ValueKey('artist-$off'),
        load: (c) async {
          // 오프라인: 받은 앨범 중 이 아티스트의 것 (곡 단위 참여는 받은 곡 목록에서)
          if (off) return ([for (final a in await app.library!.downloadedAlbums()) if (a.albumArtist?.id == artistId) a], null);
          final p = await api.call((a) => a.getCatalogApi().listAlbums(cursor: c, artistId: artistId, sort: 'year_desc'));
          return (p.items, p.nextCursor);
        },
        empty: const EmptyState(title: '앨범이 없습니다'),
        itemBuilder: (context, al, _, _) => ListTile(
          leading: Artwork(al.artworkId, size: 56, label: al.title),
          title: Text(al.title),
          subtitle: Text([if (al.year != null) '${al.year}', '${al.trackCount}곡'].join(' · ')),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AlbumScreen(albumId: al.id, title: al.title))),
        ),
      ),
    );
  }
}
