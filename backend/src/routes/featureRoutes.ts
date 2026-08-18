import { Router } from 'express';
import {
  toggleFavorite,
  createShareLink,
  revokeShareLink,
  getSharedAnalysis,
  listNotes,
  addNote,
  updateNote,
  deleteNote,
  listRules,
  addRule,
  updateRule,
  deleteRule,
  betterVersion,
  compare,
} from '../controllers/featureController';
import { authenticate } from '../middleware/auth';
import { aiRateLimiter } from '../middleware/rateLimiter';

const router = Router();

// Favorites
router.put('/documents/:id/favorite', authenticate, toggleFavorite);

// Share links
router.post('/documents/:id/share', authenticate, createShareLink);
router.delete('/documents/:id/share', authenticate, revokeShareLink);

// Notes
router.get('/documents/:documentId/notes', authenticate, listNotes);
router.post('/documents/:documentId/clauses/:clauseId/notes', authenticate, addNote);
router.put('/notes/:noteId', authenticate, updateNote);
router.delete('/notes/:noteId', authenticate, deleteNote);

// Playbook
router.get('/playbook/rules', authenticate, listRules);
router.post('/playbook/rules', authenticate, addRule);
router.put('/playbook/rules/:id', authenticate, updateRule);
router.delete('/playbook/rules/:id', authenticate, deleteRule);

// Better version + compare
router.post('/analysis/:documentId/better-version', authenticate, aiRateLimiter, betterVersion);
router.post('/analysis/compare', authenticate, compare);

// Public shared view (no auth)
router.get('/shared/:token', getSharedAnalysis);

export default router;
