//! Godelian Truth Kani verification harness.
//!
//! Run with: cargo kani --tests --unwind 10

#[cfg(kani)]
mod verification {
    use super::*;

    // =========================================================================
    // Core constants verification
    // =========================================================================

    #[kani::proof]
    fn verify_fp_den_positive() {
        assert!(FP_DEN == 100, "FP_DEN must be 100");
    }

    #[kani::proof]
    fn verify_lambda_valid() {
        assert!(LAMBDA > 0 && LAMBDA < FP_DEN, "lambda must be in (0, 100)");
    }

    #[kani::proof]
    fn verify_alpha_valid() {
        assert!(ALPHA > 0 && ALPHA < FP_DEN, "alpha must be in (0, 100)");
    }

    #[kani::proof]
    fn verify_contraction_strict() {
        assert!(CONTRACTION_FACTOR < FP_DEN, "contraction factor must be < 100");
    }

    #[kani::proof]
    fn verify_contraction_positive() {
        assert!(CONTRACTION_FACTOR > 0, "contraction factor must be > 0");
    }

    // =========================================================================
    // Strong Kleene connectives verification
    // =========================================================================

    #[kani::proof]
    fn verify_sk_neg_involution() {
        let x: usize = kani::any();
        kani::assume(x <= FP_DEN);
        assert!(sk_neg(sk_neg(x)) == x, "negation is involution");
    }

    #[kani::proof]
    fn verify_sk_neg_bounds() {
        let x: usize = kani::any();
        kani::assume(x <= FP_DEN);
        let y = sk_neg(x);
        assert!(y <= FP_DEN, "negation must stay in [0, 100]");
    }

    #[kani::proof]
    fn verify_sk_and_commutative() {
        let x: usize = kani::any();
        let y: usize = kani::any();
        kani::assume(x <= FP_DEN);
        kani::assume(y <= FP_DEN);
        assert!(sk_and(x, y) == sk_and(y, x), "and is commutative");
    }

    #[kani::proof]
    fn verify_sk_and_idempotent() {
        let x: usize = kani::any();
        kani::assume(x <= FP_DEN);
        assert!(sk_and(x, x) == x, "and is idempotent");
    }

    #[kani::proof]
    fn verify_sk_or_commutative() {
        let x: usize = kani::any();
        let y: usize = kani::any();
        kani::assume(x <= FP_DEN);
        kani::assume(y <= FP_DEN);
        assert!(sk_or(x, y) == sk_or(y, x), "or is commutative");
    }

    // =========================================================================
    // Gamma operator verification
    // =========================================================================

    #[kani::proof]
    fn verify_gamma_nonexpansive() {
        let v: Valuation = kani::any();
        let w: Valuation = kani::any();
        kani::assume(v.iter().all(|&x| x <= FP_DEN));
        kani::assume(w.iter().all(|&x| x <= FP_DEN));
        assert!(verify_gamma_nonexpansive(&v, &w), "Gamma must be 1-Lipschitz");
    }

    #[kani::proof]
    fn verify_gamma_atom_p() {
        let v: Valuation = kani::any();
        let g = gamma(&v);
        assert!(g[0] == FP_DEN, "P is always provable");
    }

    #[kani::proof]
    fn verify_godot_atom_g_soundness() {
        let v: Valuation = kani::any();
        let g = gamma(&v);
        assert!(g[2] == FP_DEN, "G = 1 - Prov(G) = 1 under soundness");
    }

    // =========================================================================
    // Contraction verification
    // =========================================================================

    #[kani::proof]
    fn verify_tlambda_contraction() {
        let v: Valuation = kani::any();
        let w: Valuation = kani::any();
        kani::assume(v.iter().all(|&x| x <= FP_DEN));
        kani::assume(w.iter().all(|&x| x <= FP_DEN));
        assert!(verify_tlambda_contraction(&v, &w), "T_lambda must be a contraction");
    }

    // =========================================================================
    // Prime sieve verification
    // =========================================================================

    #[kani::proof]
    fn verify_pi_10() {
        assert!(pi(10) == 4, "pi(10) must be 4");
    }

    #[kani::proof]
    fn verify_pi_20() {
        assert!(pi(20) == 8, "pi(20) must be 8");
    }

    #[kani::proof]
    fn verify_is_prime_2() {
        assert!(is_prime(2) == true, "2 is prime");
    }

    #[kani::proof]
    fn verify_is_prime_3() {
        assert!(is_prime(3) == true, "3 is prime");
    }

    #[kani::proof]
    fn verify_not_prime_4() {
        assert!(is_prime(4) == false, "4 is not prime");
    }

    #[kani::proof]
    fn verify_prime_sieved_convergence() {
        assert!(verify_prime_sieved_convergence(100), "prime-sieved must converge");
    }

    // =========================================================================
    // Soundness verification
    // =========================================================================

    #[kani::proof]
    fn verify_soundness_godel() {
        assert!(verify_soundness_godel(), "Gödel sentence must be true under soundness");
    }

    // =========================================================================
    // Conservative extension verification
    // =========================================================================

    #[kani::proof]
    fn verify_conservative() {
        assert!(verify_conservative(), "F' must be conservative over F");
    }
}
