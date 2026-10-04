// 렌디션 결정과 Range 제공 (02장 §5, 03장 §4.1~4.2).
// 렌디션은 불변이다. 원본이 바뀌면(미디어 버전 변경) 옛 렌디션은 410 rendition_superseded.
// 기기가 원본을 재생할 수 있으면 원본, 아니면 변환본(aac_256/aac_128, transcode.ts).
import { existsSync, promises as fsp } from 'node:fs';
import type { FastifyReply } from 'fastify';
import { issueTicket } from '../auth/tickets.ts';
import type { Principal } from '../auth/sessions.ts';
import { getTrackRow } from '../catalog/catalog.ts';
import type { Ctx } from '../ctx.ts';
import { ApiError, badRequest, notFound } from '../http/problem.ts';
import { newId } from '../ids.ts';
import { checkRoot, FileMissing, openFile, PathRejected, rootLooksEmpty, StorageUnavailable, type LibraryRow } from '../scanner/paths.ts';
import { admit, cacheFile, holdCache, PROFILES, profileNames } from './transcode.ts';

export interface RenditionRow {
  id: string;
  track_id: string;
  media_version: string;
  profile: string;
  state: 'ready' | 'preparing' | 'failed';
  mime: string | null;
  container: string | null;
  codec: string | null;
  size_bytes: number | null;
  duration_ms: number | null;
  sha256: string | null;
  cache_ref: string | null;
  error_code: string | null;
}

interface FormatSpec {
  container: string;
  codec: string;
  max_sample_rate?: number;
  max_bit_depth?: number;
}

const iso = (ms: number) => new Date(ms).toISOString().replace(/\.\d{3}Z$/, 'Z');
export const etagOf = (r: Pick<RenditionRow, 'media_version' | 'profile'>) => `"${r.media_version}-${r.profile}"`;


interface MediaFileRow {
  container: string;
  codec: string;
  mime: string;
  sample_rate: number | null;
  bit_depth: number | null;
  bitrate: number | null;
  size_bytes: number;
  mtime_ns: string;
  content_hash: string;
  rel_path: string;
  library_id: string;
}

function mediaFile(ctx: Ctx, trackId: string) {
  return ctx.store.get<MediaFileRow>('SELECT * FROM media_files WHERE track_id = ?', trackId);
}

function accepts(accept: FormatSpec[], m: { container: string; codec: string; sample_rate: number | null; bit_depth: number | null }): boolean {
  return accept.some((f) =>
    f.container.toLowerCase() === m.container && f.codec.toLowerCase() === m.codec &&
    (!f.max_sample_rate || !m.sample_rate || m.sample_rate <= f.max_sample_rate) &&
    (!f.max_bit_depth || !m.bit_depth || m.bit_depth <= f.max_bit_depth));
}

export function renditionDto(ctx: Ctx, p: Principal, r: RenditionRow) {
  const base = {
    id: r.id,
    track_id: r.track_id,
    media_version: r.media_version,
    profile: r.profile,
    state: r.state,
    ...(r.mime ? { mime: r.mime, container: r.container!, codec: r.codec! } : {}),
    error_code: r.error_code,
  };
  if (r.state !== 'ready') return { ...base, retry_after_s: r.state === 'preparing' ? 2 : null };
  const t = issueTicket(ctx, p, r.id);
  return {
    ...base,
    size_bytes: r.size_bytes!,
    duration_ms: r.duration_ms!,
    sha256: r.sha256,
    etag: etagOf(r),
    seekable: true,
    media_url: `/v1/media/${r.id}?mt=${t.ticket}`,
    ticket_expires_at: iso(t.expiresAt),
    retry_after_s: null,
  };
}

function libraryOf(ctx: Ctx, libraryId: string) {
  return ctx.store.get<LibraryRow>('SELECT * FROM libraries WHERE id = ?', libraryId)!;
}

/**
 * 사용 불가로 표시된 라이브러리는 요청이 올 때 루트를 다시 본다 (01장 §4.4 자동 복구).
 * 루트가 정상(등록 때와 같은 실제 경로, 비어 있지 않음)이면 online으로 되돌리고 스캔을 예약한다. 아니면 503.
 */
function ensureOnline(ctx: Ctx, lib: LibraryRow): void {
  if (lib.status !== 'unavailable') return;
  try {
    if (rootLooksEmpty(checkRoot(lib))) throw new StorageUnavailable('루트가 비어 있음');
  } catch {
    throw new ApiError(503, 'storage_unavailable', { headers: { 'retry-after': '30' } });
  }
  ctx.store.run("UPDATE libraries SET status = 'online' WHERE id = ? AND status = 'unavailable'", lib.id);
  ctx.log.info({ library_id: lib.id }, '저장소 복구 감지 — 라이브러리를 다시 사용, 스캔 예약');
  ctx.jobs.enqueue('scan', lib.id);
}

const LOSSY = new Set(['mp3', 'aac', 'opus', 'vorbis']);
const TRANSCODED = { container: 'm4a', codec: 'aac', sample_rate: 48_000, bit_depth: null };

export interface ResolveResult {
  status: 200 | 202;
  body: ReturnType<typeof renditionDto>;
  headers: Record<string, string>;
}

/**
 * 제공 형식 결정 (02장 §5, 03장 §4.5).
 * - 원본을 재생할 수 있고 quality=original → 원본
 * - quality가 변환 프로파일이어도 원본이 손실 압축이고 비트레이트가 더 낮으면 원본(손실 원본을 더 큰 손실본으로 다시 인코딩하지 않는다)
 * - 그 외 변환: 캐시에 있으면 200, 없으면 작업을 넣고 202 + Retry-After
 */
export function resolveRendition(ctx: Ctx, p: Principal, trackId: string, req: { purpose: string; quality: string; accept: FormatSpec[] }): ResolveResult {
  const track = getTrackRow(ctx, p, trackId); // 권한 없으면 404
  const profiles = profileNames(ctx);
  if (req.quality !== 'original' && !profiles.includes(req.quality)) throw badRequest('quality', '지원하지 않는 품질');
  ensureOnline(ctx, libraryOf(ctx, track.library_id));
  if (track.state === 'missing') throw new ApiError(404, 'media_missing');
  const m = mediaFile(ctx, trackId);
  if (!m) throw new ApiError(404, 'media_missing');

  const originalOk = accepts(req.accept, m);
  const target = req.quality === 'original' ? 'aac_256' : req.quality;
  const keepOriginal = originalOk && (req.quality === 'original' ||
    (LOSSY.has(m.codec) && m.bitrate !== null && m.bitrate <= PROFILES[target]!.bitrate));
  if (keepOriginal) {
    ctx.store.run(
      `INSERT OR IGNORE INTO renditions (id, track_id, media_version, profile, state, mime, container, codec, size_bytes, duration_ms, sha256, cache_ref, created_at)
       VALUES (?, ?, ?, 'original', 'ready', ?, ?, ?, ?, ?, ?, NULL, ?)`,
      newId('rendition'), trackId, track.media_version, m.mime, m.container, m.codec, m.size_bytes, track.duration_ms, m.content_hash, Date.now());
    const r = ctx.store.get<RenditionRow>("SELECT * FROM renditions WHERE track_id = ? AND media_version = ? AND profile = 'original'", trackId, track.media_version)!;
    return { status: 200, body: renditionDto(ctx, p, r), headers: {} };
  }
  // 변환이 꺼져 있거나 기기가 변환 형식(AAC/M4A)도 재생하지 못하면 방법이 없다
  if (!ctx.config.transcodeEnabled || !accepts(req.accept, TRANSCODED)) throw new ApiError(422, 'no_playable_format');

  const priority = req.purpose === 'stream' ? 1 : 0; // stream 작업이 download보다 먼저 (03장 §4.6)
  const existing = ctx.store.get<RenditionRow>('SELECT * FROM renditions WHERE track_id = ? AND media_version = ? AND profile = ?', trackId, track.media_version, target);
  if (existing?.state === 'ready' && existing.cache_ref && !existsSync(cacheFile(ctx, existing.cache_ref))) {
    ctx.store.run('DELETE FROM renditions WHERE id = ?', existing.id); // 정리된 변환본 → 새로 만든다
    return resolveRendition(ctx, p, trackId, req);
  }
  if (existing?.state === 'ready') return { status: 200, body: renditionDto(ctx, p, existing), headers: {} };
  if (existing?.state === 'preparing') {
    ctx.jobs.enqueue('transcode', existing.id, priority); // 같은 작업이면 우선순위만 올린다
    return { status: 202, body: renditionDto(ctx, p, existing), headers: { 'retry-after': '2' } };
  }
  const verdict = admit(ctx);
  if (verdict !== 'ok') throw new ApiError(429, 'transcode_queue_full', { headers: { 'retry-after': verdict === 'queue_full' ? '10' : '60' } });
  let id: string;
  if (existing) {
    // 실패했던 변환은 다시 요청할 때 한 번 더 시도한다
    id = existing.id;
    ctx.store.run("UPDATE renditions SET state = 'preparing', error_code = NULL WHERE id = ?", id);
  } else {
    id = newId('rendition');
    ctx.store.run("INSERT INTO renditions (id, track_id, media_version, profile, state, created_at) VALUES (?, ?, ?, ?, 'preparing', ?)",
      id, trackId, track.media_version, target, Date.now());
  }
  ctx.jobs.enqueue('transcode', id, priority);
  const r = ctx.store.get<RenditionRow>('SELECT * FROM renditions WHERE id = ?', id)!;
  return { status: r.state === 'ready' ? 200 : 202, body: renditionDto(ctx, p, r), headers: r.state === 'ready' ? {} : { 'retry-after': '2' } };
}

/** 렌디션 + 권한 + 최신 여부 확인. 원본이 바뀌었으면 410. */
export function loadRendition(ctx: Ctx, p: Principal, renditionId: string) {
  const r = ctx.store.get<RenditionRow>('SELECT * FROM renditions WHERE id = ?', renditionId);
  if (!r) throw notFound();
  const track = getTrackRow(ctx, p, r.track_id); // 권한 회수 시 404
  if (track.media_version !== r.media_version) throw new ApiError(410, 'rendition_superseded');
  // 캐시 정리로 변환 파일이 사라졌으면 410 → 앱이 다시 결정한다(재변환)
  if (r.cache_ref && r.state === 'ready' && !existsSync(cacheFile(ctx, r.cache_ref))) {
    ctx.store.run('DELETE FROM renditions WHERE id = ?', r.id);
    throw new ApiError(410, 'rendition_superseded');
  }
  return { r, track };
}

export function getRendition(ctx: Ctx, p: Principal, renditionId: string) {
  return renditionDto(ctx, p, loadRendition(ctx, p, renditionId).r);
}

// ── Range ────────────────────────────────────────────────────────

/** 단일 범위만. 여러 범위·형식 오류는 null(→ 200 전체). 범위 밖은 'unsatisfiable'. */
export function parseRange(header: string | undefined, size: number): { start: number; end: number } | null | 'unsatisfiable' {
  if (!header) return null;
  const m = /^bytes=(\d*)-(\d*)$/.exec(header.trim());
  if (!m || (m[1] === '' && m[2] === '')) return null;
  if (m[1] === '') {
    const n = Number(m[2]);
    if (n === 0) return 'unsatisfiable';
    return { start: Math.max(0, size - n), end: size - 1 };
  }
  const start = Number(m[1]);
  const end = m[2] === '' ? size - 1 : Math.min(Number(m[2]), size - 1);
  if (start >= size || (m[2] !== '' && Number(m[2]) < start)) return 'unsatisfiable';
  return { start, end };
}

export async function serveMedia(ctx: Ctx, p: Principal, renditionId: string, reply: FastifyReply, head: boolean, range: string | undefined, ifRange: string | undefined) {
  const { r, track } = loadRendition(ctx, p, renditionId);
  if (r.state === 'preparing') throw new ApiError(409, 'rendition_not_ready', { headers: { 'retry-after': '2' } });
  if (r.state !== 'ready') throw new ApiError(404, 'media_missing');
  if (r.cache_ref) return serveCached(ctx, r, reply, head, range, ifRange);
  if (track.state === 'missing') throw new ApiError(404, 'media_missing');
  const m = mediaFile(ctx, r.track_id);
  if (!m) throw new ApiError(404, 'media_missing');
  const lib = libraryOf(ctx, m.library_id);

  let opened;
  try {
    opened = await openFile(lib, m.rel_path);
  } catch (e) {
    if (e instanceof StorageUnavailable) {
      ctx.log.warn({ library_id: lib.id, err: e.message }, '미디어 요청: 저장소 사용 불가');
      throw new ApiError(503, 'storage_unavailable', { headers: { 'retry-after': '30' } });
    }
    if (e instanceof FileMissing || e instanceof PathRejected) {
      // SEC-03: 루트 밖으로 바뀐 링크도 같은 응답. 경로는 로그에만.
      ctx.log.warn({ library_id: lib.id, track_id: r.track_id, err: e.message }, '미디어 요청: 원본 파일을 쓸 수 없음');
      ctx.jobs.enqueue('scan', lib.id);
      throw new ApiError(404, 'media_missing');
    }
    throw e;
  }
  // 03장 §4.2: fstat 결과가 DB와 다르면 응답을 시작하지 않고 원본 변경으로 처리한다.
  if (opened.size !== m.size_bytes || opened.mtimeNs !== m.mtime_ns || opened.size !== r.size_bytes) {
    await opened.handle.close();
    ctx.log.info({ track_id: r.track_id }, '원본 변경 감지 — 재스캔 예약');
    ctx.jobs.enqueue('scan', lib.id);
    throw new ApiError(410, 'rendition_superseded');
  }

  return sendBytes(ctx, r, reply, head, range, ifRange, opened.handle, opened.size, String(r.duration_ms ?? track.duration_ms), () => {});
}

/** 변환본: 캐시 파일. 파일이 없어졌으면(정리됨) 410 → 앱이 다시 결정한다. */
async function serveCached(ctx: Ctx, r: RenditionRow, reply: FastifyReply, head: boolean, range: string | undefined, ifRange: string | undefined) {
  const release = holdCache(r.cache_ref!);
  let handle: fsp.FileHandle;
  try {
    handle = await fsp.open(cacheFile(ctx, r.cache_ref!), 'r');
  } catch {
    release();
    ctx.store.run('DELETE FROM renditions WHERE id = ?', r.id);
    throw new ApiError(410, 'rendition_superseded');
  }
  const st = await handle.stat();
  if (st.size !== r.size_bytes) {
    await handle.close();
    release();
    ctx.log.error({ rendition_id: r.id }, '변환 캐시 크기 불일치 — 렌디션 폐기');
    ctx.store.run('DELETE FROM renditions WHERE id = ?', r.id);
    throw new ApiError(410, 'rendition_superseded');
  }
  return sendBytes(ctx, r, reply, head, range, ifRange, handle, st.size, String(r.duration_ms), release);
}

async function sendBytes(ctx: Ctx, r: RenditionRow, reply: FastifyReply, head: boolean, range: string | undefined, ifRange: string | undefined,
  handle: fsp.FileHandle, size: number, durationMs: string, release: () => void) {
  const etag = etagOf(r);

  let rangeSpec = ifRange && ifRange !== etag ? null : parseRange(range, size);
  if (head) rangeSpec = null;
  if (rangeSpec === 'unsatisfiable') {
    await handle.close();
    release();
    // 오류 응답에는 불변 캐시 헤더를 붙이지 않는다
    throw new ApiError(416, 'range_not_satisfiable', { headers: { 'content-range': `bytes */${size}`, 'accept-ranges': 'bytes' } });
  }
  reply.header('accept-ranges', 'bytes');
  reply.header('etag', etag);
  reply.header('content-type', r.mime ?? 'application/octet-stream');
  reply.header('cache-control', 'private, no-transform, max-age=31536000, immutable');
  reply.header('x-content-duration-ms', durationMs);
  const start = rangeSpec ? rangeSpec.start : 0;
  const end = rangeSpec ? rangeSpec.end : size - 1;
  const length = size === 0 ? 0 : end - start + 1;
  if (rangeSpec) {
    reply.code(206);
    reply.header('content-range', `bytes ${start}-${end}/${size}`);
  } else {
    reply.code(200);
  }
  reply.header('content-length', String(length));
  ctx.store.run('UPDATE renditions SET last_access_at = ? WHERE id = ?', Date.now(), r.id);

  if (head || length === 0) {
    await handle.close();
    release();
    return reply.send();
  }
  const stream = handle.createReadStream({ start, end, autoClose: true });
  stream.on('close', release);
  // 응답 도중 읽기 오류가 나면 연결을 끊는다(잘린 본문을 정상 종료로 보내지 않는다).
  stream.on('error', (e) => {
    ctx.log.error({ track_id: r.track_id, err: e.message }, '미디어 전송 중 읽기 오류 — 연결 종료');
    reply.raw.destroy(e);
  });
  return reply.send(stream);
}
