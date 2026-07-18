#[cfg(kani)]
mod langlands_circuit_proof {
    use pirtm_rs::langlands_zk::{GoldilocksField, compute_euler_product};
    use std::collections::HashMap;

    // The constant matrices (filled by extraction script)
    // We import them from the generated module via the crate.
    use pirtm_rs::r1cs_constants::{A, B, C, NUM_WIRES, NUM_CONSTRAINTS};

    const MAX_PRIMES: usize = 16;

    // Wire indices (0‑based, corresponding to 1‑based circuit wires)
    const WIRE_CONSTANT_1: usize = 0;   // wire 1
    const WIRE_CLASS_ID: usize = 1;     // wire 2 (public)
    const WIRE_PRIMES_BASE: usize = 2;  // wires 3..18 (public)
    const WIRE_CLAIMED_L: usize = 18;   // wire 19 (public)
    const WIRE_SCALE: usize = 19;       // wire 20 (public)
    const WIRE_TRACE_BASE: usize = 20;  // wires 21..36 (private)
    const WIRE_DET_BASE: usize = 36;    // wires 37..52 (private)

    /// Check if a given witness satisfies all R1CS constraints.
    fn satisfies_all_constraints(w: &[GoldilocksField; NUM_WIRES]) -> bool {
        for i in 0..NUM_CONSTRAINTS {
            let mut lhs_a = GoldilocksField::zero();
            let mut lhs_b = GoldilocksField::zero();
            let mut rhs = GoldilocksField::zero();
            for j in 0..NUM_WIRES {
                lhs_a = lhs_a + (A[i][j] * w[j]);
                lhs_b = lhs_b + (B[i][j] * w[j]);
                rhs = rhs + (C[i][j] * w[j]);
            }
            if lhs_a * lhs_b != rhs {
                return false;
            }
        }
        true
    }

    #[kani::proof]
    fn verify_langlands_circuit() {
        // Symbolic witness
        let mut w = [GoldilocksField(0); NUM_WIRES];
        for i in 0..NUM_WIRES {
            w[i] = GoldilocksField(kani::any::<u64>());
        }
        // Constrain constant wire
        kani::assume(w[WIRE_CONSTANT_1] == GoldilocksField(1));

        // Constrain witness to satisfy all R1CS constraints
        kani::assume(satisfies_all_constraints(&w));

        // Extract public input: the claimed L‑value
        let claimed_l = w[WIRE_CLAIMED_L];

        // Extract primes, traces, and determinants
        let mut primes = [0u64; MAX_PRIMES];
        let mut traces = HashMap::new();
        let mut dets = HashMap::new();

        for i in 0..MAX_PRIMES {
            // Note: in a real symbolic execution we might extract the integer value
            // of the field element. For this test we assume w contains the u64 values.
            let p_val = w[WIRE_PRIMES_BASE + i].0;
            primes[i] = p_val;
            traces.insert(p_val, w[WIRE_TRACE_BASE + i]);
            dets.insert(p_val, w[WIRE_DET_BASE + i]);
        }

        // Compute the Euler product from the private data
        let s: u64 = 1; // exponent, must match public input
        let expected_l = compute_euler_product(&primes, s, &traces, &dets);

        // The theorem: the circuit enforces that claimed_l equals the computed product
        assert_eq!(claimed_l, expected_l);
    }
}
