import { Router } from 'express';
import { listSupportedLanguages } from '../controllers/languageController';

const router = Router();

router.get('/supported', listSupportedLanguages);

export default router;
