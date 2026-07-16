#!/usr/bin/env node
/**
 * Publish @spikewang/grok-cli and platform packages to the npm registry.
 *
 * Requires NPM_TOKEN (or an existing npm login). Uses the official registry
 * even if the machine default registry is a mirror.
 */
const { spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const root = path.resolve(__dirname, '..', '..');
const npmRoot = path.join(root, 'packaging', 'npm');
const version = fs.readFileSync(path.join(root, 'packaging', 'VERSION'), 'utf8').trim();
const registry = process.env.NPM_REGISTRY || 'https://registry.npmjs.org/';

const order = [
  'grok-cli-darwin-arm64',
  'grok-cli-darwin-x64',
  'grok-cli', // meta last so optionalDeps resolve
];

function run(cmd, args, cwd) {
  console.log(`$ ${cmd} ${args.join(' ')}  (cwd=${path.relative(root, cwd)})`);
  const env = { ...process.env };
  if (process.env.NPM_TOKEN) {
    // scoped auth for registry.npmjs.org
    env.npm_config_registry = registry;
  }
  const res = spawnSync(cmd, args, { cwd, env, stdio: 'inherit', shell: false });
  if (res.status !== 0) {
    process.exit(res.status ?? 1);
  }
}

// Write a project-local .npmrc for publish auth when NPM_TOKEN is present.
const npmrcPath = path.join(npmRoot, '.npmrc');
if (process.env.NPM_TOKEN) {
  const host = registry.replace(/^https?:\/\//, '').replace(/\/$/, '');
  fs.writeFileSync(
    npmrcPath,
    `registry=${registry}\n//${host}/:_authToken=${process.env.NPM_TOKEN}\naccess=public\n`,
  );
  console.log(`[publish-npm] wrote auth npmrc for ${registry}`);
}

for (const name of order) {
  const dir = path.join(npmRoot, name);
  // refuse to publish without a binary payload for platform packages
  if (name !== 'grok-cli') {
    const br = path.join(dir, 'bin', 'grok.br');
    if (!fs.existsSync(br)) {
      console.error(`[publish-npm] missing ${br}; run assemble-npm.js first`);
      process.exit(1);
    }
  }
  run('npm', ['publish', '--access', 'public', '--registry', registry], dir);
}

try {
  fs.unlinkSync(npmrcPath);
} catch {}

console.log(`[publish-npm] published @spikewang/grok-cli@${version} (+ platform packages)`);
