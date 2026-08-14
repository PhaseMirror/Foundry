//! Mirror of `polyEval_deterministic` (Multiplicity/PolynomialProofs.lean
//! witness `polyEvalDeterministicWitness`): Horner evaluation is
//! deterministic, over a symbolic 4-coefficient polynomial.

use multiplicity_algebra::poly_eval;

#[kani::proof]
fn poly_eval_deterministic() {
    let cs: [i64; 4] = kani::any();
    let x: i64 = kani::any();
    assert_eq!(poly_eval(&cs, x), poly_eval(&cs, x));
}
