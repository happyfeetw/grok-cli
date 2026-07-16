# Packaging — `@spikewang/grok-cli`

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

That single line (no `v` prefix) is stamped into:

- npm `package.json` files (`packaging/npm/**`)
- Homebrew formula (`Formula/grok-cli.rb`)
- Git tags (`v` + version, e.g. `v0.1.221`)
- GitHub Release asset names

Bump version:

```sh
echo '0.1.222' > packaging/VERSION
node packaging/scripts/sync-version.js
```

## Asset naming (GitHub Releases)

```text
grok-cli-<version>-darwin-arm64.tar.gz
grok-cli-<version>-darwin-arm64.tar.gz.sha256
grok-cli-<version>-darwin-x64.tar.gz
grok-cli-<version>-darwin-x64.tar.gz.sha256
```

Each tarball contains a single executable named **`grok`**.

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
