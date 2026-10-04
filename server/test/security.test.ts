// P1 수용 기준: SEC-01~12 (05장 §9.5), 응답·로그에 경로·토큰 없음. L1.
// SEC-05의 플레이리스트·재생 기록 부분은 해당 API가 생기는 P2에서 검증한다(여기서는 세션으로 확인).
import assert from 'node:assert/strict';
import { mkdirSync, readFileSync, renameSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { after, before, describe, it } from 'node:test';
import { scanLibrary } from '../src/scanner/scan.ts';
import { addLibrary } from '../src/admin.ts';
import { ADMIN, call, device, expectContract, linkDir, loginAs, MEMBER, OTHER, setup, type Env } from './helpers.ts';

let env: Env;
let admin: Awaited<ReturnType<typeof loginAs>>;
let member: Awaited<ReturnType<typeof loginAs>>;
let other: Awaited<ReturnType<typeof loginAs>>;
const ACCEPT = [{ container: 'flac', codec: 'flac' }, { container: 'mp3', codec: 'mp3' }, { container: 'm4a', codec: 'aac' }];

before(async () => {
  env = await setup();
  admin = await loginAs(env, ADMIN);
  member = await loginAs(env, MEMBER);
  other = await loginAs(env, OTHER);
});
after(() => env.close());

async function trackIn(libId: string, token = admin.access_token) {
  const r = await call(env, { url: `/v1/tracks?library_id=${libId}&limit=200`, token });
  return r.json().items as Array<{ id: string; title: string; artwork_id: string | null; album: { id: string } | null; artists: { id: string }[] }>;
}

async function rendition(trackId: string, token = admin.access_token) {
  const r = await call(env, { method: 'POST', url: `/v1/tracks/${trackId}/renditions`, token, body: { purpose: 'stream', quality: 'original', accept: ACCEPT } });
  assert.equal(r.statusCode, 200, r.body);
  const j = r.json();
  env.secrets.add(new URL(j.media_url, 'http://x').searchParams.get('mt')!);
  return j as { id: string; media_url: string };
}

describe('SEC-01 ID 자리에 경로 조작', () => {
  const payloads = ['../../etc/passwd', '..%2F..%2Fetc%2Fpasswd', '%2Fetc%2Fpasswd', 'C:%5CWindows%5Cwin.ini', 'trk_%00', 'trk_01JB2P3C5E7G9J1L3N5Q7S9U1W%00..', '%2e%2e%2f%2e%2e%2f', 'trk_../../x'];
  for (const p of payloads) {
    it(`/tracks/${p}`, async () => {
      for (const base of ['/v1/tracks/', '/v1/albums/', '/v1/artwork/', '/v1/renditions/', '/v1/media/']) {
        const res = await call(env, { url: `${base}${p}`, token: admin.access_token });
        assert.ok([400, 404].includes(res.statusCode), `${base}${p} → ${res.statusCode}`);
        assert.doesNotMatch(res.body, /passwd|win\.ini|[A-Z]:\\|\/etc\//i);
      }
    });
  }
});

describe('SEC-02~04 심볼릭 링크', () => {
  it('SEC-02 루트 밖을 가리키는 링크는 스캔에서 제외되고 경고 기록', async () => {
    // Windows는 파일 심볼릭 링크에 권한이 필요하므로 폴더 링크(junction)로 같은 탈출을 만든다.
    // Linux에서 만든 합성 음원 세트에는 이미 루트 밖 링크(escape-link.mp3)가 있으므로 기준값을 먼저 잰다
    const baseline = (await scanLibrary(env.ctx, env.lib1)).skippedLinks;
    const outside = join(env.dir, 'outside-sec02');
    mkdirSync(outside, { recursive: true });
    writeFileSync(join(outside, 'secret.mp3'), readFileSync(join(env.music, 'lib1', '태그 없음', 'untagged-track.mp3')));
    linkDir(outside, join(env.music, 'lib1', 'escape-dir'));
    const before = Number(env.ctx.store.get<{ n: number }>('SELECT COUNT(*) AS n FROM tracks')!.n);
    const s = await scanLibrary(env.ctx, env.lib1);
    assert.equal(s.skippedLinks, baseline + 1);
    assert.equal(Number(env.ctx.store.get<{ n: number }>('SELECT COUNT(*) AS n FROM tracks')!.n), before);
    assert.equal(env.ctx.store.get("SELECT 1 FROM media_files WHERE rel_path LIKE 'escape-dir/%'"), undefined);
    assert.match(readFileSync(env.logFile, 'utf8'), /라이브러리 루트 밖을 가리키는 링크|폴더 링크는 따라가지 않음/);
    rmSync(join(env.music, 'lib1', 'escape-dir'));
  });

  it('SEC-03 스캔 후 파일 위치를 루트 밖을 가리키는 링크로 바꿔치기 → 미디어 거부, 경로 없음', async () => {
    const dirName = '경로 시험';
    const track = (await trackIn(env.lib1)).find((t) => t.title === '특수문자 경로')!;
    const r = await rendition(track.id);
    const real = join(env.music, 'lib1', dirName);
    const outside = join(env.dir, 'outside-sec03');
    renameSync(real, outside); // 같은 파일 이름이 루트 밖에 있다
    linkDir(outside, real);
    try {
      const res = await call(env, { url: r.media_url });
      expectContract(res, 'getMedia');
      assert.equal(res.statusCode, 404);
      assert.equal(res.json().code, 'media_missing');
      assert.doesNotMatch(res.body, /outside|music|[A-Z]:\\/i);
    } finally {
      rmSync(real);
      renameSync(outside, real);
    }
  });

  it('SEC-04 라이브러리 루트가 링크 → 등록 시 실제 경로 고정, 대상이 바뀌면 unavailable', async () => {
    const a = join(env.dir, 'root-a');
    const b = join(env.dir, 'root-b');
    mkdirSync(a);
    mkdirSync(b);
    writeFileSync(join(a, 'x.mp3'), readFileSync(join(env.music, 'lib1', '태그 없음', 'untagged-track.mp3')));
    writeFileSync(join(b, 'y.mp3'), readFileSync(join(env.music, 'lib1', '태그 없음', 'untagged-track.mp3')));
    const link = join(env.dir, 'root-link');
    linkDir(a, link);
    const lib = addLibrary(env.ctx, 'Linked', link);
    assert.equal((await scanLibrary(env.ctx, lib.id)).added, 1);
    const tracks = await trackIn(lib.id);
    const r = await rendition(tracks[0]!.id);
    rmSync(link);
    linkDir(b, link); // 링크 대상 바꿔치기
    const media = await call(env, { url: r.media_url });
    expectContract(media, 'getMedia');
    assert.equal(media.statusCode, 503);
    assert.equal(media.json().code, 'storage_unavailable');
    await assert.rejects(scanLibrary(env.ctx, lib.id), /storage_unavailable|실제 경로/);
    const row = env.ctx.store.get<{ status: string }>('SELECT status FROM libraries WHERE id = ?', lib.id)!;
    assert.equal(row.status, 'unavailable');
    assert.equal(env.ctx.store.get<{ n: number }>("SELECT COUNT(*) AS n FROM tracks WHERE library_id = ? AND state = 'missing'", lib.id)!.n, 0, '곡을 missing으로 바꾸지 않음');
  });
});

describe('SEC-05 다른 사용자의 개인 자원', () => {
  it('다른 사용자의 세션 취소 → 404', async () => {
    const res = await call(env, { method: 'DELETE', url: `/v1/sessions/${other.session_id}`, token: member.access_token });
    expectContract(res, 'revokeSession');
    assert.equal(res.statusCode, 404);
    assert.equal((await call(env, { url: '/v1/me', token: other.access_token })).statusCode, 200, '취소되지 않음');
  });
});

describe('SEC-06 접근 권한 없는 라이브러리', () => {
  it('곡·앨범·아티스트·표지·렌디션·미디어 404, 검색·피드에서 제외', async () => {
    const lib2Tracks = await trackIn(env.lib2);
    assert.ok(lib2Tracks.length > 0);
    const t = lib2Tracks[0]!;
    const r = await rendition(t.id);
    const tok = member.access_token;
    for (const [url, op] of [[`/v1/tracks/${t.id}`, 'getTrack'], [`/v1/albums/${t.album!.id}`, 'getAlbum'], [`/v1/artists/${t.artists[0]!.id}`, 'getArtist'],
      [`/v1/artwork/${t.artwork_id}?size=96`, 'getArtwork'], [`/v1/renditions/${r.id}`, 'getRendition'], [`/v1/media/${r.id}`, 'getMedia']] as const) {
      const res = await call(env, { url, token: tok });
      expectContract(res, op);
      assert.equal(res.statusCode, 404, url);
      assert.equal(res.json().code, 'not_found');
    }
    const post = await call(env, { method: 'POST', url: `/v1/tracks/${t.id}/renditions`, token: tok, body: { purpose: 'stream', quality: 'original', accept: ACCEPT } });
    assert.equal(post.statusCode, 404);
    // 관리자가 발급받은 티켓 URL을 member가 써도 안 된다(티켓은 발급 사용자에 묶임) — 대신 member 자신의 Bearer로도 404
    const search = (await call(env, { url: `/v1/search?q=${encodeURIComponent('라이브러리2')}`, token: tok })).json();
    assert.equal(search.tracks.items.length, 0);
    assert.equal(search.albums.items.length, 0);
    assert.equal(search.artists.items.length, 0);
    const feed = (await call(env, { url: '/v1/changes?since=0&limit=200', token: tok })).json();
    assert.ok(!feed.changes.some((c: { id: string }) => lib2Tracks.some((x) => x.id === c.id)));
    const list = await trackIn(env.lib2, tok);
    assert.equal(list.length, 0);
  });

  it('접근 권한 회수는 이미 받은 티켓에도 즉시 반영', async () => {
    const t = (await trackIn(env.lib1, other.access_token))[0]!;
    const r = await rendition(t.id, other.access_token);
    assert.equal((await call(env, { method: 'HEAD', url: r.media_url })).statusCode, 200);
    const patch = await call(env, { method: 'PATCH', url: `/v1/admin/users/${other.user.id}`, token: admin.access_token, body: { library_ids: [] } });
    assert.equal(patch.statusCode, 200);
    const res = await call(env, { method: 'HEAD', url: r.media_url });
    assert.equal(res.statusCode, 404);
    await call(env, { method: 'PATCH', url: `/v1/admin/users/${other.user.id}`, token: admin.access_token, body: { library_ids: [env.lib1] } });
  });
});

describe('SEC-07 티켓', () => {
  it('다른 렌디션용·만료·변조·취소된 세션의 티켓 → 401', async () => {
    const [t1, t2] = await trackIn(env.lib1);
    const s = await loginAs(env, ADMIN, device('티켓 폰'));
    const r1 = await rendition(t1!.id, s.access_token);
    const r2 = await rendition(t2!.id, s.access_token);
    const mt1 = new URL(r1.media_url, 'http://x').searchParams.get('mt')!;
    const check = async (url: string, code: string) => {
      const res = await call(env, { url });
      expectContract(res, 'getMedia');
      assert.equal(res.statusCode, 401, url);
      assert.equal(res.json().code, code);
    };
    await check(`/v1/media/${r2.id}?mt=${mt1}`, 'ticket_invalid'); // 다른 렌디션
    const [body, sig] = mt1.split('.');
    const payload = JSON.parse(Buffer.from(body!, 'base64url').toString());
    const forged = Buffer.from(JSON.stringify({ ...payload, res: r2.id })).toString('base64url');
    await check(`/v1/media/${r2.id}?mt=${forged}.${sig}`, 'ticket_invalid'); // 변조
    await check(`/v1/media/${r1.id}?mt=${body}.${'A'.repeat(43)}`, 'ticket_invalid');
    await check(`/v1/media/${r1.id}?mt=garbage`, 'ticket_invalid');
    // 만료: 서명은 맞고 시간만 지난 티켓
    const { issueTicket } = await import('../src/auth/tickets.ts');
    const { principalForSession } = await import('../src/auth/sessions.ts');
    const old = issueTicket(env.ctx, principalForSession(env.ctx, s.session_id), r1.id, Date.now() - env.ctx.config.ticketTtlMs - 1000);
    await check(`/v1/media/${r1.id}?mt=${old.ticket}`, 'ticket_expired');
    // 세션 취소 후
    await call(env, { method: 'POST', url: '/v1/auth/logout', token: s.access_token });
    await check(r1.media_url, 'session_revoked');
  });
});

describe('SEC-08 일반 사용자가 /admin/*', () => {
  it('403 forbidden', async () => {
    const reqs = [
      { url: '/v1/admin/users', op: 'adminListUsers' },
      { method: 'POST' as const, url: '/v1/admin/users', op: 'adminCreateUser', body: { username: 'x1', password: 'xxxxxxxxxxxx', role: 'admin' } },
      { method: 'PATCH' as const, url: `/v1/admin/users/${member.user.id}`, op: 'adminUpdateUser', body: { role: 'admin' } },
      { method: 'DELETE' as const, url: `/v1/admin/users/${admin.user.id}`, op: 'adminDeleteUser' },
      { url: '/v1/admin/libraries', op: 'adminListLibraries' },
      { method: 'POST' as const, url: `/v1/admin/libraries/${env.lib1}/scan`, op: 'adminStartScan' },
      { url: '/v1/admin/jobs/job_01JB2P3C5E7G9J1L3N5Q7S9U1W', op: 'adminGetJob' },
    ];
    for (const r of reqs) {
      const res = await call(env, { method: r.method, url: r.url, token: member.access_token, body: r.body });
      expectContract(res, r.op);
      assert.equal(res.statusCode, 403, r.url);
      assert.equal(res.json().code, 'forbidden');
    }
  });
});

describe('SEC-09 응답 본문에 서버 경로 없음', () => {
  it('지금까지의 모든 JSON 응답에서 경로 문자열 0건', () => {
    const needles = ['/music', '/data', env.music, env.dir, env.music.replace(/\\/g, '/'), env.dir.replace(/\\/g, '\\\\'), 'lib1/', '태그 없음/', '.mp3', '.flac'];
    for (const body of env.bodies) {
      for (const n of needles) assert.ok(!body.includes(n), `응답에 "${n}" 포함: ${body.slice(0, 300)}`);
    }
    assert.ok(env.bodies.length > 30);
  });
});

describe('SEC-11 로그인 반복 실패', () => {
  it('429와 Retry-After, 사용자 이름과 IP 각각 제한', async () => {
    let last;
    for (let i = 0; i < 6; i++) {
      last = await call(env, { method: 'POST', url: '/v1/auth/login', body: { username: 'nobody', password: `wrong-${i}`, device: device() } });
    }
    expectContract(last!, 'login');
    assert.equal(last!.statusCode, 429);
    assert.equal(last!.json().code, 'rate_limited');
    assert.ok(Number(last!.headers['retry-after']) > 0);
    // 같은 IP에서는 다른 사용자 이름도 막힌다
    const ip = await call(env, { method: 'POST', url: '/v1/auth/login', body: { ...MEMBER, password: 'whatever', device: device() } });
    assert.equal(ip.statusCode, 429);
    env.ctx.limiter.reset('ip:127.0.0.1');
  });

  it('없는 사용자와 틀린 비밀번호를 구분하지 않는다', async () => {
    env.ctx.limiter.reset('ip:127.0.0.1');
    const a = await call(env, { method: 'POST', url: '/v1/auth/login', body: { username: 'ghost', password: 'x', device: device() } });
    const b = await call(env, { method: 'POST', url: '/v1/auth/login', body: { username: ADMIN.username, password: 'x', device: device() } });
    assert.equal(a.statusCode, 401);
    assert.equal(a.json().code, b.json().code);
    assert.equal(a.json().detail, b.json().detail);
    env.ctx.limiter.reset('ip:127.0.0.1');
  });
});

describe('SEC-12 리프레시 토큰 재사용', () => {
  it('유예 시간 안 재시도는 같은 쌍, 이후 재사용은 세션 폐기', async () => {
    const s = await loginAs(env, ADMIN, device('갱신 폰'));
    const r1 = (await call(env, { method: 'POST', url: '/v1/auth/refresh', body: { refresh_token: s.refresh_token } })).json();
    env.secrets.add(r1.access_token).add(r1.refresh_token);
    const retry = (await call(env, { method: 'POST', url: '/v1/auth/refresh', body: { refresh_token: s.refresh_token } })).json();
    assert.equal(retry.refresh_token, r1.refresh_token, '응답 유실 후 재시도는 같은 새 쌍');
    // 유예 시간이 지난 것처럼 만든다
    env.ctx.store.run('UPDATE sessions SET rotated_at = ? WHERE id = ?', Date.now() - env.ctx.config.refreshGraceMs - 1000, s.session_id);
    const reuse = await call(env, { method: 'POST', url: '/v1/auth/refresh', body: { refresh_token: s.refresh_token } });
    expectContract(reuse, 'refreshToken');
    assert.equal(reuse.statusCode, 401);
    assert.equal(reuse.json().code, 'session_revoked');
    // 정상 토큰도 이제 쓸 수 없다
    const legit = await call(env, { method: 'POST', url: '/v1/auth/refresh', body: { refresh_token: r1.refresh_token } });
    assert.equal(legit.json().code, 'session_revoked');
    assert.equal((await call(env, { url: '/v1/me', token: r1.access_token })).json().code, 'session_revoked');
  });

  it('만료·비활성 계정 코드 구분', async () => {
    const s = await loginAs(env, OTHER, device('만료 폰'));
    env.ctx.store.run('UPDATE sessions SET access_expires_at = ? WHERE id = ?', Date.now() - 1, s.session_id);
    assert.equal((await call(env, { url: '/v1/me', token: s.access_token })).json().code, 'access_expired');
    env.ctx.store.run('UPDATE sessions SET refresh_expires_at = ? WHERE id = ?', Date.now() - 1, s.session_id);
    assert.equal((await call(env, { method: 'POST', url: '/v1/auth/refresh', body: { refresh_token: s.refresh_token } })).json().code, 'refresh_expired');
    assert.equal((await call(env, { url: '/v1/me', token: 'bma_nonsense' })).json().code, 'access_invalid');
    const s2 = await loginAs(env, OTHER, device('차단 폰'));
    await call(env, { method: 'PATCH', url: `/v1/admin/users/${other.user.id}`, token: admin.access_token, body: { status: 'disabled' } });
    assert.equal((await call(env, { url: '/v1/me', token: s2.access_token })).json().code, 'session_revoked');
    const login = await call(env, { method: 'POST', url: '/v1/auth/login', body: { ...OTHER, device: device() } });
    expectContract(login, 'login');
    assert.equal(login.json().code, 'account_disabled');
  });
});

describe('SEC-10 로그에 비밀값 없음', () => {
  it('토큰·비밀번호·티켓 값 0건, mt는 가려짐', async () => {
    // 티켓 URL 요청이 로그에 남도록 한 번 더 요청
    const t = (await trackIn(env.lib1))[0]!;
    const r = await rendition(t.id);
    await call(env, { method: 'HEAD', url: r.media_url });
    const log = readFileSync(env.logFile, 'utf8');
    assert.ok(log.length > 1000);
    assert.match(log, /mt=<redacted>/);
    for (const s of env.secrets) assert.ok(!log.includes(s), `로그에 비밀값 포함: ${s.slice(0, 8)}…`);
    assert.doesNotMatch(log, /"authorization"/i);
  });
});
