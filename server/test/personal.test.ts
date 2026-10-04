// P2: 플레이리스트·가사·재생 기록·홈·본인 데이터 계약 + SEC-05(남의 플레이리스트·기록) + SEC-13(표지 업로드). L1.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { after, before, describe, it } from 'node:test';
import { scanLibrary } from '../src/scanner/scan.ts';
import { ADMIN, call, expectContract, loginAs, MEMBER, OTHER, setup, type Env } from './helpers.ts';

let env: Env;
let admin: Awaited<ReturnType<typeof loginAs>>;
let member: Awaited<ReturnType<typeof loginAs>>;
let other: Awaited<ReturnType<typeof loginAs>>;
let tracks: Array<{ id: string; title: string; duration_ms: number }>;

before(async () => {
  env = await setup();
  admin = await loginAs(env, ADMIN);
  member = await loginAs(env, MEMBER);
  other = await loginAs(env, OTHER);
  tracks = (await call(env, { url: '/v1/tracks?limit=200&sort=title', token: member.access_token })).json().items;
});
after(() => env.close());

const byTitle = (t: string) => tracks.find((x) => x.title === t)!;

async function req(op: string, r: Parameters<typeof call>[1]) {
  const res = await call(env, r);
  expectContract(res, op);
  return res;
}

describe('플레이리스트', () => {
  let plId = '';
  let etag = '';
  let items: Array<{ item_id: string; track?: { id: string } }> = [];

  it('생성: Idempotency-Key 재전송은 같은 결과, 플레이리스트는 하나', async () => {
    const key = randomUUID();
    const body = { name: '새벽 모음', description: '합성', track_ids: [byTitle('새벽 공기').id, byTitle('夜明けのうた').id, byTitle('형식 flac-16').id] };
    const a = await req('createPlaylist', { method: 'POST', url: '/v1/playlists', token: member.access_token, body, headers: { 'idempotency-key': key } });
    assert.equal(a.statusCode, 201);
    const b = await req('createPlaylist', { method: 'POST', url: '/v1/playlists', token: member.access_token, body, headers: { 'idempotency-key': key } });
    assert.equal(b.json().id, a.json().id);
    assert.equal(b.headers['idempotent-replay'], 'true');
    const list = (await req('listPlaylists', { url: '/v1/playlists', token: member.access_token })).json();
    assert.equal(list.items.length, 1);
    plId = a.json().id;
    etag = String(a.headers.etag);
    assert.equal(a.json().item_count, 3);
    assert.ok(a.json().mosaic_artwork_ids.length >= 1);
  });

  it('항목 순서, 편집(add/move/remove) 원자 적용, 412/428', async () => {
    items = (await req('listPlaylistItems', { url: `/v1/playlists/${plId}/items`, token: member.access_token })).json().items;
    assert.deepEqual(items.map((i) => i.track!.id), [byTitle('새벽 공기').id, byTitle('夜明けのうた').id, byTitle('형식 flac-16').id]);
    const noMatch = await req('editPlaylist', { method: 'POST', url: `/v1/playlists/${plId}/edits`, token: member.access_token, body: { ops: [{ op: 'remove', item_ids: [items[0]!.item_id] }] } });
    assert.equal(noMatch.statusCode, 428);
    const stale = await req('editPlaylist', { method: 'POST', url: `/v1/playlists/${plId}/edits`, token: member.access_token, headers: { 'if-match': '"999"' }, body: { ops: [{ op: 'remove', item_ids: [items[0]!.item_id] }] } });
    assert.equal(stale.statusCode, 412);
    assert.equal(stale.json().code, 'version_conflict');
    assert.equal(stale.headers.etag, etag, '현재 ETag를 함께 준다');
    // 하나라도 틀리면 아무것도 바뀌지 않는다
    const bad = await req('editPlaylist', { method: 'POST', url: `/v1/playlists/${plId}/edits`, token: member.access_token, headers: { 'if-match': etag },
      body: { ops: [{ op: 'remove', item_ids: [items[0]!.item_id] }, { op: 'remove', item_ids: ['pli_01JB2Q6F8H0K2M4P6R8T0V2X4Z'] }] } });
    assert.equal(bad.statusCode, 400);
    assert.equal((await req('getPlaylist', { url: `/v1/playlists/${plId}`, token: member.access_token })).json().item_count, 3);

    const key = randomUUID();
    const ops = [
      { op: 'add', track_ids: [byTitle('형식 wav').id], after_item_id: null }, // 맨 앞
      { op: 'move', item_id: items[2]!.item_id, after_item_id: items[0]!.item_id }, // flac-16을 두 번째 원래 항목 앞으로
      { op: 'remove', item_ids: [items[1]!.item_id] },
      { op: 'add', track_ids: [byTitle('형식 opus').id, byTitle('형식 opus').id] }, // 맨 뒤, 같은 곡 중복 허용
    ];
    const ok = await req('editPlaylist', { method: 'POST', url: `/v1/playlists/${plId}/edits`, token: member.access_token, headers: { 'if-match': etag, 'idempotency-key': key }, body: { ops } });
    assert.equal(ok.statusCode, 200);
    // 응답을 못 받았다고 보고 같은 편집을 다시 보내도 412가 아니라 같은 결과 (FN-22 서버 측)
    const replay = await req('editPlaylist', { method: 'POST', url: `/v1/playlists/${plId}/edits`, token: member.access_token, headers: { 'if-match': etag, 'idempotency-key': key }, body: { ops } });
    assert.equal(replay.statusCode, 200);
    assert.equal(replay.json().version, ok.json().version);
    etag = String(ok.headers.etag);
    const after = (await req('listPlaylistItems', { url: `/v1/playlists/${plId}/items?limit=2`, token: member.access_token })).json();
    const all = [...after.items];
    let cursor = after.next_cursor;
    while (cursor) {
      const pg = (await req('listPlaylistItems', { url: `/v1/playlists/${plId}/items?limit=2&cursor=${encodeURIComponent(cursor)}`, token: member.access_token })).json();
      all.push(...pg.items);
      cursor = pg.next_cursor;
    }
    assert.deepEqual(all.map((i: { track: { id: string } }) => i.track.id),
      [byTitle('형식 wav').id, byTitle('새벽 공기').id, byTitle('형식 flac-16').id, byTitle('형식 opus').id, byTitle('형식 opus').id]);
  });

  it('이름 변경(If-Match), 검색, 삭제(멱등)', async () => {
    const miss = await req('updatePlaylist', { method: 'PATCH', url: `/v1/playlists/${plId}`, token: member.access_token, body: { name: 'x' } });
    assert.equal(miss.statusCode, 428);
    const up = await req('updatePlaylist', { method: 'PATCH', url: `/v1/playlists/${plId}`, token: member.access_token, headers: { 'if-match': etag }, body: { name: '새벽의 노래들' } });
    assert.equal(up.json().name, '새벽의 노래들');
    etag = String(up.headers.etag);
    const s = (await req('search', { url: `/v1/search?q=${encodeURIComponent('노래')}&types=playlist`, token: member.access_token })).json();
    assert.equal(s.playlists.items[0].id, plId);
    const s2 = (await req('search', { url: `/v1/search?q=${encodeURIComponent('노래')}&types=playlist`, token: other.access_token })).json();
    assert.equal(s2.playlists.items.length, 0, '남의 플레이리스트는 검색되지 않는다');
  });

  it('SEC-05: 다른 사용자(관리자 포함)의 플레이리스트 → 404', async () => {
    for (const tok of [other.access_token, admin.access_token]) {
      for (const [r, op] of [
        [{ url: `/v1/playlists/${plId}` }, 'getPlaylist'],
        [{ url: `/v1/playlists/${plId}/items` }, 'listPlaylistItems'],
        [{ method: 'PATCH', url: `/v1/playlists/${plId}`, headers: { 'if-match': etag }, body: { name: 'hack' } }, 'updatePlaylist'],
        [{ method: 'POST', url: `/v1/playlists/${plId}/edits`, headers: { 'if-match': etag }, body: { ops: [{ op: 'add', track_ids: [tracks[0]!.id] }] } }, 'editPlaylist'],
        [{ method: 'DELETE', url: `/v1/playlists/${plId}` }, 'deletePlaylist'],
        [{ method: 'DELETE', url: `/v1/playlists/${plId}/cover` }, 'deletePlaylistCover'],
      ] as const) {
        const res = await req(op, { ...(r as object), token: tok } as Parameters<typeof call>[1]);
        assert.equal(res.statusCode, 404, `${op}`);
      }
    }
  });

  it('접근 권한이 사라진 곡은 순서를 지키는 자리표시자', async () => {
    // lib2 곡을 넣은 관리자 플레이리스트에서 관리자 → lib2만 보이도록 바꿀 수 없으므로 member로 시험
    await call(env, { method: 'PATCH', url: `/v1/admin/users/${member.user.id}`, token: admin.access_token, body: { library_ids: [env.lib1, env.lib2] } });
    const lib2 = (await call(env, { url: `/v1/tracks?library_id=${env.lib2}`, token: member.access_token })).json().items[0];
    const pl = (await req('createPlaylist', { method: 'POST', url: '/v1/playlists', token: member.access_token, body: { name: '권한 시험', track_ids: [tracks[0]!.id, lib2.id, tracks[1]!.id] } })).json();
    await call(env, { method: 'PATCH', url: `/v1/admin/users/${member.user.id}`, token: admin.access_token, body: { library_ids: [env.lib1] } });
    const items = (await req('listPlaylistItems', { url: `/v1/playlists/${pl.id}/items`, token: member.access_token })).json().items;
    assert.deepEqual(items.map((i: { available: boolean }) => i.available), [true, false, true]);
    assert.equal(items[1].track, undefined);
    // 접근할 수 없는 곡은 추가할 수 없다 (존재를 드러내지 않게 400)
    const add = await req('editPlaylist', { method: 'POST', url: `/v1/playlists/${pl.id}/edits`, token: member.access_token, headers: { 'if-match': `"${pl.version}"` }, body: { ops: [{ op: 'add', track_ids: [lib2.id] }] } });
    assert.equal(add.statusCode, 400);
  });

  it('표지 업로드: JPEG 정상(EXIF 제거·재인코딩), 413, 415, 손상 400, 압축 폭탄 400 (SEC-13)', async () => {
    const ffmpeg = env.ctx.config.ffmpeg;
    const make = (args: string[]) => {
      const r = spawnSync(ffmpeg, ['-v', 'error', '-f', 'lavfi', ...args, '-frames:v', '1', '-f', 'image2pipe', '-'], { maxBuffer: 64 * 1024 * 1024 });
      assert.equal(r.status, 0, r.stderr?.toString());
      return r.stdout;
    };
    const jpeg = make(['-i', 'color=c=0x336699:s=800x600', '-c:v', 'mjpeg']);
    let pl = (await req('getPlaylist', { url: `/v1/playlists/${plId}`, token: member.access_token }));
    const ok = await req('putPlaylistCover', { method: 'PUT', url: `/v1/playlists/${plId}/cover`, token: member.access_token, headers: { 'content-type': 'image/jpeg', 'if-match': String(pl.headers.etag) }, body: jpeg });
    assert.equal(ok.statusCode, 200, ok.body);
    assert.ok(ok.json().artwork_id);
    const img = await call(env, { url: `/v1/artwork/${ok.json().artwork_id}?size=256`, token: member.access_token });
    assert.equal(img.statusCode, 200, '소유자는 자기 플레이리스트 표지를 볼 수 있다');

    pl = (await req('getPlaylist', { url: `/v1/playlists/${plId}`, token: member.access_token }));
    const ifm = { 'if-match': String(pl.headers.etag) };
    const big = await req('putPlaylistCover', { method: 'PUT', url: `/v1/playlists/${plId}/cover`, token: member.access_token, headers: { 'content-type': 'image/jpeg', ...ifm }, body: Buffer.alloc(6 * 1024 * 1024, 0xff) });
    assert.equal(big.statusCode, 413);
    assert.equal(big.json().code, 'payload_too_large');
    const gif = await req('putPlaylistCover', { method: 'PUT', url: `/v1/playlists/${plId}/cover`, token: member.access_token, headers: { 'content-type': 'image/gif', ...ifm }, body: Buffer.from('GIF89a') });
    assert.equal(gif.statusCode, 415);
    assert.equal(gif.json().code, 'unsupported_media_type');
    const junk = await req('putPlaylistCover', { method: 'PUT', url: `/v1/playlists/${plId}/cover`, token: member.access_token, headers: { 'content-type': 'image/png', ...ifm }, body: Buffer.from('not an image at all') });
    assert.equal(junk.statusCode, 400);
    // 작게 압축되지만 풀면 거대한 이미지 (12000×12000 단색 PNG = 144MP)
    const bomb = make(['-i', 'color=c=black:s=12000x12000', '-c:v', 'png', '-compression_level', '9']);
    assert.ok(bomb.length < 5 * 1024 * 1024, `폭탄 크기 ${bomb.length}`);
    const b = await req('putPlaylistCover', { method: 'PUT', url: `/v1/playlists/${plId}/cover`, token: member.access_token, headers: { 'content-type': 'image/png', ...ifm }, body: bomb });
    assert.equal(b.statusCode, 400);
    assert.equal((await call(env, { url: '/v1/server' })).statusCode, 200, '서버 생존');
    const del = await req('deletePlaylistCover', { method: 'DELETE', url: `/v1/playlists/${plId}/cover`, token: member.access_token });
    assert.equal(del.statusCode, 204);
    assert.equal((await req('getPlaylist', { url: `/v1/playlists/${plId}`, token: member.access_token })).json().artwork_id, null);
  });

  it('삭제는 멱등', async () => {
    assert.equal((await req('deletePlaylist', { method: 'DELETE', url: `/v1/playlists/${plId}`, token: member.access_token })).statusCode, 204);
    assert.equal((await req('deletePlaylist', { method: 'DELETE', url: `/v1/playlists/${plId}`, token: member.access_token })).statusCode, 204);
    assert.equal((await req('getPlaylist', { url: `/v1/playlists/${plId}`, token: member.access_token })).statusCode, 404);
  });
});

describe('가사', () => {
  it('사이드카 3종 (원문 동기·한글 발음·번역), has_lyrics', async () => {
    const t = byTitle('夜明けのうた');
    const track = (await req('getTrack', { url: `/v1/tracks/${t.id}`, token: member.access_token })).json();
    assert.deepEqual(track.has_lyrics, ['original', 'pronunciation_ko', 'translation_ko']);
    const l = await req('getLyrics', { url: `/v1/tracks/${t.id}/lyrics`, token: member.access_token });
    const j = l.json();
    assert.equal(j.variants.length, 3);
    for (const v of j.variants) {
      assert.equal(v.synced, true);
      assert.equal(v.lines.length, 6);
      assert.equal(v.lines[1].t_ms, 10_000);
      assert.equal(v.source.type, 'sidecar');
    }
    assert.match(j.variants[1].lines[0].text, /요아케노/);
    const again = await req('getLyrics', { url: `/v1/tracks/${t.id}/lyrics`, token: member.access_token, headers: { 'if-none-match': String(l.headers.etag) } });
    assert.equal(again.statusCode, 304);
  });

  it('비동기 .txt, 깨진 LRC도 예외 없이', async () => {
    const plain = (await req('getLyrics', { url: `/v1/tracks/${byTitle('光の中へ').id}/lyrics`, token: member.access_token })).json();
    assert.equal(plain.variants[0].synced, false);
    assert.ok(plain.variants[0].lines.every((x: { t_ms: number | null }) => x.t_ms === null));
    const broken = (await req('getLyrics', { url: `/v1/tracks/${byTitle('ﾊﾝｶｸ ｶﾀｶﾅ と ＺＥＮＫＡＫＵ').id}/lyrics`, token: member.access_token })).json();
    const times = broken.variants[0].lines.map((x: { t_ms: number }) => x.t_ms);
    assert.deepEqual(times, [3000, 5000, 20000, 25000, 30000], '범위 밖·형식 오류 줄 제외, 시간순, 한 줄의 여러 시간');
  });

  it('한글 발음 사이드카가 없는 일본어 원문은 발음을 자동 생성 (05장 §8.4, source generated)', async () => {
    const t = byTitle('光の中へ');
    const track = (await req('getTrack', { url: `/v1/tracks/${t.id}`, token: member.access_token })).json();
    assert.deepEqual(track.has_lyrics, ['original', 'pronunciation_ko']);
    const res = await req('getLyrics', { url: `/v1/tracks/${t.id}/lyrics`, token: member.access_token });
    const l = res.json();
    const original = l.variants.find((v: { kind: string }) => v.kind === 'original');
    const pron = l.variants.find((v: { kind: string }) => v.kind === 'pronunciation_ko');
    assert.equal(pron.source.type, 'generated');
    assert.equal(pron.language, 'ko');
    assert.equal(pron.synced, original.synced);
    assert.equal(pron.lines.length, original.lines.length, '원문과 줄 수가 같아야 앱이 순서대로 맞춘다');
    assert.equal(pron.lines[0].text, '히카리노 나카에');
    assert.equal(pron.lines.at(-1).text, '', '일본어가 없는 줄은 빈 발음');
    assert.match(String(res.headers.etag), /-g\d+"$/);
    const again = await call(env, { url: `/v1/tracks/${t.id}/lyrics`, token: member.access_token, headers: { 'if-none-match': String(res.headers.etag) } });
    assert.equal(again.statusCode, 304);
    // 한국어만 있는 곡·사이드카 발음이 있는 곡은 생성하지 않는다
    const yoake = (await call(env, { url: `/v1/tracks/${byTitle('夜明けのうた').id}/lyrics`, token: member.access_token })).json();
    assert.equal(yoake.variants.find((v: { kind: string }) => v.kind === 'pronunciation_ko').source.type, 'sidecar');
  });

  it('직접 입력(관리자, If-Match), 일반 사용자 403, 재스캔이 덮어쓰지 않음, 보정값', async () => {
    const t = byTitle('夜明けのうた');
    const cur = await call(env, { url: `/v1/tracks/${t.id}/lyrics`, token: admin.access_token });
    const body = { format: 'lrc', body: '[00:01.00]직접 입력한 발음\n[00:02.50]둘째 줄', language: 'ko' };
    const forbid = await req('putLyricsVariant', { method: 'PUT', url: `/v1/tracks/${t.id}/lyrics/pronunciation_ko`, token: member.access_token, headers: { 'if-match': String(cur.headers.etag) }, body });
    assert.equal(forbid.statusCode, 403);
    const stale = await req('putLyricsVariant', { method: 'PUT', url: `/v1/tracks/${t.id}/lyrics/pronunciation_ko`, token: admin.access_token, headers: { 'if-match': '"v0-o0"' }, body });
    assert.equal(stale.statusCode, 412);
    const ok = await req('putLyricsVariant', { method: 'PUT', url: `/v1/tracks/${t.id}/lyrics/pronunciation_ko`, token: admin.access_token, headers: { 'if-match': String(cur.headers.etag) }, body });
    assert.equal(ok.statusCode, 200);
    const pron = ok.json().variants.find((v: { kind: string }) => v.kind === 'pronunciation_ko');
    assert.equal(pron.source.type, 'user');
    assert.equal(pron.lines[1].t_ms, 2500);
    await scanLibrary(env.ctx, env.lib1);
    const still = (await call(env, { url: `/v1/tracks/${t.id}/lyrics`, token: member.access_token })).json();
    assert.equal(still.variants.find((v: { kind: string }) => v.kind === 'pronunciation_ko').source.type, 'user');
    const off = await req('putLyricsOffset', { method: 'PUT', url: `/v1/tracks/${t.id}/lyrics/offset`, token: member.access_token, body: { offset_ms: -250 } });
    assert.equal(off.statusCode, 204);
    assert.equal((await call(env, { url: `/v1/tracks/${t.id}/lyrics`, token: member.access_token })).json().offset_ms, -250);
    assert.equal((await call(env, { url: `/v1/tracks/${t.id}/lyrics`, token: other.access_token })).json().offset_ms, 0, '보정값은 사용자별');
    const range = await req('putLyricsOffset', { method: 'PUT', url: `/v1/tracks/${t.id}/lyrics/offset`, token: member.access_token, body: { offset_ms: 99999 } });
    assert.equal(range.statusCode, 400);
  });

  it('사이드카가 바뀌면 다음 스캔에 반영되고 버전이 오른다', async () => {
    const t = byTitle('夜明けのうた');
    const before = (await call(env, { url: `/v1/tracks/${t.id}/lyrics`, token: member.access_token })).json().version;
    const file = join(env.music, 'lib1', '合成アルバム', '03-yoake.ko.lrc');
    writeFileSync(file, readFileSync(file, 'utf8').replace('새벽의 1번째 말', '새벽의 첫 말'));
    await scanLibrary(env.ctx, env.lib1);
    const j = (await call(env, { url: `/v1/tracks/${t.id}/lyrics`, token: member.access_token })).json();
    assert.ok(j.version > before);
    assert.equal(j.variants.find((v: { kind: string }) => v.kind === 'translation_ko').lines[0].text, '새벽의 첫 말');
  });
});

describe('재생 기록', () => {
  const ev = (track: { id: string }, played: number, id = randomUUID()) => ({
    event_id: id, track_id: track.id, started_at: new Date(Date.now() - 60_000).toISOString(), played_ms: played, completed: false, source: 'offline', context: { type: 'album', id: null },
  });

  it('일괄 전송, 중복 재전송은 duplicates, 없는·권한 없는 곡은 rejected (FN-22 서버 측)', async () => {
    const batch = [ev(byTitle('형식 flac-16'), 31_000), ev(byTitle('새벽 공기'), 16_000), ev(byTitle('길이 1초'), 600), ev(byTitle('형식 wav'), 5_000)];
    const a = await req('postPlayEvents', { method: 'POST', url: '/v1/history/events', token: member.access_token, body: { events: batch } });
    assert.deepEqual(a.json(), { accepted: 4, duplicates: 0, rejected: [] });
    const b = await req('postPlayEvents', { method: 'POST', url: '/v1/history/events', token: member.access_token, body: { events: batch } });
    assert.deepEqual(b.json(), { accepted: 0, duplicates: 4, rejected: [] });
    const lib2 = (await call(env, { url: `/v1/tracks?library_id=${env.lib2}`, token: admin.access_token })).json().items[0];
    const c = await req('postPlayEvents', { method: 'POST', url: '/v1/history/events', token: member.access_token, body: { events: [ev(lib2, 40_000), ev({ id: 'trk_01JB2P3C5E7G9J1L3N5Q7S9U1W' }, 40_000)] } });
    assert.equal(c.json().accepted, 0);
    assert.equal(c.json().rejected.length, 2);
  });

  it('최근·많이 들은 곡: 재생이 시작된 곡은 모두 1회 (기존 BangMusic 규칙, 03장 §6.9)', async () => {
    const recent = (await req('getRecentTracks', { url: '/v1/history/recent', token: member.access_token })).json();
    // 들은 길이와 무관하게 받은 이벤트는 모두 센다 (기존 앱: 곡을 불러와 재생을 시작하면 1회)
    assert.deepEqual(new Set(recent.items.map((t: { title: string }) => t.title)), new Set(['형식 flac-16', '새벽 공기', '길이 1초', '형식 wav']));
    await req('postPlayEvents', { method: 'POST', url: '/v1/history/events', token: member.access_token, body: { events: [ev(byTitle('새벽 공기'), 30_000), ev(byTitle('새벽 공기'), 30_000)] } });
    const topRes = (await req('getTopTracks', { url: '/v1/history/top?window=30d', token: member.access_token })).json();
    assert.equal(topRes.items[0].title, '새벽 공기');
    assert.equal((await req('getRecentTracks', { url: '/v1/history/recent', token: other.access_token })).json().items.length, 0, 'SEC-05: 남의 기록은 보이지 않는다');
    const page = (await req('getRecentTracks', { url: '/v1/history/recent?limit=2', token: member.access_token })).json();
    assert.ok(page.next_cursor);
    const p2 = (await req('getRecentTracks', { url: `/v1/history/recent?limit=2&cursor=${encodeURIComponent(page.next_cursor)}`, token: member.access_token })).json();
    assert.equal(p2.items.length, 2);
  });

  it('다른 사용자가 같은 event_id를 보내도 내 기록이 드러나지 않는다', async () => {
    const id = randomUUID();
    await call(env, { method: 'POST', url: '/v1/history/events', token: member.access_token, body: { events: [ev(byTitle('형식 opus'), 40_000, id)] } });
    const r = (await call(env, { method: 'POST', url: '/v1/history/events', token: other.access_token, body: { events: [ev(byTitle('형식 opus'), 40_000, id)] } })).json();
    assert.equal(r.duplicates, 0);
    assert.equal(r.rejected.length, 1);
  });

  it('홈·내보내기·기록 삭제', async () => {
    const h = (await req('getHome', { url: '/v1/home?limit=5', token: member.access_token })).json();
    assert.ok(h.recent_tracks.length > 0);
    assert.ok(h.recently_added_albums.length > 0);
    assert.ok(h.playlists.length > 0);
    const ex = await req('exportMe', { url: '/v1/me/export', token: member.access_token });
    assert.ok(ex.json().play_events.length >= 6);
    assert.ok(ex.json().playlists.length >= 1);
    assert.doesNotMatch(ex.body, /password|refresh|bm[ar]_/);
    assert.equal((await req('deleteHistory', { method: 'DELETE', url: '/v1/history', token: member.access_token })).statusCode, 204);
    assert.equal((await call(env, { url: '/v1/history/recent', token: member.access_token })).json().items.length, 0);
  });
});

describe('계정 삭제', () => {
  it('비밀번호 확인, 마지막 관리자 409, 삭제 후 세션 무효', async () => {
    const wrong = await req('deleteMe', { method: 'DELETE', url: '/v1/me', token: other.access_token, body: { password: 'wrong-password' } });
    assert.equal(wrong.statusCode, 401);
    const last = await req('deleteMe', { method: 'DELETE', url: '/v1/me', token: admin.access_token, body: { password: ADMIN.password } });
    assert.equal(last.statusCode, 409);
    assert.equal(last.json().code, 'last_admin');
    const ok = await req('deleteMe', { method: 'DELETE', url: '/v1/me', token: other.access_token, body: { password: OTHER.password } });
    assert.equal(ok.statusCode, 204);
    assert.equal((await call(env, { url: '/v1/me', token: other.access_token })).statusCode, 401);
    const relogin = await call(env, { method: 'POST', url: '/v1/auth/login', body: { ...OTHER, device: { name: 'x', platform: 'android', app_version: '1', installation_id: randomUUID() } } });
    assert.equal(relogin.statusCode, 401);
    assert.equal(env.ctx.store.get<{ n: number }>('SELECT COUNT(*) AS n FROM play_events WHERE user_id = ?', other.user.id)!.n, 0);
  });
});
