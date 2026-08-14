//! Mirror of `valuation_mul_pow` (Multiplicity/NumberTheory.lean witness
//! `valuationMulPowWitness`): `valuation p (p ^ a * p ^ b) = a + b` for
//! `p ≥ 2`, on a bounded domain where the product fits in `u64`.

use multiplicity_primes::valuation;

#[kani::proof]
#[kani::unwind(16)]
fn valuation_mul_pow() {
    let p: u64 = kani::any();
    let a: u64 = kani::any();
    let b: u64 = kani::any();
    kani::assume(p >= 2 && p < 32 && a < 6 && b < 6);
    if let (Some(pa), Some(pb)) = (p.checked_pow(a as u32), p.checked_pow(b as u32)) {
        if let Some(prod) = pa.checked_mul(pb) {
            assert_eq!(valuation(p, prod), a + b);
        }
    }
}
