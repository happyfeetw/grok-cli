//! Stamp the **product** version into this crate.
//!
//! See [`product_version_for_build`] for the SSOT rules (`packaging/VERSION`,
//! never Cargo crate versions for user-facing CLI identity).

#[path = "product_version_for_build.rs"]
mod product_version_for_build;

fn main() {
    println!("cargo:rerun-if-env-changed=GROK_VERSION");
    println!("cargo:rerun-if-env-changed=GROK_RELEASE_BUILD");
    println!("cargo:rerun-if-env-changed=GROK_REQUIRE_PRODUCT_VERSION");
    println!("cargo:rerun-if-changed=packaging/VERSION");
    // Relative path from this crate to the monorepo packaging file (best-effort
    // for cargo's change tracking; resolve still walks parents).
    println!("cargo:rerun-if-changed=../../../packaging/VERSION");

    let (version, _source) = product_version_for_build::resolve_product_version_for_build();
    // Always set — `lib.rs` uses `env!("GROK_VERSION")` with no Cargo fallback.
    println!("cargo:rustc-env=GROK_VERSION={version}");
}
