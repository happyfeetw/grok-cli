//! Official-style version stamp (upstream Grok Build contract).
//!
//! Release / packaging builds set process env `GROK_VERSION`. When present we
//! forward it with `cargo:rustc-env` so `option_env!("GROK_VERSION")` in
//! `lib.rs` resolves. When absent, `lib.rs` falls back to `CARGO_PKG_VERSION`
//! (local/dev builds).

fn main() {
    println!("cargo:rerun-if-env-changed=GROK_VERSION");
    if let Ok(v) = std::env::var("GROK_VERSION") {
        let t = v.trim();
        if !t.is_empty() {
            println!("cargo:rustc-env=GROK_VERSION={t}");
        }
    }
}
