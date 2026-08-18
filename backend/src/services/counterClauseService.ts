import { getDb, persistNow } from '../config/database';
import { clauses, analysisResults, documents } from '../models';
import { sql } from 'drizzle-orm';
import { callWithFallback } from './ai';
import { parseAiResponse } from '../prompts/analysisPrompt';
import { emitToUser } from './socketService';

const MAX_COUNTER_CLAUSES = 15;

export async function generateCounterClauses(documentId: number, userId: number): Promise<void> {
  const db = getDb();
  const analysisRows = db.select().from(analysisResults).where(
    sql`${analysisResults.documentId} = ${documentId}`
  ).all();
  const analysis = analysisRows[0];
  if (!analysis) {
    return;
  }

  db.run(sql`UPDATE ${analysisResults} SET counter_clauses_status = 'processing' WHERE id = ${analysis.id}`);
  persistNow();

  try {
    const docRows = db.select().from(documents).where(sql`${documents.id} = ${documentId}`).all();
    const jurisdiction = [docRows[0]?.countryCode, docRows[0]?.stateCode].filter(Boolean).join('-') || 'general';

    const risky = db.select().from(clauses).where(
      sql`${clauses.analysisId} = ${analysis.id}`
    ).all()
      .filter((c) => (c.riskScore ?? 0) > 50 || c.isFlagged)
      .sort((a, b) => (b.riskScore ?? 0) - (a.riskScore ?? 0))
      .slice(0, MAX_COUNTER_CLAUSES);

    if (risky.length === 0) {
      db.run(sql`UPDATE ${analysisResults} SET counter_clauses_status = 'skipped' WHERE id = ${analysis.id}`);
      persistNow();
      emitToUser(userId, 'analysis:counter_clauses_ready', { documentId, status: 'skipped', count: 0 });
      return;
    }

    for (const clause of risky) {
      try {
        const { response } = await callWithFallback({
          systemPrompt: `You rewrite risky legal clauses into fairer alternatives and give negotiation tips.
Return ONLY JSON:
{
  "rewrittenText": "balanced alternative clause text",
  "negotiationTips": {
    "steps": ["step 1", "step 2"],
    "email_template": "short professional email requesting the change"
  }
}
Rules:
- Protect both parties fairly
- Be legally enforceable in jurisdiction: ${jurisdiction}
- Use clear plain language
- Maintain original intent
- Return only JSON`,
          userPrompt: `Original clause:\n${clause.originalText}\n\nRisk: ${clause.riskReason || 'elevated risk'}\nRisk score: ${clause.riskScore}`,
          temperature: 0.3,
          expectJson: true,
        }, { task: 'rewrite' });

        const parsed = typeof response.text === 'string' ? parseAiResponse(response.text) : response.text;
        const rewritten = String((parsed as { rewrittenText?: string }).rewrittenText || '').trim();
        const tips = (parsed as { negotiationTips?: unknown }).negotiationTips || { steps: [], email_template: '' };

        if (rewritten) {
          db.run(sql`UPDATE ${clauses} SET
            counter_suggestion = ${rewritten},
            negotiation_tips = ${JSON.stringify(tips)}
            WHERE id = ${clause.id}`);
        }
      } catch (err) {
        console.error(`Counter-clause failed for clause ${clause.id}:`, err instanceof Error ? err.message : err);
      }
    }

    db.run(sql`UPDATE ${analysisResults} SET counter_clauses_status = 'ready' WHERE id = ${analysis.id}`);
    persistNow();
    emitToUser(userId, 'analysis:counter_clauses_ready', { documentId, status: 'ready', count: risky.length });
  } catch (err) {
    db.run(sql`UPDATE ${analysisResults} SET counter_clauses_status = 'failed' WHERE id = ${analysis.id}`);
    persistNow();
    emitToUser(userId, 'analysis:counter_clauses_ready', {
      documentId,
      status: 'failed',
      error: err instanceof Error ? err.message : String(err),
    });
    throw err;
  }
}
