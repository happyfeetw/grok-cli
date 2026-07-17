#!/usr/bin/env node
/**
 * Extract one Keep-a-Changelog section from CHANGELOG.md for GitHub Releases.
 *
 * Usage:
 *   node packaging/scripts/extract-changelog.js --version 0.1.222
 *   node packaging/scripts/extract-changelog.js --version 0.1.222 --out /tmp/notes.md
 *
 * Prints the section body (without the ## heading) to stdout, or writes --out.
 */
const fs = require('fs');
const path = require('path');

function arg(name) {
  const i = process.argv.indexOf(`--${name}`);
  if (i === -1 || !process.argv[i + 1]) return null;
  return process.argv[i + 1];
}

const version = arg('version');
if (!version) {
  console.error('usage: extract-changelog.js --version <semver> [--out path]');
  process.exit(1);
}

const root = path.resolve(__dirname, '..', '..');
const changelogPath = path.join(root, 'CHANGELOG.md');
const text = fs.readFileSync(changelogPath, 'utf8');

// Match "## [0.1.222] - 2026-07-17" or "## [0.1.222]"
const headerRe = new RegExp(
  `^## \\[${version.replace(/\./g, '\\.')}\\](?:\\s*-\\s*[^\\n]+)?\\s*$`,
  'm'
);
const headerMatch = headerRe.exec(text);
if (!headerMatch) {
  console.error(`[extract-changelog] no section for ${version} in ${changelogPath}`);
  process.exit(1);
}

const start = headerMatch.index + headerMatch[0].length;
const rest = text.slice(start);
// Next top-level ## heading or EOF (ignore link reference lines at bottom)
const next = rest.search(/^## \[/m);
let body = (next === -1 ? rest : rest.slice(0, next)).trimEnd();

// Drop trailing compare-link definitions if they leaked in (should not)
body = body.replace(/\n\[[^\]]+\]:\s+https?:\/\/\S+\s*$/g, '').trim();

const out = arg('out');
if (out) {
  fs.writeFileSync(out, body + '\n');
  console.error(`[extract-changelog] wrote ${out} (${body.length} chars)`);
} else {
  process.stdout.write(body + '\n');
}
