import { buildIcsCalendar } from '../src/services/icsExportService';
import { daysUntilDue, shouldSendReminder } from '../src/queue/scheduledJobs';
import { parseCitations, resolveCitations } from '../src/services/citationParserService';
import { retrieveRelevantClauses, scoreClause, tokenize } from '../src/services/chatRetrievalService';

interface TestResult { test: string; pass: boolean; detail?: string }
const results: TestResult[] = [];

function assert(condition: boolean, test: string, detail?: string) {
  results.push({ test, pass: condition, detail });
  console.log(`  ${condition ? 'PASS' : 'FAIL'} ${test}${detail ? ` — ${detail}` : ''}`);
}

console.log('\n=== F16 ICS export ===');
const ics = buildIcsCalendar([
  {
    id: 1,
    title: 'Notice Period; Renewal',
    description: 'Line1\nLine2',
    dueDate: '2026-08-15',
    consequenceIfMissed: 'Contract auto-renews',
    documentName: 'Lease, Unit A',
  },
  {
    id: 2,
    title: 'Payment Due',
    dueDate: '2026-09-01',
  },
]);

assert(ics.includes('BEGIN:VCALENDAR'), 'has VCALENDAR');
assert(ics.includes('BEGIN:VEVENT'), 'has VEVENT');
assert(ics.includes('DTSTART;VALUE=DATE:20260815'), 'all-day DTSTART');
assert(ics.includes('BEGIN:VALARM'), 'has VALARM');
assert(ics.includes('TRIGGER:-P2D'), 'VALARM 2 days before');
assert(ics.includes('Notice Period\\; Renewal'), 'escapes semicolons');
assert(ics.includes('Lease\\, Unit A') || ics.includes('Lease\\, Unit A'), 'escapes commas');
assert((ics.match(/BEGIN:VEVENT/g) || []).length === 2, 'two events');

console.log('\n=== F17 reminder day matching ===');
const today = new Date(2026, 6, 30); // Jul 30, 2026 local
assert(daysUntilDue('2026-07-31', today) === 1, 'due tomorrow = 1', String(daysUntilDue('2026-07-31', today)));
assert(daysUntilDue('2026-07-30', today) === 0, 'due today = 0');
assert(daysUntilDue('2026-08-06', today) === 7, 'due in 7 days');
assert(shouldSendReminder(1, [7, 3, 1], []), 'send when day matches');
assert(!shouldSendReminder(1, [7, 3, 1], [1]), 'skip already sent day');
assert(!shouldSendReminder(2, [7, 3, 1], []), 'skip non-matching day');
assert(shouldSendReminder(3, [7, 3, 1], [7]), 'send other configured day');

console.log('\n=== F18 retrieval ===');
const clauses = [
  {
    id: 10,
    clauseNumber: 5,
    clauseTitle: 'Early Termination',
    originalText: 'Either party may terminate this agreement early with 30 days written notice.',
    plainEnglishText: 'You can end the contract early by giving 30 days notice.',
    pageNumber: 4,
  },
  {
    id: 11,
    clauseNumber: 8,
    clauseTitle: 'Governing Law',
    originalText: 'This agreement is governed by the laws of California.',
    plainEnglishText: null,
    pageNumber: 7,
  },
];

assert(tokenize('Can I terminate early?').includes('terminate'), 'tokenize question');
assert(scoreClause('Can I terminate early?', clauses[0]) > scoreClause('Can I terminate early?', clauses[1]), 'termination scores higher');
const top = retrieveRelevantClauses('Can I terminate early?', clauses, 5, 0.15);
assert(top.length >= 1 && top[0].id === 10, 'retrieves termination clause');
assert(retrieveRelevantClauses('quantum physics spaceship thrusters', clauses, 5, 0.5).length === 0, 'unrelated below threshold');

console.log('\n=== F19 citation parser ===');
const answer = 'Yes, you may terminate early with notice.\n[Clause 5 — Early Termination] (Page 4)';
const parsed = parseCitations(answer);
assert(parsed.length === 1 && parsed[0].clauseNumber === 5, 'parses clause number');
assert(parsed[0].page === 4, 'parses page');

const resolved = resolveCitations(answer, clauses);
assert(resolved.citationConfidence === 'high', 'high confidence with match');
assert(resolved.citedClauseIds.includes(10), 'maps to clause id');
assert(resolved.citedClauses[0].title === 'Early Termination', 'cited title');

const low = resolveCitations('No citations here.', clauses);
assert(low.citationConfidence === 'low', 'low without citations');
assert(low.citedClauseIds.length === 0, 'no fake ids');

const failed = results.filter((r) => !r.pass);
console.log(`\n${results.length - failed.length}/${results.length} passed`);
if (failed.length) {
  console.error(failed);
  process.exit(1);
}
console.log('All F16–F19 unit checks passed.');
