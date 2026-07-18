# Packaging — `@spikewang/grok-cli`

**English** | [简体中文](README.zh-CN.md)

Distribution channels for this fork:

| Channel | Package / formula | Platforms |
|---------|-------------------|-----------|
| **npm** | `@spikewang/grok-cli` | macOS arm64 + x64 (via optional deps) |
| **Homebrew** | `happyfeetw/grok-cli` tap → `grok-cli` | macOS arm64 + x64 |
| **GitHub Releases** | `grok-cli-<version>-darwin-<arch>.tar.gz` | macOS only |

## Version management (upstream-compatible + SemVer 2.0)

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

### Fork numbering (SemVer 2.0 pre-release)

Product versions are **based on the upstream three-part base**, with fork-only
increments as a **SemVer pre-release** suffix (`-N`):

| Situation | `packaging/VERSION` example | Meaning |
|-----------|----------------------------|---------|
| Just synced to upstream `0.2.105` | `0.2.105-1` | First community release on that base |
| More fork-only changes before next sync | `0.2.105-2`, `0.2.105-3`, … | Bump the numeric pre-release |
| Next upstream base is `0.2.120` | `0.2.120-1` | Reset suffix; start at `-1` again |

Rules:

1. **Base** = upstream product three-part version (e.g. shell/pager monorepo
   `0.2.105` after a sync; see `SOURCE_REV` + shipping crates on upstream).
2. **Published fork builds always use** `BASE-N` (never plain `BASE` alone).
   Under SemVer 2.0, `0.2.105-1` < `0.2.105`, so shipping plain `0.2.105` would
   make later `0.2.105-N` look *older* to npm/Homebrew/update checks.
3. **N** is a positive integer that only increases between upstream syncs.
4. After a new upstream sync, set base to the new three-part version and
   restart at `-1`.

Examples of valid strings: `0.2.105-1`, `0.2.105-2`, `0.2.120-1`.

Bump and align packaging + Cargo shipping crates:

```sh
echo '0.2.105-1' > packaging/VERSION
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
