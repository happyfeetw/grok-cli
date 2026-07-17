# Packaging — `@spikewang/grok-cli`

**English** | [简体中文](README.zh-CN.md)

Distribution channels for this fork:

| Channel | Package / formula | Platforms |
|---------|-------------------|-----------|
| **npm** | `@spikewang/grok-cli` | macOS arm64 + x64 (via optional deps) |
| **Homebrew** | `happyfeetw/grok-cli` tap → `grok-cli` | macOS arm64 + x64 |
| **GitHub Releases** | `grok-cli-<version>-darwin-<arch>.tar.gz` | macOS only |

## Version management (upstream-compatible)

This fork follows the **official Grok Build** version contract for the binary:

```text
compiled VERSION = GROK_VERSION (if set at cargo build)
                 | CARGO_PKG_VERSION of the shipping crates (local/dev)
```

| Role | Where | Notes |
|------|--------|--------|
| Packaging SSOT (fork) | [`packaging/VERSION`](VERSION) | One line, no `v` prefix |
| Compile-time stamp | env `GROK_VERSION` | **Required on release CI** (same as upstream) |
| Unstamped fallback | shipping crates’ `Cargo.toml` `version` | pager-bin / pager / xai-grok-version |
| npm / formula / tags | stamped by `sync-version.js` | From `packaging/VERSION` |
| `--version` string | `VERSION_WITH_COMMIT` | `{version} ({git short sha})` |

Bump and align packaging + Cargo shipping crates:

```sh
echo '0.1.225' > packaging/VERSION
node packaging/scripts/sync-version.js
```

Release CI builds with:

```sh
export GROK_VERSION="$(tr -d '[:space:]' < packaging/VERSION)"
cargo build -p xai-grok-pager-bin --release
```

Local dry-run with the same stamp as a release:

```sh
export GROK_VERSION="$(tr -d '[:space:]' < packaging/VERSION)"
cargo build -p xai-grok-pager-bin --release
./target/release/xai-grok-pager --version
```

Without `GROK_VERSION`, `--version` uses the shipping crate Cargo version
(kept in lockstep by `sync-version.js`) plus the git short SHA.

### Changelog

Before tagging a release, add a Keep a Changelog section for the new version
in the repo-root [`CHANGELOG.md`](../CHANGELOG.md). The release workflow extracts
that section into the GitHub Release body
(`packaging/scripts/extract-changelog.js`).

## Asset naming (GitHub Releases)

```text
grok-cli-<version>-darwin-arm64.tar.gz
grok-cli-<version>-darwin-arm64.tar.gz.sha256
grok-cli-<version>-darwin-x64.tar.gz
grok-cli-<version>-darwin-x64.tar.gz.sha256
```

Each tarball contains a single executable named **`grok-cli`** (not `grok`).

## Local release dry-run

```sh
# after cargo build --release for the host
export GROK_DARWIN_ARM64=target/release/xai-grok-pager   # on Apple Silicon
node packaging/scripts/sync-version.js
node packaging/scripts/assemble-npm.js --darwin-only
```

## Publish (CI)

Push a tag matching `packaging/VERSION`:

```sh
VERSION=$(cat packaging/VERSION)
git tag -a "v${VERSION}" -m "Release v${VERSION}"
git push origin "v${VERSION}"
```
