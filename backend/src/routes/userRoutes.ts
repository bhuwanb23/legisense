import { Router } from 'express';
import {
  getProfile,
  updateProfile,
  updatePreferences,
  deleteAccount,
} from '../controllers/userController';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validate';
import {
  updateProfileSchema,
  updatePreferencesSchema,
} from '../schemas/userSchemas';

const router = Router();

router.get('/profile', authenticate, getProfile);
router.put('/profile', authenticate, validate(updateProfileSchema), updateProfile);
router.put('/preferences', authenticate, validate(updatePreferencesSchema), updatePreferences);
router.delete('/account', authenticate, deleteAccount);

export default router;
