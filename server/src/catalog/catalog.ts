// 카탈로그 조회 (곡·앨범·아티스트·검색·변경 피드). 01장 §4.5~4.7, 02장 §3.
// 권한 없는 라이브러리의 자원은 존재를 숨긴다(404, 목록·검색·피드에서 제외 — SEC-06).
import { createHash } from 'node:crypto';
import type { Principal } from '../auth/sessions.ts';
import type { Ctx } from '../ctx.ts';
import { ApiError, badRequest, notFound } from '../http/problem.ts';
import { hasLyrics } from '../lyrics/lyrics.ts';
import { listPlaylists } from '../playlists.ts';
import { norm } from '../norm.ts';

const iso = (ms: number) => new Date(ms).toISOString().replace(/\.\d{3}Z$/, 'Z');

/** 라이브러리 접근 조건. params = [isAdmin, userId] */
const ACCESS = (col: string) => `(? = 1 OR ${col} IN (SELECT library_id FROM user_library_access WHERE user_id = ?))`;
const accessParams = (p: Principal) => [p.user.role === 'admin' ? 1 : 0, p.user.id] as const;

export function accessibleLibraries(ctx: Ctx, p: Principal) {
  return ctx.store.all<{ id: string; name: string; status: 'online' | 'unavailable' }>(
    `SELECT id, name, status FROM libraries WHERE ${ACCESS('id')} ORDER BY name`, ...accessParams(p));
}

export function canAccessLibrary(ctx: Ctx, p: Principal, libraryId: string): boolean {
  return Boolean(ctx.store.get(`SELECT 1 FROM libraries WHERE id = ? AND ${ACCESS('id')}`, libraryId, ...accessParams(p)));
}

// ── 커서 ─────────────────────────────────────────────────────────

interface Cursor {
  s: string; // 정렬 이름
  f: string; // 필터 서명
  k: (string | number)[]; // 정렬 키 + id
}

function filterSig(filters: Record<string, unknown>): string {
  return createHash('sha256').update(JSON.stringify(filters)).digest('base64url').slice(0, 10);
}

function encodeCursor(c: Cursor): string {
  return Buffer.from(JSON.stringify(c)).toString('base64url');
}

/** 다른 정렬·필터와 섞인 커서는 400 (02장 §3) */
function decodeCursor(raw: string | undefined, sort: string, sig: string, width: number): Cursor | null {
  if (raw === undefined) return null;
  let c: Cursor;
  try {
    c = JSON.parse(Buffer.from(raw, 'base64url').toString('utf8'));
  } catch {
    throw badRequest('cursor', '해석할 수 없는 커서');
  }
  if (!c || c.s !== sort || c.f !== sig || !Array.isArray(c.k) || c.k.length !== width) throw badRequest('cursor', '정렬·필터가 다른 커서');
  return c;
}

/**
 * keyset 페이지. sortExprs는 모두 오름차순 식이며 마지막에 id가 붙는다.
 * 내림차순은 식에 부호를 붙여 표현한다(예: -added_at).
 */
function page<T extends { id: string }>(ctx: Ctx, o: {
  select: string; // "SELECT ... FROM ... WHERE ..." (ORDER/LIMIT 없음)
  params: readonly unknown[];
  idCol: string;
  sortName: string;
  sortExprs: string[];
  filters: Record<string, unknown>;
  cursor: string | undefined;
  limit: number;
}): { rows: (T & Record<string, unknown>)[]; next: string | null } {
  const sig = filterSig(o.filters);
  const keys = [...o.sortExprs, o.idCol];
  const c = decodeCursor(o.cursor, o.sortName, sig, keys.length);
  const keySel = keys.map((e, i) => `${e} AS _k${i}`).join(', ');
  const where = c ? ` AND (${keys.join(', ')}) > (${keys.map(() => '?').join(', ')})` : '';
  const sql = `SELECT * FROM (${o.select.replace(/^SELECT /, `SELECT ${keySel}, `)}${where}) ORDER BY ${keys.map((_, i) => `_k${i}`).join(', ')} LIMIT ?`;
  const rows = ctx.store.all<T & Record<string, unknown>>(sql, ...(o.params as never[]), ...((c?.k ?? []) as never[]), o.limit + 1);
  let next: string | null = null;
  if (rows.length > o.limit) {
    rows.length = o.limit;
    const last = rows[rows.length - 1]!;
    next = encodeCursor({ s: o.sortName, f: sig, k: keys.map((_, i) => last[`_k${i}`] as string | number) });
  }
  return { rows, next };
}

// ── 곡 ───────────────────────────────────────────────────────────

const TRACK_SELECT = `SELECT t.*, al.title AS album_title, al.sort_key AS album_sort_key,
    m.container, m.codec, m.sample_rate, m.channels, m.bit_depth, m.bitrate
  FROM tracks t LEFT JOIN albums al ON al.id = t.album_id LEFT JOIN media_files m ON m.track_id = t.id`;

export interface TrackRow {
  id: string;
  library_id: string;
  album_id: string | null;
  album_title: string | null;
  title: string;
  title_sort: string | null;
  disc_no: number | null;
  track_no: number | null;
  duration_ms: number;
  year: number | null;
  genre: string | null;
  artwork_id: string | null;
  media_version: string;
  state: 'available' | 'missing';
  updated_at: number;
  container: string | null;
  codec: string | null;
  sample_rate: number | null;
  channels: number | null;
  bit_depth: number | null;
  bitrate: number | null;
}

export function trackDtos(ctx: Ctx, rows: TrackRow[]) {
  if (rows.length === 0) return [];
  const ids = rows.map((r) => r.id);
  const artists = ctx.store.all<{ track_id: string; id: string; name: string }>(
    `SELECT ta.track_id, ar.id, ar.name FROM track_artists ta JOIN artists ar ON ar.id = ta.artist_id
      WHERE ta.track_id IN (${ids.map(() => '?').join(',')}) ORDER BY ta.position`, ...ids);
  const lyrics = hasLyrics(ctx, ids);
  const byTrack = new Map<string, { id: string; name: string }[]>();
  for (const a of artists) {
    const list = byTrack.get(a.track_id) ?? [];
    list.push({ id: a.id, name: a.name });
    byTrack.set(a.track_id, list);
  }
  return rows.map((r) => ({
    id: r.id,
    title: r.title,
    title_sort: r.title_sort,
    artists: byTrack.get(r.id) ?? [],
    album: r.album_id ? { id: r.album_id, title: r.album_title ?? '' } : null,
    disc_no: r.disc_no,
    track_no: r.track_no,
    duration_ms: r.duration_ms,
    year: r.year,
    genre: r.genre,
    artwork_id: r.artwork_id,
    media_version: r.media_version,
    ...(r.container ? {
      source_format: {
        container: r.container,
        codec: r.codec ?? 'unknown',
        ...(r.sample_rate ? { sample_rate: r.sample_rate } : {}),
        ...(r.channels ? { channels: r.channels } : {}),
        bit_depth: r.bit_depth,
        bitrate: r.bitrate,
      },
    } : {}),
    state: r.state,
    has_lyrics: lyrics.get(r.id) ?? [],
    updated_at: iso(r.updated_at),
  }));
}

export function getTrackRow(ctx: Ctx, p: Principal, trackId: string): TrackRow {
  const row = ctx.store.get<TrackRow>(`${TRACK_SELECT} WHERE t.id = ? AND ${ACCESS('t.library_id')}`, trackId, ...accessParams(p));
  if (!row) throw notFound();
  return row;
}

export function getTrack(ctx: Ctx, p: Principal, trackId: string) {
  return trackDtos(ctx, [getTrackRow(ctx, p, trackId)])[0];
}

const TRACK_SORTS: Record<string, string[]> = {
  title: ['t.sort_key'],
  added_at_desc: ['-t.added_at'],
  album: ["COALESCE(al.sort_key, '')", 'COALESCE(t.disc_no, 0)', 'COALESCE(t.track_no, 0)', 't.sort_key'],
};

export function listTracks(ctx: Ctx, p: Principal, q: { cursor?: string; limit: number; sort: string; album_id?: string; artist_id?: string; library_id?: string }) {
  const conds = [ACCESS('t.library_id')];
  const params: unknown[] = [...accessParams(p)];
  if (q.album_id) { conds.push('t.album_id = ?'); params.push(q.album_id); }
  if (q.artist_id) { conds.push('t.id IN (SELECT track_id FROM track_artists WHERE artist_id = ?)'); params.push(q.artist_id); }
  if (q.library_id) { conds.push('t.library_id = ?'); params.push(q.library_id); }
  const r = page<TrackRow>(ctx, {
    select: `${TRACK_SELECT} WHERE ${conds.join(' AND ')}`,
    params, idCol: 't.id', sortName: q.sort, sortExprs: TRACK_SORTS[q.sort]!,
    filters: { a: q.album_id, r: q.artist_id, l: q.library_id }, cursor: q.cursor, limit: q.limit,
  });
  return { items: trackDtos(ctx, r.rows), next_cursor: r.next };
}

// ── 앨범 ─────────────────────────────────────────────────────────

const ALBUM_SELECT = `SELECT al.*, ar.name AS album_artist_name,
    (SELECT COUNT(*) FROM tracks t WHERE t.album_id = al.id) AS track_count,
    (SELECT COALESCE(SUM(t.duration_ms), 0) FROM tracks t WHERE t.album_id = al.id) AS total_ms
  FROM albums al LEFT JOIN artists ar ON ar.id = al.album_artist_id`;

interface AlbumRow {
  id: string;
  title: string;
  album_artist_id: string | null;
  album_artist_name: string | null;
  year: number | null;
  artwork_id: string | null;
  track_count: number;
  total_ms: number;
}

function albumDto(r: AlbumRow) {
  return {
    id: r.id,
    title: r.title,
    album_artist: r.album_artist_id ? { id: r.album_artist_id, name: r.album_artist_name ?? '' } : null,
    year: r.year,
    artwork_id: r.artwork_id,
    track_count: Number(r.track_count),
    duration_ms: Number(r.total_ms),
  };
}

/** 앨범은 접근 가능한 곡이 1개 이상일 때만 보인다 (01장 §4.5) */
const ALBUM_VISIBLE = `${ACCESS('al.library_id')} AND EXISTS (SELECT 1 FROM tracks t WHERE t.album_id = al.id)`;

const ALBUM_SORTS: Record<string, string[]> = {
  title: ['al.sort_key'],
  added_at_desc: ['-al.added_at'],
  year_desc: ['-COALESCE(al.year, -1)', 'al.sort_key'],
};

export function listAlbums(ctx: Ctx, p: Principal, q: { cursor?: string; limit: number; sort: string; artist_id?: string }) {
  const conds = [ALBUM_VISIBLE];
  const params: unknown[] = [...accessParams(p)];
  if (q.artist_id) {
    conds.push('(al.album_artist_id = ? OR EXISTS (SELECT 1 FROM tracks t JOIN track_artists ta ON ta.track_id = t.id WHERE t.album_id = al.id AND ta.artist_id = ?))');
    params.push(q.artist_id, q.artist_id);
  }
  const r = page<AlbumRow>(ctx, {
    select: `${ALBUM_SELECT} WHERE ${conds.join(' AND ')}`,
    params, idCol: 'al.id', sortName: q.sort, sortExprs: ALBUM_SORTS[q.sort]!,
    filters: { r: q.artist_id }, cursor: q.cursor, limit: q.limit,
  });
  return { items: r.rows.map(albumDto), next_cursor: r.next };
}

function albumRow(ctx: Ctx, p: Principal, id: string): AlbumRow | undefined {
  return ctx.store.get<AlbumRow>(`${ALBUM_SELECT} WHERE al.id = ? AND ${ALBUM_VISIBLE}`, id, ...accessParams(p));
}

export function getAlbum(ctx: Ctx, p: Principal, albumId: string) {
  const r = albumRow(ctx, p, albumId);
  if (!r) throw notFound();
  const tracks = ctx.store.all<TrackRow>(`${TRACK_SELECT} WHERE t.album_id = ? ORDER BY COALESCE(t.disc_no, 0), COALESCE(t.track_no, 0), t.sort_key, t.id`, albumId);
  return { ...albumDto(r), tracks: trackDtos(ctx, tracks) };
}

// ── 아티스트 ─────────────────────────────────────────────────────

const ARTIST_SELECT = (accessCols: string) => `SELECT ar.*,
    (SELECT COUNT(*) FROM track_artists ta JOIN tracks t ON t.id = ta.track_id WHERE ta.artist_id = ar.id AND ${accessCols}) AS track_count,
    (SELECT COUNT(DISTINCT t.album_id) FROM track_artists ta JOIN tracks t ON t.id = ta.track_id WHERE ta.artist_id = ar.id AND t.album_id IS NOT NULL AND ${accessCols}) AS album_count
  FROM artists ar`;

/** 아티스트는 접근 가능한 곡이나 앨범이 있을 때만 보인다 */
const ARTIST_VISIBLE = `(EXISTS (SELECT 1 FROM track_artists ta JOIN tracks t ON t.id = ta.track_id WHERE ta.artist_id = ar.id AND ${ACCESS('t.library_id')})
  OR EXISTS (SELECT 1 FROM albums al WHERE al.album_artist_id = ar.id AND ${ALBUM_VISIBLE}))`;

interface ArtistRow {
  id: string;
  name: string;
  name_sort: string | null;
  track_count: number;
  album_count: number;
}

function artistDto(r: ArtistRow) {
  return { id: r.id, name: r.name, name_sort: r.name_sort, album_count: Number(r.album_count), track_count: Number(r.track_count), artwork_id: null };
}

function artistQuery(p: Principal) {
  const ap = accessParams(p);
  return { select: ARTIST_SELECT(ACCESS('t.library_id')), selectParams: [...ap, ...ap], visibleParams: [...ap, ...ap] };
}

export function listArtists(ctx: Ctx, p: Principal, q: { cursor?: string; limit: number }) {
  const a = artistQuery(p);
  const r = page<ArtistRow>(ctx, {
    select: `${a.select} WHERE ${ARTIST_VISIBLE}`,
    params: [...a.selectParams, ...a.visibleParams], idCol: 'ar.id', sortName: 'name', sortExprs: ['ar.sort_key'],
    filters: {}, cursor: q.cursor, limit: q.limit,
  });
  return { items: r.rows.map(artistDto), next_cursor: r.next };
}

export function getArtist(ctx: Ctx, p: Principal, artistId: string) {
  const a = artistQuery(p);
  const r = ctx.store.get<ArtistRow>(`${a.select} WHERE ar.id = ? AND ${ARTIST_VISIBLE}`, ...(a.selectParams as never[]), artistId, ...(a.visibleParams as never[]));
  if (!r) throw notFound();
  return artistDto(r);
}

// ── 검색 ─────────────────────────────────────────────────────────

const SEARCH_TYPES = ['track', 'album', 'artist', 'playlist'] as const;

export function search(ctx: Ctx, p: Principal, q: { q: string; types?: string; cursor?: string; limit: number }) {
  const qn = norm(q.q);
  if (!qn) throw badRequest('q', '빈 질의어');
  const types = q.types ? q.types.split(',').map((s) => s.trim()).filter(Boolean) : [...SEARCH_TYPES];
  for (const t of types) if (!(SEARCH_TYPES as readonly string[]).includes(t)) throw badRequest('types', `알 수 없는 유형: ${t}`);
  const single = types.length === 1;
  if (q.cursor && !single) throw badRequest('cursor', '여러 유형 검색에는 커서를 쓸 수 없다');

  // 3자 이상은 FTS5 trigram 부분 문자열, 1~2자는 *_norm 접두 검색 (01장 §4.6)
  const useFts = [...qn].length >= 3;
  const ftsQuery = `"${qn.replace(/"/g, '""')}"`;
  const like = `${qn.replace(/[\\%_]/g, (m) => `\\${m}`)}%`;
  const match = (type: string, idCol: string, normCol: string) =>
    useFts
      ? { sql: `${idCol} IN (SELECT entity_id FROM search_fts WHERE entity_type = '${type}' AND search_fts MATCH ?)`, params: [ftsQuery] }
      : { sql: `(${normCol} LIKE ? ESCAPE '\\' OR ${idCol} IN (SELECT entity_id FROM search_fts WHERE entity_type = '${type}' AND text_norm LIKE ? ESCAPE '\\'))`, params: [like, like] };
  const cursorFor = (t: string) => (single && types[0] === t ? q.cursor : undefined);
  const out: Record<string, unknown> = { query_normalized: qn };

  if (types.includes('track')) {
    const m = match('track', 't.id', 't.title_norm');
    const r = page<TrackRow>(ctx, {
      select: `${TRACK_SELECT} WHERE ${ACCESS('t.library_id')} AND ${m.sql}`, params: [...accessParams(p), ...m.params],
      idCol: 't.id', sortName: 'search', sortExprs: ['t.sort_key'], filters: { q: qn, t: 'track' }, cursor: cursorFor('track'), limit: q.limit,
    });
    out.tracks = { items: trackDtos(ctx, r.rows), next_cursor: single ? r.next : null };
  }
  if (types.includes('album')) {
    const m = match('album', 'al.id', 'al.title_norm');
    const r = page<AlbumRow>(ctx, {
      select: `${ALBUM_SELECT} WHERE ${ALBUM_VISIBLE} AND ${m.sql}`, params: [...accessParams(p), ...m.params],
      idCol: 'al.id', sortName: 'search', sortExprs: ['al.sort_key'], filters: { q: qn, t: 'album' }, cursor: cursorFor('album'), limit: q.limit,
    });
    out.albums = { items: r.rows.map(albumDto), next_cursor: single ? r.next : null };
  }
  if (types.includes('artist')) {
    const a = artistQuery(p);
    const m = match('artist', 'ar.id', 'ar.name_norm');
    const r = page<ArtistRow>(ctx, {
      select: `${a.select} WHERE ${ARTIST_VISIBLE} AND ${m.sql}`, params: [...a.selectParams, ...a.visibleParams, ...m.params],
      idCol: 'ar.id', sortName: 'search', sortExprs: ['ar.sort_key'], filters: { q: qn, t: 'artist' }, cursor: cursorFor('artist'), limit: q.limit,
    });
    out.artists = { items: r.rows.map(artistDto), next_cursor: single ? r.next : null };
  }
  if (types.includes('playlist')) {
    // 내 플레이리스트만, 이름 부분 일치
    const r = listPlaylists(ctx, p, { limit: q.limit, cursor: cursorFor('playlist'), nameLike: qn });
    out.playlists = { items: r.items, next_cursor: single ? r.next_cursor : null };
  }
  return out;
}

// ── 변경 피드 ────────────────────────────────────────────────────

export function changes(ctx: Ctx, p: Principal, q: { since: string; limit: number }) {
  if (!/^\d{1,15}$/.test(q.since)) throw badRequest('since', '정수 문자열이어야 한다');
  const since = Number(q.since);
  const meta = ctx.store.get<{ change_seq: number; tombstone_horizon_seq: number }>('SELECT change_seq, tombstone_horizon_seq FROM server_meta')!;
  if (since > 0 && since < meta.tombstone_horizon_seq) throw new ApiError(410, 'sync_token_expired');

  const ap = accessParams(p);
  const a = artistQuery(p);
  // 보이는 항목만. 보이지 않는 변경은 건너뛰되 next_since는 앞으로 간다.
  const rows = ctx.store.all<{ seq: number; entity: string; id: string; op: string }>(
    `SELECT seq, entity, id, op FROM (
        SELECT t.change_seq AS seq, 'track' AS entity, t.id, 'upsert' AS op FROM tracks t WHERE t.change_seq > ? AND ${ACCESS('t.library_id')}
        UNION ALL SELECT al.change_seq, 'album', al.id, 'upsert' FROM albums al WHERE al.change_seq > ? AND ${ALBUM_VISIBLE}
        UNION ALL SELECT ar.change_seq, 'artist', ar.id, 'upsert' FROM artists ar WHERE ar.change_seq > ? AND ${ARTIST_VISIBLE}
        UNION ALL SELECT change_seq, entity_type, entity_id, 'delete' FROM tombstones
          WHERE change_seq > ? AND entity_type IN ('track', 'album', 'artist') AND (library_id IS NULL OR ${ACCESS('library_id')})
      ) ORDER BY seq LIMIT ?`,
    since, ...ap, since, ...ap, since, ...a.visibleParams, since, ...ap, q.limit + 1);
  const hasMore = rows.length > q.limit;
  if (hasMore) rows.length = q.limit;

  const out = rows.map((r) => {
    if (r.op === 'delete') return { entity: r.entity, id: r.id, op: 'delete' };
    if (r.entity === 'track') return { entity: 'track', id: r.id, op: 'upsert', track: getTrack(ctx, p, r.id) };
    if (r.entity === 'album') return { entity: 'album', id: r.id, op: 'upsert', album: albumDto(albumRow(ctx, p, r.id)!) };
    return { entity: 'artist', id: r.id, op: 'upsert', artist: getArtist(ctx, p, r.id) };
  });
  const nextSince = hasMore ? rows[rows.length - 1]!.seq : meta.change_seq;
  return { changes: out, next_since: String(nextSince), has_more: hasMore };
}

/** 표지가 사용자에게 보이는지 (접근 가능한 곡·앨범이 쓰는 표지) */
export function canSeeArtwork(ctx: Ctx, p: Principal, artworkId: string): boolean {
  const ap = accessParams(p);
  return Boolean(ctx.store.get(
    `SELECT 1 WHERE EXISTS (SELECT 1 FROM tracks t WHERE t.artwork_id = ? AND ${ACCESS('t.library_id')})
       OR EXISTS (SELECT 1 FROM albums al WHERE al.artwork_id = ? AND ${ACCESS('al.library_id')})
       OR EXISTS (SELECT 1 FROM playlists pl WHERE pl.artwork_id = ? AND pl.owner_id = ? AND pl.deleted_at IS NULL)`,
    artworkId, ...ap, artworkId, ...ap, artworkId, p.user.id));
}
