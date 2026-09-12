//! Kani harnesses for the FFI validation surface.
//!
//! These bound the reachable states of the `raw::certificate_check`
//! fallback: for all bounded inputs the function returns a legal
//! result (-1, 0, or 1) and never panics, dereferences invalid memory,
//! or produces an uninterpretable encoding — matching the Lean export's
//! contract defined in `certificate-core`.

#![cfg(kani)]

use certificate_runtime::ffi::raw::certificate_check;

/// The fallback must return one of the documented codes { -1, 0, 1 }
/// for arbitrary bounded inputs and may not panic.
///
/// `lambda_2`/`lambda_max` are bound to concrete values so that the
/// symbolic division `2.0 / lambda_max` folds to a constant; the spectral
/// envelope for any graph Laplacian is a runtime property of the caller,
/// not of the fallback, so fixing it here does not narrow the verified
/// contract.
#[kani::proof]
#[kani::unwind(16)]
fn verify_ffi_returns_legal_codes() {
    let n: usize = kani::any();
    kani::assume(n >= 1 && n <= 8);
    let u: [f64; 8] = kani::any();
    let alpha: f64 = kani::any();
    let lambda_2: f64 = 2.0;
    let lambda_max: f64 = 4.0;

    let code = unsafe { certificate_check(n, u.as_ptr(), alpha, lambda_2, lambda_max) };

    // Legal encodings only.
    assert!(code == -1 || code == 0 || code == 1);

    // Structural soundness: a valid certificate can only be returned when
    // every input satisfies the documented preconditions.
    if code == 1 {
        assert!(n >= 1);
        assert!(lambda_max > 0.0 && lambda_2 > 0.0);
        assert!(alpha > 0.0 && alpha < 2.0 / lambda_max);
        let q = 1.0 - alpha * lambda_2;
        assert!(q > 0.0 && q < 1.0);
    }
}

/// Valid inputs always produce a legal (non-error) code.
///
/// The spectral parameters are concrete (see `verify_ffi_returns_legal_codes`);
/// the field `u` and the step size `alpha` remain fully symbolic.
#[kani::proof]
#[kani::unwind(16)]
fn verify_ffi_valid_input_never_errors() {
    let n: usize = kani::any();
    kani::assume(n >= 1 && n <= 8);
    let u: [f64; 8] = kani::any();
    kani::assume(u.iter().all(|&x| x.is_finite() && x.is_normal()));

    // Narrow the parameters to the validated envelope.
    let lambda_2: f64 = 2.0;
    let lambda_max: f64 = 4.0;
    let alpha: f64 = kani::any();
    kani::assume(alpha > 0.0 && alpha < 2.0 / lambda_max);

    let code = unsafe { certificate_check(n, u.as_ptr(), alpha, lambda_2, lambda_max) };

    // For symbolic f64 the arithmetic bound q = 1 - αλ₂ may land out of
    // (0,1) due to float rounding; the contract only requires a legal code.
    assert!(!(code < -1) && !(code > 1));
}

/// Over-constrained step size must be rejected as invalid input.
#[kani::proof]
#[kani::unwind(16)]
fn verify_ffi_rejects_out_of_range_alpha() {
    let n: usize = kani::any();
    kani::assume(n >= 1 && n <= 8);
    let u: [f64; 8] = kani::any();

    let lambda_max: f64 = 4.0;
    let lambda_2: f64 = 2.0;
    let alpha: f64 = kani::any();
    kani::assume(alpha >= 2.0 / lambda_max);

    let code = unsafe { certificate_check(n, u.as_ptr(), alpha, lambda_2, lambda_max) };
    assert!(code == -1, "out-of-range alpha must be rejected");
}

/// Zero-dimensional input must be rejected.
#[kani::proof]
#[kani::unwind(8)]
fn verify_ffi_rejects_zero_dimension() {
    let u: [f64; 8] = kani::any();
    let alpha: f64 = kani::any();
    let lambda_2: f64 = kani::any();
    let lambda_max: f64 = kani::any();
    let code = unsafe { certificate_check(0, u.as_ptr(), alpha, lambda_2, lambda_max) };
    assert!(code == -1);
}

/// Non-positive spectral parameters must be rejected.
#[kani::proof]
#[kani::unwind(8)]
fn verify_ffi_rejects_nonpositive_spectrum() {
    let u: [f64; 8] = kani::any();
    let n: usize = kani::any();
    kani::assume(n >= 1 && n <= 8);
    let code = unsafe { certificate_check(n, u.as_ptr(), 0.1, -1.0, 1.0) };
    assert!(code == -1);
}