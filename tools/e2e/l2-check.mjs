// P6 L2 시험: 실서버(HTTPS, 실제 도메인)에 붙어 API로 확인할 수 있는 항목 (05장 §9.3)
//   FN-01  HEAD 응답의 길이·MIME·ETag가 실제 바이트와 일치 (원본 + 변환본), Range 206
//   FN-06  변환 대기열 한도 초과 시 429 + Retry-After, 그동안 서버 응답성 유지
//   token  토큰 갱신 (FN-10 "재로그인 없이 복귀" 확인용: save / check)
//
// 사용: node tools/e2e/l2-check.mjs <fn01|fn06|token-save|token-check> [--library <id>]
// 계정은 .local/p6-server.txt (git 제외)에서 읽는다. 출력에 토큰·비밀번호·미디어 티켓을 쓰지 않는다.
import { createHash, randomUUID } from 'node:crypto';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';

const cred = Object.fromEntries(
  readFileSync(new URL('../../.local/p6-server.txt', import.meta.url), 'utf8')
    .split('\n').map((l) => l.match(/^(주소|사용자 이름|비밀번호):\s*(.+)$/)).filter(Boolean).map((m) => [m[1], m[2].trim()]),
);
const BASE = process.env.BM_BASE ?? cred['주소']; // 재설치 시험 서버 등 다른 주소는 BM_BASE로
const TOKEN_FILE = new URL('../../.local/p6-token.json', import.meta.url);
const ACCEPT = [{ container: 'flac', codec: 'flac' }, { container: 'mp3', codec: 'mp3' }, { container: 'm4a', codec: 'aac' }];
const args = process.argv.slice(2);
const cmd = args[0];
const libArg = args.includes('--library') ? args[args.indexOf('--library') + 1] : undefined;

let access;
async function api(method, path, body, { auth = true, raw = false, headers = {} } = {}) {
  const r = await fetch(BASE + '/v1' + path, {
    method,
    headers: { ...(auth && access ? { authorization: `Bearer ${access}` } : {}), ...(body ? { 'content-type': 'application/json' } : {}), 'x-client-api': '1.0', ...headers },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (raw) return r;
  const text = await r.text();
  return { status: r.status, headers: r.headers, json: text ? JSON.parse(text) : null };
}

async function login() {
  const r = await api('POST', '/auth/login', {
    username: cred['사용자 이름'], password: cred['비밀번호'],
    device: { name: 'P6 L2 시험', platform: 'other', app_version: '0.1.0', installation_id: randomUUID() },
  }, { auth: false });
  if (r.status !== 200) throw new Error(`로그인 실패 ${r.status} ${r.json?.code}`);
  access = r.json.access_token;
  return r.json;
}

const results = [];
function check(name, ok, detail = '') {
  results.push({ name, ok });
  console.log(`${ok ? '통과' : '실패'}  ${name}${detail ? ' — ' + detail : ''}`);
}

async function tracks(limit) {
  const q = new URLSearchParams({ limit: String(limit), ...(libArg ? { library_id: libArg } : {}) });
  const r = await api('GET', `/tracks?${q}`);
  if (r.status !== 200) throw new Error(`곡 목록 ${r.status}`);
  return r.json.items;
}

async function resolve(trackId, quality) {
  for (let i = 0; i < 120; i++) {
    const r = i === 0
      ? await api('POST', `/tracks/${trackId}/renditions`, { purpose: 'download', quality, accept: quality === 'original' ? ACCEPT : [{ container: 'm4a', codec: 'aac' }] })
      : await api('GET', `/renditions/${results.lastRendition}`);
    if (r.status === 429) throw Object.assign(new Error('429'), { r });
    results.lastRendition = r.json.id;
    if (r.json.state === 'ready') return r.json;
    if (r.json.state === 'failed') throw new Error(`변환 실패 ${trackId}`);
    await new Promise((s) => setTimeout(s, 1000 * Number(r.headers.get('retry-after') ?? 2)));
  }
  throw new Error('변환 대기 시간 초과');
}

async function fn01() {
  await login();
  const list = (await tracks(50)).filter((t) => t.state === 'available' || t.state === undefined);
  const picks = [list[0], list[Math.floor(list.length / 2)], list[list.length - 1]];
  const cases = [...picks.map((t) => [t, 'original']), [picks[0], 'aac_128']];
  for (const [t, quality] of cases) {
    const ren = await resolve(t.id, quality);
    const url = BASE + ren.media_url;
    const head = await fetch(url, { method: 'HEAD' });
    const len = Number(head.headers.get('content-length'));
    const mime = head.headers.get('content-type');
    const etag = head.headers.get('etag');
    const get = await fetch(url);
    const buf = Buffer.from(await get.arrayBuffer());
    const sha = createHash('sha256').update(buf).digest('hex');
    const label = `FN-01 ${quality} (${(buf.length / 1048576).toFixed(1)}MB)`;
    check(`${label} HEAD 길이 = 실제 바이트`, head.status === 200 && len === buf.length && len === ren.size_bytes, `HEAD ${len}, 받은 ${buf.length}, 렌디션 ${ren.size_bytes}`);
    check(`${label} MIME 일치`, mime?.startsWith(ren.mime) && get.headers.get('content-type') === mime, mime ?? '');
    check(`${label} ETag 일치`, etag === ren.etag && get.headers.get('etag') === etag);
    if (ren.sha256) check(`${label} SHA-256 = 렌디션 값`, sha === ren.sha256);
    const from = Math.floor(buf.length / 2);
    const part = await fetch(url, { headers: { range: `bytes=${from}-`, 'if-range': etag } });
    const pb = Buffer.from(await part.arrayBuffer());
    check(`${label} Range 206 + 뒷부분 바이트 일치`, part.status === 206 && part.headers.get('content-range') === `bytes ${from}-${buf.length - 1}/${buf.length}` && pb.equals(buf.subarray(from)));
  }
}

async function fn06() {
  await login();
  const list = await tracks(60);
  const info = (await api('GET', '/server', undefined, { auth: false })).json;
  console.log(`대상 ${list.length}곡을 aac_256으로 동시에 요청 (서버 한도: limits=${JSON.stringify(info.limits ?? {})})`);
  let stop = false;
  const lat = [];
  const probe = (async () => {
    while (!stop) {
      const t0 = performance.now();
      const r = await api('GET', '/server', undefined, { auth: false });
      lat.push([r.status, performance.now() - t0]);
      await new Promise((s) => setTimeout(s, 250));
    }
  })();
  const res = await Promise.all(list.map((t) => api('POST', `/tracks/${t.id}/renditions`, { purpose: 'download', quality: 'aac_256', accept: [{ container: 'm4a', codec: 'aac' }] })));
  // 대기열이 찬 동안 일반 API도 응답하는지 몇 초 더 본다
  const browse = [];
  for (let i = 0; i < 5; i++) {
    const t0 = performance.now();
    const r = await api('GET', '/albums?limit=20');
    browse.push([r.status, performance.now() - t0]);
  }
  await new Promise((s) => setTimeout(s, 3000));
  stop = true;
  await probe;
  const by = {};
  for (const r of res) by[r.status] = (by[r.status] ?? 0) + 1;
  const r429 = res.filter((r) => r.status === 429);
  console.log('응답 분포', by);
  check('FN-06 한도를 넘는 변환 요청은 429', r429.length > 0);
  check('FN-06 429에는 Retry-After와 코드', r429.length > 0 && r429.every((r) => Number(r.headers.get('retry-after')) > 0 && r.json?.code), r429[0]?.json?.code ?? '');
  check('FN-06 나머지는 200/202', res.every((r) => [200, 202, 429].includes(r.status)));
  const worst = Math.max(...lat.map((l) => l[1]), ...browse.map((b) => b[1]));
  check('FN-06 변환 중에도 서버 응답 유지(모두 200, 최대 1.5초 이내)', [...lat, ...browse].every((l) => l[0] === 200) && worst < 1500, `요청 ${lat.length + browse.length}건, 최대 ${worst.toFixed(0)}ms`);
}

async function tokenSave() {
  const t = await login();
  writeFileSync(TOKEN_FILE, JSON.stringify({ refresh: t.refresh_token, access: t.access_token }));
  const pl = await api('GET', '/playlists?limit=50');
  console.log(`토큰 저장(.local). 플레이리스트 ${pl.json.items.length}개`);
}

async function tokenCheck() {
  if (!existsSync(TOKEN_FILE)) throw new Error('token-save를 먼저');
  const saved = JSON.parse(readFileSync(TOKEN_FILE, 'utf8'));
  access = saved.access;
  // 복원 뒤 첫 기동에서 서버가 액세스 토큰을 모두 만료시킨다(backup.ts invalidateAccessTokens).
  // 앱은 access_expired를 받으면 리프레시로 새 토큰을 받으므로 사용자는 다시 로그인하지 않는다.
  const me = await api('GET', '/me');
  check('FN-10 복원 뒤 옛 액세스 토큰은 200 또는 access_expired(세션은 유지)', me.status === 200 || me.json?.code === 'access_expired', `GET /me ${me.status} ${me.json?.code ?? ''}`);
  const rf = await api('POST', '/auth/refresh', { refresh_token: saved.refresh }, { auth: false });
  check('FN-10 복원 뒤 기존 리프레시 토큰으로 갱신(재로그인 없음)', rf.status === 200, `POST /auth/refresh ${rf.status} ${rf.json?.code ?? ''}`);
  if (rf.status === 200) {
    access = rf.json.access_token;
    const me2 = await api('GET', '/me');
    check('FN-10 새 액세스 토큰으로 요청', me2.status === 200, `GET /me ${me2.status}`);
  }
  // 리프레시 토큰은 쓸 때마다 바뀐다. 옛 값을 다시 보내면 서버가 재사용으로 보고 세션을 폐기하므로 새 값을 저장한다
  if (rf.status === 200) writeFileSync(TOKEN_FILE, JSON.stringify({ refresh: rf.json.refresh_token, access: rf.json.access_token }));
}

// FN-07: 음악 마운트가 빠진 동안(down) / 다시 붙인 뒤(up)
async function fn07(phase) {
  await login();
  const list = await tracks(200);
  console.log(`곡 목록 ${list.length}곡 (라이브러리 필터 ${libArg ? '있음' : '없음'})`);
  const t = list[0];
  const r = await api('POST', `/tracks/${t.id}/renditions`, { purpose: 'stream', quality: 'original', accept: ACCEPT });
  if (phase === 'down') {
    let status = r.status, code = r.json?.code;
    if (r.status === 200) {
      const m = await fetch(BASE + r.json.media_url, { headers: { range: 'bytes=0-1023' } });
      status = m.status;
      code = m.status >= 400 ? (await m.json().catch(() => ({}))).code : undefined;
    }
    check('FN-07 마운트 해제 중 재생 → 503 storage_unavailable', status === 503 && code === 'storage_unavailable', `${status} ${code ?? ''}`);
    check('FN-07 마운트 해제 중에도 곡 목록 유지(176곡)', list.length === 176, `${list.length}곡`);
  } else {
    const m = await fetch(BASE + r.json.media_url, { headers: { range: 'bytes=0-1023' } });
    check('FN-07 재마운트 후 재생 정상(206)', r.status === 200 && m.status === 206, `${r.status} / ${m.status}`);
    check('FN-07 재마운트 후 곡 목록 176곡', list.length === 176, `${list.length}곡`);
  }
}

try {
  if (cmd === 'fn07-down') await fn07('down');
  else if (cmd === 'fn07-up') await fn07('up');
  else if (cmd === 'fn01') await fn01();
  else if (cmd === 'fn06') await fn06();
  else if (cmd === 'token-save') await tokenSave();
  else if (cmd === 'token-check') await tokenCheck();
  else throw new Error('명령: fn01 | fn06 | token-save | token-check');
} catch (e) {
  console.error('오류:', e.message);
  process.exitCode = 1;
}
if (results.some((r) => !r.ok)) process.exitCode = 1;
