import { getDb, persistNow } from '../config/database';
import { sql } from 'drizzle-orm';
import type { JobData, JobOpts } from './queue';

export type Processor = (job: JobData) => Promise<void>;

export interface WorkerOpts {
  concurrency?: number;
}

interface ActiveJob {
  id: string;
  abort: AbortController;
}

export class Worker {
  readonly queueName: string;
  private processor: Processor;
  private concurrency: number;
  private activeJobs: Map<string, ActiveJob> = new Map();
  private running = false;
  private pollTimer: ReturnType<typeof setTimeout> | null = null;
  private shutDown = false;

  constructor(queueName: string, processor: Processor, opts?: WorkerOpts) {
    this.queueName = queueName;
    this.processor = processor;
    this.concurrency = opts?.concurrency ?? 1;
  }

  async start(): Promise<void> {
    if (this.running) return;
    this.running = true;
    this.shutDown = false;
    this.poll();
    console.log(`Worker started for queue: ${this.queueName} (concurrency: ${this.concurrency})`);
  }

  async close(): Promise<void> {
    this.shutDown = true;
    this.running = false;

    if (this.pollTimer) {
      clearTimeout(this.pollTimer);
      this.pollTimer = null;
    }

    for (const [, active] of this.activeJobs) {
      active.abort.abort();
    }
    this.activeJobs.clear();
  }

  private poll(): void {
    if (this.shutDown || !this.running) return;

    this.processNext();

    this.pollTimer = setTimeout(() => this.poll(), 200);
  }

  private async processNext(): Promise<void> {
    if (this.activeJobs.size >= this.concurrency) return;

    const db = getDb();

    const pending = (await db.execute(sql`
      SELECT * FROM jobs
      WHERE queue_name = ${this.queueName}
        AND status = 'pending'
        AND (delay_until IS NULL OR delay_until <= NOW())
      ORDER BY priority ASC, created_at ASC
      LIMIT ${this.concurrency - this.activeJobs.size}
    `)).rows as Record<string, unknown>[];

    for (const row of pending) {
      const job: JobData = this.mapRow(row);
      this.executeJob(job);
    }
  }

  private async executeJob(job: JobData): Promise<void> {
    const abort = new AbortController();
    this.activeJobs.set(job.id, { id: job.id, abort });

    const db = getDb();

    const opts = job.opts as JobOpts;
    const maxAttempts = opts?.attempts || 3;

    await db.execute(sql`
      UPDATE jobs SET status = 'processing', started_at = NOW(), attempt = ${job.retryCount + 1}
      WHERE id = ${job.id}
    `);
    persistNow();

    try {
      await this.processor(job);

      await db.execute(sql`
        UPDATE jobs SET status = 'completed', completed_at = NOW()
        WHERE id = ${job.id}
      `);
      persistNow();

      this.emit('completed', job);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : String(err);
      const newRetryCount = job.retryCount + 1;

      if (newRetryCount < maxAttempts) {
        const backoff = this.calculateBackoff(opts?.backoff, newRetryCount);

        if (backoff > 0) {
          const delayUntil = new Date(Date.now() + backoff).toISOString().slice(0, 19).replace('T', ' ');
          await db.execute(sql`
            UPDATE jobs SET status = 'pending', delay_until = ${delayUntil}, retry_count = ${newRetryCount}, error = ${errorMessage}
            WHERE id = ${job.id}
          `);
        } else {
          await db.execute(sql`
            UPDATE jobs SET status = 'pending', retry_count = ${newRetryCount}, error = ${errorMessage}
            WHERE id = ${job.id}
          `);
        }
        persistNow();
        this.emit('retrying', { job, error: errorMessage, attempt: newRetryCount });
      } else {
        await db.execute(sql`
          UPDATE jobs SET status = 'failed', failed_at = NOW(), error = ${errorMessage}
          WHERE id = ${job.id}
        `);
        persistNow();
        this.emit('failed', { job, error: errorMessage });
      }
    } finally {
      this.activeJobs.delete(job.id);
    }
  }

  private calculateBackoff(backoff: JobOpts['backoff'], retryCount: number): number {
    if (!backoff) return 0;
    if (backoff.type === 'fixed') return backoff.delay;
    if (backoff.type === 'exponential') {
      return Math.min(backoff.delay * Math.pow(2, retryCount - 1), 30000);
    }
    return 0;
  }

  get activeJobCount(): number {
    return this.activeJobs.size;
  }

  private listeners: Map<string, Set<(...args: any[]) => void>> = new Map();

  on(event: string, listener: (...args: any[]) => void): void {
    if (!this.listeners.has(event)) this.listeners.set(event, new Set());
    this.listeners.get(event)!.add(listener);
  }

  private emit(event: string, ...args: unknown[]): void {
    const set = this.listeners.get(event);
    if (set) {
      for (const fn of set) fn(...args);
    }
  }

  private mapRow(row: Record<string, unknown>): JobData {
    return {
      id: String(row.id || ''),
      name: String(row.name || ''),
      data: typeof row.data === 'string' ? JSON.parse(row.data as string) : row.data,
      opts: typeof row.opts === 'string' ? JSON.parse(row.opts as string) : (row.opts as JobOpts) || {},
      queueName: String(row.queue_name || row.queueName || ''),
      status: String(row.status || 'pending'),
      priority: Number(row.priority) || 0,
      attempt: Number(row.attempt) || 0,
      maxAttempts: Number(row.max_attempts || row.maxAttempts) || 3,
      retryCount: Number(row.retry_count || row.retryCount) || 0,
      error: row.error ? String(row.error) : undefined,
      createdAt: String(row.created_at || row.createdAt || ''),
      startedAt: row.started_at ? String(row.started_at) : undefined,
      completedAt: row.completed_at ? String(row.completed_at) : undefined,
      failedAt: row.failed_at ? String(row.failed_at) : undefined,
      delayUntil: row.delay_until ? String(row.delay_until) : undefined,
    };
  }
}
