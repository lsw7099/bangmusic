// 사용자·라이브러리 관리. CLI(관리자 생성, 라이브러리 등록)와 /v1/admin API가 같이 쓴다.
import { readdirSync, realpathSync, statSync } from 'node:fs';
import { hashPassword } from './auth/crypto.ts';
import { iso, normUsername, revokeAllForUser, userSummary, type UserRow } from './auth/sessions.ts';
import type { Ctx } from './ctx.ts';
import { ApiError, badRequest, notFound } from './http/problem.ts';
import { newId } from './ids.ts';
import { checkRoot, MARKER, type LibraryRow } from './scanner/paths.ts';

export function hasAdmin(ctx: Ctx): boolean {
  return Boolean(ctx.store.get("SELECT 1 FROM users WHERE role = 'admin' AND status = 'active' AND deleted_at IS NULL"));
}

function libraryIdsOf(ctx: Ctx, userId: string): string[] {
  return ctx.store.all<{ library_id: string }>('SELECT library_id FROM user_library_access WHERE user_id = ? ORDER BY library_id', userId).map((r) => r.library_id);
}

export function adminUserDto(ctx: Ctx, u: UserRow) {
  const sessions = ctx.store.get<{ n: number }>('SELECT COUNT(*) AS n FROM sessions WHERE user_id = ? AND revoked_at IS NULL AND refresh_expires_at > ?', u.id, Date.now())!.n;
  return {
    ...userSummary(u),
    status: u.status,
    library_ids: u.role === 'admin' ? ctx.store.all<{ id: string }>('SELECT id FROM libraries ORDER BY id').map((r) => r.id) : libraryIdsOf(ctx, u.id),
    created_at: iso(u.created_at),
    session_count: Number(sessions),
  };
}

function checkLibraries(ctx: Ctx, ids: string[]) {
  for (const id of ids) {
    if (!ctx.store.get('SELECT 1 FROM libraries WHERE id = ?', id)) throw badRequest('library_ids', `없는 라이브러리: ${id}`);
  }
}

export function createUser(ctx: Ctx, input: { username: string; password: string; role: 'admin' | 'member'; display_name?: string; library_ids?: string[] }): UserRow {
  const username = normUsername(input.username);
  if (!username || username.length > 64) throw badRequest('username', '사용자 이름이 비었거나 너무 김');
  if (input.password.length < 10) throw badRequest('password', '비밀번호는 10자 이상');
  if (ctx.store.get('SELECT 1 FROM users WHERE username = ?', username)) throw new ApiError(409, 'username_taken');
  checkLibraries(ctx, input.library_ids ?? []);
  const id = newId('user');
  ctx.store.tx(() => {
    ctx.store.run('INSERT INTO users (id, username, display_name, password_hash, role, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      id, username, input.display_name ?? null, hashPassword(input.password), input.role, 'active', Date.now());
    for (const lib of input.library_ids ?? []) ctx.store.run('INSERT INTO user_library_access (user_id, library_id) VALUES (?, ?)', id, lib);
  });
  return getUser(ctx, id)!;
}

export function getUser(ctx: Ctx, id: string): UserRow | undefined {
  return ctx.store.get<UserRow>('SELECT * FROM users WHERE id = ? AND deleted_at IS NULL', id);
}

function activeAdminCount(ctx: Ctx): number {
  return Number(ctx.store.get<{ n: number }>("SELECT COUNT(*) AS n FROM users WHERE role = 'admin' AND status = 'active' AND deleted_at IS NULL")!.n);
}

export function updateUser(ctx: Ctx, id: string, patch: { display_name?: string; role?: 'admin' | 'member'; status?: 'active' | 'disabled'; library_ids?: string[]; new_password?: string; revoke_sessions?: boolean }) {
  const u = getUser(ctx, id);
  if (!u) throw notFound();
  const demotes = (patch.role && patch.role !== 'admin') || patch.status === 'disabled';
  if (u.role === 'admin' && u.status === 'active' && demotes && activeAdminCount(ctx) <= 1) throw new ApiError(409, 'last_admin');
  if (patch.library_ids) checkLibraries(ctx, patch.library_ids);
  ctx.store.tx(() => {
    if (patch.display_name !== undefined) ctx.store.run('UPDATE users SET display_name = ? WHERE id = ?', patch.display_name, id);
    if (patch.role) ctx.store.run('UPDATE users SET role = ? WHERE id = ?', patch.role, id);
    if (patch.status) ctx.store.run('UPDATE users SET status = ? WHERE id = ?', patch.status, id);
    if (patch.new_password) ctx.store.run('UPDATE users SET password_hash = ? WHERE id = ?', hashPassword(patch.new_password), id);
    if (patch.library_ids) {
      ctx.store.run('DELETE FROM user_library_access WHERE user_id = ?', id);
      for (const lib of patch.library_ids) ctx.store.run('INSERT INTO user_library_access (user_id, library_id) VALUES (?, ?)', id, lib);
    }
    // 차단·비밀번호 재설정·요청 시 세션을 폐기한다. 접근 축소는 권한 판정이 즉시 반영하므로 세션은 유지된다.
    if (patch.status === 'disabled' || patch.new_password || patch.revoke_sessions) revokeAllForUser(ctx, id, 'admin');
  });
  return getUser(ctx, id)!;
}

export function deleteUser(ctx: Ctx, id: string) {
  const u = getUser(ctx, id);
  if (!u) throw notFound();
  if (u.role === 'admin' && u.status === 'active' && activeAdminCount(ctx) <= 1) throw new ApiError(409, 'last_admin');
  ctx.store.tx(() => {
    revokeAllForUser(ctx, id, 'deleted');
    ctx.store.run('UPDATE users SET deleted_at = ?, status = ?, username = ? WHERE id = ?', Date.now(), 'disabled', `deleted:${id}`, id);
    ctx.store.run('DELETE FROM user_library_access WHERE user_id = ?', id);
  });
}

/** 라이브러리 등록 (CLI 전용). 경로는 서버 내부 값이며 API로 노출하지 않는다. */
export function addLibrary(ctx: Ctx, name: string, rootPath: string): LibraryRow {
  let real: string;
  try {
    real = realpathSync.native(rootPath);
  } catch {
    throw new Error('라이브러리 경로에 접근할 수 없다');
  }
  if (!statSync(real).isDirectory()) throw new Error('라이브러리 경로가 폴더가 아니다');
  const entries = readdirSync(real);
  if (!entries.includes(MARKER) && !entries.some((n) => !n.startsWith('.'))) {
    throw new Error(`빈 폴더는 등록하지 않는다. 마운트를 확인하거나 ${MARKER} 파일을 만들어라`);
  }
  if (ctx.store.get('SELECT 1 FROM libraries WHERE root_real = ?', real)) throw new Error('이미 등록된 경로다');
  const id = newId('library');
  ctx.store.run("INSERT INTO libraries (id, name, root_path, root_real, status) VALUES (?, ?, ?, ?, 'online')", id, name, rootPath, real);
  return ctx.store.get<LibraryRow>('SELECT * FROM libraries WHERE id = ?', id)!;
}

export function listLibrariesAdmin(ctx: Ctx) {
  const libs = ctx.store.all<LibraryRow>('SELECT * FROM libraries ORDER BY name');
  return libs.map((l) => {
    let status = l.status;
    if (status === 'online') {
      try { checkRoot(l); } catch { status = 'unavailable'; }
    }
    const c = ctx.store.get<{ total: number; missing: number }>(
      "SELECT COUNT(*) AS total, SUM(CASE WHEN state = 'missing' THEN 1 ELSE 0 END) AS missing FROM tracks WHERE library_id = ?", l.id)!;
    return {
      id: l.id,
      name: l.name,
      status,
      track_count: Number(c.total),
      missing_count: Number(c.missing ?? 0),
      last_scan_at: l.last_scan_at === null ? null : iso(l.last_scan_at),
      pending_review: Boolean(l.pending_review),
    };
  });
}
