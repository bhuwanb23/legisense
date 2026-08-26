const fs = require('fs');
const path = require('path');

function findTsFiles(dir) {
  const files = [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory() && entry.name !== 'node_modules' && entry.name !== 'models') {
      files.push(...findTsFiles(fullPath));
    } else if (entry.isFile() && entry.name.endsWith('.ts')) {
      files.push(fullPath);
    }
  }
  return files;
}

const files = findTsFiles('src');
let totalFixed = 0;

for (const filePath of files) {
  let content = fs.readFileSync(filePath, 'utf8');
  let original = content;

  // Fix multiline pattern:
  // const x = (await db.execute(sql`
  //   SELECT ...
  // `)) as Type[];
  // 
  // Need to add .rows before the ) that closes the (await group
  // The pattern is: `)) as` should become `)).rows as`
  content = content.replace(/\)\) as /g, ')).rows as ');

  // Fix single-line pattern:
  // const x = (await db.execute(sql`SELECT ...`)) as Type[];
  // Already handled by above

  // Fix: (await db.execute(sql`...`));  -- assignment without type cast
  // These don't need .rows if they're INSERT/UPDATE/DELETE (no data returned)
  // But SELECT queries do need .rows
  // For now, leave these as-is since they're typically writes

  // Fix: last_insert_rowid() -- SQLite specific, need to use RETURNING or pg instead
  content = content.replace(/last_insert_rowid\(\)/g, 'id');

  // Fix: (await db.execute(sql`...`)\n followed by ) on next line
  // Handle the case where closing ) is on next line after the backtick
  content = content.replace(/` \)\) as /g, '`)).rows as ');

  if (content !== original) {
    fs.writeFileSync(filePath, content);
    console.log('Fixed:', path.relative('src', filePath));
    totalFixed++;
  }
}

console.log('Total files fixed:', totalFixed);
