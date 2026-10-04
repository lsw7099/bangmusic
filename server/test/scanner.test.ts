// P1 수용 기준: FN-08 (이동·이름 변경 후 재스캔 → 곡 ID 유지). L1.
// 01장 §4.3 매핑 규칙과 §4.4 저장소 장애 보호도 확인한다.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdirSync, readdirSync, renameSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { after, before, describe, it } from 'node:test';
import { scanLibrary } from '../src/scanner/scan.ts';
import { ADMIN, call, expectContract, loginAs, setup, type Env } from './helpers.ts';

let env: Env;
let token: string;

before(async () => {
  env = await setup();
  token = (await loginAs(env, ADMIN)).access_token;
});
after(() => env.close());

interface T { id: string; title: string; media_version: string; state: string }
const lib1 = () => join(env.music, 'lib1');
const tracksByTitle = () => new Map(env.ctx.store.all<T>('SELECT id, title, media_version, state FROM tracks WHERE library_id = ?', env.lib1).map((t) => [t.title, t]));

describe('FN-08 이동·이름 변경', () => {
  it('파일 이름 변경 → 같은 곡 ID, 같은 미디어 버전', async () => {
    const before = tracksByTitle().get('새벽 공기')!;
    renameSync(join(lib1(), '한글 앨범', '01-새벽.mp3'), join(lib1(), '한글 앨범', '01-새벽 (이름 바꿈).mp3'));
    const s = await scanLibrary(env.ctx, env.lib1);
    assert.equal(s.moved, 1);
    assert.equal(s.added, 0);
    assert.equal(s.missing, 0);
    const now = tracksByTitle().get('새벽 공기')!;
    assert.equal(now.id, before.id);
    assert.equal(now.media_version, before.media_version);
    assert.equal(now.state, 'available');
  });

  it('폴더 통째로 이동 (곡 9개) → 모든 ID 유지, 대량 누락으로 오인하지 않음', async () => {
    const before = tracksByTitle();
    mkdirSync(join(lib1(), '정리됨'));
    renameSync(join(lib1(), '형식 모음 (Formats)'), join(lib1(), '정리됨', 'Formats'));
    const s = await scanLibrary(env.ctx, env.lib1);
    assert.equal(s.pendingReview, false);
    assert.equal(s.moved, 9);
    const after = tracksByTitle();
    for (const [title, t] of before) assert.equal(after.get(title)!.id, t.id, title);
    // API에서도 같은 곡으로 재생할 수 있다
    const t = after.get('형식 flac-16')!;
    const r = await call(env, { method: 'POST', url: `/v1/tracks/${t.id}/renditions`, token, body: { purpose: 'stream', quality: 'original', accept: [{ container: 'flac', codec: 'flac' }] } });
    assert.equal(r.statusCode, 200);
    assert.equal((await call(env, { method: 'HEAD', url: r.json().media_url })).statusCode, 200);
  });

  it('태그만 고친 뒤 이동 → 오디오 지문으로 같은 곡, 미디어 버전은 바뀜', async () => {
    const ffmpeg = env.ctx.config.ffmpeg;
    // 제목 '중복'인 곡은 일부러 2개(duplicate-a·b)다. 제목으로 찾으면 스캔 순서(디렉터리 나열 순서)에 따라
    // b를 집어 Linux에서만 실패했다 → 고칠 파일의 경로로 찾는다.
    const before = env.ctx.store.get<T>(`SELECT t.id, t.title, t.media_version, t.state FROM tracks t JOIN media_files m ON m.track_id = t.id
      WHERE m.library_id = ? AND m.rel_path = ?`, env.lib1, '이상 파일/duplicate-a.mp3')!;
    assert.equal(before.title, '중복');
    const src = join(lib1(), '이상 파일', 'duplicate-a.mp3');
    const dst = join(lib1(), '이상 파일', 'retagged-moved.mp3');
    const r = spawnSync(ffmpeg, ['-v', 'error', '-y', '-i', src, '-map', '0', '-c', 'copy', '-metadata', 'title=중복 (태그 수정)', dst]);
    assert.equal(r.status, 0, r.stderr?.toString());
    rmSync(src);
    const s = await scanLibrary(env.ctx, env.lib1);
    assert.equal(s.moved, 1, JSON.stringify(s));
    const t = env.ctx.store.get<T>('SELECT id, title, media_version, state FROM tracks WHERE id = ?', before.id)!;
    assert.equal(t.title, '중복 (태그 수정)');
    assert.notEqual(t.media_version, before.media_version);
    const api = await call(env, { url: `/v1/tracks/${before.id}`, token });
    expectContract(api, 'getTrack');
    assert.equal(api.json().title, '중복 (태그 수정)');
  });

  it('내용이 같은 중복 파일은 각각 다른 곡', () => {
    const dups = env.ctx.store.all<{ id: string }>("SELECT t.id FROM tracks t JOIN media_files m ON m.track_id = t.id WHERE m.rel_path LIKE '이상 파일/%duplicate-b.mp3'");
    assert.equal(dups.length, 1);
  });
});

describe('저장소 장애 보호 (01장 §4.4)', () => {
  it('라이브러리 루트가 사라짐(마운트 해제) → 스캔 중단, 곡을 missing으로 바꾸지 않음, 미디어 503', async () => {
    const t = tracksByTitle().get('새벽 공기')!;
    const r = (await call(env, { method: 'POST', url: `/v1/tracks/${t.id}/renditions`, token, body: { purpose: 'stream', quality: 'original', accept: [{ container: 'mp3', codec: 'mp3' }] } })).json();
    const away = join(env.music, 'lib1-unmounted');
    renameSync(lib1(), away);
    try {
      await assert.rejects(scanLibrary(env.ctx, env.lib1), (e: Error & { code?: string }) => e.code === 'storage_unavailable');
      assert.equal(env.ctx.store.get<{ n: number }>("SELECT COUNT(*) AS n FROM tracks WHERE library_id = ? AND state = 'missing'", env.lib1)!.n, 0);
      const media = await call(env, { url: r.media_url });
      expectContract(media, 'getMedia');
      assert.equal(media.statusCode, 503);
      assert.equal(media.json().code, 'storage_unavailable');
      const libs = (await call(env, { url: '/v1/admin/libraries', token })).json().items;
      assert.equal(libs.find((l: { id: string }) => l.id === env.lib1).status, 'unavailable');
    } finally {
      renameSync(away, lib1());
    }
    // 자동 복구 (01장 §4.4, FN-07 실서버에서 발견): 수동 스캔 없이 다음 요청부터 정상
    const back = await call(env, { method: 'POST', url: `/v1/tracks/${t.id}/renditions`, token, body: { purpose: 'stream', quality: 'original', accept: [{ container: 'mp3', codec: 'mp3' }] } });
    expectContract(back, 'resolveRendition');
    assert.equal(back.statusCode, 200);
    assert.equal(env.ctx.store.get<{ status: string }>('SELECT status FROM libraries WHERE id = ?', env.lib1)!.status, 'online');
    assert.equal((await call(env, { url: back.json().media_url, headers: { range: 'bytes=0-15' } })).statusCode, 206);
    const s = await scanLibrary(env.ctx, env.lib1);
    assert.equal(s.missing, 0);
    assert.equal(env.ctx.store.get<{ status: string }>('SELECT status FROM libraries WHERE id = ?', env.lib1)!.status, 'online');
  });

  it('루트가 빈 폴더(마운트 지점만 남음) → 첫 재생 요청부터 503, 스캔 중단', async () => {
    const t = env.ctx.store.get<{ id: string }>("SELECT id FROM tracks WHERE library_id = ? AND state = 'available' LIMIT 1", env.lib2)!;
    const accept = [{ container: 'flac', codec: 'flac' }, { container: 'mp3', codec: 'mp3' }, { container: 'm4a', codec: 'aac' }, { container: 'ogg', codec: 'opus' }, { container: 'ogg', codec: 'vorbis' }];
    const r = (await call(env, { method: 'POST', url: `/v1/tracks/${t.id}/renditions`, token, body: { purpose: 'stream', quality: 'original', accept } })).json();
    const away = join(env.music, 'lib2-real');
    renameSync(join(env.music, 'lib2'), away);
    mkdirSync(join(env.music, 'lib2'));
    try {
      // FN-07 실서버: 스캔이 라이브러리를 unavailable로 바꾸기 전의 첫 요청이 404 media_missing으로 나갔다
      const media = await call(env, { url: r.media_url });
      expectContract(media, 'getMedia');
      assert.equal(media.statusCode, 503);
      assert.equal(media.json().code, 'storage_unavailable');
      // 실제 경로가 같으므로 루트 확인은 통과하고, 비어 있어서 중단된다
      await assert.rejects(scanLibrary(env.ctx, env.lib2), (e: Error & { code?: string }) => e.code === 'storage_unavailable');
      assert.equal(env.ctx.store.get<{ n: number }>("SELECT COUNT(*) AS n FROM tracks WHERE library_id = ? AND state = 'missing'", env.lib2)!.n, 0);
    } finally {
      rmSync(join(env.music, 'lib2'), { recursive: true });
      renameSync(away, join(env.music, 'lib2'));
    }
  });

  it('대량 누락(기본 20% 이상) → 적용 보류, --force로 적용, 파일 복귀 시 available', async () => {
    const dir = join(lib1(), '길이 모음 (Lengths)');
    const parked = join(env.music, 'parked');
    renameSync(dir, parked);
    const japanese = join(lib1(), '合成アルバム');
    const parked2 = join(env.music, 'parked2');
    renameSync(japanese, parked2);
    const total = env.ctx.store.get<{ n: number }>("SELECT COUNT(*) AS n FROM tracks WHERE library_id = ? AND state = 'available'", env.lib1)!.n;
    const s = await scanLibrary(env.ctx, env.lib1);
    assert.equal(s.pendingReview, true, `${s.missing}/${total}`);
    assert.equal(env.ctx.store.get<{ n: number }>("SELECT COUNT(*) AS n FROM tracks WHERE library_id = ? AND state = 'missing'", env.lib1)!.n, 0);
    const libs = (await call(env, { url: '/v1/admin/libraries', token })).json().items;
    assert.equal(libs.find((l: { id: string }) => l.id === env.lib1).pending_review, true);

    const forced = await scanLibrary(env.ctx, env.lib1, { force: true });
    assert.ok(forced.missing >= 8, JSON.stringify(forced));
    const missingTrack = env.ctx.store.get<T>("SELECT id, title, media_version, state FROM tracks WHERE title = '夜明けのうた'")!;
    assert.equal(missingTrack.state, 'missing');
    const api = await call(env, { url: `/v1/tracks/${missingTrack.id}`, token });
    assert.equal(api.json().state, 'missing', '누락 곡도 ID는 남는다');
    const rend = await call(env, { method: 'POST', url: `/v1/tracks/${missingTrack.id}/renditions`, token, body: { purpose: 'stream', quality: 'original', accept: [{ container: 'flac', codec: 'flac' }] } });
    expectContract(rend, 'resolveRendition');
    assert.equal(rend.json().code, 'media_missing');

    renameSync(parked, dir);
    renameSync(parked2, japanese);
    const back = await scanLibrary(env.ctx, env.lib1);
    assert.equal(back.restored, forced.missing);
    assert.equal(tracksByTitle().get('夜明けのうた')!.id, missingTrack.id);
    assert.equal(tracksByTitle().get('夜明けのうた')!.state, 'available');
  });

  it('손상 파일은 그 파일만 실패, 스캔은 계속 (0바이트)', async () => {
    const s = await scanLibrary(env.ctx, env.lib1);
    assert.equal(s.errors, 1, '0바이트 파일 하나만 실패');
    const zero = env.ctx.store.get("SELECT 1 FROM media_files WHERE rel_path LIKE '%zero-bytes.mp3'");
    assert.equal(zero, undefined);
    assert.ok(readdirSync(join(lib1(), '이상 파일')).includes('zero-bytes.mp3'));
  });
});
