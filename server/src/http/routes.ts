// 라우트: 서버 정보, 인증, 본인, 카탈로그, 표지, 렌디션·미디어, 관리.
// 개인 자원(플레이리스트·가사·재생 기록·홈·본인 데이터)은 routes-personal.ts.
import { createReadStream } from 'node:fs';
import { adminUserDto, createUser, deleteUser, hasAdmin, listLibrariesAdmin, updateUser } from '../admin.ts';
import { ARTWORK_SIZES, artworkFile, type ArtworkRow } from '../artwork.ts';
import { hashPassword, verifyPassword } from '../auth/crypto.ts';
import { listSessions, login, logout, refresh, revokeAllForUser, revokeOwnSession, userSummary, type DeviceInfo } from '../auth/sessions.ts';
import * as catalog from '../catalog/catalog.ts';
import type { Ctx } from '../ctx.ts';
import { isId } from '../ids.ts';
import { jobDto } from '../jobs.ts';
import { getRendition, resolveRendition, serveMedia } from '../media/media.ts';
import { profileNames } from '../media/transcode.ts';
import { API_MAJOR, API_MINOR, type Api } from './app.ts';
import { registerPersonalRoutes } from './routes-personal.ts';
import { badRequest, notFound } from './problem.ts';

type Paged = { cursor?: string; limit: number };

/** SEC-01: 형식이 맞지 않는 ID는 DB를 조회하지 않고 404 */
function requireId(kind: Parameters<typeof isId>[0], value: string): string {
  if (!isId(kind, value)) throw notFound();
  return value;
}

export function registerRoutes(ctx: Ctx, api: Api) {
  registerPersonalRoutes(ctx, api);

  // ── 서버 ──
  api.op('getServerInfo', {
    auth: 'none',
    handler: () => {
      const meta = ctx.store.get<{ server_id: string; name: string }>('SELECT server_id, name FROM server_meta')!;
      return {
        server_id: meta.server_id,
        name: meta.name,
        product: 'bangmusic-server',
        version: ctx.config.version,
        api: { major: API_MAJOR, minor: API_MINOR },
        min_client_api_minor: ctx.config.minClientApiMinor,
        features: ['change_feed', 'lyrics', 'playlist_covers', 'history', ...(ctx.config.transcodeEnabled ? ['transcode'] : [])],
        transcode_profiles: profileNames(ctx),
        limits: { max_page_size: 200, max_history_batch: 500, max_cover_bytes: 5 * 1024 * 1024 },
        setup_required: !hasAdmin(ctx),
      };
    },
  });

  // ── 인증 ──
  api.op<never, never, { username: string; password: string; device: DeviceInfo }>('login', {
    auth: 'none',
    handler: (req) => login(ctx, req.body.username, req.body.password, req.body.device, req.ip),
  });
  api.op<never, never, { refresh_token: string }>('refreshToken', {
    auth: 'none',
    handler: (req) => refresh(ctx, req.body.refresh_token),
  });
  api.op('logout', {
    handler: (_req, reply, p) => {
      logout(ctx, p);
      return reply.code(204).send();
    },
  });
  api.op('listSessions', { handler: (_req, _reply, p) => ({ items: listSessions(ctx, p) }) });
  api.op<{ sessionId: string }>('revokeSession', {
    handler: (req, reply, p) => {
      revokeOwnSession(ctx, p, requireId('session', req.params.sessionId));
      return reply.code(204).send();
    },
  });

  // ── 본인 ──
  api.op('getMe', {
    handler: (_req, _reply, p) => ({ ...userSummary(p.user), libraries: catalog.accessibleLibraries(ctx, p) }),
  });
  api.op<never, never, { current_password: string; new_password: string }>('changePassword', {
    handler: (req, reply, p) => {
      if (!verifyPassword(req.body.current_password, p.user.password_hash)) throw badRequest('current_password', '현재 비밀번호가 다름');
      ctx.store.tx(() => {
        ctx.store.run('UPDATE users SET password_hash = ? WHERE id = ?', hashPassword(req.body.new_password), p.user.id);
        revokeAllForUser(ctx, p.user.id, 'password_changed', p.session.id); // 현재 세션 외 전부 폐기
      });
      return reply.code(204).send();
    },
  });

  // ── 카탈로그 ──
  api.op<never, Paged & { sort: string; album_id?: string; artist_id?: string; library_id?: string }>('listTracks', {
    handler: (req, _reply, p) => catalog.listTracks(ctx, p, req.query),
  });
  api.op<{ trackId: string }>('getTrack', {
    handler: (req, _reply, p) => catalog.getTrack(ctx, p, requireId('track', req.params.trackId)),
  });
  api.op<never, Paged & { sort: string; artist_id?: string }>('listAlbums', {
    handler: (req, _reply, p) => catalog.listAlbums(ctx, p, req.query),
  });
  api.op<{ albumId: string }>('getAlbum', {
    handler: (req, _reply, p) => catalog.getAlbum(ctx, p, requireId('album', req.params.albumId)),
  });
  api.op<never, Paged>('listArtists', {
    handler: (req, _reply, p) => catalog.listArtists(ctx, p, req.query),
  });
  api.op<{ artistId: string }>('getArtist', {
    handler: (req, _reply, p) => catalog.getArtist(ctx, p, requireId('artist', req.params.artistId)),
  });
  api.op<never, Paged & { q: string; types?: string }>('search', {
    handler: (req, _reply, p) => catalog.search(ctx, p, req.query),
  });
  api.op<never, { since: string; limit: number }>('getChanges', {
    handler: (req, _reply, p) => catalog.changes(ctx, p, req.query),
  });

  // ── 표지 ──
  api.op<{ artworkId: string }, { size: number }>('getArtwork', {
    auth: 'bearer-or-ticket',
    ticketResource: (req) => (req.params as { artworkId: string }).artworkId,
    handler: async (req, reply, p) => {
      const id = requireId('artwork', req.params.artworkId);
      if (!catalog.canSeeArtwork(ctx, p, id)) throw notFound();
      const art = ctx.store.get<ArtworkRow>('SELECT * FROM artworks WHERE id = ?', id);
      if (!art) throw notFound();
      const size = req.query.size;
      if (!(ARTWORK_SIZES as readonly number[]).includes(size)) throw badRequest('size', '지원하지 않는 크기');
      const etag = `"${art.id}-${size}"`;
      reply.header('etag', etag).header('cache-control', 'private, max-age=31536000, immutable');
      if (req.headers['if-none-match'] === etag) return reply.code(304).send();
      const file = await artworkFile(ctx, art, size);
      return reply.type('image/jpeg').send(createReadStream(file));
    },
  });

  // ── 렌디션·미디어 ──
  api.op<{ trackId: string }, never, { purpose: string; quality: string; accept: { container: string; codec: string }[] }>('resolveRendition', {
    handler: (req, reply, p) => {
      const r = resolveRendition(ctx, p, requireId('track', req.params.trackId), req.body);
      for (const [k, v] of Object.entries(r.headers)) reply.header(k, v);
      return reply.code(r.status).send(r.body);
    },
  });
  api.op<{ renditionId: string }>('getRendition', {
    handler: (req, _reply, p) => getRendition(ctx, p, requireId('rendition', req.params.renditionId)),
  });
  for (const opId of ['getMedia', 'headMedia'] as const) {
    api.op<{ renditionId: string }>(opId, {
      auth: 'bearer-or-ticket',
      ticketResource: (req) => (req.params as { renditionId: string }).renditionId,
      handler: (req, reply, p) => {
        const rid = requireId('rendition', req.params.renditionId);
        const range = req.headers.range;
        const ifRange = req.headers['if-range'];
        return serveMedia(ctx, p, rid, reply, opId === 'headMedia', range, typeof ifRange === 'string' ? ifRange : undefined);
      },
    });
  }

  // ── 관리 ──
  api.op('adminListUsers', {
    auth: 'admin',
    handler: () => ({ items: ctx.store.all<Parameters<typeof adminUserDto>[1]>('SELECT * FROM users WHERE deleted_at IS NULL ORDER BY created_at').map((u) => adminUserDto(ctx, u)) }),
  });
  api.op<never, never, Parameters<typeof createUser>[1]>('adminCreateUser', {
    auth: 'admin',
    handler: (req, reply) => reply.code(201).send(adminUserDto(ctx, createUser(ctx, req.body))),
  });
  api.op<{ userId: string }, never, Parameters<typeof updateUser>[2]>('adminUpdateUser', {
    auth: 'admin',
    handler: (req) => adminUserDto(ctx, updateUser(ctx, requireId('user', req.params.userId), req.body)),
  });
  api.op<{ userId: string }>('adminDeleteUser', {
    auth: 'admin',
    handler: (req, reply) => {
      deleteUser(ctx, requireId('user', req.params.userId));
      return reply.code(204).send();
    },
  });
  api.op('adminListLibraries', { auth: 'admin', handler: () => ({ items: listLibrariesAdmin(ctx) }) });
  api.op<{ libraryId: string }>('adminStartScan', {
    auth: 'admin',
    handler: (req, reply) => {
      const id = requireId('library', req.params.libraryId);
      if (!ctx.store.get('SELECT 1 FROM libraries WHERE id = ?', id)) throw notFound();
      return reply.code(202).send(jobDto(ctx.jobs.enqueue('scan', id)));
    },
  });
  api.op<{ jobId: string }>('adminGetJob', {
    auth: 'admin',
    handler: (req) => {
      const job = ctx.jobs.get(requireId('job', req.params.jobId));
      if (!job) throw notFound();
      return jobDto(job);
    },
  });
}
