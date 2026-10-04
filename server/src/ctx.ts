// 서버 전역 의존성 묶음. HTTP·CLI·작업자가 같은 것을 쓴다.
import { mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { FailureLimiter } from './auth/ratelimit.ts';
import { loadOrCreateSigningKey, type SigningKey } from './auth/crypto.ts';
import type { Config } from './config.ts';
import { createBackup } from './backup.ts';
import { migrate, Store } from './db/store.ts';
import { newId } from './ids.ts';
import { createLogger, type Logger } from './log.ts';
import { JobRunner } from './jobs.ts';

export interface Ctx {
  config: Config;
  store: Store;
  key: SigningKey;
  log: Logger;
  limiter: FailureLimiter;
  jobs: JobRunner;
}

export function dbPath(config: Config) {
  return join(config.dataDir, 'db', 'bangmusic.sqlite');
}

export function openCtx(config: Config, opts: { logger?: Logger } = {}): Ctx {
  const log = opts.logger ?? createLogger(config.logLevel, config.logFile);
  const store = new Store(dbPath(config));
  mkdirSync(join(config.dataDir, 'backups'), { recursive: true });
  // 01장 §5.1: 적용할 마이그레이션이 있으면 먼저 스냅샷(서명 키·표지 포함 백업 묶음)
  const applied = migrate(store, { snapshot: (reason) => createBackup(store, config, reason) });
  if (applied.length) log.info({ applied }, '마이그레이션 적용');
  const key = loadOrCreateSigningKey(config.dataDir);
  store.tx(() => {
    if (!store.get('SELECT 1 FROM server_meta')) {
      store.run('INSERT INTO server_meta (singleton, server_id, name, created_at, signing_key_id) VALUES (1, ?, ?, ?, ?)',
        newId('server'), config.serverName, Date.now(), key.id);
    } else {
      store.run('UPDATE server_meta SET signing_key_id = ? WHERE singleton = 1', key.id);
    }
  });
  const ctx = { config, store, key, log, limiter: new FailureLimiter(config.loginMaxFailures, config.loginWindowMs) } as Ctx;
  ctx.jobs = new JobRunner(ctx);
  return ctx;
}
