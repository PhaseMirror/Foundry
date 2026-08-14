//! Mirror of `occurs_append` (Multiplicity/NumberTheory.lean witness
//! `occursAppendWitness`): occurrences are additive under concatenation,
//! over symbolic 4-element lists.

use multiplicity_core::occurs;

#[kani::proof]
fn occurs_append() {
    let a: u64 = kani::any();
    let l: [u64; 4] = kani::any();
    let m: [u64; 4] = kani::any();
    let mut u = Vec::new();
    u.extend_from_slice(&l);
    u.extend_from_slice(&m);
    assert_eq!(occurs(a, &u), occurs(a, &l) + occurs(a, &m));
}
