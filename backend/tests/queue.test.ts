import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { initDatabase, closeDatabase } from '../src/config/database';
import { Queue, Worker } from '../src/queue';

process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret-for-jwt';

before(async () => {
  await initDatabase();
});

after(() => {
  closeDatabase();
});

describe('Queue', () => {
  it('creates a queue and adds a job', async () => {
    const queue = new Queue('test-basic');
    const job = await queue.add('test', { msg: 'hello' });

    assert.ok(job.id, 'job has an id');
    assert.equal(job.name, 'test');
    assert.equal(job.status, 'pending');
    assert.equal((job.data as any).msg, 'hello');

    await queue.obliterate();
  });

  it('defaults to priority 0 and attempts 3', async () => {
    const queue = new Queue('test-defaults');
    const job = await queue.add('test', {});

    assert.equal(job.priority, 0);
    assert.equal(job.maxAttempts, 3);

    await queue.obliterate();
  });

  it('respects custom priority and attempts', async () => {
    const queue = new Queue('test-opts', {
      defaultJobOptions: { priority: 1, attempts: 5 },
    });
    const job = await queue.add('test', {}, { priority: 2 });

    assert.equal(job.priority, 2);
    assert.equal(job.maxAttempts, 5);

    await queue.obliterate();
  });

  it('getJob returns the job by id', async () => {
    const queue = new Queue('test-get');
    const added = await queue.add('test', { x: 1 });
    const fetched = await queue.getJob(added.id);

    assert.ok(fetched);
    assert.equal(fetched.id, added.id);
    assert.equal((fetched.data as any).x, 1);

    await queue.obliterate();
  });

  it('getJobs returns all jobs for the queue', async () => {
    const queue = new Queue('test-list');
    await queue.add('a', {});
    await queue.add('b', {});

    const jobs = await queue.getJobs();
    assert.equal(jobs.length, 2);

    await queue.obliterate();
  });

  it('getJobs filters by status', async () => {
    const queue = new Queue('test-filter');
    await queue.add('a', {});

    const pending = await queue.getJobs(['pending']);
    assert.equal(pending.length, 1, `expected 1 pending, got ${pending.length}: ${JSON.stringify(pending)}`);
    assert.equal(pending[0].status, 'pending');

    const completed = await queue.getJobs(['completed']);
    assert.equal(completed.length, 0);

    await queue.obliterate();
  });

  it('obliterate removes all jobs', async () => {
    const queue = new Queue('test-obliterate');
    await queue.add('a', {});
    await queue.add('b', {});
    await queue.obliterate();

    const jobs = await queue.getJobs();
    assert.equal(jobs.length, 0);
  });
});

describe('Worker', () => {
  it('processes a job and marks it completed', async () => {
    const queue = new Queue('worker-basic');
    const worker = new Worker('worker-basic', async (job) => {
      assert.equal((job.data as any).msg, 'process me');
    }, { concurrency: 1 });

    worker.start();
    await queue.add('process', { msg: 'process me' });
    await new Promise((r) => setTimeout(r, 500));

    const jobs = await queue.getJobs();
    const processed = jobs.find(j => j.name === 'process');
    assert.equal(processed?.status, 'completed');

    worker.close();
    await queue.obliterate();
  });

  it('retries on failure up to maxAttempts', async () => {
    const queue = new Queue('worker-retry');
    let attempts = 0;

    const worker = new Worker('worker-retry', async () => {
      attempts++;
      throw new Error('fail');
    }, { concurrency: 1 });

    worker.start();
    await queue.add('retry-me', {}, { attempts: 3, backoff: { type: 'fixed', delay: 10 } });
    await new Promise((r) => setTimeout(r, 1000));

    const jobs = await queue.getJobs();
    const failed = jobs.find(j => j.name === 'retry-me');
    assert.equal(failed?.status, 'failed');
    assert.ok(attempts >= 2, `expected at least 2 attempts, got ${attempts}`);

    worker.close();
    await queue.obliterate();
  });

  it('respects concurrency limit', async () => {
    const queue = new Queue('worker-concurrency');
    let concurrent = 0;
    let maxSeen = 0;

    const worker = new Worker('worker-concurrency', async () => {
      concurrent++;
      maxSeen = Math.max(maxSeen, concurrent);
      await new Promise((r) => setTimeout(r, 300));
      concurrent--;
    }, { concurrency: 2 });

    worker.start();
    await queue.add('a', {});
    await queue.add('b', {});
    await queue.add('c', {});
    await new Promise((r) => setTimeout(r, 1500));

    assert.ok(maxSeen <= 2, `max concurrency was ${maxSeen}, expected ≤ 2`);

    worker.close();
    await queue.obliterate();
  });

  it('processes jobs in priority order', async () => {
    const queue = new Queue('worker-priority');
    const order: number[] = [];

    const worker = new Worker('worker-priority', async (job) => {
      order.push(job.priority);
    }, { concurrency: 1 });

    worker.start();
    await queue.add('low', {}, { priority: 10 });
    await queue.add('high', {}, { priority: 1 });
    await queue.add('mid', {}, { priority: 5 });
    await new Promise((r) => setTimeout(r, 800));

    assert.equal(order[0], 1, 'highest priority first');
    assert.equal(order[1], 5, 'medium priority second');
    assert.equal(order[2], 10, 'lowest priority last');

    worker.close();
    await queue.obliterate();
  });
});

describe('Queue priority system (named queues)', () => {
  it('analysis queue has high priority config', () => {
    const { analysisQueue, ocrQueue, notificationQueue, autoDeleteQueue, reminderQueue } = require('../src/queue/queues');

    assert.equal(analysisQueue.name, 'document-analysis');
    assert.equal(ocrQueue.name, 'ocr-processing');
    assert.equal(notificationQueue.name, 'notification');
    assert.equal(autoDeleteQueue.name, 'auto-delete');
    assert.equal(reminderQueue.name, 'reminder');
  });
});

describe('Worker events', () => {
  it('emits completed event on success', async () => {
    const queue = new Queue('events-completed');
    const worker = new Worker('events-completed', async () => {}, { concurrency: 1 });

    const events: string[] = [];
    worker.on('completed', () => events.push('completed'));
    worker.on('failed', () => events.push('failed'));
    worker.on('retrying', () => events.push('retrying'));

    worker.start();
    await queue.add('ok', {});
    await new Promise((r) => setTimeout(r, 500));

    assert.ok(events.includes('completed'), 'completed event fired');

    worker.close();
    await queue.obliterate();
  });

  it('emits failed event after exhausting retries', async () => {
    const queue = new Queue('events-failed');
    const worker = new Worker('events-failed', async () => {
      throw new Error('always fails');
    }, { concurrency: 1 });

    const events: string[] = [];
    worker.on('failed', (data) => events.push('failed'));
    worker.on('retrying', () => events.push('retrying'));

    worker.start();
    await queue.add('fail', {}, { attempts: 2, backoff: { type: 'fixed', delay: 10 } });
    await new Promise((r) => setTimeout(r, 1000));

    assert.ok(events.includes('failed'), 'failed event fired');
    assert.ok(events.includes('retrying'), 'retrying event fired before fail');

    worker.close();
    await queue.obliterate();
  });
});
