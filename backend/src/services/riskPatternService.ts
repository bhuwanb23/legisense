import { getDb, persistNow } from '../config/database';
import { clauses, riskPatterns, clauseRiskFlags } from '../models';
import { sql } from 'drizzle-orm';
import { callWithFallback } from './ai';
import { parseAiResponse } from '../prompts/analysisPrompt';

function parseKeywords(raw: string | null): string[] {
  if (!raw) return [];
  try {
    const v = JSON.parse(raw);
    return Array.isArray(v) ? v.map(String) : [];
  } catch {
    return [];
  }
}

function findSnippet(text: string, keyword: string): string {
  const lower = text.toLowerCase();
  const idx = lower.indexOf(keyword.toLowerCase());
  if (idx < 0) return text.slice(0, 160);
  const start = Math.max(0, idx - 40);
  const end = Math.min(text.length, idx + keyword.length + 80);
  return text.slice(start, end).trim();
}

export async function runRiskPatternScan(documentId: number, analysisId: number): Promise<number> {
  const db = getDb();
  const patterns = db.select().from(riskPatterns).all();
  const clauseRows = db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysisId}`).all();
  if (patterns.length === 0 || clauseRows.length === 0) return 0;

  const flaggedClauseIds = new Set<number>();
  const existingPairs = new Set<string>();

  for (const clause of clauseRows) {
    const hay = `${clause.clauseTitle || ''} ${clause.originalText || ''}`;
    for (const pattern of patterns) {
      const keywords = parseKeywords(pattern.triggerKeywords);
      const hit = keywords.find((kw) => kw && hay.toLowerCase().includes(kw.toLowerCase()));
      if (!hit) continue;
      const key = `${clause.id}:${pattern.id}`;
      if (existingPairs.has(key)) continue;
      existingPairs.add(key);

      db.insert(clauseRiskFlags).values({
        clauseId: clause.id,
        documentId,
        analysisId,
        patternId: pattern.id,
        matchType: 'keyword',
        matchConfidence: 90,
        flaggedTextSnippet: findSnippet(clause.originalText, hit),
      }).run();
      flaggedClauseIds.add(clause.id);
    }
  }

  // Optional semantic AI pass (off by default — keep process path to one LLM call)
  const semanticOn = ['1', 'true', 'on'].includes(
    (process.env.RISK_SEMANTIC_ENABLED || 'false').toLowerCase(),
  );

  if (semanticOn) {
    const candidates = clauseRows.length <= 25
      ? clauseRows
      : clauseRows.filter((c) => (c.riskScore ?? 0) >= 40 || !flaggedClauseIds.has(c.id)).slice(0, 25);

    if (candidates.length > 0) {
      try {
        const patternList = patterns.map((p) => ({ id: p.id, name: p.patternName, category: p.patternCategory })).slice(0, 60);
        const clauseList = candidates.map((c) => ({
          clauseNumber: c.clauseNumber,
          clauseId: c.id,
          title: c.clauseTitle,
          text: (c.originalText || '').slice(0, 500),
        }));

        const { response } = await callWithFallback({
          systemPrompt: `You detect risky legal clause patterns. Return ONLY JSON:
{"matches":[{"clauseId":number,"patternName":string,"confidence":0-100,"snippet":string}]}
Only include genuine matches (confidence >= 70). Use pattern names exactly from the provided list.`,
          userPrompt: JSON.stringify({ patterns: patternList, clauses: clauseList }),
          temperature: 0.2,
          expectJson: true,
        }, { task: 'analysis' });

        const parsed = typeof response.text === 'string' ? parseAiResponse(response.text) : response.text;
        const matches = Array.isArray((parsed as { matches?: unknown }).matches)
          ? (parsed as { matches: Array<{ clauseId: number; patternName: string; confidence: number; snippet?: string }> }).matches
          : [];

        for (const m of matches) {
          if (!m || (m.confidence ?? 0) < 70) continue;
          const pattern = patterns.find((p) => p.patternName.toLowerCase() === String(m.patternName || '').toLowerCase());
          const clause = clauseRows.find((c) => c.id === m.clauseId || c.clauseNumber === m.clauseId);
          if (!pattern || !clause) continue;
          const key = `${clause.id}:${pattern.id}`;
          if (existingPairs.has(key)) continue;
          existingPairs.add(key);

          db.insert(clauseRiskFlags).values({
            clauseId: clause.id,
            documentId,
            analysisId,
            patternId: pattern.id,
            matchType: 'semantic',
            matchConfidence: Math.min(100, Number(m.confidence) || 75),
            flaggedTextSnippet: m.snippet || (clause.originalText || '').slice(0, 160),
          }).run();
          flaggedClauseIds.add(clause.id);
        }
      } catch (err) {
        console.error('Semantic risk pattern scan failed:', err instanceof Error ? err.message : err);
      }
    }
  }

  for (const clauseId of flaggedClauseIds) {
    db.run(sql`UPDATE ${clauses} SET is_flagged = 1 WHERE id = ${clauseId}`);
  }

  persistNow();
  return flaggedClauseIds.size;
}
