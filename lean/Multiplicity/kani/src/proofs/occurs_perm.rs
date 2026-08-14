//! Mirror of `occurs_perm` (Multiplicity/NumberTheory.lean witness
//! `occursPermWitness`): occurrences are invariant under the swap
//! permutation `[x, y] ↔ [y, x]`.

use multiplicity_core::occurs;

#[kani::proof]
fn occurs_perm() {
    let a: u64 = kani::any();
    let x: u64 = kani::any();
    let y: u64 = kani::any();
    assert_eq!(occurs(a, &[x, y]), occurs(a, &[y, x]));
}
