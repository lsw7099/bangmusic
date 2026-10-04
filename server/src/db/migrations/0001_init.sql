-- 0001: 초기 스키마 (01장 §4.2). 전진 전용. 적용 후 이 파일을 고치지 않는다(체크섬 검사).
-- 시간은 UTC epoch 밀리초 INTEGER, ID는 접두어+ULID TEXT.

CREATE TABLE server_meta (
  singleton       INTEGER PRIMARY KEY CHECK (singleton = 1),
  server_id       TEXT NOT NULL,
  name            TEXT NOT NULL,
  created_at      INTEGER NOT NULL,
  signing_key_id  TEXT,
  change_seq      INTEGER NOT NULL DEFAULT 0,   -- 마지막으로 발급한 전역 change_seq
  tombstone_horizon_seq INTEGER NOT NULL DEFAULT 0 -- 이보다 오래된 since는 410 sync_token_expired
);

CREATE TABLE users (
  id             TEXT PRIMARY KEY,
  username       TEXT NOT NULL UNIQUE,          -- NFKC + 소문자
  display_name   TEXT,
  password_hash  TEXT NOT NULL,                 -- Argon2id PHC 문자열
  role           TEXT NOT NULL CHECK (role IN ('admin', 'member')),
  status         TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled')),
  created_at     INTEGER NOT NULL,
  deleted_at     INTEGER
);

CREATE TABLE sessions (
  id                  TEXT PRIMARY KEY,
  user_id             TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  installation_id     TEXT NOT NULL,
  device_name         TEXT NOT NULL,
  platform            TEXT NOT NULL,
  app_version         TEXT,
  refresh_hash        TEXT NOT NULL UNIQUE,
  refresh_family      TEXT NOT NULL,
  prev_refresh_hash   TEXT,
  rotated_at          INTEGER,                  -- 직전 회전 시각 (60초 재시도 유예 판단)
  rotation_blob       TEXT,                     -- 유예 시간 동안 같은 토큰 쌍을 돌려주기 위한 암호문
  access_hash         TEXT NOT NULL UNIQUE,
  access_expires_at   INTEGER NOT NULL,
  refresh_expires_at  INTEGER NOT NULL,
  created_at          INTEGER NOT NULL,
  last_seen_at        INTEGER NOT NULL,
  revoked_at          INTEGER,
  revoke_reason       TEXT
);
CREATE INDEX sessions_user ON sessions(user_id);
CREATE INDEX sessions_prev_refresh ON sessions(prev_refresh_hash);

CREATE TABLE libraries (
  id             TEXT PRIMARY KEY,
  name           TEXT NOT NULL,
  root_path      TEXT NOT NULL,                 -- 등록 시 입력한 경로 (서버 내부 전용, API 비공개)
  root_real      TEXT NOT NULL,                 -- 등록 시 realpath. 이후 달라지면 unavailable (SEC-04)
  status         TEXT NOT NULL DEFAULT 'online' CHECK (status IN ('online', 'unavailable')),
  last_scan_at   INTEGER,
  revision       INTEGER NOT NULL DEFAULT 0,
  pending_review INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE user_library_access (
  user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  library_id  TEXT NOT NULL REFERENCES libraries(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, library_id)
);

CREATE TABLE artworks (
  id            TEXT PRIMARY KEY,
  source        TEXT NOT NULL CHECK (source IN ('embedded', 'folder', 'upload')),
  content_hash  TEXT NOT NULL UNIQUE,           -- 원본 이미지 바이트의 SHA-256 (중복 제거)
  mime          TEXT NOT NULL,
  width         INTEGER NOT NULL,
  height        INTEGER NOT NULL,
  storage_ref   TEXT NOT NULL                   -- /data/artwork 아래 파일 이름 (정규화된 마스터 JPEG)
);

CREATE TABLE artists (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  name_sort   TEXT,
  name_norm   TEXT NOT NULL UNIQUE,
  sort_key    TEXT NOT NULL,
  created_at  INTEGER NOT NULL,
  change_seq  INTEGER NOT NULL
);

CREATE TABLE albums (
  id               TEXT PRIMARY KEY,
  library_id       TEXT NOT NULL REFERENCES libraries(id) ON DELETE CASCADE,
  title            TEXT NOT NULL,
  title_sort       TEXT,
  title_norm       TEXT NOT NULL,
  sort_key         TEXT NOT NULL,
  album_artist_id  TEXT REFERENCES artists(id),
  year             INTEGER,
  artwork_id       TEXT REFERENCES artworks(id),
  group_key        TEXT NOT NULL,              -- 라이브러리 안에서 앨범을 묶는 키 (앨범 아티스트 + 제목)
  added_at         INTEGER NOT NULL,
  change_seq       INTEGER NOT NULL,
  UNIQUE (library_id, group_key)
);

CREATE TABLE tracks (
  id              TEXT PRIMARY KEY,
  library_id      TEXT NOT NULL REFERENCES libraries(id) ON DELETE CASCADE,
  album_id        TEXT REFERENCES albums(id),
  title           TEXT NOT NULL,
  title_sort      TEXT,
  title_norm      TEXT NOT NULL,
  sort_key        TEXT NOT NULL,
  artist_display  TEXT,
  disc_no         INTEGER,
  track_no        INTEGER,
  duration_ms     INTEGER NOT NULL,
  year            INTEGER,
  genre           TEXT,
  artwork_id      TEXT REFERENCES artworks(id),
  media_version   TEXT NOT NULL,
  state           TEXT NOT NULL CHECK (state IN ('available', 'missing')),
  missing_since   INTEGER,
  added_at        INTEGER NOT NULL,
  updated_at      INTEGER NOT NULL,
  change_seq      INTEGER NOT NULL
);
CREATE INDEX tracks_library ON tracks(library_id);
CREATE INDEX tracks_album ON tracks(album_id);
CREATE INDEX tracks_change ON tracks(change_seq);

CREATE TABLE media_files (
  id                 TEXT PRIMARY KEY,
  track_id           TEXT NOT NULL UNIQUE REFERENCES tracks(id) ON DELETE CASCADE,
  library_id         TEXT NOT NULL REFERENCES libraries(id) ON DELETE CASCADE,
  rel_path           TEXT NOT NULL,              -- 라이브러리 루트 기준 상대 경로 ('/' 구분). API로 노출하지 않는다.
  size_bytes         INTEGER NOT NULL,
  mtime_ns           TEXT NOT NULL,              -- 나노초 문자열 (정밀도 보존)
  content_hash       TEXT NOT NULL,
  audio_fingerprint  TEXT,
  container          TEXT NOT NULL,
  codec              TEXT NOT NULL,
  mime               TEXT NOT NULL,
  bitrate            INTEGER,
  sample_rate        INTEGER,
  channels           INTEGER,
  bit_depth          INTEGER,
  scanned_at         INTEGER NOT NULL,
  UNIQUE (library_id, rel_path)
);
CREATE INDEX media_files_hash ON media_files(content_hash);
CREATE INDEX media_files_fp ON media_files(audio_fingerprint);

CREATE TABLE track_artists (
  track_id   TEXT NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
  artist_id  TEXT NOT NULL REFERENCES artists(id),
  role       TEXT NOT NULL DEFAULT 'primary',
  position   INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (track_id, artist_id, role)
);
CREATE INDEX track_artists_artist ON track_artists(artist_id);

-- §4.6: 곡 제목·아티스트명·앨범명 trigram 색인. entity_id로 원본 행을 찾는다.
CREATE VIRTUAL TABLE search_fts USING fts5(entity_type UNINDEXED, entity_id UNINDEXED, text_norm, tokenize = 'trigram');

CREATE TABLE tombstones (
  entity_type  TEXT NOT NULL,
  entity_id    TEXT NOT NULL,
  library_id   TEXT,
  change_seq   INTEGER NOT NULL,
  deleted_at   INTEGER NOT NULL,
  PRIMARY KEY (entity_type, entity_id)
);
CREATE INDEX tombstones_change ON tombstones(change_seq);

CREATE TABLE renditions (
  id             TEXT PRIMARY KEY,
  track_id       TEXT NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
  media_version  TEXT NOT NULL,
  profile        TEXT NOT NULL,
  state          TEXT NOT NULL CHECK (state IN ('ready', 'preparing', 'failed')),
  mime           TEXT,
  container      TEXT,
  codec          TEXT,
  size_bytes     INTEGER,
  duration_ms    INTEGER,
  sha256         TEXT,
  cache_ref      TEXT,                          -- profile=original이면 NULL (원본을 가리킨다)
  created_at     INTEGER NOT NULL,
  last_access_at INTEGER,
  error_code     TEXT,
  UNIQUE (track_id, media_version, profile)
);

CREATE TABLE jobs (
  id            TEXT PRIMARY KEY,
  type          TEXT NOT NULL CHECK (type IN ('transcode', 'scan', 'hash', 'backup')),
  ref_id        TEXT,
  state         TEXT NOT NULL CHECK (state IN ('queued', 'running', 'succeeded', 'failed', 'canceled')),
  progress      REAL,
  attempts      INTEGER NOT NULL DEFAULT 0,
  not_before    INTEGER,
  created_at    INTEGER NOT NULL,
  started_at    INTEGER,
  finished_at   INTEGER,
  error_code    TEXT,
  error_detail  TEXT                            -- 서버 내부 전용. API로 내보내지 않는다.
);
CREATE INDEX jobs_state ON jobs(state);
