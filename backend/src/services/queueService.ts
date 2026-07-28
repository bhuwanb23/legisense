export interface Job {
  id: string;
  documentId: number;
  userId: number;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  createdAt: string;
  error?: string;
}

type JobWorker = (documentId: number, userId: number) => Promise<void>;

class QueueService {
  private jobs: Job[] = [];
  private processing = false;
  private worker: JobWorker | null = null;

  setWorker(worker: JobWorker): void {
    this.worker = worker;
  }

  enqueue(documentId: number, userId: number): Job {
    const job: Job = {
      id: `job_${Date.now()}_${documentId}`,
      documentId,
      userId,
      status: 'pending',
      createdAt: new Date().toISOString(),
    };

    this.jobs.push(job);
    console.log(`Job enqueued: ${job.id} for document ${documentId}`);

    this.processNext();

    return job;
  }

  private async processNext(): Promise<void> {
    if (this.processing || !this.worker) return;

    const nextJob = this.jobs.find((j) => j.status === 'pending');
    if (!nextJob) return;

    this.processing = true;
    nextJob.status = 'processing';

    try {
      await this.worker(nextJob.documentId, nextJob.userId);
      nextJob.status = 'completed';
      console.log(`Job completed: ${nextJob.id}`);
    } catch (err) {
      nextJob.status = 'failed';
      nextJob.error = err instanceof Error ? err.message : String(err);
      console.error(`Job failed: ${nextJob.id}`, nextJob.error);
    } finally {
      this.processing = false;
      this.processNext();
    }
  }

  getJob(jobId: string): Job | undefined {
    return this.jobs.find((j) => j.id === jobId);
  }

  getJobsByDocument(documentId: number): Job[] {
    return this.jobs.filter((j) => j.documentId === documentId);
  }

  getStats(): { total: number; pending: number; processing: number; completed: number; failed: number } {
    return {
      total: this.jobs.length,
      pending: this.jobs.filter((j) => j.status === 'pending').length,
      processing: this.jobs.filter((j) => j.status === 'processing').length,
      completed: this.jobs.filter((j) => j.status === 'completed').length,
      failed: this.jobs.filter((j) => j.status === 'failed').length,
    };
  }
}

export const queueService = new QueueService();
