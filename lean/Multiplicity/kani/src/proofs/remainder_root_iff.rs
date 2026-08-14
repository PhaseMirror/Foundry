//! Mirror of `remainder_root_iff` (Multiplicity/PolynomialProofs.lean witness
//! `remainderRootIffWitness`): a root is exactly a zero remainder, over the
//! full `i64` domain.

use multiplicity_algebra::{poly_eval, synthetic_division};

#[kani::proof]
fn remainder_root_iff() {
    let a: i64 = kani::any();
    let b: i64 = kani::any();
    let c: i64 = kani::any();
    let r: i64 = kani::any();
    let (_, rem) = synthetic_division(&[a, b, c], r);
    assert_eq!(rem == 0, poly_eval(&[a, b, c], r) == 0);
}
