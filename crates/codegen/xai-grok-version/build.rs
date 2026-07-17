//! Stamp `GROK_VERSION` into the crate so `option_env!("GROK_VERSION")` and
//! release binaries report the packaging version (`packaging/VERSION`), not the
//! Cargo crate version (often a long-lived upstream alpha like `0.1.220-alpha.4`).
//!
//! Resolution order:
//! 1. Process env `GROK_VERSION` (CI / release builds must set this)
//! 2. Repo-root `packaging/VERSION` when present (local packaging dry-runs)
//! 3. Unset → `lib.rs` falls back to `CARGO_PKG_VERSION`

use std::path::PathBuf;

fn main() {
    println!("cargo:rerun-if-env-changed=GROK_VERSION");
    println!("cargo:rerun-if-changed=packaging/VERSION");

    if let Some(version) = resolve_version() {
        // Available to this crate via option_env!/env!("GROK_VERSION").
        println!("cargo:rustc-env=GROK_VERSION={version}");
    }
}

fn resolve_version() -> Option<String> {
    if let Ok(v) = std::env::var("GROK_VERSION") {
        let t = v.trim();
        if !t.is_empty() {
            return Some(t.to_owned());
        }
    }

    // Walk up from CARGO_MANIFEST_DIR to find packaging/VERSION (workspace root).
    let mut dir = PathBuf::from(std::env::var_os("CARGO_MANIFEST_DIR")?);
    for _ in 0..8 {
        let candidate = dir.join("packaging").join("VERSION");
        if candidate.is_file() {
            if let Ok(raw) = std::fs::read_to_string(&candidate) {
                let t = raw.trim();
                if !t.is_empty() {
                    return Some(t.to_owned());
                }
            }
            break;
        }
        if !dir.pop() {
            break;
        }
    }
    None
}
