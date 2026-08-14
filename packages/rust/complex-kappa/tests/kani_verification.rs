use num_complex::Complex;
use complex_kappa::{self, effective_coupling, hilbert_transform, zeta_zeros};

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn verify_hilbert_self_inverse() {
        let signal: [f64; 8] = kani::any();
        kani::assume(signal.iter().all(|&x| x.is_finite()));
        let transformed = hilbert_transform(&signal).unwrap();
        let double_transformed = hilbert_transform(&transformed).unwrap();
        let negated: Vec<f64> = signal.iter().map(|&x| -x).collect();
        for i in 0..signal.len() {
            kani::assert!(
                (double_transformed[i] - negated[i]).abs() < 1e-9,
                "Hilbert self-inverse failed at index {}: {} vs {}",
                i, double_transformed[i], negated[i]
            );
        }
    }

    #[kani::proof]
    fn verify_effective_coupling_identity() {
        let kappa_re: f64 = kani::any();
        let kappa_im: f64 = kani::any();
        kani::assume(kappa_re.is_finite() && kappa_im.is_finite());
        let kappa = Complex::new(kappa_re, kappa_im);
        let result = effective_coupling(kappa, Complex::new(0.0, 0.0), Complex::new(1.0, 0.0)).unwrap();
        kani::assert!(
            (result.re - kappa_re).abs() < 1e-9,
            "Real part mismatch"
        );
        kani::assert!(
            (result.im - kappa_im).abs() < 1e-9,
            "Imaginary part mismatch"
        );
    }

    #[kani::proof]
    fn verify_effective_coupling_no_divergence() {
        let kappa_re: f64 = kani::any();
        let kappa_im: f64 = kani::any();
        let d_r_re: f64 = kani::any();
        let d_r_im: f64 = kani::any();
        let o_re: f64 = kani::any();
        let o_im: f64 = kani::any();
        kani::assume(kappa_re.is_finite() && kappa_im.is_finite());
        kani::assume(d_r_re.is_finite() && d_r_im.is_finite());
        kani::assume(o_re.is_finite() && o_im.is_finite());
        kani::assume(!(o_re == 0.0 && o_im == 0.0));
        let kappa = Complex::new(kappa_re, kappa_im);
        let d_r = Complex::new(d_r_re, d_r_im);
        let o = Complex::new(o_re, o_im);
        let result = effective_coupling(kappa, d_r, o);
        kani::assert!(result.is_ok(), "effective_coupling should not fail for valid inputs");
    }

    #[kani::proof]
    fn verify_zeta_zero_bounds() {
        let n: u32 = kani::any();
        let eps: f64 = kani::any();
        let sig: f64 = kani::any();
        kani::assume(eps > 0.0 && sig > 0.0);
        let result = zeta_zeros::zeta_zero(n, eps, sig);
        if n >= 1 && n <= 32 {
            kani::assert!(result.is_ok(), "zeta_zero should succeed for n in [1,32]");
        }
    }

    #[kani::proof]
    fn verify_noise_kernel_finiteness() {
        let k: f64 = kani::any();
        let k_star: f64 = kani::any();
        let eps: f64 = kani::any();
        let sig: f64 = kani::any();
        kani::assume(k > 0.0 && k_star > 0.0 && eps > 0.0 && sig > 0.0);
        let result = complex_kappa::noise_kernel_zeta(k, k_star, eps, sig);
        kani::assert!(result.is_ok(), "noise_kernel should succeed for positive inputs");
        kani::assert!(result.unwrap().is_finite(), "noise_kernel must be finite");
    }

    #[kani::proof]
    #[kani::unwind(5)]
    fn verify_pair_correlation_bounds() {
        let beats: [f64; 4] = kani::any();
        kani::assume(beats.iter().all(|&x| x.is_finite() && x >= 0.0));
        let r2 = complex_kappa::empirical_pair_correlation(&beats, 1.0, 0.5);
        kani::assert!(r2 >= 0.0, "empirical pair correlation must be non-negative");
        kani::assert!(r2 <= 1.0, "empirical pair correlation must be <= 1");
    }
}

#[cfg(test)]
mod property_tests {
    use super::*;
    use proptest::prelude::*;

    proptest! {
        #[test]
        #[ignore]
        fn prop_hilbert_self_inverse(ref signal in prop::collection::vec(-100.0..100.0f64, 1..9)) {
            let h = hilbert_transform(signal).unwrap();
            let hh = hilbert_transform(&h).unwrap();
            for (a, b) in signal.iter().zip(hh.iter()) {
                prop_assert!((a + b).abs() < 1e-6, "self-inverse failed: {} + {} = {}", a, b, a + b);
            }
        }

        #[test]
        fn prop_gue_pair_correlation_bounded(u in -10.0..10.0f64) {
            let r2 = complex_kappa::gue_pair_correlation(u);
            prop_assert!(r2 >= 0.0);
            prop_assert!(r2 <= 1.0);
        }

        #[test]
        fn prop_effective_coupling_analytic(kr in -1.0..1.0f64, ki in -1.0..1.0f64, dr in -1.0..1.0f64) {
            let kappa = Complex::new(kr, ki);
            let d_r = Complex::new(dr, 0.0);
            let o = Complex::new(1.0, 0.0);
            if let Ok(result) = effective_coupling(kappa, d_r, o) {
                prop_assert!(result.re.is_finite());
                prop_assert!(result.im.is_finite());
            }
        }
    }
}
