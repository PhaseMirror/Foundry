//! Mirror of `quotientRemainder_remainder` (Multiplicity/PolynomialProofs.lean
//! witness `remainderTheoremWitness`): the remainder of dividing `cs` by
//! `x - r` is the evaluation of `cs` at `r`, over the full `i64` domain.

use multiplicity_algebra::{poly_eval, synthetic_division};

#[kani::proof]
fn remainder_theorem() {
    let a: i64 = kani::any();
    let b: i64 = kani::any();
    let c: i64 = kani::any();
    let r: i64 = kani::any();
    let (_, rem) = synthetic_division(&[a, b, c], r);
    assert_eq!(rem, poly_eval(&[a, b, c], r));
}
