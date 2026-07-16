#!/usr/bin/env node
/**
 * Assemble @spikewang/grok-cli platform packages (brotli-compressed binaries).
 *
 * Env (optional overrides):
 *   GROK_DARWIN_ARM64  path to arm64 binary
 *   GROK_DARWIN_X64    path to x64 binary
 *
 * Flags:
 *   --darwin-only   require both darwin binaries (default for this fork)
 *   --allow-missing skip missing platforms instead of failing
 */
const fs = require('fs');
const path = require('path');
const { promisify } = require('util');
const zlib = require('zlib');

const brotliCompress = promisify(zlib.brotliCompress);

const root = path.resolve(__dirname, '..', '..');
const npmRoot = path.join(root, 'packaging', 'npm');
const version = fs.readFileSync(path.join(root, 'packaging', 'VERSION'), 'utf8').trim();

const allowMissing = process.argv.includes('--allow-missing');

function ensureDir(p) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
}

async function pack({ platform, arch, envVar, defaultSource, binName }) {
  const dirName = `grok-cli-${platform}-${arch}`;
  const pkgDir = path.join(npmRoot, dirName);
  const pkgJsonPath = path.join(pkgDir, 'package.json');
  if (!fs.existsSync(pkgJsonPath)) {
    console.error(`[assemble] missing package dir ${pkgDir}`);
    return false;
  }

  const source = process.env[envVar] || defaultSource;
  if (!fs.existsSync(source)) {
    console.error(`[assemble] missing binary for ${platform}-${arch}: ${source}`);
    console.error(`            set ${envVar} or place the binary at the default path`);
    return allowMissing ? true : false;
  }

  const subPkg = JSON.parse(fs.readFileSync(pkgJsonPath, 'utf8'));
  subPkg.version = version;
  fs.writeFileSync(pkgJsonPath, JSON.stringify(subPkg, null, 4) + '\n');

  const outBr = path.join(pkgDir, 'bin', `${binName}.br`);
  ensureDir(outBr);
  // remove stale raw binary if present
  const rawOut = path.join(pkgDir, 'bin', binName);
  try {
    fs.unlinkSync(rawOut);
  } catch {}

  const raw = fs.readFileSync(source);
  const compressed = await brotliCompress(raw, {
    params: { [zlib.constants.BROTLI_PARAM_QUALITY]: zlib.constants.BROTLI_MAX_QUALITY },
  });
  fs.writeFileSync(outBr, compressed);
  console.log(
    `[assemble] @spikewang/${dirName}@${version}: ` +
      `${(raw.length / 1048576).toFixed(1)} MB -> ${(compressed.length / 1048576).toFixed(1)} MB`,
  );
  return true;
}

async function main() {
  // Stamp meta package version + optionalDeps pins
  require('./sync-version.js');

  const targets = [
    {
      platform: 'darwin',
      arch: 'arm64',
      binName: 'grok',
      envVar: 'GROK_DARWIN_ARM64',
      defaultSource: path.join(root, 'target', 'aarch64-apple-darwin', 'release', 'xai-grok-pager'),
    },
    {
      platform: 'darwin',
      arch: 'x64',
      binName: 'grok',
      envVar: 'GROK_DARWIN_X64',
      defaultSource: path.join(root, 'target', 'x86_64-apple-darwin', 'release', 'xai-grok-pager'),
    },
  ];

  // Host fallback: native release without triple subdir
  const hostRelease = path.join(root, 'target', 'release', 'xai-grok-pager');
  if (process.arch === 'arm64' && !process.env.GROK_DARWIN_ARM64 && fs.existsSync(hostRelease)) {
    process.env.GROK_DARWIN_ARM64 = hostRelease;
  }
  if (process.arch === 'x64' && !process.env.GROK_DARWIN_X64 && fs.existsSync(hostRelease)) {
    process.env.GROK_DARWIN_X64 = hostRelease;
  }

  const results = await Promise.all(targets.map(pack));
  if (results.some((ok) => !ok)) {
    process.exit(1);
  }
  console.log(`[assemble] done @ version ${version}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
