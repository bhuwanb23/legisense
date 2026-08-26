const fs = require('fs');
const path = require('path');

// Copy non-TS assets that tsc doesn't handle
const assets = [
  ['src/config/schema.sql', 'dist/config/schema.sql'],
];

for (const [src, dest] of assets) {
  const srcPath = path.join(__dirname, '..', src);
  const destPath = path.join(__dirname, '..', dest);
  fs.mkdirSync(path.dirname(destPath), { recursive: true });
  fs.copyFileSync(srcPath, destPath);
  console.log(`Copied ${src} -> ${dest}`);
}
