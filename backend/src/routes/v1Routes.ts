import { Router } from 'express';
import { publicAnalyze } from '../controllers/publicAnalyzeController';
import { authenticateApiKey } from '../middleware/auth';
import { aiRateLimiter } from '../middleware/rateLimiter';

const router = Router();
router.post('/analyze', authenticateApiKey, aiRateLimiter, publicAnalyze);
export default router;
