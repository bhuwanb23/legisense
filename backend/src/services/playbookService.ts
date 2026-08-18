import { getDb, persistNow } from '../config/database';
import { playbookRules, playbookFlags, clauses, analysisResults } from '../models';
import { sql } from 'drizzle-orm';

function keywordsFromRule(ruleText: string): string[] {
  return ruleText
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/)
    .filter((w) => w.length >= 5 && !['clause', 'should', 'shall', 'never', 'always', 'without'].includes(w));
}

export function runPlaybookScan(documentId: number, analysisId: number, userId: number): number {
  const db = getDb();
  const rules = db.select().from(playbookRules).where(
    sql`${playbookRules.userId} = ${userId} AND ${playbookRules.isActive} = 1`
  ).all();
  if (rules.length === 0) return 0;

  const clauseRows = db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysisId}`).all();
  db.run(sql`DELETE FROM ${playbookFlags} WHERE ${playbookFlags.analysisId} = ${analysisId}`);

  let count = 0;
  for (const rule of rules) {
    const words = keywordsFromRule(rule.ruleText);
    const blob = rule.ruleText.toLowerCase();
    for (const clause of clauseRows) {
      const text = `${clause.clauseTitle || ''} ${clause.originalText || ''} ${clause.plainEnglishText || ''}`.toLowerCase();
      const hit = blob.length > 0 && (
        (blob.includes('lock') && text.includes('lock'))
        || (blob.includes('utilit') && (text.includes('electric') || text.includes('utilit') || text.includes('water')))
        || (blob.includes('court') && text.includes('court'))
        || words.filter((w) => text.includes(w)).length >= Math.min(3, Math.max(1, words.length))
      );
      if (!hit) continue;
      db.insert(playbookFlags).values({
        documentId,
        analysisId,
        clauseId: clause.id,
        ruleId: rule.id,
        message: `Your Rule: ${rule.ruleText.slice(0, 180)}`,
      }).run();
      count++;
    }
  }
  persistNow();
  return count;
}

export function listPlaybookFlags(documentId: number) {
  const db = getDb();
  let rows = db.select().from(playbookFlags).where(sql`${playbookFlags.documentId} = ${documentId}`).all();
  if (rows.length === 0) {
    const analysis = db.select().from(analysisResults).where(sql`${analysisResults.documentId} = ${documentId}`).all()[0];
    if (analysis) {
      runPlaybookScan(documentId, analysis.id, analysis.userId);
      rows = db.select().from(playbookFlags).where(sql`${playbookFlags.documentId} = ${documentId}`).all();
    }
  }
  return rows;
}
