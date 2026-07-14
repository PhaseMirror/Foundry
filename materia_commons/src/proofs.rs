#[cfg(kani)]
mod verification {
    use crate::hamiltonian::*;
    use crate::spectral_bridge::*;
    use crate::generated_vals_array::VALS;

    const KAPPA: f64 = 0.1;
    const GAMMA: f64 = 0.5;
    const SIGMA: f64 = 2.0;

    #[kani::proof]
    fn verify_trace_identity() {
        let (h1, h2) = build_hamiltonians(KAPPA, GAMMA, SIGMA);
        let trace_formal = trace_delta_h(&h1, &h2);

        let mut trace_lean = 0.0;
        for i in 0..N_STATES {
            trace_lean += KAPPA * GAMMA * xi_simple(i, i);
        }

        // Kani checks the equality within floating tolerance
        assert!((trace_formal - trace_lean).abs() < 1e-9);
    }

    #[kani::proof]
    fn verify_diagonal_correlation_bound() {
        let mut delta_e = [0.0; N_STATES];
        for i in 0..N_STATES {
            delta_e[i] = diag_perturbation(KAPPA, GAMMA, SIGMA, i);
        }

        let rho = formal_correlation(&delta_e, KAPPA, GAMMA, SIGMA);
        // In the first-order limit, the correlation should be exactly 1.0.
        assert!(rho > 0.99);
    }

    #[kani::proof]
    fn verify_no_overflow_in_valuation() {
        let i: usize = kani::any();
        kani::assume(i < N_STATES);
        for k in 0..4 {
            let val = VALS[i][k];
            assert!(val <= 3); // since max_exp = 3
        }
    }

    #[kani::proof]
    fn verify_xi_simple_bounds() {
        let i: usize = kani::any();
        let j: usize = kani::any();
        kani::assume(i < N_STATES && j < N_STATES);
        let xi = xi_simple(i, j);
        assert!(xi >= 0.0);
        // Rough upper bound: sum of squares of min(alphas) ≤ 4 * (max_exp)^2
        assert!(xi <= 16.0 * 9.0);
    }

    /// Verify that the resolvent matrix (zI - H)^-1 is a true inverse
    /// for a concrete z value (e.g., z=1.0) within floating-point tolerance.
    #[kani::proof]
    fn verify_resolvent_inverse_z1() {
        use nalgebra::DMatrix;
        let (_, h2) = build_hamiltonians(KAPPA, GAMMA, SIGMA);
        let z = 1.0;
        let inv = crate::spectral_resolvent::resolvent_matrix(z, &h2);
        let n = h2.nrows();
        let mut product = (z * DMatrix::identity(n, n) - h2) * inv;
        
        // Assert that the product is close to the identity matrix
        for i in 0..n {
            for j in 0..n {
                let expected = if i == j { 1.0 } else { 0.0 };
                let diff = (product[(i, j)] - expected).abs();
                // Kani will check this for all states in the bounded domain
                assert!(diff < 1e-9);
            }
        }
    }

    // Optionally, we can also verify the trace for a specific z
    // without comparing to the expansion, just to ensure it's computed.
    #[kani::proof]
    fn verify_resolvent_trace_computed() {
        let (_, h2) = build_hamiltonians(KAPPA, GAMMA, SIGMA);
        let z = 1.0;
        let trace = crate::spectral_resolvent::resolvent_trace(z, &h2);
        // We don't compare to any analytic value; we just assert it's finite.
        assert!(trace.is_finite());
    }
}
