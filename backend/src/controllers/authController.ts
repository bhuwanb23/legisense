import { Request, Response, NextFunction } from 'express';
import bcrypt from 'bcrypt';
import { getDb } from '../config/database';
import { users, sessions } from '../models';
import { sql } from 'drizzle-orm';
import {
  generateToken,
  generateRefreshToken,
  verifyToken,
} from '../middleware/auth';
import {
  BadRequestError,
  UnauthorizedError,
  ConflictError,
  NotFoundError,
} from '../utils/errors';
import { persistNow } from '../config/database';

const BCRYPT_ROUNDS = 12;

export async function register(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { fullName, email, password, phoneNumber, profession } = req.body;

    const db = getDb();

    const existing = db
      .select({ id: users.id })
      .from(users)
      .where(sql`${users.email} = ${email}`)
      .all();

    if (existing.length > 0) {
      throw new ConflictError('Email already registered');
    }

    const passwordHash = await bcrypt.hash(password, BCRYPT_ROUNDS);

    db.insert(users)
      .values({
        fullName,
        email,
        passwordHash,
        phoneNumber: phoneNumber || null,
        profession: profession || null,
        authProvider: 'email',
        isVerified: false,
        isActive: true,
      })
      .run();

    const userRows = db
      .select({ id: users.id, email: users.email })
      .from(users)
      .where(sql`${users.email} = ${email}`)
      .all();

    const user = userRows[0];
    if (!user) throw new Error('Failed to create user');

    const tokenPayload = { userId: user.id, email: user.email };
    const accessToken = generateToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    const thirtyDays = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    db.insert(sessions)
      .values({
        userId: user.id,
        refreshToken,
        deviceInfo: req.headers['user-agent'] || null,
        ipAddress: req.ip || null,
        expiresAt: thirtyDays.toISOString(),
        isRevoked: false,
      })
      .run();

    db.run(
      sql`UPDATE ${users} SET last_login_at = datetime('now') WHERE id = ${user.id}`
    );

    persistNow();

    res.status(201).json({
      success: true,
      data: {
        user: { id: user.id, email: user.email, fullName },
        accessToken,
        refreshToken,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function login(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { email, password } = req.body;

    const db = getDb();

    const userRows = db
      .select()
      .from(users)
      .where(sql`${users.email} = ${email}`)
      .all();

    const user = userRows[0];

    if (!user || !user.passwordHash) {
      throw new UnauthorizedError('Invalid email or password');
    }

    if (!user.isActive) {
      throw new UnauthorizedError('Account is deactivated', 'ACCOUNT_DEACTIVATED');
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedError('Invalid email or password');
    }

    const tokenPayload = { userId: user.id, email: user.email };
    const accessToken = generateToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    const thirtyDays = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    db.insert(sessions)
      .values({
        userId: user.id,
        refreshToken,
        deviceInfo: req.headers['user-agent'] || null,
        ipAddress: req.ip || null,
        expiresAt: thirtyDays.toISOString(),
        isRevoked: false,
      })
      .run();

    db.run(
      sql`UPDATE ${users} SET last_login_at = datetime('now') WHERE id = ${user.id}`
    );

    persistNow();

    res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          fullName: user.fullName,
        },
        accessToken,
        refreshToken,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function logout(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 },
      });
      return;
    }

    const { refreshToken } = req.body;
    const db = getDb();

    if (refreshToken) {
      db.run(
        sql`UPDATE ${sessions} SET is_revoked = 1 WHERE refresh_token = ${refreshToken} AND user_id = ${req.user.id}`
      );
    } else {
      db.run(
        sql`UPDATE ${sessions} SET is_revoked = 1 WHERE user_id = ${req.user.id}`
      );
    }

    persistNow();

    res.json({ success: true, data: { message: 'Logged out successfully' } });
  } catch (err) {
    next(err);
  }
}

export async function refreshToken(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { refreshToken: token } = req.body;

    let decoded;
    try {
      decoded = verifyToken(token);
    } catch {
      throw new UnauthorizedError('Invalid or expired refresh token');
    }

    const db = getDb();

    const sessionRows = db
      .select()
      .from(sessions)
      .where(
        sql`${sessions.refreshToken} = ${token} AND ${sessions.isRevoked} = 0`
      )
      .all();

    const session = sessionRows[0];
    if (!session) {
      throw new UnauthorizedError('Refresh token has been revoked');
    }

    if (new Date(session.expiresAt) < new Date()) {
      throw new UnauthorizedError('Refresh token has expired');
    }

    db.run(
      sql`UPDATE ${sessions} SET is_revoked = 1 WHERE id = ${session.id}`
    );

    const userRows = db
      .select({ id: users.id, email: users.email, isActive: users.isActive })
      .from(users)
      .where(sql`${users.id} = ${decoded.userId}`)
      .all();

    const user = userRows[0];
    if (!user || !user.isActive) {
      throw new UnauthorizedError('User not found or deactivated');
    }

    const tokenPayload = { userId: user.id, email: user.email };
    const newAccessToken = generateToken(tokenPayload);
    const newRefreshToken = generateRefreshToken(tokenPayload);

    const thirtyDays = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    db.insert(sessions)
      .values({
        userId: user.id,
        refreshToken: newRefreshToken,
        deviceInfo: req.headers['user-agent'] || null,
        ipAddress: req.ip || null,
        expiresAt: thirtyDays.toISOString(),
        isRevoked: false,
      })
      .run();

    persistNow();

    res.json({
      success: true,
      data: {
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function forgotPassword(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { email } = req.body;

    const db = getDb();
    const userRows = db
      .select({ id: users.id })
      .from(users)
      .where(sql`${users.email} = ${email}`)
      .all();

    // Always return success to prevent email enumeration
    if (userRows.length === 0) {
      res.json({
        success: true,
        data: { message: 'If an account exists, a reset link has been sent' },
      });
      return;
    }

    const resetToken = generateToken({
      userId: userRows[0].id,
      email,
    });

    // TODO: Send email with reset link (needs email service integration)
    // For now, return the token directly (dev mode only)
    const isDev = process.env.NODE_ENV !== 'production';

    res.json({
      success: true,
      data: {
        message: 'If an account exists, a reset link has been sent',
        ...(isDev && { resetToken }),
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function resetPassword(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { token, newPassword } = req.body;

    let decoded;
    try {
      decoded = verifyToken(token);
    } catch {
      throw new BadRequestError('Invalid or expired reset token');
    }

    const db = getDb();

    const userRows = db
      .select({ id: users.id })
      .from(users)
      .where(sql`${users.id} = ${decoded.userId}`)
      .all();

    if (userRows.length === 0) {
      throw new NotFoundError('User');
    }

    const passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);

    db.run(
      sql`UPDATE ${users} SET password_hash = ${passwordHash}, updated_at = datetime('now') WHERE id = ${decoded.userId}`
    );

    // Revoke all sessions for this user
    db.run(
      sql`UPDATE ${sessions} SET is_revoked = 1 WHERE user_id = ${decoded.userId}`
    );

    persistNow();

    res.json({
      success: true,
      data: { message: 'Password reset successfully. Please log in again.' },
    });
  } catch (err) {
    next(err);
  }
}

async function verifyGoogleToken(idToken: string): Promise<{ email: string; name: string; sub: string }> {
  try {
    const response = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`);
    if (!response.ok) {
      throw new Error('Invalid token');
    }
    const data = (await response.json()) as { email?: string; name?: string; sub?: string };
    if (!data.email) throw new Error('No email in token');
    return {
      email: data.email,
      name: data.name || data.email.split('@')[0],
      sub: data.sub || '',
    };
  } catch (err) {
    throw new UnauthorizedError('Failed to verify Google token');
  }
}

async function verifyFacebookToken(accessToken: string): Promise<{ email: string; name: string; id: string }> {
  try {
    const response = await fetch(`https://graph.facebook.com/me?fields=id,name,email&access_token=${accessToken}`);
    if (!response.ok) {
      throw new Error('Invalid token');
    }
    const data = (await response.json()) as { id?: string; name?: string; email?: string };
    if (!data.email) throw new Error('No email in response');
    return {
      email: data.email,
      name: data.name || 'User',
      id: data.id || '',
    };
  } catch (err) {
    throw new UnauthorizedError('Failed to verify Facebook token');
  }
}

export async function oauthGoogle(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      throw new BadRequestError('idToken is required');
    }

    const googleUser = await verifyGoogleToken(idToken);
    const db = getDb();

    let userRows = db
      .select()
      .from(users)
      .where(sql`${users.email} = ${googleUser.email}`)
      .all();

    let user = userRows[0];

    if (!user) {
      db.insert(users)
        .values({
          email: googleUser.email,
          fullName: googleUser.name,
          authProvider: 'google',
          oauthSubject: googleUser.sub,
          passwordHash: null,
          isVerified: true,
          isActive: true,
        })
        .run();

      userRows = db
        .select()
        .from(users)
        .where(sql`${users.email} = ${googleUser.email}`)
        .all();

      user = userRows[0];
      if (!user) throw new Error('Failed to create user');
    } else if (user.authProvider === 'email') {
      db.run(sql`UPDATE ${users} SET oauth_subject = ${googleUser.sub}, auth_provider = 'google' WHERE id = ${user.id}`);
    }

    const tokenPayload = { userId: user.id, email: user.email };
    const accessToken = generateToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    const thirtyDays = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    db.insert(sessions)
      .values({
        userId: user.id,
        refreshToken,
        deviceInfo: req.headers['user-agent'] || null,
        ipAddress: req.ip || null,
        expiresAt: thirtyDays.toISOString(),
        isRevoked: false,
      })
      .run();

    db.run(sql`UPDATE ${users} SET last_login_at = datetime('now') WHERE id = ${user.id}`);

    persistNow();

    res.json({
      success: true,
      data: {
        user: { id: user.id, email: user.email, fullName: user.fullName },
        accessToken,
        refreshToken,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function oauthFacebook(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { accessToken } = req.body;

    if (!accessToken) {
      throw new BadRequestError('accessToken is required');
    }

    const fbUser = await verifyFacebookToken(accessToken);
    const db = getDb();

    let userRows = db
      .select()
      .from(users)
      .where(sql`${users.email} = ${fbUser.email}`)
      .all();

    let user = userRows[0];

    if (!user) {
      db.insert(users)
        .values({
          email: fbUser.email,
          fullName: fbUser.name,
          authProvider: 'facebook',
          oauthSubject: fbUser.id,
          passwordHash: null,
          isVerified: true,
          isActive: true,
        })
        .run();

      userRows = db
        .select()
        .from(users)
        .where(sql`${users.email} = ${fbUser.email}`)
        .all();

      user = userRows[0];
      if (!user) throw new Error('Failed to create user');
    } else if (user.authProvider === 'email') {
      db.run(sql`UPDATE ${users} SET oauth_subject = ${fbUser.id}, auth_provider = 'facebook' WHERE id = ${user.id}`);
    }

    const tokenPayload = { userId: user.id, email: user.email };
    const accessToken_jwt = generateToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    const thirtyDays = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    db.insert(sessions)
      .values({
        userId: user.id,
        refreshToken,
        deviceInfo: req.headers['user-agent'] || null,
        ipAddress: req.ip || null,
        expiresAt: thirtyDays.toISOString(),
        isRevoked: false,
      })
      .run();

    db.run(sql`UPDATE ${users} SET last_login_at = datetime('now') WHERE id = ${user.id}`);

    persistNow();

    res.json({
      success: true,
      data: {
        user: { id: user.id, email: user.email, fullName: user.fullName },
        accessToken: accessToken_jwt,
        refreshToken,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function register(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { fullName, email, password, phoneNumber, profession } = req.body;

    const db = getDb();

    const existing = db
      .select({ id: users.id })
      .from(users)
      .where(sql`${users.email} = ${email}`)
      .all();

    if (existing.length > 0) {
      throw new ConflictError('Email already registered');
    }

    const passwordHash = await bcrypt.hash(password, BCRYPT_ROUNDS);

    db.insert(users)
      .values({
        fullName,
        email,
        passwordHash,
        phoneNumber: phoneNumber || null,
        profession: profession || null,
        authProvider: 'email',
        isVerified: false,
        isActive: true,
      })
      .run();

    const userRows = db
      .select({ id: users.id, email: users.email })
      .from(users)
      .where(sql`${users.email} = ${email}`)
      .all();

    const user = userRows[0];
    if (!user) throw new Error('Failed to create user');

    const tokenPayload = { userId: user.id, email: user.email };
    const accessToken = generateToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    const thirtyDays = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    db.insert(sessions)
      .values({
        userId: user.id,
        refreshToken,
        deviceInfo: req.headers['user-agent'] || null,
        ipAddress: req.ip || null,
        expiresAt: thirtyDays.toISOString(),
        isRevoked: false,
      })
      .run();

    db.run(
      sql`UPDATE ${users} SET last_login_at = datetime('now') WHERE id = ${user.id}`
    );

    persistNow();

    res.status(201).json({
      success: true,
      data: {
        user: { id: user.id, email: user.email, fullName },
        accessToken,
        refreshToken,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function login(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { email, password } = req.body;

    const db = getDb();

    const userRows = db
      .select()
      .from(users)
      .where(sql`${users.email} = ${email}`)
      .all();

    const user = userRows[0];

    if (!user || !user.passwordHash) {
      throw new UnauthorizedError('Invalid email or password');
    }

    if (!user.isActive) {
      throw new UnauthorizedError('Account is deactivated', 'ACCOUNT_DEACTIVATED');
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedError('Invalid email or password');
    }

    const tokenPayload = { userId: user.id, email: user.email };
    const accessToken = generateToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    const thirtyDays = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    db.insert(sessions)
      .values({
        userId: user.id,
        refreshToken,
        deviceInfo: req.headers['user-agent'] || null,
        ipAddress: req.ip || null,
        expiresAt: thirtyDays.toISOString(),
        isRevoked: false,
      })
      .run();

    db.run(
      sql`UPDATE ${users} SET last_login_at = datetime('now') WHERE id = ${user.id}`
    );

    persistNow();

    res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          fullName: user.fullName,
        },
        accessToken,
        refreshToken,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function logout(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 },
      });
      return;
    }

    const { refreshToken } = req.body;
    const db = getDb();

    if (refreshToken) {
      db.run(
        sql`UPDATE ${sessions} SET is_revoked = 1 WHERE refresh_token = ${refreshToken} AND user_id = ${req.user.id}`
      );
    } else {
      db.run(
        sql`UPDATE ${sessions} SET is_revoked = 1 WHERE user_id = ${req.user.id}`
      );
    }

    persistNow();

    res.json({ success: true, data: { message: 'Logged out successfully' } });
  } catch (err) {
    next(err);
  }
}

export async function refreshToken(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { refreshToken: token } = req.body;

    let decoded;
    try {
      decoded = verifyToken(token);
    } catch {
      throw new UnauthorizedError('Invalid or expired refresh token');
    }

    const db = getDb();

    const sessionRows = db
      .select()
      .from(sessions)
      .where(
        sql`${sessions.refreshToken} = ${token} AND ${sessions.isRevoked} = 0`
      )
      .all();

    const session = sessionRows[0];
    if (!session) {
      throw new UnauthorizedError('Refresh token has been revoked');
    }

    if (new Date(session.expiresAt) < new Date()) {
      throw new UnauthorizedError('Refresh token has expired');
    }

    db.run(
      sql`UPDATE ${sessions} SET is_revoked = 1 WHERE id = ${session.id}`
    );

    const userRows = db
      .select({ id: users.id, email: users.email, isActive: users.isActive })
      .from(users)
      .where(sql`${users.id} = ${decoded.userId}`)
      .all();

    const user = userRows[0];
    if (!user || !user.isActive) {
      throw new UnauthorizedError('User not found or deactivated');
    }

    const tokenPayload = { userId: user.id, email: user.email };
    const newAccessToken = generateToken(tokenPayload);
    const newRefreshToken = generateRefreshToken(tokenPayload);

    const thirtyDays = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    db.insert(sessions)
      .values({
        userId: user.id,
        refreshToken: newRefreshToken,
        deviceInfo: req.headers['user-agent'] || null,
        ipAddress: req.ip || null,
        expiresAt: thirtyDays.toISOString(),
        isRevoked: false,
      })
      .run();

    persistNow();

    res.json({
      success: true,
      data: {
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function forgotPassword(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { email } = req.body;

    const db = getDb();
    const userRows = db
      .select({ id: users.id })
      .from(users)
      .where(sql`${users.email} = ${email}`)
      .all();

    // Always return success to prevent email enumeration
    if (userRows.length === 0) {
      res.json({
        success: true,
        data: { message: 'If an account exists, a reset link has been sent' },
      });
      return;
    }

    const resetToken = generateToken({
      userId: userRows[0].id,
      email,
    });

    // TODO: Send email with reset link (needs email service integration)
    // For now, return the token directly (dev mode only)
    const isDev = process.env.NODE_ENV !== 'production';

    res.json({
      success: true,
      data: {
        message: 'If an account exists, a reset link has been sent',
        ...(isDev && { resetToken }),
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function resetPassword(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { token, newPassword } = req.body;

    let decoded;
    try {
      decoded = verifyToken(token);
    } catch {
      throw new BadRequestError('Invalid or expired reset token');
    }

    const db = getDb();

    const userRows = db
      .select({ id: users.id })
      .from(users)
      .where(sql`${users.id} = ${decoded.userId}`)
      .all();

    if (userRows.length === 0) {
      throw new NotFoundError('User');
    }

    const passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);

    db.run(
      sql`UPDATE ${users} SET password_hash = ${passwordHash}, updated_at = datetime('now') WHERE id = ${decoded.userId}`
    );

    // Revoke all sessions for this user
    db.run(
      sql`UPDATE ${sessions} SET is_revoked = 1 WHERE user_id = ${decoded.userId}`
    );

    persistNow();

    res.json({
      success: true,
      data: { message: 'Password reset successfully. Please log in again.' },
    });
  } catch (err) {
    next(err);
  }
}

async function verifyGoogleToken(idToken: string): Promise<{ email: string; name: string; sub: string }> {
  try {
    const response = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`);
    if (!response.ok) {
      throw new Error('Invalid token');
    }
    const data = (await response.json()) as { email?: string; name?: string; sub?: string };
    if (!data.email) throw new Error('No email in token');
    return {
      email: data.email,
      name: data.name || data.email.split('@')[0],
      sub: data.sub || '',
    };
  } catch (err) {
    throw new UnauthorizedError('Failed to verify Google token');
  }
}

async function verifyFacebookToken(accessToken: string): Promise<{ email: string; name: string; id: string }> {
  try {
    const response = await fetch(`https://graph.facebook.com/me?fields=id,name,email&access_token=${accessToken}`);
    if (!response.ok) {
      throw new Error('Invalid token');
    }
    const data = (await response.json()) as { id?: string; name?: string; email?: string };
    if (!data.email) throw new Error('No email in response');
    return {
      email: data.email,
      name: data.name || 'User',
      id: data.id || '',
    };
  } catch (err) {
    throw new UnauthorizedError('Failed to verify Facebook token');
  }
}

export async function oauthGoogle(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      throw new BadRequestError('idToken is required');
    }

    const googleUser = await verifyGoogleToken(idToken);
    const db = getDb();

    let userRows = db
      .select()
      .from(users)
      .where(sql`${users.email} = ${googleUser.email}`)
      .all();

    let user = userRows[0];

    if (!user) {
      db.insert(users)
        .values({
          email: googleUser.email,
          fullName: googleUser.name,
          authProvider: 'google',
          oauthSubject: googleUser.sub,
          passwordHash: null,
          isVerified: true,
          isActive: true,
        })
        .run();

      userRows = db
        .select()
        .from(users)
        .where(sql`${users.email} = ${googleUser.email}`)
        .all();

      user = userRows[0];
      if (!user) throw new Error('Failed to create user');
    } else if (user.authProvider === 'email') {
      db.run(sql`UPDATE ${users} SET oauth_subject = ${googleUser.sub}, auth_provider = 'google' WHERE id = ${user.id}`);
    }

    const tokenPayload = { userId: user.id, email: user.email };
    const accessToken = generateToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    const thirtyDays = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    db.insert(sessions)
      .values({
        userId: user.id,
        refreshToken,
        deviceInfo: req.headers['user-agent'] || null,
        ipAddress: req.ip || null,
        expiresAt: thirtyDays.toISOString(),
        isRevoked: false,
      })
      .run();

    db.run(sql`UPDATE ${users} SET last_login_at = datetime('now') WHERE id = ${user.id}`);

    persistNow();

    res.json({
      success: true,
      data: {
        user: { id: user.id, email: user.email, fullName: user.fullName },
        accessToken,
        refreshToken,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function oauthFacebook(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { accessToken } = req.body;

    if (!accessToken) {
      throw new BadRequestError('accessToken is required');
    }

    const fbUser = await verifyFacebookToken(accessToken);
    const db = getDb();

    let userRows = db
      .select()
      .from(users)
      .where(sql`${users.email} = ${fbUser.email}`)
      .all();

    let user = userRows[0];

    if (!user) {
      db.insert(users)
        .values({
          email: fbUser.email,
          fullName: fbUser.name,
          authProvider: 'facebook',
          oauthSubject: fbUser.id,
          passwordHash: null,
          isVerified: true,
          isActive: true,
        })
        .run();

      userRows = db
        .select()
        .from(users)
        .where(sql`${users.email} = ${fbUser.email}`)
        .all();

      user = userRows[0];
      if (!user) throw new Error('Failed to create user');
    } else if (user.authProvider === 'email') {
      db.run(sql`UPDATE ${users} SET oauth_subject = ${fbUser.id}, auth_provider = 'facebook' WHERE id = ${user.id}`);
    }

    const tokenPayload = { userId: user.id, email: user.email };
    const accessToken_jwt = generateToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    const thirtyDays = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    db.insert(sessions)
      .values({
        userId: user.id,
        refreshToken,
        deviceInfo: req.headers['user-agent'] || null,
        ipAddress: req.ip || null,
        expiresAt: thirtyDays.toISOString(),
        isRevoked: false,
      })
      .run();

    db.run(sql`UPDATE ${users} SET last_login_at = datetime('now') WHERE id = ${user.id}`);

    persistNow();

    res.json({
      success: true,
      data: {
        user: { id: user.id, email: user.email, fullName: user.fullName },
        accessToken: accessToken_jwt,
        refreshToken,
      },
    });
  } catch (err) {
    next(err);
  }
}
