//! Pager library build script: stamp `VERSION_WITH_COMMIT` for tracing / OTEL.
//!
//! Product version SSOT is `packaging/VERSION` (shared with the binary and
//! `xai-grok-version`) — never this package's Cargo.toml version.

use std::process::Command;

#[path = "../xai-grok-version/product_version_for_build.rs"]
mod product_version_for_build;

fn main() {
    println!("cargo:rerun-if-changed=.git/HEAD");
    println!("cargo:rerun-if-env-changed=GROK_VERSION");
    println!("cargo:rerun-if-env-changed=GROK_RELEASE_BUILD");
    println!("cargo:rerun-if-env-changed=GROK_REQUIRE_PRODUCT_VERSION");
    println!("cargo:rerun-if-changed=packaging/VERSION");
    println!("cargo:rerun-if-changed=../../../packaging/VERSION");

    let commit = Command::new("git")
        .args(["rev-parse", "--short", "HEAD"])
        .output()
        .ok()
        .filter(|o| o.status.success())
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|| "unknown".to_string());

    let (version, _source) = product_version_for_build::resolve_product_version_for_build();

    println!(
        "cargo:rustc-env=VERSION_WITH_COMMIT={} ({})",
        version, commit
    );
}
