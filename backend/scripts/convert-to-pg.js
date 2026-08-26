const fs = require('fs');
const path = require('path');

function findTsFiles(dir, exclude = []) {
  const files = [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory() && !exclude.includes(entry.name)) {
      files.push(...findTsFiles(fullPath, exclude));
    } else if (entry.isFile() && entry.name.endsWith('.ts') && !exclude.includes(entry.name)) {
      files.push(fullPath);
    }
  }
  return files;
}

const srcDir = path.join(__dirname, '..', 'src');
const files = findTsFiles(srcDir, ['models', 'node_modules']);

let totalFiles = 0;

for (const filePath of files) {
  let content = fs.readFileSync(filePath, 'utf8');
  let original = content;

  // 1. Fix datetime('now') -> NOW() in SQL template literals
  content = content.replace(/datetime\('now'\)/g, "NOW()");

  // 2. Convert db.run(sql`...`) to await db.execute(sql`...`)
  // Match: db.run(sql`...`) where the template can span multiple lines
  content = content.replace(/\bdb\.run\(/g, 'await db.execute(');

  // 3. Remove .all() suffix from Drizzle query builder calls
  // These are synchronous in sql.js but return Promises in pg
  // Pattern: ).all() at end of statement
  content = content.replace(/\)\s*\.all\(\)/g, ')');

  // 4. Convert db.all(sql`...`) to (await db.execute(sql`...`)).rows
  // Need to find closing `) and add .rows
  // Simple approach: replace db.all( with (await db.execute( and we'll fix .rows separately
  content = content.replace(/\bdb\.all\(/g, '(await db.execute(');

  // 5. Remove .run() suffix from insert/update/delete
  // Pattern: ).run() or .run(); at end
  content = content.replace(/\)\s*\.run\(\)/g, ')');
  content = content.replace(/\.run\(\);/g, ';');

  if (content !== original) {
    fs.writeFileSync(filePath, content);
    totalFiles++;
    console.log('Updated:', path.relative(srcDir, filePath));
  }
}

console.log(`\nTotal files updated: ${totalFiles}`);
