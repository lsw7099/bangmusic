// 테스트 공통 도구. 합성 음원(tools/make-fixtures)만 쓴다 — 실제 음원을 쓰지 않는다.
// 각 테스트 묶음은 fixtures/를 임시 폴더에 복사해 쓴다(이동·삭제·링크 실험이 원본 세트를 바꾸지 않게).
import { cpSync, existsSync, mkdtempSync, readFileSync, rmSync, symlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Ajv2020, type ValidateFunction } from 'ajv/dist/2020.js';
import addFormatsModule from 'ajv-formats';
import type { FastifyInstance, LightMyRequestResponse } from 'fastify';
import { parse } from 'yaml';
import { addLibrary, createUser } from '../src/admin.ts';
import { loadConfig } from '../src/config.ts';
import { openCtx, type Ctx } from '../src/ctx.ts';
import { startServer } from '../src/main.ts';
import { scanLibrary } from '../src/scanner/scan.ts';

const addFormats = addFormatsModule as unknown as (ajv: Ajv2020) => void;

export const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
export const FIXTURES = join(REPO, 'fixtures');

export function requireFixtures() {
  if (!existsSync(join(FIXTURES, 'manifest.json'))) {
    throw new Error('합성 음원이 없다. 먼저 실행: npm run fixtures -- --clean --quick');
  }
}

/** FFmpeg 경로: 환경 변수 FFMPEG/FFPROBE, 없으면 PATH */
function ffConfig() {
  return { ffmpeg: process.env.FFMPEG ?? 'ffmpeg', ffprobe: process.env.FFPROBE ?? 'ffprobe' };
}

export const ADMIN = { username: 'siwon', password: 'admin-password-123' };
export const MEMBER = { username: 'member', password: 'member-password-123' };
export const OTHER = { username: 'other', password: 'other-password-123' };

export interface Env {
  dir: string;
  music: string;
  ctx: Ctx;
  app: FastifyInstance;
  lib1: string;
  lib2: string;
  logFile: string;
  /** 응답 본문 전체 (SEC-09 경로 노출 검사용) */
  bodies: string[];
  /** 테스트 중 만든 비밀값 (SEC-10 로그 검사용) */
  secrets: Set<string>;
  close(): Promise<void>;
}

/** 파일/폴더 링크. Windows에서는 권한 없이 만들 수 있는 junction(폴더)만 가능하다. */
export function linkDir(target: string, at: string) {
  symlinkSync(target, at, process.platform === 'win32' ? 'junction' : 'dir');
}

export async function setup(opts: { scan?: boolean; overrides?: Parameters<typeof loadConfig>[1] } = {}): Promise<Env> {
  requireFixtures();
  const dir = mkdtempSync(join(tmpdir(), 'bm-test-'));
  const music = join(dir, 'music');
  cpSync(join(FIXTURES, 'lib1'), join(music, 'lib1'), { recursive: true, verbatimSymlinks: true });
  cpSync(join(FIXTURES, 'lib2'), join(music, 'lib2'), { recursive: true, verbatimSymlinks: true });
  const logFile = join(dir, 'server.log');
  const config = loadConfig({}, {
    dataDir: join(dir, 'data'),
    cacheDir: join(dir, 'cache'),
    logFile,
    logLevel: 'info',
    serverName: '테스트 서버',
    ...ffConfig(),
    ...opts.overrides,
  });
  const ctx = openCtx(config);
  createUser(ctx, { ...ADMIN, role: 'admin', display_name: '시원' });
  const lib1 = addLibrary(ctx, 'Lib One', join(music, 'lib1')).id;
  const lib2 = addLibrary(ctx, 'Lib Two', join(music, 'lib2')).id;
  createUser(ctx, { ...MEMBER, role: 'member', library_ids: [lib1] });
  createUser(ctx, { ...OTHER, role: 'member', library_ids: [lib1] });
  if (opts.scan !== false) {
    await scanLibrary(ctx, lib1);
    await scanLibrary(ctx, lib2);
  }
  const app = startServer(ctx);
  await app.ready();
  const env: Env = {
    dir, music, ctx, app, lib1, lib2, logFile, bodies: [], secrets: new Set([ADMIN.password, MEMBER.password, OTHER.password]),
    // 복원 시험처럼 ctx·app을 바꿔 끼운 경우에도 현재 것을 닫는다
    async close() {
      await env.app.close();
      await env.ctx.jobs.stop();
      try { env.ctx.store.close(); } catch { /* 이미 닫힘 */ }
      rmSync(dir, { recursive: true, force: true, maxRetries: 5 });
    },
  };
  return env;
}

let installSeq = 0;
export function device(name = 'Test Phone') {
  installSeq++;
  return { name, platform: 'android' as const, app_version: '1.0.0', installation_id: `00000000-0000-4000-8000-${String(installSeq).padStart(12, '0')}` };
}

export interface Req {
  method?: 'GET' | 'HEAD' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  url: string;
  token?: string;
  body?: unknown;
  headers?: Record<string, string>;
}

export async function call(env: Env, r: Req): Promise<LightMyRequestResponse> {
  const res = await env.app.inject({
    method: r.method ?? 'GET',
    url: r.url,
    headers: { ...(r.token ? { authorization: `Bearer ${r.token}` } : {}), ...(r.headers ?? {}) },
    ...(r.body !== undefined ? { payload: r.body as object } : {}),
  });
  const ct = String(res.headers['content-type'] ?? '');
  if (ct.includes('json')) env.bodies.push(res.body);
  return res;
}

export async function loginAs(env: Env, who: { username: string; password: string }, dev = device()) {
  const res = await call(env, { method: 'POST', url: '/v1/auth/login', body: { ...who, device: dev } });
  if (res.statusCode !== 200) throw new Error(`로그인 실패 ${res.statusCode} ${res.body}`);
  const j = res.json();
  env.secrets.add(j.access_token);
  env.secrets.add(j.refresh_token);
  return j as { session_id: string; access_token: string; refresh_token: string; user: { id: string } };
}

// ── 계약 검사 (응답이 openapi.yaml 스키마와 일치하는지) ──────────────

type Json = Record<string, unknown>;
const spec = parse(readFileSync(join(REPO, 'docs/design/openapi.yaml'), 'utf8')) as Json & { paths: Record<string, Record<string, Json>>; components: Json & { schemas: Json; responses: Record<string, Json> } };

function rewrite(node: unknown): unknown {
  if (Array.isArray(node)) return node.map(rewrite);
  if (node && typeof node === 'object') {
    const out: Json = {};
    for (const [k, v] of Object.entries(node)) {
      out[k] = k === '$ref' && typeof v === 'string' ? v.replace('#/components/schemas/', 'bm#/$defs/') : rewrite(v);
    }
    return out;
  }
  return node;
}

const ajv = new Ajv2020({ strict: false, allErrors: true });
addFormats(ajv);
ajv.addSchema({ $id: 'bm', $defs: rewrite(spec.components.schemas) as Json });

const ops = new Map<string, Json>();
for (const [path, item] of Object.entries(spec.paths)) {
  for (const [m, op] of Object.entries(item)) if (m !== 'parameters') ops.set(op.operationId as string, { ...op, _path: path, _method: m });
}
const validators = new Map<string, ValidateFunction>();

/** 응답 상태가 계약에 정의되어 있고, 본문이 해당 스키마와 맞는지 확인한다. */
export function expectContract(res: LightMyRequestResponse, operationId: string): void {
  const op = ops.get(operationId);
  if (!op) throw new Error(`계약에 없는 동작: ${operationId}`);
  if (!res.headers['x-request-id']) throw new Error(`${operationId}: X-Request-Id 없음`);
  const responses = op.responses as Record<string, Json>;
  let def = responses[String(res.statusCode)];
  if (!def) throw new Error(`${operationId}: 계약에 없는 상태 ${res.statusCode} (${res.body.slice(0, 200)})`);
  if (def.$ref) def = spec.components.responses[(def.$ref as string).split('/').pop()!]!;
  const content = def.content as Record<string, { schema?: Json }> | undefined;
  if (!content) {
    if (res.body.length && res.statusCode !== 304) throw new Error(`${operationId}: 본문이 없어야 함`);
    return;
  }
  const ct = String(res.headers['content-type'] ?? '').split(';')[0]!.trim();
  const key = Object.keys(content).find((k) => k === ct || (k.endsWith('/*') && ct.startsWith(k.slice(0, -1))));
  if (!key) throw new Error(`${operationId} ${res.statusCode}: 계약에 없는 Content-Type ${ct}`);
  if (!key.includes('json')) return;
  const vkey = `${operationId}:${res.statusCode}:${key}`;
  let v = validators.get(vkey);
  if (!v) {
    v = ajv.compile(rewrite(content[key]!.schema ?? {}) as Json);
    validators.set(vkey, v);
  }
  if (!v(res.json())) throw new Error(`${operationId} ${res.statusCode}: 스키마 불일치 ${ajv.errorsText(v.errors)}\n${res.body.slice(0, 500)}`);
}

export const OPERATIONS = ops;
