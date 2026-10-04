// 본인 데이터: 홈, 계정 삭제, 내보내기 (05장 §8.3, 02장 §8).
import { verifyPassword } from './auth/crypto.ts';
import { iso, type Principal } from './auth/sessions.ts';
import { deleteUser } from './admin.ts';
import { listAlbums } from './catalog/catalog.ts';
import type { Ctx } from './ctx.ts';
import { recent, top } from './history.ts';
import { ApiError } from './http/problem.ts';
import { listItems, listPlaylists } from './playlists.ts';

export function home(ctx: Ctx, p: Principal, limit: number) {
  return {
    playlists: listPlaylists(ctx, p, { limit }).items,
    recent_tracks: recent(ctx, p, { limit }).items,
    top_tracks: top(ctx, p, { window: '90d', limit }).items,
    recently_added_albums: listAlbums(ctx, p, { limit, sort: 'added_at_desc' }).items,
  };
}

/** 계정과 개인 데이터 삭제. 음악 원본은 건드리지 않는다. 마지막 관리자는 409 last_admin. */
export function deleteMe(ctx: Ctx, p: Principal, password: string) {
  if (!verifyPassword(password, p.user.password_hash)) throw new ApiError(401, 'invalid_credentials'); // 계약: 204/401/409
  ctx.store.tx(() => {
    deleteUser(ctx, p.user.id); // last_admin 검사, 세션 폐기 포함
    ctx.store.run('DELETE FROM playlist_items WHERE playlist_id IN (SELECT id FROM playlists WHERE owner_id = ?)', p.user.id);
    ctx.store.run('DELETE FROM playlists WHERE owner_id = ?', p.user.id);
    ctx.store.run('DELETE FROM play_events WHERE user_id = ?', p.user.id);
    ctx.store.run('DELETE FROM track_stats WHERE user_id = ?', p.user.id);
    ctx.store.run('DELETE FROM lyrics_prefs WHERE user_id = ?', p.user.id);
    ctx.store.run('DELETE FROM idempotency_keys WHERE user_id = ?', p.user.id);
    ctx.store.run('DELETE FROM sessions WHERE user_id = ?', p.user.id);
  });
}

/** 플레이리스트(항목 포함)와 재생 기록 JSON */
export function exportMe(ctx: Ctx, p: Principal) {
  const playlists = [];
  let cursor: string | undefined;
  do {
    const page = listPlaylists(ctx, p, { limit: 200, cursor });
    for (const pl of page.items) {
      const items = [];
      let ic: string | undefined;
      do {
        const r = listItems(ctx, p, pl.id, { limit: 200, cursor: ic });
        items.push(...r.page.items.map((i) => ({ item_id: i.item_id, track_id: i.track?.id ?? null, title: i.track?.title ?? null, added_at: i.added_at })));
        ic = r.page.next_cursor ?? undefined;
      } while (ic);
      playlists.push({ ...pl, items });
    }
    cursor = page.next_cursor ?? undefined;
  } while (cursor);
  const history = ctx.store.all<{ event_id: string; track_id: string; started_at: number; played_ms: number; completed: number; source: string }>(
    'SELECT event_id, track_id, started_at, played_ms, completed, source FROM play_events WHERE user_id = ? ORDER BY started_at', p.user.id)
    .map((e) => ({ ...e, started_at: iso(e.started_at), completed: Boolean(e.completed) }));
  return {
    format: 'bangmusic-export',
    version: 1,
    exported_at: iso(Date.now()),
    user: { id: p.user.id, username: p.user.username, display_name: p.user.display_name },
    playlists,
    play_events: history,
  };
}
