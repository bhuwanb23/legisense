import { Router } from 'express';
import {
  uploadDocument,
  listDocuments,
  getDocument,
  deleteDocument,
  pasteText,
  getDocumentStatus,
  getDocumentAnalysis,
} from '../controllers/documentController';
import { uploadFile, handleMulterError } from '../middleware/fileValidator';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { pasteTextSchema } from '../schemas/documentSchemas';

const router = Router();

router.get('/', authenticate, listDocuments);

router.post(
  '/upload',
  authenticate,
  uploadFile.single('file'),
  handleMulterError,
  uploadDocument
);

router.post('/paste', authenticate, validate(pasteTextSchema), pasteText);

router.get('/:id', authenticate, getDocument);
router.get('/:id/status', authenticate, getDocumentStatus);
router.get('/:id/analysis', authenticate, getDocumentAnalysis);
router.delete('/:id', authenticate, deleteDocument);

export default router;
