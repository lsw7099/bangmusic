// P2 수용 기준: 02장 §6 오류 코드 표의 각 코드를 발생시키는 테스트. 모두 계약(openapi.yaml)과 대조한다.
// 표의 모든 코드를 CODES에 적고, 마지막에 빠진 코드가 없는지 확인한다.
import assert from 'node:assert/strict';
import { copyFileSync, renameSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { after, before, describe, it } from 'node:test';
import { issueTicket } from '../src/auth/tickets.ts';
import { principalForSession } from '../src/auth/sessions.ts';
import { newId } from '../src/ids.ts';
import { ADMIN, call, device, expectContract, loginAs, MEMBER, setup, type Env } from './helpers.ts';

/** 02장 §6 표 전체 (rendition error_code 포함) */
const CODES = [
  'validation_failed', 'invalid_credentials', 'access_expired', 'access_invalid', 'refresh_expired', 'session_revoked', 'account_disabled',
  'ticket_expired', 'ticket_invalid', 'forbidden', 'not_found', 'media_missing', 'rendition_not_ready', 'username_taken', 'last_admin',
  'rendition_superseded', 'sync_token_expired', 'version_conflict', 'payload_too_large', 'unsupported_media_type', 'range_not_satisfiable',
  'no_playable_format', 'client_too_old', 'precondition_required', 'rate_limited', 'transcode_queue_full', 'internal_error',
  'storage_unavailable', 'maintenance', 'setup_required', 'transcode_failed', 'unsupported_source',
];
const seen = new Set<string>();

let env: Env;
let s: Awaited<ReturnType<typeof loginAs>>;
let trackId = '';
let flacId = '';

before(async () => {
  env = await setup({ overrides: { transcodeQueueMax: 1, transcodeConcurrency: 1 } });
  s = await loginAs(env, ADMIN);
  const items = (await call(env, { url: '/v1/tracks?limit=200', token: s.access_token })).json().items as Array<{ id: string; title: string }>;
  trackId = items.find((t) => t.title === '형식 mp3-cbr')!.id;
  flacId = items.find((t) => t.title === '형식 flac-16')!.id;
});
after(() => env.close());

async function expectCode(op: string, r: Parameters<typeof call>[1], status: number, code: string): Promise<void> {
  const res = await call(env, r);
  expectContract(res, op);
  assert.equal(res.statusCode, status, `${code}: ${res.body.slice(0, 200)}`);
  assert.equal(res.json().code, code);
  seen.add(code);
}

const mp3Rendition = async () => (await call(env, { method: 'POST', url: `/v1/tracks/${trackId}/renditions`, token: s.access_token, body: { purpose: 'stream', quality: 'original', accept: [{ container: 'mp3', codec: 'mp3' }] } })).json();

describe('02장 §6 오류 코드', () => {
  it('400 validation_failed', () => expectCode('login', { method: 'POST', url: '/v1/auth/login', body: {} }, 400, 'validation_failed'));
  it('401 invalid_credentials', () => expectCode('login', { method: 'POST', url: '/v1/auth/login', body: { ...ADMIN, password: 'nope-nope-nope', device: device() } }, 401, 'invalid_credentials'));
  it('401 access_expired', async () => {
    const t = await loginAs(env, ADMIN);
    env.ctx.store.run('UPDATE sessions SET access_expires_at = 0 WHERE id = ?', t.session_id);
    await expectCode('getMe', { url: '/v1/me', token: t.access_token }, 401, 'access_expired');
  });
  it('401 access_invalid', () => expectCode('getMe', { url: '/v1/me', token: 'bma_x' }, 401, 'access_invalid'));
  it('401 refresh_expired', () => expectCode('refreshToken', { method: 'POST', url: '/v1/auth/refresh', body: { refresh_token: 'bmr_unknown' } }, 401, 'refresh_expired'));
  it('401 session_revoked', async () => {
    const t = await loginAs(env, ADMIN);
    await call(env, { method: 'POST', url: '/v1/auth/logout', token: t.access_token });
    await expectCode('getMe', { url: '/v1/me', token: t.access_token }, 401, 'session_revoked');
  });
  it('401 account_disabled (세션은 살아 있는데 계정이 막힘)', async () => {
    const t = await loginAs(env, MEMBER);
    env.ctx.store.run("UPDATE users SET status = 'disabled' WHERE id = ?", t.user.id);
    await expectCode('getMe', { url: '/v1/me', token: t.access_token }, 401, 'account_disabled');
    env.ctx.store.run("UPDATE users SET status = 'active' WHERE id = ?", t.user.id);
  });
  it('401 ticket_expired', async () => {
    const r = await mp3Rendition();
    const old = issueTicket(env.ctx, principalForSession(env.ctx, s.session_id), r.id, Date.now() - env.ctx.config.ticketTtlMs - 1);
    await expectCode('getMedia', { url: `/v1/media/${r.id}?mt=${old.ticket}` }, 401, 'ticket_expired');
  });
  it('401 ticket_invalid', async () => {
    const r = await mp3Rendition();
    await expectCode('getMedia', { url: `/v1/media/${r.id}?mt=a.b` }, 401, 'ticket_invalid');
  });
  it('403 forbidden', async () => {
    const m = await loginAs(env, MEMBER);
    await expectCode('adminListUsers', { url: '/v1/admin/users', token: m.access_token }, 403, 'forbidden');
  });
  it('404 not_found', () => expectCode('getTrack', { url: `/v1/tracks/${newId('track')}`, token: s.access_token }, 404, 'not_found'));
  it('404 media_missing', async () => {
    env.ctx.store.run("UPDATE tracks SET state = 'missing' WHERE id = ?", flacId);
    await expectCode('resolveRendition', { method: 'POST', url: `/v1/tracks/${flacId}/renditions`, token: s.access_token, body: { purpose: 'stream', quality: 'original', accept: [{ container: 'flac', codec: 'flac' }] } }, 404, 'media_missing');
    env.ctx.store.run("UPDATE tracks SET state = 'available' WHERE id = ?", flacId);
  });
  it('409 rendition_not_ready', async () => {
    const rid = newId('rendition');
    const v = env.ctx.store.get<{ media_version: string }>('SELECT media_version FROM tracks WHERE id = ?', flacId)!.media_version;
    env.ctx.store.run("INSERT INTO renditions (id, track_id, media_version, profile, state, created_at) VALUES (?, ?, ?, 'aac_128', 'preparing', ?)", rid, flacId, v, Date.now());
    await expectCode('getMedia', { url: `/v1/media/${rid}`, token: s.access_token }, 409, 'rendition_not_ready');
    env.ctx.store.run('DELETE FROM renditions WHERE id = ?', rid);
  });
  it('409 username_taken', () => expectCode('adminCreateUser', { method: 'POST', url: '/v1/admin/users', token: s.access_token, body: { username: ADMIN.username, password: 'xxxxxxxxxxxx', role: 'member' } }, 409, 'username_taken'));
  it('409 last_admin', () => expectCode('adminUpdateUser', { method: 'PATCH', url: `/v1/admin/users/${s.user.id}`, token: s.access_token, body: { status: 'disabled' } }, 409, 'last_admin'));
  it('410 rendition_superseded', async () => {
    const r = await mp3Rendition();
    env.ctx.store.run("UPDATE tracks SET media_version = 'changedversion00' WHERE id = ?", trackId);
    await expectCode('getRendition', { url: `/v1/renditions/${r.id}`, token: s.access_token }, 410, 'rendition_superseded');
    env.ctx.store.run('UPDATE tracks SET media_version = ? WHERE id = ?', r.media_version, trackId);
  });
  it('410 sync_token_expired', async () => {
    env.ctx.store.run('UPDATE server_meta SET tombstone_horizon_seq = 100');
    await expectCode('getChanges', { url: '/v1/changes?since=5', token: s.access_token }, 410, 'sync_token_expired');
    env.ctx.store.run('UPDATE server_meta SET tombstone_horizon_seq = 0');
  });
  it('412 version_conflict · 428 precondition_required', async () => {
    const pl = (await call(env, { method: 'POST', url: '/v1/playlists', token: s.access_token, body: { name: 'x' } })).json();
    await expectCode('updatePlaylist', { method: 'PATCH', url: `/v1/playlists/${pl.id}`, token: s.access_token, headers: { 'if-match': '"42"' }, body: { name: 'y' } }, 412, 'version_conflict');
    await expectCode('updatePlaylist', { method: 'PATCH', url: `/v1/playlists/${pl.id}`, token: s.access_token, body: { name: 'y' } }, 428, 'precondition_required');
  });
  it('413 payload_too_large · 415 unsupported_media_type', async () => {
    const pl = (await call(env, { method: 'POST', url: '/v1/playlists', token: s.access_token, body: { name: 'cover' } }));
    const h = { 'if-match': String(pl.headers.etag) };
    await expectCode('putPlaylistCover', { method: 'PUT', url: `/v1/playlists/${pl.json().id}/cover`, token: s.access_token, headers: { ...h, 'content-type': 'image/png' }, body: Buffer.alloc(6 * 1024 * 1024) }, 413, 'payload_too_large');
    await expectCode('putPlaylistCover', { method: 'PUT', url: `/v1/playlists/${pl.json().id}/cover`, token: s.access_token, headers: { ...h, 'content-type': 'image/bmp' }, body: Buffer.from('BM') }, 415, 'unsupported_media_type');
  });
  it('416 range_not_satisfiable', async () => {
    const r = await mp3Rendition();
    await expectCode('getMedia', { url: r.media_url, headers: { range: 'bytes=999999999-' } }, 416, 'range_not_satisfiable');
  });
  it('422 no_playable_format', () => expectCode('resolveRendition', { method: 'POST', url: `/v1/tracks/${flacId}/renditions`, token: s.access_token, body: { purpose: 'stream', quality: 'original', accept: [{ container: 'mp3', codec: 'mp3' }] } }, 422, 'no_playable_format'));
  it('426 client_too_old', async () => {
    env.ctx.config.minClientApiMinor = 5;
    await expectCode('getMe', { url: '/v1/me', token: s.access_token, headers: { 'bangmusic-client': 'android/1.0.0 api=1.0' } }, 426, 'client_too_old');
    env.ctx.config.minClientApiMinor = 0;
  });
  it('429 rate_limited', async () => {
    let res;
    for (let i = 0; i < 6; i++) res = await call(env, { method: 'POST', url: '/v1/auth/login', body: { username: 'brute', password: `x${i}`, device: device() } });
    expectContract(res!, 'login');
    assert.equal(res!.json().code, 'rate_limited');
    seen.add('rate_limited');
    env.ctx.limiter.reset('ip:127.0.0.1');
    env.ctx.limiter.reset('u:brute');
  });
  it('429 transcode_queue_full', async () => {
    // 대기열 한도 1: 변환 2개를 연달아
    const ids = (await call(env, { url: '/v1/tracks?limit=200', token: s.access_token })).json().items
      .filter((t: { title: string }) => ['형식 wav', '형식 flac-24', '길이 300초'].includes(t.title)).map((t: { id: string }) => t.id);
    let last;
    for (const id of ids) last = await call(env, { method: 'POST', url: `/v1/tracks/${id}/renditions`, token: s.access_token, body: { purpose: 'stream', quality: 'aac_128', accept: [{ container: 'm4a', codec: 'aac' }] } });
    expectContract(last!, 'resolveRendition');
    assert.equal(last!.json().code, 'transcode_queue_full');
    seen.add('transcode_queue_full');
    await env.ctx.jobs.idle();
  });
  it('500 internal_error (경로·스택 없이)', async () => {
    const orig = env.ctx.store.all.bind(env.ctx.store);
    env.ctx.store.all = (() => { throw new Error('C:\\secret\\path boom'); }) as typeof env.ctx.store.all;
    try {
      const res = await call(env, { url: '/v1/tracks', token: s.access_token });
      assert.equal(res.statusCode, 500);
      assert.equal(res.json().code, 'internal_error');
      assert.doesNotMatch(res.body, /secret|boom|at /);
      seen.add('internal_error');
    } finally {
      env.ctx.store.all = orig;
    }
  });
  it('503 storage_unavailable', async () => {
    const root = join(env.music, 'lib1');
    renameSync(root, `${root}-away`);
    try {
      const r = await mp3Rendition();
      await expectCode('getMedia', { url: r.media_url }, 503, 'storage_unavailable');
    } finally {
      renameSync(`${root}-away`, root);
    }
  });
  it('503 setup_required', async () => {
    env.ctx.store.run("UPDATE users SET status = 'disabled' WHERE role = 'admin'");
    await expectCode('login', { method: 'POST', url: '/v1/auth/login', body: { ...ADMIN, device: device() } }, 503, 'setup_required');
    env.ctx.store.run("UPDATE users SET status = 'active' WHERE role = 'admin'");
  });
  it('503 maintenance', async () => {
    writeFileSync(join(env.ctx.config.dataDir, 'MAINTENANCE'), '');
    await new Promise((ok) => setTimeout(ok, 2100));
    await expectCode('getMe', { url: '/v1/me', token: s.access_token }, 503, 'maintenance');
    rmSync(join(env.ctx.config.dataDir, 'MAINTENANCE'));
    await new Promise((ok) => setTimeout(ok, 2100));
  });
  it('렌디션 error_code: transcode_failed · unsupported_source', async () => {
    const v = env.ctx.store.get<{ media_version: string }>('SELECT media_version FROM tracks WHERE id = ?', flacId)!.media_version;
    for (const [profile, expected] of [['aac_bogus', 'unsupported_source']] as const) {
      const rid = newId('rendition');
      env.ctx.store.run("INSERT INTO renditions (id, track_id, media_version, profile, state, created_at) VALUES (?, ?, ?, ?, 'preparing', ?)", rid, flacId, v, profile, Date.now());
      env.ctx.jobs.enqueue('transcode', rid);
      await env.ctx.jobs.idle();
      const r = await call(env, { url: `/v1/renditions/${rid}`, token: s.access_token });
      expectContract(r, 'getRendition');
      assert.equal(r.json().state, 'failed');
      assert.equal(r.json().error_code, expected);
      seen.add(expected);
    }
    // transcode_failed: 변환 도중 FFmpeg 실패 (원본 내용을 같은 크기의 쓰레기로)
    const file = join(env.music, 'lib1', '형식 모음 (Formats)', '03-flac-16.flac');
    copyFileSync(file, `${file}.bak`);
    writeFileSync(file, Buffer.alloc(statSync(file).size, 0x55));
    try {
      const res = await call(env, { method: 'POST', url: `/v1/tracks/${flacId}/renditions`, token: s.access_token, body: { purpose: 'stream', quality: 'aac_128', accept: [{ container: 'm4a', codec: 'aac' }] } });
      await env.ctx.jobs.idle();
      const r = (await call(env, { url: `/v1/renditions/${res.json().id}`, token: s.access_token })).json();
      assert.equal(r.error_code, 'transcode_failed');
      seen.add('transcode_failed');
    } finally {
      copyFileSync(`${file}.bak`, file);
    }
  });

  it('표의 모든 코드를 발생시켰다', () => {
    const missing = CODES.filter((c) => !seen.has(c));
    assert.deepEqual(missing, []);
  });
});
