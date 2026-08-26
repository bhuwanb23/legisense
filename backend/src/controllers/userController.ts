import { Request, Response, NextFunction } from 'express';
import { getDb } from '../config/database';
import { users, sessions } from '../models';
import { sql, eq } from 'drizzle-orm';
import { NotFoundError } from '../utils/errors';
import { persistNow } from '../config/database';
import path from 'path';
import fs from 'fs/promises';
import { v4 as uuidv4 } from 'uuid';

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
        nickname: users.nickname,
        preferredDocumentTypes: users.preferredDocumentTypes,
        preferredLanguage: users.preferredLanguage,
        defaultJurisdiction: users.defaultJurisdiction,
        isVerified: users.isVerified,
        createdAt: users.createdAt,
        lastLoginAt: users.lastLoginAt,
      })
      .from(users)
      .where(sql`${users.id} = ${req.user.id}`);

    const user = rows[0];
    if (!user) throw new NotFoundError('User');

    const userData = {
      ...user,
      preferredDocumentTypes: user.preferredDocumentTypes ? JSON.parse(user.preferredDocumentTypes) : [],
    };

    res.json({ success: true, data: userData });
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
      .where(eq(users.id, req.user.id));

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
      .where(sql`${users.id} = ${req.user.id}`);

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
    const { preferredLanguage, defaultJurisdiction, nickname, preferredDocumentTypes } = req.body;

    if (preferredLanguage !== undefined) updates.preferredLanguage = preferredLanguage;
    if (defaultJurisdiction !== undefined) updates.defaultJurisdiction = defaultJurisdiction;
    if (nickname !== undefined) updates.nickname = nickname;
    if (preferredDocumentTypes !== undefined) updates.preferredDocumentTypes = JSON.stringify(preferredDocumentTypes);

    if (Object.keys(updates).length === 0) {
      res.json({ success: true, data: { message: 'No changes to update' } });
      return;
    }

    const db = getDb();
    db.update(users)
      .set(updates)
      .where(eq(users.id, req.user.id));

    persistNow();

    const rows = db
      .select({
        id: users.id,
        preferredLanguage: users.preferredLanguage,
        defaultJurisdiction: users.defaultJurisdiction,
        nickname: users.nickname,
        preferredDocumentTypes: users.preferredDocumentTypes,
      })
      .from(users)
      .where(sql`${users.id} = ${req.user.id}`);

    const result = rows[0];
    const data = {
      ...result,
      preferredDocumentTypes: result.preferredDocumentTypes ? JSON.parse(result.preferredDocumentTypes) : [],
    };

    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

export async function uploadAvatar(
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

    const file = (req as any).file as Express.Multer.File | undefined;
    if (!file) {
      res.status(400).json({
        success: false,
        error: { message: 'No file uploaded', code: 'BAD_REQUEST', statusCode: 400 },
      });
      return;
    }

    const uploadsDir = path.join(process.cwd(), 'uploads', 'avatars');
    await fs.mkdir(uploadsDir, { recursive: true });

    const ext = path.extname(file.originalname).toLowerCase();
    const filename = `${req.user.id}-${Date.now()}${ext}`;
    const filePath = path.join(uploadsDir, filename);
    const relativeUrl = `/uploads/avatars/${filename}`;

    await fs.writeFile(filePath, file.buffer);

    const db = getDb();
    db.update(users)
      .set({ profilePhotoUrl: relativeUrl })
      .where(eq(users.id, req.user.id));

    persistNow();

    const rows = db
      .select({
        id: users.id,
        fullName: users.fullName,
        email: users.email,
        profilePhotoUrl: users.profilePhotoUrl,
        nickname: users.nickname,
        preferredDocumentTypes: users.preferredDocumentTypes,
      })
      .from(users)
      .where(sql`${users.id} = ${req.user.id}`);

    const userData = rows[0];
    const data = {
      ...userData,
      preferredDocumentTypes: userData.preferredDocumentTypes ? JSON.parse(userData.preferredDocumentTypes) : [],
    };

    res.json({ success: true, data });
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
      .where(eq(users.id, req.user.id));

    await db.execute(
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
