# Contributing

Thank you for your interest in **grok-cli** — a community fork of open-source
[Grok Build](https://github.com/xai-org/grok-build) with packaging and
system-proxy fixes. **External contributions are welcome.**

中文版 / Chinese: [`CONTRIBUTING.zh-CN.md`](CONTRIBUTING.zh-CN.md)

By participating, you agree to keep discussions respectful and constructive.
Serious abuse or harassment may result in blocked interaction with this
repository.

## Ways to contribute

- Report bugs and rough edges via [GitHub Issues](https://github.com/happyfeetw/grok-cli/issues)
- Suggest features or packaging improvements (npm, Homebrew, docs)
- Open pull requests for bug fixes, docs, CI, and features
- Improve translations or user-facing help text where applicable

If you are unsure whether an idea fits, open an issue first and describe the
problem and a possible approach.

## Before you start

1. Search existing [issues](https://github.com/happyfeetw/grok-cli/issues) and
   [pull requests](https://github.com/happyfeetw/grok-cli/pulls) to avoid
   duplicates.
2. For large changes (new platforms, dependency major bumps, public API
   changes), open an issue for discussion before investing a lot of work.
3. Security vulnerabilities must **not** be filed as public issues. Follow
   [`SECURITY.md`](SECURITY.md) / [`SECURITY.zh-CN.md`](SECURITY.zh-CN.md).

## Development setup

Build and tooling requirements are documented in [`README.md`](README.md)
(*Building from source*). In short:

```sh
# Toolchain is pinned by rust-toolchain.toml (rustup installs it)
cargo check -p xai-grok-pager-bin
cargo test -p <crate>
cargo clippy -p <crate>
cargo fmt --all
```

Prefer **per-crate** `check` / `test` / `clippy` targets; full-workspace
builds are slow.

Packaging (version, npm, Homebrew) lives under [`packaging/`](packaging/) and
[`Formula/`](Formula/). See [`packaging/README.md`](packaging/README.md).

> [!IMPORTANT]
> The root `Cargo.toml` (workspace members, dependency versions, lints,
> profiles) is **generated** in upstream fashion — treat it carefully. Prefer
> editing per-crate `Cargo.toml` files when possible.

## Pull request process

1. **Fork** the repository and create a branch from `main`:
   ```sh
   git checkout -b fix/short-description
   ```
2. Make focused commits. Prefer clear messages, for example:
   - `fix(http): honor NO_PROXY for local hosts`
   - `docs: clarify Homebrew install steps`
   - `ci: fix npm publish auth for granular tokens`
3. Ensure the change builds and is lint-clean for the crates you touched:
   ```sh
   cargo fmt --all
   cargo clippy -p <crate>
   cargo test -p <crate>
   ```
4. Push to your fork and open a pull request against `main`.
5. Fill in the PR description:
   - **What** changed and **why**
   - How you tested it
   - Linked issue (e.g. `Fixes #123`) if applicable
6. Be ready to iterate on review feedback. Maintainers may request changes or
   split large PRs.

### What makes a good PR

- One logical change per PR when practical
- No unrelated reformatting of large files
- Docs/README updated when user-facing behavior or install paths change
- Version bumps only when intentionally releasing (`packaging/VERSION` and
  related packaging files stay in sync — see packaging docs)

### What we may decline

- Secrets, credentials, or personal data in the tree
- Drive-by dependency upgrades without a clear need
- Changes that re-introduce disabled default features without discussion
  (e.g. turning off `system-proxy` again)
- AI-generated walls of code without understanding, tests, or a clear problem
  statement

## Issue guidelines

**Bug reports** help most when they include:

- OS and architecture (e.g. macOS 15 arm64)
- Install method (`npm`, Homebrew, release tarball, source)
- Version (`grok-cli --version` / package version)
- Steps to reproduce, expected vs actual behavior
- Relevant logs (redact tokens and personal paths)

**Feature requests** should describe the user problem, not only a solution.

## Licensing

This project is licensed under the **Apache License, Version 2.0** — see
[`LICENSE`](LICENSE).

Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in this project is licensed under the same Apache
License, Version 2.0, without additional terms or conditions.

You confirm that you have the right to submit the contribution (for example,
it is your original work or you are authorized to contribute it).

## Community

- GitHub: issues and pull requests on
  [happyfeetw/grok-cli](https://github.com/happyfeetw/grok-cli)
- This project acknowledges the [LINUX DO](https://linux.do) community

Questions about contributing are welcome via issues. Thanks for helping improve
grok-cli.
