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

### Automated path

The [Sync upstream workflow](../.github/workflows/upstream-sync.yml) runs daily:

1. A GitHub-hosted runner fetches `upstream/main` once and pins its full SHA.
2. `--merge-only --no-fetch` performs a real merge without running Cargo.
3. A clean merge is finalized and compiled on GitHub-hosted Linux and macOS
   runners. The validated candidate is fast-forwarded to `main`, then
   `release-macos.yml` is dispatched explicitly.
4. A conflicted merge opens an `upstream-sync` + `needs-codex` Issue. The local
   Codex scheduled task resolves only the Git conflict in an isolated worktree
   and pushes `automation/upstream-sync-<full-sha>`. The same workflow performs
   finalization, builds, promotion, and release.

The local conflict task must not run Cargo, build, publish, rewrite `main`, or
force-push. It keeps the conflict worktree after pushing the candidate. At the
start of later runs, it removes that exact worktree only after the candidate is
in `origin/main`, the Issue is closed, and the worktree is clean. Incomplete
worktrees are retained; those older than seven days are reported but never
force-removed automatically. GitHub Actions closes the conflict Issue only
after promotion and successful release dispatch.

### Manual path

```bash
# Merge only; safe for a machine where Rust artifacts are intentionally avoided.
git fetch upstream main
SHA="$(git rev-parse upstream/main)"
packaging/scripts/merge-upstream.sh --merge-only --no-fetch --ref "$SHA"

# After resolving conflicts and committing, run finalization on a build runner.
packaging/scripts/merge-upstream.sh --finalize-only --no-fetch --ref "$SHA"

# Verify policy before tagging BASE-N from packaging/VERSION.
packaging/scripts/verify-upstream-policy.sh --no-fetch --ref "$SHA"
```

What the script enforces:

1. It fetches by default for standalone manual use. `--no-fetch` lets a
   workflow reuse an already-fetched, pinned commit without a duplicate fetch.
2. `--merge-only` performs only the Git merge. Conflict exit code `10` means no
   Cargo or version-stamping command ran.
3. `--finalize-only` requires the pinned upstream commit to be an ancestor of
   `HEAD`, aligns the release toolchain pin, then checks out the pinned
   upstream `Cargo.lock`.
4. It stamps the fork shipping version to **`{upstream_shell_version}-1`** via
   `packaging/VERSION` + `sync-version.js`.
5. Finalization runs **only**:
   ```bash
   cargo update -p xai-grok-pager -p xai-grok-pager-bin -p xai-grok-version
   ```
   so path crate versions in the lock match packaging, without upgrading crates.io deps.
6. `--check-only` verifies third-party lock equality, toolchain pin equality,
   and that the pinned upstream commit is already merged.

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
fork MSRV). Automated finalization aligns the release workflow pin. For a
manual change, change **both**:

1. `rust-toolchain.toml` → `channel = "…"`
2. `.github/workflows/release-macos.yml` → `toolchain: "…"`

Run `packaging/scripts/verify-upstream-policy.sh` afterward.

## Related

- Packaging / SemVer `BASE-N`: [packaging/README.md](../packaging/README.md)
- Product version stamp: `GROK_VERSION` in release CI (same as upstream contract)
