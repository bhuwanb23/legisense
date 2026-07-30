import { Router } from 'express';
import {
  uploadDocument,
  listDocuments,
  getDocument,
  deleteDocument,
  getDocumentStatus,
  getDocumentAnalysis,
  translateDocument,
} from '../controllers/documentController';
import { uploadFile, handleMulterError } from '../middleware/fileValidator';
import { authenticate } from '../middleware/auth';
import { aiRateLimiter } from '../middleware/rateLimiter';

const router = Router();

router.get('/', authenticate, listDocuments);

router.post(
  '/upload',
  authenticate,
  uploadFile.single('file'),
  handleMulterError,
  uploadDocument
);

router.get('/:id', authenticate, getDocument);
router.get('/:id/status', authenticate, getDocumentStatus);
router.get('/:id/analysis', authenticate, getDocumentAnalysis);
router.post('/:id/translate', authenticate, aiRateLimiter, translateDocument);
router.delete('/:id', authenticate, deleteDocument);

export default router;
