import { Request, Response, NextFunction } from 'express';
import { createApiKey, listApiKeys, revokeApiKey } from '../services/apiKeyService';
import { inviteCollaborator, acceptInvite, listCollaborators, revokeCollaborator } from '../services/collaboratorService';
import { listPlaybookFlags } from '../services/playbookService';
import { NotFoundError, BadRequestError } from '../utils/errors';

export async function createUserApiKey(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const name = String(req.body?.name || 'default');
    const created = await createApiKey(req.user.id, name);
    res.status(201).json({ success: true, data: created });
  } catch (err) { next(err); }
}

export async function listUserApiKeys(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    res.json({ success: true, data: { keys: await listApiKeys(req.user.id) } });
  } catch (err) { next(err); }
}

export async function revokeUserApiKey(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    await revokeApiKey(req.user.id, Number(req.params.id));
    res.json({ success: true, data: { revoked: true, id: Number(req.params.id) } });
  } catch (err) { next(err); }
}

export async function inviteDocumentCollaborator(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const documentId = Number(req.params.id);
    const email = String(req.body?.email || '');
    const role = (req.body?.role === 'commenter' ? 'commenter' : 'viewer') as 'viewer' | 'commenter';
    const invite = await inviteCollaborator(documentId, req.user.id, email, role);
    res.status(201).json({ success: true, data: invite });
  } catch (err) { next(err); }
}

export async function listDocumentCollaborators(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const rows = await listCollaborators(Number(req.params.id), req.user.id);
    res.json({ success: true, data: { collaborators: rows } });
  } catch (err) { next(err); }
}

export async function revokeDocumentCollaborator(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    await revokeCollaborator(Number(req.params.id), req.user.id, Number(req.params.collabId));
    res.json({ success: true, data: { revoked: true } });
  } catch (err) { next(err); }
}

export async function acceptCollaboratorInvite(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const token = String(req.body?.token || req.query.token || '');
    if (!token) throw new BadRequestError('token is required');
    const result = await acceptInvite(token, req.user.id, req.user.email);
    res.json({ success: true, data: result });
  } catch (err) { next(err); }
}

export async function getPlaybookFlagsForDocument(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const documentId = Number(req.params.documentId);
    const flags = await listPlaybookFlags(documentId);
    res.json({ success: true, data: { flags } });
  } catch (err) { next(err); }
}
