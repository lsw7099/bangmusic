// 라이브러리 스캔 (01장 §4.3~4.4).
// 1단계(분석): 파일 목록·태그·해시를 모으고 이동을 판정한다. DB를 바꾸지 않는다.
// 2단계(적용): 대량 누락 검사를 통과하면 한 트랜잭션씩 반영한다.
// 음악 원본에는 쓰지 않는다. 손상 파일은 그 파일만 실패로 기록하고 계속한다.
import { promises as fsp, readdirSync, realpathSync, statSync } from 'node:fs';
import { extname, join } from 'node:path';
import { extractEmbedded, ingestArtwork } from '../artwork.ts';
import { syncTrackLyrics } from '../lyrics/lyrics.ts';
import type { Ctx } from '../ctx.ts';
import { mediaVersion, newId } from '../ids.ts';
import { JobError } from '../jobs.ts';
import { norm, sortKey } from '../norm.ts';
import { checkRoot, isInside, rootLooksEmpty, StorageUnavailable, toRel, type LibraryRow } from './paths.ts';
import { audioFingerprint, fileSha256, probe, type ProbeResult } from './probe.ts';

const AUDIO_EXT = new Set(['mp3', 'flac', 'm4a', 'mp4', 'aac', 'ogg', 'oga', 'opus', 'wav', 'aif', 'aiff', 'wma', 'ape', 'wv', 'dsf', 'dff', 'mka']);
const FOLDER_COVERS = ['cover.jpg', 'cover.jpeg', 'cover.png', 'folder.jpg', 'folder.jpeg', 'folder.png', 'front.jpg', 'front.jpeg', 'front.png'];
const PROBE_CONCURRENCY = 4;

interface Walked {
  rel: string;
  abs: string;
  dirRel: string;
  size: number;
  mtimeNs: string;
}

interface ExistingRow {
  media_id: string;
  track_id: string;
  rel_path: string;
  size_bytes: number;
  mtime_ns: string;
  content_hash: string;
  audio_fingerprint: string | null;
  state: 'available' | 'missing';
}

interface Analyzed {
  file: Walked;
  probe: ProbeResult;
  hash: string;
  fingerprint: string | null;
}

export interface ScanSummary {
  files: number;
  added: number;
  updated: number;
  moved: number;
  missing: number;
  restored: number;
  errors: number;
  skippedLinks: number;
  pendingReview: boolean;
}

// ── 1단계: 파일 목록 ───────────────────────────────────────────────

function walk(ctx: Ctx, root: string) {
  const files: Walked[] = [];
  const covers = new Map<string, string>();
  const dirNames = new Map<string, Set<string>>();
  let skippedLinks = 0;
  const stack = [root];
  while (stack.length) {
    const dir = stack.pop()!;
    let entries;
    try {
      entries = readdirSync(dir, { withFileTypes: true });
    } catch (e) {
      ctx.log.warn({ dir, code: (e as NodeJS.ErrnoException).code }, '폴더를 읽지 못함');
      continue;
    }
    const dirRel = dir === root ? '' : toRel(root, dir);
    const coverHere: string[] = [];
    dirNames.set(dirRel, new Set(entries.filter((e) => !e.isDirectory()).map((e) => e.name.toLowerCase())));
    for (const ent of entries) {
      if (ent.name.startsWith('.')) continue;
      const abs = join(dir, ent.name);
      let isFile = ent.isFile();
      let isDir = ent.isDirectory();
      if (ent.isSymbolicLink()) {
        // SEC-02: 루트 밖을 가리키는 링크는 등록하지 않는다. 폴더 링크는 따라가지 않는다(순환·중복 방지).
        let real: string;
        try {
          real = realpathSync.native(abs);
        } catch {
          skippedLinks++;
          ctx.log.warn({ path: abs }, '끊어진 링크 — 건너뜀');
          continue;
        }
        if (!isInside(root, real)) {
          skippedLinks++;
          ctx.log.warn({ path: abs }, '라이브러리 루트 밖을 가리키는 링크 — 건너뜀');
          continue;
        }
        const st = statSync(real);
        if (st.isDirectory()) {
          skippedLinks++;
          ctx.log.warn({ path: abs }, '폴더 링크는 따라가지 않음 — 건너뜀');
          continue;
        }
        isFile = st.isFile();
        isDir = false;
      }
      if (isDir) {
        stack.push(abs);
        continue;
      }
      if (!isFile) continue;
      const lower = ent.name.toLowerCase();
      if (FOLDER_COVERS.includes(lower)) coverHere.push(abs);
      if (!AUDIO_EXT.has(extname(lower).slice(1))) continue;
      const st = statSync(abs, { bigint: true });
      files.push({ rel: toRel(root, abs), abs, dirRel, size: Number(st.size), mtimeNs: st.mtimeNs.toString() });
    }
    coverHere.sort((a, b) => FOLDER_COVERS.indexOf(a.split(/[\\/]/).pop()!.toLowerCase()) - FOLDER_COVERS.indexOf(b.split(/[\\/]/).pop()!.toLowerCase()));
    if (coverHere[0]) covers.set(dirRel, coverHere[0]);
  }
  files.sort((a, b) => a.rel.localeCompare(b.rel));
  return { files, covers, dirNames, skippedLinks };
}

async function pool<T, R>(items: T[], n: number, fn: (t: T) => Promise<R>): Promise<R[]> {
  const out = new Array<R>(items.length);
  let next = 0;
  await Promise.all(Array.from({ length: Math.min(n, items.length) }, async () => {
    while (next < items.length) {
      const i = next++;
      out[i] = await fn(items[i]!);
    }
  }));
  return out;
}

// ── 2단계: 적용 ────────────────────────────────────────────────────

function parseNo(v: string | undefined): number | null {
  const n = Number.parseInt((v ?? '').split('/')[0]!, 10);
  return Number.isFinite(n) && n > 0 ? n : null;
}

function parseYear(v: string | undefined): number | null {
  const m = /(\d{4})/.exec(v ?? '');
  return m ? Number(m[1]) : null;
}

function baseTitle(rel: string): string {
  const name = rel.split('/').pop()!;
  return name.slice(0, name.length - extname(name).length);
}

function upsertArtist(ctx: Ctx, name: string, nameSort: string | undefined): string {
  const n = norm(name);
  const row = ctx.store.get<{ id: string; name_sort: string | null }>('SELECT id, name_sort FROM artists WHERE name_norm = ?', n);
  if (row) {
    if (nameSort && nameSort !== row.name_sort) {
      ctx.store.run('UPDATE artists SET name_sort = ?, sort_key = ?, change_seq = ? WHERE id = ?', nameSort, sortKey(name, nameSort), ctx.store.nextChangeSeq(), row.id);
    }
    return row.id;
  }
  const id = newId('artist');
  ctx.store.run('INSERT INTO artists (id, name, name_sort, name_norm, sort_key, created_at, change_seq) VALUES (?, ?, ?, ?, ?, ?, ?)',
    id, name, nameSort ?? null, n, sortKey(name, nameSort), Date.now(), ctx.store.nextChangeSeq());
  ctx.store.run("INSERT INTO search_fts (entity_type, entity_id, text_norm) VALUES ('artist', ?, ?)", id, [n, nameSort ? norm(nameSort) : ''].join(' ').trim());
  return id;
}

function upsertAlbum(ctx: Ctx, libId: string, title: string, titleSort: string | undefined, albumArtistId: string | null, albumArtistName: string, year: number | null, artworkId: string | null): string {
  const groupKey = `${norm(albumArtistName)}\u0000${norm(title)}`;
  const row = ctx.store.get<{ id: string; year: number | null; artwork_id: string | null; title_sort: string | null }>(
    'SELECT id, year, artwork_id, title_sort FROM albums WHERE library_id = ? AND group_key = ?', libId, groupKey);
  if (row) {
    const newYear = row.year ?? year;
    const newArt = row.artwork_id ?? artworkId;
    const newSort = titleSort ?? row.title_sort;
    ctx.store.run('UPDATE albums SET year = ?, artwork_id = ?, title_sort = ?, sort_key = ?, change_seq = ? WHERE id = ?',
      newYear, newArt, newSort, sortKey(title, newSort), ctx.store.nextChangeSeq(), row.id);
    return row.id;
  }
  const id = newId('album');
  ctx.store.run(`INSERT INTO albums (id, library_id, title, title_sort, title_norm, sort_key, album_artist_id, year, artwork_id, group_key, added_at, change_seq)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    id, libId, title, titleSort ?? null, norm(title), sortKey(title, titleSort), albumArtistId, year, artworkId, groupKey, Date.now(), ctx.store.nextChangeSeq());
  ctx.store.run("INSERT INTO search_fts (entity_type, entity_id, text_norm) VALUES ('album', ?, ?)", id, [norm(title), titleSort ? norm(titleSort) : ''].join(' ').trim());
  return id;
}

function bumpRelated(ctx: Ctx, trackId: string) {
  const t = ctx.store.get<{ album_id: string | null }>('SELECT album_id FROM tracks WHERE id = ?', trackId);
  if (t?.album_id) ctx.store.run('UPDATE albums SET change_seq = ? WHERE id = ?', ctx.store.nextChangeSeq(), t.album_id);
  for (const a of ctx.store.all<{ artist_id: string }>('SELECT artist_id FROM track_artists WHERE track_id = ?', trackId)) {
    ctx.store.run('UPDATE artists SET change_seq = ? WHERE id = ?', ctx.store.nextChangeSeq(), a.artist_id);
  }
}

/** 곡 메타데이터 반영. trackId가 null이면 새 곡. */
function writeTrack(ctx: Ctx, lib: LibraryRow, trackId: string | null, a: Analyzed, artworkId: string | null): string {
  const now = Date.now();
  const tags = a.probe.tags;
  const title = tags.title ?? baseTitle(a.file.rel);
  const artistName = tags.artist ?? null;
  const albumArtistName = tags.album_artist ?? artistName;
  const artistId = artistName ? upsertArtist(ctx, artistName, tags.artist_sort) : null;
  const albumArtistId = albumArtistName ? (albumArtistName === artistName ? artistId : upsertArtist(ctx, albumArtistName, undefined)) : null;
  const year = parseYear(tags.date);
  const albumId = tags.album ? upsertAlbum(ctx, lib.id, tags.album, tags.album_sort, albumArtistId, albumArtistName ?? '', year, artworkId) : null;
  const version = mediaVersion(a.hash);
  const id = trackId ?? newId('track');

  if (trackId) bumpRelated(ctx, trackId); // 이전 앨범·아티스트의 집계가 바뀐다
  const fields = [lib.id, albumId, title, tags.title_sort ?? null, norm(title), sortKey(title, tags.title_sort), artistName,
    parseNo(tags.disc), parseNo(tags.track), a.probe.durationMs, year, tags.genre ?? null, artworkId, version] as const;
  if (trackId) {
    ctx.store.run(`UPDATE tracks SET library_id = ?, album_id = ?, title = ?, title_sort = ?, title_norm = ?, sort_key = ?, artist_display = ?,
        disc_no = ?, track_no = ?, duration_ms = ?, year = ?, genre = ?, artwork_id = ?, media_version = ?,
        state = 'available', missing_since = NULL, updated_at = ?, change_seq = ? WHERE id = ?`,
      ...fields, now, ctx.store.nextChangeSeq(), id);
  } else {
    ctx.store.run(`INSERT INTO tracks (library_id, album_id, title, title_sort, title_norm, sort_key, artist_display, disc_no, track_no,
        duration_ms, year, genre, artwork_id, media_version, id, state, added_at, updated_at, change_seq)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'available', ?, ?, ?)`,
      ...fields, id, now, now, ctx.store.nextChangeSeq());
  }
  ctx.store.run('DELETE FROM track_artists WHERE track_id = ?', id);
  if (artistId) ctx.store.run("INSERT INTO track_artists (track_id, artist_id, role, position) VALUES (?, ?, 'primary', 0)", id, artistId);
  ctx.store.run("DELETE FROM search_fts WHERE entity_type = 'track' AND entity_id = ?", id);
  ctx.store.run("INSERT INTO search_fts (entity_type, entity_id, text_norm) VALUES ('track', ?, ?)", id,
    [norm(title), tags.title_sort ? norm(tags.title_sort) : ''].join(' ').trim());

  const p = a.probe;
  const mf = [lib.id, a.file.rel, a.file.size, a.file.mtimeNs, a.hash, a.fingerprint, p.container, p.codec, p.mime, p.bitrate, p.sampleRate, p.channels, p.bitDepth, now] as const;
  const existing = ctx.store.get<{ id: string }>('SELECT id FROM media_files WHERE track_id = ?', id);
  if (existing) {
    ctx.store.run(`UPDATE media_files SET library_id = ?, rel_path = ?, size_bytes = ?, mtime_ns = ?, content_hash = ?, audio_fingerprint = ?,
        container = ?, codec = ?, mime = ?, bitrate = ?, sample_rate = ?, channels = ?, bit_depth = ?, scanned_at = ? WHERE id = ?`, ...mf, existing.id);
  } else {
    ctx.store.run(`INSERT INTO media_files (library_id, rel_path, size_bytes, mtime_ns, content_hash, audio_fingerprint, container, codec, mime,
        bitrate, sample_rate, channels, bit_depth, scanned_at, id, track_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, ...mf, newId('mediaFile'), id);
  }
  bumpRelated(ctx, id);
  return id;
}

function setTrackState(ctx: Ctx, trackId: string, state: 'available' | 'missing') {
  const now = Date.now();
  ctx.store.run('UPDATE tracks SET state = ?, missing_since = ?, updated_at = ?, change_seq = ? WHERE id = ?',
    state, state === 'missing' ? now : null, now, ctx.store.nextChangeSeq(), trackId);
  bumpRelated(ctx, trackId);
}

// ── 진입점 ─────────────────────────────────────────────────────────

export async function scanLibrary(ctx: Ctx, libraryId: string, opts: { force?: boolean; progress?: (p: number) => void } = {}): Promise<ScanSummary> {
  const lib = ctx.store.get<LibraryRow>('SELECT * FROM libraries WHERE id = ?', libraryId);
  if (!lib) throw new JobError('not_found', `라이브러리 없음: ${libraryId}`);

  // §4.4: 루트 확인에 실패하면 스캔을 중단하고 어떤 곡도 missing으로 바꾸지 않는다.
  let root: string;
  try {
    root = checkRoot(lib);
    if (rootLooksEmpty(root)) throw new StorageUnavailable('라이브러리 루트가 비어 있음(표식 없음)');
  } catch (e) {
    ctx.store.run("UPDATE libraries SET status = 'unavailable' WHERE id = ?", lib.id);
    ctx.log.warn({ library_id: lib.id, err: (e as Error).message }, '스캔 중단: 저장소 사용 불가');
    throw new JobError('storage_unavailable', (e as Error).message);
  }

  const { files, covers, dirNames, skippedLinks } = walk(ctx, root);
  // 분석에 실패했던 파일은 크기·mtime이 그대로면 다시 분석하지 않는다
  const knownFailures = new Map(ctx.store.all<{ rel_path: string; size_bytes: number; mtime_ns: string }>(
    'SELECT rel_path, size_bytes, mtime_ns FROM scan_failures WHERE library_id = ?', lib.id).map((r) => [r.rel_path, r]));
  const existing = ctx.store.all<ExistingRow>(
    `SELECT m.id AS media_id, m.track_id, m.rel_path, m.size_bytes, m.mtime_ns, m.content_hash, m.audio_fingerprint, t.state
       FROM media_files m JOIN tracks t ON t.id = m.track_id WHERE m.library_id = ?`, lib.id);
  const byPath = new Map(existing.map((r) => [r.rel_path, r]));
  const walkedPaths = new Set(files.map((f) => f.rel));

  const unchanged: Array<{ file: Walked; row: ExistingRow }> = [];
  const toAnalyze: Array<{ file: Walked; row: ExistingRow | null }> = [];
  let knownFailed = 0;
  for (const f of files) {
    const row = byPath.get(f.rel);
    const kf = knownFailures.get(f.rel);
    if (!row && kf && kf.size_bytes === f.size && kf.mtime_ns === f.mtimeNs) { knownFailed++; continue; }
    if (row && row.size_bytes === f.size && row.mtime_ns === f.mtimeNs) unchanged.push({ file: f, row });
    else toAnalyze.push({ file: f, row: row ?? null });
  }

  let done = 0;
  let errors = 0;
  const total = Math.max(1, toAnalyze.length);
  const analyzed = await pool(toAnalyze, PROBE_CONCURRENCY, async ({ file, row }) => {
    try {
      const [p, hash] = await Promise.all([probe(ctx.config.ffprobe, file.abs), fileSha256(file.abs)]);
      // 지문은 나중에 "태그만 고친 뒤 이동"을 찾으려면 모든 파일에 저장되어 있어야 한다 (01장 §4.3 3단계)
      const fingerprint = await audioFingerprint(ctx.config.ffmpeg, file.abs);
      return { file, row, a: { file, probe: p, hash, fingerprint } as Analyzed };
    } catch (e) {
      errors++;
      ctx.log.warn({ library_id: lib.id, path: file.rel, err: (e as Error).message }, '파일 분석 실패 — 건너뜀');
      ctx.store.run(`INSERT INTO scan_failures (library_id, rel_path, size_bytes, mtime_ns, reason, failed_at) VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(library_id, rel_path) DO UPDATE SET size_bytes = excluded.size_bytes, mtime_ns = excluded.mtime_ns, reason = excluded.reason, failed_at = excluded.failed_at`,
        lib.id, file.rel, file.size, file.mtimeNs, (e as Error).message.slice(0, 200), Date.now());
      return { file, row, a: null };
    } finally {
      opts.progress?.((++done / total) * 0.8);
    }
  });

  // 사라진 매핑(이번 스캔에서 경로가 안 보이거나 분석 실패) = 이동 후보
  const failedPaths = new Set(analyzed.filter((x) => !x.a).map((x) => x.file.rel));
  const candidates = existing.filter((r) => !walkedPaths.has(r.rel_path) || failedPaths.has(r.rel_path));
  const used = new Set<string>();
  const moves: Array<{ a: Analyzed; row: ExistingRow }> = [];
  const added: Analyzed[] = [];
  const changed: Array<{ a: Analyzed; row: ExistingRow }> = [];
  for (const x of analyzed) {
    if (!x.a) continue;
    if (x.row) { changed.push({ a: x.a, row: x.row }); continue; }
    const byHash = candidates.find((c) => !used.has(c.media_id) && c.content_hash === x.a!.hash);
    if (byHash) { used.add(byHash.media_id); moves.push({ a: x.a, row: byHash }); continue; }
    added.push(x.a);
  }
  // 태그만 고친 뒤 이동: 오디오 지문이 같은 후보가 정확히 1개일 때만 연결한다.
  const remaining = candidates.filter((c) => !used.has(c.media_id) && c.audio_fingerprint);
  if (remaining.length && added.length) {
    for (const a of [...added]) {
      if (!a.fingerprint) continue;
      const matches = remaining.filter((c) => !used.has(c.media_id) && c.audio_fingerprint === a.fingerprint);
      if (matches.length === 1) {
        used.add(matches[0]!.media_id);
        moves.push({ a, row: matches[0]! });
        added.splice(added.indexOf(a), 1);
      }
    }
  }
  const gone = candidates.filter((c) => !used.has(c.media_id) && c.state === 'available');

  // §4.4: 기존 곡 중 일정 비율 이상이 사라지면 적용하지 않고 관리자 확인을 기다린다.
  const availableBefore = existing.filter((r) => r.state === 'available').length;
  const summary: ScanSummary = { files: files.length, added: added.length, updated: changed.length, moved: moves.length, missing: gone.length, restored: 0, errors: errors + knownFailed, skippedLinks, pendingReview: false };
  if (!opts.force && availableBefore > 0 && gone.length / availableBefore >= ctx.config.scanMissingThreshold) {
    ctx.store.run("UPDATE libraries SET pending_review = 1, status = 'online' WHERE id = ?", lib.id);
    ctx.log.warn({ library_id: lib.id, gone: gone.length, available: availableBefore }, '대량 누락 감지 — 스캔 결과 적용 보류');
    return { ...summary, added: 0, updated: 0, moved: 0, missing: 0, pendingReview: true };
  }

  // 표지: 내장 표지 우선, 없으면 같은 폴더의 cover.jpg 등
  const folderArt = new Map<string, string | null>();
  async function artworkFor(a: Analyzed): Promise<string | null> {
    if (a.probe.hasEmbeddedCover) {
      const bytes = await extractEmbedded(ctx, a.file.abs);
      const id = bytes ? await ingestArtwork(ctx, bytes, 'embedded') : null;
      if (id) return id;
    }
    if (!folderArt.has(a.file.dirRel)) {
      const coverPath = covers.get(a.file.dirRel);
      let id: string | null = null;
      if (coverPath) {
        try {
          const real = await fsp.realpath(coverPath);
          if (isInside(root, real)) id = await ingestArtwork(ctx, await fsp.readFile(real), 'folder');
        } catch (e) {
          ctx.log.warn({ path: coverPath, err: (e as Error).message }, '폴더 표지를 읽지 못함');
        }
      }
      folderArt.set(a.file.dirRel, id);
    }
    return folderArt.get(a.file.dirRel) ?? null;
  }

  const apply = [...changed.map((c) => ({ a: c.a, trackId: c.row.track_id })), ...moves.map((m) => ({ a: m.a, trackId: m.row.track_id })), ...added.map((a) => ({ a, trackId: null as string | null }))];
  let i = 0;
  for (const item of apply) {
    const art = await artworkFor(item.a);
    ctx.store.tx(() => writeTrack(ctx, lib, item.trackId, item.a, art));
    opts.progress?.(0.8 + (++i / Math.max(1, apply.length)) * 0.2);
  }
  ctx.store.tx(() => {
    for (const u of unchanged) {
      if (u.row.state === 'missing') {
        setTrackState(ctx, u.row.track_id, 'available');
        summary.restored++;
      }
    }
    for (const g of gone) setTrackState(ctx, g.track_id, 'missing');
    ctx.store.run("UPDATE libraries SET status = 'online', pending_review = 0, last_scan_at = ?, revision = revision + 1 WHERE id = ?", Date.now(), lib.id);
  });
  ctx.store.run(`DELETE FROM scan_failures WHERE library_id = ? AND rel_path IN (SELECT rel_path FROM media_files WHERE library_id = ?)`, lib.id, lib.id);
  const walkedSet = new Set(files.map((f) => f.rel));
  for (const r of ctx.store.all<{ rel_path: string }>('SELECT rel_path FROM scan_failures WHERE library_id = ?', lib.id)) {
    if (!walkedSet.has(r.rel_path)) ctx.store.run('DELETE FROM scan_failures WHERE library_id = ? AND rel_path = ?', lib.id, r.rel_path);
  }

  // 가사: 사이드카는 음원이 그대로여도 바뀔 수 있으므로 모든 곡을 확인한다. 내장 가사는 이번에 분석한 파일만.
  const embeddedByPath = new Map(apply.map((x) => [x.a.file.rel, x.a.probe.tags.lyrics ?? null]));
  for (const m of ctx.store.all<{ track_id: string; rel_path: string }>('SELECT track_id, rel_path FROM media_files WHERE library_id = ?', lib.id)) {
    if (!walkedSet.has(m.rel_path)) continue;
    const dirRel = m.rel_path.includes('/') ? m.rel_path.slice(0, m.rel_path.lastIndexOf('/')) : '';
    await syncTrackLyrics(ctx, root, m.track_id, m.rel_path, dirNames.get(dirRel) ?? new Set(), embeddedByPath.has(m.rel_path) ? embeddedByPath.get(m.rel_path) : undefined);
  }
  ctx.log.info({ library_id: lib.id, ...summary }, '스캔 완료');
  return summary;
}

export function registerScanJob(ctx: Ctx) {
  ctx.jobs.register('scan', async (job, progress) => {
    await scanLibrary(ctx, job.ref_id!, { progress });
  });
}
