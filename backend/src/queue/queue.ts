import { getDb } from '../config/database';
import { sql } from 'drizzle-orm';

export interface JobData {
  id: string;
  name: string;
  data: unknown;
  opts: JobOpts;
  queueName: string;
  status: string;
  priority: number;
  attempt: number;
  maxAttempts: number;
  retryCount: number;
  error?: string;
  createdAt: string;
  startedAt?: string;
  completedAt?: string;
  failedAt?: string;
  delayUntil?: string;
  returnvalue?: unknown;
}

export interface JobOpts {
  priority?: number;
  attempts?: number;
  backoff?: { type: 'exponential' | 'fixed'; delay: number };
  delay?: number;
  repeat?: { pattern: string };
}

export interface QueueOpts {
  defaultJobOptions?: Partial<JobOpts>;
}

export class Queue {
  readonly name: string;
  private opts: QueueOpts;
  private static initialized = false;

  constructor(name: string, opts?: QueueOpts) {
    this.name = name;
    this.opts = opts || {};
    Queue.ensureTable();
  }

  static ensureTable(): void {
    if (Queue.initialized) return;
    Queue.initialized = true;

    try {
      const db = getDb();
      db.run(sql`
        CREATE TABLE IF NOT EXISTS jobs (
          id TEXT PRIMARY KEY,
          queue_name TEXT NOT NULL,
          name TEXT NOT NULL,
          data TEXT NOT NULL DEFAULT '{}',
          opts TEXT NOT NULL DEFAULT '{}',
          status TEXT NOT NULL DEFAULT 'pending',
          priority INTEGER NOT NULL DEFAULT 0,
          attempt INTEGER NOT NULL DEFAULT 0,
          max_attempts INTEGER NOT NULL DEFAULT 3,
          retry_count INTEGER NOT NULL DEFAULT 0,
          error TEXT,
          delay_until TEXT,
          repeat_job_key TEXT,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          started_at TEXT,
          completed_at TEXT,
          failed_at TEXT,
          returnvalue TEXT
        )
      `);
      db.run(sql`CREATE INDEX IF NOT EXISTS idx_jobs_queue_status ON jobs(queue_name, status, priority)`);
      db.run(sql`CREATE INDEX IF NOT EXISTS idx_jobs_repeat_key ON jobs(repeat_job_key)`);
    } catch {
      // Table may already exist or db not initialized yet
    }
  }

  async add(jobName: string, data: unknown, opts?: JobOpts): Promise<JobData> {
    const db = getDb();
    const mergedOpts = { ...this.opts.defaultJobOptions, ...opts };
    const id = `${this.name}_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

    const delay = mergedOpts.delay || 0;
    const delayUntil = delay > 0
      ? new Date(Date.now() + delay).toISOString()
      : null;

    db.run(sql`
      INSERT INTO jobs (id, queue_name, name, data, opts, status, priority, max_attempts, delay_until)
      VALUES (${id}, ${this.name}, ${jobName}, ${JSON.stringify(data)}, ${JSON.stringify(mergedOpts)}, 'pending', ${mergedOpts.priority || 0}, ${mergedOpts.attempts || 3}, ${delayUntil})
    `);

    const job = this.mapRow({ id, queueName: this.name, name: jobName, data, opts: mergedOpts, status: 'pending', priority: mergedOpts.priority || 0, maxAttempts: mergedOpts.attempts || 3, delayUntil });

    return job;
  }

  async addRepeatable(jobName: string, data: unknown, pattern: string): Promise<void> {
    const repeatKey = `${this.name}:${jobName}:${pattern}`;
    const db = getDb();

    const existing = db.all(sql`
      SELECT id FROM jobs WHERE repeat_job_key = ${repeatKey} AND status NOT IN ('completed', 'failed')
    `) as { id: string }[];

    if (existing.length > 0) return;

    const id = `${this.name}_repeat_${Date.now()}`;
    db.run(sql`
      INSERT INTO jobs (id, queue_name, name, data, opts, status, priority, max_attempts, repeat_job_key)
      VALUES (${id}, ${this.name}, ${jobName}, ${JSON.stringify(data)}, ${JSON.stringify({ repeat: { pattern }, priority: 3 })}, 'pending', 3, 3, ${repeatKey})
    `);
  }

  async getJob(jobId: string): Promise<JobData | undefined> {
    const db = getDb();
    const rows = db.all(sql`SELECT * FROM jobs WHERE id = ${jobId}`) as Record<string, unknown>[];
    return rows.length > 0 ? this.mapRow(rows[0]) : undefined;
  }

  async getJobs(statuses?: string[]): Promise<JobData[]> {
    const db = getDb();
    if (statuses && statuses.length > 0) {
      const placeholders = statuses.map(() => '?').join(',');
      const rows = db.all(sql`
        SELECT * FROM jobs WHERE queue_name = ${this.name} AND status IN (${sql.raw(placeholders)})
        ORDER BY priority ASC, created_at ASC
      `) as Record<string, unknown>[];
      return rows.map(r => this.mapRow(r));
    }
    const rows = db.all(sql`
      SELECT * FROM jobs WHERE queue_name = ${this.name}
      ORDER BY priority ASC, created_at ASC
    `) as Record<string, unknown>[];
    return rows.map(r => this.mapRow(r));
  }

  async getActiveCount(): Promise<number> {
    const db = getDb();
    const rows = db.all(sql`
      SELECT COUNT(*) as count FROM jobs WHERE queue_name = ${this.name} AND status = 'processing'
    `) as { count: number }[];
    return Number(rows[0]?.count ?? 0);
  }

  async getPendingCount(): Promise<number> {
    const db = getDb();
    const rows = db.all(sql`
      SELECT COUNT(*) as count FROM jobs WHERE queue_name = ${this.name} AND status = 'pending' AND (delay_until IS NULL OR delay_until <= datetime('now'))
    `) as { count: number }[];
    return Number(rows[0]?.count ?? 0);
  }

  async close(): Promise<void> {
    // no-op for SQLite-backed queues
  }

  async obliterate(): Promise<void> {
    const db = getDb();
    db.run(sql`DELETE FROM jobs WHERE queue_name = ${this.name}`);
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
      startedAt: row.started_at ? String(row.started_at) : (row.startedAt ? String(row.startedAt) : undefined),
      completedAt: row.completed_at ? String(row.completed_at) : (row.completedAt ? String(row.completedAt) : undefined),
      failedAt: row.failed_at ? String(row.failed_at) : (row.failedAt ? String(row.failedAt) : undefined),
      delayUntil: row.delay_until ? String(row.delay_until) : (row.delayUntil ? String(row.delayUntil) : undefined),
      returnvalue: row.returnvalue || undefined,
    };
  }
}
