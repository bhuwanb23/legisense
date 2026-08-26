import crypto from 'crypto';
import { getDb, persistNow } from '../config/database';
import { documentCollaborators, documents, users } from '../models';
import { sql } from 'drizzle-orm';
import { BadRequestError, NotFoundError, ForbiddenError } from '../utils/errors';
import { createNotification } from './notificationService';

export type CollabRole = 'viewer' | 'commenter';

export async function inviteCollaborator(
  documentId: number,
  ownerId: number,
  email: string,
  role: CollabRole = 'viewer',
): Promise<{ token: string; inviteUrl: string; email: string; role: string }> {
  const db = getDb();
  const doc = (await db.select().from(documents).where(
    sql`${documents.id} = ${documentId} AND ${documents.userId} = ${ownerId} AND ${documents.isDeleted} = FALSE`
  ))[0];
  if (!doc) throw new NotFoundError('Document');
  const clean = email.trim().toLowerCase();
  if (!clean.includes('@')) throw new BadRequestError('Valid email is required');
  if (!['viewer', 'commenter'].includes(role)) throw new BadRequestError('role must be viewer or commenter');

  const existing = (await db.select().from(documentCollaborators).where(
    sql`${documentCollaborators.documentId} = ${documentId} AND ${documentCollaborators.email} = ${clean} AND ${documentCollaborators.status} != 'revoked'`
  ))[0];
  if (existing) {
    return {
      token: existing.token,
      inviteUrl: `/api/collaborators/accept?token=${existing.token}`,
      email: clean,
      role: existing.role,
    };
  }

  const token = crypto.randomBytes(16).toString('hex');
  const invitee = (await db.select().from(users).where(sql`${users.email} = ${clean}`))[0];
  await db.insert(documentCollaborators).values({
    documentId,
    invitedBy: ownerId,
    email: clean,
    userId: invitee?.id ?? null,
    role,
    token,
    status: 'pending',
  });
  persistNow();
  if (invitee) {
    createNotification(
      invitee.id,
      'workspace_invite',
      'Document shared with you',
      `You were invited to "${doc.originalName}" as ${role}.`,
      documentId,
    );
  }
  return {
    token,
    inviteUrl: `/api/collaborators/accept?token=${token}`,
    email: clean,
    role,
  };
}

export async function acceptInvite(token: string, userId: number, email: string): Promise<{ documentId: number; role: string }> {
  const db = getDb();
  const row = (await db.select().from(documentCollaborators).where(
    sql`${documentCollaborators.token} = ${token}`
  ))[0];
  if (!row || row.status === 'revoked') throw new NotFoundError('Invite');
  if (row.email.toLowerCase() !== email.toLowerCase()) {
    throw new ForbiddenError('Invite email does not match this account');
  }
  await db.execute(sql`UPDATE ${documentCollaborators} SET status = 'accepted', user_id = ${userId} WHERE id = ${row.id}`);
  persistNow();
  return { documentId: row.documentId, role: row.role };
}

export async function listCollaborators(documentId: number, ownerId: number) {
  const db = getDb();
  const doc = (await db.select().from(documents).where(
    sql`${documents.id} = ${documentId} AND ${documents.userId} = ${ownerId}`
  ))[0];
  if (!doc) throw new NotFoundError('Document');
  return await db.select().from(documentCollaborators).where(
    sql`${documentCollaborators.documentId} = ${documentId} AND ${documentCollaborators.status} != 'revoked'`
  );
}

export async function revokeCollaborator(documentId: number, ownerId: number, collabId: number): Promise<void> {
  const db = getDb();
  const doc = (await db.select().from(documents).where(
    sql`${documents.id} = ${documentId} AND ${documents.userId} = ${ownerId}`
  ))[0];
  if (!doc) throw new NotFoundError('Document');
  const row = (await db.select().from(documentCollaborators).where(
    sql`${documentCollaborators.id} = ${collabId} AND ${documentCollaborators.documentId} = ${documentId}`
  ))[0];
  if (!row) throw new NotFoundError('Collaborator');
  await db.execute(sql`UPDATE ${documentCollaborators} SET status = 'revoked' WHERE id = ${collabId}`);
  persistNow();
}

export type AccessRole = 'owner' | 'viewer' | 'commenter';

export async function getDocumentAccess(userId: number, documentId: number): Promise<{ role: AccessRole } | null> {
  const db = getDb();
  const owned = (await db.select().from(documents).where(
    sql`${documents.id} = ${documentId} AND ${documents.userId} = ${userId} AND ${documents.isDeleted} = FALSE`
  ))[0];
  if (owned) return { role: 'owner' };
  const collab = (await db.select().from(documentCollaborators).where(
    sql`${documentCollaborators.documentId} = ${documentId}
        AND ${documentCollaborators.userId} = ${userId}
        AND ${documentCollaborators.status} = 'accepted'`
  ))[0];
  if (!collab) return null;
  return { role: collab.role === 'commenter' ? 'commenter' : 'viewer' };
}
