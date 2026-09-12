#[cfg(kani)]
mod verification {
    use kani::proof;

    // ---------------------------------------------------------------------------
    // Kernel: Prime-Encoded Operator (PEQOMA)
    // ---------------------------------------------------------------------------

    /// Prime-encoded operator: Â_p(i,j) = p(k) · Â(i,j)
    fn prime_encoded_action(base_op: &[[f64; 3]; 3], prime_val: f64, i: usize, j: usize) -> f64 {
        prime_val * base_op[i][j]
    }

    /// Matrix-vector product: (M·v)_i = Σ_j M_{ij} · v_j
    fn mat_vec_mul(m: &[[f64; 3]; 3], v: &[f64; 3]) -> [f64; 3] {
        let mut result = [0.0f64; 3];
        for i in 0..3 {
            let mut sum = 0.0;
            for j in 0..3 {
                sum += m[i][j] * v[j];
            }
            result[i] = sum;
        }
        result
    }

    // ---------------------------------------------------------------------------
    // Kernel: Multiplicity Processor
    // ---------------------------------------------------------------------------

    /// Compute multiplicity pair: λ_i · λ_j · C_{kij}
    fn multiplicity_pair(eigenvalues: &[f64; 2], coupling: f64, i: usize, j: usize) -> f64 {
        eigenvalues[i] * eigenvalues[j] * coupling
    }

    /// Evolve eigenvalue with feedback: λ_new = λ + η · ∂L/∂λ
    fn evolve_eigenvalue(eigenval: f64, learning_rate: f64, gradient: f64) -> f64 {
        eigenval + learning_rate * gradient
    }

    // ---------------------------------------------------------------------------
    // Proof 1: Eigenvalue scaling for diagonal operators
    // For a diagonal base operator Â, prime encoding scales each diagonal entry:
    //   Â_p(i,i) = p(k) · Â(i,i)
    // This is the core PEQOMA invariant: Â_p|ψ_i⟩ = p(k) · λ_i |ψ_i⟩
    // ---------------------------------------------------------------------------
    #[proof]
    #[kani::unwind(3)]
    fn proof_eigenvalue_scaling_diagonal() {
        let base_diag: [f64; 3] = kani::any();
        let prime_val: f64 = kani::any();

        // Bound inputs to avoid overflow / NaN
        kani::assume(base_diag[0].is_finite() && base_diag[0].abs() < 1e6);
        kani::assume(base_diag[1].is_finite() && base_diag[1].abs() < 1e6);
        kani::assume(base_diag[2].is_finite() && base_diag[2].abs() < 1e6);
        kani::assume(prime_val.is_finite() && prime_val.abs() < 1e6);

        // Build diagonal base operator
        let base_op = [
            [base_diag[0], 0.0, 0.0],
            [0.0, base_diag[1], 0.0],
            [0.0, 0.0, base_diag[2]],
        ];

        // Prime-encoded action on diagonal = prime_val · base_diag[i]
        for i in 0..3 {
            let encoded = prime_encoded_action(&base_op, prime_val, i, i);
            let expected = prime_val * base_diag[i];
            assert!(
                (encoded - expected).abs() < 1e-10,
                "Eigenvalue scaling: Â_p(i,i) must equal p(k) · Â(i,i)"
            );
        }
    }

    // ---------------------------------------------------------------------------
    // Proof 2: Prime-encoded matrix-vector product = prime · (base · v)
    // For any base operator, vector, and prime value:
    //   (Â_p · v)_i = p(k) · (Â · v)_i
    // ---------------------------------------------------------------------------
    #[proof]
    #[kani::unwind(3)]
    fn proof_prime_encoded_mat_vec_scaling() {
        let base_op: [[f64; 3]; 3] = kani::any();
        let v: [f64; 3] = kani::any();
        let prime_val: f64 = kani::any();

        // Bound all entries
        for i in 0..3 {
            for j in 0..3 {
                kani::assume(base_op[i][j].is_finite() && base_op[i][j].abs() < 1e4);
            }
            kani::assume(v[i].is_finite() && v[i].abs() < 1e4);
        }
        kani::assume(prime_val.is_finite() && prime_val.abs() < 1e4);

        // Build prime-encoded operator: Â_p(i,j) = prime_val · base_op(i,j)
        let encoded_op = [
            [
                prime_val * base_op[0][0],
                prime_val * base_op[0][1],
                prime_val * base_op[0][2],
            ],
            [
                prime_val * base_op[1][0],
                prime_val * base_op[1][1],
                prime_val * base_op[1][2],
            ],
            [
                prime_val * base_op[2][0],
                prime_val * base_op[2][1],
                prime_val * base_op[2][2],
            ],
        ];

        let result_encoded = mat_vec_mul(&encoded_op, &v);
        let result_base = mat_vec_mul(&base_op, &v);

        for i in 0..3 {
            let expected = prime_val * result_base[i];
            assert!(
                (result_encoded[i] - expected).abs() < 1e-6,
                "Mat-vec scaling: (Â_p · v)_i must equal p(k) · (Â · v)_i"
            );
        }
    }

    // ---------------------------------------------------------------------------
    // Proof 3: Zero learning rate → eigenvalues unchanged
    // The processor feedback step with η=0 is the identity:
    //   λ_new = λ + 0 · ∂L/∂λ = λ
    // ---------------------------------------------------------------------------
    #[proof]
    fn proof_processor_zero_lr_identity() {
        let eigenval: f64 = kani::any();
        let gradient: f64 = kani::any();

        kani::assume(eigenval.is_finite() && eigenval.abs() < 1e8);
        kani::assume(gradient.is_finite() && gradient.abs() < 1e8);

        let evolved = evolve_eigenvalue(eigenval, 0.0, gradient);

        assert!(
            (evolved - eigenval).abs() < 1e-10,
            "Zero learning rate must leave eigenvalue unchanged"
        );
    }

    // ---------------------------------------------------------------------------
    // Proof 4: Multiplicity pair symmetry under coupling symmetry
    // If C_{kij} = C_{kji}, then M_{k,ij} = M_{k,ji}
    // ---------------------------------------------------------------------------
    #[proof]
    fn proof_multiplicity_pair_symmetry() {
        let eigenvalues: [f64; 2] = kani::any();
        let coupling_val: f64 = kani::any();

        kani::assume(eigenvalues[0].is_finite() && eigenvalues[0].abs() < 1e4);
        kani::assume(eigenvalues[1].is_finite() && eigenvalues[1].abs() < 1e4);
        kani::assume(coupling_val.is_finite() && coupling_val.abs() < 1e4);

        // With symmetric coupling (C_{kij} = C_{kji} = coupling_val),
        // M_{k,ij} = λ_i · λ_j · C and M_{k,ji} = λ_j · λ_i · C
        // These are equal by commutativity of multiplication.
        let pair_01 = multiplicity_pair(&eigenvalues, coupling_val, 0, 1);
        let pair_10 = multiplicity_pair(&eigenvalues, coupling_val, 1, 0);

        assert!(
            (pair_01 - pair_10).abs() < 1e-10,
            "Multiplicity pair must be symmetric under symmetric coupling"
        );
    }

    // ---------------------------------------------------------------------------
    // Proof 5: Well-definedness — all outputs are finite for bounded inputs
    // ---------------------------------------------------------------------------
    #[proof]
    #[kani::unwind(3)]
    fn proof_peqoma_output_finite() {
        let base_op: [[f64; 3]; 3] = kani::any();
        let prime_val: f64 = kani::any();
        let v: [f64; 3] = kani::any();

        // Bound all inputs
        for i in 0..3 {
            for j in 0..3 {
                kani::assume(base_op[i][j].is_finite() && base_op[i][j].abs() < 1e4);
            }
            kani::assume(v[i].is_finite() && v[i].abs() < 1e4);
        }
        kani::assume(prime_val.is_finite() && prime_val.abs() < 1e4);

        // Build prime-encoded operator and compute action
        let encoded_op = [
            [
                prime_val * base_op[0][0],
                prime_val * base_op[0][1],
                prime_val * base_op[0][2],
            ],
            [
                prime_val * base_op[1][0],
                prime_val * base_op[1][1],
                prime_val * base_op[1][2],
            ],
            [
                prime_val * base_op[2][0],
                prime_val * base_op[2][1],
                prime_val * base_op[2][2],
            ],
        ];

        let result = mat_vec_mul(&encoded_op, &v);

        for i in 0..3 {
            assert!(
                result[i].is_finite(),
                "PEQOMA output must be finite for bounded inputs"
            );
        }
    }

    // ---------------------------------------------------------------------------
    // Proof 6: Processor output finiteness
    // For bounded eigenvalues and coupling, multiplicity pair is finite
    // ---------------------------------------------------------------------------
    #[proof]
    fn proof_processor_output_finite() {
        let eigenvalues: [f64; 2] = kani::any();
        let coupling_val: f64 = kani::any();

        kani::assume(eigenvalues[0].is_finite() && eigenvalues[0].abs() < 1e4);
        kani::assume(eigenvalues[1].is_finite() && eigenvalues[1].abs() < 1e4);
        kani::assume(coupling_val.is_finite() && coupling_val.abs() < 1e4);

        for i in 0..2 {
            for j in 0..2 {
                let result = multiplicity_pair(&eigenvalues, coupling_val, i, j);
                assert!(
                    result.is_finite(),
                    "Processor multiplicity pair must be finite"
                );
            }
        }
    }

    // ---------------------------------------------------------------------------
    // Proof 7: Prime-encoded zero base → zero output
    // If Â = 0, then Â_p = p(k) · 0 = 0 for all primes
    // ---------------------------------------------------------------------------
    #[proof]
    #[kani::unwind(3)]
    fn proof_prime_encoded_zero_base() {
        let prime_val: f64 = kani::any();
        let v: [f64; 3] = kani::any();

        kani::assume(prime_val.is_finite() && prime_val.abs() < 1e4);
        kani::assume(v[0].is_finite() && v[0].abs() < 1e4);
        kani::assume(v[1].is_finite() && v[1].abs() < 1e4);
        kani::assume(v[2].is_finite() && v[2].abs() < 1e4);

        let zero_op = [[0.0f64; 3]; 3];
        let encoded_op = [
            [
                prime_val * zero_op[0][0],
                prime_val * zero_op[0][1],
                prime_val * zero_op[0][2],
            ],
            [
                prime_val * zero_op[1][0],
                prime_val * zero_op[1][1],
                prime_val * zero_op[1][2],
            ],
            [
                prime_val * zero_op[2][0],
                prime_val * zero_op[2][1],
                prime_val * zero_op[2][2],
            ],
        ];

        let result = mat_vec_mul(&encoded_op, &v);

        for i in 0..3 {
            assert!(
                result[i].abs() < 1e-10,
                "Zero base operator must produce zero output regardless of prime"
            );
        }
    }
}
