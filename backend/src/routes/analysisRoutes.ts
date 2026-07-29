import { Router } from 'express';
import {
  startAnalysis,
  getAnalysis,
  getClauses,
  getRisks,
  getSummary,
  getRiskDashboard,
} from '../controllers/analysisController';
import { authenticate } from '../middleware/auth';
import { aiRateLimiter } from '../middleware/rateLimiter';

const router = Router();

router.post('/start/:documentId', authenticate, aiRateLimiter, startAnalysis);
router.get('/:documentId', authenticate, getAnalysis);
router.get('/:documentId/clauses', authenticate, getClauses);
router.get('/:documentId/risks', authenticate, getRisks);
router.get('/:documentId/summary', authenticate, getSummary);
router.get('/:documentId/risk-dashboard', authenticate, getRiskDashboard);

export default router;
