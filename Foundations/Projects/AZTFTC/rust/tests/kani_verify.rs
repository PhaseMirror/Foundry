#[cfg(kani)]
mod kani_verify {
    use super::*;

    #[kani::proof]
    fn verify_is_prime_2() {
        assert!(is_prime(2));
    }

    #[kani::proof]
    fn verify_is_prime_3() {
        assert!(is_prime(3));
    }

    #[kani::proof]
    fn verify_is_prime_4() {
        assert!(!is_prime(4));
    }

    #[kani::proof]
    fn verify_pi_10() {
        assert_eq!(pi(10), 4);
    }

    #[kani::proof]
    fn verify_pi_20() {
        assert_eq!(pi(20), 8);
    }

    #[kani::proof]
    fn verify_normalize_preserves_norm() {
        let v: Vec<f64> = kani::vec![1.0, 2.0, 3.0];
        let n = normalize(&v);
        let norm = f64::sqrt(norm_sq(&n));
        assert!((norm - 1.0).abs() < 1e-10);
    }

    #[kani::proof]
    fn verify_inner_prod_symmetric() {
        let v: Vec<f64> = kani::vec![1.0, 2.0];
        let w: Vec<f64> = kani::vec![3.0, 4.0];
        assert!((inner_prod(&v, &w) - inner_prod(&w, &v)).abs() < 1e-10);
    }

    #[kani::proof]
    fn verify_log_gaussian_positive() {
        let sigma: f64 = kani::any();
        let v: f64 = kani::any();
        kani::assume(sigma > 0.0);
        assert!(log_gaussian(sigma, v) > 0.0);
    }

    #[kani::proof]
    fn verify_build_u_dimensions() {
        let n: usize = kani::any();
        let m: usize = kani::any();
        kani::assume(n > 0);
        kani::assume(m > 0);
        let primes = first_n_primes(n);
        let mat = build_u(n, m, &primes);
        assert_eq!(mat.len(), n * m);
        for row in &mat {
            assert_eq!(row.len(), n * m);
        }
    }

    #[kani::proof]
    fn verify_power_iter_diagonal() {
        let lambda: f64 = kani::any();
        kani::assume(lambda > 0.0);
        let mat = vec![vec![lambda, 0.0], vec![0.0, lambda]];
        let v0 = vec![1.0, 1.0];
        let rho = power_iter(&mat, &v0, 100);
        assert!((rho - lambda).abs() < 1e-6);
    }
}
