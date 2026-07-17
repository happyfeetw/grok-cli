#!/usr/bin/env node
/**
 * Rewrite Formula/grok-cli.rb version + per-arch sha256 from release assets.
 *
 * Usage:
 *   node packaging/scripts/update-formula.js \
 *     --version 0.1.221 \
 *     --arm64-sha <hex> \
 *     --x64-sha <hex>
 */
const fs = require('fs');
const path = require('path');

function arg(name) {
  const i = process.argv.indexOf(`--${name}`);
  if (i === -1 || !process.argv[i + 1]) {
    console.error(`missing --${name}`);
    process.exit(1);
  }
  return process.argv[i + 1];
}

const version = arg('version');
const arm64Sha = arg('arm64-sha');
const x64Sha = arg('x64-sha');
const root = path.resolve(__dirname, '..', '..');
const formulaPath = path.join(root, 'Formula', 'grok-cli.rb');
const repo = process.env.GROK_CLI_REPO || 'happyfeetw/grok-cli';

const formula = `class GrokCli < Formula
  desc "Grok coding agent CLI (fork with system-proxy support)"
  homepage "https://github.com/${repo}"
  version "${version}"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/${repo}/releases/download/v${version}/grok-cli-${version}-darwin-arm64.tar.gz"
      sha256 "${arm64Sha}"
    end
    on_intel do
      url "https://github.com/${repo}/releases/download/v${version}/grok-cli-${version}-darwin-x64.tar.gz"
      sha256 "${x64Sha}"
    end
  end

  def install
    # Ship as grok-cli so it does not shadow the official grok command.
    bin.install "grok-cli"
  end

  test do
    assert_predicate bin/"grok-cli", :exist?
  end
end
`;

fs.mkdirSync(path.dirname(formulaPath), { recursive: true });
fs.writeFileSync(formulaPath, formula);
console.log(`[update-formula] wrote ${formulaPath}`);
console.log(`  version=${version}`);
console.log(`  arm64 sha256=${arm64Sha}`);
console.log(`  x64   sha256=${x64Sha}`);
