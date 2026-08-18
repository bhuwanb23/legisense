import { Router } from 'express';
import {
  getProfile,
  updateProfile,
  updatePreferences,
  deleteAccount,
  uploadAvatar,
} from '../controllers/userController';
import { createUserApiKey, listUserApiKeys, revokeUserApiKey } from '../controllers/workspaceController';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { uploadFile, handleMulterError } from '../middleware/fileValidator';
import {
  updateProfileSchema,
  updatePreferencesSchema,
} from '../schemas/userSchemas';

const router = Router();

router.get('/profile', authenticate, getProfile);
router.put('/profile', authenticate, validate(updateProfileSchema), updateProfile);
router.put('/preferences', authenticate, validate(updatePreferencesSchema), updatePreferences);
router.post('/avatar', authenticate, uploadFile.single('avatar'), handleMulterError, uploadAvatar);
router.delete('/account', authenticate, deleteAccount);
router.post('/api-keys', authenticate, createUserApiKey);
router.get('/api-keys', authenticate, listUserApiKeys);
router.delete('/api-keys/:id', authenticate, revokeUserApiKey);

export default router;
