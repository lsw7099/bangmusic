// 개인 자원 라우트: 플레이리스트, 가사, 재생 기록, 홈, 계정 삭제·내보내기.
import type { FastifyReply, FastifyRequest } from 'fastify';
import { ingestArtwork } from '../artwork.ts';
import type { Principal } from '../auth/sessions.ts';
import type { Ctx } from '../ctx.ts';
import { deleteHistory, postEvents, recent, top, type PlayEventIn } from '../history.ts';
import { isId } from '../ids.ts';
import { getLyrics, lyricsEtag, putLyrics, putOffset, type LyricsKind } from '../lyrics/lyrics.ts';
import { deleteMe, exportMe, home } from '../me.ts';
import * as pl from '../playlists.ts';
import type { Api } from './app.ts';
import { badRequest, notFound } from './problem.ts';

type Paged = { cursor?: string; limit: number };
export const MAX_COVER_BYTES = 5 * 1024 * 1024;
const IDEMPOTENCY_TTL_MS = 24 * 3600 * 1000;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function requireId(kind: Parameters<typeof isId>[0], value: string): string {
  if (!isId(kind, value)) throw notFound();
  return value;
}

interface Outcome {
  status: number;
  body: unknown;
  headers: Record<string, string>;
}

/**
 * Idempotency-Key (02장 §4): 같은 키의 재요청은 처음 결과를 그대로 돌려준다(24시간).
 * 재요청 확인이 버전 검사보다 먼저다 — 응답을 못 받은 편집을 다시 보내도 412가 나지 않는다.
 */
function idempotent(ctx: Ctx, p: Principal, req: FastifyRequest, reply: FastifyReply, operation: string, fn: () => Outcome) {
  const key = req.headers['idempotency-key'];
  const send = (o: Outcome) => {
    for (const [k, v] of Object.entries(o.headers)) reply.header(k, v);
    return reply.code(o.status).send(o.body);
  };
  if (key === undefined) return send(fn());
  if (typeof key !== 'string' || !UUID.test(key)) throw badRequest('Idempotency-Key', 'UUID여야 한다');
  const now = Date.now();
  const prior = ctx.store.get<{ status: number; headers: string; body: string; created_at: number }>(
    'SELECT status, headers, body, created_at FROM idempotency_keys WHERE user_id = ? AND key = ? AND operation = ?', p.user.id, key, operation);
  if (prior && now - prior.created_at < IDEMPOTENCY_TTL_MS) {
    return send({ status: prior.status, headers: { ...JSON.parse(prior.headers), 'idempotent-replay': 'true' }, body: JSON.parse(prior.body) });
  }
  const out = fn();
  ctx.store.run('DELETE FROM idempotency_keys WHERE created_at < ?', now - IDEMPOTENCY_TTL_MS);
  ctx.store.run(`INSERT OR REPLACE INTO idempotency_keys (user_id, key, operation, status, headers, body, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)`,
    p.user.id, key, operation, out.status, JSON.stringify(out.headers), JSON.stringify(out.body), now);
  return send(out);
}

export function registerPersonalRoutes(ctx: Ctx, api: Api) {
  // ── 홈·본인 ──
  api.op<never, { limit: number }>('getHome', { handler: (req, _r, p) => home(ctx, p, req.query.limit) });
  api.op<never, never, { password: string }>('deleteMe', {
    handler: (req, reply, p) => {
      deleteMe(ctx, p, req.body.password);
      return reply.code(204).send();
    },
  });
  api.op('exportMe', {
    handler: (_req, reply, p) => {
      reply.header('content-disposition', 'attachment; filename="bangmusic-export.json"');
      return exportMe(ctx, p);
    },
  });

  // ── 가사 ──
  api.op<{ trackId: string }>('getLyrics', {
    handler: async (req, reply, p) => {
      const id = requireId('track', req.params.trackId);
      const body = await getLyrics(ctx, p, id); // 권한 확인을 겸하므로 304보다 먼저
      const etag = lyricsEtag(ctx, p, id);
      reply.header('etag', etag);
      if (req.headers['if-none-match'] === etag) return reply.code(304).send();
      return body;
    },
  });
  api.op<{ trackId: string; kind: LyricsKind }, never, { format: 'lrc' | 'plain'; body: string; language?: string; source_name?: string; license_note?: string }>('putLyricsVariant', {
    auth: 'admin', // 일반 사용자는 403 (계약)
    handler: async (req, reply, p) => {
      const id = requireId('track', req.params.trackId);
      const out = await putLyrics(ctx, p, id, req.params.kind, req.headers['if-match'], req.body);
      reply.header('etag', lyricsEtag(ctx, p, id));
      return out;
    },
  });
  api.op<{ trackId: string }, never, { offset_ms: number }>('putLyricsOffset', {
    handler: (req, reply, p) => {
      putOffset(ctx, p, requireId('track', req.params.trackId), req.body.offset_ms);
      return reply.code(204).send();
    },
  });

  // ── 재생 기록 ──
  api.op<never, never, { events: PlayEventIn[] }>('postPlayEvents', { handler: (req, _r, p) => postEvents(ctx, p, req.body.events) });
  api.op<never, Paged>('getRecentTracks', { handler: (req, _r, p) => recent(ctx, p, req.query) });
  api.op<never, { window: string; limit: number }>('getTopTracks', { handler: (req, _r, p) => top(ctx, p, req.query) });
  api.op('deleteHistory', {
    handler: (_req, reply, p) => {
      deleteHistory(ctx, p.user.id);
      return reply.code(204).send();
    },
  });

  // ── 플레이리스트 ──
  api.op<never, Paged>('listPlaylists', { handler: (req, _r, p) => pl.listPlaylists(ctx, p, req.query) });
  api.op<never, never, { name: string; description?: string; track_ids?: string[] }>('createPlaylist', {
    handler: (req, reply, p) => idempotent(ctx, p, req, reply, 'createPlaylist', () => {
      const r = pl.createPlaylist(ctx, p, req.body);
      return { status: 201, body: r.dto, headers: { etag: r.etag } };
    }),
  });
  api.op<{ playlistId: string }>('getPlaylist', {
    handler: (req, reply, p) => {
      const r = pl.getPlaylist(ctx, p, requireId('playlist', req.params.playlistId));
      reply.header('etag', r.etag);
      return r.dto;
    },
  });
  api.op<{ playlistId: string }, never, { name?: string; description?: string }>('updatePlaylist', {
    handler: (req, reply, p) => {
      const r = pl.updatePlaylist(ctx, p, requireId('playlist', req.params.playlistId), req.headers['if-match'], req.body);
      reply.header('etag', r.etag);
      return r.dto;
    },
  });
  api.op<{ playlistId: string }>('deletePlaylist', {
    handler: (req, reply, p) => {
      pl.deletePlaylist(ctx, p, requireId('playlist', req.params.playlistId));
      return reply.code(204).send();
    },
  });
  api.op<{ playlistId: string }, Paged>('listPlaylistItems', {
    handler: (req, reply, p) => {
      const r = pl.listItems(ctx, p, requireId('playlist', req.params.playlistId), req.query);
      reply.header('etag', r.etag);
      return r.page;
    },
  });
  api.op<{ playlistId: string }, never, { ops: Parameters<typeof pl.editPlaylist>[4] }>('editPlaylist', {
    handler: (req, reply, p) => {
      const id = requireId('playlist', req.params.playlistId);
      return idempotent(ctx, p, req, reply, `editPlaylist:${id}`, () => {
        const r = pl.editPlaylist(ctx, p, id, req.headers['if-match'], req.body.ops);
        return { status: 200, body: r.dto, headers: { etag: r.etag } };
      });
    },
  });
  api.op<{ playlistId: string }, never, Buffer>('putPlaylistCover', {
    handler: async (req, reply, p) => {
      const id = requireId('playlist', req.params.playlistId);
      pl.assertCoverWritable(ctx, p, id, req.headers['if-match']);
      if (!Buffer.isBuffer(req.body) || req.body.length === 0) throw badRequest('body', '이미지가 비었다');
      // 디코딩 후 다시 인코딩한다(EXIF 등 메타데이터 제거). 해석 실패·과도한 픽셀 수는 400 (SEC-13)
      const artId = await ingestArtwork(ctx, req.body, 'upload');
      if (!artId) throw badRequest('body', '이미지를 해석할 수 없다');
      const r = pl.setCover(ctx, p, id, req.headers['if-match'], artId);
      reply.header('etag', r.etag);
      return r.dto;
    },
  });
  api.op<{ playlistId: string }>('deletePlaylistCover', {
    handler: (req, reply, p) => {
      pl.setCover(ctx, p, requireId('playlist', req.params.playlistId), undefined, null);
      return reply.code(204).send();
    },
  });
}
