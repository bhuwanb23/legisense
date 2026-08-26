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

  // The db.all() replacement created: (await db.execute(sql`...`)
  // where the closing ) was from the original db.all() call
  // This leaves the opening ( unmatched
  // Fix: find (await db.execute(` ... `) and add .rows and closing )
  
  // Strategy: find all occurrences of (await db.execute( and ensure they have
  // a matching ) with .rows before any 'as' keyword or end of assignment
  
  // Pattern 1: (await db.execute(sql`...`)) as Type  -- already has double )), just add .rows
  // Pattern 2: (await db.execute(sql`...`) as Type   -- missing ), add ) and .rows
  
  // Use a state-machine approach to find balanced parens after (await db.execute(
  const lines = content.split('\n');
  const newLines = [];
  
  for (let i = 0; i < lines.length; i++) {
    let line = lines[i];
    
    // Fix: (await db.execute(sql`...`) as -> (await db.execute(sql`...`)).rows as
    // This handles the case where ) closes db.execute but (await is unmatched
    if (line.includes('(await db.execute(') && line.includes(' as ')) {
      // Find the pattern: (await db.execute(something) as Type
      // The ) before 'as' closes db.execute, but we need another ) for (await
      // and .rows for the QueryResult
      line = line.replace(
        /\(await db\.execute\(([^)]+\)`)\) as /g,
        '((await db.execute($1`)).rows) as '
      );
      // Also handle single-close: (await db.execute(sql`...`) as
      line = line.replace(
        /\(await db\.execute\(([^)]+)\) as /g,
        '((await db.execute($1)).rows) as '
      );
    }
    
    newLines.push(line);
  }
  
  content = newLines.join('\n');
  
  if (content !== original) {
    fs.writeFileSync(filePath, content);
    console.log('Fixed:', path.relative('src', filePath));
    totalFixed++;
  }
}

// Now check for remaining (await db.execute without proper closing
for (const filePath of files) {
  let content = fs.readFileSync(filePath, 'utf8');
  let original = content;
  
  // Find lines with (await db.execute that assign to a variable and end with just )
  // These need .rows added
  const lines = content.split('\n');
  const newLines = [];
  
  for (let i = 0; i < lines.length; i++) {
    let line = lines[i];
    
    // Pattern: const x = (await db.execute(sql`...`));
    // This is correct but the result is QueryResult, not rows
    // We need: const x = (await db.execute(sql`...`)).rows;
    
    if (line.match(/const \w+ = \(await db\.execute\(/) && line.endsWith(');')) {
      // Check if it already has .rows
      if (!line.includes('.rows')) {
        line = line.replace(/\);$/, ')).rows;');
        // Fix double ) issue
        line = line.replace(/\(\(await db\.execute\(/, '(await db.execute(');
      }
    }
    
    newLines.push(line);
  }
  
  content = newLines.join('\n');
  
  if (content !== original) {
    fs.writeFileSync(filePath, content);
    console.log('Fixed rows:', path.relative('src', filePath));
    totalFixed++;
  }
}

console.log('Total fixes:', totalFixed);
