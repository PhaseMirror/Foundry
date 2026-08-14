#[cfg(kani)]
mod jury_schur_proofs {
    use ndarray::{Array1, Array2};
    use pirtm_rs::jury::{satisfies_schur_condition, spectral_radius_less_than_one_2x2};

    #[kani::proof]
    fn schur_implies_contractive_2x2() {
        // symbolic entries for a 2×2 matrix
        fn any_fraction() -> f64 {
            let num: u8 = kani::any();
            kani::assume(num <= 10); // Values from 0.0 to 1.0
            (num as f64) / 10.0
        }

        // symbolic entries for a 2×2 matrix on a discrete grid
        let a00 = any_fraction();
        let a01 = any_fraction();
        let a10 = any_fraction();
        let a11 = any_fraction();
        let a = Array2::from_shape_vec((2, 2), vec![a00, a01, a10, a11]).unwrap();

        // symbolic positive vector on a discrete grid
        let v0 = any_fraction();
        let v1 = any_fraction();
        kani::assume(v0 > 0.0);
        kani::assume(v1 > 0.0);
        let v = Array1::from_vec(vec![v0, v1]);

        // assume the Schur condition holds
        kani::assume(satisfies_schur_condition(&a, &v));

        // then spectral radius < 1 must be true
        assert!(spectral_radius_less_than_one_2x2(&a));
    }
}
