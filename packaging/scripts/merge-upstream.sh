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
#   packaging/scripts/merge-upstream.sh              # merge upstream/main
#   packaging/scripts/merge-upstream.sh --check-only # verify policy, no merge
#   packaging/scripts/merge-upstream.sh --ref a5727c5
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_REF="${UPSTREAM_REF:-main}"
CHECK_ONLY=0
DO_MERGE=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-only) CHECK_ONLY=1; DO_MERGE=0; shift ;;
    --ref) UPSTREAM_REF="$2"; shift 2 ;;
    --remote) UPSTREAM_REMOTE="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,20p' "$0"
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

# --- checks that always run ---
verify_toolchain_pin

if ! git remote get-url "$UPSTREAM_REMOTE" >/dev/null 2>&1; then
  die "remote '${UPSTREAM_REMOTE}' not configured (expected xai-org/grok-build)"
fi

info "fetch ${UPSTREAM_REMOTE}"
git fetch "$UPSTREAM_REMOTE" --tags

UPSTREAM_TIP="${UPSTREAM_REMOTE}/${UPSTREAM_REF}"
if [[ "$UPSTREAM_REF" != main && "$UPSTREAM_REF" != master ]]; then
  # allow raw sha / tag
  if git rev-parse --verify "$UPSTREAM_REF" >/dev/null 2>&1; then
    UPSTREAM_TIP="$UPSTREAM_REF"
  fi
fi
git rev-parse --verify "$UPSTREAM_TIP" >/dev/null 2>&1 \
  || die "cannot resolve ${UPSTREAM_TIP}"

info "upstream tip: $(git rev-parse --short "$UPSTREAM_TIP") $(git log -1 --oneline "$UPSTREAM_TIP")"

# Verify current tree lock against upstream tip when already merged or for check-only.
if [[ -f Cargo.lock ]]; then
  tmp_up="$(mktemp)"
  git show "${UPSTREAM_TIP}:Cargo.lock" >"$tmp_up"
  if ! verify_lock_third_party Cargo.lock "$tmp_up" "$UPSTREAM_TIP"; then
    if [[ "$CHECK_ONLY" -eq 1 ]]; then
      rm -f "$tmp_up"
      exit 1
    fi
    info "third-party lock drift detected — will restore from upstream after merge"
  fi
  rm -f "$tmp_up"
fi

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  info "check-only: policy OK"
  exit 0
fi

if [[ -n "$(git status --porcelain)" ]]; then
  die "working tree not clean; commit or stash before merge-upstream"
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

info "merge ${UPSTREAM_TIP} (no commit if conflicts)"
set +e
git merge --no-edit "$UPSTREAM_TIP"
merge_rc=$?
set -e

# Always force upstream lock for third-party, even if merge auto-resolved a hybrid.
restore_upstream_lock_and_restamp "$UPSTREAM_TIP" "$FORK_VER"

# Re-check
tmp_up="$(mktemp)"
git show "${UPSTREAM_TIP}:Cargo.lock" >"$tmp_up"
verify_lock_third_party Cargo.lock "$tmp_up" "$UPSTREAM_TIP"
rm -f "$tmp_up"
verify_toolchain_pin

if [[ "$merge_rc" -ne 0 ]]; then
  echo
  echo "Merge reported conflicts. Cargo.lock has been restored from upstream and"
  echo "shipping versions stamped to ${FORK_VER}."
  echo "Resolve remaining files, keep fork branding (grok-cli / system-proxy), then:"
  echo "  git add -A && git commit"
  echo "  packaging/scripts/merge-upstream.sh --check-only"
  exit 1
fi

info "merge finished; packaging/VERSION=${FORK_VER}"
info "next: resolve any branding conflicts if needed, update CHANGELOG, commit, tag v${FORK_VER}"
info "verify: packaging/scripts/merge-upstream.sh --check-only"
