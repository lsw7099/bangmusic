// 로그인·갱신·취소·인증 (02장 §1). 토큰은 SHA-256 해시만 저장한다. JWT를 쓰지 않는다.
import { ApiError } from '../http/problem.ts';
import { newId } from '../ids.ts';
import { norm } from '../norm.ts';
import type { Ctx } from '../ctx.ts';
import { DUMMY_HASH, open, randomToken, seal, sha256hex, verifyPassword } from './crypto.ts';

export interface UserRow {
  id: string;
  username: string;
  display_name: string | null;
  role: 'admin' | 'member';
  status: 'active' | 'disabled';
  password_hash: string;
  created_at: number;
}

export interface SessionRow {
  id: string;
  user_id: string;
  installation_id: string;
  device_name: string;
  platform: string;
  app_version: string | null;
  refresh_hash: string;
  prev_refresh_hash: string | null;
  rotated_at: number | null;
  rotation_blob: string | null;
  access_hash: string;
  access_expires_at: number;
  refresh_expires_at: number;
  created_at: number;
  last_seen_at: number;
  revoked_at: number | null;
}

export interface Principal {
  user: UserRow;
  session: SessionRow;
}

export interface DeviceInfo {
  name: string;
  platform: string;
  app_version: string;
  installation_id: string;
}

export const normUsername = (u: string) => norm(u).replace(/\s/g, '');

const iso = (ms: number) => new Date(ms).toISOString().replace(/\.\d{3}Z$/, 'Z');

export function userSummary(u: UserRow) {
  return { id: u.id, username: u.username, display_name: u.display_name ?? undefined, role: u.role };
}

function issuePair(ctx: Ctx, now: number) {
  const access = randomToken('bma_');
  const refresh = randomToken('bmr_');
  return {
    access,
    refresh,
    accessExp: now + ctx.config.accessTtlMs,
    refreshExp: now + ctx.config.refreshTtlMs,
  };
}

function tokenResponse(sessionId: string, user: UserRow, p: ReturnType<typeof issuePair>) {
  return {
    session_id: sessionId,
    access_token: p.access,
    access_expires_at: iso(p.accessExp),
    refresh_token: p.refresh,
    refresh_expires_at: iso(p.refreshExp),
    user: userSummary(user),
  };
}

export function login(ctx: Ctx, username: string, password: string, device: DeviceInfo, ip: string) {
  const uname = normUsername(username);
  const keys = [`u:${uname}`, `ip:${ip}`];
  const wait = ctx.limiter.retryAfter(keys);
  if (wait > 0) throw new ApiError(429, 'rate_limited', { headers: { 'retry-after': String(wait) } });

  const user = ctx.store.get<UserRow>('SELECT * FROM users WHERE username = ? AND deleted_at IS NULL', uname);
  const ok = verifyPassword(password, user?.password_hash ?? DUMMY_HASH) && Boolean(user);
  if (!ok || !user) {
    ctx.limiter.fail(keys);
    throw new ApiError(401, 'invalid_credentials');
  }
  if (user.status !== 'active') throw new ApiError(403, 'account_disabled');
  ctx.limiter.reset(`u:${uname}`);

  const now = Date.now();
  const pair = issuePair(ctx, now);
  const sessionId = newId('session');
  ctx.store.tx(() => {
    // 같은 설치(installation_id)로 다시 로그인하면 이전 세션을 대체한다.
    ctx.store.run(
      "UPDATE sessions SET revoked_at = ?, revoke_reason = 'replaced' WHERE user_id = ? AND installation_id = ? AND revoked_at IS NULL",
      now, user.id, device.installation_id,
    );
    ctx.store.run(
      `INSERT INTO sessions (id, user_id, installation_id, device_name, platform, app_version, refresh_hash, refresh_family,
         access_hash, access_expires_at, refresh_expires_at, created_at, last_seen_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      sessionId, user.id, device.installation_id, device.name, device.platform, device.app_version,
      sha256hex(pair.refresh), sessionId, sha256hex(pair.access), pair.accessExp, pair.refreshExp, now, now,
    );
  });
  return tokenResponse(sessionId, user, pair);
}

function revoke(ctx: Ctx, sessionId: string, reason: string) {
  ctx.store.run('UPDATE sessions SET revoked_at = ?, revoke_reason = ?, rotation_blob = NULL WHERE id = ? AND revoked_at IS NULL', Date.now(), reason, sessionId);
}

/**
 * 리프레시 회전 (02장 §1.2). 직전 토큰은 유예 시간(기본 60초) 동안 같은 새 쌍을 다시 받는다.
 * 그 이후 재사용은 탈취로 보고 세션을 폐기한다 (SEC-12).
 */
export function refresh(ctx: Ctx, refreshToken: string) {
  const now = Date.now();
  const h = sha256hex(refreshToken);
  const current = ctx.store.get<SessionRow>('SELECT * FROM sessions WHERE refresh_hash = ?', h);
  if (current) {
    const user = checkSessionUsable(ctx, current, 'refresh');
    if (current.refresh_expires_at <= now) throw new ApiError(401, 'refresh_expired');
    const pair = issuePair(ctx, now);
    const blob = seal(ctx.key.key, JSON.stringify(pair));
    ctx.store.run(
      `UPDATE sessions SET prev_refresh_hash = refresh_hash, refresh_hash = ?, access_hash = ?, access_expires_at = ?,
         refresh_expires_at = ?, rotated_at = ?, rotation_blob = ?, last_seen_at = ? WHERE id = ?`,
      sha256hex(pair.refresh), sha256hex(pair.access), pair.accessExp, pair.refreshExp, now, blob, now, current.id,
    );
    return tokenResponse(current.id, user, pair);
  }

  const previous = ctx.store.get<SessionRow>('SELECT * FROM sessions WHERE prev_refresh_hash = ?', h);
  if (previous) {
    const user = checkSessionUsable(ctx, previous, 'refresh');
    const withinGrace = previous.rotated_at !== null && now - previous.rotated_at <= ctx.config.refreshGraceMs;
    const pair = withinGrace && previous.rotation_blob ? open(ctx.key.key, previous.rotation_blob) : null;
    if (pair) return tokenResponse(previous.id, user, JSON.parse(pair));
    revoke(ctx, previous.id, 'refresh_reuse');
    ctx.log.warn({ session_id: previous.id }, '리프레시 토큰 재사용 감지 — 세션 폐기');
    throw new ApiError(401, 'session_revoked');
  }
  throw new ApiError(401, 'refresh_expired');
}

function checkSessionUsable(ctx: Ctx, s: SessionRow, _use: 'access' | 'refresh'): UserRow {
  if (s.revoked_at !== null) throw new ApiError(401, 'session_revoked');
  const user = ctx.store.get<UserRow>('SELECT * FROM users WHERE id = ? AND deleted_at IS NULL', s.user_id);
  if (!user) throw new ApiError(401, 'session_revoked');
  if (user.status !== 'active') throw new ApiError(401, 'account_disabled');
  return user;
}

/** Authorization: Bearer 인증. 실패 코드를 구분한다 (02장 §6). */
export function authenticate(ctx: Ctx, header: string | undefined): Principal {
  const m = header ? /^Bearer\s+(\S+)$/i.exec(header) : null;
  if (!m) throw new ApiError(401, 'access_invalid');
  const s = ctx.store.get<SessionRow>('SELECT * FROM sessions WHERE access_hash = ?', sha256hex(m[1]!));
  if (!s) throw new ApiError(401, 'access_invalid');
  const user = checkSessionUsable(ctx, s, 'access');
  const now = Date.now();
  if (s.access_expires_at <= now) throw new ApiError(401, 'access_expired');
  if (now - s.last_seen_at > 60_000) ctx.store.run('UPDATE sessions SET last_seen_at = ? WHERE id = ?', now, s.id);
  return { user, session: s };
}

/** 티켓 검증 등에서 세션·사용자 상태만 확인할 때 */
export function principalForSession(ctx: Ctx, sessionId: string): Principal {
  const s = ctx.store.get<SessionRow>('SELECT * FROM sessions WHERE id = ?', sessionId);
  if (!s) throw new ApiError(401, 'session_revoked');
  const user = checkSessionUsable(ctx, s, 'access');
  return { user, session: s };
}

export function logout(ctx: Ctx, p: Principal) {
  revoke(ctx, p.session.id, 'logout');
}

export function listSessions(ctx: Ctx, p: Principal) {
  const rows = ctx.store.all<SessionRow>(
    'SELECT * FROM sessions WHERE user_id = ? AND revoked_at IS NULL AND refresh_expires_at > ? ORDER BY last_seen_at DESC',
    p.user.id, Date.now(),
  );
  return rows.map((s) => ({
    id: s.id,
    device_name: s.device_name,
    platform: s.platform,
    app_version: s.app_version ?? undefined,
    created_at: iso(s.created_at),
    last_seen_at: iso(s.last_seen_at),
    current: s.id === p.session.id,
  }));
}

export function revokeOwnSession(ctx: Ctx, p: Principal, sessionId: string) {
  const s = ctx.store.get<SessionRow>('SELECT * FROM sessions WHERE id = ?', sessionId);
  if (!s || s.user_id !== p.user.id) throw new ApiError(404, 'not_found'); // SEC-05: 남의 세션은 존재도 숨긴다
  revoke(ctx, s.id, 'user');
}

export function revokeAllForUser(ctx: Ctx, userId: string, reason: string, exceptSessionId?: string) {
  ctx.store.run(
    'UPDATE sessions SET revoked_at = ?, revoke_reason = ?, rotation_blob = NULL WHERE user_id = ? AND revoked_at IS NULL AND id != ?',
    Date.now(), reason, userId, exceptSessionId ?? '',
  );
}

export { iso };
