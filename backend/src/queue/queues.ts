import { Queue } from './queue';

export const analysisQueue = new Queue('document-analysis', {
  defaultJobOptions: {
    attempts: 3,
    backoff: { type: 'exponential', delay: 2000 },
    priority: 1,
  },
});

export const ocrQueue = new Queue('ocr-processing', {
  defaultJobOptions: {
    attempts: 2,
    backoff: { type: 'fixed', delay: 5000 },
    priority: 1,
  },
});

export const notificationQueue = new Queue('notification', {
  defaultJobOptions: {
    attempts: 5,
    backoff: { type: 'fixed', delay: 5000 },
    priority: 2,
  },
});

export const autoDeleteQueue = new Queue('auto-delete', {
  defaultJobOptions: {
    attempts: 1,
    priority: 3,
  },
});

export const reminderQueue = new Queue('reminder', {
  defaultJobOptions: {
    attempts: 2,
    backoff: { type: 'fixed', delay: 10000 },
    priority: 2,
  },
});
