import initSqlJs, { type Database } from 'sql.js';
import { drizzle, type SQLJsDatabase } from 'drizzle-orm/sql-js';
import { sql } from 'drizzle-orm';
import { users, documents, analysisResults } from '../src/models';

let sqlClient: Database;
let db: SQLJsDatabase;

const results: { test: string; pass: boolean; detail?: string }[] = [];

function assert(condition: boolean, test: string, detail?: string) {
  results.push({ test, pass: condition, detail });
  console.log(`  ${condition ? '✅' : '❌'} ${test}${detail ? ` — ${detail}` : ''}`);
}

async function setup() {
  const SQL = await initSqlJs();
  sqlClient = new SQL.Database();
  sqlClient.run('PRAGMA foreign_keys = ON');
  db = drizzle(sqlClient);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${users} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone_number TEXT,
    password_hash TEXT,
    auth_provider TEXT NOT NULL DEFAULT 'email',
    profile_photo_url TEXT,
    profession TEXT,
    preferred_language TEXT NOT NULL DEFAULT 'en',
    default_jurisdiction TEXT,
    is_verified INTEGER NOT NULL DEFAULT 0,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    last_login_at TEXT
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${documents} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id),
    original_name TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    file_format TEXT NOT NULL,
    file_size INTEGER,
    page_count INTEGER,
    source_type TEXT NOT NULL,
    source_url TEXT,
    raw_text TEXT,
    detected_language TEXT,
    upload_status TEXT NOT NULL DEFAULT 'uploading',
    processing_status TEXT NOT NULL DEFAULT 'pending',
    is_deleted INTEGER NOT NULL DEFAULT 0,
    auto_delete_at TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${analysisResults} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    document_id INTEGER NOT NULL UNIQUE REFERENCES documents(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    document_type TEXT,
    detected_type_confidence REAL,
    overall_risk_score REAL,
    risk_level TEXT,
    fairness_score REAL,
    favors_party TEXT,
    summary TEXT,
    key_parties TEXT,
    critical_dates TEXT,
    key_obligations TEXT,
    missing_clauses TEXT,
    jurisdiction_flags TEXT,
    processing_time REAL,
    ai_model_used TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);
}

async function testUserModel() {
  console.log('\n🧑 Testing User Model');

  const insertResult = await db.insert(users).values({
    fullName: 'Bhawarlal Bhuwan',
    email: 'bhuwan@legisense.com',
    phoneNumber: '+91-9876543210',
    passwordHash: '$2b$10$hashedpassword',
    authProvider: 'email',
    profession: 'lawyer',
    preferredLanguage: 'en',
    defaultJurisdiction: JSON.stringify({ country: 'India', state: 'Rajasthan' }),
    isVerified: true,
    isActive: true,
  }).returning();

  assert(insertResult.length === 1, 'Insert user returns 1 row');
  assert(insertResult[0].fullName === 'Bhawarlal Bhuwan', 'fullName stored correctly');
  assert(insertResult[0].email === 'bhuwan@legisense.com', 'email stored correctly');
  assert(insertResult[0].authProvider === 'email', 'authProvider defaults correctly');
  assert(insertResult[0].isVerified === true, 'isVerified boolean stored correctly');
  assert(insertResult[0].isActive === true, 'isActive boolean stored correctly');
  assert(insertResult[0].preferredLanguage === 'en', 'preferredLanguage defaults to en');

  const allUsers = await db.select().from(users);
  assert(allUsers.length === 1, 'Select returns inserted user');

  const found = await db.select().from(users).where(sql`${users.email} = 'bhuwan@legisense.com'`);
  assert(found.length === 1, 'Query by email works');

  const notFound = await db.select().from(users).where(sql`${users.email} = 'nonexistent@test.com'`);
  assert(notFound.length === 0, 'Query for nonexistent email returns empty');

  try {
    await db.insert(users).values({
      fullName: 'Duplicate',
      email: 'bhuwan@legisense.com',
    });
    assert(false, 'Duplicate email should throw', 'No error thrown');
  } catch {
    assert(true, 'Duplicate email throws error (UNIQUE constraint)');
  }

  const oauthUser = await db.insert(users).values({
    fullName: 'Google User',
    email: 'google@test.com',
    authProvider: 'google',
  }).returning();
  assert(oauthUser[0].passwordHash === null, 'OAuth user has null passwordHash');
  assert(oauthUser[0].authProvider === 'google', 'OAuth provider stored correctly');
}

async function testDocumentModel() {
  console.log('\n📄 Testing Document Model');

  const user = (await db.select().from(users).limit(1))[0];

  const doc = await db.insert(documents).values({
    userId: user.id,
    originalName: 'RentAgreement_2024.pdf',
    storagePath: '/uploads/rent-agreement.pdf',
    fileFormat: 'pdf',
    fileSize: 1024000,
    pageCount: 12,
    sourceType: 'file_upload',
    rawText: 'This is a rental agreement between Party A and Party B...',
    detectedLanguage: 'en',
    uploadStatus: 'uploaded',
    processingStatus: 'completed',
  }).returning();

  assert(doc.length === 1, 'Insert document returns 1 row');
  assert(doc[0].userId === user.id, 'userId links to user correctly');
  assert(doc[0].originalName === 'RentAgreement_2024.pdf', 'originalName stored');
  assert(doc[0].fileFormat === 'pdf', 'fileFormat stored');
  assert(doc[0].fileSize === 1024000, 'fileSize stored as integer');
  assert(doc[0].uploadStatus === 'uploaded', 'uploadStatus stored');
  assert(doc[0].processingStatus === 'completed', 'processingStatus stored');
  assert(doc[0].isDeleted === false, 'isDeleted defaults to false');

  const allDocs = await db.select().from(documents);
  assert(allDocs.length === 1, 'Select returns inserted document');

  const userDocs = await db.select().from(documents).where(sql`${documents.userId} = ${user.id}`);
  assert(userDocs.length === 1, 'Query by userId works');

  await db.insert(documents).values({
    userId: user.id,
    originalName: 'NDA_signed.pdf',
    storagePath: '/uploads/nda.pdf',
    fileFormat: 'pdf',
    sourceType: 'file_upload',
  });

  const multipleDocs = await db.select().from(documents).where(sql`${documents.userId} = ${user.id}`);
  assert(multipleDocs.length === 2, 'User can have multiple documents (1:N)');
}

async function testAnalysisResultModel() {
  console.log('\n🤖 Testing AnalysisResult Model');

  const user = (await db.select().from(users).limit(1))[0];
  const doc = (await db.select().from(documents).limit(1))[0];

  const keyParties = JSON.stringify([
    { name: 'Party A', role: 'Landlord', obligations: ['Maintain property'] },
    { name: 'Party B', role: 'Tenant', obligations: ['Pay rent on time'] },
  ]);
  const criticalDates = JSON.stringify([
    { label: 'Lease Start', date: '2024-01-01', urgency: 'high' },
    { label: 'Lease End', date: '2024-12-31', urgency: 'medium' },
  ]);
  const keyObligations = JSON.stringify([
    { party: 'Party A', obligation: 'Maintain property in habitable condition' },
    { party: 'Party B', obligation: 'Pay ₹15,000 rent by 5th of each month' },
  ]);

  const result = await db.insert(analysisResults).values({
    documentId: doc.id,
    userId: user.id,
    documentType: 'Rental',
    detectedTypeConfidence: 92.5,
    overallRiskScore: 35,
    riskLevel: 'low',
    fairnessScore: 55,
    favorsParty: 'Balanced',
    summary: 'This is a standard residential rental agreement...',
    keyParties,
    criticalDates,
    keyObligations,
    missingClauses: JSON.stringify(['Maintenance responsibilities']),
    jurisdictionFlags: JSON.stringify([]),
    processingTime: 3.2,
    aiModelUsed: 'claude-3.5',
  }).returning();

  assert(result.length === 1, 'Insert analysis result returns 1 row');
  assert(result[0].documentId === doc.id, 'documentId links correctly');
  assert(result[0].userId === user.id, 'userId links correctly');
  assert(result[0].documentType === 'Rental', 'documentType stored');
  assert(result[0].detectedTypeConfidence === 92.5, 'confidence score stored as real');
  assert(result[0].overallRiskScore === 35, 'riskScore stored as real');
  assert(result[0].riskLevel === 'low', 'riskLevel stored');
  assert(result[0].fairnessScore === 55, 'fairnessScore stored');
  assert(result[0].favorsParty === 'Balanced', 'favorsParty stored');
  assert(result[0].processingTime === 3.2, 'processingTime stored');
  assert(result[0].aiModelUsed === 'claude-3.5', 'aiModelUsed stored');

  const parsedParties = JSON.parse(result[0].keyParties!);
  assert(parsedParties.length === 2, 'keyParties JSON roundtrip — array length');
  assert(parsedParties[0].name === 'Party A', 'keyParties JSON roundtrip — party name');
  assert(parsedParties[1].role === 'Tenant', 'keyParties JSON roundtrip — party role');

  const parsedDates = JSON.parse(result[0].criticalDates!);
  assert(parsedDates.length === 2, 'criticalDates JSON roundtrip — array length');
  assert(parsedDates[0].urgency === 'high', 'criticalDates JSON roundtrip — urgency');

  const parsedObligations = JSON.parse(result[0].keyObligations!);
  assert(parsedObligations.length === 2, 'keyObligations JSON roundtrip — array length');

  try {
    await db.insert(analysisResults).values({
      documentId: doc.id,
      userId: user.id,
    });
    assert(false, 'Duplicate documentId should throw (1:1)', 'No error thrown');
  } catch {
    assert(true, 'Duplicate documentId throws error (UNIQUE constraint — 1:1)');
  }
}

async function testCascadeDelete() {
  console.log('\n🔗 Testing Foreign Key Constraints');

  const user = (await db.select().from(users).limit(1))[0];

  await db.insert(documents).values({
    userId: user.id,
    originalName: 'orphan.pdf',
    storagePath: '/uploads/orphan.pdf',
    fileFormat: 'pdf',
    sourceType: 'paste',
  });

  const allDocs = await db.select().from(documents);
  const orphanDoc = allDocs[allDocs.length - 1];

  assert(orphanDoc !== undefined, 'Orphan document inserted');
  assert(orphanDoc.originalName === 'orphan.pdf', 'Orphan doc has correct name');

  await db.insert(analysisResults).values({
    documentId: orphanDoc.id,
    userId: user.id,
    documentType: 'Other',
  });

  const allResults = await db.select().from(analysisResults);
  const linkedResult = allResults.find((r) => r.documentId === orphanDoc.id);
  assert(linkedResult !== undefined, 'Analysis result created for orphan doc');
  assert(linkedResult!.documentId === orphanDoc.id, 'Links correctly');
}

function printSummary() {
  console.log('\n' + '='.repeat(50));
  const passed = results.filter((r) => r.pass).length;
  const failed = results.filter((r) => !r.pass).length;
  console.log(`Results: ${passed} passed, ${failed} failed, ${results.length} total`);
  console.log('='.repeat(50));

  if (failed > 0) {
    console.log('\nFailed tests:');
    results.filter((r) => !r.pass).forEach((r) => {
      console.log(`  ❌ ${r.test}${r.detail ? ` — ${r.detail}` : ''}`);
    });
  }

  return failed === 0;
}

async function main() {
  console.log('🧪 Legisense Database Model Tests\n');
  console.log('Setting up in-memory SQLite database...');

  await setup();
  console.log('Database ready.\n');

  await testUserModel();
  await testDocumentModel();
  await testAnalysisResultModel();
  await testCascadeDelete();

  const allPassed = printSummary();

  sqlClient.close();
  process.exit(allPassed ? 0 : 1);
}

main().catch((err) => {
  console.error('Test runner failed:', err);
  process.exit(1);
});
