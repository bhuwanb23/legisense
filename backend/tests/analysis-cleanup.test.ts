import { enrichAnalysisOutput, inferDocumentType, normalizeDocumentType, isParseableDate } from '../src/services/analysisCleanup';
import type { AnalysisOutput } from '../src/schemas/analysisSchemas';

function base(): AnalysisOutput {
  return {
    documentType: 'string — detected document type',
    detectedTypeConfidence: 95,
    overallRiskScore: 10,
    riskLevel: 'low',
    fairnessScore: 60,
    favorsParty: 'Company',
    summary: 'Employment Agreement',
    keyParties: [
      { name: 'Acme', role: 'Employer', type: 'company', obligations: [], obligations_summary: 'Pay salary' },
    ],
    criticalDates: [
      { label: 'Start', date: 'unknown', urgency: 'high', importance: 'x' },
      { label: 'Real', date: '2025-03-01', urgency: 'high', importance: 'Start date' },
    ],
    keyObligations: [],
    missingClauses: ['Termination clause', 'Non-Compete clause', 'Confidentiality'],
    clauses: [
      {
        clauseNumber: 1,
        clauseTitle: 'Termination',
        originalText: 'Company may terminate with 15 days notice.',
        plainEnglishText: 'Identifies termination.',
        readingLevel: 'grade_5',
        keyLegalTerms: [],
        riskLevel: 'high',
        riskScore: 80,
        riskReason: 'Standard clause.',
        riskCategory: 'termination',
        counterSuggestion: 'Equalize notice.',
      },
      {
        clauseNumber: 2,
        clauseTitle: 'Non-Compete',
        originalText: '24 month ban across India.',
        plainEnglishText: 'You cannot join competitors for two years.',
        readingLevel: 'grade_5',
        keyLegalTerms: [],
        riskLevel: 'high',
        riskScore: 85,
        riskReason: 'Long non-compete after exit.',
        riskCategory: 'termination',
        counterSuggestion: '',
      },
    ],
    riskItems: [
      {
        riskType: 'legal',
        title: 'Legal Risk — 2 clauses found',
        description: 'Standard clause.',
        severity: 'high',
        severityScore: 70,
        recommendation: '',
        legalReference: '',
      },
      {
        riskType: 'termination',
        title: 'Unequal notice',
        description: '15 vs 90 days notice.',
        severity: 'high',
        severityScore: 78,
        recommendation: 'Equalize',
        legalReference: '',
      },
    ],
    deadlines: [
      { title: 'Bad', description: 'x', dueDate: 'unknown', recurrence: 'one-time', deadlineType: 'other', partyResponsible: '', consequenceIfMissed: '', isRecurring: false },
      { title: 'Good', description: 'Start', dueDate: '2025-03-01', recurrence: 'one-time', deadlineType: 'milestone', partyResponsible: '', consequenceIfMissed: '', isRecurring: false },
    ],
    breachScenarios: [],
  };
}

function assert(cond: unknown, msg: string): asserts cond {
  if (!cond) throw new Error(msg);
}

const employmentText = `
EMPLOYMENT AGREEMENT between Acme and Jordan.
Non-compete for 24 months. Termination with notice.
`;

const resumeText = `
Curriculum Vitae
Padmanaban G
Education: MBA
Skills: HR, Excel
Experience: Internship
Certifications: SHRM
`;

const cleaned = enrichAnalysisOutput(base(), employmentText);
assert(cleaned.documentType === 'Employment Agreement', `type=${cleaned.documentType}`);
assert(!cleaned.missingClauses.some((m) => /termination|non-compete/i.test(m)), `missing=${cleaned.missingClauses}`);
assert(cleaned.riskItems.length === 1, `risks=${cleaned.riskItems.length}`);
assert(cleaned.deadlines.length === 1 && cleaned.deadlines[0].dueDate === '2025-03-01', 'deadlines');
assert(cleaned.criticalDates.length === 1, 'criticalDates');
assert(cleaned.summary.length >= 80, `summary len ${cleaned.summary.length}`);
assert(!/^Identifies/i.test(cleaned.clauses[0].plainEnglishText), cleaned.clauses[0].plainEnglishText);
assert(normalizeDocumentType('string — detected document type', employmentText) === 'Employment Agreement', 'normalize');
assert(inferDocumentType('This NDA between A and B') === 'NDA', 'infer nda');
assert(isParseableDate('2025-03-01') && !isParseableDate('unknown'), 'dates');

const nonLegal = enrichAnalysisOutput(base(), resumeText);
assert(nonLegal.clauses.length === 0, 'resume clauses');
assert(/not appear to be a legal contract/i.test(nonLegal.summary), 'resume summary');

console.log('analysisCleanup tests passed');
