// 가사 3종 (원문·한글 발음·한국어 번역). 출처는 서버의 사이드카 파일, 파일 내장 가사, 관리자 직접 입력,
// 그리고 한글 발음이 없을 때 원문에서 오프라인으로 만든 자동 생성 발음(source generated)뿐이다(05장 §8.4).
// 직접 입력(user)한 가사는 재스캔이 덮어쓰지 않는다. 자동 생성 발음은 저장하지 않고 요청 때 만들어 메모리에 둔다.
import { promises as fsp } from 'node:fs';
import { join } from 'node:path';
import { sha256hex } from '../auth/crypto.ts';
import type { Principal } from '../auth/sessions.ts';
import { getTrackRow } from '../catalog/catalog.ts';
import type { Ctx } from '../ctx.ts';
import { ApiError, badRequest } from '../http/problem.ts';
import { isInside } from '../scanner/paths.ts';
import { decodeText, parseLyrics } from './lrc.ts';
import { hasJapanese, PRONUNCIATION_VERSION, pronounceLines } from './pronunciation.ts';

export type LyricsKind = 'original' | 'pronunciation_ko' | 'translation_ko';
const KINDS: LyricsKind[] = ['original', 'pronunciation_ko', 'translation_ko'];
const MAX_SIDECAR_BYTES = 512 * 1024;

interface LyricsRow {
  track_id: string;
  kind: LyricsKind;
  format: 'lrc' | 'plain';
  language: string | null;
  body: string;
  source_type: 'sidecar' | 'embedded' | 'user' | 'provider';
  source_name: string | null;
  license_note: string | null;
  content_hash: string;
}

function bumpVersion(ctx: Ctx, trackId: string) {
  ctx.store.run('INSERT INTO lyrics_versions (track_id, version) VALUES (?, 1) ON CONFLICT(track_id) DO UPDATE SET version = version + 1', trackId);
  // has_lyrics가 Track에 들어 있으므로 곡도 변경 피드에 다시 나간다
  ctx.store.run('UPDATE tracks SET change_seq = ?, updated_at = ? WHERE id = ?', ctx.store.nextChangeSeq(), Date.now(), trackId);
}

function version(ctx: Ctx, trackId: string): number {
  return Number(ctx.store.get<{ version: number }>('SELECT version FROM lyrics_versions WHERE track_id = ?', trackId)?.version ?? 0);
}

interface Candidate {
  kind: LyricsKind;
  format: 'lrc' | 'plain';
  language: string | null;
  body: string;
  source_type: 'sidecar' | 'embedded';
  source_name: string;
}

/** 한 종류를 반영한다. 직접 입력 가사가 있으면 건드리지 않는다. 바뀌었으면 true */
function apply(ctx: Ctx, trackId: string, kind: LyricsKind, c: Candidate | null, managed: Array<LyricsRow['source_type']>): boolean {
  const cur = ctx.store.get<LyricsRow>('SELECT * FROM lyrics WHERE track_id = ? AND kind = ?', trackId, kind);
  if (cur && !managed.includes(cur.source_type)) return false;
  if (!c) {
    if (!cur) return false;
    ctx.store.run('DELETE FROM lyrics WHERE track_id = ? AND kind = ?', trackId, kind);
    return true;
  }
  const hash = sha256hex(`${c.format}\n${c.source_type}\n${c.body}`);
  if (cur && cur.content_hash === hash) return false;
  ctx.store.run(`INSERT INTO lyrics (track_id, kind, format, language, body, source_type, source_name, license_note, content_hash, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, NULL, ?, ?)
       ON CONFLICT(track_id, kind) DO UPDATE SET format = excluded.format, language = excluded.language, body = excluded.body,
         source_type = excluded.source_type, source_name = excluded.source_name, license_note = NULL, content_hash = excluded.content_hash,
         updated_at = excluded.updated_at`,
    trackId, kind, c.format, c.language, c.body, c.source_type, c.source_name, hash, Date.now());
  return true;
}

async function readSidecar(root: string, dirAbs: string, name: string, existing: Set<string>): Promise<string | null> {
  if (!existing.has(name.toLowerCase())) return null;
  try {
    const real = await fsp.realpath(join(dirAbs, name));
    if (!isInside(root, real)) return null; // 루트 밖을 가리키는 사이드카는 읽지 않는다
    const st = await fsp.stat(real);
    if (!st.isFile() || st.size > MAX_SIDECAR_BYTES) return null;
    return decodeText(await fsp.readFile(real));
  } catch {
    return null;
  }
}

/**
 * 스캔 중 곡 하나의 사이드카·내장 가사를 맞춘다.
 * <곡이름>.lrc / .txt → 원문, <곡이름>.ko-pron.lrc → 한글 발음, <곡이름>.ko.lrc → 한국어 번역.
 * embedded가 undefined면(이번 스캔에서 태그를 읽지 않음) 내장 가사는 그대로 둔다.
 */
export async function syncTrackLyrics(ctx: Ctx, root: string, trackId: string, audioRel: string, dirNames: Set<string>, embedded: string | null | undefined) {
  const parts = audioRel.split('/');
  const file = parts.pop()!;
  const dot = file.lastIndexOf('.');
  const base = dot > 0 ? file.slice(0, dot) : file;
  const dirAbs = join(root, ...parts);
  const lrc = await readSidecar(root, dirAbs, `${base}.lrc`, dirNames);
  const txt = lrc === null ? await readSidecar(root, dirAbs, `${base}.txt`, dirNames) : null;
  const pron = await readSidecar(root, dirAbs, `${base}.ko-pron.lrc`, dirNames);
  const tr = await readSidecar(root, dirAbs, `${base}.ko.lrc`, dirNames);

  let original: Candidate | null = null;
  if (lrc !== null) original = { kind: 'original', format: 'lrc', language: null, body: lrc, source_type: 'sidecar', source_name: '서버의 .lrc 파일' };
  else if (txt !== null) original = { kind: 'original', format: 'plain', language: null, body: txt, source_type: 'sidecar', source_name: '서버의 .txt 파일' };
  else if (embedded) original = { kind: 'original', format: /\[\d{1,3}:\d{2}/.test(embedded) ? 'lrc' : 'plain', language: null, body: embedded, source_type: 'embedded', source_name: '파일 내장 가사' };

  ctx.store.tx(() => {
    let changed = false;
    // 내장 가사를 이번에 읽지 않았으면 기존 embedded는 유지 (사이드카만 관리)
    changed = apply(ctx, trackId, 'original', original ?? null, embedded === undefined && !original ? ['sidecar'] : ['sidecar', 'embedded']) || changed;
    changed = apply(ctx, trackId, 'pronunciation_ko', pron === null ? null : { kind: 'pronunciation_ko', format: 'lrc', language: 'ko', body: pron, source_type: 'sidecar', source_name: '서버의 .ko-pron.lrc 파일' }, ['sidecar']) || changed;
    changed = apply(ctx, trackId, 'translation_ko', tr === null ? null : { kind: 'translation_ko', format: 'lrc', language: 'ko', body: tr, source_type: 'sidecar', source_name: '서버의 .ko.lrc 파일' }, ['sidecar']) || changed;
    if (changed) bumpVersion(ctx, trackId);
  });
}

const GENERATED_SOURCE = { type: 'generated', name: '자동 생성 (형태소 분석, 오프라인)', license_note: 'kuromoji (Apache-2.0), IPADIC' } as const;
const CACHE_MAX = 200;
/** 원문 content_hash → 일본어 포함 여부 / 생성한 발음 줄 (같은 원문은 한 번만 분석) */
const japaneseCache = new Map<string, boolean>();
const generatedCache = new Map<string, Promise<{ t_ms: number | null; text: string }[]>>();

function remember<V>(cache: Map<string, V>, key: string, make: () => V): V {
  let v = cache.get(key);
  if (v === undefined) {
    v = make();
    if (cache.size >= CACHE_MAX) cache.delete(cache.keys().next().value!);
    cache.set(key, v);
  }
  return v;
}

/** 이 원문에서 한글 발음을 만들 수 있는지 */
function generatable(original: Pick<LyricsRow, 'body' | 'content_hash'>): boolean {
  return remember(japaneseCache, original.content_hash, () => hasJapanese(original.body));
}

export function hasLyrics(ctx: Ctx, trackIds: string[]): Map<string, LyricsKind[]> {
  const out = new Map<string, LyricsKind[]>();
  if (trackIds.length === 0) return out;
  const rows = ctx.store.all<{ track_id: string; kind: LyricsKind; content_hash: string; body: string | null }>(
    `SELECT track_id, kind, content_hash, CASE WHEN kind = 'original' THEN body END AS body
       FROM lyrics WHERE track_id IN (${trackIds.map(() => '?').join(',')})`, ...trackIds);
  for (const r of rows) {
    const list = out.get(r.track_id) ?? [];
    list.push(r.kind);
    out.set(r.track_id, list);
  }
  for (const r of rows) {
    const list = out.get(r.track_id)!;
    if (r.kind === 'original' && !list.includes('pronunciation_ko') && generatable({ body: r.body ?? '', content_hash: r.content_hash })) list.push('pronunciation_ko');
  }
  for (const [k, v] of out) out.set(k, KINDS.filter((x) => v.includes(x)));
  return out;
}

export function lyricsEtag(ctx: Ctx, p: Principal, trackId: string): string {
  // -g: 자동 생성 규칙 버전. 규칙이 바뀌면 앱의 캐시가 무효가 된다
  return `"v${version(ctx, trackId)}-o${offsetOf(ctx, p, trackId)}-g${PRONUNCIATION_VERSION}"`;
}

function offsetOf(ctx: Ctx, p: Principal, trackId: string): number {
  return Number(ctx.store.get<{ offset_ms: number }>('SELECT offset_ms FROM lyrics_prefs WHERE user_id = ? AND track_id = ?', p.user.id, trackId)?.offset_ms ?? 0);
}

export async function getLyrics(ctx: Ctx, p: Principal, trackId: string) {
  getTrackRow(ctx, p, trackId); // 권한
  const rows = ctx.store.all<LyricsRow>('SELECT * FROM lyrics WHERE track_id = ?', trackId);
  const ver = version(ctx, trackId);
  const offset = offsetOf(ctx, p, trackId);
  const variants = [];
  for (const kind of KINDS) {
    const r = rows.find((x) => x.kind === kind);
    if (r) {
      const parsed = parseLyrics(r.format, r.body);
      variants.push({ kind, language: r.language, synced: parsed.synced, lines: parsed.lines,
        source: { type: r.source_type as string, name: r.source_name, license_note: r.license_note } });
      continue;
    }
    const original = rows.find((x) => x.kind === 'original');
    if (kind !== 'pronunciation_ko' || !original || !generatable(original)) continue;
    const parsed = parseLyrics(original.format, original.body);
    const key = `${original.content_hash}:${PRONUNCIATION_VERSION}`;
    const lines = await remember(generatedCache, key, () => pronounceLines(parsed.lines).catch((e: unknown) => {
      generatedCache.delete(key); // 실패는 기억하지 않는다
      throw e;
    }));
    variants.push({ kind, language: 'ko', synced: parsed.synced, lines, source: { ...GENERATED_SOURCE } as { type: string; name: string | null; license_note: string | null } });
  }
  return { track_id: trackId, version: ver, offset_ms: offset, variants };
}

/** 관리자 직접 입력 (If-Match 필수). 이후 재스캔은 이 종류를 덮어쓰지 않는다. */
export async function putLyrics(ctx: Ctx, p: Principal, trackId: string, kind: LyricsKind, ifMatch: string | undefined,
  body: { format: 'lrc' | 'plain'; body: string; language?: string; source_name?: string; license_note?: string }) {
  getTrackRow(ctx, p, trackId);
  const current = version(ctx, trackId);
  const m = ifMatch ? /^"?v(\d+)(?:-o-?\d+)?(?:-g\d+)?"?$/.exec(ifMatch.trim()) : null;
  if (!m) throw badRequest('If-Match', '가사 ETag 형식이 아님');
  if (Number(m[1]) !== current) throw new ApiError(412, 'version_conflict', { headers: { etag: lyricsEtag(ctx, p, trackId) } });
  if (body.format === 'lrc' && !parseLyrics('lrc', body.body).synced) throw badRequest('body', '시간 표시가 있는 줄이 없다');
  ctx.store.tx(() => {
    ctx.store.run(`INSERT INTO lyrics (track_id, kind, format, language, body, source_type, source_name, license_note, content_hash, updated_at)
         VALUES (?, ?, ?, ?, ?, 'user', ?, ?, ?, ?)
         ON CONFLICT(track_id, kind) DO UPDATE SET format = excluded.format, language = excluded.language, body = excluded.body,
           source_type = 'user', source_name = excluded.source_name, license_note = excluded.license_note,
           content_hash = excluded.content_hash, updated_at = excluded.updated_at`,
      trackId, kind, body.format, body.language ?? (kind === 'original' ? null : 'ko'), body.body,
      body.source_name ?? '사용자 입력', body.license_note ?? null, sha256hex(body.body), Date.now());
    bumpVersion(ctx, trackId);
  });
  return await getLyrics(ctx, p, trackId);
}

export function putOffset(ctx: Ctx, p: Principal, trackId: string, offsetMs: number) {
  getTrackRow(ctx, p, trackId);
  ctx.store.run('INSERT INTO lyrics_prefs (user_id, track_id, offset_ms) VALUES (?, ?, ?) ON CONFLICT(user_id, track_id) DO UPDATE SET offset_ms = excluded.offset_ms',
    p.user.id, trackId, offsetMs);
}
