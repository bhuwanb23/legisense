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
} from './queues';
import { createAnalysisWorker } from './workers/analysisWorker';
import { createNotificationWorker } from './workers/notificationWorker';
import { deleteExpiredDocuments, checkDeadlineReminders } from './scheduledJobs';

export { Queue } from './queue';
export { Worker } from './worker';
export {
  analysisQueue,
  ocrQueue,
  notificationQueue,
  autoDeleteQueue,
  reminderQueue,
} from './queues';

let analysisWorker: Worker;
let notificationWorker: Worker;
let scheduler: Scheduler;

export function ensureJobsTable(): void {
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
  console.log('Jobs table created/verified.');
}

export async function startQueueSystem(): Promise<void> {
  ensureJobsTable();

  analysisWorker = createAnalysisWorker();
  notificationWorker = createNotificationWorker();

  scheduler = new Scheduler();

  // Auto-delete: every hour
  scheduler.register(
    autoDeleteQueue, analysisWorker,
    'auto-delete', {},
    '0 * * * *', 60 * 60 * 1000,
  );

  // Reminder check: every 6 hours
  scheduler.register(
    reminderQueue, analysisWorker,
    'check-reminders', {},
    '0 */6 * * *', 6 * 60 * 60 * 1000,
  );

  // Override scheduler's run handlers for the scheduled jobs
  scheduler.runScheduledJob = async (queue, jobName, data) => {
    if (jobName === 'auto-delete') {
      await deleteExpiredDocuments();
    } else if (jobName === 'check-reminders') {
      await checkDeadlineReminders();
    }
  };

  await analysisWorker.start();
  await notificationWorker.start();
  await scheduler.start();

  console.log('Queue system started: analysis, notification, auto-delete, reminder');
}

export async function stopQueueSystem(): Promise<void> {
  await scheduler?.stop();
  await analysisWorker?.close();
  await notificationWorker?.close();
  console.log('Queue system stopped');
}
