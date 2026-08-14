#[cfg(kani)]
mod schur_test_proof {
    // We demonstrate the van Gelder-Schur test for a small matrix computationally.
    // The Schur test states: if T is a non-negative matrix, v is a positive vector,
    // and T v <= \kappa v with \kappa < 1, then the spectral radius of T is <= \kappa.
    // We prove this by showing that the v-weighted max norm ||x||_v contracts by \kappa.

    const N: usize = 4;

    fn weighted_max_norm(x: &[f64; N], v: &[f64; N]) -> f64 {
        let mut max_val = 0.0_f64;
        for i in 0..N {
            let val = x[i].abs() / v[i];
            if val > max_val {
                max_val = val;
            }
        }
        max_val
    }

    #[kani::proof]
    fn verify_schur_weighted_norm_contraction() {
        // We use symbolic values, but since f64 can be tricky with infinities/NaNs,
        // we constrain them to reasonable finite ranges.
        let mut t = [[0.0_f64; N]; N];
        let mut v = [0.0_f64; N];
        let mut x = [0.0_f64; N];
        let kappa: f64 = kani::any();

        kani::assume(kappa > 0.0 && kappa < 1.0);

        for i in 0..N {
            v[i] = kani::any();
            kani::assume(v[i] > 0.1 && v[i] < 10.0); // positive vector v

            x[i] = kani::any();
            kani::assume(x[i] > -10.0 && x[i] < 10.0);

            for j in 0..N {
                t[i][j] = kani::any();
                kani::assume(t[i][j] >= 0.0 && t[i][j] < 10.0); // non-negative matrix
            }
        }

        // Assume the Schur condition: (T v)_i <= kappa * v_i
        for i in 0..N {
            let mut row_sum = 0.0;
            for j in 0..N {
                row_sum += t[i][j] * v[j];
            }
            kani::assume(row_sum <= kappa * v[i]);
        }

        // Calculate Tx
        let mut tx = [0.0_f64; N];
        for i in 0..N {
            let mut row_sum = 0.0;
            for j in 0..N {
                row_sum += t[i][j] * x[j];
            }
            tx[i] = row_sum;
        }

        // Prove that ||Tx||_v <= kappa * ||x||_v
        let norm_x = weighted_max_norm(&x, &v);
        let norm_tx = weighted_max_norm(&tx, &v);

        // Due to floating point imprecision, we assert with a small epsilon
        assert!(norm_tx <= kappa * norm_x + 1e-9, "Weighted norm did not contract!");
    }
}
