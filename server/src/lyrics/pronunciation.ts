// 한글 발음 자동 생성 (05장 §8.4 P3 결정). 오프라인: kuromoji 형태소 분석(IPADIC 사전) → 읽기 → 가나를 한글로.
// 동작 기준: 기존 Windows BangMusic src/pronunciation.cjs와 그 테스트(test/pronunciation.test.cjs).
// 외부 서비스를 부르지 않는다. 사전은 처음 쓸 때 워커 스레드에서 불러오고, 한동안 쓰지 않으면 워커를 끝내 메모리를 돌려준다
// (측정 2026-10-03: 사전을 올리면 RSS +330MB, 워커를 끝내면 대부분 반환 — 1GB 장비에서 상주시키지 않는다).
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { Worker } from 'node:worker_threads';

const require = createRequire(import.meta.url);
/** 마지막 사용 후 이 시간이 지나면 워커(사전)를 내린다 */
const IDLE_MS = 2 * 60_000;

/** 생성 규칙이 바뀌면 올린다. ETag에 들어가 앱이 새 발음을 받는다. */
export const PRONUNCIATION_VERSION = 1;

const kana: Record<string, string> = {};
for (const [japanese, korean] of [
  ['あいうえお', '아 이 우 에 오'], ['かきくけこ', '카 키 쿠 케 코'], ['がぎぐげご', '가 기 구 게 고'],
  ['さしすせそ', '사 시 스 세 소'], ['ざじずぜぞ', '자 지 즈 제 조'], ['たちつてと', '타 치 츠 테 토'],
  ['だぢづでど', '다 지 즈 데 도'], ['なにぬねの', '나 니 누 네 노'], ['はひふへほ', '하 히 후 헤 호'],
  ['ばびぶべぼ', '바 비 부 베 보'], ['ぱぴぷぺぽ', '파 피 푸 페 포'], ['まみむめも', '마 미 무 메 모'],
  ['やゆよ', '야 유 요'], ['らりるれろ', '라 리 루 레 로'], ['わゐゑを', '와 이 에 오'],
  ['ぁぃぅぇぉゃゅょゎゔゕゖ', '아 이 우 에 오 야 유 요 와 부 카 케'],
] as const) {
  const ko = korean.split(' ');
  [...japanese].forEach((ch, i) => { kana[ch] = ko[i]!; });
}
for (const [stem, syllables] of Object.entries({ き: '캬 큐 쿄', ぎ: '갸 규 교', し: '샤 슈 쇼', じ: '쟈 쥬 죠', ち: '챠 츄 쵸', ぢ: '쟈 쥬 죠', に: '냐 뉴 뇨', ひ: '햐 휴 효', び: '뱌 뷰 뵤', ぴ: '퍄 퓨 표', み: '먀 뮤 묘', り: '랴 류 료' })) {
  const ko = syllables.split(' ');
  [...'ゃゅょ'].forEach((ch, i) => { kana[stem + ch] = ko[i]!; });
}
Object.assign(kana, {
  ふぁ: '파', ふぃ: '피', ふぇ: '페', ふぉ: '포', ふゅ: '퓨', てぃ: '티', でぃ: '디', とぅ: '투', どぅ: '두', てゅ: '튜', でゅ: '듀',
  うぃ: '위', うぇ: '웨', うぉ: '워', しぇ: '셰', じぇ: '제', ちぇ: '체', つぁ: '차', つぃ: '치', つぇ: '체', つぉ: '초',
  ゔぁ: '바', ゔぃ: '비', ゔぇ: '베', ゔぉ: '보', ゔゅ: '뷰', くぁ: '콰', くぃ: '퀴', くぇ: '퀘', くぉ: '쿼', ぐぁ: '과',
});

/** 마지막 한글 음절에 받침을 붙인다. 받침을 붙일 수 없으면 대체 글자를 덧붙인다. */
function addFinal(text: string, final: number, fallback: string): string {
  const code = text.charCodeAt(text.length - 1) - 0xac00;
  return code >= 0 && code < 11172 && code % 28 === 0 ? text.slice(0, -1) + String.fromCharCode(code + 0xac00 + final) : text + fallback;
}

const LONG_VOWEL = ['아', '애', '아', '애', '어', '에', '어', '에', '오', '아', '애', '오', '오', '우', '어', '에', '이', '우', '으', '이', '이'];

/** 가나 → 한글 (요음, 촉음 っ→ㅅ받침, 장음 ー→앞 모음 반복, ん→ㄴ받침, 반각 가나) */
export function kanaToHangul(input: string): string {
  const text = String(input)
    .replace(/[ｦ-ﾟ]+/g, (v) => v.normalize('NFKC'))
    .normalize('NFC')
    .replace(/[ァ-ヶ]/g, (c) => String.fromCharCode(c.charCodeAt(0) - 0x60));
  let result = '';
  for (let i = 0; i < text.length; i++) {
    const ch = text[i]!;
    if (ch === 'ん') { result = addFinal(result, 4, '응'); continue; }
    if (ch === 'っ') { result = addFinal(result, 19, '읏'); continue; }
    if (ch === 'ー') {
      const code = result.charCodeAt(result.length - 1) - 0xac00;
      result += code >= 0 && code < 11172 ? LONG_VOWEL[Math.floor(code / 28) % 21] : 'ー';
      continue;
    }
    const pair = text.slice(i, i + 2);
    if (kana[pair]) {
      result += kana[pair];
      i++;
    } else {
      result += kana[ch] ?? ch;
    }
  }
  return result;
}

interface Token {
  surface_form: string;
  pos: string;
  pos_detail_1: string;
  reading?: string;
  pronunciation?: string;
}
// 워커: 문장 목록을 받아 형태소 목록을 돌려준다. 읽기 → 한글 변환은 이 스레드에서 한다.
const WORKER_SOURCE = `
const { parentPort, workerData } = require('node:worker_threads');
const kuromoji = require(workerData.kuromoji);
const pick = (t) => ({ surface_form: t.surface_form, pos: t.pos, pos_detail_1: t.pos_detail_1, reading: t.reading, pronunciation: t.pronunciation });
const ready = new Promise((ok, fail) => kuromoji.builder({ dicPath: workerData.dicPath }).build((e, t) => (e ? fail(e) : ok(t))));
parentPort.on('message', async ({ id, phrases }) => {
  try {
    const t = await ready;
    parentPort.postMessage({ id, tokens: phrases.map((p) => t.tokenize(p).map(pick)) });
  } catch (e) {
    parentPort.postMessage({ id, error: String(e && e.message || e) });
  }
});`;

interface Pending { ok: (v: Token[][]) => void; fail: (e: Error) => void }
let worker: Worker | null = null;
let idleTimer: NodeJS.Timeout | null = null;
let nextId = 0;
const pending = new Map<number, Pending>();

function stopWorker(reason?: Error) {
  const w = worker;
  worker = null;
  if (idleTimer) clearTimeout(idleTimer);
  idleTimer = null;
  for (const p of pending.values()) p.fail(reason ?? new Error('pronunciation worker stopped'));
  pending.clear();
  void w?.terminate();
}

function startWorker(): Worker {
  const pkg = require.resolve('kuromoji/package.json');
  const w = new Worker(WORKER_SOURCE, { eval: true, workerData: { kuromoji: require.resolve('kuromoji'), dicPath: join(dirname(pkg), 'dict') } });
  w.on('message', (m: { id: number; tokens?: Token[][]; error?: string }) => {
    const p = pending.get(m.id);
    if (!p) return;
    pending.delete(m.id);
    if (m.error !== undefined) p.fail(new Error(m.error));
    else p.ok(m.tokens!);
  });
  w.on('error', (e) => { if (worker === w) stopWorker(e); });
  w.on('exit', () => { if (worker === w) stopWorker(); });
  return w;
}

/** 문장들을 형태소로 나눈다 (워커). 마지막 요청 뒤 IDLE_MS가 지나면 워커를 내린다. */
function tokenizeMany(phrases: string[]): Promise<Token[][]> {
  if (phrases.length === 0) return Promise.resolve([]);
  worker ??= startWorker();
  if (idleTimer) clearTimeout(idleTimer);
  idleTimer = null;
  const id = nextId++;
  const w = worker;
  return new Promise<Token[][]>((ok, fail) => {
    pending.set(id, { ok, fail });
    w.ref(); // 응답을 기다리는 동안은 프로세스를 붙잡는다
    w.postMessage({ id, phrases });
  }).finally(() => {
    if (worker === w && pending.size === 0) {
      w.unref(); // 쉬는 워커 때문에 프로세스가 끝나지 못하는 일이 없게
      idleTimer = setTimeout(() => stopWorker(), IDLE_MS);
      idleTimer.unref();
    }
  });
}

/** 테스트·종료용: 사전을 지금 내린다 */
export function unloadPronunciation() {
  stopWorker();
}

const JAPANESE = /[぀-ヿ㐀-鿿]/;

/** 일본어가 있는 줄인지 (발음을 만들 대상) */
export function hasJapanese(text: string): boolean {
  return JAPANESE.test(text);
}

/** 한 줄(여러 줄도 가능)의 한글 발음. 라틴 문자·문장부호·공백·줄바꿈은 그대로, 일본어가 없으면 빈 문자열. */
export async function pronounce(text: string): Promise<string> {
  return (await pronounceTexts([text]))[0]!;
}

const PHRASE = /[぀-ヿ㐀-鿿々〆〇]+/g;

/** 여러 줄을 한 번의 워커 왕복으로 */
async function pronounceTexts(texts: string[]): Promise<string[]> {
  const phrases = [...new Set(texts.filter((t) => JAPANESE.test(t)).flatMap((t) => t.match(PHRASE) ?? []))];
  const tokens = await tokenizeMany(phrases);
  const byPhrase = new Map(phrases.map((p, i) => [p, tokens[i]!]));
  return texts.map((text) => (JAPANESE.test(text) ? text.replace(PHRASE, (phrase) => readPhrase(byPhrase.get(phrase)!)) : ''));
}

function readPhrase(tokens: Token[]): string {
  let out = '';
  for (const token of tokens) {
    const surface = token.surface_form;
    let reading = [token.pronunciation, token.reading].find((v) => v && v !== '*') ?? surface;
    // 조사 は·へ·を는 와·에·오로 읽는다
    if (token.pos === '助詞') reading = ({ は: 'ワ', へ: 'エ', を: 'オ' } as Record<string, string>)[surface] ?? reading;
    const attached = token.pos === '助詞' || token.pos === '助動詞' || token.pos_detail_1 === '接尾';
    if (out && !attached) out += ' ';
    out += kanaToHangul(reading);
  }
  return out;
}

/** 줄 목록의 발음 (같은 문장은 한 번만 계산 — 후렴 반복) */
export async function pronounceLines<T extends { t_ms: number | null; text: string }>(lines: T[]): Promise<{ t_ms: number | null; text: string }[]> {
  const texts = [...new Set(lines.map((l) => l.text))];
  const read = await pronounceTexts(texts);
  const memo = new Map(texts.map((t, i) => [t, read[i]!]));
  return lines.map((l) => ({ t_ms: l.t_ms, text: memo.get(l.text)! }));
}
