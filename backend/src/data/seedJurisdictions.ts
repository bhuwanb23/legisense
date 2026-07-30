import { getDb, persistNow } from '../config/database';
import { jurisdictions, legalRules } from '../models';
import { sql } from 'drizzle-orm';
import { jurisdictionSeeds } from './jurisdictions';
import { legalRuleSeeds } from './legalRules';

export function seedJurisdictionsAndRules(): void {
  const db = getDb();

  const existing = db.select({ count: sql<number>`count(*)` }).from(jurisdictions).all();
  if (Number(existing[0]?.count ?? 0) === 0) {
    let seeded = 0;
    for (const row of jurisdictionSeeds) {
      try {
        db.insert(jurisdictions).values({
          countryCode: row.countryCode,
          countryName: row.countryName,
          stateCode: row.stateCode,
          stateName: row.stateName,
        }).run();
        seeded++;
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        if (!message.includes('UNIQUE constraint failed')) throw err;
      }
    }
    console.log(`Seeded ${seeded} jurisdictions.`);
  }

  const existingRules = db.select({ count: sql<number>`count(*)` }).from(legalRules).all();
  if (Number(existingRules[0]?.count ?? 0) === 0) {
    const allJurisdictions = db.select().from(jurisdictions).all();
    const byKey = new Map<string, number>();
    for (const j of allJurisdictions) {
      byKey.set(`${j.countryCode}|${j.stateCode ?? ''}`, j.id);
    }

    let seeded = 0;
    for (const rule of legalRuleSeeds) {
      const jid = byKey.get(`${rule.countryCode}|${rule.stateCode ?? ''}`);
      if (!jid) continue;
      try {
        db.insert(legalRules).values({
          jurisdictionId: jid,
          documentType: rule.documentType,
          ruleTitle: rule.ruleTitle,
          ruleDescription: rule.ruleDescription,
          ruleType: rule.ruleType,
          clauseKeywords: JSON.stringify(rule.clauseKeywords),
          legalReference: rule.legalReference,
          severity: rule.severity,
          conflictingJurisdictions: JSON.stringify(rule.conflictingJurisdictions ?? []),
        }).run();
        seeded++;
      } catch {
        // skip duplicates on re-seed races
      }
    }
    console.log(`Seeded ${seeded} legal rules.`);
  }

  persistNow();
}
