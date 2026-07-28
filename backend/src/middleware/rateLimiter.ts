import rateLimit from 'express-rate-limit';
import { TooManyRequestsError } from '../utils/errors';

export const rateLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (_req, _res, _next) => {
    throw new TooManyRequestsError('Rate limit exceeded. Max 100 requests per minute.');
  },
});

export const aiRateLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (_req, _res, _next) => {
    throw new TooManyRequestsError(
      'AI endpoint rate limit exceeded. Max 10 AI requests per minute.'
    );
  },
});
