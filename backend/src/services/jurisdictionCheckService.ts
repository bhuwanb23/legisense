import { getDb, persistNow } from '../config/database';
import {
  documents, analysisResults, clauses, legalRules, jurisdictions,
  jurisdictionFlags, users,
} from '../models';
import { sql } from 'drizzle-orm';
import type { ConflictingJurisdiction } from '../data/legalRules';

export interface CreatedFlag {
  id: number;
  analysisId: number;
  documentId: number;
  clauseId: number | null;
  ruleId: number;
  flagType: string;
  message: string;
  legalReference: string | null;
  severity: string;
  ruleTitle?: string;
  conflictingJurisdictions?: ConflictingJurisdiction[];
}

const DOC_TYPE_ALIASES: Record<string, string[]> = {
  nda: ['nda', 'non_disclosure', 'non-disclosure agreement', 'nda'],
  non_disclosure: ['nda', 'non_disclosure'],
  rental_agreement: ['rental_agreement', 'rental', 'lease'],
  employment_contract: ['employment_contract', 'employment'],
  freelance_agreement: ['freelance_agreement', 'freelance'],
  loan_agreement: ['loan_agreement', 'loan'],
  sale_deed: ['sale_deed', 'sale'],
  service_agreement: ['service_agreement', 'service'],
  mou: ['mou', 'memorandum'],
  memorandum: ['mou', 'memorandum'],
  power_of_attorney: ['power_of_attorney'],
  partnership_deed: ['partnership_deed', 'partnership'],
  terms_of_service: ['terms_of_service'],
  privacy_policy: ['privacy_policy'],
};

function normalizeDocType(raw: string | null | undefined): string {
  if (!raw) return 'unknown';
  const lower = raw.toLowerCase().trim().replace(/\s+/g, '_').replace(/-/g, '_');
  for (const [canonical, aliases] of Object.entries(DOC_TYPE_ALIASES)) {
    if (aliases.includes(lower) || lower.includes(canonical)) return canonical;
  }
  if (lower.includes('nda') || lower.includes('non_disclosure') || lower.includes('confidential')) return 'nda';
  if (lower.includes('rent') || lower.includes('lease')) return 'rental_agreement';
  if (lower.includes('employ')) return 'employment_contract';
  return lower;
}

function parseKeywords(raw: string | null): string[] {
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed.map(String) : [];
  } catch {
    return [];
  }
}

function parseConflicts(raw: string | null): ConflictingJurisdiction[] {
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export function clauseMatchesKeywords(text: string, keywords: string[]): boolean {
  const hay = text.toLowerCase();
  return keywords.some((kw) => kw.trim() && hay.includes(kw.toLowerCase()));
}

export async function resolveJurisdictionIds(countryCode: string, stateCode: string | null): Promise<number[]> {
  const db = getDb();
  const ids: number[] = [];

  const countryLevel = await db.select().from(jurisdictions).where(
    sql`${jurisdictions.countryCode} = ${countryCode} AND ${jurisdictions.stateCode} IS NULL`
  );
  if (countryLevel[0]) ids.push(countryLevel[0].id);

  if (stateCode) {
    const stateLevel = await db.select().from(jurisdictions).where(
      sql`${jurisdictions.countryCode} = ${countryCode} AND ${jurisdictions.stateCode} = ${stateCode}`
    );
    if (stateLevel[0]) ids.push(stateLevel[0].id);
  }

  return ids;
}

export function parseUserJurisdiction(raw: string | null | undefined): {
  countryCode: string | null;
  stateCode: string | null;
  history: Array<{ countryCode: string; stateCode: string }>;
} {
  if (!raw) return { countryCode: null, stateCode: null, history: [] };
  try {
    const parsed = JSON.parse(raw);
    if (parsed && typeof parsed === 'object') {
      return {
        countryCode: parsed.country || parsed.countryCode || null,
        stateCode: parsed.state || parsed.stateCode || null,
        history: Array.isArray(parsed.history)
          ? parsed.history.map((h: Record<string, string>) => ({
              countryCode: h.country || h.countryCode,
              stateCode: h.state || h.stateCode,
            })).filter((h: { countryCode?: string; stateCode?: string }) => h.countryCode && h.stateCode)
          : [],
      };
    }
  } catch {
    // plain string like "IN-MH" or "IN/MH"
    const m = raw.match(/^([A-Za-z]{2})[-_/]?([A-Za-z0-9]+)?$/);
    if (m) return { countryCode: m[1].toUpperCase(), stateCode: m[2]?.toUpperCase() || null, history: [] };
  }
  return { countryCode: null, stateCode: null, history: [] };
}

export async function updateUserJurisdictionHistory(
  userId: number,
  countryCode: string,
  stateCode: string | null,
): Promise<void> {
  const db = getDb();
  const rows = await db.select().from(users).where(sql`${users.id} = ${userId}`);
  if (!rows[0]) return;

  const current = parseUserJurisdiction(rows[0].defaultJurisdiction);
  const history = current.history.filter(
    (h) => !(h.countryCode === countryCode && h.stateCode === (stateCode || '')),
  );
  if (stateCode) {
    history.unshift({ countryCode, stateCode });
  }
  const trimmed = history.slice(0, 10);
  const payload = JSON.stringify({
    country: countryCode,
    state: stateCode,
    history: trimmed.map((h) => ({ country: h.countryCode, state: h.stateCode })),
  });
  await db.execute(sql`UPDATE ${users} SET default_jurisdiction = ${payload}, updated_at = NOW() WHERE id = ${userId}`);
}

export async function runJurisdictionCheck(
  documentId: number,
  analysisId: number,
  documentType: string | null,
): Promise<CreatedFlag[]> {
  const db = getDb();

  const docRows = await db.select().from(documents).where(sql`${documents.id} = ${documentId}`);
  const doc = docRows[0];
  if (!doc) {
    await db.execute(sql`UPDATE ${analysisResults} SET jurisdiction_check_status = 'skipped' WHERE id = ${analysisId}`);
    return [];
  }

  let countryCode = doc.countryCode;
  let stateCode = doc.stateCode;

  if (!countryCode) {
    const userRows = await db.select().from(users).where(sql`${users.id} = ${doc.userId}`);
    const parsed = parseUserJurisdiction(userRows[0]?.defaultJurisdiction);
    countryCode = parsed.countryCode;
    stateCode = stateCode || parsed.stateCode;
  }

  if (!countryCode) {
    await db.execute(sql`UPDATE ${analysisResults} SET jurisdiction_check_status = 'skipped' WHERE id = ${analysisId}`);
    persistNow();
    return [];
  }

  try {
    const jurisdictionIds = resolveJurisdictionIds(countryCode, stateCode);
    if (jurisdictionIds.length === 0) {
      await db.execute(sql`UPDATE ${analysisResults} SET jurisdiction_check_status = 'skipped' WHERE id = ${analysisId}`);
      persistNow();
      return [];
    }

    const normalizedType = normalizeDocType(documentType);
    const typeVariants = DOC_TYPE_ALIASES[normalizedType] || [normalizedType];

    const allRules = (await db.select().from(legalRules)).filter((r) => {
      if (!jurisdictionIds.includes(r.jurisdictionId)) return false;
      return typeVariants.includes(r.documentType) || r.documentType === normalizedType;
    });

    const clauseRows = await db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysisId}`);
    const created: CreatedFlag[] = [];
    const stateLabel = stateCode || countryCode;

    for (const rule of allRules) {
      const keywords = parseKeywords(rule.clauseKeywords);
      const conflicts = parseConflicts(rule.conflictingJurisdictions);

      if (rule.ruleType === 'required') {
        const anyMatch = clauseRows.some((c) =>
          clauseMatchesKeywords(`${c.clauseTitle || ''} ${c.originalText || ''}`, keywords),
        );
        if (!anyMatch) {
          await db.insert(jurisdictionFlags).values({
            analysisId,
            documentId,
            clauseId: null,
            ruleId: rule.id,
            flagType: 'missing_requirement',
            message: `Required under ${stateLabel} law but not clearly found: ${rule.ruleTitle}. ${rule.ruleDescription}`,
            legalReference: rule.legalReference,
            severity: rule.severity,
          });
          created.push({
            id: 0,
            analysisId,
            documentId,
            clauseId: null,
            ruleId: rule.id,
            flagType: 'missing_requirement',
            message: rule.ruleTitle,
            legalReference: rule.legalReference,
            severity: rule.severity,
            ruleTitle: rule.ruleTitle,
            conflictingJurisdictions: conflicts,
          });
        }
        continue;
      }

      for (const clause of clauseRows) {
        const text = `${clause.clauseTitle || ''} ${clause.originalText || ''}`;
        if (!clauseMatchesKeywords(text, keywords)) continue;

        const flagType = rule.ruleType === 'prohibited' ? 'violation' : 'conflict';
        const message = rule.ruleType === 'prohibited'
          ? `This clause may be unenforceable or prohibited in ${stateLabel}: ${rule.ruleTitle}. ${rule.ruleDescription}`
          : `This clause may be limited by ${stateLabel} law: ${rule.ruleTitle}. ${rule.ruleDescription}`;

        await db.insert(jurisdictionFlags).values({
          analysisId,
          documentId,
          clauseId: clause.id,
          ruleId: rule.id,
          flagType,
          message,
          legalReference: rule.legalReference,
          severity: rule.severity,
        });

        created.push({
          id: 0,
          analysisId,
          documentId,
          clauseId: clause.id,
          ruleId: rule.id,
          flagType,
          message,
          legalReference: rule.legalReference,
          severity: rule.severity,
          ruleTitle: rule.ruleTitle,
          conflictingJurisdictions: conflicts,
        });
      }
    }

    const flagRows = await db.select().from(jurisdictionFlags).where(
      sql`${jurisdictionFlags.analysisId} = ${analysisId}`
    );

    const summary = flagRows.map((f) => ({
      clause_id: f.clauseId,
      rule_id: f.ruleId,
      flag_type: f.flagType,
      message: f.message,
      legal_reference: f.legalReference,
      severity: f.severity,
    }));

    await db.execute(sql`UPDATE ${analysisResults} SET
      jurisdiction_flags = ${JSON.stringify(summary)},
      jurisdiction_check_status = 'completed'
      WHERE id = ${analysisId}`);

    updateUserJurisdictionHistory(doc.userId, countryCode, stateCode);
    persistNow();

    // Re-attach rule metadata for conflict service
    return flagRows.map((f) => {
      const rule = allRules.find((r) => r.id === f.ruleId);
      return {
        id: f.id,
        analysisId: f.analysisId,
        documentId: f.documentId,
        clauseId: f.clauseId,
        ruleId: f.ruleId,
        flagType: f.flagType,
        message: f.message,
        legalReference: f.legalReference,
        severity: f.severity,
        ruleTitle: rule?.ruleTitle,
        conflictingJurisdictions: rule ? parseConflicts(rule.conflictingJurisdictions) : [],
      };
    });
  } catch (err) {
    console.error('Jurisdiction check failed:', err);
    await db.execute(sql`UPDATE ${analysisResults} SET jurisdiction_check_status = 'failed' WHERE id = ${analysisId}`);
    persistNow();
    return [];
  }
}
