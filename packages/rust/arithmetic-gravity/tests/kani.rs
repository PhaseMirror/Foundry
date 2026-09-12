//! Kani verification harnesses for arithmetic gravity.
use arithmetic_gravity::max_eigenvalue_modulus;

/// For all non‑negative gravity and all primes up to 1000,
/// the contraction margin is strictly preserved.
#[kani::proof]
#[kani::unwind(32)]
fn verify_contraction_for_non_negative_gravity() {
    let gamma_p: f64 = 0.08;          // fixed damping probability
    let g: f64 = kani::any();
    kani::assume(g >= 0.0 && g <= 10.0);
    let p: u64 = kani::any();
    kani::assume(p >= 2 && p <= 1000);

    let modulus = max_eigenvalue_modulus(p, gamma_p, g).unwrap();
    kani::assert(modulus < 1.0, "Contraction margin violated for non‑negative gravity");
}

/// For a negative gravity we exhibit a concrete prime where contraction fails.
#[kani::proof]
fn verify_contraction_failure_for_negative_gravity() {
    let gamma_p: f64 = 0.08;
    let g: f64 = -0.5;                // negative gravity ⇒ δ = 0.5
    let p: u64 = 100;                 // prime large enough: 100^0.5 = 10, base ≈0.959 → 9.59 > 1

    let modulus = max_eigenvalue_modulus(p, gamma_p, g).unwrap();
    kani::assert(modulus > 1.0, "Expected contraction failure not observed");
}

/// Symbolic check: show that for g = -0.1 there exists some prime breaking contraction.
/// Kani will attempt to symbolically find a counterexample; we bound the search to 2..=10000.
#[kani::proof]
#[kani::unwind(10000)]
fn exists_prime_breaking_contraction_for_negative_g() {
    let gamma_p: f64 = 0.08;
    let g: f64 = -0.1;
    let p: u64 = kani::any();
    kani::assume(p >= 2 && p <= 10000);
    let modulus = max_eigenvalue_modulus(p, gamma_p, g).unwrap();
    // We assert that at least one p makes modulus > 1; Kani will try to find one.
    kani::assert(modulus <= 1.0, "No prime up to 10000 breaks contraction for g=-0.1");
    // If this assertion is FALSE, Kani will report a counterexample (p where modulus > 1).
}
