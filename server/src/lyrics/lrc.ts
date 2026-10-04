// LRC/일반 텍스트 가사 해석. 깨진 파일에도 예외를 던지지 않는다(파서 내구성, 05장 §10.2 "깨진 LRC").
// 동작 기준: 기존 Windows BangMusic의 src/ui/lyrics-core.js (parseLrc)와 그 테스트(test/lyrics.test.cjs).
// 설계의 제안 규칙과 다른 점은 기존 테스트를 따른다(CLAUDE.md, 03장 §6.3):
// - [offset:N]은 시각에 N ms를 **더한다** (LRC 관례와 반대지만 기존 앱 동작)
// - 같은 시각의 줄은 하나로 합친다 (문장이 다르면 줄바꿈으로 잇는다)
// - 시간 표시는 줄 어디에 있어도 인식하고, 단어 시간 <mm:ss.xx>는 지운다
// - 시간 없는 가사는 빈 줄과 메타데이터 줄([ar:] 등)을 버린다

export interface LyricLine {
  t_ms: number | null;
  text: string;
}

export interface ParsedLyrics {
  synced: boolean;
  lines: LyricLine[];
}

const TIME = /\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]/g;
const WORD_TIME = /<\d{1,3}:\d{2}(?:[.:]\d{1,3})?>/g;
const META_LINE = /^\[(ar|al|ti|by|offset|length|re|ve):/i;

/** 바이트 → 문자열. UTF-16(BOM) 지원, BOM 제거, 잘못된 UTF-8은 대체 문자로 (예외 없음) */
export function decodeText(bytes: Uint8Array): string {
  let text: string;
  if (bytes.length >= 2 && bytes[0] === 0xff && bytes[1] === 0xfe) text = new TextDecoder('utf-16le').decode(bytes.subarray(2));
  else if (bytes.length >= 2 && bytes[0] === 0xfe && bytes[1] === 0xff) text = new TextDecoder('utf-16be').decode(bytes.subarray(2));
  else text = new TextDecoder('utf-8', { fatal: false }).decode(bytes);
  return text.replace(/^﻿/, '').replace(/\r\n?/g, '\n');
}

/** 시간 없는 가사: 비어 있지 않은 줄만 (기존 앱 동작) */
export function parsePlain(text: string): ParsedLyrics {
  const lines = text.replace(/^﻿/, '').replace(/\r/g, '').split('\n')
    .map((l) => l.replace(WORD_TIME, '').trim())
    .filter((l) => l && !META_LINE.test(l))
    .map((l) => ({ t_ms: null, text: l }));
  return { synced: false, lines };
}

/**
 * 동기 LRC. 한 줄에 시간이 여러 개면 각각 같은 문장. 초가 60 이상인 시간은 버린다.
 * 유효한 시간이 하나도 없으면 일반 텍스트로 본다.
 */
export function parseLrc(input: string): ParsedLyrics {
  const text = input.replace(/^﻿/, '').replace(/\r/g, '');
  const offset = Number(/\[offset\s*:\s*([+-]?\d+)\]/i.exec(text)?.[1] ?? 0);
  const rows: { t: number; text: string }[] = [];
  for (const line of text.split('\n')) {
    const times = [...line.matchAll(TIME)];
    if (times.length === 0) continue;
    const body = line.replace(TIME, '').replace(WORD_TIME, '').trim();
    for (const m of times) {
      if (Number(m[2]) >= 60) continue;
      // 소수부는 십진 소수: .2 = 0.2초, .25 = 0.25초, .250 = 0.25초
      const frac = m[3] ? Math.round(Number(`0.${m[3]}`) * 1000) : 0;
      rows.push({ t: Math.max(0, Number(m[1]) * 60_000 + Number(m[2]) * 1000 + frac + offset), text: body });
    }
  }
  if (rows.length === 0) return parsePlain(text);
  // 안정 정렬 후 같은 시각을 합친다
  rows.sort((a, b) => a.t - b.t);
  const merged: { t: number; text: string }[] = [];
  for (const r of rows) {
    const prev = merged[merged.length - 1];
    if (prev && prev.t === r.t) {
      if (r.text && r.text !== prev.text) prev.text = [prev.text, r.text].filter(Boolean).join('\n');
    } else {
      merged.push({ ...r });
    }
  }
  return { synced: true, lines: merged.map((r) => ({ t_ms: r.t, text: r.text })) };
}

export function parseLyrics(format: 'lrc' | 'plain', body: string): ParsedLyrics {
  return format === 'lrc' ? parseLrc(body) : parsePlain(body);
}
