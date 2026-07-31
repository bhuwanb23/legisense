import type { AnalysisOutput, Clause, Deadline, RiskItem } from '../schemas/analysisSchemas';

const PROMPT_LEAK =
  /string\s*[—\-:]\s*|detected document type|e\.g\.|example shape|illustrative/i;

const META_PLAIN =
  /^(identifies|defines|sets|states|describes|outlines|specifies)\b/i;

const FILLER_RISK_TITLE =
  /risk\s*[—\-]\s*\d+\s*clauses?\s+found/i;

const ALLOWED_TYPES = [
  'NDA',
  'Employment Agreement',
  'Lease Agreement',
  'Loan Agreement',
  'Service Agreement',
  'Sale Deed',
  'Partnership Deed',
  'Power of Attorney',
  'Terms of Service',
  'Privacy Policy',
  'Will',
  'Court Notice',
  'MOU',
  'Other',
] as const;

const TYPE_HINTS: Array<{ re: RegExp; label: (typeof ALLOWED_TYPES)[number] }> = [
  { re: /\b(non[-\s]?disclosure|nda)\b/i, label: 'NDA' },
  { re: /\b(employment|offer letter|employee)\b/i, label: 'Employment Agreement' },
  { re: /\b(lease|rental|landlord|tenant|rent)\b/i, label: 'Lease Agreement' },
  { re: /\b(loan|emi|borrower|lender|nbfc)\b/i, label: 'Loan Agreement' },
  { re: /\b(master services|service agreement|msa|retainer|sla)\b/i, label: 'Service Agreement' },
  { re: /\b(sale deed|conveyance)\b/i, label: 'Sale Deed' },
  { re: /\b(partnership deed)\b/i, label: 'Partnership Deed' },
  { re: /\b(power of attorney|poa)\b/i, label: 'Power of Attorney' },
  { re: /\b(terms of service|terms and conditions)\b/i, label: 'Terms of Service' },
  { re: /\b(privacy policy)\b/i, label: 'Privacy Policy' },
  { re: /\b(last will|testament)\b/i, label: 'Will' },
  { re: /\b(court notice|summons)\b/i, label: 'Court Notice' },
  { re: /\b(memorandum of understanding|\bmou\b)\b/i, label: 'MOU' },
];

export function looksLikeNonLegalDocument(text: string): boolean {
  const t = text.toLowerCase();
  const hasContractSignal =
    /\b(agreement|hereinafter|party of the|whereas|indemnif|covenant|governing law|non[-\s]?compete)\b/i.test(
      t,
    );
  if (hasContractSignal) return false;

  const resumeHits = [
    /\bcurriculum vitae\b/,
    /\bresume\b/,
    /\beducation\b/,
    /\bskills\b/,
    /\bexperience\b/,
    /\binternship\b/,
    /\bcertifications?\b/,
  ].filter((re) => re.test(t)).length;

  return resumeHits >= 3;
}

export function inferDocumentType(text: string): string {
  for (const hint of TYPE_HINTS) {
    if (hint.re.test(text)) return hint.label;
  }
  if (looksLikeNonLegalDocument(text)) return 'Other';
  return 'Other';
}

export function normalizeDocumentType(raw: string, sourceText: string): string {
  const s = (raw || '').trim();
  if (!s || PROMPT_LEAK.test(s) || s.length > 60) {
    return inferDocumentType(sourceText);
  }

  const lower = s.toLowerCase();
  for (const label of ALLOWED_TYPES) {
    if (lower === label.toLowerCase()) return label;
  }
  for (const hint of TYPE_HINTS) {
    if (hint.re.test(s)) return hint.label;
  }
  return inferDocumentType(sourceText);
}

export function isParseableDate(value: string | null | undefined): boolean {
  if (!value) return false;
  const v = String(value).trim();
  if (!v || v.toLowerCase() === 'unknown' || v.length < 8) return false;
  // Accept ISO-ish or clear day-month-year
  if (/^\d{4}-\d{2}-\d{2}/.test(v)) {
    const t = Date.parse(v.slice(0, 10));
    return !Number.isNaN(t);
  }
  const t = Date.parse(v);
  return !Number.isNaN(t);
}

function normalizeMissingClauses(missing: string[], clauses: Clause[]): string[] {
  const titleBlob = clauses
    .map((c) => `${c.clauseTitle} ${c.plainEnglishText}`.toLowerCase())
    .join(' || ');

  return missing
    .map((m) => m.trim())
    .filter((m) => m.length > 0)
    .filter((m) => {
      const key = m
        .toLowerCase()
        .replace(/\bclauses?\b/g, ' ')
        .replace(/[^a-z0-9\s]/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();
      if (!key) return false;
      const tokens = key.split(' ').filter((t) => t.length > 3);
      if (tokens.length === 0) return true;
      // Drop if most meaningful tokens already appear in extracted clauses
      const hits = tokens.filter((t) => titleBlob.includes(t)).length;
      return hits < Math.ceil(tokens.length * 0.6);
    })
    .filter((m, i, arr) => arr.findIndex((x) => x.toLowerCase() === m.toLowerCase()) === i)
    .slice(0, 8);
}

function isFillerRisk(r: RiskItem): boolean {
  if (FILLER_RISK_TITLE.test(r.title)) return true;
  const desc = (r.description || '').toLowerCase();
  if (desc === 'standard clause.' || desc === 'standard clause') return true;
  if (r.title === 'Risk' && (!r.description || r.description === 'No description')) return true;
  return false;
}

function cleanClause(c: Clause): Clause {
  let plain = c.plainEnglishText || '';
  let original = c.originalText || '';
  let reason = c.riskReason || '';

  if (original === '(no text)' || original.toLowerCase() === 'n/a') {
    original = '';
  }

  if (META_PLAIN.test(plain.trim()) && plain.trim().split(/\s+/).length <= 8) {
    // Prefer expanding from original quote when model returned a useless stub.
    if (original.length > 20) {
      plain = `In plain terms: ${original.length > 280 ? `${original.slice(0, 277)}…` : original}`;
    }
  }

  if (/^standard clause\.?$/i.test(reason.trim())) {
    if (c.riskScore >= 40) {
      reason = `This ${c.clauseTitle || 'clause'} may put one party at a disadvantage and should be reviewed carefully.`;
    } else if (original) {
      reason = `Routine wording; still confirm it matches your understanding of “${c.clauseTitle || 'this section'}”.`;
    } else {
      reason = 'Limited detail available from the model for this clause.';
    }
  }

  return {
    ...c,
    originalText: original || c.originalText,
    plainEnglishText: plain || c.plainEnglishText,
    riskReason: reason,
  };
}

function filterDeadlines(items: Deadline[]): Deadline[] {
  return items.filter((d) => isParseableDate(d.dueDate));
}

function buildNonLegalStub(ai: AnalysisOutput, sourceText: string): AnalysisOutput {
  const snippet = sourceText.replace(/\s+/g, ' ').trim().slice(0, 180);
  return {
    ...ai,
    documentType: 'Other',
    detectedTypeConfidence: Math.min(ai.detectedTypeConfidence || 70, 80),
    overallRiskScore: 0,
    riskLevel: 'low',
    fairnessScore: 50,
    favorsParty: 'Balanced',
    summary:
      `This file does not appear to be a legal contract. ${snippet ? `It looks like: “${snippet}${sourceText.length > 180 ? '…' : ''}”. ` : ''}` +
      'Legisense skipped clause/risk extraction. Upload an agreement (employment, NDA, lease, loan, MSA, etc.) for a full analysis.',
    keyParties: [],
    criticalDates: [],
    keyObligations: [],
    missingClauses: [],
    clauses: [],
    riskItems: [],
    deadlines: [],
    breachScenarios: [],
  };
}

/**
 * Post-LLM cleanup so the UI gets usable fields even when a small model is sloppy.
 */
export function enrichAnalysisOutput(ai: AnalysisOutput, sourceText: string): AnalysisOutput {
  if (looksLikeNonLegalDocument(sourceText) || /resume|curriculum vitae/i.test(ai.documentType || '')) {
    return buildNonLegalStub(ai, sourceText);
  }

  const documentType = normalizeDocumentType(ai.documentType, sourceText);
  const clauses = (ai.clauses || []).map(cleanClause).filter((c) => {
    // Drop empty junk clauses
    const title = (c.clauseTitle || '').toLowerCase();
    if (title === 'original text' || title === 'clause') {
      return (c.originalText || '').length > 40 || (c.plainEnglishText || '').length > 40;
    }
    return true;
  });

  let summary = (ai.summary || '').trim();
  if (summary.length < 80 || PROMPT_LEAK.test(summary) || summary === documentType) {
    const partyNames = (ai.keyParties || []).map((p) => p.name).filter(Boolean).slice(0, 2);
    const clauseBits = clauses
      .slice(0, 4)
      .map((c) => c.clauseTitle)
      .filter(Boolean)
      .join(', ');
    summary =
      `${documentType}${partyNames.length ? ` between ${partyNames.join(' and ')}` : ''}. ` +
      (clauseBits
        ? `Key sections covered: ${clauseBits}. `
        : 'Limited clause detail was extracted. ') +
      `Overall risk assessed as ${ai.riskLevel || 'low'} (${ai.overallRiskScore ?? 0}/100). ` +
      'Open the clause list and risk items for details; re-run analysis with a stronger model for a richer summary.';
  }

  const missingClauses = normalizeMissingClauses(ai.missingClauses || [], clauses);
  const riskItems = (ai.riskItems || []).filter((r) => !isFillerRisk(r));
  const deadlines = filterDeadlines(ai.deadlines || []);
  const criticalDates = (ai.criticalDates || []).filter((d) => isParseableDate(d.date));

  return {
    ...ai,
    documentType,
    summary,
    clauses,
    missingClauses,
    riskItems,
    deadlines,
    criticalDates,
  };
}

/** Only promote medium+ clauses with a real reason into risk rows. */
export function shouldPromoteClauseToRisk(score: number, reason: string | null | undefined): boolean {
  if (score < 34) return false;
  const r = (reason || '').trim().toLowerCase();
  if (!r) return false;
  if (r === 'standard clause' || r === 'standard clause.') return false;
  if (r.startsWith('routine wording')) return false;
  return true;
}
