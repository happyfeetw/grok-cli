# Upstream sync policy (this fork)

**English** | [简体中文](upstream-sync.zh-CN.md)

How this community fork (`happyfeetw/grok-cli`) tracks
[`xai-org/grok-build`](https://github.com/xai-org/grok-build) **without**
dependency / MSRV drift.

## Goals

1. **Code**: merge upstream `main` and keep fork deltas (product name `grok-cli`,
   system-proxy, npm/Homebrew packaging, SemVer `BASE-N`).
2. **Lockfile**: third-party crates in `Cargo.lock` **must match upstream**
   (same name@version for every `registry+` / `git+` package), except a small
   **system-proxy** allowlist this fork needs (`system-configuration*`, etc.).
3. **Toolchain**: `rust-toolchain.toml` channel **must equal** the pin in
   [`.github/workflows/release-macos.yml`](../.github/workflows/release-macos.yml).
   Bump only when **upstream** bumps (or you intentionally diverge).

## Never do this after an upstream merge

| Command | Why it hurts |
|---------|----------------|
| `cargo generate-lockfile` | Resolves **latest** compatible crates → often **above** pinned MSRV (e.g. rustc 1.92). |
| `cargo update` (no `-p`) | Same class of drift across the workspace. |
| Hand-editing random versions in `Cargo.lock` | Diverges from upstream without review. |
| Bumping only CI toolchain | Local `rust-toolchain.toml` and CI disagree. |

## Always do this

```bash
# 1) Clean tree, then automated merge + lock restore
packaging/scripts/merge-upstream.sh

# 2) Fix remaining conflicts (keep grok-cli branding / system-proxy)
# 3) CHANGELOG + commit
# 4) Policy check before tag
packaging/scripts/merge-upstream.sh --check-only
# or
packaging/scripts/verify-upstream-policy.sh

# 5) Tag BASE-N from packaging/VERSION (e.g. 0.2.110-1)
```

What the script enforces:

1. `git fetch upstream` and `git merge upstream/main` (or `--ref <sha>`).
2. **`git checkout <upstream-tip> -- Cargo.lock`** so third-party pins match upstream.
3. Stamps fork shipping version to **`{upstream_shell_version}-1`** via
   `packaging/VERSION` + `sync-version.js`.
4. Runs **only**:
   ```bash
   cargo update -p xai-grok-pager -p xai-grok-pager-bin -p xai-grok-version
   ```
   so path crate versions in the lock match packaging, without upgrading crates.io deps.
5. Verifies third-party lock equality and toolchain pin match.

If packaging is already on the same base and you need `-2`, `-3`, edit
`packaging/VERSION` after the script and re-run `node packaging/scripts/sync-version.js`
plus the three-package `cargo update -p …` line.

## Manual recovery (lock already drifted)

```bash
git fetch upstream
git checkout upstream/main -- Cargo.lock
node packaging/scripts/sync-version.js   # after packaging/VERSION is correct
cargo update -p xai-grok-pager -p xai-grok-pager-bin -p xai-grok-version
packaging/scripts/verify-upstream-policy.sh
```

## When to raise Rust (MSRV)

Only when **upstream** raises `rust-toolchain.toml` (or you accept a permanent
fork MSRV). Then change **both**:

1. `rust-toolchain.toml` → `channel = "…"`
2. `.github/workflows/release-macos.yml` → `toolchain: "…"`

Run `packaging/scripts/verify-upstream-policy.sh` afterward.

## Related

- Packaging / SemVer `BASE-N`: [packaging/README.md](../packaging/README.md)
- Product version stamp: `GROK_VERSION` in release CI (same as upstream contract)
