// 백업·복원 (01장 §5.2~5.3).
// 스냅샷 = /data/backups/<UTC>-<이유>/ { db.sqlite (VACUUM INTO), secrets/signing.key }
// 표지 마스터는 내용 해시 이름이라 /data/backups/artwork/ 한 곳에 증분 복사한다.
// 변환 캐시는 백업하지 않는다(재생성 가능). 음악 원본은 이 서버의 책임 밖이다.
import { chmodSync, copyFileSync, existsSync, mkdirSync, readdirSync, readFileSync, renameSync, rmSync, statSync } from 'node:fs';
import { basename, join } from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import type { Config } from './config.ts';
import type { Store } from './db/store.ts';

const stamp = () => new Date().toISOString().replace(/[-:]/g, '').replace(/\.\d+Z$/, 'Z');
export const backupsDir = (config: Config) => join(config.dataDir, 'backups');
const artworkPool = (config: Config) => join(backupsDir(config), 'artwork');
const SNAPSHOT_RE = /^\d{8}T\d{6}Z-[\w-]+$/;

export function createBackup(store: Store, config: Config, reason: string): string {
  const dir = join(backupsDir(config), `${stamp()}-${reason.replace(/[^\w-]/g, '_')}`);
  mkdirSync(dir, { recursive: true, mode: 0o700 });
  store.exec(`VACUUM INTO '${join(dir, 'db.sqlite').replace(/'/g, "''")}'`);
  const key = join(config.dataDir, 'secrets', 'signing.key');
  if (existsSync(key)) {
    mkdirSync(join(dir, 'secrets'), { recursive: true, mode: 0o700 });
    copyFileSync(key, join(dir, 'secrets', 'signing.key'));
    try { chmodSync(join(dir, 'secrets', 'signing.key'), 0o600); } catch { /* Windows */ }
  }
  const art = join(config.dataDir, 'artwork');
  if (existsSync(art)) {
    mkdirSync(artworkPool(config), { recursive: true });
    for (const f of readdirSync(art)) {
      if (f.startsWith('.')) continue;
      const target = join(artworkPool(config), f);
      if (!existsSync(target)) copyFileSync(join(art, f), target);
    }
  }
  prune(config);
  return dir;
}

export function listBackups(config: Config): string[] {
  if (!existsSync(backupsDir(config))) return [];
  return readdirSync(backupsDir(config)).filter((n) => SNAPSHOT_RE.test(n) && existsSync(join(backupsDir(config), n, 'db.sqlite'))).sort();
}

/** 최근 N개만 남긴다 */
function prune(config: Config) {
  const all = listBackups(config);
  for (const old of all.slice(0, Math.max(0, all.length - config.backupKeep))) {
    rmSync(join(backupsDir(config), old), { recursive: true, force: true });
  }
}

function integrityOk(file: string): boolean {
  try {
    const db = new DatabaseSync(file, { readOnly: true });
    const r = db.prepare('PRAGMA quick_check').get() as { quick_check: string };
    db.close();
    return r.quick_check === 'ok';
  } catch {
    return false;
  }
}

/** 서버가 실행 중인지 (serve가 쓰는 pid 파일) */
export function serverRunning(config: Config): number | null {
  const pidFile = join(config.dataDir, 'server.pid');
  if (!existsSync(pidFile)) return null;
  const pid = Number(readFileSync(pidFile, 'utf8').trim());
  if (!Number.isInteger(pid) || pid <= 0 || pid === process.pid) return null;
  try {
    process.kill(pid, 0);
    return pid;
  } catch {
    return null;
  }
}

/**
 * 복원 (01장 §5.3). 서버가 멈춘 상태에서만.
 * 1) 스냅샷 무결성 검사 2) 현재 DB를 db-pre-restore-<UTC>로 보관 후 교체 3) 서명 키·표지 복원
 * 4) 보관한 현재 DB에 있던 세션을 옮겨 온다(스냅샷 이후 회전한 리프레시 토큰으로도 재로그인 없이 복귀)
 * 이후 기동(openCtx)에서 마이그레이션, 캐시 없는 렌디션 정리, 액세스 토큰 무효화가 이어진다(finishRestore).
 */
export function restoreBackup(config: Config, dbFile: string, snapshot: string): { preRestore: string | null } {
  const running = serverRunning(config);
  if (running) throw new Error(`서버가 실행 중이다(pid ${running}). 먼저 멈춰라`);
  const dir = existsSync(join(snapshot, 'db.sqlite')) ? snapshot : join(backupsDir(config), basename(snapshot));
  const snapDb = join(dir, 'db.sqlite');
  if (!existsSync(snapDb)) throw new Error('스냅샷에 db.sqlite가 없다');
  if (!integrityOk(snapDb)) throw new Error('스냅샷 무결성 검사 실패');

  let preRestore: string | null = null;
  if (existsSync(dbFile)) {
    preRestore = join(backupsDir(config), `db-pre-restore-${stamp()}.sqlite`);
    mkdirSync(backupsDir(config), { recursive: true });
    renameSync(dbFile, preRestore);
  }
  for (const ext of ['-wal', '-shm']) rmSync(dbFile + ext, { force: true });
  mkdirSync(join(dbFile, '..'), { recursive: true });
  copyFileSync(snapDb, dbFile);

  const key = join(dir, 'secrets', 'signing.key');
  if (existsSync(key)) {
    mkdirSync(join(config.dataDir, 'secrets'), { recursive: true, mode: 0o700 });
    copyFileSync(key, join(config.dataDir, 'secrets', 'signing.key'));
  }
  if (existsSync(artworkPool(config))) {
    const art = join(config.dataDir, 'artwork');
    mkdirSync(art, { recursive: true });
    for (const f of readdirSync(artworkPool(config))) {
      if (!existsSync(join(art, f))) copyFileSync(join(artworkPool(config), f), join(art, f));
    }
  }

  if (preRestore && integrityOk(preRestore) && statSync(preRestore).size > 0) {
    const db = new DatabaseSync(dbFile);
    try {
      db.exec(`ATTACH DATABASE '${preRestore.replace(/'/g, "''")}' AS cur`);
      const hasSessions = db.prepare("SELECT 1 FROM cur.sqlite_master WHERE type = 'table' AND name = 'sessions'").get();
      if (hasSessions) {
        // 두 DB의 스키마 버전이 다를 수 있으므로 공통 열만 옮긴다
        const cols = (t: string) => new Set((db.prepare(`PRAGMA ${t}.table_info(sessions)`).all() as { name: string }[]).map((c) => c.name));
        const main = cols('main');
        const common = [...cols('cur')].filter((c) => main.has(c)).join(', ');
        db.exec(`INSERT OR REPLACE INTO main.sessions (${common}) SELECT ${common} FROM cur.sessions WHERE user_id IN (SELECT id FROM main.users)`);
      }
      db.exec('DETACH DATABASE cur');
    } finally {
      db.close();
    }
  }
  return { preRestore };
}

/** 복원 후 첫 기동에서 할 일: 캐시 파일이 없는 렌디션 정리는 recoverCache가, 액세스 토큰 무효화는 여기서 */
export function invalidateAccessTokens(store: Store) {
  store.run('UPDATE sessions SET access_expires_at = 0 WHERE revoked_at IS NULL');
}
