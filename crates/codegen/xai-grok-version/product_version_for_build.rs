//! Shared product-version resolution for **build scripts only**
//! (`xai-grok-version`, `xai-grok-pager-bin`, `xai-grok-pager`).
//!
//! # Product version vs Cargo crate version
//!
//! This monorepo has many crates, each with its own `Cargo.toml` `version`
//! (often an upstream alpha like `0.1.220-alpha.4` or `0.2.0-dev`). That is
//! **not** the user-facing CLI / npm / Homebrew version.
//!
//! The **only** product-version source of truth is:
//!
//! ```text
//! packaging/VERSION
//! ```
//!
//! Optionally overridden by the process env `GROK_VERSION` (release CI sets
//! this explicitly so the stamp is auditable in logs).
//!
//! # Resolution order
//!
//! 1. `GROK_VERSION` env (non-empty)
//! 2. Repo-root `packaging/VERSION`
//! 3. Dev fallback `0.0.0-dev` (never a random crate `CARGO_PKG_VERSION`)
//!
//! Release CI sets `GROK_RELEASE_BUILD=1`. If resolution lands on the dev
//! fallback while that flag is set, the build **panics** so a misconfigured
//! pipeline cannot ship a binary that lies about its version.

use std::path::PathBuf;

/// Where the product version string came from.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProductVersionSource {
    /// `GROK_VERSION` process environment.
    Env,
    /// `packaging/VERSION` on disk.
    PackagingFile,
    /// Last-resort local/dev placeholder — never a Cargo package version.
    DevFallback,
}

impl ProductVersionSource {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Env => "env:GROK_VERSION",
            Self::PackagingFile => "packaging/VERSION",
            Self::DevFallback => "dev-fallback",
        }
    }

    pub fn is_release_grade(self) -> bool {
        matches!(self, Self::Env | Self::PackagingFile)
    }
}

/// Resolve the product version for stamping into binaries / `xai-grok-version`.
pub fn resolve_product_version() -> (String, ProductVersionSource) {
    if let Ok(v) = std::env::var("GROK_VERSION") {
        let t = v.trim();
        if !t.is_empty() {
            return (t.to_owned(), ProductVersionSource::Env);
        }
    }

    if let Some(v) = read_packaging_version() {
        return (v, ProductVersionSource::PackagingFile);
    }

    ("0.0.0-dev".to_owned(), ProductVersionSource::DevFallback)
}

/// Same as [`resolve_product_version`], but panics when a release build would
/// otherwise use the dev fallback.
pub fn resolve_product_version_for_build() -> (String, ProductVersionSource) {
    let (version, source) = resolve_product_version();
    let release_build = env_flag("GROK_RELEASE_BUILD") || env_flag("GROK_REQUIRE_PRODUCT_VERSION");
    if release_build && !source.is_release_grade() {
        panic!(
            "product version unavailable for release build \
             (set GROK_VERSION or ensure packaging/VERSION exists). \
             Refusing to fall back to a Cargo crate version. source={}",
            source.as_str()
        );
    }
    // Visible in `cargo build -vv` / CI logs without spamming normal builds.
    println!(
        "cargo:rustc-env=GROK_PRODUCT_VERSION_SOURCE={}",
        source.as_str()
    );
    eprintln!(
        "product-version: {version} (source={})",
        source.as_str()
    );
    (version, source)
}

fn env_flag(name: &str) -> bool {
    match std::env::var(name) {
        Ok(v) => matches!(
            v.trim().to_ascii_lowercase().as_str(),
            "1" | "true" | "yes" | "on"
        ),
        Err(_) => false,
    }
}

fn read_packaging_version() -> Option<String> {
    let mut dir = PathBuf::from(std::env::var_os("CARGO_MANIFEST_DIR")?);
    for _ in 0..10 {
        let candidate = dir.join("packaging").join("VERSION");
        if candidate.is_file() {
            let raw = std::fs::read_to_string(&candidate).ok()?;
            let t = raw.trim();
            if !t.is_empty() {
                return Some(t.to_owned());
            }
            return None;
        }
        if !dir.pop() {
            break;
        }
    }
    None
}
