// Lists (and with --apply removes) ARB keys no Dart code references.
// A key counts as used if `.key` appears anywhere in lib/ or test/ outside
// lib/l10n/gen. Removal is line-based so the ARB formatting stays as is.
const fs = require('fs');
const path = require('path');

// Run from anywhere: node scripts/unused_l10n.js [--apply]
const root = path.resolve(__dirname, '..');
const arbDir = path.join(root, 'lib/l10n');
const apply = process.argv.includes('--apply');

function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) {
      if (p.replace(/\\/g, '/').endsWith('lib/l10n/gen')) continue;
      walk(p, out);
    } else if (e.name.endsWith('.dart')) out.push(p);
  }
  return out;
}
const code = [...walk(path.join(root, 'lib')), ...walk(path.join(root, 'test'))]
  .map((f) => fs.readFileSync(f, 'utf8'))
  .join('\n');

const en = JSON.parse(fs.readFileSync(path.join(arbDir, 'app_en.arb'), 'utf8'));
const keys = Object.keys(en).filter((k) => !k.startsWith('@'));
const keep = /^(common|pending)/; // shared / in-flight (slip import)
const unused = keys.filter((k) => !keep.test(k)).filter((k) => !new RegExp(`\\.${k}\\b`).test(code));
console.log(`${unused.length} unused of ${keys.length}`);
console.log(unused.join('\n'));
if (!apply) process.exit(0);

for (const name of ['app_en.arb', 'app_th.arb']) {
  const file = path.join(arbDir, name);
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  const out = [];
  for (let i = 0; i < lines.length; i++) {
    const m = lines[i].match(/^\s*"(@?)([A-Za-z0-9_]+)"\s*:/);
    if (m && unused.includes(m[2])) {
      // Skip this entry; a multi-line value/object runs until braces balance.
      let depth = 0;
      for (let j = i; j < lines.length; j++) {
        for (const ch of lines[j]) {
          if (ch === '{') depth++;
          if (ch === '}') depth--;
        }
        if (depth <= 0) { i = j; break; }
      }
      continue;
    }
    out.push(lines[i]);
  }
  let text = out.join('\n');
  // Drop a dangling comma before the closing brace.
  text = text.replace(/,(\s*)\}\s*$/, '$1}\n');
  JSON.parse(text); // must still be valid
  fs.writeFileSync(file, text);
  console.log(name, 'written');
}
