// 설정은 환경 변수로만 받는다(비밀값 제외 — 서명 키는 DATA_DIR/secrets에 생성). 05장 §9.1~9.2.
import { availableParallelism } from 'node:os';
import { resolve } from 'node:path';

export interface Config {
  dataDir: string;
  cacheDir: string;
  host: string;
  port: number;
  serverName: string;
  /** X-Forwarded-*를 믿을 프록시 주소. 비우면 믿지 않는다 (05장 §9.3). */
  trustProxy: string[];
  accessTtlMs: number;
  refreshTtlMs: number;
  ticketTtlMs: number;
  refreshGraceMs: number;
  /** 한 번의 스캔에서 기존 곡 중 이 비율 이상이 사라지면 적용을 보류한다 (01장 §4.4). */
  scanMissingThreshold: number;
  loginMaxFailures: number;
  loginWindowMs: number;
  /** 변환 (03장 §4.6). 기본값은 측정 전 가정 — P2 측정 후 조정 */
  transcodeEnabled: boolean;
  transcodeConcurrency: number;
  transcodeQueueMax: number;
  transcodeTimeoutMs: number;
  cacheMaxBytes: number;
  cacheMinFreeBytes: number;
  /** 매일 자동 백업 시각(UTC 시). 음수면 끈다 */
  backupHourUtc: number;
  backupKeep: number;
  /** 이보다 낮은 API minor의 앱은 426 (02장 §2.2) */
  minClientApiMinor: number;
  ffmpeg: string;
  ffprobe: string;
  logLevel: string;
  /** 로그 파일. 비우면 stdout. */
  logFile: string | null;
  version: string;
}

function num(env: NodeJS.ProcessEnv, key: string, def: number): number {
  const v = env[key];
  if (v === undefined || v === '') return def;
  const n = Number(v);
  if (!Number.isFinite(n)) throw new Error(`${key}는 숫자여야 한다`);
  return n;
}

export const SERVER_VERSION = '0.1.0';

export function loadConfig(env: NodeJS.ProcessEnv = process.env, overrides: Partial<Config> = {}): Config {
  const base: Config = {
    dataDir: resolve(env.BANGMUSIC_DATA_DIR ?? '/data'),
    cacheDir: resolve(env.BANGMUSIC_CACHE_DIR ?? '/cache'),
    host: env.BANGMUSIC_HOST ?? '0.0.0.0',
    port: num(env, 'BANGMUSIC_PORT', 8080),
    serverName: env.BANGMUSIC_SERVER_NAME ?? 'BangMusic',
    trustProxy: (env.BANGMUSIC_TRUST_PROXY ?? '').split(',').map((s) => s.trim()).filter(Boolean),
    accessTtlMs: num(env, 'BANGMUSIC_ACCESS_TTL_S', 3600) * 1000,
    refreshTtlMs: num(env, 'BANGMUSIC_REFRESH_TTL_S', 90 * 86400) * 1000,
    ticketTtlMs: num(env, 'BANGMUSIC_TICKET_TTL_S', 12 * 3600) * 1000,
    refreshGraceMs: num(env, 'BANGMUSIC_REFRESH_GRACE_S', 60) * 1000,
    scanMissingThreshold: num(env, 'BANGMUSIC_SCAN_MISSING_THRESHOLD', 0.2),
    loginMaxFailures: num(env, 'BANGMUSIC_LOGIN_MAX_FAILURES', 5),
    loginWindowMs: num(env, 'BANGMUSIC_LOGIN_WINDOW_S', 300) * 1000,
    transcodeEnabled: (env.BANGMUSIC_TRANSCODE_ENABLED ?? 'true') !== 'false',
    transcodeConcurrency: num(env, 'BANGMUSIC_TRANSCODE_CONCURRENCY', Math.min(2, availableParallelism())),
    transcodeQueueMax: num(env, 'BANGMUSIC_TRANSCODE_QUEUE_MAX', 20),
    transcodeTimeoutMs: num(env, 'BANGMUSIC_TRANSCODE_TIMEOUT_S', 600) * 1000,
    cacheMaxBytes: num(env, 'BANGMUSIC_CACHE_MAX_BYTES', 10 * 1024 ** 3),
    cacheMinFreeBytes: num(env, 'BANGMUSIC_CACHE_MIN_FREE_BYTES', 1024 ** 3),
    backupHourUtc: num(env, 'BANGMUSIC_BACKUP_HOUR_UTC', 18),
    backupKeep: num(env, 'BANGMUSIC_BACKUP_KEEP', 14),
    minClientApiMinor: num(env, 'BANGMUSIC_MIN_CLIENT_API_MINOR', 0),
    ffmpeg: env.FFMPEG ?? 'ffmpeg',
    ffprobe: env.FFPROBE ?? 'ffprobe',
    logLevel: env.BANGMUSIC_LOG_LEVEL ?? 'info',
    logFile: env.BANGMUSIC_LOG_FILE || null,
    version: SERVER_VERSION,
  };
  return { ...base, ...overrides };
}
