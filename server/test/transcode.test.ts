// P2: 변환 (03장 §4.5~4.6), FN-04(다운로드 도중 원본 교체 → 혼합 없음), FN-06(동시성·대기열 한도),
// SEC-14(손상 오디오 변환 — 그 파일만 실패, 프로세스 생존). L1.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { copyFileSync, existsSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { after, before, describe, it } from 'node:test';
import { scanLibrary } from '../src/scanner/scan.ts';
import { ADMIN, call, expectContract, loginAs, setup, type Env } from './helpers.ts';

let env: Env;
let token: string;
const ANDROID_LIKE = [{ container: 'mp3', codec: 'mp3' }, { container: 'm4a', codec: 'aac' }, { container: 'flac', codec: 'flac' }]; // ALAC·Opus·Vorbis·WAV 없음
const sha = (b: Buffer) => createHash('sha256').update(b).digest('hex');

before(async () => {
  env = await setup({ overrides: { transcodeConcurrency: 1, transcodeQueueMax: 3 } });
  token = (await loginAs(env, ADMIN)).access_token;
});
after(() => env.close());

async function trackId(title: string) {
  const r = (await call(env, { url: `/v1/search?q=${encodeURIComponent(title)}&types=track&limit=50`, token })).json();
  const t = r.tracks.items.find((x: { title: string }) => x.title === title);
  assert.ok(t, title);
  return t.id as string;
}

async function resolve(id: string, body: object) {
  const res = await call(env, { method: 'POST', url: `/v1/tracks/${id}/renditions`, token, body });
  expectContract(res, 'resolveRendition');
  return res;
}

/** 202 → GET /renditions 폴링 → ready */
async function untilReady(rid: string) {
  for (let i = 0; i < 200; i++) {
    const r = await call(env, { url: `/v1/renditions/${rid}`, token });
    expectContract(r, 'getRendition');
    const j = r.json();
    if (j.state !== 'preparing') return j;
    await new Promise((ok) => setTimeout(ok, 100));
  }
  throw new Error('변환이 끝나지 않음');
}

describe('변환 결과', () => {
  it('ALAC → aac_256: 202 → ready, 캐시 파일 = 제공 바이트, AAC-LC/M4A·faststart·태그 없음', async () => {
    const id = await trackId('형식 m4a-alac');
    const res = await resolve(id, { purpose: 'stream', quality: 'original', accept: ANDROID_LIKE });
    assert.equal(res.statusCode, 202);
    assert.equal(res.json().state, 'preparing');
    assert.ok(Number(res.headers['retry-after']) > 0);
    // 준비 중 미디어 요청은 409 rendition_not_ready
    const early = await call(env, { url: `/v1/media/${res.json().id}`, token });
    if (early.statusCode !== 200) {
      expectContract(early, 'getMedia');
      assert.equal(early.json().code, 'rendition_not_ready');
    }
    const r = await untilReady(res.json().id);
    assert.equal(r.state, 'ready');
    assert.equal(r.profile, 'aac_256');
    assert.equal(r.mime, 'audio/mp4');
    assert.ok(Math.abs(r.duration_ms - 30_000) < 200, `길이 ${r.duration_ms}`);
    const body = await call(env, { url: r.media_url });
    expectContract(body, 'getMedia');
    assert.equal(sha(body.rawPayload), r.sha256);
    assert.equal(body.rawPayload.length, r.size_bytes);
    // moov가 mdat보다 앞 (첫 요청만으로 재생·탐색 — 03장 §4.3)
    const buf = body.rawPayload;
    assert.ok(buf.indexOf('moov') > 0 && buf.indexOf('moov') < buf.indexOf('mdat'), 'faststart');
    const tmp = join(env.dir, 'out.m4a');
    writeFileSync(tmp, buf);
    const pr = spawnSync(env.ctx.config.ffprobe, ['-v', 'error', '-show_entries', 'stream=codec_name,profile,channels:format_tags', '-of', 'json', tmp]);
    const info = JSON.parse(pr.stdout.toString());
    assert.equal(info.streams.length, 1, '표지 스트림 없음');
    assert.equal(info.streams[0].codec_name, 'aac');
    assert.equal(info.streams[0].profile, 'LC');
    assert.equal(info.streams[0].channels, 2);
    assert.equal(info.format.tags?.title, undefined, '태그 없음');
    // 같은 요청은 같은 렌디션, 이제 200
    const again = await resolve(id, { purpose: 'download', quality: 'original', accept: ANDROID_LIKE });
    assert.equal(again.statusCode, 200);
    assert.equal(again.json().id, r.id);
    // Range 이어 붙이기
    const a = await call(env, { url: r.media_url, headers: { range: `bytes=0-${Math.floor(r.size_bytes / 2)}` } });
    const b = await call(env, { url: r.media_url, headers: { range: `bytes=${Math.floor(r.size_bytes / 2) + 1}-` } });
    assert.equal(sha(Buffer.concat([a.rawPayload, b.rawPayload])), r.sha256);
  });

  it('손실 원본의 비트레이트가 더 낮으면 원본을 준다 (mp3 192k에 aac_256 요청)', async () => {
    const id = await trackId('형식 mp3-cbr');
    const r = await resolve(id, { purpose: 'stream', quality: 'aac_256', accept: ANDROID_LIKE });
    assert.equal(r.statusCode, 200);
    assert.equal(r.json().profile, 'original');
    const lower = await resolve(id, { purpose: 'stream', quality: 'aac_128', accept: ANDROID_LIKE });
    assert.equal(lower.statusCode, 202, '원본(192k)보다 낮은 품질은 변환');
    assert.equal(lower.json().profile, 'aac_128');
    await untilReady(lower.json().id);
  });

  it('기기가 AAC도 못 받으면 422', async () => {
    const id = await trackId('형식 m4a-alac');
    const r = await resolve(id, { purpose: 'stream', quality: 'original', accept: [{ container: 'mp3', codec: 'mp3' }] });
    assert.equal(r.statusCode, 422);
  });
});

describe('FN-06 동시성·대기열 한도', () => {
  it('대기열이 차면 429 transcode_queue_full, 그동안 서버 응답성 유지', async () => {
    // 동시성 1, 대기열 3. 서로 다른 곡 5개를 변환 요청
    const titles = ['형식 flac-24', '형식 ogg-vorbis', '형식 opus', '형식 wav', '길이 300초'];
    const ids = await Promise.all(titles.map(trackId));
    const results = [];
    for (const id of ids) results.push(await resolve(id, { purpose: 'download', quality: 'aac_128', accept: [{ container: 'm4a', codec: 'aac' }] }));
    const codes = results.map((r) => r.statusCode);
    assert.deepEqual(codes.slice(0, 3), [202, 202, 202]);
    const full = results.find((r) => r.statusCode === 429)!;
    assert.ok(full, `429가 있어야 함: ${codes}`);
    assert.equal(full.json().code, 'transcode_queue_full');
    assert.ok(Number(full.headers['retry-after']) > 0);
    // 변환이 도는 동안 API 응답 시간
    const t0 = performance.now();
    for (let i = 0; i < 20; i++) assert.equal((await call(env, { url: '/v1/tracks?limit=50', token })).statusCode, 200);
    const avg = (performance.now() - t0) / 20;
    assert.ok(avg < 100, `평균 응답 ${avg.toFixed(1)}ms`);
    await env.ctx.jobs.idle();
    for (const r of results.filter((x) => x.statusCode === 202)) assert.equal((await untilReady(r.json().id)).state, 'ready');
  });

  it('stream 요청이 대기 중인 download보다 먼저 처리된다', async () => {
    const a = await trackId('형식 flac-16');
    const b = await trackId('형식 m4a-aac');
    const c = await trackId('夜明けのうた');
    const r1 = (await resolve(a, { purpose: 'download', quality: 'aac_128', accept: [{ container: 'm4a', codec: 'aac' }] })).json();
    const r2 = (await resolve(b, { purpose: 'download', quality: 'aac_128', accept: [{ container: 'm4a', codec: 'aac' }] })).json();
    const r3 = (await resolve(c, { purpose: 'stream', quality: 'aac_128', accept: [{ container: 'm4a', codec: 'aac' }] })).json();
    await env.ctx.jobs.idle();
    const job = (rid: string) => env.ctx.store.get<{ started_at: number }>("SELECT started_at FROM jobs WHERE type = 'transcode' AND ref_id = ? ORDER BY created_at DESC", rid)!.started_at;
    // r1은 이미 실행 중이었을 수 있다. r3(stream)은 r2(download)보다 먼저 시작해야 한다
    assert.ok(job(r3.id) <= job(r2.id), 'stream 우선');
    void r1;
  });
});

describe('FN-04 다운로드 도중 원본 교체', () => {
  it('원본 렌디션: 앞부분 받은 뒤 교체 → 410 → 새 렌디션으로 처음부터, 혼합 없음', async () => {
    const id = await trackId('형식 flac-16');
    const file = join(env.music, 'lib1', '형식 모음 (Formats)', '03-flac-16.flac');
    const r = (await resolve(id, { purpose: 'download', quality: 'original', accept: [{ container: 'flac', codec: 'flac' }] })).json();
    const half = Math.floor(r.size_bytes / 2);
    const first = await call(env, { url: r.media_url, headers: { range: `bytes=0-${half - 1}` } });
    assert.equal(first.statusCode, 206);
    // 다른 FLAC으로 교체 (24비트 파일 내용)
    copyFileSync(join(env.music, 'lib1', '형식 모음 (Formats)', '04-flac-24.flac'), file);
    const rest = await call(env, { url: r.media_url, headers: { range: `bytes=${half}-` } });
    expectContract(rest, 'getMedia');
    assert.equal(rest.statusCode, 410, '옛 바이트와 새 바이트를 섞지 않는다');
    assert.equal(rest.json().code, 'rendition_superseded');
    await env.ctx.jobs.idle(); // 410이 예약한 재스캔
    const r2 = (await resolve(id, { purpose: 'download', quality: 'original', accept: [{ container: 'flac', codec: 'flac' }] })).json();
    assert.notEqual(r2.id, r.id);
    assert.notEqual(r2.media_version, r.media_version);
    const whole = await call(env, { url: r2.media_url });
    assert.equal(sha(whole.rawPayload), r2.sha256);
  });

  it('변환 렌디션도 원본이 바뀌면 410, 다시 결정하면 새 변환본', async () => {
    const id = await trackId('형식 m4a-alac');
    const r = (await resolve(id, { purpose: 'download', quality: 'original', accept: ANDROID_LIKE })).json();
    const ready = r.state === 'ready' ? r : await untilReady(r.id);
    const file = join(env.music, 'lib1', '형식 모음 (Formats)', '06-m4a-alac.m4a');
    const res = spawnSync(env.ctx.config.ffmpeg, ['-v', 'error', '-y', '-f', 'lavfi', '-i', 'sine=f=660:d=20', '-c:a', 'alac', file]);
    assert.equal(res.status, 0);
    await scanLibrary(env.ctx, env.lib1);
    const old = await call(env, { url: ready.media_url, headers: { range: 'bytes=0-99' } });
    assert.equal(old.statusCode, 410);
    const n = await resolve(id, { purpose: 'download', quality: 'original', accept: ANDROID_LIKE });
    assert.equal(n.statusCode, 202);
    const nr = await untilReady(n.json().id);
    assert.ok(Math.abs(nr.duration_ms - 20_000) < 200);
  });
});

describe('SEC-14 손상 오디오 변환', () => {
  it('잘린 FLAC·내용이 깨진 파일: 그 렌디션만 failed, 서버 생존, 다른 변환 정상', async () => {
    const dir = join(env.music, 'lib1', '이상 파일');
    // 오디오 헤더 뒤가 쓰레기인 WAV (ffprobe는 통과, 디코딩은 실패/짧음)
    const wav = readFileSync(join(env.music, 'lib1', '형식 모음 (Formats)', '09-wav.wav')).subarray(0, 44);
    writeFileSync(join(dir, 'header-only.wav'), wav);
    await scanLibrary(env.ctx, env.lib1);
    const truncated = await trackId('잘림 원본');
    const r = await resolve(truncated, { purpose: 'stream', quality: 'original', accept: [{ container: 'm4a', codec: 'aac' }] });
    assert.ok([200, 202].includes(r.statusCode));
    const done = r.json().state === 'ready' ? r.json() : await untilReady(r.json().id);
    assert.ok(['ready', 'failed'].includes(done.state), done.state);
    if (done.state === 'failed') assert.ok(['transcode_failed', 'unsupported_source'].includes(done.error_code));
    assert.equal((await call(env, { url: '/v1/server' })).statusCode, 200);
    const ok = await resolve(await trackId('형식 flac-24'), { purpose: 'stream', quality: 'aac_256', accept: [{ container: 'm4a', codec: 'aac' }] });
    const okr = ok.json().state === 'ready' ? ok.json() : await untilReady(ok.json().id);
    assert.equal(okr.state, 'ready');
  });

  it('변환 실패 시 렌디션 failed + error_code, 재요청 시 다시 시도', async () => {
    const id = await trackId('형식 ogg-vorbis');
    const r = (await resolve(id, { purpose: 'stream', quality: 'aac_256', accept: [{ container: 'm4a', codec: 'aac' }] })).json();
    const ready = r.state === 'ready' ? r : await untilReady(r.id);
    // 원본을 깨뜨리되 크기는 그대로 → DB와 크기가 같아 변환 단계까지 간다. 캐시 렌디션을 지워 재변환 유도
    env.ctx.store.run('DELETE FROM renditions WHERE id = ?', ready.id);
    const file = join(env.music, 'lib1', '형식 모음 (Formats)', '07-ogg-vorbis.ogg');
    const size = statSync(file).size;
    writeFileSync(file, Buffer.alloc(size, 0x41));
    // mtime이 바뀌었지만 스캔 전이므로 DB는 옛 값 → 변환 작업이 원본을 열어 실패
    const f = (await resolve(id, { purpose: 'stream', quality: 'aac_256', accept: [{ container: 'm4a', codec: 'aac' }] })).json();
    const failed = await untilReady(f.id);
    assert.equal(failed.state, 'failed');
    assert.equal(failed.error_code, 'transcode_failed');
    const retry = await resolve(id, { purpose: 'stream', quality: 'aac_256', accept: [{ container: 'm4a', codec: 'aac' }] });
    assert.equal(retry.statusCode, 202, '실패한 변환은 재요청 시 다시 시도');
    assert.equal(retry.json().id, f.id);
    await env.ctx.jobs.idle();
    assert.equal((await call(env, { url: '/v1/server' })).statusCode, 200);
    const tmpLeft = existsSync(join(env.ctx.config.cacheDir, 'tmp')) ? readdirSync(join(env.ctx.config.cacheDir, 'tmp')) : [];
    assert.deepEqual(tmpLeft, [], '실패한 임시 파일이 남지 않는다');
  });
});

describe('캐시 한도', () => {
  it('한도를 넘으면 오래 안 쓴 변환본 파일부터 지우고, 그 렌디션은 410 → 다시 결정하면 재변환', async () => {
    const files = readdirSync(join(env.ctx.config.cacheDir, 'renditions'));
    assert.ok(files.length >= 3);
    const before = env.ctx.store.all<{ id: string }>("SELECT id FROM renditions WHERE cache_ref IS NOT NULL AND state = 'ready' ORDER BY COALESCE(last_access_at, created_at)");
    env.ctx.config.cacheMaxBytes = 1; // 다음 변환에서 정리가 일어나게
    const id = await trackId('형식 mp3-vbr');
    const r = (await resolve(id, { purpose: 'stream', quality: 'aac_128', accept: [{ container: 'm4a', codec: 'aac' }] })).json();
    await untilReady(r.id);
    const left = readdirSync(join(env.ctx.config.cacheDir, 'renditions'));
    assert.ok(left.length < files.length + 1, `정리됨: ${files.length} → ${left.length}`);
    const evicted = before.find((b) => !left.includes(`${b.id}.m4a`))!;
    assert.ok(evicted, '정리된 렌디션이 있다');
    const g = await call(env, { url: `/v1/renditions/${evicted.id}`, token });
    expectContract(g, 'getRendition');
    assert.equal(g.statusCode, 410, '정리된 변환본은 410 → 앱이 다시 결정');
    assert.equal(g.json().code, 'rendition_superseded');
    env.ctx.config.cacheMaxBytes = 10 * 1024 ** 3;
  });
});

