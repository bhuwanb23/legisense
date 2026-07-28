import { Request, Response, NextFunction } from 'express';
import { getDb } from '../config/database';
import { documents, chatMessages, analysisResults } from '../models';
import { sql } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import { NotFoundError, BadRequestError } from '../utils/errors';
import { persistNow } from '../config/database';

// TODO: Replace stub with real Gemini integration
async function generateAiResponse(
  _documentText: string,
  _conversationHistory: Array<{ role: string; message: string }>,
  _userMessage: string
): Promise<{ response: string; tokensUsed: number }> {
  // Stub: returns a placeholder response
  // Real implementation will call Gemini with document context + conversation history
  return {
    response: 'This is a placeholder response. AI chat integration requires Gemini API setup with document context.',
    tokensUsed: 0,
  };
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

    // Save user message
    db.insert(chatMessages).values({
      documentId,
      userId: req.user.id,
      sessionId: sessionIdFinal,
      role: 'user',
      message: message.trim(),
    }).run();

    // Get conversation history for context
    const historyRows = db.select().from(chatMessages).where(
      sql`${chatMessages.documentId} = ${documentId} AND ${chatMessages.sessionId} = ${sessionIdFinal}`
    ).all();

    const conversationHistory = historyRows.map((m) => ({
      role: m.role,
      message: m.message,
    }));

    // Get document text for AI context
    const docText = docRows[0].rawText || '';

    // Generate AI response
    const startTime = Date.now();
    const aiResult = await generateAiResponse(docText, conversationHistory, message.trim());
    const responseTime = (Date.now() - startTime) / 1000;

    // Save assistant message
    db.insert(chatMessages).values({
      documentId,
      userId: req.user.id,
      sessionId: sessionIdFinal,
      role: 'assistant',
      message: aiResult.response,
      tokensUsed: aiResult.tokensUsed,
      responseTime,
    }).run();

    persistNow();

    res.status(201).json({
      success: true,
      data: {
        sessionId: sessionIdFinal,
        message: {
          role: 'assistant',
          content: aiResult.response,
          tokensUsed: aiResult.tokensUsed,
          responseTime,
        },
      },
    });
  } catch (err) {
    next(err);
  }
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

    // Sort by createdAt ascending and paginate
    const sorted = messages.sort((a, b) => {
      if (a.createdAt < b.createdAt) return -1;
      if (a.createdAt > b.createdAt) return 1;
      return 0;
    });

    const paginated = sorted.slice(offset, offset + limit);

    // Group by session
    const sessions = new Map<string, typeof paginated>();
    for (const msg of paginated) {
      const existing = sessions.get(msg.sessionId) || [];
      existing.push(msg);
      sessions.set(msg.sessionId, existing);
    }

    res.json({
      success: true,
      data: {
        messages: paginated.map((m) => ({
          id: m.id,
          role: m.role,
          content: m.message,
          sessionId: m.sessionId,
          tokensUsed: m.tokensUsed,
          responseTime: m.responseTime,
          createdAt: m.createdAt,
        })),
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
