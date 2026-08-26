import { Request, Response, NextFunction } from 'express';
import crypto from 'crypto';
import { getDb, persistNow } from '../config/database';
import { documents, analysisResults, clauses, shareLinks, clauseNotes, playbookRules } from '../models';
import { sql } from 'drizzle-orm';
import { NotFoundError, BadRequestError, ForbiddenError } from '../utils/errors';
import { generateBetterVersion, compareDocuments, listTemplates, getTemplate, exportTemplate, compareDocumentToTemplate } from '../services/featureService';
import { getTypeEntry } from '../data/documentTypes';
import { getDocumentAccess } from '../services/collaboratorService';

/* ------------------------------ Favorites ------------------------------ */

export async function toggleFavorite(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const documentId = Number(req.params.id);
    const isFavorite = req.body?.isFavorite ?? req.body?.is_favorite;
    if (typeof isFavorite !== 'boolean' && isFavorite !== 0 && isFavorite !== 1) {
      throw new BadRequestError('isFavorite (boolean) is required');
    }
    const db = getDb();
    const rows = await db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id} AND ${documents.isDeleted} = 0`
    );
    if (!rows[0]) throw new NotFoundError('Document');

    await db.execute(sql`UPDATE ${documents} SET is_favorite = ${isFavorite ? 1 : 0}, updated_at = NOW() WHERE id = ${documentId}`);
    persistNow();
    res.json({ success: true, data: { documentId, isFavorite: Boolean(isFavorite) } });
  } catch (err) {
    next(err);
  }
}

/* ----------------------------- Share links ----------------------------- */

export async function createShareLink(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const documentId = Number(req.params.id);
    const db = getDb();

    const docRows = await db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id} AND ${documents.isDeleted} = 0`
    );
    if (!docRows[0]) throw new NotFoundError('Document');

    // Reuse an active link if one exists.
    const existing = await db.select().from(shareLinks).where(
      sql`${shareLinks.documentId} = ${documentId} AND ${shareLinks.userId} = ${req.user.id} AND ${shareLinks.isActive} = 1`
    );
    if (existing[0]) {
      res.json({ success: true, data: shareLinkPayload(existing[0], docRows[0]) });
      return;
    }

    const token = crypto.randomBytes(16).toString('hex');
    const expiresAt = req.body?.expiresInDays
      ? new Date(Date.now() + Number(req.body.expiresInDays) * 86400000).toISOString()
      : new Date(Date.now() + 7 * 86400000).toISOString();

    await db.insert(shareLinks).values({
      documentId,
      userId: req.user.id,
      token,
      isActive: true,
      views: 0,
      expiresAt,
    });
    persistNow();

    const rows = await db.select().from(shareLinks).where(sql`${shareLinks.token} = ${token}`);
    const link = rows[0];
    if (!link) throw new Error('Failed to create share link');

    res.status(201).json({ success: true, data: shareLinkPayload(link, docRows[0]) });
  } catch (err) {
    next(err);
  }
}

export async function revokeShareLink(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const documentId = Number(req.params.id);
    const db = getDb();
    const rows = await db.select().from(shareLinks).where(
      sql`${shareLinks.documentId} = ${documentId} AND ${shareLinks.userId} = ${req.user.id}`
    );
    if (rows.length === 0) throw new NotFoundError('Share link');

    await db.execute(sql`UPDATE ${shareLinks} SET is_active = 0 WHERE id = ${rows[0].id}`);
    persistNow();
    res.json({ success: true, data: { revoked: true, documentId } });
  } catch (err) {
    next(err);
  }
}

/** Public, unauthenticated view of a shared analysis. */
export async function getSharedAnalysis(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const token = req.params.token;
    const db = getDb();
    const rows = await db.select().from(shareLinks).where(sql`${shareLinks.token} = ${token}`);
    const link = rows[0];
    if (!link || !link.isActive) throw new NotFoundError('Share link');

    if (link.expiresAt && new Date(link.expiresAt) < new Date()) {
      await db.execute(sql`UPDATE ${shareLinks} SET is_active = 0 WHERE id = ${link.id}`);
      persistNow();
      throw new NotFoundError('Share link has expired');
    }

    const analysisRows = await db.select().from(analysisResults).where(
      sql`${analysisResults.documentId} = ${link.documentId}`
    );
    const analysis = analysisRows[0];
    const docRows = await db.select().from(documents).where(sql`${documents.id} = ${link.documentId}`);
    const doc = docRows[0];

    const clauseRows = analysis
      ? await db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysis.id}`)
      : [];

    await db.execute(sql`UPDATE ${shareLinks} SET views = views + 1 WHERE id = ${link.id}`);
    persistNow();

    const parse = (v: string | null) => {
      if (!v) return [];
      try { return JSON.parse(v); } catch { return []; }
    };

    res.json({
      success: true,
      data: {
        documentTitle: doc?.originalName || 'Document',
        sharedBy: link.userId,
        createdAt: link.createdAt,
        analysis: analysis ? {
          documentType: analysis.documentType,
          overallRiskScore: analysis.overallRiskScore,
          riskLevel: analysis.riskLevel,
          fairnessScore: analysis.fairnessScore,
          summary: analysis.summary,
          keyParties: parse(analysis.keyParties),
          criticalDates: parse(analysis.criticalDates),
          keyObligations: parse(analysis.keyObligations),
          missingClauses: parse(analysis.missingClauses),
        } : null,
        clauses: clauseRows.map((c) => ({
          clauseNumber: c.clauseNumber,
          clauseTitle: c.clauseTitle,
          originalText: c.originalText,
          plainEnglishText: c.plainEnglishText,
          riskLevel: c.riskLevel,
          riskScore: c.riskScore,
          riskReason: c.riskReason,
        })),
      },
    });
  } catch (err) {
    next(err);
  }
}

function shareLinkPayload(
  link: typeof shareLinks.$inferSelect,
  doc: typeof documents.$inferSelect,
) {
  return {
    token: link.token,
    url: `/api/shared/${link.token}`,
    fullUrl: `${process.env.PUBLIC_BASE_URL || 'http://localhost:3001'}/api/shared/${link.token}`,
    documentId: link.documentId,
    documentTitle: doc.originalName,
    isActive: link.isActive,
    views: link.views,
    expiresAt: link.expiresAt,
    createdAt: link.createdAt,
  };
}

/* ---------------------------- Clause notes ----------------------------- */

export async function listNotes(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const documentId = Number(req.params.documentId);
    if (!getDocumentAccess(req.user.id, documentId)) throw new NotFoundError('Document');
    const db = getDb();
    const rows = await db.select().from(clauseNotes).where(
      sql`${clauseNotes.documentId} = ${documentId}`
    );
    res.json({ success: true, data: { notes: rows } });
  } catch (err) {
    next(err);
  }
}

export async function addNote(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const documentId = Number(req.params.documentId);
    const clauseId = Number(req.params.clauseId);
    const note = String(req.body?.note || '').trim();
    if (!note) throw new BadRequestError('note is required');
    const access = getDocumentAccess(req.user.id, documentId);
    if (!access) throw new NotFoundError('Document');
    if (access.role === 'viewer') throw new ForbiddenError('Commenter role required to add notes');

    const db = getDb();
    const clauseRows = await db.select().from(clauses).where(
      sql`${clauses.id} = ${clauseId} AND ${clauses.documentId} = ${documentId}`
    );
    if (!clauseRows[0]) throw new NotFoundError('Clause');

    await db.insert(clauseNotes).values({
      clauseId,
      documentId,
      userId: req.user.id,
      note,
    });
    persistNow();

    const rows = await db.select().from(clauseNotes).where(
      sql`${clauseNotes.clauseId} = ${clauseId} AND ${clauseNotes.documentId} = ${documentId} AND ${clauseNotes.userId} = ${req.user.id}`
    );
    res.status(201).json({ success: true, data: rows[rows.length - 1] });
  } catch (err) {
    next(err);
  }
}

export async function updateNote(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const noteId = Number(req.params.noteId);
    const note = String(req.body?.note || '').trim();
    if (!note) throw new BadRequestError('note is required');

    const db = getDb();
    const rows = await db.select().from(clauseNotes).where(
      sql`${clauseNotes.id} = ${noteId} AND ${clauseNotes.userId} = ${req.user.id}`
    );
    if (!rows[0]) throw new NotFoundError('Note');

    await db.execute(sql`UPDATE ${clauseNotes} SET note = ${note}, updated_at = NOW() WHERE id = ${noteId}`);
    persistNow();
    const updated = await db.select().from(clauseNotes).where(sql`${clauseNotes.id} = ${noteId}`)[0];
    res.json({ success: true, data: updated });
  } catch (err) {
    next(err);
  }
}

export async function deleteNote(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const noteId = Number(req.params.noteId);
    const db = getDb();
    const rows = await db.select().from(clauseNotes).where(
      sql`${clauseNotes.id} = ${noteId} AND ${clauseNotes.userId} = ${req.user.id}`
    );
    if (!rows[0]) throw new NotFoundError('Note');
    await db.execute(sql`DELETE FROM ${clauseNotes} WHERE id = ${noteId}`);
    persistNow();
    res.json({ success: true, data: { deleted: true, id: noteId } });
  } catch (err) {
    next(err);
  }
}

/* ---------------------------- Playbook rules ---------------------------- */

export async function listRules(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const db = getDb();
    const rows = await db.select().from(playbookRules).where(
      sql`${playbookRules.userId} = ${req.user.id}`
    ).orderBy(sql`${playbookRules.createdAt} DESC`);
    res.json({ success: true, data: { rules: rows } });
  } catch (err) {
    next(err);
  }
}

export async function addRule(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const ruleText = String(req.body?.ruleText ?? req.body?.rule_text ?? '').trim();
    if (!ruleText) throw new BadRequestError('ruleText is required');
    const category = String(req.body?.category || 'general').trim() || 'general';

    const db = getDb();
    await db.insert(playbookRules).values({
      userId: req.user.id,
      ruleText,
      category,
      isActive: true,
    });
    persistNow();

    const rows = await db.select().from(playbookRules).where(
      sql`${playbookRules.userId} = ${req.user.id} AND ${playbookRules.ruleText} = ${ruleText}`
    );
    res.status(201).json({ success: true, data: rows[rows.length - 1] });
  } catch (err) {
    next(err);
  }
}

export async function updateRule(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const ruleId = Number(req.params.id);
    const db = getDb();
    const rows = await db.select().from(playbookRules).where(
      sql`${playbookRules.id} = ${ruleId} AND ${playbookRules.userId} = ${req.user.id}`
    );
    if (!rows[0]) throw new NotFoundError('Rule');

    const ruleText = req.body?.ruleText ?? req.body?.rule_text;
    const category = req.body?.category;
    const isActive = req.body?.isActive ?? req.body?.is_active;

    if (ruleText !== undefined) {
      const t = String(ruleText).trim();
      if (!t) throw new BadRequestError('ruleText cannot be empty');
      await db.execute(sql`UPDATE ${playbookRules} SET rule_text = ${t} WHERE id = ${ruleId}`);
    }
    if (category !== undefined) {
      await db.execute(sql`UPDATE ${playbookRules} SET category = ${String(category).trim() || 'general'} WHERE id = ${ruleId}`);
    }
    if (isActive !== undefined) {
      await db.execute(sql`UPDATE ${playbookRules} SET is_active = ${isActive ? 1 : 0} WHERE id = ${ruleId}`);
    }
    persistNow();
    const updated = await db.select().from(playbookRules).where(sql`${playbookRules.id} = ${ruleId}`)[0];
    res.json({ success: true, data: updated });
  } catch (err) {
    next(err);
  }
}

export async function deleteRule(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const ruleId = Number(req.params.id);
    const db = getDb();
    const rows = await db.select().from(playbookRules).where(
      sql`${playbookRules.id} = ${ruleId} AND ${playbookRules.userId} = ${req.user.id}`
    );
    if (!rows[0]) throw new NotFoundError('Rule');
    await db.execute(sql`DELETE FROM ${playbookRules} WHERE id = ${ruleId}`);
    persistNow();
    res.json({ success: true, data: { deleted: true, id: ruleId } });
  } catch (err) {
    next(err);
  }
}

/* --------------------------- Better version ----------------------------- */

export async function betterVersion(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const documentId = Number(req.params.documentId);
    const result = await generateBetterVersion(documentId, req.user.id);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

/* ------------------------------- Compare -------------------------------- */

export async function compare(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const documentIdA = Number(req.body?.documentIdA ?? req.body?.document_id_a);
    const documentIdB = Number(req.body?.documentIdB ?? req.body?.document_id_b);
    if (!documentIdA || !documentIdB || documentIdA === documentIdB) {
      throw new BadRequestError('documentIdA and documentIdB are required and must differ');
    }
    const result = await compareDocuments(documentIdA, documentIdB, req.user.id);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

/* ------------------------------ Templates ------------------------------- */

export async function templates(_req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    res.json({ success: true, data: { templates: listTemplates() } });
  } catch (err) {
    next(err);
  }
}

/* ------------------------- Confirm type by key -------------------------- */

export async function resolveType(_req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const type = String(_req.query.type || '');
    const entry = getTypeEntry(type);
    res.json({
      success: true,
      data: {
        type: entry.type,
        typeLabel: entry.typeLabel,
        icon: entry.icon,
        subTypes: entry.subTypes,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function getTemplateByType(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const type = String(req.params.type || '');
    const jurisdiction = req.query.jurisdiction ? String(req.query.jurisdiction) : undefined;
    const tpl = getTemplate(type, jurisdiction);
    if (!tpl) throw new NotFoundError('Template');
    res.json({ success: true, data: tpl });
  } catch (err) {
    next(err);
  }
}

export async function exportTemplateByType(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const type = String(req.params.type || '');
    const format = String(req.query.format || 'pdf').toLowerCase() === 'docx' ? 'docx' : 'pdf';
    const jurisdiction = req.query.jurisdiction ? String(req.query.jurisdiction) : undefined;
    const result = await exportTemplate(type, format, jurisdiction);
    res.setHeader('Content-Type', result.contentType);
    res.setHeader('Content-Disposition', `attachment; filename="${result.filename}"`);
    res.send(result.buffer);
  } catch (err) {
    next(err);
  }
}

export async function compareTemplate(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new NotFoundError('User');
    const documentId = Number(req.body?.documentId ?? req.body?.document_id);
    const type = String(req.body?.type || '');
    const jurisdiction = req.body?.jurisdiction ? String(req.body.jurisdiction) : undefined;
    if (!documentId || !type) throw new BadRequestError('documentId and type are required');
    const result = await compareDocumentToTemplate(documentId, type, req.user.id, jurisdiction);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}
