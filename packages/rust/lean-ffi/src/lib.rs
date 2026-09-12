//! Lean ↔ Rust FFI bridge using `lean-rs-host`.
//!
//! This crate is the Rust consumer of the `lean/FFI/Bridge.lean` capability.
//! It initialises the Lean runtime, opens the Lake project, loads the `FFI`
//! shared library, and provides typed wrappers around every exported symbol.
//!
//! ## Proof-certificate preservation
//!
//! The Lean side exports the raw certificate bytes for the 108-cycle
//! admissibility proof.  Rust can re-verify those bytes through
//! `lean_sdk::verify_certificate`, which checks:
//!   * Hecke recurrence per prime block
//!   * Deligne bound per prime block
//!   * Effective Lipschitz constant ≤ ACE_BOUND
//!
//! ## Build integration
//!
//! `build.rs` uses `lean-toolchain` to invoke `lake build FFI:shared`,
//! emitting the correct `cargo:rustc-link-*` directives so the dylib is
//! found at link time.

use lean_rs::LeanResult;
use lean_rs_host::{LeanCapabilities, LeanElabOptions, LeanHost, LeanSession};
use lean_sdk::verify_certificate;
use std::path::PathBuf;

// ---------------------------------------------------------------------------
// FFIBridge — the single entry point
// ---------------------------------------------------------------------------

/// One-time initialised bridge to the Lean `FFI` capability.
///
/// Holds a [`LeanHost`] (process-lifetime) and a [`LeanCapabilities`]
/// (reused across sessions).  Drop closes the underlying dylibs.
pub struct FFIBridge {
    host: LeanHost,
    caps: LeanCapabilities,
}

impl FFIBridge {
    /// Open the Lake project rooted at `lean/` and load the `FFI` library.
    pub fn new() -> LeanResult<Self> {
        let lake_root = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .parent()
            .expect("crate lives under the repo root")
            .join("lean");

        let runtime = lean_rs::LeanRuntime::init()?;
        let host = LeanHost::from_lake_project(runtime, &lake_root)?;
        let caps = host.load_capabilities("Prime", "FFI")?;

        Ok(Self { host, caps })
    }

    /// Open a fresh session for one unit of FFI work.
    pub fn session(&self) -> LeanResult<FFISession<'_>> {
        let sess = self.caps.session(&["FFI"], None, None)?;
        Ok(FFISession { session: sess })
    }

    /// Convenience: fetch ACE_BOUND without opening a dedicated session.
    /// Uses the host shim-only path which is sufficient for scalar reads.
    pub fn ace_bound(&self) -> LeanResult<f64> {
        let shims = self.host.load_shims_only()?;
        let mut sess = shims.session(&["FFI"], None, None)?;
        let export = sess.exported::<(), f64>("lean_ace_bound")?;
        export.call(())
    }

    /// Convenience: check whether cycle108 is admissible.
    pub fn cycle108_admissible(&self) -> LeanResult<bool> {
        let shims = self.host.load_shims_only()?;
        let mut sess = shims.session(&["FFI"], None, None)?;
        let export = sess.exported::<(), u8>("lean_cycle108_admissible")?;
        let raw = export.call(())?;
        Ok(raw != 0)
    }

    /// Convenience: dimension of the 108-cycle tensor product space.
    pub fn cycle108_dimension(&self) -> LeanResult<u64> {
        let shims = self.host.load_shims_only()?;
        let mut sess = shims.session(&["FFI"], None, None)?;
        let export = sess.exported::<(), u64>("lean_cycle108_dimension")?;
        export.call(())
    }

    /// Convenience: effective Lipschitz constant for the 108-cycle.
    pub fn cycle108_lambda_eff(&self) -> LeanResult<f64> {
        let shims = self.host.load_shims_only()?;
        let mut sess = shims.session(&["FFI"], None, None)?;
        let export = sess.exported::<(), f64>("lean_cycle108_lambda_eff")?;
        export.call(())
    }

    /// End-to-end verification: generate the canonical 108-cycle certificate
    /// via `lean_sdk`, then confirm the Lean-proved constants are consistent.
    ///
    /// Returns `true` iff:
    ///   * The canonical word verifies against Rust-side Hecke + Deligne + Lipschitz checks
    ///   * The computed λ_eff matches the Lean-exported value
    pub fn verify_cycle108_proof(&self) -> LeanResult<bool> {
        use lean_sdk::{generate_canonical_word, verify_certificate, IRWord};
        let word = generate_canonical_word();
        let bytes = word.to_bytes();
        let result = verify_certificate(&bytes);
        if !result.is_valid {
            return Ok(false);
        }
        let lean_lambda = self.cycle108_lambda_eff()?;
        let lambda_match = (result.lambda_eff - lean_lambda).abs() < 1e-9;
        Ok(lambda_match)
    }
}

// ---------------------------------------------------------------------------
// FFISession — typed wrappers around a single Lean session
// ---------------------------------------------------------------------------

/// A borrowed Lean session pre-loaded with the `FFI` library.
pub struct FFISession<'a> {
    session: LeanSession<'a>,
}

impl<'a> FFISession<'a> {
    /// Elaborate a Lean term string in the session environment.
    pub fn elaborate(&mut self, term: &str) -> LeanResult<lean_rs::LeanExpr> {
        let opts = LeanElabOptions::new();
        let elaborated = self.session.elaborate(term, None, &opts, None)?;
        Ok(elaborated)
    }

    /// Query the kind of a Lean declaration by name.
    pub fn declaration_kind(&mut self, name: &str) -> LeanResult<String> {
        self.session.declaration_kind(name, None)
    }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    /// Integration test: initialise the bridge and read ACE_BOUND.
    #[test]
    fn test_ace_bound() {
        let bridge = FFIBridge::new().expect("bridge must initialise");
        let bound = bridge.ace_bound().expect("ace_bound must call Lean");
        assert!((bound - 0.6).abs() < 1e-9, "ACE_BOUND must be 0.6, got {}", bound);
    }

    /// Integration test: cycle108 admissibility.
    #[test]
    fn test_cycle108_admissible() {
        let bridge = FFIBridge::new().expect("bridge must initialise");
        let admissible = bridge
            .cycle108_admissible()
            .expect("cycle108_admissible must call Lean");
        assert!(admissible, "cycle108 must be admissible");
    }

    /// Integration test: dimension == 108.
    #[test]
    fn test_cycle108_dimension() {
        let bridge = FFIBridge::new().expect("bridge must initialise");
        let dim = bridge
            .cycle108_dimension()
            .expect("cycle108_dimension must call Lean");
        assert_eq!(dim, 108, "dimension must be 108");
    }

    /// Integration test: proof certificate verification with Lean constant.
    #[test]
    fn test_cycle108_proof_roundtrip() {
        use lean_sdk::{generate_canonical_word, verify_certificate};
        let bridge = FFIBridge::new().expect("bridge must initialise");

        let word = generate_canonical_word();
        let bytes = word.to_bytes();
        let result = verify_certificate(&bytes);
        assert!(result.is_valid, "canonical word must verify");

        let lean_lambda = bridge
            .cycle108_lambda_eff()
            .expect("cycle108_lambda_eff must call Lean");
        assert!(
            (result.lambda_eff - lean_lambda).abs() < 1e-9,
            "Rust lambda_eff {} must match Lean {}",
            result.lambda_eff,
            lean_lambda
        );
    }
}
