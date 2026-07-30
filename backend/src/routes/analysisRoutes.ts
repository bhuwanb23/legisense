import { Router } from 'express';
import {
  startAnalysis,
  getAnalysis,
  getClauses,
  getRisks,
  getSummary,
  getRiskDashboard,
  getRisksByCategory,
  getPlainEnglish,
  lookupGlossary,
  classifyEndpoint,
  confirmDocumentType,
  getJurisdictionFlags,
  getStateConflicts,
} from '../controllers/analysisController';
import { authenticate } from '../middleware/auth';
import { aiRateLimiter } from '../middleware/rateLimiter';

const router = Router();

router.post('/start/:documentId', authenticate, aiRateLimiter, startAnalysis);
router.get('/:documentId', authenticate, getAnalysis);
router.get('/:documentId/clauses', authenticate, getClauses);
router.get('/:documentId/risks', authenticate, getRisks);
router.get('/:documentId/risks/:category', authenticate, getRisksByCategory);
router.get('/:documentId/summary', authenticate, getSummary);
router.get('/:documentId/risk-dashboard', authenticate, getRiskDashboard);
router.get('/:documentId/plain-english', authenticate, getPlainEnglish);
router.get('/:documentId/jurisdiction-flags', authenticate, getJurisdictionFlags);
router.get('/:documentId/state-conflicts', authenticate, getStateConflicts);
router.get('/:documentId/classify', authenticate, classifyEndpoint);
router.post('/:documentId/confirm-type', authenticate, confirmDocumentType);
router.post('/glossary', authenticate, lookupGlossary);

export default router;
