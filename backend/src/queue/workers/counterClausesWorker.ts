import { generateCounterClauses } from '../../services/counterClauseService';
import { Worker } from '../worker';

export function createCounterClausesWorker(): Worker {
  return new Worker('counter-clauses', async (job) => {
    const { documentId, userId } = job.data as { documentId: number; userId: number };
    await generateCounterClauses(documentId, userId);
  }, { concurrency: 1 });
}
