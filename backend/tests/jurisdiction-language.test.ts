import { clauseMatchesKeywords, parseUserJurisdiction } from '../src/services/jurisdictionCheckService';
import { getNeighborStates } from '../src/data/neighboringStates';
import { detectLanguage, toIso6391 } from '../src/services/languageDetectionService';
import { SUPPORTED_LANGUAGES, isSupportedLanguage } from '../src/config/languages';
import { legalRuleSeeds } from '../src/data/legalRules';
import { jurisdictionSeeds } from '../src/data/jurisdictions';

interface TestResult { test: string; pass: boolean; detail?: string }
const results: TestResult[] = [];

function assert(condition: boolean, test: string, detail?: string) {
  results.push({ test, pass: condition, detail });
  console.log(`  ${condition ? 'PASS' : 'FAIL'} ${test}${detail ? ` — ${detail}` : ''}`);
}

console.log('\n=== F9 keyword matching ===');
assert(clauseMatchesKeywords('Employee shall not compete with Company', ['non-compete', 'shall not compete']), 'matches non-compete phrase');
assert(!clauseMatchesKeywords('Payment is due monthly', ['non-compete']), 'no false positive');
assert(clauseMatchesKeywords('SECURITY DEPOSIT of three months', ['security deposit']), 'case insensitive');

console.log('\n=== F9 jurisdiction parse ===');
const j1 = parseUserJurisdiction(JSON.stringify({ country: 'IN', state: 'MH', history: [{ country: 'IN', state: 'DL' }] }));
assert(j1.countryCode === 'IN' && j1.stateCode === 'MH', 'parses JSON jurisdiction');
assert(j1.history.length === 1 && j1.history[0].stateCode === 'DL', 'parses history');
const j2 = parseUserJurisdiction('IN-KA');
assert(j2.countryCode === 'IN' && j2.stateCode === 'KA', 'parses IN-KA string');

console.log('\n=== F9 seed coverage ===');
assert(jurisdictionSeeds.filter((j) => j.countryCode === 'IN' && j.stateCode).length >= 36, 'India states+UTs seeded', String(jurisdictionSeeds.filter((j) => j.countryCode === 'IN' && j.stateCode).length));
assert(jurisdictionSeeds.filter((j) => j.countryCode === 'US' && j.stateCode).length >= 50, 'US states seeded');
assert(legalRuleSeeds.length >= 30, 'legal rules MVP count', String(legalRuleSeeds.length));
assert(legalRuleSeeds.some((r) => r.conflictingJurisdictions && r.conflictingJurisdictions.length > 0), 'rules include conflicts for F10');

console.log('\n=== F10 neighbors ===');
const mhNeighbors = getNeighborStates('IN', 'MH');
assert(mhNeighbors.includes('GJ') && mhNeighbors.includes('KA'), 'Maharashtra neighbors');
assert(getNeighborStates('US', 'CA').includes('OR'), 'California neighbors');

console.log('\n=== F11 languages ===');
assert(SUPPORTED_LANGUAGES.length >= 37, '37+ languages', String(SUPPORTED_LANGUAGES.length));
assert(isSupportedLanguage('hi') && isSupportedLanguage('ta') && isSupportedLanguage('es'), 'hi/ta/es supported');
assert(toIso6391('eng') === 'en' && toIso6391('hin') === 'hi', 'iso3 mapping');

const en = detectLanguage('This Non-Disclosure Agreement is entered into by and between Acme Corporation and John Doe regarding confidential information.');
assert(en.language === 'en', 'detects English', en.language);

const hi = detectLanguage('यह एक गोपनीयता समझौता है जो दो पक्षों के बीच किया गया है। इसमें गोपनीय जानकारी की सुरक्षा और कानूनी दायित्वों का उल्लेख है। यह दस्तावेज़ भारतीय अनुबंध अधिनियम के अंतर्गत आता है।');
assert(hi.language === 'hi', 'detects Hindi', hi.language);

const failed = results.filter((r) => !r.pass);
console.log(`\n${results.length - failed.length}/${results.length} passed`);
if (failed.length) {
  console.error('Failures:', failed);
  process.exit(1);
}
console.log('All F9–F11 unit checks passed.');
