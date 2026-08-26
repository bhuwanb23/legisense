import { createNotification } from '../../services/notificationService';
import { Worker } from '../worker';

export function createNotificationWorker(): Worker {
  const worker = new Worker('notification', async (job) => {
    const { userId, type, title, body, documentId } = job.data as {
      userId: number;
      type: string;
      title: string;
      body: string;
      documentId?: number;
    };

    await createNotification(userId, type, title, body, documentId);
  }, { concurrency: 3 });

  return worker;
}
