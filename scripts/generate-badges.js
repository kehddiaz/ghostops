// CI retrigger Wed Sep 24 03:52:16 PM UTC 2025
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { makeBadge } = require('badge-maker');

// Paths
const dataFile = path.resolve(__dirname, '../milestones/milestones.json');
const outDir   = path.resolve(__dirname, '../badges');

if (!fs.existsSync(outDir)) {
  fs.mkdirSync(outDir, { recursive: true });
}

// Load milestones
const { milestones } = JSON.parse(fs.readFileSync(dataFile, 'utf-8'));

milestones.forEach(({ id, name, status, level }) => {
  // Choose color by status (or by level if you like)
  const color = status === 'completed' ? 'brightgreen' : 'orange';

  const format = {
    label: name,
    message: status,
    color,
    style: 'flat',
  };

  const svg = makeBadge(format);
  fs.writeFileSync(path.join(outDir, `${id}.svg`), svg);
  console.log(`• Generated badge: ${id}.svg`);
});
