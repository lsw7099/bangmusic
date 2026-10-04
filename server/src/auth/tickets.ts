// 미디어 티켓 (02장 §1.4). base64url(payload) "." base64url(HMAC-SHA256(key, payload)).
// payload = {v, sid, uid, res, exp}. 한 자원에만 유효하다. 값은 로그에 남기지 않는다.
import { timingSafeEqual } from 'node:crypto';
import { ApiError } from '../http/problem.ts';
import type { Ctx } from '../ctx.ts';
import { hmac } from './crypto.ts';
import { principalForSession, type Principal } from './sessions.ts';

interface TicketPayload {
  v: 1;
  sid: string;
  uid: string;
  res: string;
  exp: number;
}

export function issueTicket(ctx: Ctx, p: Principal, resourceId: string, now = Date.now()) {
  const payload: TicketPayload = { v: 1, sid: p.session.id, uid: p.user.id, res: resourceId, exp: now + ctx.config.ticketTtlMs };
  const body = Buffer.from(JSON.stringify(payload)).toString('base64url');
  const sig = hmac(ctx.key.key, body).toString('base64url');
  return { ticket: `${body}.${sig}`, expiresAt: payload.exp };
}

/**
 * 검증 순서: 서명 → 만료 → 자원 일치 → 세션 유효 → (호출자가) 라이브러리 접근 권한.
 * 마지막 두 단계 때문에 티켓이 살아 있어도 세션 취소·권한 회수가 즉시 반영된다.
 */
export function verifyTicket(ctx: Ctx, ticket: string, resourceId: string, now = Date.now()): Principal {
  const dot = ticket.indexOf('.');
  if (dot <= 0) throw new ApiError(401, 'ticket_invalid');
  const body = ticket.slice(0, dot);
  const given = Buffer.from(ticket.slice(dot + 1), 'base64url');
  const expected = hmac(ctx.key.key, body);
  if (given.length !== expected.length || !timingSafeEqual(given, expected)) throw new ApiError(401, 'ticket_invalid');
  let payload: TicketPayload;
  try {
    payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
  } catch {
    throw new ApiError(401, 'ticket_invalid');
  }
  if (payload.v !== 1 || typeof payload.exp !== 'number') throw new ApiError(401, 'ticket_invalid');
  if (payload.exp <= now) throw new ApiError(401, 'ticket_expired');
  if (payload.res !== resourceId) throw new ApiError(401, 'ticket_invalid');
  const principal = principalForSession(ctx, payload.sid);
  if (principal.user.id !== payload.uid) throw new ApiError(401, 'ticket_invalid');
  return principal;
}
