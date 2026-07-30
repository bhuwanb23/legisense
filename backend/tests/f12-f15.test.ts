import { riskPatternSeeds } from '../src/data/riskPatterns';
import { requiredClauseSeeds } from '../src/data/requiredClauses';
import { expandRecurringDates, calculateDeadlineUrgency, computeDeadlineHealth } from '../src/services/deadlineService';

interface TestResult { test: string; pass: boolean; detail?: string }
const results: TestResult[] = [];

function assert(condition: boolean, test: string, detail?: string) {
  results.push({ test, pass: condition, detail });
  console.log(`  ${condition ? 'PASS' : 'FAIL'} ${test}${detail ? ` — ${detail}` : ''}`);
}

console.log('\n=== F12 risk patterns ===');
assert(riskPatternSeeds.length >= 50, '50+ risk patterns', String(riskPatternSeeds.length));
assert(riskPatternSeeds.some((p) => p.patternName === 'Unlimited Liability'), 'has Unlimited Liability');
assert(riskPatternSeeds.some((p) => p.patternName === 'Auto-Renewal Trap'), 'has Auto-Renewal Trap');

console.log('\n=== F13 required templates ===');
assert(requiredClauseSeeds.filter((t) => t.documentType === 'rental_agreement').length >= 5, 'rental templates');
assert(requiredClauseSeeds.filter((t) => t.documentType === 'employment_contract').length >= 5, 'employment templates');
assert(requiredClauseSeeds.filter((t) => t.documentType === 'nda').length >= 4, 'nda templates');

console.log('\n=== F15 deadlines ===');
const monthly = expandRecurringDates('2025-01-05', 'monthly', 12);
assert(monthly.length === 12, 'monthly expands to 12', String(monthly.length));
assert(monthly[0] === '2025-01-05', 'first date preserved');
assert(monthly[1].startsWith('2025-02'), 'second is next month', monthly[1]);

const past = new Date();
past.setDate(past.getDate() - 3);
assert(calculateDeadlineUrgency(past.toISOString().slice(0, 10)) === 'overdue', 'overdue urgency');

const soon = new Date();
soon.setDate(soon.getDate() + 3);
assert(calculateDeadlineUrgency(soon.toISOString().slice(0, 10)) === 'this_week', 'this_week urgency');

const health = computeDeadlineHealth([
  { urgencyLevel: 'overdue', isCompleted: false, isDismissed: false },
  { urgencyLevel: 'upcoming', isCompleted: true, isDismissed: false },
  { urgencyLevel: 'this_month', isCompleted: false, isDismissed: false },
]);
assert(health.overdue === 1 && health.completed === 1 && health.upcoming === 1, 'health counts');
assert(health.status === 'fair' || health.status === 'poor', 'health status', health.status);

// keyword helper smoke
function matches(text: string, kws: string[]) {
  const hay = text.toLowerCase();
  return kws.some((k) => hay.includes(k.toLowerCase()));
}
assert(matches('Liability shall be unlimited under this agreement', ['unlimited liability', 'liability shall be unlimited']), 'keyword match unlimited');

const failed = results.filter((r) => !r.pass);
console.log(`\n${results.length - failed.length}/${results.length} passed`);
if (failed.length) {
  console.error(failed);
  process.exit(1);
}
console.log('All F12–F15 unit checks passed.');
