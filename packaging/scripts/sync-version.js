#!/usr/bin/env node
/**
 * Stamp packaging/VERSION into packaging surfaces and the shipping Cargo
 * packages (official-style: binary crate version aligns with product/npm).
 *
 * - packaging/npm package.json files
 * - Formula/grok-cli.rb (version + URL placeholders)
 * - xai-grok-pager-bin / xai-grok-pager / xai-grok-version Cargo.toml
 *   (unstamped local builds fall back to CARGO_PKG_VERSION)
 *
 * Release CI still sets GROK_VERSION at compile time (upstream contract).
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
  formula = formula.replace(
    /releases\/download\/v[^/]+\/grok-cli-[^-]+-darwin-/g,
    `releases/download/v${version}/grok-cli-${version}-darwin-`,
  );
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

// Shipping crates: keep Cargo version aligned with product/npm so unstamped
// local builds (no GROK_VERSION) report the same semver as packaging.
const cargoTomls = [
  'crates/codegen/xai-grok-pager-bin/Cargo.toml',
  'crates/codegen/xai-grok-pager/Cargo.toml',
  'crates/codegen/xai-grok-version/Cargo.toml',
];
for (const rel of cargoTomls) {
  const p = path.join(root, rel);
  if (!fs.existsSync(p)) continue;
  const before = fs.readFileSync(p, 'utf8');
  const after = before.replace(/^version\s*=\s*"[^"]+"/m, `version = "${version}"`);
  if (after === before) {
    console.warn(`[sync-version] no version field updated in ${rel}`);
    continue;
  }
  fs.writeFileSync(p, after);
  console.log(`[sync-version] ${rel} -> ${version}`);
}

console.log(`[sync-version] version=${version}`);
