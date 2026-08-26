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

  // Add await to Drizzle select queries missing it
  // Pattern: = db.select(  -> await db.select(
  content = content.replace(/(\s)= db\.select\(/g, '$1= await db.select(');

  // Pattern: = db.insert(  -> await db.insert(
  content = content.replace(/(\s)= db\.insert\(/g, '$1= await db.insert(');

  // Pattern: = db.update(  -> await db.update(
  content = content.replace(/(\s)= db\.update\(/g, '$1= await db.update(');

  // Pattern: = db.delete(  -> await db.delete(
  content = content.replace(/(\s)= db\.delete\(/g, '$1= await db.delete(');

  // Also handle: .select( without = prefix (standalone calls)
  // These are typically: db.select()...  without variable assignment
  // Skip these as they're usually already awaited or are fire-and-forget

  // Fix: non-async functions that now need await
  // Add async to functions that contain await but aren't async
  // This is complex, skip for now

  if (content !== original) {
    fs.writeFileSync(filePath, content);
    console.log('Added await:', path.relative('src', filePath));
    totalFixed++;
  }
}

console.log('Total files fixed:', totalFixed);
