import { initDatabase, getDb, closeDatabase, persistNow } from '../src/config/database';
import { sql } from 'drizzle-orm';
import { users, documents, analysisResults, clauses, riskItems } from '../src/models';
import { AnalysisOutputSchema, PartySchema, ClauseSchema } from '../src/schemas/analysisSchemas';
import { buildAnalysisUserPrompt, parseAiResponse } from '../src/prompts/analysisPrompt';
import { chunkText, mergeAnalysisResults, estimateTotalRequestTokens } from '../src/services/chunkingService';

interface TestResult {
  test: string;
  pass: boolean;
  detail?: string;
}

const results: TestResult[] = [];

function assert(condition: boolean, test: string, detail?: string) {
  results.push({ test, pass: condition, detail });
  console.log(`  ${condition ? '✅' : '❌'} ${test}${detail ? ` — ${detail}` : ''}`);
}

function buildValidAnalysisOutput(overrides: Record<string, unknown> = {}) {
  return {
    documentType: 'NDA',
    detectedTypeConfidence: 95,
    overallRiskScore: 42,
    riskLevel: 'medium',
    fairnessScore: 55,
    favorsParty: 'Party A',
    summary: 'This is a non-disclosure agreement between two parties governing confidentiality of shared information.',
    keyParties: [
      { name: 'Acme Corp', role: 'Disclosing Party', type: 'company', obligations: ['Share confidential information'], obligations_summary: 'Acme Corp must share its confidential information with John Doe for evaluation purposes.' },
      { name: 'John Doe', role: 'Receiving Party', type: 'individual', obligations: ['Maintain confidentiality'], obligations_summary: 'John Doe must keep all shared information confidential and return or destroy it upon request.' },
    ],
    criticalDates: [
      { label: 'Effective Date', date: '2024-01-01', urgency: 'high', importance: 'All obligations under the agreement begin on this date.' },
    ],
    keyObligations: [
      { party: 'John Doe', obligation: 'Keep confidential information secret for 5 years', consequence: 'Legal action for breach of confidentiality, damages, and potential termination.' },
    ],
    breachScenarios: [
      { scenario: 'Unauthorized disclosure of confidential information', consequence: 'Legal action for damages, termination of agreement, and potential criminal liability.' },
    ],
    missingClauses: ['Termination clause', 'Governing law'],
    clauses: [
      {
        clauseNumber: 1,
        clauseTitle: 'Definition of Confidential Information',
        originalText: 'Confidential Information means any information disclosed by one party to the other.',
        plainEnglishText: 'This clause defines what counts as secret information.',
        riskLevel: 'low',
        riskScore: 10,
        riskReason: 'Standard definition clause.',
        riskCategory: 'legal',
        counterSuggestion: '',
      },
    ],
    riskItems: [
      {
        riskType: 'liability',
        title: 'Broad definition of confidential info',
        description: 'The definition is overly broad and may capture non-confidential information.',
        severity: 'medium',
        severityScore: 55,
        recommendation: 'Narrow the definition to written information marked as confidential.',
        legalReference: 'Indian Evidence Act, 1872',
      },
    ],
    deadlines: [
      {
        title: 'Return of Materials',
        description: 'Return all confidential materials upon termination.',
        dueDate: 'Upon termination',
        recurrence: 'one-time',
      },
    ],
    ...overrides,
  };
}

async function run() {
  console.log('🧪 AI Document Analysis Pipeline Tests\n');
  await initDatabase();
  const db = getDb();

  db.run(sql`DELETE FROM ${clauses}`);
  db.run(sql`DELETE FROM ${analysisResults}`);
  db.run(sql`DELETE FROM ${documents}`);
  db.run(sql`DELETE FROM ${users}`);
  persistNow();

  db.insert(users).values({
    fullName: 'Analysis Test User',
    email: 'analysis-test@test.com',
    passwordHash: 'hash',
    authProvider: 'email',
    isActive: true,
  }).run();
  const userRow = db.select().from(users).where(sql`${users.email} = 'analysis-test@test.com'`).all()[0];
  const userId = userRow.id;

  // ═══════════════════════════════════════════════════
  //  1. Zod Schema Validation
  // ═══════════════════════════════════════════════════
  console.log('\n── 1. Zod Schema Validation ──');

  {
    const valid = buildValidAnalysisOutput();
    const parsed = AnalysisOutputSchema.parse(valid);
    assert(parsed.documentType === 'NDA', 'AnalysisOutputSchema parses valid output');
    assert(parsed.riskLevel === 'medium', 'AnalysisOutputSchema validates riskLevel enum');
    assert(parsed.clauses.length === 1, 'AnalysisOutputSchema parses clauses array');
    assert(parsed.keyParties.length === 2, 'AnalysisOutputSchema parses keyParties');
  }

  {
    const valid = buildValidAnalysisOutput({ overallRiskScore: 0 });
    const parsed = AnalysisOutputSchema.parse(valid);
    assert(parsed.overallRiskScore === 0, 'AnalysisOutputSchema allows riskScore = 0');
  }

  {
    const valid = buildValidAnalysisOutput({ overallRiskScore: 100 });
    const parsed = AnalysisOutputSchema.parse(valid);
    assert(parsed.overallRiskScore === 100, 'AnalysisOutputSchema allows riskScore = 100');
  }

  {
    let threw = false;
    try {
      AnalysisOutputSchema.parse(buildValidAnalysisOutput({ overallRiskScore: 150 }));
    } catch {
      threw = true;
    }
    assert(threw, 'AnalysisOutputSchema rejects riskScore > 100');
  }

  {
    let threw = false;
    try {
      AnalysisOutputSchema.parse(buildValidAnalysisOutput({ riskLevel: 'extreme' }));
    } catch {
      threw = true;
    }
    assert(threw, 'AnalysisOutputSchema rejects invalid riskLevel');
  }

  {
    let threw = false;
    try {
      AnalysisOutputSchema.parse(buildValidAnalysisOutput({ clauses: [{ ...buildValidAnalysisOutput().clauses[0], clauseNumber: -1 }] }));
    } catch {
      threw = true;
    }
    assert(threw, 'AnalysisOutputSchema rejects negative clauseNumber');
  }

  {
    const minimal = {
      documentType: 'Rental Agreement',
      detectedTypeConfidence: 80,
      overallRiskScore: 30,
      riskLevel: 'low',
      fairnessScore: 60,
      favorsParty: 'Tenant',
      summary: 'A rental agreement.',
      keyParties: [],
      criticalDates: [],
      keyObligations: [],
      breachScenarios: [],
      missingClauses: [],
      clauses: [],
      riskItems: [],
      deadlines: [],
    };
    const parsed = AnalysisOutputSchema.parse(minimal);
    assert(parsed.documentType === 'Rental Agreement', 'AnalysisOutputSchema accepts minimal valid output');
    assert(parsed.clauses.length === 0, 'AnalysisOutputSchema accepts empty clauses');
    assert(parsed.breachScenarios.length === 0, 'AnalysisOutputSchema accepts empty breachScenarios');
  }

  {
    let threw = false;
    try {
      AnalysisOutputSchema.parse({});
    } catch {
      threw = true;
    }
    assert(threw, 'AnalysisOutputSchema rejects empty object');
  }

  // ═══════════════════════════════════════════════════
  //  2. Party Schema with type field
  // ═══════════════════════════════════════════════════
  console.log('\n── 2. Party Schema (with type field) ──');

  {
    const company = PartySchema.parse({ name: 'Acme Corp', role: 'Employer', type: 'company', obligations: [], obligations_summary: 'Acme Corp must pay salary and provide benefits.' });
    assert(company.type === 'company', 'PartySchema accepts company type');
  }

  {
    const individual = PartySchema.parse({ name: 'John Doe', role: 'Employee', type: 'individual', obligations: [], obligations_summary: 'John Doe must perform duties and keep information confidential.' });
    assert(individual.type === 'individual', 'PartySchema accepts individual type');
  }

  {
    const defaulted = PartySchema.parse({ name: 'Unknown', role: 'Party', obligations: [], obligations_summary: 'No specific obligations identified.' });
    assert(defaulted.type === 'unknown', 'PartySchema defaults type to unknown');
  }

  {
    let threw = false;
    try {
      PartySchema.parse({ name: '', role: 'Party', obligations: [], obligations_summary: 'Test.' });
    } catch {
      threw = true;
    }
    assert(threw, 'PartySchema rejects empty name');
  }

  // ═══════════════════════════════════════════════════
  //  3. Clause Schema
  // ═══════════════════════════════════════════════════
  console.log('\n── 3. Clause Schema ──');

  {
    const clause = ClauseSchema.parse({
      clauseNumber: 1,
      clauseTitle: 'Parties',
      originalText: 'This Agreement is between...',
      plainEnglishText: 'Identifies who is signing.',
      riskLevel: 'none',
      riskScore: 0,
      riskReason: 'Standard.',
      riskCategory: 'legal',
      counterSuggestion: '',
    });
    assert(clause.clauseNumber === 1, 'ClauseSchema accepts valid clause');
    assert(clause.riskLevel === 'none', 'ClauseSchema allows riskLevel=none');
  }

  {
    let threw = false;
    try {
      ClauseSchema.parse({
        clauseNumber: 1,
        clauseTitle: 'Parties',
        originalText: '',
        plainEnglishText: 'Identifies who is signing.',
        riskLevel: 'none',
        riskScore: 0,
        riskReason: 'Standard.',
        riskCategory: 'legal',
        counterSuggestion: '',
      });
    } catch {
      threw = true;
    }
    assert(threw, 'ClauseSchema rejects empty originalText');
  }

  {
    let threw = false;
    try {
      ClauseSchema.parse({
        clauseNumber: 1,
        clauseTitle: 'Parties',
        originalText: 'Text',
        plainEnglishText: 'Explanation',
        riskLevel: 'none',
        riskScore: 0,
        riskReason: 'Standard.',
        riskCategory: 'invalid-category',
        counterSuggestion: '',
      });
    } catch {
      threw = true;
    }
    assert(threw, 'ClauseSchema rejects invalid riskCategory');
  }

  // ═══════════════════════════════════════════════════
  //  4. Breach Scenarios Schema
  // ═══════════════════════════════════════════════════
  console.log('\n── 4. Breach Scenarios ──');

  {
    const { BreachScenarioSchema } = await import('../src/schemas/analysisSchemas');
    const valid = BreachScenarioSchema.parse({ scenario: 'Failure to pay', consequence: 'Penalty interest applies.' });
    assert(valid.scenario === 'Failure to pay', 'BreachScenarioSchema parses valid breach');
    assert(valid.consequence === 'Penalty interest applies.', 'BreachScenarioSchema parses consequence');
  }

  {
    const { BreachScenarioSchema } = await import('../src/schemas/analysisSchemas');
    let threw = false;
    try { BreachScenarioSchema.parse({ scenario: '', consequence: 'Test' }); } catch { threw = true; }
    assert(threw, 'BreachScenarioSchema rejects empty scenario');
  }

  {
    const { AnalysisOutputSchema } = await import('../src/schemas/analysisSchemas');
    const valid = AnalysisOutputSchema.parse(buildValidAnalysisOutput());
    assert(valid.breachScenarios.length === 1, 'AnalysisOutputSchema parses breachScenarios array');
    assert(valid.breachScenarios[0].scenario.includes('Unauthorized'), 'breachScenarios has correct scenario');
  }

  // ═══════════════════════════════════════════════════
  //  5. Key Obligations with consequence
  // ═══════════════════════════════════════════════════
  console.log('\n── 5. Key Obligations with consequence ──');

  {
    const { KeyObligationSchema, AnalysisOutputSchema } = await import('../src/schemas/analysisSchemas');
    const valid = KeyObligationSchema.parse({ party: 'Acme Corp', obligation: 'Pay salary', consequence: 'Late fees apply.' });
    assert(valid.consequence === 'Late fees apply.', 'KeyObligationSchema parses consequence');

    const output = AnalysisOutputSchema.parse(buildValidAnalysisOutput());
    assert(output.keyObligations[0].consequence.length > 0, 'AnalysisOutput includes obligation consequence');
  }

  // ═══════════════════════════════════════════════════
  //  6. Critical Dates with importance
  // ═══════════════════════════════════════════════════
  console.log('\n── 6. Critical Dates with importance ──');

  {
    const { CriticalDateSchema, AnalysisOutputSchema } = await import('../src/schemas/analysisSchemas');
    const valid = CriticalDateSchema.parse({ label: 'Renewal', date: '2025-01-01', urgency: 'high', importance: 'Must act by this date.' });
    assert(valid.importance === 'Must act by this date.', 'CriticalDateSchema parses importance');

    const output = AnalysisOutputSchema.parse(buildValidAnalysisOutput());
    assert(output.criticalDates[0].importance.length > 0, 'AnalysisOutput includes date importance');
  }

  // ═══════════════════════════════════════════════════
  //  7. Deadline Urgency Calculation
  // ═══════════════════════════════════════════════════
  console.log('\n── 7. Deadline Urgency Calculation ──');

  function calcUrgency(dateStr: string): string {
    if (!dateStr || dateStr.length < 10) return 'medium';
    const parsed = new Date(dateStr);
    if (isNaN(parsed.getTime())) return 'medium';
    const now = new Date();
    const diffMs = parsed.getTime() - now.getTime();
    const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));
    if (diffDays < 0) return 'overdue';
    if (diffDays <= 7) return 'critical';
    if (diffDays <= 30) return 'high';
    if (diffDays <= 90) return 'medium';
    return 'low';
  }

  {
    const past = calcUrgency('2020-01-01');
    assert(past === 'overdue', 'calcUrgency returns overdue for past date');
  }

  {
    const tomorrow = new Date(Date.now() + 86400000).toISOString().slice(0, 10);
    const soon = calcUrgency(tomorrow);
    assert(soon === 'critical', 'calcUrgency returns critical for date within 7 days');
  }

  {
    const twoWeeks = new Date(Date.now() + 14 * 86400000).toISOString().slice(0, 10);
    const med = calcUrgency(twoWeeks);
    assert(med === 'high', 'calcUrgency returns high for date within 30 days');
  }

  {
    const twoMonths = new Date(Date.now() + 60 * 86400000).toISOString().slice(0, 10);
    const norm = calcUrgency(twoMonths);
    assert(norm === 'medium', 'calcUrgency returns medium for date within 90 days');
  }

  {
    const far = new Date(Date.now() + 180 * 86400000).toISOString().slice(0, 10);
    const low = calcUrgency(far);
    assert(low === 'low', 'calcUrgency returns low for date beyond 90 days');
  }

  {
    const unparseable = calcUrgency('Upon termination');
    assert(unparseable === 'medium', 'calcUrgency returns medium for unparseable date');
  }

  {
    const empty = calcUrgency('');
    assert(empty === 'medium', 'calcUrgency returns medium for empty string');
  }

  {
    const short = calcUrgency('2024');
    assert(short === 'medium', 'calcUrgency returns medium for too-short date string');
  }

  // ═══════════════════════════════════════════════════
  //  8. Prompt Builder
  // ═══════════════════════════════════════════════════
  console.log('\n── 8. Prompt Builder ──');

  {
    const prompt = buildAnalysisUserPrompt('Short document text.');
    assert(prompt.includes('Short document text.'), 'buildAnalysisUserPrompt includes document text');
    assert(prompt.includes('Analyze the following'), 'buildAnalysisUserPrompt has instruction');
    assert(prompt.includes('raw JSON only'), 'buildAnalysisUserPrompt enforces JSON only');
  }

  {
    const prompt = buildAnalysisUserPrompt('');
    assert(prompt.includes('---'), 'buildAnalysisUserPrompt handles empty document');
  }

  // ═══════════════════════════════════════════════════
  //  9. AI Response Parser (enhanced)
  // ═══════════════════════════════════════════════════
  console.log('\n── 9. AI Response Parser ──');

  {
    const validJson = '{"documentType":"NDA","overallRiskScore":42}';
    const parsed = parseAiResponse(validJson);
    assert(parsed.documentType === 'NDA', 'parseAiResponse parses valid JSON');
  }

  {
    const markdownJson = '```json\n{"documentType":"Rental"}\n```';
    const parsedMd = parseAiResponse(markdownJson);
    assert(parsedMd.documentType === 'Rental', 'parseAiResponse strips markdown fences');
  }

  {
    const trimmedJson = '  {"documentType":"Employment"}  ';
    const parsedTrimmed = parseAiResponse(trimmedJson);
    assert(parsedTrimmed.documentType === 'Employment', 'parseAiResponse handles whitespace');
  }

  {
    const withPrefix = 'Here is the analysis:\n{"documentType":"NDA"}';
    const parsed = parseAiResponse(withPrefix);
    assert(parsed.documentType === 'NDA', 'parseAiResponse extracts JSON from text prefix');
  }

  {
    const withSuffix = '{"documentType":"NDA"}\nThat was the analysis.';
    const parsed = parseAiResponse(withSuffix);
    assert(parsed.documentType === 'NDA', 'parseAiResponse extracts JSON with text suffix');
  }

  {
    const complex = 'Some preamble text\n```json\n{"documentType":"Partnership","overallRiskScore":30}\n```\nSome post text.';
    const parsed = parseAiResponse(complex);
    assert(parsed.documentType === 'Partnership', 'parseAiResponse extracts from complex markdown');
    assert(parsed.overallRiskScore === 30, 'parseAiResponse gets all fields from complex response');
  }

  {
    let parseFailed = false;
    try { parseAiResponse('not json at all'); } catch { parseFailed = true; }
    assert(parseFailed, 'parseAiResponse throws on invalid JSON');
  }

  {
    let parseFailed = false;
    try { parseAiResponse(''); } catch { parseFailed = true; }
    assert(parseFailed, 'parseAiResponse throws on empty string');
  }

  // ═══════════════════════════════════════════════════
  //  10. Token Estimation
  // ═══════════════════════════════════════════════════
  console.log('\n── 10. Token Estimation ──');

  {
    const tokens = estimateTotalRequestTokens('System prompt.', 'User text.');
    assert(typeof tokens === 'number' && tokens > 0, 'estimateTotalRequestTokens returns positive number');
  }

  {
    const emptyTokens = estimateTotalRequestTokens('', '');
    assert(emptyTokens === 0, 'estimateTotalRequestTokens returns 0 for empty input');
  }

  {
    const longText = 'A'.repeat(4000);
    const tokens = estimateTotalRequestTokens(longText, longText);
    assert(tokens === 2000, `estimateTotalRequestTokens estimates ~4 chars per token (got ${tokens})`);
  }

  // ═══════════════════════════════════════════════════
  //  11. Chunking Service
  // ═══════════════════════════════════════════════════
  console.log('\n── 11. Chunking Service ──');

  {
    const chunks = chunkText('Short text.');
    assert(chunks.length >= 1, 'chunkText returns at least 1 chunk for short text');
    assert(chunks[0].text === 'Short text.', 'chunkText preserves short text');
  }

  {
    const longText = 'Paragraph one.\n\nParagraph two.\n\nParagraph three.\n\nParagraph four.\n\nParagraph five.';
    const smallChunks = chunkText(longText, 8);
    assert(smallChunks.length > 1, 'chunkText splits text into multiple chunks with low token limit');
  }

  {
    const same = mergeAnalysisResults([buildValidAnalysisOutput(), buildValidAnalysisOutput()]);
    assert(same.documentType === 'NDA', 'mergeAnalysisResults merges identical results');
    assert(same.clauses.length === 2, 'mergeAnalysisResults concatenates clauses');
    assert(same.keyParties.length === 2, 'mergeAnalysisResults deduplicates parties');
  }

  {
    const a = buildValidAnalysisOutput({ documentType: 'NDA', overallRiskScore: 10, riskLevel: 'low', clauses: [{ clauseNumber: 1, clauseTitle: 'A', originalText: 'A', plainEnglishText: 'A', riskLevel: 'low', riskScore: 10, riskReason: '', riskCategory: 'legal', counterSuggestion: '' }] });
    const b = buildValidAnalysisOutput({ documentType: 'Rental', overallRiskScore: 80, riskLevel: 'high', clauses: [{ clauseNumber: 2, clauseTitle: 'B', originalText: 'B', plainEnglishText: 'B', riskLevel: 'high', riskScore: 80, riskReason: '', riskCategory: 'financial', counterSuggestion: '' }] });
    const merged = mergeAnalysisResults([a, b]);
    assert(merged.documentType === 'Rental', 'mergeAnalysisResults picks highest risk document type');
    assert(merged.riskLevel === 'high', 'mergeAnalysisResults picks highest risk level');
    assert(merged.clauses.length === 2, 'mergeAnalysisResults merges clauses from both');
  }

  {
    let threw = false;
    try { mergeAnalysisResults([]); } catch { threw = true; }
    assert(threw, 'mergeAnalysisResults throws on empty array');
  }

  // ═══════════════════════════════════════════════════
  //  12. DB integration — status 'analyzed'
  // ═══════════════════════════════════════════════════
  console.log('\n── 12. DB Status Integration ──');

  {
    db.insert(documents).values({
      userId,
      originalName: 'test-analysis.pdf',
      storagePath: 'test-path.txt',
      fileFormat: 'txt',
      fileSize: 100,
      sourceType: 'file',
      uploadStatus: 'uploaded',
      processingStatus: 'analyzed',
      rawText: 'Test document text for analysis.',
    }).run();

    const docRow = db.select().from(documents).where(sql`${documents.originalName} = 'test-analysis.pdf'`).all()[0];
    assert(docRow.processingStatus === 'analyzed', 'Document can be stored with status = analyzed');

    const testDocId = docRow.id;

    db.insert(analysisResults).values({
      documentId: testDocId,
      userId,
      documentType: 'NDA',
      overallRiskScore: 42,
      riskLevel: 'medium',
      fairnessScore: 55,
      favorsParty: 'Balanced',
      summary: 'Test analysis.',
      keyParties: JSON.stringify([]),
      criticalDates: JSON.stringify([]),
      keyObligations: JSON.stringify([]),
      missingClauses: JSON.stringify([]),
      jurisdictionFlags: JSON.stringify([]),
      breachScenarios: JSON.stringify([]),
      processingTime: 1.5,
      aiModelUsed: 'test-model',
    }).run();

    const analysisRow = db.select().from(analysisResults).where(sql`${analysisResults.documentId} = ${testDocId}`).all()[0];
    assert(analysisRow.documentType === 'NDA', 'Analysis result stored with correct documentType');
    assert(analysisRow.aiModelUsed === 'test-model', 'Analysis result stores model name');
  }

  // ═══════════════════════════════════════════════════
  //  13. Risk Score Dashboard
  // ═══════════════════════════════════════════════════
  console.log('\n── 13. Risk Score Dashboard ──');

  function calcRiskScore(clauses: { riskScore: number; riskLevel: string }[]): { overallScore: number; riskLevel: string } {
    if (clauses.length === 0) return { overallScore: 0, riskLevel: 'low' };

    let weightedSum = 0;
    let totalWeight = 0;
    let hasCritical = false;

    for (const c of clauses) {
      const score = c.riskScore;
      if (score >= 90) hasCritical = true;

      const weight = score >= 67 ? 2.0 : score >= 34 ? 1.0 : 0.5;
      weightedSum += score * weight;
      totalWeight += weight;
    }

    let overall = Math.round(weightedSum / totalWeight);
    if (hasCritical) overall = Math.max(overall, 60);

    const riskLevel = overall <= 33 ? 'low' : overall <= 66 ? 'medium' : 'high';
    return { overallScore: overall, riskLevel };
  }

  {
    const result = calcRiskScore([
      { riskScore: 20, riskLevel: 'low' } as any,
      { riskScore: 20, riskLevel: 'low' } as any,
    ]);
    assert(result.overallScore <= 33, 'All low clauses → low score');
    assert(result.riskLevel === 'low', 'All low clauses → riskLevel low');
  }

  {
    const result = calcRiskScore([
      { riskScore: 80, riskLevel: 'high' } as any,
      { riskScore: 75, riskLevel: 'high' } as any,
    ]);
    assert(result.overallScore >= 67, 'All high clauses → high score');
    assert(result.riskLevel === 'high', 'All high clauses → riskLevel high');
  }

  {
    const result = calcRiskScore([
      { riskScore: 45, riskLevel: 'medium' } as any,
      { riskScore: 50, riskLevel: 'medium' } as any,
    ]);
    assert(result.overallScore >= 34 && result.overallScore <= 66, 'All medium clauses → medium score');
    assert(result.riskLevel === 'medium', 'All medium clauses → riskLevel medium');
  }

  {
    const result = calcRiskScore([
      { riskScore: 95, riskLevel: 'high' } as any,
      { riskScore: 10, riskLevel: 'low' } as any,
    ]);
    assert(result.overallScore >= 60, 'Critical clause (95) forces minimum 60, got ' + result.overallScore);
    assert(result.riskLevel === 'high', 'Critical clause → riskLevel high');
  }

  {
    const result = calcRiskScore([]);
    assert(result.overallScore === 0, 'Empty clauses → score 0');
    assert(result.riskLevel === 'low', 'Empty clauses → riskLevel low');
  }

  {
    const result = calcRiskScore([
      { riskScore: 100, riskLevel: 'high' } as any,
    ]);
    assert(result.overallScore === 100, 'Single clause at 100 → score 100');
    assert(result.riskLevel === 'high', 'Single clause at 100 → riskLevel high');
  }

  {
    const result = calcRiskScore([
      { riskScore: 0, riskLevel: 'low' } as any,
    ]);
    assert(result.overallScore === 0, 'Single clause at 0 → score 0');
    assert(result.riskLevel === 'low', 'Single clause at 0 → riskLevel low');
  }

  {
    const result = calcRiskScore([
      { riskScore: 33, riskLevel: 'low' } as any,
    ]);
    assert(result.overallScore === 33, 'Score 33 → still low (got ' + result.overallScore + ')');
    assert(result.riskLevel === 'low', 'Score 33 → riskLevel low');
  }

  {
    const result = calcRiskScore([
      { riskScore: 34, riskLevel: 'medium' } as any,
    ]);
    assert(result.overallScore === 34, 'Score 34 → medium boundary (got ' + result.overallScore + ')');
    assert(result.riskLevel === 'medium', 'Score 34 → riskLevel medium');
  }

  {
    const result = calcRiskScore([
      { riskScore: 66, riskLevel: 'medium' } as any,
    ]);
    assert(result.overallScore === 66, 'Score 66 → medium boundary (got ' + result.overallScore + ')');
    assert(result.riskLevel === 'medium', 'Score 66 → riskLevel medium');
  }

  {
    const result = calcRiskScore([
      { riskScore: 67, riskLevel: 'high' } as any,
    ]);
    assert(result.overallScore === 67, 'Score 67 → high boundary (got ' + result.overallScore + ')');
    assert(result.riskLevel === 'high', 'Score 67 → riskLevel high');
  }

  {
    const result = calcRiskScore([
      { riskScore: 89, riskLevel: 'high' } as any,
    ]);
    assert(result.overallScore === 89, 'Score 89 → high without floor (got ' + result.overallScore + ')');
    assert(result.riskLevel === 'high', 'Score 89 → riskLevel high');
  }

  {
    const result = calcRiskScore([
      { riskScore: 90, riskLevel: 'high' } as any,
    ]);
    assert(result.overallScore >= 60, 'Score 90 → floor kicks in, got ' + result.overallScore);
    assert(result.overallScore === 90, 'Score 90 → stays 90 since 90 > 60 (got ' + result.overallScore + ')');
    assert(result.riskLevel === 'high', 'Score 90 → riskLevel high');
  }

  {
    const result = calcRiskScore([
      { riskScore: 80, riskLevel: 'high' } as any,
      { riskScore: 30, riskLevel: 'low' } as any,
      { riskScore: 50, riskLevel: 'medium' } as any,
    ]);
    assert(result.overallScore > 0 && result.overallScore <= 100, 'Mixed clauses produce valid score (got ' + result.overallScore + ')');
    assert(['low', 'medium', 'high'].includes(result.riskLevel), 'Mixed clauses produce valid riskLevel');
  }

  // ═══════════════════════════════════════════════════
  //  14. Risk Categorization
  // ═══════════════════════════════════════════════════
  console.log('\n── 14. Risk Categorization ──');

  {
    const { ClauseSchema, RiskItemSchema } = await import('../src/schemas/analysisSchemas');
    const clause = ClauseSchema.parse({
      clauseNumber: 1, clauseTitle: 'IP Clause', originalText: 'IP text.', plainEnglishText: 'IP.',
      riskLevel: 'low', riskScore: 10, riskReason: '', riskCategory: 'intellectual_property', counterSuggestion: '',
    });
    assert(clause.riskCategory === 'intellectual_property', 'ClauseSchema accepts intellectual_property');

    const operational = ClauseSchema.parse({
      clauseNumber: 2, clauseTitle: 'Ops Clause', originalText: 'Ops text.', plainEnglishText: 'Ops.',
      riskLevel: 'low', riskScore: 10, riskReason: '', riskCategory: 'operational', counterSuggestion: '',
    });
    assert(operational.riskCategory === 'operational', 'ClauseSchema accepts operational');

    const riskItem = RiskItemSchema.parse({
      riskType: 'intellectual_property', title: 'IP Risk', description: 'IP issue.',
      severity: 'high', severityScore: 70, recommendation: '', legalReference: '',
    });
    assert(riskItem.riskType === 'intellectual_property', 'RiskItemSchema accepts intellectual_property');
  }

  {
    const db = getDb();
    db.insert(documents).values({
      userId, originalName: 'risk-cat-test.pdf', storagePath: 'test.txt',
      fileFormat: 'txt', fileSize: 100, sourceType: 'file', uploadStatus: 'uploaded',
      processingStatus: 'analyzed', rawText: 'Test.',
    }).run();
    const testDocId = db.select({ id: documents.id }).from(documents).where(
      sql`${documents.originalName} = 'risk-cat-test.pdf'`
    ).all()[0].id;

    db.insert(analysisResults).values({
      documentId: testDocId, userId,
      documentType: 'NDA', overallRiskScore: 50, riskLevel: 'medium',
      fairnessScore: 50, favorsParty: 'Balanced', summary: 'Test.',
      keyParties: '[]', criticalDates: '[]', keyObligations: '[]',
      missingClauses: '[]', jurisdictionFlags: '[]', breachScenarios: '[]',
      processingTime: 1, aiModelUsed: 'test',
    }).run();
    const analysisId = db.select({ id: analysisResults.id }).from(analysisResults).where(
      sql`${analysisResults.documentId} = ${testDocId}`
    ).all()[0].id;

    db.insert(clauses).values({
      documentId: testDocId, analysisId,
      clauseNumber: 1, clauseTitle: 'Payment', originalText: 'Pay $100.', plainEnglishText: 'Payment terms.',
      riskLevel: 'high', riskScore: 80, riskReason: 'High payment obligation.',
      riskCategory: 'financial', counterSuggestion: 'Negotiate better terms.',
    }).run();

    db.insert(clauses).values({
      documentId: testDocId, analysisId,
      clauseNumber: 2, clauseTitle: 'Confidentiality', originalText: 'Keep secret.', plainEnglishText: 'NDA.',
      riskLevel: 'low', riskScore: 15, riskReason: 'Standard NDA.',
      riskCategory: 'legal', counterSuggestion: '',
    }).run();

    db.insert(clauses).values({
      documentId: testDocId, analysisId,
      clauseNumber: 3, clauseTitle: 'Termination', originalText: '30 days notice.', plainEnglishText: 'Term terms.',
      riskLevel: 'medium', riskScore: 50, riskReason: 'Notice period is short.',
      riskCategory: 'termination', counterSuggestion: 'Extend to 60 days.',
    }).run();

    db.insert(clauses).values({
      documentId: testDocId, analysisId,
      clauseNumber: 4, clauseTitle: 'Data Privacy', originalText: 'Collect data.', plainEnglishText: 'Privacy terms.',
      riskLevel: 'critical', riskScore: 95, riskReason: 'Broad data collection.',
      riskCategory: 'privacy', counterSuggestion: 'Limit data collection.',
    }).run();

    const clauseRows = db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysisId}`).all();
    assert(clauseRows.length === 4, 'Clauses inserted for risk categorization test (got ' + clauseRows.length + ')');

    const grouped: Record<string, typeof clauseRows> = {};
    for (const c of clauseRows) {
      const cat = c.riskCategory || 'other';
      if (!grouped[cat]) grouped[cat] = [];
      grouped[cat].push(c);
    }
    assert(Object.keys(grouped).length === 4, 'Clauses grouped into 4 categories (got ' + Object.keys(grouped).length + ')');
    assert(grouped.financial.length === 1, 'financial category has 1 clause');
    assert(grouped.legal.length === 1, 'legal category has 1 clause');
    assert(grouped.termination.length === 1, 'termination category has 1 clause');
    assert(grouped.privacy.length === 1, 'privacy category has 1 clause');

    for (const [category, catClauses] of Object.entries(grouped)) {
      const maxRiskClause = catClauses.reduce((best, c) =>
        (c.riskScore ?? 0) > (best.riskScore ?? 0) ? c : best
        , catClauses[0]);

      const score = maxRiskClause.riskScore ?? 0;
      const severity = score >= 90 ? 'critical' : score >= 67 ? 'high' : score >= 34 ? 'medium' : 'low';
      const label = category.charAt(0).toUpperCase() + category.slice(1);

      db.insert(riskItems).values({
        analysisId,
        clauseId: maxRiskClause.id,
        riskType: category,
        title: `${label} Risk — ${catClauses.length} clause${catClauses.length > 1 ? 's' : ''} found`,
        description: maxRiskClause.riskReason || maxRiskClause.plainEnglishText || `Clauses categorized as ${label}.`,
        severity,
        severityScore: score,
        recommendation: maxRiskClause.counterSuggestion || 'Review this clause for potential risk mitigation.',
        legalReference: '',
      }).run();
    }

    const generatedRiskItems = db.select().from(riskItems).where(
      sql`${riskItems.analysisId} = ${analysisId} AND ${riskItems.clauseId} IS NOT NULL`
    ).all();
    assert(generatedRiskItems.length === 4, '4 risk items generated from 4 categories (got ' + generatedRiskItems.length + ')');

    const privacyItem = generatedRiskItems.find((r) => r.riskType === 'privacy');
    assert(privacyItem !== undefined, 'Privacy category has a risk item');
    assert(privacyItem?.severity === 'critical', 'Privacy risk has critical severity (got ' + privacyItem?.severity + ')');
    assert(privacyItem?.severityScore === 95, 'Privacy risk has score 95 (got ' + privacyItem?.severityScore + ')');

    const financialItem = generatedRiskItems.find((r) => r.riskType === 'financial');
    assert(financialItem !== undefined, 'Financial category has a risk item');
    assert(financialItem?.severity === 'high', 'Financial risk has high severity (got ' + financialItem?.severity + ')');

    const terminationItem = generatedRiskItems.find((r) => r.riskType === 'termination');
    assert(terminationItem !== undefined, 'Termination category has a risk item');
    assert(terminationItem?.severity === 'medium', 'Termination risk has medium severity (got ' + terminationItem?.severity + ')');

    const legalItem = generatedRiskItems.find((r) => r.riskType === 'legal');
    assert(legalItem !== undefined, 'Legal category has a risk item');
    assert(legalItem?.severity === 'low', 'Legal risk has low severity (got ' + legalItem?.severity + ')');

    const privacyClauses = clauseRows.filter((c) => c.riskCategory === 'privacy');
    assert(privacyClauses.length === 1, 'Filtered clauses by privacy category returns 1 clause');
  }

  // ═══════════════════════════════════════════════════
  //  CLEANUP & SUMMARY
  // ═══════════════════════════════════════════════════
  closeDatabase();

  console.log('\n═══════════════════════════════════════════');
  const passed = results.filter((r) => r.pass).length;
  const failed = results.filter((r) => !r.pass).length;
  console.log(`\n  ${passed} passed, ${failed} failed, ${results.length} total`);
  if (failed > 0) {
    console.log('\n  Failed tests:');
    results.filter((r) => !r.pass).forEach((r) => console.log(`    ❌ ${r.test}${r.detail ? ` — ${r.detail}` : ''}`));
  }
  console.log('');
  process.exit(failed > 0 ? 1 : 0);
}

run().catch((err) => {
  console.error('Unhandled test error:', err);
  process.exit(1);
});
