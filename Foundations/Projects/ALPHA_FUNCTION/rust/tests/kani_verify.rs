#[cfg(kani)]
mod kani_verify {
    use super::*;

    #[kani::proof]
    fn verify_kernel_g1_at_zero() {
        assert!(kernel_g1(0.0, 0.0) == 1.0);
    }

    #[kani::proof]
    fn verify_kernel_g2_at_zero() {
        let a: f64 = kani::any();
        kani::assume(a.is_finite());
        assert!(kernel_g2(a, 0.0, 0.0) == 1.0);
    }

    #[kani::proof]
    fn verify_kernel_g3_at_zero() {
        let c: f64 = kani::any();
        let m: f64 = kani::any();
        kani::assume(c.is_finite());
        kani::assume(m.is_finite());
        assert!(kernel_g3(c, m, 0.0, 0.0) == 1.0);
    }

    #[kani::proof]
    fn verify_soft_threshold_preserves_dimension() {
        let w: Vec<f64> = kani::vec![1.0, 2.0, 3.0];
        let b: Vec<f64> = kani::vec![1.0];
        let t: f64 = kani::any();
        kani::assume(t >= 0.0);
        let result = soft_threshold(&w, &b, t);
        assert_eq!(result.len(), w.len());
    }

    #[kani::proof]
    fn verify_soft_threshold_nonnegative() {
        let w: Vec<f64> = kani::vec![1.0, 2.0, 3.0];
        let b: Vec<f64> = kani::vec![1.0];
        let t: f64 = kani::any();
        kani::assume(t >= 0.0);
        let result = soft_threshold(&w, &b, t);
        for &val in &result {
            assert!(val >= 0.0);
        }
    }

    #[kani::proof]
    fn verify_zeta_converges_for_s_gt_1() {
        let s: f64 = kani::any();
        kani::assume(s > 1.0);
        let result = zeta_slice(s, 100);
        assert!(result.is_finite());
    }

    #[kani::proof]
    fn verify_alpha_master_series() {
        let x: f64 = kani::any();
        let theta0: f64 = kani::any();
        let c_k: Vec<f64> = kani::vec![1.0, 2.0];
        let rho_k: Vec<f64> = kani::vec![2.0, 3.0];
        kani::assume(x > 0.0);
        kani::assume(theta0 > 0.0);
        let result = alpha_master(x, theta0, &c_k, &rho_k);
        assert!(result.is_finite());
    }
}
