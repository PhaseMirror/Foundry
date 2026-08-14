#[cfg(kani)]
mod hilbert_polya_proofs {
    use ndarray::{Array1, Array2};
    use pirtm_rs::hilbert_polya::single_prime_operator_2x2;
    use pirtm_rs::jury::{satisfies_schur_condition, spectral_radius_less_than_one_2x2};

    /// Verify that for any small prime p, the single-mode 2×2 operator A_p
    /// satisfies the Schur condition (with the all-ones vector) and therefore
    /// has spectral radius < 1 via the previously proven 2×2 Jury lemma.
    #[kani::proof]
    fn verify_single_prime_satisfies_schur_and_contractive() {
        let p: u64 = kani::any();
        kani::assume(p >= 2 && p <= 7); // laboratory primes
        let a = single_prime_operator_2x2(p);
        let v = Array1::from_vec(vec![1.0, 1.0]); // strictly positive
        assert!(
            satisfies_schur_condition(&a, &v),
            "A_p must satisfy Schur condition with all-ones vector"
        );
        assert!(
            spectral_radius_less_than_one_2x2(&a),
            "A_p must have spectral radius < 1"
        );
    }
}
