// 로컬 라이브러리 저장소 (03장 §5.2, §5.6). 프로필·사용자마다 하나 — 다른 프로필의 행·파일을 볼 수 없다(FN-21).
// 화면과 엔진은 drift 테이블을 직접 만지지 않고 이 클래스만 쓴다.
import 'dart:convert';
import 'dart:io';

import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/download_state.dart';
import '../domain/norm.dart';
import 'local_db.dart';

/// 요청자 종류 (03장 §5.4)
enum RequestKind { track, album, playlist }

class LibraryStore {
  LibraryStore(this.db, this.root);

  final LibraryDb db;

  /// `profiles/<server_id>/<user_id>/` — media/, tmp/, artwork/ 가 이 아래
  final Directory root;

  Directory get mediaDir => Directory('${root.path}/media');
  Directory get tmpDir => Directory('${root.path}/tmp');
  File mediaFile(String fileName) => File('${mediaDir.path}/$fileName');
  File partFile(String downloadId) => File('${tmpDir.path}/$downloadId.part');

  static Future<Directory> profileDir(String serverId, String userId) async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}/profiles/$serverId/$userId');
  }

  static Future<LibraryStore> open(String serverId, String userId) async => openIn(await profileDir(serverId, userId));

  /// 이 디렉터리의 library.sqlite와 파일들 (테스트는 임시 디렉터리로 같은 경로를 쓴다)
  static Future<LibraryStore> openIn(Directory dir) async {
    await Directory('${dir.path}/media').create(recursive: true);
    await Directory('${dir.path}/tmp').create(recursive: true);
    return LibraryStore(LibraryDb(NativeDatabase.createInBackground(File('${dir.path}/library.sqlite'))), dir);
  }

  /// 테스트용: 메모리 DB + 임시 디렉터리
  static Future<LibraryStore> openForTest(Directory dir) async {
    await Directory('${dir.path}/media').create(recursive: true);
    await Directory('${dir.path}/tmp').create(recursive: true);
    return LibraryStore(LibraryDb(NativeDatabase.memory()), dir);
  }

  Future<void> close() => db.close();

  // ── 서버 응답 사본 ───────────────────────────────────────────

  String _trackSearch(Track t) => norm([t.title, ...t.artists.map((a) => a.name), t.album?.title ?? ''].join(' '));

  Future<void> putTracks(Iterable<Track> tracks) => db.batch((b) {
        for (final t in tracks) {
          b.insert(db.localTracks, LocalTracksCompanion.insert(
            id: t.id, albumId: Value(t.album?.id), json: jsonEncode(t.toJson()), search: _trackSearch(t), updatedAt: t.updatedAt.millisecondsSinceEpoch,
          ), mode: InsertMode.insertOrReplace);
        }
      });

  Future<void> putAlbum(AlbumDetail a) async {
    final j = a.toJson()..remove('tracks');
    await db.into(db.localAlbums).insertOnConflictUpdate(LocalAlbumsCompanion.insert(
      id: a.id, json: jsonEncode(j), search: norm('${a.title} ${a.albumArtist?.name ?? ''}'),
    ));
    await putTracks(a.tracks);
  }

  Future<void> putArtists(Iterable<ArtistRef> artists) => db.batch((b) {
        for (final a in artists) {
          b.insert(db.localArtists, LocalArtistsCompanion.insert(id: a.id, json: jsonEncode(a.toJson()), search: norm(a.name)), mode: InsertMode.insertOrReplace);
        }
      });

  /// 플레이리스트와 항목 순서 (03장 §5.6). items는 서버 순서 그대로
  Future<void> putPlaylist(Playlist p, List<PlaylistItem> items) async {
    await db.transaction(() async {
      await db.into(db.localPlaylists).insertOnConflictUpdate(LocalPlaylistsCompanion.insert(id: p.id, json: jsonEncode(p.toJson()), version: p.version, search: norm(p.name)));
      await (db.delete(db.localPlaylistItems)..where((t) => t.playlistId.equals(p.id))).go();
      await db.batch((b) {
        for (final (i, it) in items.indexed) {
          if (it.track == null) continue;
          b.insert(db.localPlaylistItems, LocalPlaylistItemsCompanion.insert(playlistId: p.id, itemId: it.itemId, position: i, trackId: it.track!.id));
        }
      });
      await putTracks([for (final it in items) if (it.track != null) it.track!]);
    });
  }

  /// 오프라인 편집을 로컬 사본에 바로 반영한다 (03장 §6.8). 서버 연산 형식 그대로: add / remove / move.
  /// 새 항목 ID는 서버가 정하므로 임시로 local_ 접두어를 쓴다(동기화 후 서버 응답으로 교체).
  Future<void> applyLocalOps(String playlistId, List<Map<String, Object?>> ops, {Iterable<Track> tracks = const []}) async {
    await putTracks(tracks);
    await db.transaction(() async {
      final rows = await (db.select(db.localPlaylistItems)..where((t) => t.playlistId.equals(playlistId))..orderBy([(t) => OrderingTerm(expression: t.position)])).get();
      final items = [for (final r in rows) (itemId: r.itemId, trackId: r.trackId)];
      var seq = DateTime.now().microsecondsSinceEpoch;
      int indexAfter(Object? after) => after == null ? 0 : items.indexWhere((i) => i.itemId == after) + 1;
      for (final op in ops) {
        switch (op['op']) {
          case 'add':
            final ids = [for (final t in op['track_ids']! as List) t as String];
            final at = op.containsKey('after_item_id') ? indexAfter(op['after_item_id']) : items.length;
            items.insertAll(at.clamp(0, items.length), [for (final t in ids) (itemId: 'local_${seq++}', trackId: t)]);
          case 'remove':
            final gone = {for (final i in op['item_ids']! as List) i as String};
            items.removeWhere((i) => gone.contains(i.itemId));
          case 'move':
            final from = items.indexWhere((i) => i.itemId == op['item_id']);
            if (from < 0) break;
            final it = items.removeAt(from);
            items.insert(indexAfter(op['after_item_id']).clamp(0, items.length), it);
        }
      }
      await (db.delete(db.localPlaylistItems)..where((t) => t.playlistId.equals(playlistId))).go();
      await db.batch((b) {
        for (final (i, it) in items.indexed) {
          b.insert(db.localPlaylistItems, LocalPlaylistItemsCompanion.insert(playlistId: playlistId, itemId: it.itemId, position: i, trackId: it.trackId));
        }
      });
    });
  }

  Future<void> putLyrics(Lyrics l, String? etag) => db.into(db.localLyrics).insertOnConflictUpdate(
        LocalLyricsCompanion.insert(trackId: l.trackId, json: jsonEncode(l.toJson()), etag: Value(etag)));

  Track _track(LocalTrack r) => Track.fromJson(jsonDecode(r.json) as Map<String, dynamic>);

  Future<Track?> track(String id) async {
    final r = await (db.select(db.localTracks)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _track(r);
  }

  Future<Map<String, Track>> tracksByIds(Iterable<String> ids) async {
    final rows = await (db.select(db.localTracks)..where((t) => t.id.isIn(ids.toSet()))).get();
    return {for (final r in rows) r.id: _track(r)};
  }

  Future<({Lyrics lyrics, String? etag})?> lyrics(String trackId) async {
    final r = await (db.select(db.localLyrics)..where((t) => t.trackId.equals(trackId))).getSingleOrNull();
    return r == null ? null : (lyrics: Lyrics.fromJson(jsonDecode(r.json) as Map<String, dynamic>), etag: r.etag);
  }

  // ── 오프라인 탐색 (03장 §5.6): 받은 곡이 있는 것만 ────────────────

  /// 재생할 수 있는 완료본이 있는 곡 ID
  Future<Set<String>> playableTrackIds() async {
    final rows = await (db.select(db.downloads)..where((d) => d.state.equals(DlState.completed.wire) & d.locked.equals(false))).get();
    return {for (final r in rows) r.trackId};
  }

  /// 로컬 사본 전체 (받지 않은 곡 포함 — 받아 둔 플레이리스트·앨범의 나머지 곡). 오프라인에서 "다운로드한 항목만"을 끈 경우
  Future<List<Track>> allTracks() async {
    final rows = await db.select(db.localTracks).get();
    return rows.map(_track).toList()..sort((a, b) => norm(a.title).compareTo(norm(b.title)));
  }

  Future<List<Album>> allAlbums() async {
    final rows = await db.select(db.localAlbums).get();
    return [for (final r in rows) Album.fromJson(jsonDecode(r.json) as Map<String, dynamic>)]..sort((a, b) => norm(a.title).compareTo(norm(b.title)));
  }

  /// 받은 곡 전체 (제목순) — 오프라인 라이브러리
  Future<List<Track>> downloadedTracks() async {
    final list = (await tracksByIds(await playableTrackIds())).values.toList();
    return list..sort((a, b) => norm(a.title).compareTo(norm(b.title)));
  }

  int _trackOrder(Track a, Track b) {
    final d = (a.discNo ?? 0).compareTo(b.discNo ?? 0);
    if (d != 0) return d;
    final t = (a.trackNo ?? 0).compareTo(b.trackNo ?? 0);
    return t != 0 ? t : a.title.compareTo(b.title);
  }

  Future<List<Track>> albumTracks(String albumId) async {
    final rows = await (db.select(db.localTracks)..where((t) => t.albumId.equals(albumId))).get();
    return rows.map(_track).toList()..sort(_trackOrder);
  }

  Future<Album?> album(String id) async {
    final r = await (db.select(db.localAlbums)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : Album.fromJson(jsonDecode(r.json) as Map<String, dynamic>);
  }

  /// 받은 곡이 하나라도 있는 앨범
  Future<List<Album>> downloadedAlbums() async {
    final playable = await playableTrackIds();
    if (playable.isEmpty) return [];
    final albumIds = (await (db.select(db.localTracks)..where((t) => t.id.isIn(playable))).get()).map((r) => r.albumId).whereType<String>().toSet();
    final rows = await (db.select(db.localAlbums)..where((t) => t.id.isIn(albumIds))).get();
    return [for (final r in rows) Album.fromJson(jsonDecode(r.json) as Map<String, dynamic>)]..sort((a, b) => norm(a.title).compareTo(norm(b.title)));
  }

  Future<List<Playlist>> playlists() async {
    final rows = await db.select(db.localPlaylists).get();
    return [for (final r in rows) Playlist.fromJson(jsonDecode(r.json) as Map<String, dynamic>)]..sort((a, b) => norm(a.name).compareTo(norm(b.name)));
  }

  Future<Playlist?> playlist(String id) async {
    final r = await (db.select(db.localPlaylists)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : Playlist.fromJson(jsonDecode(r.json) as Map<String, dynamic>);
  }

  /// 플레이리스트 곡 (저장된 순서). 같은 곡이 여러 번 들어갈 수 있다
  Future<List<({String itemId, Track track})>> playlistTracks(String playlistId) async {
    final items = await (db.select(db.localPlaylistItems)..where((t) => t.playlistId.equals(playlistId))..orderBy([(t) => OrderingTerm(expression: t.position)])).get();
    final tracks = await tracksByIds(items.map((i) => i.trackId));
    return [for (final i in items) if (tracks[i.trackId] != null) (itemId: i.itemId, track: tracks[i.trackId]!)];
  }

  /// 로컬 검색: 서버와 같은 정규화, 부분 일치 (03장 §5.6). onlyPlayable이면 받은 곡만
  Future<List<Track>> searchTracks(String q, {bool onlyPlayable = true, int limit = 100}) async {
    final key = norm(q);
    if (key.isEmpty) return [];
    final playable = onlyPlayable ? await playableTrackIds() : null;
    final query = db.select(db.localTracks)..where((t) => t.search.contains(key));
    if (playable != null) query.where((t) => t.id.isIn(playable));
    query.limit(limit);
    return (await query.get()).map(_track).toList();
  }

  Future<List<Album>> searchAlbums(String q, {int limit = 50}) async {
    final key = norm(q);
    if (key.isEmpty) return [];
    final ids = (await downloadedAlbums()).map((a) => a.id).toSet();
    final rows = await (db.select(db.localAlbums)..where((t) => t.search.contains(key) & t.id.isIn(ids))..limit(limit)).get();
    return [for (final r in rows) Album.fromJson(jsonDecode(r.json) as Map<String, dynamic>)];
  }

  // ── 다운로드 ─────────────────────────────────────────────────

  static Download toDownload(DownloadRow r) => Download(
        id: r.id, trackId: r.trackId, quality: r.quality, state: DlState.parse(r.state), renditionId: r.renditionId,
        mediaVersion: r.mediaVersion, bytesTotal: r.bytesTotal, bytesDone: r.bytesDone, sha256: r.sha256, etag: r.etag, ext: r.ext,
        errorCode: r.errorCode, attempts: r.attempts, integrityRetried: r.integrityRetried,
        notBefore: r.notBefore == null ? null : DateTime.fromMillisecondsSinceEpoch(r.notBefore!, isUtc: true),
        stale: r.stale, locked: r.locked, verified: r.verified == null ? null : Verified.values.byName(r.verified!), fileName: r.fileName,
      );

  Future<List<Download>> downloads() async => (await (db.select(db.downloads)..orderBy([(d) => OrderingTerm(expression: d.createdAt)])).get()).map(toDownload).toList();

  Stream<List<Download>> watchDownloads() =>
      (db.select(db.downloads)..orderBy([(d) => OrderingTerm(expression: d.createdAt)])).watch().map((rows) => rows.map(toDownload).toList());

  Future<Download?> download(String id) async {
    final r = await (db.select(db.downloads)..where((d) => d.id.equals(id))).getSingleOrNull();
    return r == null ? null : toDownload(r);
  }

  /// 이 곡의 재생 가능한 완료본 (§5.5 재생 시 크기 재확인은 호출하는 쪽)
  Future<Download?> playableFor(String trackId) async {
    final rows = await (db.select(db.downloads)..where((d) => d.trackId.equals(trackId) & d.state.equals(DlState.completed.wire) & d.locked.equals(false))).get();
    if (rows.isEmpty) return null;
    // 새 버전 완료본이 있으면 그것 (stale이 아닌 쪽)
    rows.sort((a, b) => (a.stale ? 1 : 0).compareTo(b.stale ? 1 : 0));
    return toDownload(rows.first);
  }

  Future<void> saveDownload(Download d) async {
    final row = DownloadsCompanion(
        id: Value(d.id), trackId: Value(d.trackId), quality: Value(d.quality), state: Value(d.state.wire), renditionId: Value(d.renditionId),
        mediaVersion: Value(d.mediaVersion), bytesTotal: Value(d.bytesTotal), bytesDone: Value(d.bytesDone), sha256: Value(d.sha256),
        etag: Value(d.etag), ext: Value(d.ext), errorCode: Value(d.errorCode), attempts: Value(d.attempts), integrityRetried: Value(d.integrityRetried),
        notBefore: Value(d.notBefore?.millisecondsSinceEpoch), stale: Value(d.stale), locked: Value(d.locked), verified: Value(d.verified?.name),
        fileName: Value(d.fileName),
        completedAt: d.state == DlState.completed ? Value(DateTime.now().millisecondsSinceEpoch) : const Value.absent(),
      );
    final n = await (db.update(db.downloads)..where((r) => r.id.equals(d.id))).write(row);
    if (n == 0) await db.into(db.downloads).insert(row.copyWith(createdAt: Value(DateTime.now().millisecondsSinceEpoch)));
  }

  Future<void> deleteDownload(String id) => db.transaction(() async {
        await (db.delete(db.downloadRequests)..where((r) => r.downloadId.equals(id))).go();
        await (db.delete(db.downloads)..where((d) => d.id.equals(id))).go();
      });

  /// 다운로드 요청 (03장 §5.4 중복 방지): 같은 곡·음질의 행이 이미 있으면 요청자만 늘린다. 새로 만들었으면 created=true
  Future<({Download download, bool created})> request(String trackId, String quality, RequestKind kind, String refId, {required String Function() newId}) async {
    return db.transaction(() async {
      final existing = await (db.select(db.downloads)..where((d) => d.trackId.equals(trackId) & d.quality.equals(quality))).get();
      // 새 버전 받기 중이면 진행 중인 행에 붙인다
      existing.sort((a, b) => (a.state == DlState.completed.wire ? 1 : 0).compareTo(b.state == DlState.completed.wire ? 1 : 0));
      final hit = existing.isEmpty ? null : toDownload(existing.first);
      final d = hit ?? Download(id: newId(), trackId: trackId, quality: quality);
      if (hit == null) {
        await db.into(db.downloads).insert(DownloadsCompanion.insert(
          id: d.id, trackId: trackId, quality: quality, state: DlState.queued.wire, createdAt: DateTime.now().millisecondsSinceEpoch,
        ));
      }
      await db.into(db.downloadRequests).insert(DownloadRequestsCompanion.insert(downloadId: d.id, kind: kind.name, refId: refId), mode: InsertMode.insertOrIgnore);
      return (download: d, created: hit == null);
    });
  }

  /// 같은 곡의 새 버전 받기 (§5.4 2단계): 요청자를 그대로 물려받는 새 행
  Future<Download> requestNewVersion(Download old, {required String Function() newId}) => db.transaction(() async {
        final d = Download(id: newId(), trackId: old.trackId, quality: old.quality);
        await db.into(db.downloads).insert(DownloadsCompanion.insert(id: d.id, trackId: d.trackId, quality: d.quality, state: DlState.queued.wire, createdAt: DateTime.now().millisecondsSinceEpoch));
        final reqs = await (db.select(db.downloadRequests)..where((r) => r.downloadId.equals(old.id))).get();
        for (final r in reqs) {
          await db.into(db.downloadRequests).insert(DownloadRequestsCompanion.insert(downloadId: d.id, kind: r.kind, refId: r.refId), mode: InsertMode.insertOrIgnore);
        }
        return d;
      });

  /// 요청자 하나를 뗀다. 요청자가 하나도 남지 않은 다운로드를 돌려준다(호출한 쪽이 취소·삭제한다)
  Future<List<Download>> release(RequestKind kind, String refId) => db.transaction(() async {
        final mine = await (db.select(db.downloadRequests)..where((r) => r.kind.equals(kind.name) & r.refId.equals(refId))).get();
        await (db.delete(db.downloadRequests)..where((r) => r.kind.equals(kind.name) & r.refId.equals(refId))).go();
        final orphaned = <Download>[];
        for (final m in mine) {
          final left = await (db.select(db.downloadRequests)..where((r) => r.downloadId.equals(m.downloadId))).get();
          if (left.isEmpty) {
            final d = await download(m.downloadId);
            if (d != null) orphaned.add(d);
          }
        }
        return orphaned;
      });

  Future<List<({String kind, String refId})>> requestersOf(String downloadId) async =>
      [for (final r in await (db.select(db.downloadRequests)..where((r) => r.downloadId.equals(downloadId))).get()) (kind: r.kind, refId: r.refId)];

  Future<void> pinGroup(RequestKind kind, String refId, String quality) => db.into(db.downloadGroups).insertOnConflictUpdate(
        DownloadGroupsCompanion.insert(kind: kind.name, refId: refId, quality: quality, createdAt: DateTime.now().millisecondsSinceEpoch));

  Future<void> unpinGroup(RequestKind kind, String refId) => (db.delete(db.downloadGroups)..where((g) => g.kind.equals(kind.name) & g.refId.equals(refId))).go();

  Future<List<({RequestKind kind, String refId, String quality})>> groups() async =>
      [for (final g in await db.select(db.downloadGroups).get()) (kind: RequestKind.values.byName(g.kind), refId: g.refId, quality: g.quality)];

  Future<bool> isPinned(RequestKind kind, String refId) async =>
      (await (db.select(db.downloadGroups)..where((g) => g.kind.equals(kind.name) & g.refId.equals(refId))).getSingleOrNull()) != null;

  /// 완료본이 차지하는 바이트 (§5.7 저장 한도)
  Future<int> usedBytes() async {
    final rows = await (db.select(db.downloads)..where((d) => d.state.equals(DlState.completed.wire))).get();
    return rows.fold<int>(0, (s, r) => s + (r.bytesTotal ?? 0));
  }

  // ── 대기 중인 변경 (FN-22) ───────────────────────────────────

  Future<void> addPlayEvent(PlayEvent e) => db.into(db.pendingPlayEvents).insert(
        PendingPlayEventsCompanion.insert(eventId: e.eventId, json: jsonEncode(e.toJson()), createdAt: DateTime.now().millisecondsSinceEpoch),
        mode: InsertMode.insertOrIgnore);

  Future<List<PlayEvent>> pendingPlayEvents({int limit = 500}) async {
    final rows = await (db.select(db.pendingPlayEvents)..orderBy([(e) => OrderingTerm(expression: e.createdAt)])..limit(limit)).get();
    return [for (final r in rows) PlayEvent.fromJson(jsonDecode(r.json) as Map<String, dynamic>)];
  }

  Future<void> removePlayEvents(Iterable<String> ids) => (db.delete(db.pendingPlayEvents)..where((e) => e.eventId.isIn(ids.toSet()))).go();

  Future<void> addPendingOp(String playlistId, List<Map<String, Object?>> ops, String idempotencyKey) => db.into(db.pendingOps).insert(
        PendingOpsCompanion.insert(playlistId: playlistId, opsJson: jsonEncode(ops), idempotencyKey: idempotencyKey, createdAt: DateTime.now().millisecondsSinceEpoch));

  Future<List<({int seq, String playlistId, List<Map<String, Object?>> ops, String key})>> pendingOps() async {
    final rows = await (db.select(db.pendingOps)..orderBy([(o) => OrderingTerm(expression: o.seq)])).get();
    return [
      for (final r in rows)
        (seq: r.seq, playlistId: r.playlistId, ops: [for (final o in jsonDecode(r.opsJson) as List) (o as Map).cast<String, Object?>()], key: r.idempotencyKey)
    ];
  }

  Future<void> removeOp(int seq) => (db.delete(db.pendingOps)..where((o) => o.seq.equals(seq))).go();

  Future<String?> syncValue(String key) async => (await (db.select(db.syncState)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;
  Future<void> setSyncValue(String key, String value) => db.into(db.syncState).insertOnConflictUpdate(SyncStateCompanion.insert(key: key, value: value));
}
