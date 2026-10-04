// L0 단위 테스트: 정규화, Range 해석, ID, 마이그레이션 규칙, 속도 제한.
import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { describe, it } from 'node:test';
import { FailureLimiter } from '../src/auth/ratelimit.ts';
import { loadMigrations, migrate, MigrationError, Store } from '../src/db/store.ts';
import { isId, mediaVersion, newId, ulid } from '../src/ids.ts';
import { redactUrl } from '../src/log.ts';
import { pronounceLines, unloadPronunciation } from '../src/lyrics/pronunciation.ts';
import { parseRange } from '../src/media/media.ts';
import { norm, sortKey } from '../src/norm.ts';

describe('norm (01장 §4.6)', () => {
  it('가타카나·반각·히라가나 통일', () => {
    assert.equal(norm('ｶﾞｰﾙｽﾞ'), 'がーるず');
    assert.equal(norm('ガールズ'), 'がーるず');
    assert.equal(norm('がーるず'), 'がーるず');
  });
  it('전각 영숫자·대소문자·공백', () => {
    assert.equal(norm('ＺＥＮＫＡＫＵ  Abc\t１２'), 'zenkaku abc 12');
  });
  it('한자·한글은 그대로', () => {
    assert.equal(norm('夜明けのうた'), '夜明けのうた');
    assert.equal(norm('새벽 공기'), '새벽 공기');
  });
  it('정렬 키는 정렬 태그 우선, 한자 읽기를 추측하지 않음', () => {
    assert.equal(sortKey('夜明けのうた', 'ヨアケノウタ'), 'よあけのうた');
    assert.equal(sortKey('夜明けのうた', null), '夜明けのうた');
    assert.equal(sortKey('X', '  '), 'x');
  });
});

describe('parseRange (03장 §4.2)', () => {
  const size = 1000;
  it('정상', () => {
    assert.deepEqual(parseRange('bytes=0-99', size), { start: 0, end: 99 });
    assert.deepEqual(parseRange('bytes=900-', size), { start: 900, end: 999 });
    assert.deepEqual(parseRange('bytes=-100', size), { start: 900, end: 999 });
    assert.deepEqual(parseRange('bytes=-5000', size), { start: 0, end: 999 });
    assert.deepEqual(parseRange('bytes=990-5000', size), { start: 990, end: 999 });
  });
  it('전체로 처리 (null)', () => {
    for (const h of [undefined, '', 'bytes=0-1,5-9', 'items=0-1', 'bytes=-', 'bytes=a-b']) assert.equal(parseRange(h, size), null, String(h));
  });
  it('범위 밖', () => {
    for (const h of ['bytes=1000-', 'bytes=1000-1001', 'bytes=-0', 'bytes=10-5']) assert.equal(parseRange(h, size), 'unsatisfiable', h);
  });
});

describe('ID (01장 §4.1)', () => {
  it('접두어 + ULID, 시간순', () => {
    const a = ulid(1_000_000);
    const b = ulid(2_000_000);
    assert.equal(a.length, 26);
    assert.ok(a.slice(0, 10) < b.slice(0, 10));
    const id = newId('track');
    assert.ok(isId('track', id));
    assert.ok(!isId('album', id));
    for (const bad of ['trk_../../etc', 'trk_', 'trk_01JB2P3C5E7G9J1L3N5Q7S9U1W\0', 'TRK_01JB2P3C5E7G9J1L3N5Q7S9U1W', 'trk_01JB2P3C5E7G9J1L3N5Q7S9U1I']) assert.ok(!isId('track', bad), bad);
  });
  it('미디어 버전은 16자, 내용 해시가 같으면 같다', () => {
    const v = mediaVersion('a'.repeat(64));
    assert.match(v, /^[0-9a-z]{16}$/);
    assert.equal(v, mediaVersion('a'.repeat(64)));
    assert.notEqual(v, mediaVersion('b'.repeat(64)));
  });
});

describe('마이그레이션 (01장 §5.1)', () => {
  function tmp() {
    const dir = mkdtempSync(join(tmpdir(), 'bm-mig-'));
    return { dir, cleanup: () => rmSync(dir, { recursive: true, force: true }) };
  }
  it('새 DB에 적용, 다시 실행하면 아무것도 하지 않음', () => {
    const { dir, cleanup } = tmp();
    const s = new Store(join(dir, 'db.sqlite'));
    assert.deepEqual(migrate(s), [1, 2]);
    assert.deepEqual(migrate(s), []);
    s.close();
    cleanup();
  });
  it('적용된 파일의 체크섬이 다르면 기동 거부', () => {
    const { dir, cleanup } = tmp();
    const s = new Store(join(dir, 'db.sqlite'));
    migrate(s);
    const changed = loadMigrations().map((m) => ({ ...m, checksum: 'x' }));
    assert.throws(() => migrate(s, { migrations: changed }), MigrationError);
    s.close();
    cleanup();
  });
  it('DB가 실행 파일보다 새 버전이면 기동 거부', () => {
    const { dir, cleanup } = tmp();
    const s = new Store(join(dir, 'db.sqlite'));
    migrate(s);
    s.run("INSERT INTO schema_migrations (version, name, applied_at, checksum) VALUES (99, '0099_future.sql', 0, 'x')");
    assert.throws(() => migrate(s), /새롭다/);
    s.close();
    cleanup();
  });
  it('적용할 것이 있으면 먼저 스냅샷, 실패하면 롤백(부분 적용 없음)', () => {
    const { dir, cleanup } = tmp();
    const migDir = join(dir, 'm');
    mkdirSync(migDir);
    writeFileSync(join(migDir, '0001_a.sql'), 'CREATE TABLE a (x INTEGER);');
    const s = new Store(join(dir, 'db.sqlite'));
    migrate(s, { migrations: loadMigrations(migDir) });
    writeFileSync(join(migDir, '0002_b.sql'), 'CREATE TABLE b (x INTEGER); CREATE TABLE broken (;');
    const snaps: string[] = [];
    assert.throws(() => migrate(s, { migrations: loadMigrations(migDir), snapshot: (r) => snaps.push(r) }));
    assert.deepEqual(snaps, ['pre-migrate-2']);
    assert.equal(s.get("SELECT name FROM sqlite_master WHERE name = 'b'"), undefined, '롤백됨');
    assert.equal(s.all('SELECT version FROM schema_migrations').length, 1);
    s.close();
    cleanup();
  });
});

describe('기타', () => {
  it('로그 URL에서 mt 가리기', () => {
    assert.equal(redactUrl('/v1/media/rnd_1?mt=abc.def&x=1'), '/v1/media/rnd_1?mt=<redacted>&x=1');
    assert.equal(redactUrl('/v1/artwork/img_1?size=96&mt=abc'), '/v1/artwork/img_1?size=96&mt=<redacted>');
  });
  it('실패 제한: 한도 도달 시 남은 초', () => {
    const l = new FailureLimiter(3, 60_000);
    const t = 1_000_000;
    l.fail(['u:a'], t);
    l.fail(['u:a'], t + 1000);
    assert.equal(l.retryAfter(['u:a'], t + 2000), 0);
    l.fail(['u:a'], t + 2000);
    assert.equal(l.retryAfter(['u:a'], t + 2000), 58);
    assert.equal(l.retryAfter(['u:a'], t + 61_000), 0, '창이 지나면 풀림');
  });
});

describe('한글 발음 워커 (05장 §8.4)', () => {
  it('사전을 내린 뒤에도 다시 불러와 같은 결과, 동시 요청도 각각 응답', async () => {
    const lines = [{ t_ms: 0, text: '空へ' }, { t_ms: 1, text: 'Hello' }];
    const first = await pronounceLines(lines);
    unloadPronunciation();
    const [a, b] = await Promise.all([pronounceLines(lines), pronounceLines([{ t_ms: null, text: '今日' }])]);
    assert.deepEqual(a, first);
    assert.deepEqual(first.map((l) => l.text), ['소라에', '']);
    assert.deepEqual(b, [{ t_ms: null, text: '쿄오' }]);
  });
});
