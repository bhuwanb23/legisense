import { Request, Response, NextFunction } from 'express';
import { getDb, persistNow } from '../config/database';
import { documents, chatMessages, clauses } from '../models';
import { sql } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import { NotFoundError, BadRequestError } from '../utils/errors';
import { retrieveRelevantClauses, chunkRawText } from '../services/chatRetrievalService';
import { resolveCitations } from '../services/citationParserService';
import { callWithFallback } from '../services/ai';
import { CHAT_SYSTEM_PROMPT, buildChatUserPrompt } from '../prompts/chatPrompt';
import { emitToUser } from '../services/socketService';

const NOT_FOUND_RESPONSE =
  'This question cannot be answered from the document. The available clauses do not contain enough information about this topic.';

export async function createChatSession(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const documentId = Number(req.params.documentId);
    const db = getDb();
    const docRows = db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id} AND ${documents.isDeleted} = 0`
    ).all();
    if (!docRows[0]) throw new NotFoundError('Document');

    const sessionId = uuidv4();
    res.status(201).json({
      success: true,
      data: { sessionId, documentId },
    });
  } catch (err) {
    next(err);
  }
}

export async function sendMessage(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const documentId = Number(req.params.documentId);
    const { message, sessionId } = req.body;

    if (!message || message.trim().length === 0) {
      throw new BadRequestError('Message cannot be empty');
    }

    const db = getDb();

    const docRows = db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id} AND ${documents.isDeleted} = 0`
    ).all();

    if (!docRows[0]) throw new NotFoundError('Document');

    const sessionIdFinal = sessionId || uuidv4();
    const userMessage = message.trim();

    db.insert(chatMessages).values({
      documentId,
      userId: req.user.id,
      sessionId: sessionIdFinal,
      role: 'user',
      message: userMessage,
    }).run();

    const historyRows = db.select().from(chatMessages).where(
      sql`${chatMessages.documentId} = ${documentId} AND ${chatMessages.sessionId} = ${sessionIdFinal}`
    ).all();

    const conversationHistory = historyRows
      .sort((a, b) => a.createdAt.localeCompare(b.createdAt))
      .map((m) => ({ role: m.role, message: m.message }));

    const clauseRows = db.select().from(clauses).where(
      sql`${clauses.documentId} = ${documentId}`
    ).all();

    let retrieved = retrieveRelevantClauses(userMessage, clauseRows, 5, 0.15);

    // Fallback: if no clauses, try raw text chunks as pseudo-context (no citations)
    if (retrieved.length === 0 && clauseRows.length === 0 && docRows[0].rawText) {
      const chunks = chunkRawText(docRows[0].rawText);
      retrieved = chunks.map((c, i) => ({
        id: -1 - i,
        clauseNumber: i + 1,
        clauseTitle: c.title,
        originalText: c.text,
        plainEnglishText: null,
        pageNumber: null,
        score: 0.2,
      })).slice(0, 5);
    }

    const startTime = Date.now();
    let responseText = NOT_FOUND_RESPONSE;
    let tokensUsed = 0;
    let citedClauses: ReturnType<typeof resolveCitations>['citedClauses'] = [];
    let citationConfidence: 'high' | 'low' = 'low';
    let citedClauseIds: number[] = [];
    let citedPages: Array<number | null> = [];
    const retrievedIds = retrieved.filter((r) => r.id > 0).map((r) => r.id);
    let responseTime = 0;

    try {
      if (retrieved.length === 0) {
        // keep not-found
      } else {
        const contextBlocks = retrieved.map((c) =>
          `Clause ${c.clauseNumber ?? '?'}: ${c.clauseTitle || 'Untitled'}\nPage: ${c.pageNumber ?? 'N/A'}\nText: ${c.originalText.slice(0, 700)}`
        ).join('\n\n');

        try {
          const { response } = await callWithFallback({
            systemPrompt: CHAT_SYSTEM_PROMPT,
            userPrompt: buildChatUserPrompt(
              contextBlocks,
              userMessage,
              conversationHistory.slice(0, -1),
            ),
            temperature: 0.3,
            expectJson: false,
          }, { task: 'chat' });

          responseText = response.text;
          tokensUsed = response.usage?.totalTokens || 0;
        } catch (err) {
          console.error('Chat AI failed:', err instanceof Error ? err.message : err);
          responseText = 'Sorry, I could not generate an answer right now. Please try again.';
        }

        const resolved = resolveCitations(responseText, clauseRows, retrievedIds.slice(0, 3));
        citedClauses = resolved.citedClauses;
        citationConfidence = resolved.citationConfidence;
        citedClauseIds = resolved.citedClauseIds;
        citedPages = resolved.citedPages;

        if (citationConfidence === 'low' && retrievedIds.length > 0 && !responseText.includes('[Clause')) {
          const top = retrieved.filter((r) => r.id > 0).slice(0, 2);
          const autoCite = top.map((c) =>
            `[Clause ${c.clauseNumber} — ${c.clauseTitle || 'Untitled'}] (Page ${c.pageNumber ?? 'N/A'})`
          ).join('\n');
          responseText = `${responseText.trim()}\n\n${autoCite}`;
          const resolved2 = resolveCitations(responseText, clauseRows, retrievedIds.slice(0, 3));
          citedClauses = resolved2.citedClauses;
          citationConfidence = resolved2.citationConfidence;
          citedClauseIds = resolved2.citedClauseIds;
          citedPages = resolved2.citedPages;
        }
      }
    } finally {
      responseTime = (Date.now() - startTime) / 1000;
      try {
        db.insert(chatMessages).values({
          documentId,
          userId: req.user.id,
          sessionId: sessionIdFinal,
          role: 'assistant',
          message: responseText,
          citedClauseIds: JSON.stringify(citedClauseIds),
          citedPages: JSON.stringify(citedPages),
          tokensUsed,
          responseTime,
        }).run();
        persistNow();
      } catch (persistErr) {
        console.error('Failed to persist assistant chat row:', persistErr);
      }
    }

    emitToUser(req.user.id, 'chat:message', {
      documentId,
      sessionId: sessionIdFinal,
      role: 'assistant',
    });

    res.status(201).json({
      success: true,
      data: {
        sessionId: sessionIdFinal,
        message: {
          role: 'assistant',
          content: responseText,
          tokensUsed,
          responseTime,
          citedClauses,
          citationConfidence,
        },
      },
    });
  } catch (err) {
    next(err);
  }
}

function parseJsonField(raw: string | null): unknown {
  if (!raw) return [];
  try { return JSON.parse(raw); } catch { return []; }
}

export async function getHistory(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const documentId = Number(req.params.documentId);
    const sessionId = req.query.sessionId as string | undefined;
    const page = Number(req.query.page) || 1;
    const limit = Math.min(Number(req.query.limit) || 50, 100);
    const offset = (page - 1) * limit;

    const db = getDb();

    const docRows = db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id} AND ${documents.isDeleted} = 0`
    ).all();

    if (!docRows[0]) throw new NotFoundError('Document');

    let whereClause = sql`${chatMessages.documentId} = ${documentId} AND ${chatMessages.userId} = ${req.user.id}`;
    if (sessionId) {
      whereClause = sql`${whereClause} AND ${chatMessages.sessionId} = ${sessionId}`;
    }

    const messages = db.select().from(chatMessages).where(whereClause).all();
    const clauseRows = db.select().from(clauses).where(sql`${clauses.documentId} = ${documentId}`).all();
    const clauseById = new Map(clauseRows.map((c) => [c.id, c]));

    const sorted = messages.sort((a, b) => a.createdAt.localeCompare(b.createdAt));
    const paginated = sorted.slice(offset, offset + limit);

    const sessions = new Map<string, typeof paginated>();
    for (const msg of paginated) {
      const existing = sessions.get(msg.sessionId) || [];
      existing.push(msg);
      sessions.set(msg.sessionId, existing);
    }

    res.json({
      success: true,
      data: {
        messages: paginated.map((m) => {
          const ids = parseJsonField(m.citedClauseIds) as number[];
          const citedClauses = Array.isArray(ids)
            ? ids.map((id) => {
                const c = clauseById.get(id);
                if (!c) return null;
                return {
                  clause_id: c.id,
                  clause_number: c.clauseNumber,
                  title: c.clauseTitle,
                  page: c.pageNumber,
                  snippet: (c.originalText || '').slice(0, 160),
                };
              }).filter(Boolean)
            : [];

          return {
            id: m.id,
            role: m.role,
            content: m.message,
            sessionId: m.sessionId,
            tokensUsed: m.tokensUsed,
            responseTime: m.responseTime,
            citedClauseIds: ids,
            citedPages: parseJsonField(m.citedPages),
            citedClauses,
            createdAt: m.createdAt,
          };
        }),
        sessions: Array.from(sessions.keys()),
        pagination: {
          page,
          limit,
          total: messages.length,
          totalPages: Math.ceil(messages.length / limit),
        },
      },
    });
  } catch (err) {
    next(err);
  }
}
