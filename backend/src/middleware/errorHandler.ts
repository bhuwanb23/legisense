import { Request, Response, NextFunction } from 'express';
import { AppError } from '../utils/errors';
import { ZodError } from 'zod';
import multer from 'multer';

interface ErrorResponse {
  success: false;
  error: {
    message: string;
    code: string;
    statusCode: number;
    details?: unknown;
    stack?: string;
  };
}

export function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  const isDev = process.env.NODE_ENV !== 'production' || process.env.EXPOSE_ERRORS === 'true';

  if (err instanceof AppError) {
    const response: ErrorResponse = {
      success: false,
      error: {
        message: err.message,
        code: err.code,
        statusCode: err.statusCode,
        details: err.details,
      },
    };
    res.status(err.statusCode).json(response);
    return;
  }

  if (err instanceof ZodError) {
    const fieldErrors = err.issues.map((e) => ({
      field: e.path.join('.'),
      message: e.message,
    }));

    const response: ErrorResponse = {
      success: false,
      error: {
        message: 'Validation failed',
        code: 'VALIDATION_ERROR',
        statusCode: 422,
        details: fieldErrors,
      },
    };
    res.status(422).json(response);
    return;
  }

  if (err instanceof multer.MulterError) {
    const response: ErrorResponse = {
      success: false,
      error: {
        message: err.message,
        code: 'UPLOAD_ERROR',
        statusCode: 400,
      },
    };
    res.status(400).json(response);
    return;
  }

  if (err.message === 'Not allowed by CORS') {
    const response: ErrorResponse = {
      success: false,
      error: {
        message: 'Origin not allowed by CORS policy',
        code: 'CORS_ERROR',
        statusCode: 403,
      },
    };
    res.status(403).json(response);
    return;
  }

  console.error('Unhandled error:', err);

  const response: ErrorResponse = {
    success: false,
    error: {
      message: isDev ? err.message : 'Internal server error',
      code: 'INTERNAL_ERROR',
      statusCode: 500,
      ...(isDev && { stack: err.stack }),
    },
  };
  res.status(500).json(response);
}

export function notFoundHandler(req: Request, _res: Response, next: NextFunction): void {
  const err = new AppError(
    `Route ${req.method} ${req.originalUrl} not found`,
    404,
    'NOT_FOUND'
  );
  next(err);
}
