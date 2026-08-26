import { getDb, persistNow } from '../config/database';
import {
  documents, clauses, jurisdictionConflicts, users,
} from '../models';
import { sql } from 'drizzle-orm';
import { getNeighborStates } from '../data/neighboringStates';
import {
  parseUserJurisdiction,
  type CreatedFlag,
} from './jurisdictionCheckService';
import type { ConflictingJurisdiction } from '../data/legalRules';

function allowedStateCodes(
  countryCode: string,
  selectedState: string | null,
  history: Array<{ countryCode: string; stateCode: string }>,
): Set<string> {
  const allowed = new Set<string>();
  if (selectedState) {
    allowed.add(selectedState);
    for (const n of getNeighborStates(countryCode, selectedState)) {
      allowed.add(n);
    }
  }
  for (const h of history) {
    if (h.countryCode === countryCode && h.stateCode) {
      allowed.add(h.stateCode);
    }
  }
  return allowed;
}

export async function runConflictDetection(
  documentId: number,
  analysisId: number,
  flags: CreatedFlag[],
): Promise<void> {
  const db = getDb();
  const docRows = db.select().from(documents).where(sql`${documents.id} = ${documentId}`);
  const doc = docRows[0];
  if (!doc?.countryCode) return;

  const userRows = db.select().from(users).where(sql`${users.id} = ${doc.userId}`);
  const parsed = parseUserJurisdiction(userRows[0]?.defaultJurisdiction);
  const allowed = allowedStateCodes(doc.countryCode, doc.stateCode || parsed.stateCode, parsed.history);

  const byClause = new Map<number, {
    clauseTitle: string | null;
    conflicts: ConflictingJurisdiction[];
  }>();

  for (const flag of flags) {
    if (!flag.clauseId) continue;
    if (!flag.conflictingJurisdictions || flag.conflictingJurisdictions.length === 0) continue;

    const filtered = flag.conflictingJurisdictions.filter((c) => {
      const docCountry = (doc.countryCode || '').toUpperCase();
      const cc = (c.countryCode || doc.countryCode || '').toUpperCase();
      if (cc && docCountry && cc !== docCountry) return false;
      return allowed.size === 0 || allowed.has(c.stateCode);
    });

    if (filtered.length === 0) continue;

    const clauseRows = db.select().from(clauses).where(sql`${clauses.id} = ${flag.clauseId}`);
    const title = clauseRows[0]?.clauseTitle || flag.ruleTitle || 'Clause';

    const existing = byClause.get(flag.clauseId) || { clauseTitle: title, conflicts: [] };
    for (const c of filtered) {
      if (!existing.conflicts.some((e) => e.stateCode === c.stateCode && e.enforceability === c.enforceability)) {
        existing.conflicts.push(c);
      }
    }
    byClause.set(flag.clauseId, existing);
  }

  for (const [clauseId, data] of byClause) {
    if (data.conflicts.length < 2 && !(doc.stateCode && data.conflicts.some((c) => c.stateCode !== doc.stateCode))) {
      // Still save if there is at least one cross-state difference vs selected
      if (data.conflicts.length === 0) continue;
    }

    const conflictData = data.conflicts.map((c) => ({
      state: c.stateCode,
      status: c.enforceability,
      note: c.note || c.rule,
      rule: c.rule,
    }));

    // Include selected state if we have local status from the flag
    if (doc.stateCode && !conflictData.some((c) => c.state === doc.stateCode)) {
      conflictData.unshift({
        state: doc.stateCode,
        status: 'void',
        note: 'Flagged under selected jurisdiction rules',
        rule: data.clauseTitle || '',
      });
    }

    db.insert(jurisdictionConflicts).values({
      analysisId,
      documentId,
      clauseId,
      clauseTitle: data.clauseTitle,
      conflictData: JSON.stringify(conflictData),
    });
  }

  persistNow();
}

export function getFilteredStateConflicts(documentId: number, userId: number) {
  const db = getDb();
  const docRows = db.select().from(documents).where(
    sql`${documents.id} = ${documentId} AND ${documents.userId} = ${userId}`
  );
  if (!docRows[0]) return null;

  const rows = db.select().from(jurisdictionConflicts).where(
    sql`${jurisdictionConflicts.documentId} = ${documentId}`
  );

  return rows.map((r) => ({
    id: r.id,
    clause_id: r.clauseId,
    clause_title: r.clauseTitle,
    conflict_data: safeParse(r.conflictData),
  }));
}

function safeParse(raw: string | null): unknown {
  if (!raw) return [];
  try { return JSON.parse(raw); } catch { return []; }
}
