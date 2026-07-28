import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';
import { ValidationError } from '../utils/errors';

type RequestProperty = 'body' | 'query' | 'params';

export function validate(
  schema: ZodSchema,
  property: RequestProperty = 'body'
) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      const data = schema.parse(req[property]);
      req[property] = data;
      next();
    } catch (err) {
      if (err instanceof ZodError) {
        const fieldErrors = err.issues.map((e) => ({
          field: e.path.join('.'),
          message: e.message,
        }));
        next(new ValidationError('Input validation failed', fieldErrors));
      } else {
        next(err);
      }
    }
  };
}

export function sanitizeString(input: string): string {
  return input
    .replace(/[<>]/g, '')
    .replace(/javascript:/gi, '')
    .replace(/on\w+\s*=/gi, '')
    .trim();
}

export function sanitizeObject<T extends Record<string, unknown>>(obj: T): T {
  const sanitized = { ...obj };
  for (const key of Object.keys(sanitized)) {
    if (typeof sanitized[key] === 'string') {
      (sanitized[key] as unknown) = sanitizeString(sanitized[key] as string);
    }
  }
  return sanitized;
}
