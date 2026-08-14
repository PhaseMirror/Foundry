//! Mirror of `valuation_pow_self` (Multiplicity/NumberTheory.lean witness
//! `valuationPowSelfWitness`): `valuation p (p ^ k) = k` for `p ≥ 2`, on a
//! bounded domain where the power fits in `u64`.

use multiplicity_primes::valuation;

#[kani::proof]
#[kani::unwind(16)]
fn valuation_pow_self() {
    let p: u64 = kani::any();
    let k: u64 = kani::any();
    kani::assume(p >= 2 && p < 32 && k < 6);
    if let Some(pk) = p.checked_pow(k as u32) {
        assert_eq!(valuation(p, pk), k);
    }
}
