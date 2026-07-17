<div align="center">

<p><strong>English</strong> | <a href="README.zh-CN.md">简体中文</a></p>

<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://media.x.ai/v1/website/spacexai-symbol-white-transparent-0c31957f.png">
    <source media="(prefers-color-scheme: light)" srcset="https://media.x.ai/v1/website/spacexai-symbol-black-transparent-6435cf42.png">
    <img alt="SpaceXAI logo" src="https://media.x.ai/v1/website/spacexai-symbol-black-transparent-6435cf42.png" width="96">
  </picture>
  <br>
  Grok Build (<code>grok</code>)
</h1>

<p align="center">
  <a href="https://linux.do"><img src="https://shorturl.at/ggSqS" alt="LINUX DO" /></a>
</p>

<p>
  <a href="https://www.npmjs.com/package/@spikewang/grok-cli">
    <img
      src="https://img.shields.io/npm/v/@spikewang/grok-cli?style=for-the-badge&logo=npm&logoColor=white"
      alt="npm @spikewang/grok-cli"
    />
  </a>
  <a href="LICENSE">
    <img
      src="https://img.shields.io/badge/License-Apache%202.0-green?style=for-the-badge"
      alt="Apache-2.0"
    />
  </a>
</p>

**Grok Build** is SpaceXAI's terminal-based AI coding agent. It runs as a
full-screen TUI that understands your codebase, edits files, executes shell
commands, searches the web, and manages long-running tasks — interactively,
headlessly for scripting/CI, or embedded in editors via the Agent Client
Protocol (ACP).

[Install](#install) ·
[Changelog](CHANGELOG.md) ·
[Building from source](#building-from-source) ·
[HTTP proxies](#http-proxies) ·
[Documentation](#documentation) ·
[Repository layout](#repository-layout) ·
[Development](#development) ·
[Contributing](#contributing) ·
[License](#license)

![Grok Build TUI](https://media.x.ai/v1/website/universe-tui-screenshot-6f7a0837.png)

**Learn more about Grok Build at [x.ai/cli](https://x.ai/cli)**

This repository is a **community fork** of the open-source Grok Build tree
(upstream: [xai-org/grok-build](https://github.com/xai-org/grok-build)), with
extra packaging and system-proxy fixes. Contributions are welcome.

</div>

---

## Install

This repository is a **community fork** (`happyfeetw/grok-cli`) of open-source
Grok Build, with **system-proxy** re-enabled and macOS-focused packaging under
the product name **`grok-cli`**.

Version source of truth: [`packaging/VERSION`](packaging/VERSION) (currently
kept in lockstep with git tags `v*`, npm, and Homebrew).

Release notes for this fork live in [`CHANGELOG.md`](CHANGELOG.md) and are
copied onto each [GitHub Release](https://github.com/happyfeetw/grok-cli/releases).

### npm / bun (macOS)

```sh
npm install -g @spikewang/grok-cli
# or
bun add -g @spikewang/grok-cli

grok-cli --version
```

The installed command is **`grok-cli`** (not `grok`), so it will not replace
or shadow the official SpaceXAI/xAI `grok` binary.

In-app updates (`grok-cli update` / auto-update) pull from **this fork**:
npm package `@spikewang/grok-cli` and GitHub Releases on
`happyfeetw/grok-cli` — not from `x.ai/cli` or `@xai-official/grok`.

Publishes only **macOS** optional binaries:

| Package | Platform |
|---------|----------|
| `@spikewang/grok-cli` | meta package (trampoline + postinstall) |
| `@spikewang/grok-cli-darwin-arm64` | Apple Silicon |
| `@spikewang/grok-cli-darwin-x64` | Intel |

### Homebrew (macOS)

```sh
brew tap happyfeetw/grok-cli https://github.com/happyfeetw/grok-cli
brew install grok-cli
grok-cli --version
```

Formula: [`Formula/grok-cli.rb`](Formula/grok-cli.rb) (sha256 updated by the
release workflow).

### GitHub Releases (macOS tarballs)

Other channels are limited to GitHub Release archives:

```text
grok-cli-<version>-darwin-arm64.tar.gz
grok-cli-<version>-darwin-x64.tar.gz
```

Each archive contains a single **`grok-cli`** binary (+ matching `.sha256` files).

```sh
tar -xzf grok-cli-<version>-darwin-arm64.tar.gz
install -m 755 grok-cli ~/.local/bin/grok-cli
```

See [Releases](https://github.com/happyfeetw/grok-cli/releases).

### Official upstream installer

Upstream SpaceXAI builds (not this fork):

```sh
curl -fsSL https://x.ai/cli/install.sh | bash   # macOS / Linux / Git Bash
irm https://x.ai/cli/install.ps1 | iex          # Windows PowerShell
```

## Building from source

Requirements:

- **Rust** — the toolchain is pinned by [`rust-toolchain.toml`](rust-toolchain.toml);
  `rustup` installs it automatically on first build.
- **protoc** — proto codegen resolves [`bin/protoc`](bin/protoc) (a
  [dotslash](https://dotslash-cli.com) launcher) or falls back to a `protoc` on
  `PATH` / `$PROTOC`.
- macOS and Linux are supported build hosts; Windows builds are best-effort
  and not currently tested from this tree.

```sh
cargo run -p xai-grok-pager-bin              # build + launch the TUI
cargo build -p xai-grok-pager-bin --release  # release binary: target/release/xai-grok-pager
cargo check -p xai-grok-pager-bin            # fast validation
```

The cargo binary artifact is named `xai-grok-pager`. This fork installs it as
**`grok-cli`** so it stays distinct from the official `grok` command:

```sh
mkdir -p ~/.local/bin
install -m 755 target/release/xai-grok-pager ~/.local/bin/grok-cli
```

Make sure `~/.local/bin` is on your `PATH`. On first launch it opens your
browser to authenticate — see the
[authentication guide](crates/codegen/xai-grok-pager/docs/user-guide/02-authentication.md).

Packaging internals (version sync, npm assemble, formula rewrite): see
[`packaging/README.md`](packaging/README.md).

## HTTP proxies

Shared HTTP clients (API, sampling, uploads, and MCP HTTP transports) honor
proxies via reqwest's `system-proxy` feature:

| Platform | Behavior |
|----------|----------|
| **macOS** | Reads **System Settings → Network → Proxies** when the corresponding env var is unset |
| **Linux** | Environment variables only (`HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY`, `NO_PROXY`) |
| Windows | Same feature also reads Internet Settings if you build there; Windows is still best-effort for this tree |

Explicit `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY` / `NO_PROXY` always take
precedence over OS settings. PAC / auto-config scripts are not evaluated, and
proxy configuration is read when each process-wide client is first built.

## Documentation

Full online documentation is available at
[docs.x.ai/build/overview](https://docs.x.ai/build/overview).

The user guide ships with the pager crate:
[`crates/codegen/xai-grok-pager/docs/user-guide/`](crates/codegen/xai-grok-pager/docs/user-guide/)
— getting started, keyboard shortcuts, slash commands, configuration, theming,
MCP servers, skills, plugins, hooks, headless mode, sandboxing, and more.

## Repository layout

| Path | Contents |
|------|----------|
| `packaging/` | Version file, npm packages (`@spikewang/grok-cli*`), release scripts |
| `Formula/grok-cli.rb` | Homebrew formula |
| `crates/codegen/xai-grok-pager-bin` | Composition-root package; builds the `xai-grok-pager` binary |
| `crates/codegen/xai-grok-pager` | The TUI: scrollback, prompt, modals, rendering |
| `crates/codegen/xai-grok-shell` | Agent runtime + leader/stdio/headless entry points |
| `crates/codegen/xai-grok-tools` | Tool implementations (terminal, file edit, search, ...) |
| `crates/codegen/xai-grok-workspace` | Host filesystem, VCS, execution, checkpoints |
| `crates/codegen/...` | The rest of the CLI crate closure (config, MCP, markdown, sandbox, ...) |
| `crates/common/`, `crates/build/`, `prod/mc/` | Small shared leaf crates pulled in by the closure |
| `third_party/` | Vendored upstream source (Mermaid diagram stack) — see below |

> [!IMPORTANT]
> The root `Cargo.toml` (workspace members, dependency versions, lints,
> profiles) is **generated** — treat it as read-only. Prefer editing per-crate
> `Cargo.toml` files.

## Development

```sh
cargo check -p <crate>        # always target specific crates; full-workspace builds are slow
cargo test -p xai-grok-config # per-crate tests
cargo clippy -p <crate>       # lint config: clippy.toml at the repo root
cargo fmt --all               # rustfmt.toml at the repo root
```

## Contributing

**External contributions are welcome.** Bug reports, docs fixes, packaging
improvements, and feature PRs are all appreciated.

Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) (English) or
[`CONTRIBUTING.zh-CN.md`](CONTRIBUTING.zh-CN.md) (简体中文) for the workflow
(issues, PR expectations, coding style, and licensing of contributions).

This project acknowledges the [LINUX DO](https://linux.do) community.

## License

First-party code in this repository is licensed under the **Apache License,
Version 2.0** — see [`LICENSE`](LICENSE).

Third-party and vendored code remains under its original licenses. See:

- [`THIRD-PARTY-NOTICES`](THIRD-PARTY-NOTICES) — crates.io / git dependencies,
  bundled UI themes, and **in-tree source ports** (including openai/codex and
  sst/opencode tool implementations)
- [`crates/codegen/xai-grok-tools/THIRD_PARTY_NOTICES.md`](crates/codegen/xai-grok-tools/THIRD_PARTY_NOTICES.md)
  — crate-local notice for the codex and opencode ports (license texts +
  Apache §4(b) change notice)
- [`third_party/NOTICE`](third_party/NOTICE) — vendored Mermaid-stack index
