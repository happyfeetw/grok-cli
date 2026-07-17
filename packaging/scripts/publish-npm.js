#!/usr/bin/env node
/**
 * Publish @spikewang/grok-cli and platform packages to the npm registry.
 *
 * Auth (any one works):
 *   - NPM_TOKEN env (classic or granular automation token)
 *   - NODE_AUTH_TOKEN env (set by actions/setup-node)
 *   - existing `npm login`
 *
 * Writes a per-package .npmrc so publish does not depend on parent-dir
 * discovery or a conflicting userconfig from setup-node.
 */
const { spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const root = path.resolve(__dirname, '..', '..');
const npmRoot = path.join(root, 'packaging', 'npm');
const version = fs.readFileSync(path.join(root, 'packaging', 'VERSION'), 'utf8').trim();
const registry = (process.env.NPM_REGISTRY || 'https://registry.npmjs.org/').replace(/\/?$/, '/');
const token = (process.env.NPM_TOKEN || process.env.NODE_AUTH_TOKEN || '').trim();

const order = [
  'grok-cli-darwin-arm64',
  'grok-cli-darwin-x64',
  'grok-cli', // meta last so optionalDeps resolve on install
];

function npmrcContents() {
  // registry.npmjs.org auth line must not include https://
  const host = registry.replace(/^https?:\/\//, '').replace(/\/$/, '');
  const lines = [
    `registry=${registry}`,
    `//${host}/:_authToken=${token}`,
    'always-auth=true',
    '',
  ];
  return lines.join('\n');
}

function run(cmd, args, cwd) {
  console.log(`$ ${cmd} ${args.join(' ')}  (cwd=${path.relative(root, cwd)})`);
  const env = {
    ...process.env,
    npm_config_registry: registry,
  };
  // Prefer explicit token; avoid leaking into logs via npm config list.
  if (token) {
    env.NODE_AUTH_TOKEN = token;
    env.NPM_TOKEN = token;
  }
  const res = spawnSync(cmd, args, { cwd, env, stdio: 'inherit', shell: false });
  if (res.status !== 0) {
    process.exit(res.status ?? 1);
  }
}

if (!token) {
  console.error('[publish-npm] NPM_TOKEN / NODE_AUTH_TOKEN is empty');
  process.exit(1);
}

console.log(`[publish-npm] registry=${registry}`);
console.log(`[publish-npm] token length=${token.length} prefix=${token.slice(0, 7)}…`);

const rootNpmrc = path.join(npmRoot, '.npmrc');
fs.writeFileSync(rootNpmrc, npmrcContents(), { mode: 0o600 });

// Who am I? Helps diagnose scope/permission issues without printing the token.
run('npm', ['whoami', '--registry', registry, '--userconfig', rootNpmrc], npmRoot);

const written = [rootNpmrc];
for (const name of order) {
  const dir = path.join(npmRoot, name);
  if (name !== 'grok-cli') {
    const br = path.join(dir, 'bin', 'grok-cli.br');
    if (!fs.existsSync(br)) {
      console.error(`[publish-npm] missing ${br}; run assemble-npm.js first`);
      process.exit(1);
    }
  }

  const pkgNpmrc = path.join(dir, '.npmrc');
  fs.writeFileSync(pkgNpmrc, npmrcContents(), { mode: 0o600 });
  written.push(pkgNpmrc);

  run(
    'npm',
    ['publish', '--access', 'public', '--registry', registry, '--userconfig', pkgNpmrc],
    dir,
  );
}

for (const f of written) {
  try {
    fs.unlinkSync(f);
  } catch {}
}

console.log(`[publish-npm] published @spikewang/grok-cli@${version} (+ platform packages)`);
