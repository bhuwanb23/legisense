import { Router } from 'express';
import {
  listDeadlines,
  listUpcomingDeadlines,
  listDocumentDeadlines,
  completeDeadline,
  dismissDeadline,
} from '../controllers/deadlineController';
import { authenticate } from '../middleware/auth';

const router = Router();

router.get('/', authenticate, listDeadlines);
router.get('/upcoming', authenticate, listUpcomingDeadlines);
router.get('/document/:documentId', authenticate, listDocumentDeadlines);
router.put('/:id/complete', authenticate, completeDeadline);
router.put('/:id/dismiss', authenticate, dismissDeadline);

export default router;
