// 비밀번호 해시(Argon2id), 토큰, 서명 키. 토큰·비밀번호 원문은 저장하지도 로그에 남기지도 않는다.
import {
  argon2Sync, createCipheriv, createDecipheriv, createHash, createHmac, hkdfSync,
  randomBytes, timingSafeEqual,
} from 'node:crypto';
import { chmodSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

// OWASP 권장 최소값 (m=19 MiB, t=2, p=1)
const ARGON = { memory: 19456, passes: 2, parallelism: 1, tagLength: 32 };

export function hashPassword(password: string): string {
  const salt = randomBytes(16);
  const tag = argon2Sync('argon2id', { message: password, nonce: salt, ...ARGON });
  return `$argon2id$v=19$m=${ARGON.memory},t=${ARGON.passes},p=${ARGON.parallelism}$${salt.toString('base64url')}$${tag.toString('base64url')}`;
}

export function verifyPassword(password: string, phc: string): boolean {
  const m = /^\$argon2id\$v=19\$m=(\d+),t=(\d+),p=(\d+)\$([\w-]+)\$([\w-]+)$/.exec(phc);
  if (!m) return false;
  const expected = Buffer.from(m[5]!, 'base64url');
  const tag = argon2Sync('argon2id', {
    message: password,
    nonce: Buffer.from(m[4]!, 'base64url'),
    memory: Number(m[1]),
    passes: Number(m[2]),
    parallelism: Number(m[3]),
    tagLength: expected.length,
  });
  return tag.length === expected.length && timingSafeEqual(tag, expected);
}

/** 사용자가 없을 때도 같은 시간을 쓰게 하는 더미 해시 (사용자 존재 여부 노출 방지) */
export const DUMMY_HASH = hashPassword(randomBytes(16).toString('hex'));

export function randomToken(prefix: string): string {
  return `${prefix}${randomBytes(32).toString('base64url')}`;
}

export function sha256hex(value: string | Buffer): string {
  return createHash('sha256').update(value).digest('hex');
}

export interface SigningKey {
  id: string;
  key: Buffer;
}

/** 티켓 서명 키. 최초 기동 시 무작위 생성, 권한 600 (05장 §9.2). 이미지·환경 변수·로그에 두지 않는다. */
export function loadOrCreateSigningKey(dataDir: string): SigningKey {
  const dir = join(dataDir, 'secrets');
  const file = join(dir, 'signing.key');
  if (!existsSync(file)) {
    mkdirSync(dir, { recursive: true, mode: 0o700 });
    writeFileSync(file, randomBytes(32).toString('hex') + '\n', { mode: 0o600, flag: 'wx' });
    try { chmodSync(file, 0o600); } catch { /* Windows: 무시 */ }
  }
  const key = Buffer.from(readFileSync(file, 'utf8').trim(), 'hex');
  if (key.length < 32) throw new Error('서명 키 파일이 손상되었다');
  return { id: sha256hex(key).slice(0, 12), key };
}

export function hmac(key: Buffer, data: string): Buffer {
  return createHmac('sha256', key).update(data).digest();
}

function subKey(key: Buffer, info: string): Buffer {
  return Buffer.from(hkdfSync('sha256', key, Buffer.alloc(0), info, 32));
}

/** 리프레시 재시도 유예 동안 같은 토큰 쌍을 돌려주기 위한 단기 암호문 (AES-256-GCM). */
export function seal(key: Buffer, plaintext: string): string {
  const iv = randomBytes(12);
  const c = createCipheriv('aes-256-gcm', subKey(key, 'refresh-rotation'), iv);
  const body = Buffer.concat([c.update(plaintext, 'utf8'), c.final()]);
  return Buffer.concat([iv, c.getAuthTag(), body]).toString('base64url');
}

export function open(key: Buffer, sealed: string): string | null {
  try {
    const raw = Buffer.from(sealed, 'base64url');
    const d = createDecipheriv('aes-256-gcm', subKey(key, 'refresh-rotation'), raw.subarray(0, 12));
    d.setAuthTag(raw.subarray(12, 28));
    return Buffer.concat([d.update(raw.subarray(28)), d.final()]).toString('utf8');
  } catch {
    return null;
  }
}
