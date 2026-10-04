// P1 수용 기준: OpenAPI 계약 테스트 (응답이 스키마와 일치). L1.
import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { ADMIN, call, device, expectContract, loginAs, MEMBER, setup, type Env } from './helpers.ts';

let env: Env;
let admin: Awaited<ReturnType<typeof loginAs>>;
let member: Awaited<ReturnType<typeof loginAs>>;

const ACCEPT_ALL = [
  { container: 'flac', codec: 'flac' }, { container: 'mp3', codec: 'mp3' }, { container: 'm4a', codec: 'aac' },
  { container: 'm4a', codec: 'alac' }, { container: 'ogg', codec: 'vorbis' }, { container: 'ogg', codec: 'opus' }, { container: 'wav', codec: 'pcm_s16le' },
];

before(async () => {
  env = await setup();
  admin = await loginAs(env, ADMIN);
  member = await loginAs(env, MEMBER);
});
after(() => env.close());

async function get(url: string, opId: string, token = admin.access_token) {
  const res = await call(env, { url, token });
  expectContract(res, opId);
  return res;
}

/** 커서를 끝까지 따라가며 중복·누락이 없는지 */
async function walkAll(url: string, opId: string, limit = 7) {
  const ids: string[] = [];
  let cursor: string | null = null;
  for (let i = 0; i < 100; i++) {
    const sep = url.includes('?') ? '&' : '?';
    const res = await get(`${url}${sep}limit=${limit}${cursor ? `&cursor=${encodeURIComponent(cursor)}` : ''}`, opId);
    const j = res.json();
    ids.push(...j.items.map((x: { id: string }) => x.id));
    cursor = j.next_cursor;
    if (!cursor) break;
  }
  assert.equal(new Set(ids).size, ids.length, `${url}: 페이지 사이 중복`);
  return ids;
}

describe('계약: 서버·인증', () => {
  it('GET /server', async () => {
    const res = await call(env, { url: '/v1/server' });
    expectContract(res, 'getServerInfo');
    const j = res.json();
    assert.equal(j.product, 'bangmusic-server');
    assert.equal(j.setup_required, false);
    assert.match(j.server_id, /^srv_/);
  });

  it('로그인·갱신·세션 목록·로그아웃', async () => {
    const res = await call(env, { method: 'POST', url: '/v1/auth/login', body: { ...ADMIN, device: device('계약 폰') } });
    expectContract(res, 'login');
    const t = res.json();
    env.secrets.add(t.access_token).add(t.refresh_token);
    const r2 = await call(env, { method: 'POST', url: '/v1/auth/refresh', body: { refresh_token: t.refresh_token } });
    expectContract(r2, 'refreshToken');
    const t2 = r2.json();
    env.secrets.add(t2.access_token).add(t2.refresh_token);
    const s = await get('/v1/sessions', 'listSessions', t2.access_token);
    assert.ok(s.json().items.some((x: { current: boolean }) => x.current));
    const out = await call(env, { method: 'POST', url: '/v1/auth/logout', token: t2.access_token });
    expectContract(out, 'logout');
    assert.equal(out.statusCode, 204);
    const after = await call(env, { url: '/v1/me', token: t2.access_token });
    expectContract(after, 'getMe');
    assert.equal(after.json().code, 'session_revoked');
  });

  it('잘못된 요청은 400 validation_failed', async () => {
    const res = await call(env, { method: 'POST', url: '/v1/auth/login', body: { username: 'x' } });
    expectContract(res, 'login');
    assert.equal(res.json().code, 'validation_failed');
    assert.ok(res.json().errors.length > 0);
  });

  it('GET /me, 비밀번호 변경', async () => {
    const me = await get('/v1/me', 'getMe', member.access_token);
    assert.equal(me.json().libraries.length, 1);
    const extra = await loginAs(env, MEMBER, device('다른 폰'));
    const bad = await call(env, { method: 'PUT', url: '/v1/me/password', token: member.access_token, body: { current_password: 'wrong-password', new_password: 'new-member-password-1' } });
    expectContract(bad, 'changePassword');
    assert.equal(bad.statusCode, 400);
    const ok = await call(env, { method: 'PUT', url: '/v1/me/password', token: member.access_token, body: { current_password: MEMBER.password, new_password: 'new-member-password-1' } });
    expectContract(ok, 'changePassword');
    env.secrets.add('new-member-password-1');
    // 현재 세션은 유지, 다른 세션은 폐기
    assert.equal((await call(env, { url: '/v1/me', token: member.access_token })).statusCode, 200);
    assert.equal((await call(env, { url: '/v1/me', token: extra.access_token })).json().code, 'session_revoked');
  });
});

describe('계약: 카탈로그', () => {
  it('곡 목록 — 정렬 3종을 끝까지 넘겨도 중복·누락 없음', async () => {
    const total = Number(env.ctx.store.get<{ n: number }>('SELECT COUNT(*) AS n FROM tracks')!.n);
    for (const sort of ['title', 'added_at_desc', 'album']) {
      const ids = await walkAll(`/v1/tracks?sort=${sort}`, 'listTracks');
      assert.equal(ids.length, total, `sort=${sort}`);
    }
  });

  it('다른 정렬의 커서는 400', async () => {
    const first = (await get('/v1/tracks?sort=title&limit=2', 'listTracks')).json();
    const res = await call(env, { url: `/v1/tracks?sort=album&cursor=${encodeURIComponent(first.next_cursor)}`, token: admin.access_token });
    expectContract(res, 'listTracks');
    assert.equal(res.statusCode, 400);
  });

  it('곡·앨범·아티스트 상세', async () => {
    const albums = await walkAll('/v1/albums?sort=title', 'listAlbums', 3);
    await walkAll('/v1/albums?sort=year_desc', 'listAlbums', 3);
    await walkAll('/v1/albums?sort=added_at_desc', 'listAlbums', 3);
    for (const id of albums) {
      const a = (await get(`/v1/albums/${id}`, 'getAlbum')).json();
      assert.equal(a.tracks.length, a.track_count);
      for (const t of a.tracks) await get(`/v1/tracks/${t.id}`, 'getTrack');
    }
    const artists = await walkAll('/v1/artists', 'listArtists', 2);
    for (const id of artists) await get(`/v1/artists/${id}`, 'getArtist');
    const ja = (await get(`/v1/albums/${albums[0]}`, 'getAlbum')).json();
    assert.ok(ja.title);
  });

  it('일본어 정렬 태그·트랙 순서', async () => {
    const res = (await get('/v1/search?q=%E5%A4%9C%E6%98%8E%E3%81%91&types=track', 'search')).json(); // 夜明け
    const t = res.tracks.items[0];
    assert.equal(t.title, '夜明けのうた');
    assert.equal(t.title_sort, 'よあけのうた');
    assert.equal(t.track_no, 3);
    assert.equal(t.source_format.container, 'flac');
  });

  it('검색 정규화: 가타카나·반각·히라가나가 같은 결과', async () => {
    const queries = ['テスト楽団', 'てすと楽団', 'ﾃｽﾄ楽団'];
    const results = [];
    for (const q of queries) {
      const j = (await get(`/v1/search?q=${encodeURIComponent(q)}&types=artist`, 'search')).json();
      assert.equal(j.query_normalized, 'てすと楽団');
      results.push(j.artists.items.map((a: { id: string }) => a.id).join());
    }
    assert.equal(new Set(results).size, 1);
    assert.ok(results[0]);
  });

  it('검색: 1~2자 접두, 여러 유형, 단일 유형 커서', async () => {
    const short = (await get(`/v1/search?q=${encodeURIComponent('형식')}`, 'search')).json();
    assert.ok(short.tracks.items.length > 0);
    assert.equal(short.tracks.next_cursor, null);
    assert.deepEqual(short.playlists, { items: [], next_cursor: null });
    const ids: string[] = [];
    let cursor = '';
    for (;;) {
      const j = (await get(`/v1/search?q=${encodeURIComponent('형식')}&types=track&limit=2${cursor}`, 'search')).json();
      ids.push(...j.tracks.items.map((x: { id: string }) => x.id));
      if (!j.tracks.next_cursor) break;
      cursor = `&cursor=${encodeURIComponent(j.tracks.next_cursor)}`;
    }
    assert.equal(ids.length, 9);
    assert.equal(new Set(ids).size, 9);
  });

  it('변경 피드: 0부터 끝까지, 이후 빈 묶음', async () => {
    let since = '0';
    const seen = new Set<string>();
    for (let i = 0; i < 100; i++) {
      const j = (await get(`/v1/changes?since=${since}&limit=10`, 'getChanges')).json();
      for (const c of j.changes) seen.add(`${c.entity}:${c.id}`);
      since = j.next_since;
      if (!j.has_more) break;
    }
    const tracks = Number(env.ctx.store.get<{ n: number }>('SELECT COUNT(*) AS n FROM tracks')!.n);
    assert.equal([...seen].filter((k) => k.startsWith('track:')).length, tracks);
    const empty = (await get(`/v1/changes?since=${since}`, 'getChanges')).json();
    assert.equal(empty.changes.length, 0);
    assert.equal(empty.has_more, false);
    const bad = await call(env, { url: '/v1/changes?since=abc', token: admin.access_token });
    assert.equal(bad.statusCode, 400);
  });

  it('표지: 크기별 JPEG, ETag, 304', async () => {
    const t = (await get(`/v1/search?q=${encodeURIComponent('새벽 공기')}&types=track`, 'search')).json().tracks.items[0];
    assert.ok(t.artwork_id, '내장 표지');
    for (const size of [96, 256, 512, 1024]) {
      const res = await call(env, { url: `/v1/artwork/${t.artwork_id}?size=${size}`, token: admin.access_token });
      expectContract(res, 'getArtwork');
      assert.equal(res.headers['content-type'], 'image/jpeg');
      assert.equal(res.rawPayload.subarray(0, 2).toString('hex'), 'ffd8');
    }
    const first = await call(env, { url: `/v1/artwork/${t.artwork_id}?size=256`, token: admin.access_token });
    const again = await call(env, { url: `/v1/artwork/${t.artwork_id}?size=256`, token: admin.access_token, headers: { 'if-none-match': String(first.headers.etag) } });
    expectContract(again, 'getArtwork');
    assert.equal(again.statusCode, 304);
    // 폴더 cover.jpg (6000px 원본) → 마스터는 1024px 이하
    const big = env.ctx.store.get<{ width: number; height: number }>(
      "SELECT a.width, a.height FROM artworks a JOIN albums al ON al.artwork_id = a.id WHERE al.title = '큰 표지 앨범'");
    assert.ok(big && big.width <= 1024 && big.height <= 1024);
  });
});

describe('표지 동시 요청 (실기기에서 발견한 경합)', () => {
  it('같은 표지·크기를 동시에 10번 요청해도 모두 200, 같은 바이트', async () => {
    const { rmSync } = await import('node:fs');
    const { join } = await import('node:path');
    rmSync(join(env.ctx.config.cacheDir, 'artwork'), { recursive: true, force: true });
    const t = (await get(`/v1/search?q=${encodeURIComponent('형식 mp3-cbr')}&types=track`, 'search')).json().tracks.items[0];
    const all = await Promise.all(Array.from({ length: 10 }, () => call(env, { url: `/v1/artwork/${t.artwork_id}?size=256`, token: admin.access_token })));
    for (const r of all) {
      expectContract(r, 'getArtwork');
      assert.equal(r.statusCode, 200);
    }
    assert.equal(new Set(all.map((r) => r.rawPayload.toString('base64'))).size, 1);
  });
});

describe('계약: 렌디션·미디어', () => {
  it('원본 렌디션 결정 → 상태 조회 → HEAD/GET', async () => {
    const track = (await get(`/v1/search?q=${encodeURIComponent('夜明けのうた')}&types=track`, 'search')).json().tracks.items[0];
    const res = await call(env, { method: 'POST', url: `/v1/tracks/${track.id}/renditions`, token: admin.access_token, body: { purpose: 'stream', quality: 'original', accept: ACCEPT_ALL } });
    expectContract(res, 'resolveRendition');
    const r = res.json();
    assert.equal(r.state, 'ready');
    assert.equal(r.profile, 'original');
    assert.equal(r.mime, 'audio/flac');
    env.secrets.add(new URL(r.media_url, 'http://x').searchParams.get('mt')!);
    const again = (await call(env, { method: 'POST', url: `/v1/tracks/${track.id}/renditions`, token: admin.access_token, body: { purpose: 'download', quality: 'original', accept: ACCEPT_ALL } })).json();
    assert.equal(again.id, r.id, '같은 요청은 같은 렌디션(멱등)');
    expectContract(await call(env, { url: `/v1/renditions/${r.id}`, token: admin.access_token }), 'getRendition');
    const head = await call(env, { method: 'HEAD', url: r.media_url });
    expectContract(head, 'headMedia');
    assert.equal(Number(head.headers['content-length']), r.size_bytes);
    const body = await call(env, { url: r.media_url });
    expectContract(body, 'getMedia');
    const part = await call(env, { url: r.media_url, headers: { range: 'bytes=100-199' } });
    expectContract(part, 'getMedia');
    assert.equal(part.statusCode, 206);
  });

  it('재생할 수 없는 형식은 422, 알 수 없는 품질은 400', async () => {
    const track = (await get(`/v1/search?q=${encodeURIComponent('형식 m4a-alac')}&types=track`, 'search')).json().tracks.items[0];
    const res = await call(env, { method: 'POST', url: `/v1/tracks/${track.id}/renditions`, token: admin.access_token, body: { purpose: 'stream', quality: 'original', accept: [{ container: 'mp3', codec: 'mp3' }] } });
    expectContract(res, 'resolveRendition');
    assert.equal(res.json().code, 'no_playable_format');
    const q = await call(env, { method: 'POST', url: `/v1/tracks/${track.id}/renditions`, token: admin.access_token, body: { purpose: 'stream', quality: 'aac_999', accept: ACCEPT_ALL } });
    expectContract(q, 'resolveRendition');
    assert.equal(q.statusCode, 400);
  });
});

describe('계약: 관리', () => {
  it('사용자·라이브러리·스캔·작업', async () => {
    expectContract(await call(env, { url: '/v1/admin/users', token: admin.access_token }), 'adminListUsers');
    const created = await call(env, { method: 'POST', url: '/v1/admin/users', token: admin.access_token, body: { username: 'newbie', password: 'newbie-password-1', role: 'member', library_ids: [env.lib2] } });
    expectContract(created, 'adminCreateUser');
    env.secrets.add('newbie-password-1');
    const dup = await call(env, { method: 'POST', url: '/v1/admin/users', token: admin.access_token, body: { username: 'NEWBIE', password: 'newbie-password-1', role: 'member' } });
    expectContract(dup, 'adminCreateUser');
    assert.equal(dup.json().code, 'username_taken');
    const id = created.json().id;
    const upd = await call(env, { method: 'PATCH', url: `/v1/admin/users/${id}`, token: admin.access_token, body: { display_name: '새 사용자', library_ids: [env.lib1, env.lib2] } });
    expectContract(upd, 'adminUpdateUser');
    assert.equal(upd.json().library_ids.length, 2);
    const adminId = admin.user.id;
    const lastAdmin = await call(env, { method: 'PATCH', url: `/v1/admin/users/${adminId}`, token: admin.access_token, body: { role: 'member' } });
    expectContract(lastAdmin, 'adminUpdateUser');
    assert.equal(lastAdmin.json().code, 'last_admin');
    const del = await call(env, { method: 'DELETE', url: `/v1/admin/users/${id}`, token: admin.access_token });
    expectContract(del, 'adminDeleteUser');
    expectContract(await call(env, { method: 'DELETE', url: `/v1/admin/users/${adminId}`, token: admin.access_token }), 'adminDeleteUser');
    const libs = await call(env, { url: '/v1/admin/libraries', token: admin.access_token });
    expectContract(libs, 'adminListLibraries');
    assert.equal(libs.json().items.length, 2);
    const scan = await call(env, { method: 'POST', url: `/v1/admin/libraries/${env.lib2}/scan`, token: admin.access_token });
    expectContract(scan, 'adminStartScan');
    await env.ctx.jobs.idle();
    const job = await call(env, { url: `/v1/admin/jobs/${scan.json().id}`, token: admin.access_token });
    expectContract(job, 'adminGetJob');
    assert.equal(job.json().state, 'succeeded');
  });
});
