// 플레이리스트 (02장 §4). 소유자 전용(남의 것은 404 — SEC-05).
// 모든 수정은 If-Match "<version>" 필수(없으면 428, 다르면 412 + 현재 ETag). 생성·편집은 Idempotency-Key로 재전송 중복 방지.
import type { Principal } from './auth/sessions.ts';
import { iso } from './auth/sessions.ts';
import { trackDtos, type TrackRow } from './catalog/catalog.ts';
import type { Ctx } from './ctx.ts';
import { ApiError, badRequest, notFound } from './http/problem.ts';
import { newId } from './ids.ts';
import { norm } from './norm.ts';

// ── 분수 인덱스 (base62, 사전순 = 순서) ───────────────────────────
const DIGITS = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
const idx = (c: string) => DIGITS.indexOf(c);

/** a < 결과 < b. a=''은 0, b=null은 1. 결과는 '0'으로 끝나지 않는다. */
export function keyBetween(a: string, b: string | null): string {
  if (b !== null && a >= b) throw new Error(`keyBetween: ${a} >= ${b}`);
  if (b !== null) {
    let n = 0;
    while ((a[n] ?? '0') === b[n]) n++;
    if (n > 0) return b.slice(0, n) + keyBetween(a.slice(n), b.slice(n));
  }
  const da = a ? idx(a[0]!) : 0;
  const db = b !== null ? idx(b[0]!) : DIGITS.length;
  if (db - da > 1) return DIGITS[Math.round((da + db) / 2)]!;
  if (b !== null && b.length > 1) return b[0]!;
  return DIGITS[da]! + keyBetween(a.slice(1), null);
}

// ── 공통 ─────────────────────────────────────────────────────────

export interface PlaylistRow {
  id: string;
  owner_id: string;
  name: string;
  description: string | null;
  artwork_id: string | null;
  version: number;
  created_at: number;
  updated_at: number;
}

export const etagOf = (pl: { version: number }) => `"${pl.version}"`;

function load(ctx: Ctx, p: Principal, id: string): PlaylistRow {
  const pl = ctx.store.get<PlaylistRow>('SELECT * FROM playlists WHERE id = ? AND deleted_at IS NULL', id);
  if (!pl || pl.owner_id !== p.user.id) throw notFound(); // 관리자도 남의 플레이리스트는 볼 수 없다
  return pl;
}

/** If-Match 확인. 없으면 428, 다르면 412 + 현재 ETag */
function checkVersion(pl: PlaylistRow, ifMatch: string | undefined, missing: 'precondition' | 'validation' = 'precondition') {
  if (!ifMatch) throw missing === 'precondition' ? new ApiError(428, 'precondition_required') : badRequest('If-Match', '필수 헤더');
  const m = /^(?:W\/)?"?(\d+)"?$/.exec(ifMatch.trim());
  if (!m || Number(m[1]) !== pl.version) throw new ApiError(412, 'version_conflict', { headers: { etag: etagOf(pl) } });
}

const ACCESS = `(? = 1 OR t.library_id IN (SELECT library_id FROM user_library_access WHERE user_id = ?))`;
const accessParams = (p: Principal) => [p.user.role === 'admin' ? 1 : 0, p.user.id] as const;

export function playlistDto(ctx: Ctx, p: Principal, pl: PlaylistRow) {
  const stats = ctx.store.get<{ n: number; ms: number }>(
    `SELECT COUNT(*) AS n, COALESCE(SUM(CASE WHEN t.state = 'available' AND ${ACCESS} THEN t.duration_ms ELSE 0 END), 0) AS ms
       FROM playlist_items i JOIN tracks t ON t.id = i.track_id WHERE i.playlist_id = ?`, ...accessParams(p), pl.id)!;
  const mosaic = ctx.store.all<{ artwork_id: string }>(
    `SELECT t.artwork_id FROM playlist_items i JOIN tracks t ON t.id = i.track_id
      WHERE i.playlist_id = ? AND t.artwork_id IS NOT NULL AND t.state = 'available' AND ${ACCESS}
      GROUP BY t.artwork_id ORDER BY MIN(i.position_key) LIMIT 4`, pl.id, ...accessParams(p));
  return {
    id: pl.id,
    name: pl.name,
    description: pl.description,
    artwork_id: pl.artwork_id,
    mosaic_artwork_ids: mosaic.map((m) => m.artwork_id),
    version: pl.version,
    item_count: Number(stats.n),
    duration_ms: Number(stats.ms),
    created_at: iso(pl.created_at),
    updated_at: iso(pl.updated_at),
  };
}

function touch(ctx: Ctx, id: string) {
  ctx.store.run('UPDATE playlists SET version = version + 1, updated_at = ? WHERE id = ?', Date.now(), id);
}

/** 추가할 곡은 사용자가 볼 수 있는 곡이어야 한다(존재를 드러내지 않도록 400으로 통일) */
function checkTracks(ctx: Ctx, p: Principal, ids: string[]) {
  for (const id of new Set(ids)) {
    const ok = ctx.store.get(`SELECT 1 FROM tracks t WHERE t.id = ? AND ${ACCESS}`, id, ...accessParams(p));
    if (!ok) throw badRequest('track_ids', '알 수 없는 곡');
  }
}

function orderedKeys(ctx: Ctx, playlistId: string) {
  return ctx.store.all<{ id: string; position_key: string }>('SELECT id, position_key FROM playlist_items WHERE playlist_id = ? ORDER BY position_key, id', playlistId);
}

/** afterItemId: undefined=맨 뒤, null=맨 앞 */
function insertKeys(items: { id: string; position_key: string }[], afterItemId: string | null | undefined, count: number): string[] {
  let lo = '';
  let hi: string | null = null;
  if (afterItemId === undefined) {
    lo = items.length ? items[items.length - 1]!.position_key : '';
  } else if (afterItemId === null) {
    hi = items.length ? items[0]!.position_key : null;
  } else {
    const i = items.findIndex((x) => x.id === afterItemId);
    if (i < 0) throw badRequest('ops/after_item_id', '없는 항목');
    lo = items[i]!.position_key;
    hi = items[i + 1]?.position_key ?? null;
  }
  const keys: string[] = [];
  for (let k = 0; k < count; k++) {
    lo = keyBetween(lo, hi);
    keys.push(lo);
  }
  return keys;
}

// ── 조회 ─────────────────────────────────────────────────────────

export function listPlaylists(ctx: Ctx, p: Principal, q: { cursor?: string; limit: number; nameLike?: string }) {
  let after: [number, string] | null = null;
  if (q.cursor) {
    try {
      const c = JSON.parse(Buffer.from(q.cursor, 'base64url').toString('utf8'));
      if (c.s !== `pl${q.nameLike ?? ''}` || c.k.length !== 2) throw new Error();
      after = [Number(c.k[0]), String(c.k[1])];
    } catch {
      throw badRequest('cursor', '해석할 수 없는 커서');
    }
  }
  const rows = ctx.store.all<PlaylistRow>(
    `SELECT * FROM playlists WHERE owner_id = ? AND deleted_at IS NULL ${q.nameLike !== undefined ? "AND name_norm LIKE ? ESCAPE '\\'" : ''}
      ${after ? 'AND (-updated_at, id) > (?, ?)' : ''} ORDER BY -updated_at, id LIMIT ?`,
    p.user.id, ...(q.nameLike !== undefined ? [`%${q.nameLike.replace(/[\\%_]/g, (m) => `\\${m}`)}%`] : []), ...(after ? [-after[0], after[1]] : []), q.limit + 1);
  let next: string | null = null;
  if (rows.length > q.limit) {
    rows.length = q.limit;
    const last = rows[rows.length - 1]!;
    next = Buffer.from(JSON.stringify({ s: `pl${q.nameLike ?? ''}`, k: [last.updated_at, last.id] })).toString('base64url');
  }
  return { items: rows.map((r) => playlistDto(ctx, p, r)), next_cursor: next };
}

export function getPlaylist(ctx: Ctx, p: Principal, id: string) {
  const pl = load(ctx, p, id);
  return { dto: playlistDto(ctx, p, pl), etag: etagOf(pl) };
}

export function listItems(ctx: Ctx, p: Principal, id: string, q: { cursor?: string; limit: number }) {
  const pl = load(ctx, p, id);
  let after: [string, string] | null = null;
  if (q.cursor) {
    try {
      const c = JSON.parse(Buffer.from(q.cursor, 'base64url').toString('utf8'));
      if (c.s !== 'items' || c.p !== id || c.k.length !== 2) throw new Error();
      after = [String(c.k[0]), String(c.k[1])];
    } catch {
      throw badRequest('cursor', '해석할 수 없는 커서');
    }
  }
  const items = ctx.store.all<{ id: string; track_id: string; position_key: string; added_at: number }>(
    `SELECT id, track_id, position_key, added_at FROM playlist_items WHERE playlist_id = ? ${after ? 'AND (position_key, id) > (?, ?)' : ''}
      ORDER BY position_key, id LIMIT ?`, id, ...(after ?? []), q.limit + 1);
  let next: string | null = null;
  if (items.length > q.limit) {
    items.length = q.limit;
    const last = items[items.length - 1]!;
    next = Buffer.from(JSON.stringify({ s: 'items', p: id, k: [last.position_key, last.id] })).toString('base64url');
  }
  // 접근 권한이 사라졌거나 누락된 곡은 순서를 지키는 자리표시자로 (01장 §4.5)
  const ids = [...new Set(items.map((i) => i.track_id))];
  const visible = ids.length ? ctx.store.all<TrackRow>(
    `SELECT t.*, al.title AS album_title, m.container, m.codec, m.sample_rate, m.channels, m.bit_depth, m.bitrate
       FROM tracks t LEFT JOIN albums al ON al.id = t.album_id LEFT JOIN media_files m ON m.track_id = t.id
      WHERE t.id IN (${ids.map(() => '?').join(',')}) AND t.state = 'available' AND ${ACCESS}`, ...ids, ...accessParams(p)) : [];
  const dtos = new Map(trackDtos(ctx, visible).map((t) => [t.id, t]));
  return {
    page: {
      items: items.map((i) => {
        const t = dtos.get(i.track_id);
        return t ? { item_id: i.id, available: true, track: t, added_at: iso(i.added_at) } : { item_id: i.id, available: false, added_at: iso(i.added_at) };
      }),
      next_cursor: next,
      version: pl.version,
    },
    etag: etagOf(pl),
  };
}

// ── 수정 ─────────────────────────────────────────────────────────

export function createPlaylist(ctx: Ctx, p: Principal, body: { name: string; description?: string; track_ids?: string[] }) {
  checkTracks(ctx, p, body.track_ids ?? []);
  const id = newId('playlist');
  const now = Date.now();
  ctx.store.tx(() => {
    ctx.store.run('INSERT INTO playlists (id, owner_id, name, name_norm, description, version, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 1, ?, ?)',
      id, p.user.id, body.name, norm(body.name), body.description ?? null, now, now);
    const keys = insertKeys([], undefined, body.track_ids?.length ?? 0);
    body.track_ids?.forEach((t, i) => ctx.store.run('INSERT INTO playlist_items (id, playlist_id, track_id, position_key, added_at) VALUES (?, ?, ?, ?, ?)',
      newId('playlistItem'), id, t, keys[i]!, now));
  });
  return getPlaylist(ctx, p, id);
}

export function updatePlaylist(ctx: Ctx, p: Principal, id: string, ifMatch: string | undefined, body: { name?: string; description?: string }) {
  const pl = load(ctx, p, id);
  checkVersion(pl, ifMatch);
  ctx.store.tx(() => {
    if (body.name !== undefined) ctx.store.run('UPDATE playlists SET name = ?, name_norm = ? WHERE id = ?', body.name, norm(body.name), id);
    if (body.description !== undefined) ctx.store.run('UPDATE playlists SET description = ? WHERE id = ?', body.description, id);
    touch(ctx, id);
  });
  return getPlaylist(ctx, p, id);
}

export function deletePlaylist(ctx: Ctx, p: Principal, id: string) {
  const pl = ctx.store.get<PlaylistRow & { deleted_at: number | null }>('SELECT * FROM playlists WHERE id = ?', id);
  if (!pl || pl.owner_id !== p.user.id) throw notFound();
  if (pl.deleted_at !== null) return; // 멱등
  ctx.store.tx(() => {
    ctx.store.run('DELETE FROM playlist_items WHERE playlist_id = ?', id);
    ctx.store.run('UPDATE playlists SET deleted_at = ?, version = version + 1 WHERE id = ?', Date.now(), id);
  });
}

type EditOp =
  | { op: 'add'; track_ids: string[]; after_item_id?: string | null }
  | { op: 'remove'; item_ids: string[] }
  | { op: 'move'; item_id: string; after_item_id: string | null };

/** 연산 전체를 원자적으로 적용한다. 하나라도 틀리면 아무것도 바뀌지 않는다. */
export function editPlaylist(ctx: Ctx, p: Principal, id: string, ifMatch: string | undefined, ops: EditOp[]) {
  const pl = load(ctx, p, id);
  checkVersion(pl, ifMatch);
  for (const op of ops) if (op.op === 'add') checkTracks(ctx, p, op.track_ids);
  const now = Date.now();
  ctx.store.tx(() => {
    for (const op of ops) {
      const items = orderedKeys(ctx, id);
      if (op.op === 'add') {
        const keys = insertKeys(items, 'after_item_id' in op ? op.after_item_id : undefined, op.track_ids.length);
        op.track_ids.forEach((t, i) => ctx.store.run('INSERT INTO playlist_items (id, playlist_id, track_id, position_key, added_at) VALUES (?, ?, ?, ?, ?)',
          newId('playlistItem'), id, t, keys[i]!, now));
      } else if (op.op === 'remove') {
        for (const itemId of op.item_ids) {
          if (!items.some((x) => x.id === itemId)) throw badRequest('ops/item_ids', '없는 항목');
          ctx.store.run('DELETE FROM playlist_items WHERE id = ?', itemId);
        }
      } else {
        if (!items.some((x) => x.id === op.item_id)) throw badRequest('ops/item_id', '없는 항목');
        if (op.after_item_id === op.item_id) throw badRequest('ops/after_item_id', '자기 자신 뒤로 옮길 수 없다');
        const rest = items.filter((x) => x.id !== op.item_id);
        const [key] = insertKeys(rest, op.after_item_id, 1);
        ctx.store.run('UPDATE playlist_items SET position_key = ? WHERE id = ?', key!, op.item_id);
      }
    }
    touch(ctx, id);
  });
  return getPlaylist(ctx, p, id);
}

export function setCover(ctx: Ctx, p: Principal, id: string, ifMatch: string | undefined, artworkId: string | null) {
  const pl = load(ctx, p, id);
  if (artworkId !== null) checkVersion(pl, ifMatch, 'validation'); // 계약상 표지 업로드에는 428이 없다
  ctx.store.tx(() => {
    ctx.store.run('UPDATE playlists SET artwork_id = ? WHERE id = ?', artworkId, id);
    touch(ctx, id);
  });
  return getPlaylist(ctx, p, id);
}

/** 업로드 전에 버전·소유를 확인한다(디코딩 비용을 쓰기 전에) */
export function assertCoverWritable(ctx: Ctx, p: Principal, id: string, ifMatch: string | undefined) {
  checkVersion(load(ctx, p, id), ifMatch, 'validation');
}
