// 검색·정렬용 정규화 (01장 §4.6).
// NFKC → 소문자 → 가타카나를 히라가나로 → 공백 축약. 전각/반각 통일은 NFKC가 처리한다
// (반각 가타카나 ｶﾞ → ガ, 전각 영숫자 Ｚ → Z). 컬럼·색인·질의어에 같은 함수를 쓴다.

export function norm(input: string): string {
  const s = input.normalize('NFKC').toLowerCase();
  let out = '';
  for (const ch of s) {
    const cp = ch.codePointAt(0)!;
    // 가타카나 ァ(30A1)~ヶ(30F6) → 히라가나 (0x60 차이). ー(30FC)는 그대로 둔다.
    out += cp >= 0x30a1 && cp <= 0x30f6 ? String.fromCodePoint(cp - 0x60) : ch;
  }
  return out.replace(/\s+/gu, ' ').trim();
}

/** 정렬 키: 정렬 태그가 있으면 그것, 없으면 제목. 한자 읽기를 추측하지 않는다. */
export function sortKey(title: string, sortTag: string | null | undefined): string {
  return norm(sortTag && sortTag.trim() ? sortTag : title);
}
