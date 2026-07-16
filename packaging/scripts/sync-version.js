#!/usr/bin/env node
/**
 * Stamp packaging/VERSION into npm package.json files and Formula/grok-cli.rb
 * placeholders that use {{VERSION}}.
 *
 * Usage: node packaging/scripts/sync-version.js
 */
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..', '..');
const versionPath = path.join(root, 'packaging', 'VERSION');
const version = fs.readFileSync(versionPath, 'utf8').trim();

if (!/^\d+\.\d+\.\d+([.-][0-9A-Za-z.-]+)?$/.test(version)) {
  console.error(`Invalid version in packaging/VERSION: ${JSON.stringify(version)}`);
  process.exit(1);
}

const npmRoot = path.join(root, 'packaging', 'npm');
const packages = [
  'grok-cli',
  'grok-cli-darwin-arm64',
  'grok-cli-darwin-x64',
];

for (const name of packages) {
  const pkgPath = path.join(npmRoot, name, 'package.json');
  const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
  pkg.version = version;
  if (pkg.optionalDependencies) {
    for (const key of Object.keys(pkg.optionalDependencies)) {
      if (key.startsWith('@spikewang/')) {
        pkg.optionalDependencies[key] = version;
      }
    }
  }
  fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 4) + '\n');
  console.log(`[sync-version] ${path.relative(root, pkgPath)} -> ${version}`);
}

// Formula: replace version "..." and leave sha256 to the release job.
const formulaPath = path.join(root, 'Formula', 'grok-cli.rb');
if (fs.existsSync(formulaPath)) {
  let formula = fs.readFileSync(formulaPath, 'utf8');
  formula = formula.replace(/version\s+"[^"]+"/, `version "${version}"`);
  // URL version segments: /download/vX.Y.Z/grok-cli-X.Y.Z-darwin-
  formula = formula.replace(
    /releases\/download\/v[^/]+\/grok-cli-[^-]+-darwin-/g,
    `releases/download/v${version}/grok-cli-${version}-darwin-`,
  );
  // Also handle urls that already use full asset names without prior rewrite
  formula = formula.replace(
    /grok-cli-\d+\.\d+\.\d+(?:[.-][0-9A-Za-z.-]+)?-darwin-/g,
    `grok-cli-${version}-darwin-`,
  );
  formula = formula.replace(
    /download\/v\d+\.\d+\.\d+(?:[.-][0-9A-Za-z.-]+)?\//g,
    `download/v${version}/`,
  );
  fs.writeFileSync(formulaPath, formula);
  console.log(`[sync-version] Formula/grok-cli.rb -> ${version}`);
}

console.log(`[sync-version] version=${version}`);
