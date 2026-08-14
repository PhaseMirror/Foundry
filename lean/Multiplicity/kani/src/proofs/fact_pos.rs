//! Mirror of `natFact_pos` (Multiplicity/NumberTheory.lean witness
//! `factorialPosWitness`): `n!` is positive for every `n` (bounded domain).

use multiplicity_core::factorial;

#[kani::proof]
#[kani::unwind(64)]
fn fact_pos() {
    let n: u64 = kani::any();
    kani::assume(n < 64);
    assert!(factorial(n) >= 1);
}
