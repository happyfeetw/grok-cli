# @spikewang/grok-cli

Grok coding agent CLI (community fork of [xAI Grok Build](https://github.com/xai-org/grok-build)) with **reqwest `system-proxy`** re-enabled so macOS **System Settings → Network → Proxies** are honored when `HTTP_PROXY` / `HTTPS_PROXY` are unset.

## Install

```sh
npm install -g @spikewang/grok-cli
# or
bun add -g @spikewang/grok-cli

grok-cli --version
```

The only command installed is **`grok-cli`**. It does **not** provide or replace
the official `grok` command.

## Supported platforms

| OS | Arch | npm optional package |
|----|------|----------------------|
| macOS | Apple Silicon (`arm64`) | `@spikewang/grok-cli-darwin-arm64` |
| macOS | Intel (`x64`) | `@spikewang/grok-cli-darwin-x64` |

Linux/Windows: not published on this channel yet — build from source or use another install method.

## Other install channels

- **Homebrew:** `brew tap happyfeetw/grok-cli https://github.com/happyfeetw/grok-cli && brew install grok-cli`
- **GitHub Releases:** `grok-cli-<version>-darwin-arm64.tar.gz` / `…-darwin-x64.tar.gz` (binary name: `grok-cli`)

## Proxy behavior

| Source | Priority |
|--------|----------|
| `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY` / `NO_PROXY` | Highest |
| macOS System Settings proxies | Used when env is unset |
| PAC / auto-config | Not supported |

## Version

See `packaging/VERSION` in the repository (single source of truth).
