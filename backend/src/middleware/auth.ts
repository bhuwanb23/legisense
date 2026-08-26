import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { UnauthorizedError } from '../utils/errors';
import { getDb } from '../config/database';
import { users } from '../models';
import { sql } from 'drizzle-orm';
import { authenticateApiKey as lookupApiKey } from '../services/apiKeyService';

function getJwtConfig() {
  const secret = process.env.JWT_SECRET || '';
  if (!secret) throw new Error('JWT_SECRET is not set. Add a strong random key to your .env file.');
  if (secret === 'dev-secret-change-me' || secret === 'change-this-to-a-random-64-char-string') {
    console.warn('WARNING: Using insecure JWT_SECRET. Generate a strong random key for production.');
  }
  const access = Number(process.env.JWT_ACCESS_EXPIRES_IN) || 900;
  const refresh = Number(process.env.JWT_REFRESH_EXPIRES_IN) || 2592000;
  if (access <= 0) throw new Error('JWT_ACCESS_EXPIRES_IN must be a positive number');
  if (refresh <= 0) throw new Error('JWT_REFRESH_EXPIRES_IN must be a positive number');
  return { secret, access, refresh };
}

interface JwtPayload {
  userId: number;
  email: string;
}

export function authenticate(req: Request, _res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(new UnauthorizedError('Missing or invalid authorization header'));
  }

  const token = authHeader.split(' ')[1];

  try {
    const { secret } = getJwtConfig();
    const decoded = jwt.verify(token, secret) as JwtPayload;

    const db = getDb();
    const rows = db
      .select({
        id: users.id,
        email: users.email,
        fullName: users.fullName,
        authProvider: users.authProvider,
        isActive: users.isActive,
      })
      .from(users)
      .where(sql`${users.id} = ${decoded.userId}`);

    const user = rows[0];

    if (!user) {
      return next(new UnauthorizedError('User not found', 'USER_NOT_FOUND'));
    }

    if (!user.isActive) {
      return next(new UnauthorizedError('Account is deactivated', 'ACCOUNT_DEACTIVATED'));
    }

    req.user = {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      authProvider: user.authProvider,
      isActive: user.isActive,
    };

    next();
  } catch (err) {
    if (err instanceof jwt.TokenExpiredError) {
      return next(new UnauthorizedError('Token expired', 'TOKEN_EXPIRED'));
    }
    if (err instanceof jwt.JsonWebTokenError) {
      return next(new UnauthorizedError('Invalid token', 'INVALID_TOKEN'));
    }
    next(err);
  }
}

function attachApiKeyUser(req: Request, next: NextFunction, countUsage: boolean): void {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(new UnauthorizedError('Missing or invalid authorization header'));
  }
  const token = authHeader.split(' ')[1];
  try {
    const user = lookupApiKey(token, { countUsage });
    req.user = {
      id: user.id,
      email: user.email,
      fullName: user.fullName || '',
      authProvider: user.authProvider || 'email',
      isActive: user.isActive,
    };
    next();
  } catch (err) {
    next(err);
  }
}

export function authenticateApiKey(req: Request, _res: Response, next: NextFunction): void {
  attachApiKeyUser(req, next, true);
}

export function authenticateApiKeyRead(req: Request, _res: Response, next: NextFunction): void {
  attachApiKeyUser(req, next, false);
}

export function optionalAuth(req: Request, _res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }

  const token = authHeader.split(' ')[1];

  try {
    const { secret } = getJwtConfig();
    const decoded = jwt.verify(token, secret) as JwtPayload;

    const db = getDb();
    const rows = db
      .select({
        id: users.id,
        email: users.email,
        fullName: users.fullName,
        authProvider: users.authProvider,
        isActive: users.isActive,
      })
      .from(users)
      .where(sql`${users.id} = ${decoded.userId}`);

    const user = rows[0];

    if (user && user.isActive) {
      req.user = {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        authProvider: user.authProvider,
        isActive: user.isActive,
      };
    }
  } catch {
    // Token invalid — continue without user
  }

  next();
}

export function generateToken(payload: JwtPayload): string {
  const { secret, access } = getJwtConfig();
  return jwt.sign({ ...payload, jti: crypto.randomUUID() }, secret, {
    expiresIn: access,
  });
}

export function generateRefreshToken(payload: JwtPayload): string {
  const { secret, refresh } = getJwtConfig();
  return jwt.sign({ ...payload, jti: crypto.randomUUID() }, secret, {
    expiresIn: refresh,
  });
}

export function verifyToken(token: string): JwtPayload {
  const { secret } = getJwtConfig();
  return jwt.verify(token, secret) as JwtPayload;
}
