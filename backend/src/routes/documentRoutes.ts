import { Router } from 'express';
import { uploadDocument, getDocumentStatus, getDocumentAnalysis } from '../controllers/documentController';
import { uploadFile, handleMulterError } from '../middleware/fileValidator';
import { authenticate } from '../middleware/auth';

const router = Router();

router.post(
  '/upload',
  authenticate,
  uploadFile.single('file'),
  handleMulterError,
  uploadDocument
);

router.get('/:id/status', authenticate, getDocumentStatus);
router.get('/:id/analysis', authenticate, getDocumentAnalysis);

export default router;
