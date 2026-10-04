// 로그인 실패 속도 제한 (02장 §1.1, SEC-11). 사용자 이름별·IP별로 따로 센다.
// 단일 프로세스 서버이므로 메모리에 둔다(재시작하면 초기화 — 가정용 규모에서 허용).

export class FailureLimiter {
  private readonly hits = new Map<string, number[]>();
  private readonly max: number;
  private readonly windowMs: number;

  constructor(max: number, windowMs: number) {
    this.max = max;
    this.windowMs = windowMs;
  }

  private recent(key: string, now: number): number[] {
    const list = (this.hits.get(key) ?? []).filter((t) => now - t < this.windowMs);
    if (list.length) this.hits.set(key, list);
    else this.hits.delete(key);
    return list;
  }

  /** 제한 중이면 남은 초, 아니면 0 */
  retryAfter(keys: string[], now = Date.now()): number {
    let wait = 0;
    for (const k of keys) {
      const list = this.recent(k, now);
      if (list.length >= this.max) wait = Math.max(wait, Math.ceil((list[0]! + this.windowMs - now) / 1000));
    }
    return wait;
  }

  fail(keys: string[], now = Date.now()): void {
    for (const k of keys) this.hits.set(k, [...this.recent(k, now), now]);
  }

  reset(key: string): void {
    this.hits.delete(key);
  }
}
