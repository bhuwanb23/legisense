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
  getFlaggedClauses,
  submitRiskFeedback,
  getMissingClausesEndpoint,
  getCounterClauses,
  markCounterUsed,
  rewritePlainEnglish,
} from '../controllers/analysisController';
import { templates } from '../controllers/featureController';
import { authenticate } from '../middleware/auth';
import { aiRateLimiter } from '../middleware/rateLimiter';

const router = Router();

// Must be registered before /:documentId routes so "templates" isn't
// captured as a document id.
router.get('/templates', templates);

router.post('/start/:documentId', authenticate, aiRateLimiter, startAnalysis);
router.get('/:documentId', authenticate, getAnalysis);
router.get('/:documentId/clauses', authenticate, getClauses);
router.get('/:documentId/risks', authenticate, getRisks);
router.get('/:documentId/risks/:category', authenticate, getRisksByCategory);
router.get('/:documentId/summary', authenticate, getSummary);
router.get('/:documentId/risk-dashboard', authenticate, getRiskDashboard);
router.get('/:documentId/plain-english', authenticate, getPlainEnglish);
router.post('/:documentId/plain-english/rewrite', authenticate, aiRateLimiter, rewritePlainEnglish);
router.get('/:documentId/jurisdiction-flags', authenticate, getJurisdictionFlags);
router.get('/:documentId/state-conflicts', authenticate, getStateConflicts);
router.get('/:documentId/flagged-clauses', authenticate, getFlaggedClauses);
router.post('/:documentId/clauses/:clauseId/risk-feedback', authenticate, submitRiskFeedback);
router.get('/:documentId/missing-clauses', authenticate, getMissingClausesEndpoint);
router.get('/:documentId/counter-clauses', authenticate, getCounterClauses);
router.post('/:documentId/clauses/:clauseId/counter-used', authenticate, aiRateLimiter, markCounterUsed);
router.get('/:documentId/classify', authenticate, classifyEndpoint);
router.post('/:documentId/confirm-type', authenticate, confirmDocumentType);
router.post('/glossary', authenticate, lookupGlossary);

export default router;
