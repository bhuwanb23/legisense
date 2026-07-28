import { Router } from 'express';
import { listDeadlines, completeDeadline, dismissDeadline } from '../controllers/deadlineController';
import { authenticate } from '../middleware/auth';

const router = Router();

router.get('/', authenticate, listDeadlines);
router.put('/:id/complete', authenticate, completeDeadline);
router.put('/:id/dismiss', authenticate, dismissDeadline);

export default router;
