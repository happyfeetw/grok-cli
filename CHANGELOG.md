# Changelog

All notable changes to this **community fork** of Grok Build (`happyfeetw/grok-cli`,
product command **`grok-cli`**) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
for fork packaging releases (`packaging/VERSION` / git tags `v*`).

Upstream Grok Build feature history lives in
[`crates/codegen/xai-grok-shell/CHANGELOG.md`](crates/codegen/xai-grok-shell/CHANGELOG.md).
This root changelog focuses on **fork-specific** behavior: system proxy,
packaging, branding, and distribution.

## [Unreleased]

## [0.1.225] - 2026-07-18

### Changed

- Align product versioning with **upstream Grok Build**: compile-time
  `GROK_VERSION` stamp, otherwise `CARGO_PKG_VERSION` (shipping crates).
- Remove the fork-only packaging-file-as-binary-SSOT path. `packaging/VERSION`
  stays the packaging SSOT and is exported as `GROK_VERSION` on release CI;
  `sync-version.js` also aligns shipping crate Cargo.toml versions for
  unstamped local builds.

## [0.1.224] - 2026-07-18

### Changed

- **Product version SSOT**: user-facing CLI / npm / tag version comes only from
  `packaging/VERSION` (optional `GROK_VERSION` override). Cargo crate versions
  are no longer used as a silent fallback for `--version`.
- Shared build-script resolver
  (`xai-grok-version/product_version_for_build.rs`) used by the version crate,
  pager lib, and pager binary; release CI sets `GROK_RELEASE_BUILD=1` to fail
  closed if the packaging version is missing.

## [0.1.223] - 2026-07-18

### Fixed

- Release CI stamps `GROK_VERSION` from `packaging/VERSION` into the binary so
  `grok-cli --version` matches the npm / GitHub Release / Homebrew version
  (previously showed the Cargo crate version, e.g. `0.1.220-alpha.4`).
- `xai-grok-version` build script injects `GROK_VERSION` via `cargo:rustc-env`
  and falls back to reading `packaging/VERSION` when the env var is unset.

## [0.1.222] - 2026-07-17

### Changed

- Ship the product command as **`grok-cli`** (binary, npm bin, tarball payload,
  Homebrew formula) so installs do not shadow the official SpaceXAI/xAI
  **`grok`** command.
- In-app updates (`grok-cli update` / auto-update) pull from **this fork only**:
  npm `@spikewang/grok-cli` and GitHub Releases on `happyfeetw/grok-cli`
  (not `x.ai/cli` / `@xai-official/grok`).
- Managed npm installs stay under `~/.grok` for layout compatibility with the
  official tool tree.

### Documentation

- Bilingual README / packaging / security / contributing docs (English + 简体中文).
- Community signals: contributions welcome, LINUX DO badge, security contact
  pointed at this fork.

### Distribution

- macOS GitHub Release assets continue as
  `grok-cli-<version>-darwin-{arm64,x64}.tar.gz` (+ `.sha256`).
- npm meta package `@spikewang/grok-cli@0.1.222` with optional darwin binaries.
- Homebrew formula `Formula/grok-cli.rb` aligned to release digests.

## [0.1.221] - 2026-07-17

### Added

- **System proxy on macOS**: HTTP clients honor macOS System Settings proxies
  when `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY` are unset
  (`reqwest` system-proxy enablement).
- **macOS packaging pipeline**:
  - GitHub Actions release workflow for `darwin-arm64` + `darwin-x64`
  - npm packages under `@spikewang/grok-cli*`
  - Homebrew formula under this repository (`Formula/grok-cli.rb`)
  - Stable asset names on GitHub Releases
- Version source of truth: `packaging/VERSION` (synced into npm package.json).

### Fixed

- Release CI: artifact layout / sha collection for GitHub Release uploads.
- npm trampoline binary script tracked in packaging for reliable installs.
- Build/CI robustness around `protoc` paths (historical Windows matrix work;
  current release target is macOS-only).

[Unreleased]: https://github.com/happyfeetw/grok-cli/compare/v0.1.225...HEAD
[0.1.225]: https://github.com/happyfeetw/grok-cli/compare/v0.1.224...v0.1.225
[0.1.224]: https://github.com/happyfeetw/grok-cli/compare/v0.1.223...v0.1.224
[0.1.223]: https://github.com/happyfeetw/grok-cli/compare/v0.1.222...v0.1.223
[0.1.222]: https://github.com/happyfeetw/grok-cli/compare/v0.1.221...v0.1.222
[0.1.221]: https://github.com/happyfeetw/grok-cli/releases/tag/v0.1.221
