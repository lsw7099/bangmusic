// 기존 Windows BangMusic(v0.4.6) 테스트 이식 (L0). 출처: Documents/ChatGPT/음악 플레이어/test/
// 설계 규칙과 다르면 이 테스트가 우선한다 (CLAUDE.md, 03장 §6.3). 시간 단위만 초 → ms로 옮겼다.
import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { decodeText, parseLrc } from '../src/lyrics/lrc.ts';
import { kanaToHangul, pronounce, pronounceLines } from '../src/lyrics/pronunciation.ts';
import { norm } from '../src/norm.ts';

describe('lyrics.test.cjs 이식', () => {
  it('LRC handles multiple timestamps, fractions, metadata, blank instrumental lines and offsets', () => {
    const data = parseLrc('[ar:テスト]\n[offset:500]\n[00:04.2][00:08.250]風\n[00:02.00]光\n[00:06.00]\n[00:04.200]空');
    assert.equal(data.synced, true);
    assert.deepEqual(data.lines, [
      { t_ms: 2500, text: '光' },
      { t_ms: 4700, text: '風\n空' },
      { t_ms: 6500, text: '' },
      { t_ms: 8750, text: '風' },
    ]);
    assert.equal(parseLrc('普通の歌詞\n二行目').synced, false);
  });

  it('UTF-16 LRC decode preserves complete Japanese code points', () => {
    const bytes = Buffer.concat([Buffer.from([255, 254]), Buffer.from('夜の音', 'utf16le')]);
    assert.equal(decodeText(bytes), '夜の音');
  });
});

describe('core.test.cjs 이식: 일본어 검색 정규화', () => {
  it('Japanese search normalizes width, katakana and composed dakuten without editing originals', () => {
    assert.equal(norm('ﾖﾙｼｶ'), norm('よるしか'));
    assert.equal(norm('ガラス'), norm('がらす'));
    assert.equal(norm('ＪＰＯＰ'), 'jpop');
  });
});

describe('pronunciation.test.cjs 이식 (한글 발음 자동 생성)', () => {
  it('kana conversion covers digraphs, small tsu, long vowels, nasal and halfwidth kana', () => {
    for (const [text, expected] of [['きゃきゅきょ', '캬큐쿄'], ['がっこう', '갓코우'], ['スーパー', '스으파아'], ['ミュージック', '뮤우짓쿠'], ['ｶﾞｯﾂﾎﾟｰｽﾞ', '갓츠포오즈'], ['こんにちは', '콘니치하'], ['ファイト！', '파이토！']]) {
      assert.equal(kanaToHangul(text!), expected, text);
    }
  });

  it('offline dictionary reads kanji and pronounced particles without changing Latin text', async () => {
    assert.equal(await pronounce('風が窓をたたいて'), '카제가 마도오 타타이테');
    assert.equal(await pronounce('君は夢を見ている'), '키미와 유메오 미테 이루');
    assert.equal(await pronounce('今日'), '쿄오');
    assert.equal(await pronounce('Hello 世界！\n空へ'), 'Hello 세카이！\n소라에');
    assert.equal(await pronounce('한국어 only 123'), '');
  });

  it('reading rows preserve timestamps, repeats and blank lines', async () => {
    const rows = [{ t_ms: 1000, text: '風' }, { t_ms: 3000, text: '' }, { t_ms: 5000, text: '風' }];
    const result = await pronounceLines(rows);
    assert.deepEqual(result.map((r) => r.t_ms), [1000, 3000, 5000]);
    assert.deepEqual(result.map((r) => r.text), ['카제', '', '카제']);
    assert.equal((rows[0] as { pronunciation?: string }).pronunciation, undefined, '입력을 바꾸지 않는다');
  });
});
