// P2 운영 수용 기준: FN-09(강제 종료 후 복구), FN-10(백업·복원), FN-11(마이그레이션 실패 롤백),
// FN-20(버전 호환, 서버 측), 점검 모드, SEC-15(음악 원본에 쓰지 않음). L1.
import assert from 'node:assert/strict';
import { spawn, spawnSync, type ChildProcess } from 'node:child_process';
import { createHash, randomUUID } from 'node:crypto';
import { cpSync, existsSync, mkdtempSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { createServer } from 'node:net';
import { tmpdir } from 'node:os';
import { join, relative } from 'node:path';
import { after, describe, it } from 'node:test';
import { DatabaseSync } from 'node:sqlite';
import { invalidateAccessTokens, listBackups, restoreBackup, createBackup } from '../src/backup.ts';
import { loadConfig } from '../src/config.ts';
import { dbPath, openCtx } from '../src/ctx.ts';
import { loadMigrations, migrate, Store } from '../src/db/store.ts';
import { startServer } from '../src/main.ts';
import { recoverCache, registerTranscodeJob } from '../src/media/transcode.ts';
import { scanLibrary } from '../src/scanner/scan.ts';
import { ADMIN, call, device, expectContract, FIXTURES, loginAs, REPO, setup, type Env } from './helpers.ts';

const MAIN = join(REPO, 'server', 'src', 'main.ts');
const cleanups: Array<() => Promise<void> | void> = [];
after(async () => {
  for (const c of cleanups.reverse()) await c();
});

function treeHash(dir: string): string {
  const h = createHash('sha256');
  const walk = (d: string) => {
    for (const e of readdirSync(d, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
      const p = join(d, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.isFile()) {
        const st = statSync(p);
        h.update(`${relative(dir, p)}\0${st.size}\0${st.mtimeMs}\0`);
        h.update(readFileSync(p));
      }
    }
  };
  walk(dir);
  return h.digest('hex');
}

describe('FN-09 서버 프로세스 강제 종료 후 재시작', () => {
  function freePort(): Promise<number> {
    return new Promise((ok) => {
      const s = createServer().listen(0, '127.0.0.1', () => {
        const port = (s.address() as { port: number }).port;
        s.close(() => ok(port));
      });
    });
  }

  it('변환 작업 도중 kill → 재시작 → 작업 복구·완료, 임시 파일 정리, DB 무결성', async () => {
    const dir = mkdtempSync(join(tmpdir(), 'bm-fn09-'));
    cleanups.push(() => rmSync(dir, { recursive: true, force: true, maxRetries: 5 }));
    cpSync(join(FIXTURES, 'lib1'), join(dir, 'music'), { recursive: true, verbatimSymlinks: true });
    const port = await freePort();
    const envVars = {
      ...process.env,
      BANGMUSIC_DATA_DIR: join(dir, 'data'), BANGMUSIC_CACHE_DIR: join(dir, 'cache'), BANGMUSIC_PORT: String(port), BANGMUSIC_HOST: '127.0.0.1',
      BANGMUSIC_LOG_FILE: join(dir, 'server.log'), BANGMUSIC_TRANSCODE_CONCURRENCY: '1', BANGMUSIC_BACKUP_HOUR_UTC: '-1',
    };
    const cli = (args: string[], input?: string) => {
      const r = spawnSync(process.execPath, [MAIN, ...args], { env: envVars, input, encoding: 'utf8' });
      assert.equal(r.status, 0, r.stderr);
      return r.stdout;
    };
    cli(['admin', 'create', ADMIN.username], `${ADMIN.password}\n`);
    cli(['library', 'add', 'L', join(dir, 'music')]);
    cli(['scan']);
    const serve = () => {
      const c = spawn(process.execPath, [MAIN, 'serve'], { env: envVars, stdio: 'ignore' });
      cleanups.push(() => { if (c.exitCode === null) c.kill('SIGKILL'); });
      return c;
    };
    const base = `http://127.0.0.1:${port}/v1`;
    const waitUp = async () => {
      for (let i = 0; i < 100; i++) {
        if (await fetch(`${base}/server`).then((r) => r.ok).catch(() => false)) return;
        await new Promise((ok) => setTimeout(ok, 100));
      }
      throw new Error('서버가 뜨지 않음');
    };
    let child: ChildProcess = serve();
    await waitUp();
    const login = await (await fetch(`${base}/auth/login`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ ...ADMIN, device: device() }) })).json();
    const auth = { authorization: `Bearer ${login.access_token}`, 'content-type': 'application/json' };
    const tracks = (await (await fetch(`${base}/tracks?limit=200`, { headers: auth })).json()).items as Array<{ id: string; title: string }>;
    const targets = tracks.filter((t) => ['길이 300초', '삑 세기 (청취 확인용)', '형식 flac-24', '형식 wav'].includes(t.title));
    const rids: string[] = [];
    for (const t of targets) {
      const r = await (await fetch(`${base}/tracks/${t.id}/renditions`, { method: 'POST', headers: auth, body: JSON.stringify({ purpose: 'download', quality: 'aac_128', accept: [{ container: 'm4a', codec: 'aac' }] }) })).json();
      rids.push(r.id);
    }
    // 첫 변환이 실행되는 중에 강제 종료
    await new Promise((ok) => setTimeout(ok, 150));
    child.kill('SIGKILL');
    await new Promise((ok) => child.once('exit', ok));
    const mid = new DatabaseSync(join(dir, 'data', 'db', 'bangmusic.sqlite'), { readOnly: true });
    const states = mid.prepare("SELECT state, COUNT(*) AS n FROM jobs WHERE type = 'transcode' GROUP BY state").all() as { state: string; n: number }[];
    mid.close();
    assert.ok(states.some((s) => s.state === 'running' || s.state === 'queued'), `종료 시점에 남은 작업이 있어야 시험이 의미 있다: ${JSON.stringify(states)}`);

    child = serve();
    await waitUp();
    for (const rid of rids) {
      let j: { state: string } = { state: 'preparing' };
      for (let i = 0; i < 300 && j.state === 'preparing'; i++) {
        await new Promise((ok) => setTimeout(ok, 100));
        const res = await fetch(`${base}/renditions/${rid}`, { headers: auth });
        if (res.status === 401) {
          // 액세스 토큰은 그대로 유효해야 한다
          throw new Error('재시작 후 토큰이 무효');
        }
        j = await res.json();
      }
      assert.equal(j.state, 'ready', `${rid} 복구 후 완료`);
    }
    assert.deepEqual(readdirSync(join(dir, 'cache', 'tmp')), [], '중단된 임시 파일 정리');
    child.kill('SIGTERM');
    await new Promise((ok) => child.once('exit', ok));
    const db = new DatabaseSync(join(dir, 'data', 'db', 'bangmusic.sqlite'), { readOnly: true });
    assert.equal((db.prepare('PRAGMA integrity_check').get() as { integrity_check: string }).integrity_check, 'ok');
    db.close();
  });
});

describe('FN-10 백업 → DB 삭제 → 복원', () => {
  it('로그인·목록·플레이리스트·재생 기록이 스냅샷과 같고, 앱은 재로그인 없이 복귀', async () => {
    const env = await setup();
    cleanups.push(() => env.close());
    const s = await loginAs(env, ADMIN);
    const tracks = (await call(env, { url: '/v1/tracks?limit=200', token: s.access_token })).json().items;
    const pl = (await call(env, { method: 'POST', url: '/v1/playlists', token: s.access_token, body: { name: '백업 시험', track_ids: tracks.slice(0, 3).map((t: { id: string }) => t.id) } })).json();
    await call(env, { method: 'POST', url: '/v1/history/events', token: s.access_token, body: { events: [{ event_id: randomUUID(), track_id: tracks[0].id, started_at: new Date().toISOString(), played_ms: 40_000, completed: true, source: 'stream' }] } });
    const snapshotOf = async (tok: string) => ({
      tracks: (await call(env, { url: '/v1/tracks?limit=200', token: tok })).json().items.map((t: { id: string; media_version: string }) => `${t.id}:${t.media_version}`),
      playlists: (await call(env, { url: '/v1/playlists', token: tok })).json().items.map((p: { id: string; version: number; item_count: number }) => `${p.id}:${p.version}:${p.item_count}`),
      recent: (await call(env, { url: '/v1/history/recent', token: tok })).json().items.map((t: { id: string }) => t.id),
      server: (await call(env, { url: '/v1/server' })).json().server_id,
    });
    const before = await snapshotOf(s.access_token);
    const snap = createBackup(env.ctx.store, env.ctx.config, 'manual');
    assert.ok(listBackups(env.ctx.config).length >= 1);
    assert.ok(existsSync(join(snap, 'secrets', 'signing.key')));

    // 서버 정지 → DB 파일 삭제 → 복원
    await env.app.close();
    await env.ctx.jobs.stop();
    env.ctx.store.close();
    const file = dbPath(env.ctx.config);
    for (const ext of ['', '-wal', '-shm']) rmSync(file + ext, { force: true });
    const r = restoreBackup(env.ctx.config, file, snap);
    assert.equal(r.preRestore, null);
    const ctx2 = openCtx(env.ctx.config);
    registerTranscodeJob(ctx2);
    recoverCache(ctx2);
    invalidateAccessTokens(ctx2.store);
    const app2 = startServer(ctx2);
    await app2.ready();
    Object.assign(env, { ctx: ctx2, app: app2 });

    // 액세스 토큰은 무효 → 앱이 리프레시로 복귀 (재로그인 없음)
    assert.equal((await call(env, { url: '/v1/me', token: s.access_token })).json().code, 'access_expired');
    const refreshed = await call(env, { method: 'POST', url: '/v1/auth/refresh', body: { refresh_token: s.refresh_token } });
    assert.equal(refreshed.statusCode, 200);
    const t2 = refreshed.json();
    env.secrets.add(t2.access_token).add(t2.refresh_token);
    assert.deepEqual(await snapshotOf(t2.access_token), before);
    const items = (await call(env, { url: `/v1/playlists/${pl.id}/items`, token: t2.access_token })).json();
    assert.equal(items.items.length, 3);
    // 표지 마스터도 돌아온다
    const art = tracks.find((t: { artwork_id: string | null }) => t.artwork_id)!.artwork_id;
    assert.equal((await call(env, { url: `/v1/artwork/${art}?size=96`, token: t2.access_token })).statusCode, 200);
  });

  it('스냅샷 이후 회전한 리프레시 토큰: 현재 DB가 남아 있으면 세션을 옮겨 와 재로그인 불필요', async () => {
    const env = await setup({ scan: false });
    cleanups.push(() => env.close());
    const s = await loginAs(env, ADMIN);
    const snap = createBackup(env.ctx.store, env.ctx.config, 'manual');
    const rotated = (await call(env, { method: 'POST', url: '/v1/auth/refresh', body: { refresh_token: s.refresh_token } })).json();
    env.secrets.add(rotated.access_token).add(rotated.refresh_token);
    await env.app.close();
    await env.ctx.jobs.stop();
    env.ctx.store.close();
    const r = restoreBackup(env.ctx.config, dbPath(env.ctx.config), snap);
    assert.ok(r.preRestore && existsSync(r.preRestore), '이전 DB 보관');
    const ctx2 = openCtx(env.ctx.config);
    invalidateAccessTokens(ctx2.store);
    const app2 = startServer(ctx2);
    await app2.ready();
    Object.assign(env, { ctx: ctx2, app: app2 });
    const ok = await call(env, { method: 'POST', url: '/v1/auth/refresh', body: { refresh_token: rotated.refresh_token } });
    assert.equal(ok.statusCode, 200, ok.body);
    env.secrets.add(ok.json().access_token).add(ok.json().refresh_token);
  });

  it('서버가 실행 중이면 복원을 거부', async () => {
    const env = await setup({ scan: false });
    cleanups.push(() => env.close());
    const snap = createBackup(env.ctx.store, env.ctx.config, 'manual');
    // 다른 살아 있는 프로세스의 pid를 기록한 것처럼
    const sleeper = spawn(process.execPath, ['-e', 'setTimeout(()=>{},30000)'], { stdio: 'ignore' });
    cleanups.push(() => { sleeper.kill('SIGKILL'); });
    writeFileSync(join(env.ctx.config.dataDir, 'server.pid'), String(sleeper.pid));
    assert.throws(() => restoreBackup(env.ctx.config, dbPath(env.ctx.config), snap), /실행 중/);
    rmSync(join(env.ctx.config.dataDir, 'server.pid'));
  });
});

describe('FN-11 마이그레이션 실패 주입', () => {
  it('실패한 마이그레이션은 롤백되고, 이전 버전 서버가 같은 데이터로 기동', async () => {
    const env = await setup();
    cleanups.push(() => env.close());
    const s = await loginAs(env, ADMIN);
    const before = (await call(env, { url: '/v1/tracks?limit=200', token: s.access_token })).json().items.length;
    await env.app.close();
    await env.ctx.jobs.stop();
    env.ctx.store.close();

    const migDir = mkdtempSync(join(tmpdir(), 'bm-mig-'));
    cleanups.push(() => rmSync(migDir, { recursive: true, force: true }));
    for (const m of loadMigrations()) writeFileSync(join(migDir, m.name), m.sql);
    writeFileSync(join(migDir, '0099_broken.sql'), "ALTER TABLE tracks ADD COLUMN extra TEXT;\nUPDATE tracks SET extra = 'x';\nCREATE TABLE oops (;");
    const store = new Store(dbPath(env.ctx.config));
    const snaps: string[] = [];
    assert.throws(() => migrate(store, { migrations: loadMigrations(migDir), snapshot: (r) => { snaps.push(createBackup(store, env.ctx.config, r)); } }));
    assert.equal(snaps.length, 1, '실패하기 전 스냅샷');
    const cols = (store.all<{ name: string }>('PRAGMA table_info(tracks)')).map((c) => c.name);
    assert.ok(!cols.includes('extra'), '부분 적용 없음');
    assert.equal(Number(store.get<{ v: number }>('SELECT MAX(version) AS v FROM schema_migrations')!.v), 2);
    store.close();

    const ctx2 = openCtx(env.ctx.config); // 이전 버전(현재 코드) 서버로 기동
    const app2 = startServer(ctx2);
    await app2.ready();
    Object.assign(env, { ctx: ctx2, app: app2 });
    assert.equal((await call(env, { url: '/v1/tracks?limit=200', token: s.access_token })).json().items.length, before);
  });
});

describe('FN-20 버전 호환 (서버 측)', () => {
  it('오래된 앱: GET /server는 읽을 수 있고 나머지는 426. 최신 앱과 헤더 없는 요청은 정상', async () => {
    const env = await setup({ scan: false, overrides: { minClientApiMinor: 1 } });
    cleanups.push(() => env.close());
    const old = { 'bangmusic-client': 'android/0.9.0 api=1.0' };
    const info = await call(env, { url: '/v1/server', headers: old });
    expectContract(info, 'getServerInfo');
    assert.equal(info.statusCode, 200);
    assert.equal(info.json().min_client_api_minor, 1);
    const login = await call(env, { method: 'POST', url: '/v1/auth/login', headers: old, body: { ...ADMIN, device: device() } });
    expectContract(login, 'login');
    assert.equal(login.statusCode, 426);
    assert.equal(login.json().code, 'client_too_old');
    const s = await loginAs(env, ADMIN);
    const tracks = await call(env, { url: '/v1/tracks', token: s.access_token, headers: old });
    expectContract(tracks, 'listTracks');
    assert.equal(tracks.statusCode, 426);
    assert.equal((await call(env, { url: '/v1/tracks', token: s.access_token, headers: { 'bangmusic-client': 'android/1.1.0 api=1.1' } })).statusCode, 200);
    assert.equal((await call(env, { url: '/v1/tracks', token: s.access_token, headers: { 'bangmusic-client': 'android/2.0.0 api=1.7' } })).statusCode, 200, '서버보다 새 앱도 /v1 안에서는 동작');
  });
});

describe('점검 모드', () => {
  it('MAINTENANCE 파일이 있으면 서버 정보 외 503 maintenance', async () => {
    const env = await setup({ scan: false });
    cleanups.push(() => env.close());
    writeFileSync(join(env.ctx.config.dataDir, 'MAINTENANCE'), 'x');
    await new Promise((ok) => setTimeout(ok, 2100)); // 확인 주기
    const r = await call(env, { method: 'POST', url: '/v1/auth/login', body: { ...ADMIN, device: device() } });
    expectContract(r, 'login');
    assert.equal(r.statusCode, 503);
    assert.equal(r.json().code, 'maintenance');
    assert.equal((await call(env, { url: '/v1/server' })).statusCode, 200);
    rmSync(join(env.ctx.config.dataDir, 'MAINTENANCE'));
  });
});

describe('SEC-15 음악 원본에 쓰지 않는다 (L1: 파일 트리 비교)', () => {
  it('스캔·변환·표지·가사 입력·백업을 거쳐도 라이브러리 파일이 바이트·mtime까지 그대로', async () => {
    const env = await setup({ scan: false });
    cleanups.push(() => env.close());
    const lib = join(env.music, 'lib1');
    const before = treeHash(lib);
    await scanLibrary(env.ctx, env.lib1);
    const s = await loginAs(env, ADMIN);
    const tracks = (await call(env, { url: '/v1/tracks?limit=200', token: s.access_token })).json().items as Array<{ id: string; title: string }>;
    for (const t of tracks.slice(0, 6)) {
      await call(env, { method: 'POST', url: `/v1/tracks/${t.id}/renditions`, token: s.access_token, body: { purpose: 'stream', quality: 'aac_128', accept: [{ container: 'm4a', codec: 'aac' }] } });
    }
    await env.ctx.jobs.idle();
    const yoake = tracks.find((t) => t.title === '夜明けのうた')!;
    const cur = await call(env, { url: `/v1/tracks/${yoake.id}/lyrics`, token: s.access_token });
    await call(env, { method: 'PUT', url: `/v1/tracks/${yoake.id}/lyrics/original`, token: s.access_token, headers: { 'if-match': String(cur.headers.etag) }, body: { format: 'plain', body: '직접 입력' } });
    createBackup(env.ctx.store, env.ctx.config, 'manual');
    await scanLibrary(env.ctx, env.lib1);
    assert.equal(treeHash(lib), before);
  });
});

describe('관리 명령: admin password (비밀번호 재설정)', () => {
  it('비밀번호를 바꾸면 옛 비밀번호는 거부, 새 비밀번호로 로그인, 기존 세션은 끝남. 짧은 비밀번호·없는 사용자는 거부', async () => {
    const env = await setup({ scan: false });
    cleanups.push(() => env.close());
    const old = await loginAs(env, ADMIN);
    const cli = (args: string[], input: string) => spawnSync(process.execPath, [MAIN, ...args], {
      env: { ...process.env, BANGMUSIC_DATA_DIR: env.ctx.config.dataDir, BANGMUSIC_CACHE_DIR: env.ctx.config.cacheDir, BANGMUSIC_LOG_FILE: join(env.dir, 'cli.log') },
      input, encoding: 'utf8',
    });
    const fresh = 'new-password-456';
    env.secrets.add(fresh);
    const short = cli(['admin', 'password', ADMIN.username], 'short\n');
    assert.notEqual(short.status, 0, '10자 미만 거부');
    assert.equal((await call(env, { url: '/v1/me', token: old.access_token })).statusCode, 200, '거부되면 아무것도 바뀌지 않는다');
    assert.notEqual(cli(['admin', 'password', 'nobody'], `${fresh}\n`).status, 0, '없는 사용자');

    const r = cli(['admin', 'password', ADMIN.username.toUpperCase()], `${fresh}\n`); // 사용자 이름은 정규화해서 찾는다
    assert.equal(r.status, 0, r.stderr);
    assert.ok(!r.stdout.includes(fresh) && !r.stderr.includes(fresh), '비밀번호를 출력하지 않는다');
    assert.equal((await call(env, { method: 'POST', url: '/v1/auth/login', body: { ...ADMIN, device: device() } })).statusCode, 401, '옛 비밀번호');
    const me = await call(env, { url: '/v1/me', token: old.access_token });
    assert.equal(me.statusCode, 401, '기존 세션은 끝난다');
    assert.equal(me.json().code, 'session_revoked');
    await loginAs(env, { username: ADMIN.username, password: fresh });
  });
});
