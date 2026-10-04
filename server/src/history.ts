// 재생 기록 (03장 §6.9). event_id(앱이 만든 UUID)가 이미 있으면 중복으로 세고 무시한다 → 재전송 안전 (FN-22).
// 집계 규칙은 기존 Windows BangMusic(test/home-collections.test.cjs)을 따른다: 곡이 정상으로 불러와져
// 재생이 시작되면 1회. 일시정지·재개는 늘리지 않고, 재생 실패는 세지 않는다(앱이 실패한 곡의 이벤트를 보내지 않는다).
// 설계 초안의 "30초 또는 50%" 기준은 기존 앱 규칙으로 대체했다.
import type { Principal } from './auth/sessions.ts';
import { getTrackRow, trackDtos, type TrackRow } from './catalog/catalog.ts';
import type { Ctx } from './ctx.ts';
import { badRequest } from './http/problem.ts';

export interface PlayEventIn {
  event_id: string;
  track_id: string;
  started_at: string;
  played_ms: number;
  completed: boolean;
  source: 'stream' | 'offline';
  context?: { type?: string; id?: string | null };
}


export function postEvents(ctx: Ctx, p: Principal, events: PlayEventIn[]) {
  let accepted = 0;
  let duplicates = 0;
  const rejected: { event_id: string; code: string }[] = [];
  const now = Date.now();
  ctx.store.tx(() => {
    for (const e of events) {
      const startedAt = Date.parse(e.started_at);
      if (!Number.isFinite(startedAt)) throw badRequest('events/started_at', '날짜 형식 오류');
      const dup = ctx.store.get<{ user_id: string }>('SELECT user_id FROM play_events WHERE event_id = ?', e.event_id);
      if (dup) {
        // 다른 사용자가 같은 ID를 썼다면 존재를 알리지 않고 거절한다
        if (dup.user_id === p.user.id) duplicates++;
        else rejected.push({ event_id: e.event_id, code: 'not_found' });
        continue;
      }
      let track: TrackRow;
      try {
        track = getTrackRow(ctx, p, e.track_id);
      } catch {
        rejected.push({ event_id: e.event_id, code: 'not_found' }); // 없거나 권한 없는 곡 → 앱은 재전송하지 않는다
        continue;
      }
      const counted = true; // 받은 이벤트는 모두 1회 (재생이 시작된 곡만 앱이 보낸다)
      ctx.store.run(`INSERT INTO play_events (event_id, user_id, session_id, track_id, started_at, played_ms, completed, counted, source, context_type, context_id, received_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        e.event_id, p.user.id, p.session.id, e.track_id, startedAt, e.played_ms, e.completed ? 1 : 0, counted ? 1 : 0, e.source,
        e.context?.type ?? null, e.context?.id ?? null, now);
      if (counted) {
        ctx.store.run(`INSERT INTO track_stats (user_id, track_id, play_count, last_played_at) VALUES (?, ?, 1, ?)
            ON CONFLICT(user_id, track_id) DO UPDATE SET play_count = play_count + 1, last_played_at = MAX(last_played_at, excluded.last_played_at)`,
          p.user.id, e.track_id, startedAt);
      }
      accepted++;
    }
  });
  return { accepted, duplicates, rejected };
}

const TRACK_JOIN = `SELECT t.*, al.title AS album_title, m.container, m.codec, m.sample_rate, m.channels, m.bit_depth, m.bitrate
  FROM tracks t LEFT JOIN albums al ON al.id = t.album_id LEFT JOIN media_files m ON m.track_id = t.id`;
const ACCESS = `(? = 1 OR t.library_id IN (SELECT library_id FROM user_library_access WHERE user_id = ?))`;

/** 최근 들은 곡 (곡당 1회, 최근순). 커서 = (last_played_at, track_id) */
export function recent(ctx: Ctx, p: Principal, q: { cursor?: string; limit: number }) {
  let after: [number, string] | null = null;
  if (q.cursor) {
    try {
      const c = JSON.parse(Buffer.from(q.cursor, 'base64url').toString('utf8'));
      if (c.s !== 'recent' || !Array.isArray(c.k) || c.k.length !== 2) throw new Error();
      after = [Number(c.k[0]), String(c.k[1])];
    } catch {
      throw badRequest('cursor', '해석할 수 없는 커서');
    }
  }
  const isAdmin = p.user.role === 'admin' ? 1 : 0;
  const rows = ctx.store.all<TrackRow & { last_played_at: number }>(
    `SELECT x.*, s.last_played_at FROM track_stats s JOIN (${TRACK_JOIN}) x ON x.id = s.track_id
      JOIN tracks t ON t.id = s.track_id
      WHERE s.user_id = ? AND ${ACCESS} ${after ? 'AND (-s.last_played_at, s.track_id) > (?, ?)' : ''}
      ORDER BY -s.last_played_at, s.track_id LIMIT ?`,
    p.user.id, isAdmin, p.user.id, ...(after ? [-after[0], after[1]] : []), q.limit + 1);
  let next: string | null = null;
  if (rows.length > q.limit) {
    rows.length = q.limit;
    const last = rows[rows.length - 1]!;
    next = Buffer.from(JSON.stringify({ s: 'recent', k: [last.last_played_at, last.id] })).toString('base64url');
  }
  return { items: trackDtos(ctx, rows), next_cursor: next };
}

const WINDOWS: Record<string, number | null> = { '30d': 30, '90d': 90, '365d': 365, all: null };

/** 기간별 많이 들은 곡 (기간 안의 집계된 재생 수, 동점이면 최근 재생 순) */
export function top(ctx: Ctx, p: Principal, q: { window: string; limit: number }) {
  const days = WINDOWS[q.window];
  const since = days === null || days === undefined ? 0 : Date.now() - days * 86_400_000;
  const isAdmin = p.user.role === 'admin' ? 1 : 0;
  const rows = ctx.store.all<TrackRow>(
    `SELECT x.* FROM (SELECT track_id, COUNT(*) AS n, MAX(started_at) AS last FROM play_events
         WHERE user_id = ? AND counted = 1 AND started_at >= ? GROUP BY track_id) e
       JOIN (${TRACK_JOIN}) x ON x.id = e.track_id JOIN tracks t ON t.id = e.track_id
      WHERE ${ACCESS} ORDER BY e.n DESC, e.last DESC, e.track_id LIMIT ?`,
    p.user.id, since, isAdmin, p.user.id, q.limit);
  return { items: trackDtos(ctx, rows), next_cursor: null };
}

export function deleteHistory(ctx: Ctx, userId: string) {
  ctx.store.tx(() => {
    ctx.store.run('DELETE FROM play_events WHERE user_id = ?', userId);
    ctx.store.run('DELETE FROM track_stats WHERE user_id = ?', userId);
  });
}
