import { Router } from 'express';
import { sendMessage, getHistory, createChatSession } from '../controllers/chatController';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { sendMessageSchema } from '../schemas/chatSchemas';
import { aiRateLimiter } from '../middleware/rateLimiter';

const router = Router();

router.post('/:documentId/session', authenticate, createChatSession);
router.post('/:documentId/message', authenticate, aiRateLimiter, validate(sendMessageSchema), sendMessage);
router.get('/:documentId/history', authenticate, getHistory);

export default router;
