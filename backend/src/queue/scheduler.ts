import { getDb, persistNow } from '../config/database';
import { sql } from 'drizzle-orm';

interface ScheduledTask {
  name: string;
  handler: () => Promise<void>;
  intervalMs: number;
  lastRun: number;
}

export class Scheduler {
  private tasks: ScheduledTask[] = [];
  private timers: ReturnType<typeof setInterval>[] = [];
  private running = false;

  register(name: string, handler: () => Promise<void>, intervalMs: number): void {
    this.tasks.push({ name, handler, intervalMs, lastRun: 0 });
  }

  async start(): Promise<void> {
    if (this.running) return;
    this.running = true;

    await this.resumeProcessingJobs();

    for (const task of this.tasks) {
      await task.handler();
      task.lastRun = Date.now();
      const timer = setInterval(async () => {
        if (!this.running) return;
        try {
          await task.handler();
          task.lastRun = Date.now();
        } catch (err) {
          console.error(`Scheduled task "${task.name}" failed:`, err);
        }
      }, task.intervalMs);
      this.timers.push(timer);
      console.log(`Scheduler registered: ${task.name} (every ${task.intervalMs / 1000}s)`);
    }
  }

  async stop(): Promise<void> {
    this.running = false;
    for (const timer of this.timers) clearInterval(timer);
    this.timers = [];
    console.log('Scheduler stopped');
  }

  private async resumeProcessingJobs(): Promise<void> {
    const db = getDb();

    const stuck = (await db.execute(sql`
      SELECT id FROM jobs WHERE status = 'processing'
    `) as { id: string }[];

    for (const row of stuck) {
      await db.execute(sql`UPDATE jobs SET status = 'pending' WHERE id = ${row.id}`);
    }

    if (stuck.length > 0) {
      persistNow();
      console.log(`Reset ${stuck.length} stuck jobs to pending`);
    }
  }
}
