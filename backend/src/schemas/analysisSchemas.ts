import { z } from 'zod';

/** Coerce empty/missing strings to a fallback so tiny local models still validate. */
const softStr = (fallback = '') =>
  z.preprocess((v) => {
    if (v == null) return fallback;
    const s = String(v).trim();
    return s.length > 0 ? s : fallback;
  }, z.string());

const softStrMin1 = (fallback = 'unknown') =>
  z.preprocess((v) => {
    if (v == null) return fallback;
    const s = String(v).trim();
    return s.length > 0 ? s : fallback;
  }, z.string().min(1));

const softNum = (fallback = 0, min = 0, max = 100) =>
  z.preprocess((v) => {
    const n = typeof v === 'number' ? v : Number(v);
    if (!Number.isFinite(n)) return fallback;
    return Math.min(max, Math.max(min, n));
  }, z.number().min(min).max(max));

function enumOr<T extends [string, ...string[]]>(values: T, fallback: T[number]) {
  return z.preprocess((v) => {
    if (v == null) return fallback;
    const s = String(v).toLowerCase().trim().replace(/\s+/g, '_');
    return (values as readonly string[]).includes(s) ? s : fallback;
  }, z.enum(values));
}

export const PartySchema = z.object({
  name: softStrMin1('Party'),
  role: softStrMin1('party'),
  type: enumOr(['individual', 'company', 'government', 'unknown'] as const, 'unknown'),
  obligations: z.array(z.string()).default([]),
  obligations_summary: softStrMin1('No obligations summarized.'),
});

export const ClauseSchema = z.object({
  clauseNumber: z.preprocess((v) => {
    const n = typeof v === 'number' ? v : Number(v);
    return Number.isFinite(n) && n > 0 ? Math.floor(n) : 1;
  }, z.number().int().positive()),
  clauseTitle: softStrMin1('Clause'),
  originalText: softStrMin1('(no text)'),
  plainEnglishText: softStrMin1('(no summary)'),
  readingLevel: enumOr(['grade_5', 'grade_8', 'standard'] as const, 'grade_8'),
  keyLegalTerms: z.array(z.object({
    term: softStrMin1('term'),
    definition: softStrMin1('definition'),
  })).default([]),
  riskLevel: enumOr(['none', 'low', 'medium', 'high'] as const, 'low'),
  riskScore: softNum(0),
  riskReason: softStr(''),
  riskCategory: enumOr(
    ['financial', 'legal', 'privacy', 'termination', 'obligation', 'liability', 'compliance', 'intellectual_property', 'operational'] as const,
    'legal',
  ),
  pageReference: z.preprocess((v) => {
    const n = typeof v === 'number' ? v : Number(v);
    return Number.isFinite(n) && n > 0 ? Math.floor(n) : null;
  }, z.number().int().positive().nullable().optional()),
  partyReferences: z.array(softStrMin1('')).default([]),
  counterSuggestion: softStr(''),
});

export const CriticalDateSchema = z.object({
  label: softStrMin1('Date'),
  date: softStrMin1('unknown'),
  urgency: enumOr(['high', 'medium', 'low'] as const, 'medium'),
  importance: softStrMin1('Noted'),
});

export const KeyObligationSchema = z.object({
  party: softStrMin1('Party'),
  obligation: softStrMin1('Obligation'),
  consequence: softStrMin1('Not specified'),
});

export const BreachScenarioSchema = z.object({
  scenario: softStrMin1('Scenario'),
  consequence: softStrMin1('Consequence'),
});

export const RiskItemSchema = z.object({
  riskType: enumOr(
    ['financial', 'liability', 'privacy', 'termination', 'missing', 'compliance', 'legal', 'obligation', 'intellectual_property', 'operational'] as const,
    'legal',
  ),
  title: softStrMin1('Risk'),
  description: softStrMin1('No description'),
  severity: enumOr(['critical', 'high', 'medium', 'low'] as const, 'medium'),
  severityScore: softNum(50),
  recommendation: softStr(''),
  legalReference: softStr(''),
});

const RecurrenceSchema = z.preprocess((val) => {
  if (val == null || val === '') return 'one-time';
  const s = String(val).toLowerCase().trim();
  if (['one-time', 'onetime', 'once', 'single', 'none', 'n/a', 'na'].includes(s)) return 'one-time';
  if (['monthly', 'month', 'per month'].includes(s)) return 'monthly';
  if (['yearly', 'annual', 'annually', 'year', 'per year'].includes(s)) return 'yearly';
  if (['quarterly', 'quarter', 'per quarter'].includes(s)) return 'quarterly';
  if (['weekly', 'daily', 'biweekly', 'biannual', 'semi-annual', 'semiannual'].includes(s)) {
    return s === 'biannual' || s === 'semi-annual' || s === 'semiannual' ? 'yearly' : 'one-time';
  }
  return 'one-time';
}, z.enum(['one-time', 'monthly', 'yearly', 'quarterly']));

export const DeadlineSchema = z.object({
  title: softStrMin1('Deadline'),
  description: softStrMin1('Deadline'),
  dueDate: softStrMin1('unknown'),
  recurrence: RecurrenceSchema.default('one-time'),
  deadlineType: enumOr(
    ['payment', 'renewal', 'notice', 'termination', 'review', 'milestone', 'compliance', 'other'] as const,
    'other',
  ),
  partyResponsible: softStr(''),
  consequenceIfMissed: softStr(''),
  isRecurring: z.preprocess((v) => Boolean(v), z.boolean()).optional().default(false),
});

export const AnalysisOutputSchema = z.object({
  documentType: softStrMin1('unknown'),
  detectedTypeConfidence: softNum(50),
  overallRiskScore: softNum(0),
  riskLevel: enumOr(['low', 'medium', 'high'] as const, 'low'),
  fairnessScore: softNum(50),
  favorsParty: softStrMin1('neither'),
  summary: softStrMin1('No summary available.'),
  keyParties: z.array(PartySchema).default([]),
  criticalDates: z.array(CriticalDateSchema).default([]),
  keyObligations: z.array(KeyObligationSchema).default([]),
  // Tiny models often emit objects/arrays instead of plain strings.
  missingClauses: z.preprocess((v) => {
    if (!Array.isArray(v)) return [];
    return v.map((item) => {
      if (typeof item === 'string') return item;
      if (item && typeof item === 'object') {
        const o = item as Record<string, unknown>;
        const pick = o.clause || o.name || o.title || o.description || o.text;
        if (typeof pick === 'string' && pick.trim()) return pick.trim();
        try { return JSON.stringify(item); } catch { return String(item); }
      }
      if (Array.isArray(item)) return item.map(String).join(': ');
      return String(item ?? '');
    }).filter((s) => s.length > 0);
  }, z.array(z.string()).default([])),
  clauses: z.array(ClauseSchema).default([]),
  riskItems: z.array(RiskItemSchema).default([]),
  deadlines: z.array(DeadlineSchema).default([]),
  breachScenarios: z.array(BreachScenarioSchema).default([]),
});

export type Party = z.infer<typeof PartySchema>;
export type Clause = z.infer<typeof ClauseSchema>;
export type CriticalDate = z.infer<typeof CriticalDateSchema>;
export type KeyObligation = z.infer<typeof KeyObligationSchema>;
export type RiskItem = z.infer<typeof RiskItemSchema>;
export type Deadline = z.infer<typeof DeadlineSchema>;
export type BreachScenario = z.infer<typeof BreachScenarioSchema>;
export type AnalysisOutput = z.infer<typeof AnalysisOutputSchema>;
