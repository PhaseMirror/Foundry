//! Mirror of `gcd_mul_lcm` (Multiplicity/NumberTheory.lean witness
//! `gcdMulLcmWitness`): `gcd a b * lcm a b = a * b`, on a bounded domain so
//! the saturating `lcm` cannot overflow (the Lean statement is in unbounded
//! `Nat`).

use multiplicity_algebra::gcd_lcm;

#[kani::proof]
fn gcd_mul_lcm() {
    let a: u64 = kani::any();
    let b: u64 = kani::any();
    kani::assume(a < 1024 && b < 1024);
    let (g, l) = gcd_lcm(a, b);
    assert_eq!(g.wrapping_mul(l), a.wrapping_mul(b));
}
