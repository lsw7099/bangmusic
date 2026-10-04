// P1 수용 기준: FN-01(HEAD 정확성), FN-02(임의 Range 100회 이어 붙이기 = 원본 SHA-256). L1.
// 03장 §4.2의 Range 규칙 전부와, 원본 변경 시 410도 함께 확인한다.
import assert from 'node:assert/strict';
import { createHash, randomInt } from 'node:crypto';
import { appendFileSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { after, before, describe, it } from 'node:test';
import { ADMIN, call, expectContract, FIXTURES, loginAs, setup, type Env } from './helpers.ts';

let env: Env;
let token: string;
const ACCEPT = [
  { container: 'flac', codec: 'flac' }, { container: 'mp3', codec: 'mp3' }, { container: 'm4a', codec: 'aac' }, { container: 'm4a', codec: 'alac' },
  { container: 'ogg', codec: 'vorbis' }, { container: 'ogg', codec: 'opus' }, { container: 'wav', codec: 'pcm_s16le' },
];

before(async () => {
  env = await setup();
  token = (await loginAs(env, ADMIN)).access_token;
});
after(() => env.close());

interface Manifest { files: Array<{ path: string; sha256: string; size: number; codec?: string; purpose: string[] }> }
const manifest = (): Manifest => JSON.parse(readFileSync(join(FIXTURES, 'manifest.json'), 'utf8'));

async function renditionFor(title: string) {
  const t = (await call(env, { url: `/v1/search?q=${encodeURIComponent(title)}&types=track`, token })).json().tracks.items.find((x: { title: string }) => x.title === title);
  assert.ok(t, title);
  const r = await call(env, { method: 'POST', url: `/v1/tracks/${t.id}/renditions`, token, body: { purpose: 'download', quality: 'original', accept: ACCEPT } });
  assert.equal(r.statusCode, 200, r.body);
  return { track: t, r: r.json() };
}

const sha = (b: Buffer) => createHash('sha256').update(b).digest('hex');

describe('FN-01 HEAD 응답이 실제 바이트와 일치', () => {
  const titles = ['형식 mp3-cbr', '형식 mp3-vbr', '형식 flac-16', '형식 flac-24', '형식 m4a-aac', '형식 m4a-alac', '형식 ogg-vorbis', '형식 opus', '형식 wav', '길이 300초', '삑 세기 (청취 확인용)'];
  for (const title of titles) {
    it(title, async () => {
      const { r } = await renditionFor(title);
      const head = await call(env, { method: 'HEAD', url: r.media_url });
      expectContract(head, 'headMedia');
      const full = await call(env, { url: r.media_url });
      expectContract(full, 'getMedia');
      assert.equal(full.statusCode, 200);
      assert.equal(head.body.length, 0, 'HEAD 본문 없음');
      assert.equal(Number(head.headers['content-length']), full.rawPayload.length);
      assert.equal(Number(head.headers['content-length']), r.size_bytes);
      assert.equal(head.headers['content-type'], r.mime);
      assert.equal(head.headers.etag, r.etag);
      assert.equal(head.headers['accept-ranges'], 'bytes');
      assert.equal(Number(head.headers['x-content-duration-ms']), r.duration_ms);
      assert.equal(sha(full.rawPayload), r.sha256, '렌디션 sha256 = 실제 바이트');
      // 합성 음원 세트의 기록과도 일치 (원본 그대로 제공)
      const m = manifest().files.find((f) => f.sha256 === r.sha256);
      assert.ok(m, 'manifest에 같은 해시의 원본이 있다');
    });
  }
});

describe('FN-02 임의 Range 100회를 이어 붙이면 원본과 같다', () => {
  it('5분 FLAC', async () => {
    const { r } = await renditionFor('길이 300초');
    const size: number = r.size_bytes;
    // 0..size를 무작위 지점 99개로 나눠 100조각 → 무작위 순서로 요청 → 위치대로 이어 붙이기
    const cuts = new Set<number>();
    while (cuts.size < 99) cuts.add(randomInt(1, size));
    const bounds = [0, ...[...cuts].sort((a, b) => a - b), size];
    const pieces = bounds.slice(0, -1).map((start, i) => ({ start, end: bounds[i + 1]! - 1 }));
    const order = pieces.map((_, i) => i).sort(() => Math.random() - 0.5);
    const got = new Array<Buffer>(pieces.length);
    for (const i of order) {
      const p = pieces[i]!;
      const res = await call(env, { url: r.media_url, headers: { range: `bytes=${p.start}-${p.end}` } });
      assert.equal(res.statusCode, 206);
      assert.equal(res.headers['content-range'], `bytes ${p.start}-${p.end}/${size}`);
      assert.equal(Number(res.headers['content-length']), p.end - p.start + 1);
      got[i] = res.rawPayload;
    }
    const joined = Buffer.concat(got);
    assert.equal(joined.length, size);
    assert.equal(sha(joined), r.sha256);
  });
});

describe('Range 규칙 (03장 §4.2)', () => {
  it('a-, -n, 끝 넘는 b, 여러 범위, 형식 오류, If-Range, 416', async () => {
    const { r } = await renditionFor('형식 mp3-cbr');
    const size: number = r.size_bytes;
    const full = (await call(env, { url: r.media_url })).rawPayload;
    const get = (headers: Record<string, string>) => call(env, { url: r.media_url, headers });

    const open = await get({ range: `bytes=${size - 10}-` });
    assert.equal(open.statusCode, 206);
    assert.deepEqual(open.rawPayload, full.subarray(size - 10));
    const suffix = await get({ range: 'bytes=-5' });
    assert.equal(suffix.headers['content-range'], `bytes ${size - 5}-${size - 1}/${size}`);
    assert.deepEqual(suffix.rawPayload, full.subarray(size - 5));
    const over = await get({ range: `bytes=0-${size * 2}` });
    assert.equal(over.statusCode, 206);
    assert.equal(over.rawPayload.length, size);
    const multi = await get({ range: 'bytes=0-1,5-9' });
    assert.equal(multi.statusCode, 200, '다중 범위는 전체');
    assert.equal(multi.rawPayload.length, size);
    assert.equal((await get({ range: 'items=0-1' })).statusCode, 200, '형식 오류는 무시');
    const ifRangeBad = await get({ range: 'bytes=0-9', 'if-range': '"other"' });
    assert.equal(ifRangeBad.statusCode, 200);
    const ifRangeOk = await get({ range: 'bytes=0-9', 'if-range': r.etag });
    assert.equal(ifRangeOk.statusCode, 206);
    for (const range of [`bytes=${size}-`, `bytes=${size + 100}-${size + 200}`, 'bytes=-0', 'bytes=10-5']) {
      const res = await get({ range });
      expectContract(res, 'getMedia');
      assert.equal(res.statusCode, 416, range);
      assert.equal(res.headers['content-range'], `bytes */${size}`);
      assert.equal(res.json().code, 'range_not_satisfiable');
      assert.equal(res.headers['cache-control'], undefined, '오류 응답은 불변 캐시 대상이 아님');
    }
  });

  it('Bearer 헤더로도 받을 수 있다', async () => {
    const { r } = await renditionFor('형식 wav');
    const res = await call(env, { url: `/v1/media/${r.id}`, token, headers: { range: 'bytes=0-3' } });
    assert.equal(res.statusCode, 206);
    assert.equal(res.rawPayload.toString('latin1'), 'RIFF');
  });
});

describe('원본이 바뀌면 옛 렌디션은 410 (혼합 방지)', () => {
  it('파일 변경 → 미디어 410 + 재스캔 → 새 media_version, 새 렌디션', async () => {
    const { track, r } = await renditionFor('형식 opus');
    const file = join(env.music, 'lib1', '형식 모음 (Formats)', '08-opus.opus');
    appendFileSync(file, Buffer.alloc(16)); // 크기가 바뀐다
    const res = await call(env, { url: r.media_url, headers: { range: 'bytes=0-99' } });
    expectContract(res, 'getMedia');
    assert.equal(res.statusCode, 410);
    assert.equal(res.json().code, 'rendition_superseded');
    await env.ctx.jobs.idle(); // 410이 예약한 재스캔
    const after = (await call(env, { url: `/v1/tracks/${track.id}`, token })).json();
    assert.equal(after.id, track.id, '곡 ID 유지');
    assert.notEqual(after.media_version, track.media_version);
    const old = await call(env, { url: `/v1/renditions/${r.id}`, token });
    expectContract(old, 'getRendition');
    assert.equal(old.statusCode, 410);
    const { r: r2 } = await renditionFor('형식 opus');
    assert.notEqual(r2.id, r.id);
    assert.equal((await call(env, { method: 'HEAD', url: r2.media_url })).statusCode, 200);
  });
});
