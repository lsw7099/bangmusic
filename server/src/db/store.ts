// SQLite 접근과 마이그레이션 (01장 §2.4, §5.1).
// WAL, foreign_keys=ON, busy_timeout. 쓰기는 이 프로세스의 단일 커넥션으로 직렬화한다.
import { createHash } from 'node:crypto';
import { mkdirSync, readdirSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { DatabaseSync, type StatementSync } from 'node:sqlite';

const MIGRATIONS_DIR = join(dirname(fileURLToPath(import.meta.url)), 'migrations');

type Param = null | number | bigint | string | Uint8Array;
export type Row = Record<string, unknown>;

export class Store {
  readonly db: DatabaseSync;
  private readonly cache = new Map<string, StatementSync>();
  private txDepth = 0;

  constructor(file: string) {
    if (file !== ':memory:') mkdirSync(dirname(file), { recursive: true });
    this.db = new DatabaseSync(file);
    this.db.exec('PRAGMA journal_mode = WAL; PRAGMA foreign_keys = ON; PRAGMA busy_timeout = 5000; PRAGMA synchronous = NORMAL;');
  }

  private stmt(sql: string): StatementSync {
    let s = this.cache.get(sql);
    if (!s) {
      s = this.db.prepare(sql);
      this.cache.set(sql, s);
    }
    return s;
  }

  get<T = Row>(sql: string, ...params: Param[]): T | undefined {
    return this.stmt(sql).get(...params) as T | undefined;
  }

  all<T = Row>(sql: string, ...params: Param[]): T[] {
    return this.stmt(sql).all(...params) as T[];
  }

  run(sql: string, ...params: Param[]): { changes: number } {
    const r = this.stmt(sql).run(...params);
    return { changes: Number(r.changes) };
  }

  exec(sql: string): void {
    this.db.exec(sql);
  }

  /** 중첩 가능한 트랜잭션 (안쪽은 SAVEPOINT). 예외가 나면 롤백한다. */
  tx<T>(fn: () => T): T {
    const name = `sp${this.txDepth}`;
    this.db.exec(this.txDepth === 0 ? 'BEGIN IMMEDIATE' : `SAVEPOINT ${name}`);
    this.txDepth++;
    try {
      const out = fn();
      this.txDepth--;
      this.db.exec(this.txDepth === 0 ? 'COMMIT' : `RELEASE ${name}`);
      return out;
    } catch (e) {
      this.txDepth--;
      this.db.exec(this.txDepth === 0 ? 'ROLLBACK' : `ROLLBACK TO ${name}; RELEASE ${name}`);
      throw e;
    }
  }

  /** 카탈로그 변경마다 전역 단조 증가 값 (01장 §4.7). 트랜잭션 안에서 부른다. */
  nextChangeSeq(): number {
    this.run('UPDATE server_meta SET change_seq = change_seq + 1 WHERE singleton = 1');
    return Number(this.get<{ s: number }>('SELECT change_seq AS s FROM server_meta WHERE singleton = 1')!.s);
  }

  close(): void {
    this.cache.clear();
    this.db.close();
  }
}

export interface Migration {
  version: number;
  name: string;
  sql: string;
  checksum: string;
}

export function loadMigrations(dir = MIGRATIONS_DIR): Migration[] {
  return readdirSync(dir)
    .filter((f) => /^\d{4}_.+\.sql$/.test(f))
    .sort()
    .map((f) => {
      const sql = readFileSync(join(dir, f), 'utf8').replace(/\r\n/g, '\n');
      return { version: Number(f.slice(0, 4)), name: f, sql, checksum: createHash('sha256').update(sql).digest('hex') };
    });
}

export class MigrationError extends Error {}

/**
 * 기동 시 마이그레이션 (01장 §5.1).
 * 무결성 검사 → (적용할 것이 있으면) 스냅샷 → 한 트랜잭션으로 적용 → 실패 시 롤백 후 기동 중단.
 * 이미 적용된 파일의 체크섬이 다르거나 DB가 더 새 버전이면 기동을 거부한다.
 */
export function migrate(store: Store, opts: { snapshot?: (reason: string) => void; migrations?: Migration[] } = {}): number[] {
  const migrations = opts.migrations ?? loadMigrations();
  const check = store.get<{ quick_check: string }>('PRAGMA quick_check');
  if (check?.quick_check !== 'ok') throw new MigrationError('DB 무결성 검사 실패');

  store.exec('CREATE TABLE IF NOT EXISTS schema_migrations (version INTEGER PRIMARY KEY, name TEXT NOT NULL, applied_at INTEGER NOT NULL, checksum TEXT NOT NULL)');
  const applied = store.all<{ version: number; name: string; checksum: string }>('SELECT version, name, checksum FROM schema_migrations ORDER BY version');
  const known = new Map(migrations.map((m) => [m.version, m]));
  for (const a of applied) {
    const m = known.get(Number(a.version));
    if (!m) throw new MigrationError(`DB 스키마 버전 ${a.version}이 이 서버보다 새롭다. 직전 스냅샷을 복원하라`);
    if (m.checksum !== a.checksum) throw new MigrationError(`적용된 마이그레이션 ${m.name}의 체크섬이 다르다`);
  }
  const done = new Set(applied.map((a) => Number(a.version)));
  const pending = migrations.filter((m) => !done.has(m.version));
  if (pending.length === 0) return [];
  if (applied.length > 0) opts.snapshot?.(`pre-migrate-${pending[0]!.version}`);
  store.tx(() => {
    for (const m of pending) {
      store.exec(m.sql);
      store.run('INSERT INTO schema_migrations (version, name, applied_at, checksum) VALUES (?, ?, ?, ?)', m.version, m.name, Date.now(), m.checksum);
    }
  });
  return pending.map((m) => m.version);
}
