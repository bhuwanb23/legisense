import { EventEmitter } from 'events';
import { getDb } from '../config/database';
import { queueJobs } from '../models';
import { sql } from 'drizzle-orm';
import { persistNow } from '../config/database';

export interface Job {
  id: string;
  documentId: number;
  userId: number;
  status: 'pending' | 'processing' | 'completed' | 'failed' | 'retrying';
  createdAt: string;
  error?: string;
}

export interface QueueServiceOptions {
  maxConcurrency?: number;
  defaultTimeoutMs?: number;
  defaultMaxRetries?: number;
  pollIntervalMs?: number;
}

type JobWorker = (documentId: number, userId: number) => Promise<void>;

class QueueService extends EventEmitter {
  private worker: JobWorker | null = null;
  private activeJobs = 0;
  private maxConcurrency: number;
  private defaultTimeoutMs: number;
  private defaultMaxRetries: number;
  private shutDownRequested = false;
  private timers = new Map<string, NodeJS.Timeout>();
  private pollTimer: NodeJS.Timeout | null = null;

  constructor(options?: QueueServiceOptions) {
    super();
    this.maxConcurrency = options?.maxConcurrency ?? 2;
    this.defaultTimeoutMs = options?.defaultTimeoutMs ?? 300000;
    this.defaultMaxRetries = options?.defaultMaxRetries ?? 3;
  }

  setWorker(worker: JobWorker): void {
    this.worker = worker;
  }

  async enqueue(documentId: number, userId: number): Promise<Job> {
    return await this.enqueueWithOptions(documentId, userId);
  }

  async enqueueWithOptions(
    documentId: number,
    userId: number,
    options?: { priority?: number; timeoutMs?: number; maxRetries?: number }
  ): Promise<Job> {
    const db = getDb();
    const id = `job_${Date.now()}_${documentId}_${Math.random().toString(36).slice(2, 6)}`;

    await db.insert(queueJobs).values({
      id,
      documentId,
      userId,
      status: 'pending',
      priority: options?.priority ?? 0,
      retryCount: 0,
      maxRetries: options?.maxRetries ?? this.defaultMaxRetries,
      timeoutMs: options?.timeoutMs ?? this.defaultTimeoutMs,
    });

    persistNow();

    const job: Job = {
      id,
      documentId,
      userId,
      status: 'pending',
      createdAt: new Date().toISOString(),
    };

    console.log(`Job enqueued: ${job.id} for document ${documentId}`);
    this.emit('job:queued', { ...job });
    this.processNext();

    return job;
  }

  private async processNext(): Promise<void> {
    if (this.shutDownRequested) return;
    if (!this.worker) return;
    if (this.activeJobs >= this.maxConcurrency) return;

    const db = getDb();

    const pendingRows = await db.select().from(queueJobs).where(
      sql`${queueJobs.status} = 'pending'`
    );

    if (pendingRows.length === 0) return;

    pendingRows.sort((a, b) => {
      if (b.priority !== a.priority) return b.priority - a.priority;
      return a.createdAt.localeCompare(b.createdAt);
    });

    const nextJob = pendingRows[0];

    this.activeJobs++;

    await db.execute(sql`UPDATE ${queueJobs} SET status = 'processing', started_at = NOW() WHERE id = ${nextJob.id}`);
    persistNow();

    this.emit('job:started', {
      id: nextJob.id,
      documentId: nextJob.documentId,
      userId: nextJob.userId,
    });

    const timer = setTimeout(() => this.handleTimeout(nextJob.id), nextJob.timeoutMs);
    this.timers.set(nextJob.id, timer);

    try {
      await this.worker(nextJob.documentId, nextJob.userId);

      clearTimeout(timer);
      this.timers.delete(nextJob.id);

      await db.execute(sql`UPDATE ${queueJobs} SET status = 'completed', completed_at = NOW() WHERE id = ${nextJob.id}`);
      persistNow();

      this.emit('job:completed', { id: nextJob.id, documentId: nextJob.documentId });
    } catch (err) {
      clearTimeout(timer);
      this.timers.delete(nextJob.id);

      const errorMessage = err instanceof Error ? err.message : String(err);

      if (nextJob.retryCount < nextJob.maxRetries) {
        const newRetryCount = nextJob.retryCount + 1;
        const backoffMs = Math.min(1000 * Math.pow(2, newRetryCount), 30000);

        await db.execute(sql`UPDATE ${queueJobs} SET status = 'retrying', retry_count = ${newRetryCount}, error = ${errorMessage} WHERE id = ${nextJob.id}`);
        persistNow();

        this.emit('job:retrying', {
          id: nextJob.id,
          documentId: nextJob.documentId,
          retryCount: newRetryCount,
          error: errorMessage,
        });

        setTimeout(async () => {
          await db.execute(sql`UPDATE ${queueJobs} SET status = 'pending' WHERE id = ${nextJob.id}`);
          persistNow();
          this.processNext();
        }, backoffMs);
      } else {
        await db.execute(sql`UPDATE ${queueJobs} SET status = 'failed', error = ${errorMessage}, completed_at = NOW() WHERE id = ${nextJob.id}`);
        persistNow();

        this.emit('job:failed', { id: nextJob.id, documentId: nextJob.documentId, error: errorMessage });
      }
    } finally {
      this.activeJobs--;
      this.processNext();
    }
  }

  private async handleTimeout(jobId: string): Promise<void> {
    const db = getDb();
    const rows = await db.select().from(queueJobs).where(
      sql`${queueJobs.id} = ${jobId} AND ${queueJobs.status} = 'processing'`
    );

    if (rows.length > 0) {
      await db.execute(sql`UPDATE ${queueJobs} SET status = 'failed', error = 'Job timed out', completed_at = NOW() WHERE id = ${jobId}`);
      persistNow();
      this.emit('job:failed', { id: jobId, error: 'Job timed out' });
    }
  }

  async getJob(jobId: string): Promise<Job | undefined> {
    const db = getDb();
    const rows = await db.select().from(queueJobs).where(sql`${queueJobs.id} = ${jobId}`);
    return rows.length > 0 ? this.mapJob(rows[0]) : undefined;
  }

  async getJobsByDocument(documentId: number): Promise<Job[]> {
    const db = getDb();
    const rows = await db.select().from(queueJobs).where(sql`${queueJobs.documentId} = ${documentId}`);
    return rows.map((r) => this.mapJob(r));
  }

  async getPendingJobs(): Promise<Job[]> {
    const db = getDb();
    const rows = await db.select().from(queueJobs).where(
      sql`${queueJobs.status} IN ('pending', 'retrying')`
    );
    return rows.map((r) => this.mapJob(r));
  }

  async getStats(): Promise<{ total: number; pending: number; processing: number; completed: number; failed: number; retrying: number }> {
    const db = getDb();
    const result = (await db.execute(sql`
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
        SUM(CASE WHEN status = 'processing' THEN 1 ELSE 0 END) as processing,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
        SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed,
        SUM(CASE WHEN status = 'retrying' THEN 1 ELSE 0 END) as retrying
      FROM queue_jobs
    `)).rows as Array<{ total: number; pending: number; processing: number; completed: number; failed: number; retrying: number }>;
    return result[0] || { total: 0, pending: 0, processing: 0, completed: 0, failed: 0, retrying: 0 };
  }

  async shutdown(timeoutMs = 30000): Promise<void> {
    this.shutDownRequested = true;
    if (this.pollTimer) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }

    if (this.activeJobs === 0) return;

    return new Promise((resolve) => {
      const interval = setInterval(() => {
        if (this.activeJobs === 0) {
          clearInterval(interval);
          resolve();
          return;
        }
      }, 200);

      setTimeout(async () => {
        clearInterval(interval);
        const db = getDb();
        await db.execute(sql`UPDATE ${queueJobs} SET status = 'failed', error = 'Shutdown timeout' WHERE status = 'processing'`);
        persistNow();
        this.activeJobs = 0;
        resolve();
      }, timeoutMs);
    });
  }

  get activeJobCount(): number {
    return this.activeJobs;
  }

  get isShuttingDown(): boolean {
    return this.shutDownRequested;
  }

  private mapJob(row: typeof queueJobs.$inferSelect): Job {
    return {
      id: row.id,
      documentId: row.documentId,
      userId: row.userId,
      status: row.status as Job['status'],
      createdAt: row.createdAt,
      error: row.error || undefined,
    };
  }
}

export const queueService = new QueueService();
