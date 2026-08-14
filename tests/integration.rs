// Real integration test for the 108-cycle Glass-Box gate.
//
// This test exercises the genuine verification engine (no hardcoded stubs):
//   1. Build the canonical 108-cycle word and serialize it.
//   2. Verify it: Hecke + Deligne + lambda_eff <= ACE_BOUND must all hold,
//      dimension must be 108.
//   3. The proof digest must be reproducible: re-verifying identical bytes
//      yields an identical digest.
//   4. A single-byte corruption must change the digest AND cause rejection,
//      proving the gate is real and not a constant.

use lean_sdk::{generate_canonical_word, verify_certificate, ACE_BOUND};

#[test]
fn canonical_108_cycle_verifies() {
    let word = generate_canonical_word();
    let bytes = word.to_bytes();

    let v = verify_certificate(&bytes);

    assert!(v.is_valid, "canonical word must verify: {:?}", v);
    assert!(v.hecke_ok, "Hecke recurrence must hold");
    assert!(v.deligne_ok, "Deligne bound must hold");
    assert_eq!(v.dimension, 108, "dimension of canonical word must be 108");
    assert!(
        v.lambda_eff > 0.0 && v.lambda_eff <= ACE_BOUND,
        "lambda_eff {} must be in (0, {}]",
        v.lambda_eff,
        ACE_BOUND
    );
}

#[test]
fn digest_is_reproducible() {
    let bytes = generate_canonical_word().to_bytes();
    let a = verify_certificate(&bytes);
    let b = verify_certificate(&bytes);
    assert_eq!(a.digest, b.digest, "digest must be deterministic");
    assert_eq!(
        a.lambda_eff, b.lambda_eff,
        "lambda_eff must be deterministic"
    );
}

#[test]
fn corruption_is_rejected() {
    let bytes = generate_canonical_word().to_bytes();
    let good = verify_certificate(&bytes);
    assert!(good.is_valid);

    // Flip a single byte in the coefficient region (after the header).
    let mut corrupted = bytes.clone();
    let flip_idx = corrupted.len() / 2;
    corrupted[flip_idx] ^= 0x01;

    let bad = verify_certificate(&corrupted);

    assert_ne!(
        good.digest, bad.digest,
        "a byte flip must change the proof digest"
    );
    assert!(
        !bad.is_valid,
        "a corrupted word must be rejected by the gate"
    );
}

#[test]
fn hecke_violation_is_rejected() {
    // Same primes/exponents but a coefficient that breaks the Hecke recurrence.
    let bytes = lean_sdk::IRWord {
        blocks: vec![
            lean_sdk::PrimeBlock {
                prime: 3,
                r_max: 3,
                coeffs: vec![1, 252, 113643, -73279080],
            },
            lean_sdk::PrimeBlock {
                prime: 2,
                r_max: 2,
                coeffs: vec![1, -24, -1472],
            },
        ],
    }
    .to_bytes();

    let v = verify_certificate(&bytes);
    assert!(!v.is_valid, "Hecke violation must be rejected");
    assert!(!v.hecke_ok);
}
