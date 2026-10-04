-- 0002: P2 — 플레이리스트, 가사, 재생 기록, 멱등 키, 변환 작업 (01장 §4.2). 전진 전용.

CREATE TABLE playlists (
  id           TEXT PRIMARY KEY,
  owner_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  name_norm    TEXT NOT NULL,
  description  TEXT,
  artwork_id   TEXT REFERENCES artworks(id),
  version      INTEGER NOT NULL DEFAULT 1,      -- 변경마다 +1, ETag "<version>"
  created_at   INTEGER NOT NULL,
  updated_at   INTEGER NOT NULL,
  deleted_at   INTEGER
);
CREATE INDEX playlists_owner ON playlists(owner_id, updated_at);

CREATE TABLE playlist_items (
  id            TEXT PRIMARY KEY,
  playlist_id   TEXT NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
  track_id      TEXT NOT NULL REFERENCES tracks(id),
  position_key  TEXT NOT NULL,                 -- 분수 인덱스 (사전순 = 재생 순서)
  added_at      INTEGER NOT NULL
);
CREATE INDEX playlist_items_order ON playlist_items(playlist_id, position_key, id);

CREATE TABLE lyrics (
  track_id      TEXT NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
  kind          TEXT NOT NULL CHECK (kind IN ('original', 'pronunciation_ko', 'translation_ko')),
  format        TEXT NOT NULL CHECK (format IN ('lrc', 'plain')),
  language      TEXT,
  body          TEXT NOT NULL,
  source_type   TEXT NOT NULL CHECK (source_type IN ('sidecar', 'embedded', 'user', 'provider')),
  source_name   TEXT,
  license_note  TEXT,
  content_hash  TEXT NOT NULL,                 -- 사이드카가 바뀌었는지 판단
  updated_at    INTEGER NOT NULL,
  PRIMARY KEY (track_id, kind)
);

-- 곡별 가사 묶음 버전 (ETag). 가사 종류가 바뀔 때마다 +1
CREATE TABLE lyrics_versions (
  track_id  TEXT PRIMARY KEY REFERENCES tracks(id) ON DELETE CASCADE,
  version   INTEGER NOT NULL
);

CREATE TABLE lyrics_prefs (
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  track_id   TEXT NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
  offset_ms  INTEGER NOT NULL,
  PRIMARY KEY (user_id, track_id)
);

CREATE TABLE play_events (
  event_id      TEXT PRIMARY KEY,              -- 앱이 만든 UUID. 충돌 = 중복 재전송 → 무시
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_id    TEXT,
  track_id      TEXT NOT NULL REFERENCES tracks(id),
  started_at    INTEGER NOT NULL,
  played_ms     INTEGER NOT NULL,
  completed     INTEGER NOT NULL,
  counted       INTEGER NOT NULL,              -- 03장 §6.9 기준(30초 또는 50%)을 넘었는지
  source        TEXT NOT NULL CHECK (source IN ('stream', 'offline')),
  context_type  TEXT,
  context_id    TEXT,
  received_at   INTEGER NOT NULL
);
CREATE INDEX play_events_user ON play_events(user_id, started_at);

CREATE TABLE track_stats (
  user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  track_id        TEXT NOT NULL REFERENCES tracks(id),
  play_count      INTEGER NOT NULL,
  last_played_at  INTEGER NOT NULL,
  PRIMARY KEY (user_id, track_id)
);
CREATE INDEX track_stats_recent ON track_stats(user_id, last_played_at);

-- Idempotency-Key: 같은 키의 재요청에 처음 결과를 돌려준다 (24시간 보존)
CREATE TABLE idempotency_keys (
  user_id      TEXT NOT NULL,
  key          TEXT NOT NULL,
  operation    TEXT NOT NULL,
  status       INTEGER NOT NULL,
  headers      TEXT NOT NULL,
  body         TEXT NOT NULL,
  created_at   INTEGER NOT NULL,
  PRIMARY KEY (user_id, key, operation)
);

-- 변환 작업 우선순위 (stream이 download보다 먼저, 03장 §4.6)
ALTER TABLE jobs ADD COLUMN priority INTEGER NOT NULL DEFAULT 0;

-- 분석에 실패한 파일을 크기·mtime이 같으면 다시 분석하지 않는다 (P1 알려진 제한 2)
CREATE TABLE scan_failures (
  library_id  TEXT NOT NULL REFERENCES libraries(id) ON DELETE CASCADE,
  rel_path    TEXT NOT NULL,
  size_bytes  INTEGER NOT NULL,
  mtime_ns    TEXT NOT NULL,
  reason      TEXT NOT NULL,
  failed_at   INTEGER NOT NULL,
  PRIMARY KEY (library_id, rel_path)
);
