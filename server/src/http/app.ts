// HTTP 앱. 라우트의 메서드·경로·요청 스키마는 openapi.yaml에서 생성한 schemas.json에서 가져온다.
// 응답 오류는 모두 problem+json (02장 §6). 모든 응답에 X-Request-Id.
import { randomBytes } from 'node:crypto';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import Fastify, { type FastifyBaseLogger, type FastifyInstance, type FastifyReply, type FastifyRequest } from 'fastify';
import { hasAdmin } from '../admin.ts';
import { authenticate, type Principal } from '../auth/sessions.ts';
import { verifyTicket } from '../auth/tickets.ts';
import type { Ctx } from '../ctx.ts';
import generated from '../generated/schemas.json' with { type: 'json' };
import { ApiError, problemBody } from './problem.ts';
import { registerRoutes } from './routes.ts';
import { MAX_COVER_BYTES } from './routes-personal.ts';

export const API_MAJOR = 1;
export const API_MINOR = 0;

interface Operation {
  operationId: string;
  method: string;
  url: string;
  security: string[];
  params: object | null;
  querystring: object | null;
  headers: object | null;
  body: object | null;
}

const OPERATIONS = new Map((generated.operations as Operation[]).map((o) => [o.operationId, o]));

declare module 'fastify' {
  interface FastifyRequest {
    principal?: Principal;
  }
}

export type Auth = 'none' | 'bearer' | 'bearer-or-ticket' | 'admin';

export interface RouteDef<P = Record<string, string>, Q = Record<string, unknown>, B = unknown> {
  auth?: Auth;
  /** 미디어 티켓이 가리켜야 하는 자원 ID (bearer-or-ticket) */
  ticketResource?: (req: FastifyRequest) => string;
  handler: (req: FastifyRequest<{ Params: P; Querystring: Q; Body: B }>, reply: FastifyReply, p: Principal) => unknown;
}

export interface Api {
  op<P = Record<string, string>, Q = Record<string, unknown>, B = unknown>(operationId: string, def: RouteDef<P, Q, B>): void;
}

const CLIENT_RE = /\bapi=(\d+)\.(\d+)\b/;

export function buildApp(ctx: Ctx): FastifyInstance {
  const app = Fastify({
    loggerInstance: ctx.log as FastifyBaseLogger,
    genReqId: () => `req_${randomBytes(6).toString('base64url')}`,
    requestIdHeader: false,
    trustProxy: ctx.config.trustProxy.length ? ctx.config.trustProxy : false,
    exposeHeadRoutes: false,
    bodyLimit: 1024 * 1024,
    ajv: { customOptions: { coerceTypes: 'array', useDefaults: true, removeAdditional: false, strict: false, allErrors: false } },
  });

  for (const s of generated.schemas) app.addSchema(s as { $id: string });

  // 플레이리스트 표지 업로드 본문 (image/jpeg|png|webp). 한도를 넘으면 413
  app.addContentTypeParser(['image/jpeg', 'image/png', 'image/webp'], { parseAs: 'buffer', bodyLimit: MAX_COVER_BYTES }, (_req, body, done) => done(null, body));

  // 점검 모드: DATA_DIR/MAINTENANCE 파일이 있으면 서버 정보 외에는 503 maintenance (복원 준비 등)
  const maintenanceFlag = join(ctx.config.dataDir, 'MAINTENANCE');
  let maintenance = { at: 0, on: false };
  const inMaintenance = () => {
    const now = Date.now();
    if (now - maintenance.at > 2000) maintenance = { at: now, on: existsSync(maintenanceFlag) };
    return maintenance.on;
  };

  app.addHook('onRequest', async (req, reply) => {
    reply.header('x-request-id', req.id);
    // 02장 §2.2: 앱의 API minor가 서버 최소값보다 낮으면 426
    const client = req.headers['bangmusic-client'];
    const m = typeof client === 'string' ? CLIENT_RE.exec(client) : null;
    // GET /server는 예외: 오래된 앱도 min_client_api_minor를 읽어 업데이트 안내를 띄울 수 있어야 한다
    if (m && Number(m[1]) === API_MAJOR && Number(m[2]) < ctx.config.minClientApiMinor && req.url.split('?')[0] !== '/v1/server') {
      throw new ApiError(426, 'client_too_old');
    }
  });

  app.setErrorHandler((err: Error & { statusCode?: number; validation?: Array<{ instancePath?: string; params?: { missingProperty?: string }; message?: string }>; validationContext?: string; code?: string }, req, reply) => {
    if (err instanceof ApiError) {
      for (const [k, v] of Object.entries(err.headers)) reply.header(k, v);
      return reply.code(err.status).type('application/problem+json').send(problemBody(err.status, err.code, req.id, err.errors));
    }
    if (err.validation) {
      const errors = err.validation.slice(0, 10).map((v) => ({
        field: `${err.validationContext ?? 'body'}${v.instancePath ?? ''}${v.params?.missingProperty ? `/${v.params.missingProperty}` : ''}`,
        message: v.message ?? 'invalid',
      }));
      return reply.code(400).type('application/problem+json').send(problemBody(400, 'validation_failed', req.id, errors));
    }
    if (err.statusCode && err.statusCode >= 400 && err.statusCode < 500) {
      // 본문 해석 실패, 지원하지 않는 Content-Type 등 Fastify 자체 오류
      // 표지 업로드만 계약에 413/415가 있다. 다른 동작의 형식 오류는 400
      const cover = req.routeOptions.url === '/v1/playlists/:playlistId/cover';
      const status = cover && (err.statusCode === 413 || err.statusCode === 415) ? err.statusCode : 400;
      const code = status === 413 ? 'payload_too_large' : status === 415 ? 'unsupported_media_type' : 'validation_failed';
      return reply.code(status).type('application/problem+json').send(problemBody(status, code, req.id));
    }
    req.log.error({ err: { message: err.message, stack: err.stack } }, '처리되지 않은 오류');
    return reply.code(500).type('application/problem+json').send(problemBody(500, 'internal_error', req.id));
  });

  app.setNotFoundHandler((req, reply) => {
    reply.code(404).type('application/problem+json').send(problemBody(404, 'not_found', req.id));
  });

  const api: Api = {
    op(operationId, def) {
      const o = OPERATIONS.get(operationId);
      if (!o) throw new Error(`계약에 없는 동작: ${operationId}`);
      const auth = def.auth ?? 'bearer';
      app.route({
        method: o.method as 'GET',
        url: o.url,
        schema: {
          ...(o.params ? { params: o.params } : {}),
          ...(o.querystring ? { querystring: o.querystring } : {}),
          ...(o.body ? { body: o.body } : {}),
        },
        handler: async (req, reply) => {
          // 초기 설정(관리자 생성) 전에는 서버 정보만 응답한다
          if (operationId !== 'getServerInfo' && inMaintenance()) throw new ApiError(503, 'maintenance', { headers: { 'retry-after': '60' } });
          if (operationId !== 'getServerInfo' && !hasAdmin(ctx)) throw new ApiError(503, 'setup_required');
          let principal: Principal | undefined;
          if (auth === 'bearer-or-ticket') {
            const mt = (req.query as Record<string, unknown>).mt;
            principal = typeof mt === 'string' && !req.headers.authorization
              ? verifyTicket(ctx, mt, def.ticketResource!(req))
              : authenticate(ctx, req.headers.authorization);
          } else if (auth !== 'none') {
            principal = authenticate(ctx, req.headers.authorization);
            if (auth === 'admin' && principal.user.role !== 'admin') throw new ApiError(403, 'forbidden');
          }
          req.principal = principal;
          const out = await def.handler(req as never, reply, principal!);
          if (reply.sent) return reply;
          return out;
        },
      });
    },
  };

  registerRoutes(ctx, api);
  return app;
}
