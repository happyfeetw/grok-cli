#!/usr/bin/env bash
# Verify fork policy: toolchain pin match + Cargo.lock third-party == upstream.
# Exit 0 if OK. Intended for local use and optional CI.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
exec "$ROOT/packaging/scripts/merge-upstream.sh" --check-only "$@"
