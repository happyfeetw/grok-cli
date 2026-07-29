#!/usr/bin/env node
/**
 * Add a deterministic changelog section for an automated upstream merge.
 *
 * Usage:
 *   node packaging/scripts/prepare-upstream-changelog.js \
 *     --upstream-sha <full-sha> [--date YYYY-MM-DD]
 */
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..', '..');
const args = process.argv.slice(2);

function option(name) {
  const index = args.indexOf(name);
  if (index === -1) return undefined;
  if (index + 1 >= args.length) {
    throw new Error(`${name} requires a value`);
  }
  return args[index + 1];
}

const upstreamSha = option('--upstream-sha');
const releaseDate = option('--date') || new Date().toISOString().slice(0, 10);

if (!upstreamSha || !/^[0-9a-f]{40}$/i.test(upstreamSha)) {
  throw new Error('--upstream-sha must be a full 40-character Git SHA');
}
if (!/^\d{4}-\d{2}-\d{2}$/.test(releaseDate)) {
  throw new Error('--date must use YYYY-MM-DD');
}

const versionPath = path.join(root, 'packaging', 'VERSION');
const changelogPath = path.join(root, 'CHANGELOG.md');
const version = fs.readFileSync(versionPath, 'utf8').trim();
const changelog = fs.readFileSync(changelogPath, 'utf8');
const heading = `## [${version}]`;

if (changelog.includes(heading)) {
  console.log(`[prepare-upstream-changelog] ${heading} already exists`);
  process.exit(0);
}

const unreleased = /^## \[Unreleased\][^\n]*\n/m;
const match = changelog.match(unreleased);
if (!match || match.index === undefined) {
  throw new Error('CHANGELOG.md is missing a ## [Unreleased] heading');
}

const insertAt = match.index + match[0].length;
const section = [
  '',
  `## [${version}] - ${releaseDate}`,
  '',
  '### Changed',
  '',
  `- Merged upstream \`xai-org/grok-build\` through \`${upstreamSha.slice(0, 12)}\`.`,
  '- Preserved this fork’s `grok-cli` branding, `@spikewang` packaging,',
  '  `system-proxy` support, and strict upstream third-party dependency pins.',
  '',
].join('\n');

const updated = changelog.slice(0, insertAt) + section + changelog.slice(insertAt);
fs.writeFileSync(changelogPath, updated);
console.log(`[prepare-upstream-changelog] added ${heading}`);
