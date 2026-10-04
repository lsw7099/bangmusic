// 공개 ID = 유형 접두어 + ULID (01장 §4.1). 경로와 무관하게 최초 발견 시 만든다.
import { createHash, randomBytes } from 'node:crypto';

const CROCKFORD = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

export const PREFIXES = {
  server: 'srv',
  user: 'usr',
  session: 'ses',
  library: 'lib',
  track: 'trk',
  album: 'alb',
  artist: 'art',
  playlist: 'pl',
  playlistItem: 'pli',
  rendition: 'rnd',
  artwork: 'img',
  job: 'job',
  mediaFile: 'mf',
} as const;

export type IdKind = keyof typeof PREFIXES;

export function ulid(now = Date.now()): string {
  let time = '';
  let t = now;
  for (let i = 0; i < 10; i++) {
    time = CROCKFORD[t % 32] + time;
    t = Math.floor(t / 32);
  }
  const rand = randomBytes(16);
  let r = '';
  for (let i = 0; i < 16; i++) r += CROCKFORD[rand[i]! % 32];
  return time + r;
}

export function newId(kind: IdKind): string {
  return `${PREFIXES[kind]}_${ulid()}`;
}

const ID_RE = /^[a-z]{2,3}_[0-9A-HJKMNP-TV-Z]{26}$/;

/** 요청 경로의 ID가 형식에 맞는지. 맞지 않으면 DB를 조회하지 않고 404로 끝낸다 (SEC-01). */
export function isId(kind: IdKind, value: unknown): value is string {
  return typeof value === 'string' && ID_RE.test(value) && value.startsWith(`${PREFIXES[kind]}_`);
}

/** Crockford base32 소문자. 미디어 버전에 쓴다. */
export function base32(buf: Buffer): string {
  let bits = 0;
  let value = 0;
  let out = '';
  for (const byte of buf) {
    value = (value << 8) | byte;
    bits += 8;
    while (bits >= 5) {
      out += CROCKFORD[(value >>> (bits - 5)) & 31];
      bits -= 5;
    }
  }
  if (bits > 0) out += CROCKFORD[(value << (5 - bits)) & 31];
  return out.toLowerCase();
}

/** media_version = base32(sha256(content_hash))[0:16] (01장 §4.3) */
export function mediaVersion(contentHash: string): string {
  return base32(createHash('sha256').update(contentHash).digest()).slice(0, 16);
}
