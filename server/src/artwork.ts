// 표지 (01장 §4.2 artworks). 원본 이미지 바이트의 해시로 중복을 없애고,
// 긴 변 1024px 이하의 JPEG 마스터를 /data/artwork에 둔다. 작은 크기는 요청 시 /cache/artwork에 만든다.
// 음악 원본 경로에는 쓰지 않는다. 표지 응답은 원본 파일을 다시 읽지 않는다.
import { randomUUID } from 'node:crypto';
import { existsSync, mkdirSync, renameSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { sha256hex } from './auth/crypto.ts';
import type { Ctx } from './ctx.ts';
import { newId } from './ids.ts';
import { run } from './scanner/probe.ts';

export const ARTWORK_SIZES = [96, 256, 512, 1024] as const;
const MASTER_MAX = 1024;
const MAX_SOURCE_BYTES = 32 * 1024 * 1024;
/** 디코딩 전에 확인하는 최대 픽셀 수 (압축 폭탄 방지, SEC-13). 6000×6000 = 36MP는 허용 */
const MAX_PIXELS = 50_000_000;

export interface ArtworkRow {
  id: string;
  source: 'embedded' | 'folder' | 'upload';
  content_hash: string;
  mime: string;
  width: number;
  height: number;
  storage_ref: string;
}

const artworkDir = (ctx: Ctx) => join(ctx.config.dataDir, 'artwork');
const thumbDir = (ctx: Ctx) => join(ctx.config.cacheDir, 'artwork');

/** 음원에 내장된 표지의 원본 바이트 */
export async function extractEmbedded(ctx: Ctx, file: string): Promise<Buffer | null> {
  const r = await run(ctx.config.ffmpeg, ['-nostdin', '-v', 'error', '-protocol_whitelist', 'file,pipe', '-i', file, '-map', '0:v:0', '-c', 'copy', '-frames:v', '1', '-f', 'image2pipe', '-'],
    { timeoutMs: 30_000, maxOut: MAX_SOURCE_BYTES });
  return r.code === 0 && r.stdout.length > 0 ? r.stdout : null;
}

async function imageSize(ctx: Ctx, file: string): Promise<{ width: number; height: number } | null> {
  const r = await run(ctx.config.ffprobe, ['-v', 'error', '-select_streams', 'v:0', '-show_entries', 'stream=width,height', '-of', 'csv=p=0:s=x', '-i', file], { timeoutMs: 15_000 });
  const m = /^(\d+)x(\d+)/.exec(r.stdout.toString().trim());
  return r.code === 0 && m ? { width: Number(m[1]), height: Number(m[2]) } : null;
}

/** 이미지 바이트를 등록하고 표지 ID를 돌려준다. 디코딩에 실패하면 null (스캔은 계속). */
export async function ingestArtwork(ctx: Ctx, bytes: Buffer, source: ArtworkRow['source']): Promise<string | null> {
  if (bytes.length === 0 || bytes.length > MAX_SOURCE_BYTES) return null;
  const hash = sha256hex(bytes);
  const existing = ctx.store.get<{ id: string }>('SELECT id FROM artworks WHERE content_hash = ?', hash);
  if (existing) return existing.id;

  // 헤더만 읽어 크기를 확인하고, 너무 크면 디코딩하지 않는다
  const dims = await run(ctx.config.ffprobe, ['-v', 'error', '-protocol_whitelist', 'pipe', '-f', 'image2pipe', '-i', 'pipe:0', '-select_streams', 'v:0',
    '-show_entries', 'stream=width,height', '-of', 'csv=p=0:s=x'], { input: bytes, timeoutMs: 15_000 });
  const dm = /^(\d+)x(\d+)/.exec(dims.stdout.toString().trim());
  if (dims.code !== 0 || !dm || Number(dm[1]) * Number(dm[2]) > MAX_PIXELS || Number(dm[1]) === 0) {
    ctx.log.warn({ hash, source, dims: dm?.[0] ?? null }, '표지 이미지 거부(해석 불가 또는 픽셀 수 초과)');
    return null;
  }

  const dir = artworkDir(ctx);
  mkdirSync(dir, { recursive: true });
  const ref = `${hash}.jpg`;
  const target = join(dir, ref);
  if (!existsSync(target)) {
    const tmp = join(dir, `.tmp-${randomUUID()}.jpg`);
    // 원본보다 키우지 않고 긴 변을 1024px 이하로. 메타데이터(EXIF 등)는 다시 인코딩하며 버린다.
    const r = await run(ctx.config.ffmpeg, [
      '-nostdin', '-v', 'error', '-protocol_whitelist', 'pipe', '-f', 'image2pipe', '-i', 'pipe:0',
      '-frames:v', '1', '-vf', `scale='min(${MASTER_MAX},iw)':'min(${MASTER_MAX},ih)':force_original_aspect_ratio=decrease`,
      '-map_metadata', '-1', '-q:v', '3', '-y', tmp,
    ], { input: bytes, timeoutMs: 60_000 });
    if (r.code !== 0) {
      ctx.log.warn({ hash, source }, '표지 이미지를 해석하지 못함');
      return null;
    }
    renameSync(tmp, target);
  }
  const size = await imageSize(ctx, target);
  if (!size) return null;
  const id = newId('artwork');
  ctx.store.run('INSERT OR IGNORE INTO artworks (id, source, content_hash, mime, width, height, storage_ref) VALUES (?, ?, ?, ?, ?, ?, ?)',
    id, source, hash, 'image/jpeg', size.width, size.height, ref);
  return ctx.store.get<{ id: string }>('SELECT id FROM artworks WHERE content_hash = ?', hash)!.id;
}

/** 만드는 중인 썸네일. 같은 표지·크기를 동시에 요청하면 한 번만 만든다. */
const inflight = new Map<string, Promise<string>>();

/** 요청 크기(긴 변)의 JPEG 파일 경로. 마스터보다 크면 마스터를 쓴다. */
export async function artworkFile(ctx: Ctx, art: ArtworkRow, size: number): Promise<string> {
  const master = join(artworkDir(ctx), art.storage_ref);
  if (size >= Math.max(art.width, art.height)) return master;
  const dir = thumbDir(ctx);
  const file = join(dir, `${art.id}-${size}.jpg`);
  if (existsSync(file)) return file;
  // 앱은 목록·화면이 같은 표지를 동시에 그린다. 같은 임시 이름을 쓰면 한쪽 rename이 실패했다(실기기에서 발견).
  let p = inflight.get(file);
  if (!p) {
    p = makeThumb(ctx, master, dir, file, size).finally(() => inflight.delete(file));
    inflight.set(file, p);
  }
  return p;
}

async function makeThumb(ctx: Ctx, master: string, dir: string, file: string, size: number): Promise<string> {
  mkdirSync(dir, { recursive: true });
  const tmp = join(dir, `.tmp-${randomUUID()}.jpg`); // 프로세스·요청마다 고유
  const r = await run(ctx.config.ffmpeg, [
    '-nostdin', '-v', 'error', '-protocol_whitelist', 'file', '-i', master, '-frames:v', '1',
    '-vf', `scale=${size}:${size}:force_original_aspect_ratio=decrease`, '-q:v', '4', '-y', tmp,
  ], { timeoutMs: 30_000 });
  if (r.code !== 0) {
    rmSync(tmp, { force: true });
    throw new Error('썸네일 생성 실패');
  }
  renameSync(tmp, file);
  return file;
}
