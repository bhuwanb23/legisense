import { queueService } from '../services/queueService';
import { analyzeDocumentPipeline } from '../services/analysisService';

export function startAnalysisWorker(): void {
  queueService.setWorker(analyzeDocumentPipeline);
  console.log('Analysis worker ready.');
}
