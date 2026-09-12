//! ADR-231 harness: trace coefficients of the Zeta–Multiplicity transform are
//! bounded by `0 ≤ Tr(Π_n T) < 1` for `1 ≤ n ≤ N_max = 500`.
//!
//! The Lean axiom `finite_trace_bounds_certified` in
//! `RH_Multiplicity/KaniCertificates.lean` is imported from the certificate
//! produced by this harness.

use kani_harnesses::{compute_exact_trace_projection, ExactRational};

/// Exhaustively verifies that the exact rational trace projection
/// Tr(Π_n T) = a_n^2 / (n^3 * 108) satisfies 0 <= Tr(Π_n T) < 1
/// for all n in 1..=500 and all Deligne-bounded Fourier coefficients a_n^2 <= 4 * n^3.
#[cfg(kani)]
#[kani::proof]
#[kani::unwind(10)]
fn verify_trace_bounds() {
    let n: u64 = kani::any();
    let a_n: i64 = kani::any();

    kani::assume(n >= 1 && n <= 500);
    // Bounded by Deligne inequality: a_n^2 <= 4 * n^3
    let a_sq = (a_n.abs() as u64).saturating_mul(a_n.abs() as u64);
    let deligne_bound = 4u64.saturating_mul(n.saturating_pow(3));
    kani::assume(a_sq <= deligne_bound);

    let proj = compute_exact_trace_projection(n, a_n);

    // Non-negativity assertion
    kani::assert(proj.ge(&ExactRational::ZERO), "trace non-negative");

    // Strict contractivity bound assertion (< 1)
    kani::assert(proj.lt(&ExactRational::ONE), "trace strictly below one");

    // Sharp analytical ceiling (<= 1/27 since a_n^2 <= 4*n^3 implies a_n^2/(108*n^3) <= 4/108 = 1/27)
    let sharp_bound = ExactRational::new(1, 27);
    kani::assert(proj.le(&sharp_bound), "trace bounded by 1/27");
}

