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
  { re: /\b(lease|rental|landlord|tenant|rent|leave and licence|leave and license|licensee|licensor)\b/i, label: 'Lease Agreement' },
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
    .filter((m) => m.length > 2)
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

/** Drop prompt-example risks that don't match the source document. */
function riskSupportedByDocument(r: RiskItem, sourceText: string, documentType: string): boolean {
  const title = (r.title || '').toLowerCase();
  const text = sourceText.toLowerCase();
  const type = documentType.toLowerCase();

  if (title.includes('unequal notice')) {
    return (
      type.includes('employment') &&
      /\b(resign|90 days|15 days|probation)\b/i.test(text)
    );
  }
  if (title.includes('unlimited damages') || title.includes('unlimited indemnity')) {
    return /\b(indemnif|unlimited|consequential)\b/.test(text);
  }
  if (title.includes('statutory benefits') || title.includes('pf/esi')) {
    return type.includes('employment');
  }
  return true;
}

function filterMissingForType(missing: string[], documentType: string): string[] {
  const type = documentType.toLowerCase();
  return missing.filter((m) => {
    const low = m.toLowerCase();
    if (/pf\/esi|statutory benefits|provident fund/.test(low) && !type.includes('employment')) {
      return false;
    }
    if (/non[-\s]?compete/.test(low) && (type.includes('lease') || type.includes('loan') || type === 'nda')) {
      return false;
    }
    return true;
  });
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

  const missingClauses = filterMissingForType(
    normalizeMissingClauses(ai.missingClauses || [], clauses),
    documentType,
  );
  const riskItems = (ai.riskItems || [])
    .filter((r) => !isFillerRisk(r))
    .filter((r) => riskSupportedByDocument(r, sourceText, documentType));
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

function parseIsoLikeDate(raw: string): string | null {
  const t = Date.parse(raw);
  if (Number.isNaN(t)) return null;
  return new Date(t).toISOString().slice(0, 10);
}

function extractParties(text: string): AnalysisOutput['keyParties'] {
  const parties: AnalysisOutput['keyParties'] = [];
  const licensor = text.match(/([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)[,\s]+(?:aged[^,]*,\s*)?(?:residing[^.]*?)?(?:hereinafter referred to as the\s+)?[\"']?Licensor/i);
  const licensee = text.match(/([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)[,\s]+(?:aged[^,]*,\s*)?(?:residing[^.]*?)?(?:hereinafter referred to as the\s+)?[\"']?Licensee/i);
  if (licensor) {
    parties.push({
      name: licensor[1].trim(),
      role: 'Licensor',
      type: 'individual',
      obligations: [],
      obligations_summary: 'Owner granting the licence.',
    });
  }
  if (licensee) {
    parties.push({
      name: licensee[1].trim(),
      role: 'Licensee',
      type: 'individual',
      obligations: [],
      obligations_summary: 'Occupant of the premises.',
    });
  }
  return parties;
}

function scoreClause(title: string, body: string): {
  riskLevel: 'none' | 'low' | 'medium' | 'high';
  riskScore: number;
  riskReason: string;
  riskCategory: Clause['riskCategory'];
  counterSuggestion: string;
} {
  const blob = `${title} ${body}`.toLowerCase();
  if (/lock[\s-]*out|self-help|disconnect (utilities|electricity)|without (a )?court/.test(blob)) {
    return {
      riskLevel: 'high',
      riskScore: 88,
      riskReason: 'Allows lock-out or utility cut-off without a court order.',
      riskCategory: 'termination',
      counterSuggestion: 'The Licensor shall not lock out, disconnect utilities, or seize goods without a court order. Any eviction must follow due process.',
    };
  }
  if (/lock[\s-]*in|shall not terminate/.test(blob) && /month/.test(blob)) {
    return {
      riskLevel: 'high',
      riskScore: 78,
      riskReason: 'Lock-in prevents the occupant from leaving without paying remaining fees.',
      riskCategory: 'termination',
      counterSuggestion: 'Lock-in shall not exceed three months. After lock-in either party may terminate with 30 days’ written notice. Liquidated damages shall not exceed one month’s fee.',
    };
  }
  if (/indemnif|hold harmless/.test(blob) && /unlimited|any and all|whatsoever/.test(blob)) {
    return {
      riskLevel: 'high',
      riskScore: 82,
      riskReason: 'Indemnity is one-sided or uncapped.',
      riskCategory: 'liability',
      counterSuggestion: 'Each party indemnifies the other only for its own negligence, capped at 12 months’ licence fee.',
    };
  }
  if (/late fee|penalty|liquidated/.test(blob)) {
    return {
      riskLevel: 'medium',
      riskScore: 55,
      riskReason: 'Penalty or late fee may be disproportionate.',
      riskCategory: 'financial',
      counterSuggestion: 'Late fee shall not exceed 2% per month of the overdue amount, with a 7-day cure period.',
    };
  }
  if (/licence fee|rent/.test(blob)) {
    return {
      riskLevel: 'medium',
      riskScore: 42,
      riskReason: 'Fee amount and increases should be checked against market and notice rules.',
      riskCategory: 'financial',
      counterSuggestion: 'Any increase requires written mutual agreement and shall not exceed 5% per year.',
    };
  }
  return {
    riskLevel: 'low',
    riskScore: 18,
    riskReason: 'Routine clause; still read against your facts.',
    riskCategory: 'legal',
    counterSuggestion: '',
  };
}

/**
 * Offline clause split used when every AI provider is unavailable (timeout, quota, etc.).
 */
export function buildHeuristicAnalysis(sourceText: string): AnalysisOutput {
  const documentType = inferDocumentType(sourceText);
  const numbered = sourceText.split(/(?=(?:^|\n)\s*\d+\.\s+)|(?=\s\d+\.\s+[A-Z])/m)
    .map((s) => s.trim())
    .filter((s) => /^\d+\./.test(s));
  const clauses: Clause[] = numbered.map((block, i) => {
    const m = block.match(/^(\d+)\.\s*([A-Z][A-Z0-9 \-\/']{2,80}?)(?:\.|:)\s*([\s\S]+)$/);
    const clauseNumber = m ? Number(m[1]) : i + 1;
    const clauseTitle = m ? m[2].trim() : `Clause ${i + 1}`;
    const originalText = (m ? m[3] : block).replace(/\s+/g, ' ').trim();
    const scored = scoreClause(clauseTitle, originalText);
    return {
      clauseNumber,
      clauseTitle,
      originalText: originalText.slice(0, 4000) || block.slice(0, 400),
      plainEnglishText: originalText.slice(0, 400),
      readingLevel: 'grade_8' as const,
      keyLegalTerms: [],
      ...scored,
      partyReferences: [],
    };
  });

  const parties = extractParties(sourceText);
  const startMatch = sourceText.match(/(\d{1,2}\s+(January|February|March|April|May|June|July|August|September|October|November|December)\s+20\d{2})/i);
  const endMatch = sourceText.match(/(?:expir|until|end(?:ing)? on|through)\s+(\d{1,2}\s+(January|February|March|April|May|June|July|August|September|October|November|December)\s+20\d{2})/i);
  const startIso = startMatch ? parseIsoLikeDate(startMatch[1]) : null;
  const endIso = endMatch ? parseIsoLikeDate(endMatch[1]) : null;

  const criticalDates: AnalysisOutput['criticalDates'] = [];
  const deadlines: AnalysisOutput['deadlines'] = [];
  if (startIso) {
    criticalDates.push({ label: 'Licence Term Start Date', date: startIso, urgency: 'medium', importance: 'Commencement' });
    deadlines.push({
      title: 'Licence Term Start Date',
      description: 'Term commences',
      dueDate: startIso,
      recurrence: 'one-time',
      deadlineType: 'milestone',
      partyResponsible: '',
      consequenceIfMissed: '',
      isRecurring: false,
    });
  }
  if (endIso) {
    criticalDates.push({ label: 'Licence Term End Date', date: endIso, urgency: 'high', importance: 'Expiry' });
    deadlines.push({
      title: 'Licence Term End Date',
      description: 'Term ends',
      dueDate: endIso,
      recurrence: 'one-time',
      deadlineType: 'termination',
      partyResponsible: '',
      consequenceIfMissed: '',
      isRecurring: false,
    });
  }

  const high = clauses.filter((c) => c.riskLevel === 'high');
  const overall = Math.min(100, Math.round(clauses.reduce((s, c) => s + c.riskScore, 0) / Math.max(1, clauses.length) * 1.4));
  const fairnessScore = Math.max(8, 55 - high.length * 12);
  const favors = parties.find((p) => /licensor|landlord|employer|company/i.test(p.role))?.name || 'Licensor';

  return {
    documentType,
    detectedTypeConfidence: 70,
    overallRiskScore: overall,
    riskLevel: overall >= 67 ? 'high' : overall >= 34 ? 'medium' : 'low',
    fairnessScore,
    favorsParty: favors,
    imbalanceReason: high.length
      ? `This contract favors ${favors} because of one-sided terms in ${high.map((c) => c.clauseTitle).join(', ')}.`
      : 'Heuristic split found no clearly one-sided clauses.',
    perCategoryFairness: {
      financial: 40,
      termination: high.some((c) => c.riskCategory === 'termination') ? 22 : 50,
      liability: high.some((c) => c.riskCategory === 'liability') ? 25 : 50,
      obligation: 42,
      compliance: 48,
      legal: 45,
    },
    summary: `${documentType}${parties.length ? ` between ${parties.map((p) => p.name).join(' and ')}` : ''}. Heuristic extraction of ${clauses.length} clauses while cloud analysis was unavailable.`,
    keyParties: parties,
    criticalDates,
    keyObligations: [],
    missingClauses: ['Registration / stamp duty sharing', 'Inventory of fixtures'],
    clauses,
    riskItems: high.map((c) => ({
      riskType: 'legal' as const,
      title: c.clauseTitle,
      description: c.riskReason,
      severity: 'high' as const,
      severityScore: c.riskScore,
      recommendation: c.counterSuggestion,
      legalReference: '',
    })),
    deadlines,
    breachScenarios: [],
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
