//! # FFI bridge to the Lean 4 certificate core
//!
//! Raw C-ABI bindings to the Lean 4 exported certificate-check function from
//! `certificate-core` (module `FFI.lean`, symbol `certificate_check`).
//!
//! ## Build modes
//!
//! * `lean-ffi` **feature enabled**: the kernel-checked Lean export is linked
//!   from the `certificate_core` static library (built by `build.rs`). This is
//!   the ADR's Tier-1 verification path: the mathematical theorem lives in the
//!   Lean kernel.
//! * **feature disabled** (default): no Lean toolchain is required. The symbol
//!   is resolved to a Rust fallback that performs the same input validation as
//!   the Lean export. The *operational* certificate that gates real traffic is
//!   the pure-Rust [`crate::certificate::CertifiedState`], which is
//!   Kani-verified against the Lean specification in `tests/kani/`.
//!
//! ## Trust boundary
//!
//! This module is the **only** `unsafe` entry point in the crate. All calls
//! reaching `raw::certificate_check` must uphold the documented safety
//! requirements. Every other module is `#![forbid(unsafe_code)]`.

/// Raw C-ABI bindings. These are `unsafe` by construction.
pub mod raw {
    /// Check the spectral contraction certificate for a heat step.
    ///
    /// Returns `1` when the certificate holds within tolerance, `0` when
    /// it is violated, and `-1` on invalid input.
    ///
    /// # Safety
    ///
    /// - `n` must be the length of the field `u`.
    /// - `u_ptr` must point to at least `n` valid, aligned `f64` values.
    /// - The Lean runtime must be initialized before this is called when
    ///   the `lean-ffi` feature is enabled.
    pub unsafe fn certificate_check(
        n: usize,
        u_ptr: *const f64,
        alpha: f64,
        lambda_2: f64,
        lambda_max: f64,
    ) -> i32 {
        // The authoritative export lives in the Lean static library. When the
        // toolchain is available it is linked here.
        #[cfg(feature = "lean-ffi")]
        {
            extern "C" {
                #[link_name = "certificate_check"]
                fn lean_certificate_check(
                    n: usize,
                    u: *const f64,
                    alpha: f64,
                    lambda_2: f64,
                    lambda_max: f64,
                ) -> i32;
            }
            return lean_certificate_check(n, u_ptr, alpha, lambda_2, lambda_max);
        }

        // Fallback: validate inputs exactly as the Lean export does. The
        // symbol is also implemented when the Lean library is unavailable so
        // that integration tests and heterogeneous builds stay green.
        #[cfg(not(feature = "lean-ffi"))]
        {
            if n == 0 || u_ptr.is_null() {
                return -1;
            }
            if !(lambda_max > 0.0) || !(lambda_2 > 0.0) {
                return -1;
            }
            let u = unsafe { core::slice::from_raw_parts(u_ptr, n) };
            if u.iter().any(|x| x.is_nan()) {
                return -1;
            }
            let upper = 2.0 / lambda_max;
            if !(alpha > 0.0 && alpha < upper) {
                return -1;
            }
            // The contraction factor (1 - αλ₂) must be a valid probability.
            let q = 1.0 - alpha * lambda_2;
            if !(q > 0.0 && q < 1.0) {
                return 0;
            }
            1
        }
    }
}

/// Public re-export for integration tests.
pub use raw::certificate_check;

/// The exported symbol name declared by the Lean `@[export certificate_check]`.
pub const EXPORTED_SYMBOL: &str = "certificate_check";

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn exported_symbol_matches_doc() {
        assert_eq!(EXPORTED_SYMBOL, "certificate_check");
    }

    #[test]
    fn invalid_input_returns_minus_one() {
        assert_eq!(
            unsafe { raw::certificate_check(0, core::ptr::null(), 0.1, 1.0, 2.0) },
            -1
        );
        assert_eq!(
            unsafe { raw::certificate_check(2, core::ptr::null(), 0.1, 1.0, 2.0) },
            -1
        );
        let u = [1.0, 2.0];
        assert_eq!(
            unsafe { raw::certificate_check(2, u.as_ptr(), 0.1, 1.0, 0.0) },
            -1
        );
    }

    #[test]
    fn valid_input_returns_positive() {
        let u = [1.0, 2.0, 3.0];
        let r = unsafe { raw::certificate_check(3, u.as_ptr(), 0.1, 0.5, 2.0) };
        assert_eq!(r, 1);
    }

    #[test]
    fn nan_rejected() {
        let u = [f64::NAN, 1.0];
        let r = unsafe { raw::certificate_check(2, u.as_ptr(), 0.1, 0.5, 2.0) };
        assert_eq!(r, -1);
    }
}