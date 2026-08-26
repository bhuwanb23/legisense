import { getDb, persistNow } from '../config/database';
import { riskPatterns, requiredClausesTemplates } from '../models';
import { sql } from 'drizzle-orm';
import { riskPatternSeeds } from './riskPatterns';
import { requiredClauseSeeds } from './requiredClauses';

export async function seedRiskAndRequiredLibraries(): Promise<void> {
  const db = getDb();

  const existingPatterns = await db.select({ count: sql<number>`count(*)` }).from(riskPatterns);
  if (Number(existingPatterns[0]?.count ?? 0) === 0) {
    let seeded = 0;
    for (const p of riskPatternSeeds) {
      try {
        await db.insert(riskPatterns).values({
          patternName: p.patternName,
          patternCategory: p.patternCategory,
          severity: p.severity,
          triggerKeywords: JSON.stringify(p.triggerKeywords),
          explanation: p.explanation,
          recommendation: p.recommendation,
        });
        seeded++;
      } catch {
        // skip
      }
    }
    console.log(`Seeded ${seeded} risk patterns.`);
  }

  const existingTemplates = await db.select({ count: sql<number>`count(*)` }).from(requiredClausesTemplates);
  if (Number(existingTemplates[0]?.count ?? 0) === 0) {
    let seeded = 0;
    for (const t of requiredClauseSeeds) {
      try {
        await db.insert(requiredClausesTemplates).values({
          documentType: t.documentType,
          clauseName: t.clauseName,
          importance: t.importance,
          whyNeeded: t.whyNeeded,
          exampleText: t.exampleText,
          detectionKeywords: JSON.stringify(t.detectionKeywords),
        });
        seeded++;
      } catch {
        // skip
      }
    }
    console.log(`Seeded ${seeded} required clause templates.`);
  }

  persistNow();
}
