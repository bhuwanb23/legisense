import { analyzeDocumentPipeline } from '../../services/analysisService';
import { Worker } from '../worker';

export function createAnalysisWorker(): Worker {
  const worker = new Worker('document-analysis', async (job) => {
    const { documentId, userId } = job.data as { documentId: number; userId: number };
    await analyzeDocumentPipeline(documentId, userId);
  }, { concurrency: 2 });

  return worker;
}
