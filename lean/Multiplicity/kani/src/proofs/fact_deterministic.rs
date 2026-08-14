//! Mirror of `natFact_deterministic` (Multiplicity/NumberTheory.lean witness
//! `factorialDeterministicWitness`): evaluating the factorial twice on the
//! same input yields the same output.

use multiplicity_core::factorial;

#[kani::proof]
#[kani::unwind(64)]
fn fact_deterministic() {
    let n: u64 = kani::any();
    kani::assume(n < 64);
    assert_eq!(factorial(n), factorial(n));
}
