import { Router } from 'express';
import { listCountries, listStates } from '../controllers/jurisdictionController';

const router = Router();

router.get('/countries', listCountries);
router.get('/:country/states', listStates);

export default router;
