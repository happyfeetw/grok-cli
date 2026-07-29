#!/usr/bin/env bash
# Merge xai-org/grok-build into this fork without drifting third-party deps.
#
# Policy (strict upstream lock):
#   1. Prefer upstream's Cargo.lock for all registry/git crates.
#   2. Never run `cargo generate-lockfile` or unconstrained `cargo update`.
#   3. After merge, only refresh shipping path crates to packaging/VERSION
#      (BASE-N) via `cargo update -p …` on those packages.
#   4. Keep rust-toolchain.toml channel in lockstep with release CI.
#
# Usage:
#   packaging/scripts/merge-upstream.sh                    # merge + finalize
#   packaging/scripts/merge-upstream.sh --merge-only       # merge, no Cargo work
#   packaging/scripts/merge-upstream.sh --finalize-only    # restamp after merge
#   packaging/scripts/merge-upstream.sh --check-only       # verify policy only
#   packaging/scripts/merge-upstream.sh --no-fetch --ref <full-sha>
#
# Exit codes:
#   0  success (including an already-merged upstream ref)
#   2  invalid arguments
#   10 merge conflicts remain; no Cargo command was run
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_REF="${UPSTREAM_REF:-main}"
MODE="full"
FETCH_UPSTREAM=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-only) MODE="check"; shift ;;
    --merge-only) MODE="merge"; shift ;;
    --finalize-only) MODE="finalize"; shift ;;
    --no-fetch) FETCH_UPSTREAM=0; shift ;;
    --ref)
      [[ $# -ge 2 ]] || { echo "error: --ref requires a value" >&2; exit 2; }
      UPSTREAM_REF="$2"
      shift 2
      ;;
    --remote)
      [[ $# -ge 2 ]] || { echo "error: --remote requires a value" >&2; exit 2; }
      UPSTREAM_REMOTE="$2"
      shift 2
      ;;
    -h|--help)
      sed -n '2,25p' "$0"
      exit 0
      ;;
    *)
      echo "unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

die() { echo "error: $*" >&2; exit 1; }
info() { echo "→ $*"; }

toolchain_channel() {
  # channel = "1.92.0"
  sed -n 's/^channel = "\([^"]*\)"/\1/p' rust-toolchain.toml | head -1
}

release_workflow_toolchain() {
  # toolchain: "1.92.0" in release-macos.yml
  sed -n 's/.*toolchain: *"\([^"]*\)".*/\1/p' .github/workflows/release-macos.yml | head -1
}

verify_toolchain_pin() {
  local tt wf
  tt="$(toolchain_channel)"
  wf="$(release_workflow_toolchain)"
  [[ -n "$tt" ]] || die "could not read channel from rust-toolchain.toml"
  [[ -n "$wf" ]] || die "could not read toolchain from release-macos.yml"
  if [[ "$tt" != "$wf" ]]; then
    die "toolchain mismatch: rust-toolchain.toml=$tt vs release-macos.yml=$wf
Bump both together when following upstream; do not leave CI on a different pin."
  fi
  info "toolchain pin OK: $tt (rust-toolchain.toml + release CI)"
}

align_release_workflow_toolchain() {
  local channel
  channel="$(toolchain_channel)"
  [[ -n "$channel" ]] || die "could not read channel from rust-toolchain.toml"
  python3 - "$channel" <<'PY'
import re
import sys
from pathlib import Path

channel = sys.argv[1]
path = Path(".github/workflows/release-macos.yml")
before = path.read_text()
after, count = re.subn(
    r'(?m)^(\s*toolchain:\s*)"[^"]+"(\s*)$',
    rf'\g<1>"{channel}"\g<2>',
    before,
)
if count == 0:
    print("error: release-macos.yml has no explicit toolchain pin", file=sys.stderr)
    sys.exit(1)
path.write_text(after)
print(f"→ release workflow toolchain aligned to {channel} ({count} occurrence)")
PY
}

# Compare third-party package versions (registry/git) between two lockfiles.
# Path packages may differ (fork BASE-N shipping versions).
verify_lock_third_party() {
  local ours="$1"
  local theirs="$2"
  local label="${3:-upstream}"
  python3 - "$ours" "$theirs" "$label" <<'PY'
import re, sys
from pathlib import Path

ours_p, theirs_p, label = sys.argv[1], sys.argv[2], sys.argv[3]

def registry_packages(text: str) -> dict[str, str]:
    """name -> version for packages with a crates.io/git source."""
    out: dict[str, str] = {}
    blocks = re.split(r"\n\[\[package\]\]\n", text)
    for b in blocks:
        name_m = re.search(r'^name = "([^"]+)"', b, re.M)
        ver_m = re.search(r'^version = "([^"]+)"', b, re.M)
        src_m = re.search(r'^source = "([^"]+)"', b, re.M)
        if not (name_m and ver_m and src_m):
            continue  # path / workspace members without source
        name, ver, src = name_m.group(1), ver_m.group(1), src_m.group(1)
        if "registry+" in src or "git+" in src:
            # Multiple versions of same name can exist; key by name@version
            out[f"{name}@{ver}"] = src
    return out

ours = registry_packages(Path(ours_p).read_text())
theirs = registry_packages(Path(theirs_p).read_text())

# Intentional fork delta: reqwest `system-proxy` (upstream disables it).
# Pure additions and extra co-installed versions of these names are allowed.
FORK_SYSTEM_PROXY_ALLOW = {
    "system-configuration",
    "system-configuration-sys",
    "windows-registry",
    "core-foundation",  # older co-version pulled by system-configuration
    "core-foundation-sys",
}

def pkg_name(key: str) -> str:
    return key.split("@", 1)[0]

only_ours_raw = sorted(set(ours) - set(theirs))
only_theirs = sorted(set(theirs) - set(ours))
only_ours = sorted(
    k for k in only_ours_raw if pkg_name(k) not in FORK_SYSTEM_PROXY_ALLOW
)
allowed_extras = sorted(
    k for k in only_ours_raw if pkg_name(k) in FORK_SYSTEM_PROXY_ALLOW
)
# Same name@ver is enough for alignment; source URL should match when both present
src_mismatch = sorted(
    k for k in set(ours) & set(theirs) if ours[k] != theirs[k]
)

ok = True
if only_ours:
    ok = False
    print(f"error: Cargo.lock has registry/git packages not in {label}:", file=sys.stderr)
    for k in only_ours[:40]:
        print(f"  + {k}", file=sys.stderr)
    if len(only_ours) > 40:
        print(f"  … and {len(only_ours) - 40} more", file=sys.stderr)
if only_theirs:
    ok = False
    print(f"error: Cargo.lock missing registry/git packages from {label}:", file=sys.stderr)
    for k in only_theirs[:40]:
        print(f"  - {k}", file=sys.stderr)
    if len(only_theirs) > 40:
        print(f"  … and {len(only_theirs) - 40} more", file=sys.stderr)
if src_mismatch:
    ok = False
    print(f"error: source URL drift vs {label}:", file=sys.stderr)
    for k in src_mismatch[:20]:
        print(f"  {k}", file=sys.stderr)

if not ok:
    print(
        "\nPolicy: keep upstream Cargo.lock for third-party deps.\n"
        "  git checkout upstream/main -- Cargo.lock\n"
        "  cargo update -p xai-grok-pager -p xai-grok-pager-bin -p xai-grok-version\n"
        "Never: cargo generate-lockfile  (causes MSRV / dependency drift)\n"
        "Allowed fork-only extras: system-proxy stack "
        f"({', '.join(sorted(FORK_SYSTEM_PROXY_ALLOW))})",
        file=sys.stderr,
    )
    sys.exit(1)

msg = f"→ Cargo.lock third-party packages match {label} ({len(theirs)} upstream entries)"
if allowed_extras:
    msg += f"; fork system-proxy extras OK ({len(allowed_extras)})"
print(msg)
PY
}

shipping_base_from_upstream_tree() {
  # Prefer pager-bin / shell version on the merged tree tip we are syncing to.
  local ref="$1"
  local v
  v="$(git show "${ref}:crates/codegen/xai-grok-shell/Cargo.toml" 2>/dev/null \
    | sed -n 's/^version = "\([0-9][0-9.]*\)"/\1/p' | head -1)"
  if [[ -z "$v" ]]; then
    v="$(git show "${ref}:crates/codegen/xai-grok-pager/Cargo.toml" 2>/dev/null \
      | sed -n 's/^version = "\([0-9][0-9.]*\)"/\1/p' | head -1)"
  fi
  echo "$v"
}

stamp_shipping_to_fork_version() {
  local fork_ver="$1"
  info "stamp shipping crates + packaging to ${fork_ver}"
  printf '%s\n' "$fork_ver" > packaging/VERSION
  node packaging/scripts/sync-version.js
  # Only touch path package entries; do not upgrade registry crates.
  cargo update -p xai-grok-pager -p xai-grok-pager-bin -p xai-grok-version
}

restore_upstream_lock_and_restamp() {
  local ref="$1"
  local fork_ver="$2"
  info "restore Cargo.lock from ${ref} (strict upstream third-party pins)"
  git checkout "$ref" -- Cargo.lock
  stamp_shipping_to_fork_version "$fork_ver"
}

# --- checks that run before fetching / resolving the upstream ref ---
# Finalization may follow an upstream toolchain bump. It aligns release CI
# deterministically before verifying the shared pin.
if [[ "$MODE" != "finalize" ]]; then
  verify_toolchain_pin
fi

if [[ "$FETCH_UPSTREAM" -eq 1 ]]; then
  if ! git remote get-url "$UPSTREAM_REMOTE" >/dev/null 2>&1; then
    die "remote '${UPSTREAM_REMOTE}' not configured (expected xai-org/grok-build)"
  fi
  info "fetch ${UPSTREAM_REMOTE}"
  git fetch "$UPSTREAM_REMOTE" --tags
else
  info "skip fetch (--no-fetch)"
fi

UPSTREAM_TIP="${UPSTREAM_REMOTE}/${UPSTREAM_REF}"
if [[ "$UPSTREAM_REF" != "main" && "$UPSTREAM_REF" != "master" ]] \
  && git rev-parse --verify "${UPSTREAM_REF}^{commit}" >/dev/null 2>&1; then
  # Prefer an already-resolved raw SHA / tag over a remote branch name.
  UPSTREAM_TIP="$UPSTREAM_REF"
fi
git rev-parse --verify "${UPSTREAM_TIP}^{commit}" >/dev/null 2>&1 \
  || die "cannot resolve ${UPSTREAM_TIP}"
UPSTREAM_TIP="$(git rev-parse "${UPSTREAM_TIP}^{commit}")"

info "upstream tip: $(git rev-parse --short "$UPSTREAM_TIP") $(git log -1 --oneline "$UPSTREAM_TIP")"

# Verify current tree lock against upstream tip for policy checks. Before a new
# merge it may legitimately differ, and finalize mode repairs it first.
if [[ "$MODE" == "check" && -f Cargo.lock ]]; then
  tmp_up="$(mktemp)"
  git show "${UPSTREAM_TIP}:Cargo.lock" >"$tmp_up"
  verify_lock_third_party Cargo.lock "$tmp_up" "$UPSTREAM_TIP"
  rm -f "$tmp_up"
fi

if [[ "$MODE" == "check" ]]; then
  git merge-base --is-ancestor "$UPSTREAM_TIP" HEAD \
    || die "${UPSTREAM_TIP} is not an ancestor of HEAD"
  info "check-only: policy OK"
  exit 0
fi

if [[ -n "$(git status --porcelain)" ]]; then
  die "working tree not clean; start from a clean checkout"
fi

BASE="$(shipping_base_from_upstream_tree "$UPSTREAM_TIP")"
[[ -n "$BASE" ]] || die "could not read upstream shipping version from ${UPSTREAM_TIP}"
FORK_VER="${BASE}-1"
# If packaging already on same base with higher -N, keep higher N only when not resetting base.
CUR="$(tr -d '[:space:]' < packaging/VERSION || true)"
if [[ "$CUR" == "${BASE}-"* ]]; then
  # already on this base — leave N bump to human; default still -1 after fresh sync
  info "note: packaging/VERSION is already ${CUR} (base ${BASE}); will set ${FORK_VER} for a full re-sync stamp (edit after if you need -2+)"
fi

if [[ "$MODE" == "finalize" ]]; then
  git merge-base --is-ancestor "$UPSTREAM_TIP" HEAD \
    || die "${UPSTREAM_TIP} is not an ancestor of HEAD; merge it before finalizing"
else
  if git merge-base --is-ancestor "$UPSTREAM_TIP" HEAD; then
    info "already merged: ${UPSTREAM_TIP}"
    if [[ "$MODE" == "merge" ]]; then
      exit 0
    fi
  else
    info "merge ${UPSTREAM_TIP} (no Cargo commands in merge phase)"
    set +e
    git merge --no-edit "$UPSTREAM_TIP"
    merge_rc=$?
    set -e

    if [[ "$merge_rc" -ne 0 ]]; then
      if [[ -f Cargo.lock ]]; then
        info "resolve Cargo.lock from ${UPSTREAM_TIP}; leave semantic conflicts for Codex"
        git checkout "$UPSTREAM_TIP" -- Cargo.lock
      fi
      echo
      echo "Merge conflicts remain. No Cargo command or version-stamping script was run."
      echo "Resolve the remaining files and commit the merge. Then run finalization on"
      echo "a GitHub-hosted runner:"
      echo "  packaging/scripts/merge-upstream.sh --finalize-only --no-fetch --ref ${UPSTREAM_TIP}"
      exit 10
    fi
  fi

  if [[ "$MODE" == "merge" ]]; then
    info "merge-only finished; no Cargo command or version stamp was run"
    exit 0
  fi
fi

# Finalization intentionally runs only after the upstream commit is part of
# HEAD. This is the only phase that restores/stamps Cargo metadata.
align_release_workflow_toolchain
restore_upstream_lock_and_restamp "$UPSTREAM_TIP" "$FORK_VER"

tmp_up="$(mktemp)"
git show "${UPSTREAM_TIP}:Cargo.lock" >"$tmp_up"
verify_lock_third_party Cargo.lock "$tmp_up" "$UPSTREAM_TIP"
rm -f "$tmp_up"
verify_toolchain_pin

info "finalization finished; packaging/VERSION=${FORK_VER}"
info "next: update CHANGELOG, commit, and tag v${FORK_VER}"
info "verify: packaging/scripts/merge-upstream.sh --check-only"
