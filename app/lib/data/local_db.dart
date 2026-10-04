// 프로필·사용자별 로컬 DB (03장 §5.2 library.sqlite). 서버 응답의 사본, 다운로드, 대기 중인 변경.
// 위치: <앱 전용 저장소>/profiles/<server_id>/<user_id>/library.sqlite — 서버 ID를 그대로 키로 쓴다(프로필별 DB라 충돌 없음).
import 'package:drift/drift.dart';

part 'local_db.g.dart';

/// 곡 사본. json은 서버 Track 그대로, search는 norm(제목 + 아티스트 + 앨범) (03장 §5.6 로컬 검색)
class LocalTracks extends Table {
  @override
  String get tableName => 'tracks';
  TextColumn get id => text()();
  TextColumn get albumId => text().nullable()();
  TextColumn get json => text()();
  TextColumn get search => text()();
  IntColumn get updatedAt => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

class LocalAlbums extends Table {
  @override
  String get tableName => 'albums';
  TextColumn get id => text()();
  TextColumn get json => text()();
  TextColumn get search => text()();
  @override
  Set<Column> get primaryKey => {id};
}

class LocalArtists extends Table {
  @override
  String get tableName => 'artists';
  TextColumn get id => text()();
  TextColumn get json => text()();
  TextColumn get search => text()();
  @override
  Set<Column> get primaryKey => {id};
}

class LocalPlaylists extends Table {
  @override
  String get tableName => 'playlists';
  TextColumn get id => text()();
  TextColumn get json => text()();
  IntColumn get version => integer()();
  TextColumn get search => text()();
  @override
  Set<Column> get primaryKey => {id};
}

class LocalPlaylistItems extends Table {
  @override
  String get tableName => 'playlist_items';
  TextColumn get playlistId => text()();
  TextColumn get itemId => text()();
  IntColumn get position => integer()();
  TextColumn get trackId => text()();
  @override
  Set<Column> get primaryKey => {playlistId, itemId};
}

/// 가사 전체(세 종류 + 보정값) 사본 (03장 §5.6)
class LocalLyrics extends Table {
  @override
  String get tableName => 'lyrics';
  TextColumn get trackId => text()();
  TextColumn get json => text()();
  TextColumn get etag => text().nullable()();
  @override
  Set<Column> get primaryKey => {trackId};
}

/// 다운로드 (03장 §5.2, §5.3). 상태 전이는 domain/download_state.dart만 한다.
@DataClassName('DownloadRow')
class Downloads extends Table {
  TextColumn get id => text()();
  TextColumn get trackId => text()();
  TextColumn get quality => text()();
  TextColumn get state => text()();
  TextColumn get renditionId => text().nullable()();
  TextColumn get mediaVersion => text().nullable()();
  IntColumn get bytesTotal => integer().nullable()();
  IntColumn get bytesDone => integer().withDefault(const Constant(0))();
  TextColumn get sha256 => text().nullable()();
  TextColumn get etag => text().nullable()();
  TextColumn get ext => text().nullable()();
  TextColumn get errorCode => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  BoolColumn get integrityRetried => boolean().withDefault(const Constant(false))();
  IntColumn get notBefore => integer().nullable()();
  BoolColumn get stale => boolean().withDefault(const Constant(false))();
  BoolColumn get locked => boolean().withDefault(const Constant(false))();
  TextColumn get verified => text().nullable()();
  TextColumn get fileName => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get completedAt => integer().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// 누가 이 다운로드를 요구했나 (03장 §5.4 중복 방지: 파일 하나를 공유하고 요청자만 늘린다).
/// 설계의 requested_by 컬럼을 요청자 여러 개를 담도록 표로 나눴다. kind: track / album / playlist
class DownloadRequests extends Table {
  TextColumn get downloadId => text()();
  TextColumn get kind => text()();
  TextColumn get refId => text()();
  @override
  Set<Column> get primaryKey => {downloadId, kind, refId};
}

/// "앨범/플레이리스트 전체 다운로드"로 고정한 대상 — 새 곡이 추가되면 자동으로 받는다 (03장 §5.2)
class DownloadGroups extends Table {
  TextColumn get kind => text()();
  TextColumn get refId => text()();
  TextColumn get quality => text()();
  IntColumn get createdAt => integer()();
  @override
  Set<Column> get primaryKey => {kind, refId};
}

/// 오프라인 중 플레이리스트 편집 (순서 보존, Idempotency-Key 포함)
class PendingOps extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get playlistId => text()();
  TextColumn get opsJson => text()();
  TextColumn get idempotencyKey => text()();
  IntColumn get createdAt => integer()();
}

/// 미전송 재생 기록 (event_id로 서버가 중복 제거, FN-22)
class PendingPlayEvents extends Table {
  TextColumn get eventId => text()();
  TextColumn get json => text()();
  IntColumn get createdAt => integer()();
  @override
  Set<Column> get primaryKey => {eventId};
}

class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [LocalTracks, LocalAlbums, LocalArtists, LocalPlaylists, LocalPlaylistItems, LocalLyrics, Downloads, DownloadRequests, DownloadGroups, PendingOps, PendingPlayEvents, SyncState])
class LibraryDb extends _$LibraryDb {
  LibraryDb(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement('CREATE INDEX downloads_track ON downloads (track_id, quality)');
          await customStatement('CREATE INDEX downloads_state ON downloads (state)');
          await customStatement('CREATE INDEX tracks_album ON tracks (album_id)');
        },
        beforeOpen: (_) async {
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
