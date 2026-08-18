import { Router } from 'express';
import { publicAnalyze, getPublicAnalyze } from '../controllers/publicAnalyzeController';
import { authenticateApiKey, authenticateApiKeyRead } from '../middleware/auth';

const router = Router();
router.post('/analyze', authenticateApiKey, publicAnalyze);
router.get('/analyze/:documentId', authenticateApiKeyRead, getPublicAnalyze);
export default router;
