#[cfg(kani)]
mod hilbert_polya_proof {
    use pirtm_rs::hilbert_polya::*;

    #[kani::proof]
    fn verify_hp_operator_contractive_and_symmetric() {
        // Fixed small primes and cutoff
        let primes = [2u64, 3u64];
        let cutoff: usize = 2; // Kani symbolically unrolls loops up to bound
        let hp = build_hp_operator(&primes, cutoff);

        // Check symmetry
        assert!(is_symmetric(&hp));

        // Check Frobenius norm squared < 1 (sufficient condition for contractivity)
        let frob_sq = frobenius_norm_sq(&hp);
        assert!(frob_sq < 1.0, "Operator not contractive");
    }

    #[kani::proof]
    fn verify_hp_operator_primes_2_3_5_contractive() {
        let primes = [2u64, 3u64, 5u64];
        let cutoff = 2;
        let hp = build_hp_operator(&primes, cutoff);
        assert!(is_symmetric(&hp));
        let frob_sq = frobenius_norm_sq(&hp);
        assert!(frob_sq < 1.0);
    }

    #[kani::proof]
    fn verify_hp_operator_primes_2_3_5_7_contractive() {
        let primes = [2u64, 3u64, 5u64, 7u64];
        let cutoff = 2;
        let hp = build_hp_operator(&primes, cutoff);
        assert!(is_symmetric(&hp));
        let frob_sq = frobenius_norm_sq(&hp);
        assert!(frob_sq < 1.0);
    }
}
