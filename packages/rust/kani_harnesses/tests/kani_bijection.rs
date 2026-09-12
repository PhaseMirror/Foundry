//! ADR-231 harness: the Ethical–Spectral map Φ is injective on the first 32
//! non-trivial zeta zeros.
//!
//! The Lean axiom `finite_bijection_certified` in
//! `RH_Multiplicity/KaniCertificates.lean` is imported from the certificate
//! produced by this harness.

use kani_harnesses::ideal_id;
use kani_harnesses::rank_of;
use kani_harnesses::ZEROS_SCALED;

/// Exhaustively verifies injectivity of the ideal model `Φ(z) = rank of z` on
/// the table of the first 32 scaled zeros: the table is strictly ascending
/// and no two entries share an ideal.
#[cfg(kani)]
#[kani::proof]
fn verify_bijection_small_zeros() {
    let i: u64 = kani::any();
    let j: u64 = kani::any();
    kani::assume(i < 32 && j < 32 && i < j);

    let zi: u64 = ZEROS_SCALED[i as usize];
    let zj: u64 = ZEROS_SCALED[j as usize];
    // The table is strictly ascending, hence ranks are distinct.
    kani::assert(zi < zj, "zero table is strictly ascending");
    // Φ is injective: distinct zeros map to distinct ideals.
    kani::assert(ideal_id(zi) != ideal_id(zj), "Phi injective on certified zeros");
}

/// Structural consistency check: `rank_of` counts exactly the entries
/// strictly below the queried zero, so `Φ(z_i) = i` on the certified range.
#[cfg(kani)]
#[kani::proof]
fn verify_rank_consistent() {
    let i: usize = kani::any();
    kani::assume(i < 32);
    kani::assert(rank_of(&ZEROS_SCALED, ZEROS_SCALED[i]) == i as u64, "rank equals index");
}
