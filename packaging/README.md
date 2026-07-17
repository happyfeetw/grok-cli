# Packaging — `@spikewang/grok-cli`

**English** | [简体中文](README.zh-CN.md)

Distribution channels for this fork:

| Channel | Package / formula | Platforms |
|---------|-------------------|-----------|
| **npm** | `@spikewang/grok-cli` | macOS arm64 + x64 (via optional deps) |
| **Homebrew** | `spikewang/grok-cli` tap → `grok-cli` | macOS arm64 + x64 |
| **GitHub Releases** | `grok-cli-<version>-darwin-<arch>.tar.gz` | macOS only |

## Version source of truth

```text
packaging/VERSION
```

That single line (no `v` prefix) is the **only product version**. It is stamped into:

- npm `package.json` files (`packaging/npm/**`) via `sync-version.js`
- Homebrew formula (`Formula/grok-cli.rb`)
- Git tags (`v` + version, e.g. `v0.1.223`)
- GitHub Release asset names
- The CLI binary (`grok-cli --version`) via build scripts — **not** via
  individual crates’ `Cargo.toml` `version` fields

### Product version vs Cargo crate versions

This workspace is mostly Rust. Many crates keep independent Cargo versions
(e.g. `0.1.220-alpha.4`, `0.2.0-dev`) for monorepo/crate evolution. Those
**must not** appear as the user-facing CLI version.

| Kind | Source | Example |
|------|--------|---------|
| Product / packaging | `packaging/VERSION` | `0.1.224` |
| Cargo crate | each `Cargo.toml` | `0.1.220-alpha.4` (ignored for `--version`) |

Build-time resolution (shared:
`crates/codegen/xai-grok-version/product_version_for_build.rs`):

1. `GROK_VERSION` env (release CI sets this explicitly)
2. else `packaging/VERSION` on disk
3. else `0.0.0-dev` (never `CARGO_PKG_VERSION`)

Release CI also sets `GROK_RELEASE_BUILD=1` so a missing packaging version
**fails the build** instead of shipping a wrong identity.

Bump version:

```sh
echo '0.1.224' > packaging/VERSION
node packaging/scripts/sync-version.js
```

Before tagging a release, add a Keep a Changelog section for the new version
in the repo-root [`CHANGELOG.md`](../CHANGELOG.md). The release workflow extracts
that section into the GitHub Release body
(`packaging/scripts/extract-changelog.js`).

Local binary with the same stamp as packaging (automatic if `packaging/VERSION`
is present):

```sh
cargo build -p xai-grok-pager-bin --release
# or explicit:
export GROK_VERSION="$(tr -d '[:space:]' < packaging/VERSION)"
export GROK_RELEASE_BUILD=1   # optional: fail if VERSION file missing
cargo build -p xai-grok-pager-bin --release
./target/release/xai-grok-pager --version
```

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

CI will: build macOS binaries → GitHub Release → update Homebrew formula →
`npm publish` (requires repo secret `NPM_TOKEN`).
