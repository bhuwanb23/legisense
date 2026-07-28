import { Request, Response, NextFunction } from 'express';
import { getDb } from '../config/database';
import { users, sessions } from '../models';
import { sql, eq } from 'drizzle-orm';
import { NotFoundError } from '../utils/errors';
import { persistNow } from '../config/database';

export async function getProfile(
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

    const db = getDb();
    const rows = db
      .select({
        id: users.id,
        fullName: users.fullName,
        email: users.email,
        phoneNumber: users.phoneNumber,
        authProvider: users.authProvider,
        profilePhotoUrl: users.profilePhotoUrl,
        profession: users.profession,
        preferredLanguage: users.preferredLanguage,
        defaultJurisdiction: users.defaultJurisdiction,
        isVerified: users.isVerified,
        createdAt: users.createdAt,
        lastLoginAt: users.lastLoginAt,
      })
      .from(users)
      .where(sql`${users.id} = ${req.user.id}`)
      .all();

    const user = rows[0];
    if (!user) throw new NotFoundError('User');

    res.json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
}

export async function updateProfile(
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

    const updates: Record<string, unknown> = {};
    const { fullName, phoneNumber, profession, profilePhotoUrl } = req.body;

    if (fullName !== undefined) updates.fullName = fullName;
    if (phoneNumber !== undefined) updates.phoneNumber = phoneNumber;
    if (profession !== undefined) updates.profession = profession;
    if (profilePhotoUrl !== undefined) updates.profilePhotoUrl = profilePhotoUrl;

    if (Object.keys(updates).length === 0) {
      res.json({ success: true, data: { message: 'No changes to update' } });
      return;
    }

    const db = getDb();
    db.update(users)
      .set(updates)
      .where(eq(users.id, req.user.id))
      .run();

    persistNow();

    const rows = db
      .select({
        id: users.id,
        fullName: users.fullName,
        email: users.email,
        phoneNumber: users.phoneNumber,
        profession: users.profession,
        profilePhotoUrl: users.profilePhotoUrl,
        updatedAt: users.updatedAt,
      })
      .from(users)
      .where(sql`${users.id} = ${req.user.id}`)
      .all();

    res.json({ success: true, data: rows[0] });
  } catch (err) {
    next(err);
  }
}

export async function updatePreferences(
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

    const updates: Record<string, unknown> = {};
    const { preferredLanguage, defaultJurisdiction } = req.body;

    if (preferredLanguage !== undefined) updates.preferredLanguage = preferredLanguage;
    if (defaultJurisdiction !== undefined) updates.defaultJurisdiction = defaultJurisdiction;

    if (Object.keys(updates).length === 0) {
      res.json({ success: true, data: { message: 'No changes to update' } });
      return;
    }

    const db = getDb();
    db.update(users)
      .set(updates)
      .where(eq(users.id, req.user.id))
      .run();

    persistNow();

    const rows = db
      .select({
        id: users.id,
        preferredLanguage: users.preferredLanguage,
        defaultJurisdiction: users.defaultJurisdiction,
      })
      .from(users)
      .where(sql`${users.id} = ${req.user.id}`)
      .all();

    res.json({ success: true, data: rows[0] });
  } catch (err) {
    next(err);
  }
}

export async function deleteAccount(
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

    const db = getDb();

    db.update(users)
      .set({ isActive: false })
      .where(eq(users.id, req.user.id))
      .run();

    db.run(
      sql`UPDATE ${sessions} SET is_revoked = 1 WHERE user_id = ${req.user.id}`
    );

    persistNow();

    res.json({
      success: true,
      data: { message: 'Account deactivated successfully' },
    });
  } catch (err) {
    next(err);
  }
}
