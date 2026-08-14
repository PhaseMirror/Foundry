//! Mirror of `rootMultiplicity_le_degree` (Multiplicity/PolynomialProofs.lean
//! witness `rootMultiplicityLeDegreeWitness`): the multiplicity of a root
//! never exceeds the polynomial degree.

use multiplicity_algebra::root_multiplicity;

#[kani::proof]
#[kani::unwind(16)]
fn root_multiplicity_le_degree() {
    let a: i64 = kani::any();
    let b: i64 = kani::any();
    let c: i64 = kani::any();
    let r: i64 = kani::any();
    let cs = [a, b, c];
    assert!(root_multiplicity(&cs, r) <= cs.len());
}
