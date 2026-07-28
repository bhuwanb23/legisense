import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { UnauthorizedError } from '../utils/errors';
import { getDb } from '../config/database';
import { users } from '../models';
import { sql } from 'drizzle-orm';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';

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
    const decoded = jwt.verify(token, JWT_SECRET) as JwtPayload;

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
      .where(sql`${users.id} = ${decoded.userId}`)
      .all();

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

export function optionalAuth(req: Request, _res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as JwtPayload;

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
      .where(sql`${users.id} = ${decoded.userId}`)
      .all();

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
  return jwt.sign({ ...payload, jti: crypto.randomUUID() }, JWT_SECRET, {
    expiresIn: 7 * 24 * 60 * 60, // 7 days in seconds
  } as jwt.SignOptions);
}

export function generateRefreshToken(payload: JwtPayload): string {
  return jwt.sign({ ...payload, jti: crypto.randomUUID() }, JWT_SECRET, {
    expiresIn: 30 * 24 * 60 * 60, // 30 days in seconds
  } as jwt.SignOptions);
}

export function verifyToken(token: string): JwtPayload {
  return jwt.verify(token, JWT_SECRET) as JwtPayload;
}
