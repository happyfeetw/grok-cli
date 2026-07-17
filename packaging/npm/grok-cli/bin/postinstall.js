#!/usr/bin/env node
// Install the platform binary into ~/.grok-cli/bin/grok-cli-<version> + symlink grok-cli.
// Uses a separate home dir from the official `grok` installer (~/.grok).
const path = require('path');
const fs = require('fs');
const os = require('os');
const zlib = require('zlib');

const pkgName = '@spikewang/grok-cli';
const BIN_NAME = 'grok-cli';
const CANONICAL_DIR = path.join(os.homedir(), '.grok-cli', 'bin');
const key = `${process.platform}-${process.arch}`;
const SUPPORTED = new Set(['darwin-arm64', 'darwin-x64']);

if (!SUPPORTED.has(key)) {
  console.error(`${pkgName}: unsupported platform ${key} (macOS arm64/x64 only).`);
  process.exit(0);
}

let version;
try {
  version = require('../package.json').version;
} catch {
  version = undefined;
}
if (!version) {
  console.error(`${pkgName}: unable to determine version`);
  process.exit(0);
}

function resolvePlatformPackageDir() {
  const platformPkg = `${pkgName}-${key}`;
  try {
    return path.dirname(require.resolve(`${platformPkg}/package.json`));
  } catch {
    return null;
  }
}

const platformDir = resolvePlatformPackageDir();
if (!platformDir) {
  console.error(`${pkgName}: platform package ${pkgName}-${key} not installed.`);
  console.error('  Avoid npm/bun --no-optional. Try: npm install -g @spikewang/grok-cli');
  process.exit(0);
}

const brPath = path.join(platformDir, 'bin', `${BIN_NAME}.br`);
const rawPath = path.join(platformDir, 'bin', BIN_NAME);
let vendored = null;
if (fs.existsSync(brPath)) {
  const decompressed = zlib.brotliDecompressSync(fs.readFileSync(brPath));
  fs.writeFileSync(rawPath, decompressed);
  fs.chmodSync(rawPath, 0o755);
  try {
    fs.unlinkSync(brPath);
  } catch {}
  vendored = rawPath;
} else if (fs.existsSync(rawPath)) {
  vendored = rawPath;
}

if (!vendored) {
  console.error(`${pkgName}: missing binary in platform package`);
  process.exit(0);
}

fs.mkdirSync(CANONICAL_DIR, { recursive: true });
const versionedName = `${BIN_NAME}-${version}`;
const versionedPath = path.join(CANONICAL_DIR, versionedName);
const canonicalPath = path.join(CANONICAL_DIR, BIN_NAME);

if (!fs.existsSync(versionedPath)) {
  const tmp = `${versionedPath}.tmp.${process.pid}`;
  fs.copyFileSync(vendored, tmp);
  fs.chmodSync(tmp, 0o755);
  fs.renameSync(tmp, versionedPath);
}

const tmpLink = `${canonicalPath}.link.${process.pid}`;
try {
  fs.unlinkSync(tmpLink);
} catch {}
fs.symlinkSync(versionedName, tmpLink);
fs.renameSync(tmpLink, canonicalPath);

console.log(`${pkgName}: installed ${canonicalPath} -> ${versionedName}`);
console.log(`${pkgName}: run \`${BIN_NAME}\` (not \`grok\`) to avoid clashing with the official CLI.`);
