// 프로세스 안 작업 큐 (01장 §4.2 jobs). 재시작하면 running을 queued로 되돌려 다시 실행한다.
// 유형별 동시 실행 수가 따로 있다: scan 1, transcode = TRANSCODE_CONCURRENCY (03장 §4.6).
// 같은 유형 안에서는 priority가 높은 것(stream > download)부터, 그다음 먼저 들어온 순서.
import { newId } from './ids.ts';
import type { Ctx } from './ctx.ts';

export type JobType = 'scan' | 'transcode' | 'hash' | 'backup';

export interface JobRow {
  id: string;
  type: JobType;
  ref_id: string | null;
  state: 'queued' | 'running' | 'succeeded' | 'failed' | 'canceled';
  progress: number | null;
  attempts: number;
  priority: number;
  created_at: number;
  started_at: number | null;
  finished_at: number | null;
  error_code: string | null;
}

export type JobHandler = (job: JobRow, progress: (p: number) => void) => Promise<void>;

/** 작업이 실패할 때 API로 보낼 수 있는 코드. 메시지(경로 포함 가능)는 서버 로그·error_detail에만 둔다. */
export class JobError extends Error {
  readonly code: string;
  constructor(code: string, detail: string) {
    super(detail);
    this.code = code;
  }
}

export class JobRunner {
  private readonly ctx: Ctx;
  private readonly handlers = new Map<JobType, JobHandler>();
  private readonly limits = new Map<JobType, number>();
  private readonly active = new Map<JobType, number>();
  private readonly inflight = new Set<Promise<void>>();
  private stopped = false;

  constructor(ctx: Ctx) {
    this.ctx = ctx;
  }

  register(type: JobType, handler: JobHandler, concurrency = 1) {
    this.handlers.set(type, handler);
    this.limits.set(type, Math.max(1, concurrency));
  }

  /** 기동 시 한 번. 중단된 작업을 되살린다. */
  recover() {
    const r = this.ctx.store.run("UPDATE jobs SET state = 'queued', started_at = NULL WHERE state = 'running'");
    if (r.changes) this.ctx.log.info({ count: r.changes }, '중단된 작업을 대기열로 되돌림');
  }

  get(id: string): JobRow | undefined {
    return this.ctx.store.get<JobRow>('SELECT * FROM jobs WHERE id = ?', id);
  }

  /** 대기·실행 중인 작업 수 */
  pending(type: JobType): number {
    return Number(this.ctx.store.get<{ n: number }>("SELECT COUNT(*) AS n FROM jobs WHERE type = ? AND state IN ('queued', 'running')", type)!.n);
  }

  /** 같은 대상의 작업이 대기·실행 중이면 그것을 돌려준다(중복 실행 방지). */
  enqueue(type: JobType, refId: string | null, priority = 0): JobRow {
    const existing = this.ctx.store.get<JobRow>(
      "SELECT * FROM jobs WHERE type = ? AND ref_id IS ? AND state IN ('queued', 'running') ORDER BY created_at LIMIT 1",
      type, refId,
    );
    if (existing) {
      if (priority > existing.priority) this.ctx.store.run('UPDATE jobs SET priority = ? WHERE id = ?', priority, existing.id);
      return this.get(existing.id)!;
    }
    const id = newId('job');
    this.ctx.store.run("INSERT INTO jobs (id, type, ref_id, state, priority, created_at) VALUES (?, ?, ?, 'queued', ?, ?)", id, type, refId, priority, Date.now());
    this.kick();
    return this.get(id)!;
  }

  kick() {
    if (this.stopped) return;
    for (const [type] of this.handlers) {
      while ((this.active.get(type) ?? 0) < (this.limits.get(type) ?? 1)) {
        const job = this.ctx.store.get<JobRow>(
          "SELECT * FROM jobs WHERE type = ? AND state = 'queued' AND (not_before IS NULL OR not_before <= ?) ORDER BY priority DESC, created_at LIMIT 1",
          type, Date.now(),
        );
        if (!job) break;
        this.ctx.store.run("UPDATE jobs SET state = 'running', started_at = ?, attempts = attempts + 1, progress = 0 WHERE id = ?", Date.now(), job.id);
        this.active.set(type, (this.active.get(type) ?? 0) + 1);
        const p = this.execute(job).finally(() => {
          this.active.set(type, (this.active.get(type) ?? 1) - 1);
          this.inflight.delete(p);
          this.kick();
        });
        this.inflight.add(p);
      }
    }
  }

  private async execute(job: JobRow) {
    const handler = this.handlers.get(job.type);
    try {
      if (!handler) throw new JobError('internal_error', `처리기 없음: ${job.type}`);
      await handler(job, (p) => this.ctx.store.run('UPDATE jobs SET progress = ? WHERE id = ?', Math.max(0, Math.min(1, p)), job.id));
      this.ctx.store.run("UPDATE jobs SET state = 'succeeded', progress = 1, finished_at = ? WHERE id = ?", Date.now(), job.id);
    } catch (e) {
      const code = e instanceof JobError ? e.code : 'internal_error';
      this.ctx.log.error({ job_id: job.id, type: job.type, err: (e as Error).message }, '작업 실패');
      try {
        this.ctx.store.run("UPDATE jobs SET state = 'failed', finished_at = ?, error_code = ?, error_detail = ? WHERE id = ?",
          Date.now(), code, (e as Error).message, job.id);
      } catch { /* 종료 중 DB가 닫힘 */ }
    }
  }

  /** 대기열이 빌 때까지 기다린다 (테스트·CLI용). */
  async idle() {
    while (this.inflight.size) await Promise.all([...this.inflight]);
  }

  async stop() {
    this.stopped = true;
    await this.idle();
  }
}

export function jobDto(j: JobRow) {
  const iso = (ms: number | null) => (ms === null ? null : new Date(ms).toISOString().replace(/\.\d{3}Z$/, 'Z'));
  return {
    id: j.id,
    type: j.type,
    state: j.state,
    progress: j.progress,
    error_code: j.error_code,
    started_at: iso(j.started_at),
    finished_at: iso(j.finished_at),
  };
}
