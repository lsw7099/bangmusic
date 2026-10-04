// 변환 (03장 §4.5~4.6). AAC-LC / M4A, 스테레오, 48kHz 초과는 48kHz. 태그·표지는 넣지 않는다.
// 파일 전체를 먼저 만들어 캐시에 두고 Range로 제공한다. 캐시 쓰기 순서:
// /cache/tmp/<job>.part → fsync → 크기·SHA-256·길이 측정 → /cache/renditions/<rid>.m4a로 rename → DB ready.
// 이 순서 때문에 불완전한 변환본이 제공되는 일은 없다.
import { createHash } from 'node:crypto';
import { createReadStream, existsSync, mkdirSync, promises as fsp, readdirSync, rmSync, statfsSync } from 'node:fs';
import { join } from 'node:path';
import type { Ctx } from '../ctx.ts';
import { JobError } from '../jobs.ts';
import { FileMissing, PathRejected, resolveFile, StorageUnavailable, type LibraryRow } from '../scanner/paths.ts';
import { run } from '../scanner/probe.ts';

export const PROFILES: Record<string, { bitrate: number }> = {
  aac_256: { bitrate: 256_000 },
  aac_128: { bitrate: 128_000 },
};

export const profileNames = (ctx: Ctx) => (ctx.config.transcodeEnabled ? Object.keys(PROFILES) : []);

const tmpDir = (ctx: Ctx) => join(ctx.config.cacheDir, 'tmp');
export const renditionDir = (ctx: Ctx) => join(ctx.config.cacheDir, 'renditions');
export const cacheFile = (ctx: Ctx, ref: string) => join(renditionDir(ctx), ref);

/** 응답 중인 캐시 파일 (정리에서 제외) */
const openRefs = new Map<string, number>();
export function holdCache(ref: string): () => void {
  openRefs.set(ref, (openRefs.get(ref) ?? 0) + 1);
  let released = false;
  return () => {
    if (released) return;
    released = true;
    const n = (openRefs.get(ref) ?? 1) - 1;
    if (n <= 0) openRefs.delete(ref);
    else openRefs.set(ref, n);
  };
}

function freeBytes(dir: string): number {
  try {
    const s = statfsSync(dir);
    return Number(s.bavail) * Number(s.bsize);
  } catch {
    return Number.MAX_SAFE_INTEGER; // 알 수 없으면 막지 않는다
  }
}

/** 기동 시: tmp 비우기, ready인데 파일이 없는 변환 렌디션 삭제 (03장 §4.6) */
export function recoverCache(ctx: Ctx) {
  rmSync(tmpDir(ctx), { recursive: true, force: true });
  mkdirSync(tmpDir(ctx), { recursive: true });
  mkdirSync(renditionDir(ctx), { recursive: true });
  const rows = ctx.store.all<{ id: string; cache_ref: string }>("SELECT id, cache_ref FROM renditions WHERE cache_ref IS NOT NULL AND state = 'ready'");
  let removed = 0;
  for (const r of rows) {
    if (!existsSync(cacheFile(ctx, r.cache_ref))) {
      ctx.store.run('DELETE FROM renditions WHERE id = ?', r.id);
      removed++;
    }
  }
  // 작업 없이 preparing으로 남은 행(작업 기록 손실)은 다시 대기열에
  for (const r of ctx.store.all<{ id: string }>(
    "SELECT id FROM renditions WHERE state = 'preparing' AND id NOT IN (SELECT ref_id FROM jobs WHERE type = 'transcode' AND state IN ('queued', 'running'))")) {
    ctx.jobs.enqueue('transcode', r.id, 0);
  }
  if (removed) ctx.log.info({ removed }, '캐시 파일이 없는 변환 렌디션 정리');
}

/** 새 변환을 받아도 되는지. 아니면 그 이유 */
export function admit(ctx: Ctx): 'ok' | 'queue_full' | 'no_space' {
  if (ctx.jobs.pending('transcode') >= ctx.config.transcodeQueueMax) return 'queue_full';
  if (freeBytes(ctx.config.cacheDir) < ctx.config.cacheMinFreeBytes) {
    evict(ctx, 0);
    if (freeBytes(ctx.config.cacheDir) < ctx.config.cacheMinFreeBytes) return 'no_space';
  }
  return 'ok';
}

/**
 * 캐시 한도 유지. 원본이 바뀌어 쓸모없어진 변환본을 먼저, 그다음 오래 안 쓴 것부터 지운다.
 * 응답 중인 파일은 건너뛴다. extraBytes = 곧 쓸 크기.
 */
export function evict(ctx: Ctx, extraBytes: number) {
  const rows = ctx.store.all<{ id: string; cache_ref: string; size_bytes: number; stale: number }>(
    `SELECT r.id, r.cache_ref, r.size_bytes, (r.media_version != t.media_version) AS stale
       FROM renditions r JOIN tracks t ON t.id = r.track_id
      WHERE r.cache_ref IS NOT NULL AND r.state = 'ready'
      ORDER BY stale DESC, COALESCE(r.last_access_at, r.created_at)`);
  // 파일만 지우고 행은 남긴다: 다음 요청이 410 rendition_superseded를 받아 다시 결정하게 (02장 §5)
  const present = rows.filter((r) => existsSync(cacheFile(ctx, r.cache_ref)));
  let total = present.reduce((s, r) => s + Number(r.size_bytes), 0) + extraBytes;
  for (const r of present) {
    if (total <= ctx.config.cacheMaxBytes && !r.stale) break;
    if (openRefs.has(r.cache_ref)) continue;
    rmSync(cacheFile(ctx, r.cache_ref), { force: true });
    total -= Number(r.size_bytes);
  }
}

function sha256File(file: string): Promise<string> {
  return new Promise((ok, fail) => {
    const h = createHash('sha256');
    createReadStream(file).on('data', (d) => h.update(d)).on('error', fail).on('end', () => ok(h.digest('hex')));
  });
}

interface RenditionJobRow {
  id: string;
  track_id: string;
  media_version: string;
  profile: string;
  state: string;
}

export function registerTranscodeJob(ctx: Ctx) {
  ctx.jobs.register('transcode', async (job) => {
    const r = ctx.store.get<RenditionJobRow>('SELECT id, track_id, media_version, profile, state FROM renditions WHERE id = ?', job.ref_id);
    if (!r || r.state === 'ready') return;
    try {
      await transcode(ctx, r, job.id);
    } catch (e) {
      const code = e instanceof JobError ? e.code : 'transcode_failed';
      ctx.store.run("UPDATE renditions SET state = 'failed', error_code = ? WHERE id = ?", code, r.id);
      throw e instanceof JobError ? e : new JobError('transcode_failed', (e as Error).message);
    }
  }, ctx.config.transcodeConcurrency);
}

async function transcode(ctx: Ctx, r: RenditionJobRow, jobId: string) {
  const profile = PROFILES[r.profile];
  if (!profile) throw new JobError('unsupported_source', `알 수 없는 프로파일 ${r.profile}`);
  const track = ctx.store.get<{ media_version: string }>('SELECT media_version FROM tracks WHERE id = ?', r.track_id);
  if (!track || track.media_version !== r.media_version) {
    ctx.store.run('DELETE FROM renditions WHERE id = ?', r.id); // 원본이 이미 바뀜 — 앱은 410을 받고 다시 결정한다
    return;
  }
  const m = ctx.store.get<{ library_id: string; rel_path: string; size_bytes: number; sample_rate: number | null }>(
    'SELECT library_id, rel_path, size_bytes, sample_rate FROM media_files WHERE track_id = ?', r.track_id);
  if (!m) throw new JobError('media_missing', '원본 매핑 없음');
  const lib = ctx.store.get<LibraryRow>('SELECT * FROM libraries WHERE id = ?', m.library_id)!;

  // 입력 경로는 경로 해석기가 준 값만 (03장 §4.6)
  let source: string;
  try {
    source = await resolveFile(lib, m.rel_path);
    if ((await fsp.stat(source)).size !== m.size_bytes) throw new JobError('media_missing', '원본이 바뀜 — 재스캔 필요');
  } catch (e) {
    if (e instanceof JobError) throw e;
    if (e instanceof StorageUnavailable) throw new JobError('storage_unavailable', e.message);
    if (e instanceof FileMissing || e instanceof PathRejected) throw new JobError('media_missing', e.message);
    throw e;
  }

  mkdirSync(tmpDir(ctx), { recursive: true });
  mkdirSync(renditionDir(ctx), { recursive: true });
  const tmp = join(tmpDir(ctx), `${jobId}.part.m4a`);
  const rate = Math.min(m.sample_rate ?? 48_000, 48_000);
  const res = await run(ctx.config.ffmpeg, [
    '-nostdin', '-v', 'error', '-protocol_whitelist', 'file', '-i', source,
    '-map', '0:a:0', '-vn', '-sn', '-dn', '-map_metadata', '-1', '-map_chapters', '-1',
    '-c:a', 'aac', '-b:a', String(profile.bitrate), '-ac', '2', '-ar', String(rate),
    '-movflags', '+faststart', '-f', 'mp4', '-y', tmp,
  ], { timeoutMs: ctx.config.transcodeTimeoutMs, lowPriority: true });
  if (res.timedOut || res.code !== 0) {
    rmSync(tmp, { force: true });
    throw new JobError('transcode_failed', res.timedOut ? '변환 시간 초과' : `ffmpeg 실패: ${res.stderr.slice(0, 200)}`);
  }
  const fh = await fsp.open(tmp, 'r+');
  await fh.sync();
  await fh.close();
  const size = (await fsp.stat(tmp)).size;
  const sha = await sha256File(tmp);
  const probe = await run(ctx.config.ffprobe, ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', '-i', tmp], { timeoutMs: 30_000 });
  const durationMs = Math.round(Number.parseFloat(probe.stdout.toString()) * 1000);
  if (!Number.isFinite(durationMs) || durationMs <= 0 || size === 0) {
    rmSync(tmp, { force: true });
    throw new JobError('transcode_failed', '변환 결과를 확인하지 못함');
  }
  evict(ctx, size);
  const ref = `${r.id}.m4a`;
  await fsp.rename(tmp, cacheFile(ctx, ref));
  ctx.store.run(`UPDATE renditions SET state = 'ready', mime = 'audio/mp4', container = 'm4a', codec = 'aac', size_bytes = ?, duration_ms = ?,
      sha256 = ?, cache_ref = ?, error_code = NULL WHERE id = ?`, size, durationMs, sha, ref, r.id);
}

/** 테스트·운영 확인용: 캐시 폴더의 렌디션 파일 목록 */
export function cachedFiles(ctx: Ctx): string[] {
  try {
    return readdirSync(renditionDir(ctx));
  } catch {
    return [];
  }
}
