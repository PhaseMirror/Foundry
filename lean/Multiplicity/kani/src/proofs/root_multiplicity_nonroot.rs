//! Mirror of `rootMultiplicity_of_not_root` (Multiplicity/PolynomialProofs.lean
//! witness `rootMultiplicityOfNotRootWitness`): a non-root has multiplicity
//! zero.

use multiplicity_algebra::{poly_eval, root_multiplicity};

#[kani::proof]
#[kani::unwind(16)]
fn root_multiplicity_nonroot() {
    let a: i64 = kani::any();
    let b: i64 = kani::any();
    let c: i64 = kani::any();
    let r: i64 = kani::any();
    let cs = [a, b, c];
    if poly_eval(&cs, r) != 0 {
        assert_eq!(root_multiplicity(&cs, r), 0);
    }
}
