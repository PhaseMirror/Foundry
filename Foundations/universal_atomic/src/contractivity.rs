//! Contractivity helper for the Universal Atomic Calculator (UAC)
//!
//! Provides an exact rational scaling equality used in the Banach‑type
//! contraction proof. The implementation mirrors the Lean core theorem
//! `scalar_contractivity_bound_rat`.

use num_rational::Ratio;

/// Returns the scalar contractivity equality `(γ / (S + η)) * (S + η) = γ`.
///
/// Panics if `S + η == 0` – this corresponds to the `h_nonzero` hypothesis
/// required by the mathematical specification.
pub fn scalar_contractivity_bound_rat(gamma: Ratio<i64>, s: Ratio<i64>, eta: Ratio<i64>) -> Ratio<i64> {
    let denom = s + eta;
    assert!(denom != Ratio::from_integer(0), "Denominator must be non‑zero");
    (gamma / denom) * denom
}
