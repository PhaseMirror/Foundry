//! Mirror of `theoremOf` (Multiplicity/Kernel.lean): a theorem obligation is
//! accepted exactly when its Boolean statement holds.

use multiplicity_core::theorem;

#[kani::proof]
fn theorem_of() {
    let statement: bool = kani::any();
    assert_eq!(theorem(statement), statement);
}
