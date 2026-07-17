//! Kani verification harnesses for PARM sealed state.
//!
//! These proofs are run with `cargo kani -p parm --harness <name>`.
//! They verify determinism, overflow safety, and 108-cycle anchor preservation.

use crate::{ParmEngine, ParmError, ParmSealWitness};

mod verification {
    use crate::{ParmEngine, ParmError};

    /// Proof: same input always returns same output.
    #[kani::proof]
    fn proof_deterministic() {
        let engine = ParmEngine;
        let p1: u64 = kani::any();
        let p2: u64 = kani::any();
        let p3: u64 = kani::any();

        let res1 = engine.sealed_state(&[p1, p2, p3]);
        let res2 = engine.sealed_state(&[p1, p2, p3]);

        match (res1, res2) {
            (Ok(v1), Ok(v2)) => kani::assert(v1 == v2, "Deterministic"),
            (Err(_), Err(_)) => kani::assert(true, "Deterministic error"),
            _ => kani::assert(false, "Non-deterministic"),
        }
    }

    /// Proof: no overflow for small bounded inputs.
    #[kani::proof]
    fn proof_no_overflow_small_inputs() {
        let engine = ParmEngine;
        let p1: u64 = kani::any();
        let p2: u64 = kani::any();
        kani::assume(p1 < 1000 && p2 < 1000);
        let res = engine.sealed_state(&[p1, p2]);
        kani::assert(res.is_ok(), "No overflow for small inputs");
    }

    /// Proof: 108-cycle anchor is preserved.
    #[kani::proof]
    fn proof_108_cycle_anchor() {
        let engine = ParmEngine;
        let res = engine.sealed_state(&[3, 3, 3, 2, 2]);
        match res {
            Ok(v) => kani::assert(v == 960, "108-cycle anchor must be 960"),
            Err(_) => kani::assert(false, "108-cycle should not overflow"),
        }
    }

    /// Proof: empty input returns EmptyInput error.
    #[kani::proof]
    fn proof_empty_input_error() {
        let engine = ParmEngine;
        let res = engine.sealed_state(&[]);
        match res {
            Err(ParmError::EmptyInput) => kani::assert(true, "Empty input rejected"),
            _ => kani::assert(false, "Empty input should return EmptyInput"),
        }
    }

    /// Proof: singleton seal is p^2.
    #[kani::proof]
    fn proof_singleton_square() {
        let engine = ParmEngine;
        let p: u64 = kani::any();
        kani::assume(p < 10000);
        let res = engine.sealed_state(&[p]);
        match res {
            Ok(v) => kani::assert(v == p * p, "Singleton must be p^2"),
            Err(_) => kani::assert(false, "Singleton should not overflow for p < 10000"),
        }
    }

    /// Proof: witness is deterministic for same input.
    #[kani::proof]
    fn proof_witness_deterministic() {
        let engine = ParmEngine;
        let p1: u64 = kani::any();
        let p2: u64 = kani::any();
        kani::assume(p1 < 1000 && p2 < 1000);

        let (_, w1) = engine.seal_with_witness(&[p1, p2]).unwrap();
        let (_, w2) = engine.seal_with_witness(&[p1, p2]).unwrap();

        kani::assert(w1.input_hash == w2.input_hash, "Witness hash must be deterministic");
        kani::assert(w1.sealed_value == w2.sealed_value, "Witness value must be deterministic");
    }
}
