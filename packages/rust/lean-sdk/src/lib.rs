pub mod verification;

pub use verification::{
    deserialize_word, generate_canonical_word, generate_certificate_file, verify_certificate,
    verify_certificate_with_digest, IRWord, PrimeBlock, VerificationResult, ACE_BOUND_THRESHOLD,
};

/// Backward-compatible alias.
pub type ResonanceWord = IRWord;

/// Backward-compatible alias.
pub type Verification = VerificationResult;

/// Backward-compatible alias for the canonical word generator.
pub fn canonical_108_cycle() -> ResonanceWord {
    verification::generate_canonical_word()
}

/// Lean-derived maximal allowable effective Lipschitz constant for the
/// 108-cycle. Mirrors `aceBound` in Core.lean, which returns 6000/10000 = 0.6
/// for any word whose dimension D equals 108.
pub const ACE_BOUND: f64 = verification::ACE_BOUND_THRESHOLD;
