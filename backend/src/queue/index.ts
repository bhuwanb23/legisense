import { getDb } from '../config/database';
import { sql } from 'drizzle-orm';
import { Scheduler } from './scheduler';
import { Worker } from './worker';
import {
  analysisQueue,
  ocrQueue,
  notificationQueue,
  autoDeleteQueue,
  reminderQueue,
  counterClausesQueue,
} from './queues';
import { createAnalysisWorker } from './workers/analysisWorker';
import { createNotificationWorker } from './workers/notificationWorker';
import { createOcrWorker } from './workers/ocrWorker';
import { createCounterClausesWorker } from './workers/counterClausesWorker';
import { deleteExpiredDocuments, checkDeadlineReminders } from './scheduledJobs';

export { Queue } from './queue';
export { Worker } from './worker';
export {
  analysisQueue,
  ocrQueue,
  notificationQueue,
  autoDeleteQueue,
  reminderQueue,
  counterClausesQueue,
} from './queues';

let analysisWorker: Worker;
let notificationWorker: Worker;
let ocrWorker: Worker;
let counterClausesWorker: Worker;
let scheduler: Scheduler;

export async function ensureJobsTable(): Promise<void> {
  const db = getDb();
  await db.execute(sql`
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
      created_at TEXT NOT NULL DEFAULT (NOW()),
      started_at TEXT,
      completed_at TEXT,
      failed_at TEXT,
      returnvalue TEXT
    )
  `);
  await db.execute(sql`CREATE INDEX IF NOT EXISTS idx_jobs_queue_status ON jobs(queue_name, status, priority)`);
  await db.execute(sql`CREATE INDEX IF NOT EXISTS idx_jobs_repeat_key ON jobs(repeat_job_key)`);
  console.log('Jobs table created/verified.');
}

export async function startQueueSystem(): Promise<void> {
  await ensureJobsTable();

  analysisWorker = createAnalysisWorker();
  notificationWorker = createNotificationWorker();
  ocrWorker = createOcrWorker();
  counterClausesWorker = createCounterClausesWorker();

  scheduler = new Scheduler();

  scheduler.register('auto-delete', deleteExpiredDocuments, 60 * 60 * 1000);
  scheduler.register('check-reminders', checkDeadlineReminders, 6 * 60 * 60 * 1000);

  await analysisWorker.start();
  await notificationWorker.start();
  await ocrWorker.start();
  await counterClausesWorker.start();
  await scheduler.start();

  console.log('Queue system started: ocr, analysis, notification, counter-clauses, auto-delete, reminder');
}

export async function stopQueueSystem(): Promise<void> {
  await scheduler?.stop();
  await analysisWorker?.close();
  await notificationWorker?.close();
  await ocrWorker?.close();
  await counterClausesWorker?.close();
  console.log('Queue system stopped');
}
