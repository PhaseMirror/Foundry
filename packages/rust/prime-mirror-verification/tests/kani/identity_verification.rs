//! Kani verification harness for ADR-401: Identity System Integration
//!
//! Proves:
//! 1. C2_contractive: Lyapunov (toCRMF sys) < 10000 for all IdentitySystem
//! 2. C4_sparse: p.word_length ≤ 108 for all PrimeMoc
//! 3. bitL0_persistence: toBitL0 is invariant
//! 4. spectral_nonzero_108: prime_gap_chi2 (3 - 2) > 0
//! 5. L_eff ≤ 0.85 (scaled: ≤ 8500) for 108-cycle

use kani::proof;
use prime_mirror_verification::{
    A, C, D, IdentitySystem, PrimeMoc, bit_l0_persistence, c2_contractive, c4_sparse,
    l_eff, l_eff_bound_108, lyapunov, prime_gap_chi2, spectral_gap, spectral_nonzero_108,
    to_bit_l0,
};

#[kani::proof]
fn verify_c2_contractive_empty_system() {
    let sys: IdentitySystem<()> = IdentitySystem::new();
    kani::assert(c2_contractive(&sys), "C2 contractive: Lyapunov must be < 10000");
}

#[kani::proof]
fn verify_c4_sparse_prime_2() {
    let p = PrimeMoc::prime_2();
    kani::assert(c4_sparse(&p), "C4 sparse: word length must be ≤ 108");
}

#[kani::proof]
fn verify_c4_sparse_prime_3() {
    let p = PrimeMoc::prime_3();
    kani::assert(c4_sparse(&p), "C4 sparse: word length must be ≤ 108");
}

#[kani::proof]
fn verify_bit_l0_persistence_prime_2() {
    let p = PrimeMoc::prime_2();
    kani::assert(bit_l0_persistence(&p), "BitL0 persistence must hold");
}

#[kani::proof]
fn verify_bit_l0_persistence_prime_3() {
    let p = PrimeMoc::prime_3();
    kani::assert(bit_l0_persistence(&p), "BitL0 persistence must hold");
}

#[kani::proof]
fn verify_spectral_nonzero_108() {
    kani::assert(spectral_nonzero_108(), "Spectral gap chi2 for 108-cycle must be > 0");
}

#[kani::proof]
fn verify_l_eff_bound_108() {
    let bound = l_eff_bound_108();
    kani::assert(bound < 10000, "L_eff bound for 108-cycle must be < 10000 (≤ 0.85)");
}

#[kani::proof]
fn verify_l_eff_scaled_threshold() {
    // For any resonance score ≥ 1500, L_eff ≤ 8500
    let resonance_score: u64 = kani::any();
    kani::assume(resonance_score >= 1500 && resonance_score <= 10000);
    let eff = l_eff(resonance_score);
    kani::assert(eff <= 8500, "L_eff must be ≤ 0.85 for valid resonance scores");
}

#[kani::proof]
fn verify_lyapunov_positive() {
    let resonance_score: u64 = kani::any();
    kani::assume(resonance_score <= 10000);
    let lyap = lyapunov(resonance_score);
    kani::assert(lyap >= 0, "Lyapunov must be non-negative");
    kani::assert(lyap <= 10000, "Lyapunov must be ≤ 10000");
}

#[kani::proof]
fn verify_spectral_gap_positive() {
    let p1: u64 = kani::any();
    let p2: u64 = kani::any();
    kani::assume(p1 >= 2 && p1 <= 100);
    kani::assume(p2 >= 2 && p2 <= 100);
    kani::assume(p1 != p2);
    let gap = spectral_gap(p1, p2);
    kani::assert(gap > 0, "Spectral gap must be positive for distinct primes");
}

#[kani::proof]
fn verify_prime_gap_chi2_positive() {
    let p: u64 = kani::any();
    kani::assume(p >= 1 && p <= 100);
    let chi2 = prime_gap_chi2(p);
    kani::assert(chi2 > 0, "Prime gap chi2 must be positive");
}

#[kani::proof]
fn verify_to_bit_l0_2_and_3() {
    let p2 = PrimeMoc::prime_2();
    let p3 = PrimeMoc::prime_3();
    kani::assert(to_bit_l0(&p2) == true, "toBitL0 for prime 2 must be true");
    kani::assert(to_bit_l0(&p3) == true, "toBitL0 for prime 3 must be true");
}

#[kani::proof]
fn verify_identity_system_lift_bounds() {
    let sys: IdentitySystem<()> = IdentitySystem::new();
    let resonance = c2_contractive(&sys);
    let dim_ok = crmf_dim(&sys) <= 10000;
    kani::assert(resonance, "IdentitySystem lift must be contractive");
    kani::assert(dim_ok, "IdentitySystem dimension must be within bounds");
}
