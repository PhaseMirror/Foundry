//! ADR-231 harness: isolation measure decays below `10⁻³` for all primes
//! `p ≤ P_max = 10000`.
//!
//! The Lean axiom `finite_coherence_certified` in
//! `RH_Multiplicity/KaniCertificates.lean` is imported from the certificate
//! produced by this harness.

use kani_harnesses::compute_rho_lambda;
use kani_harnesses::is_prime;

/// Exhaustively verifies that `ρ_Λ(p, t_max) * 10⁶ = 1000 / p ≤ 1000` for
/// every prime `p` in `2..=10000`, i.e. `ρ_Λ(p, t_max) ≤ 10⁻³` on the
/// certified range.  `t_max = 100.0` is the measurement horizon.
#[cfg(kani)]
#[kani::proof]
fn verify_coherence_finite_primes() {
    let p: u64 = kani::any();
    kani::assume(p >= 2 && p <= 10000);

    if is_prime(p) {
        let rho_scaled = compute_rho_lambda(p, 100.0);
        // Assert rho_Lambda < 0.001 (scaled by 1,000,000 -> <= 1000)
        kani::assert(rho_scaled <= 1000, "isolation measure below 1e-3");
    }
}
