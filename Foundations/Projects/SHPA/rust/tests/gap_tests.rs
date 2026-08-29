use num_bigint::BigUint;
use shpa::gap_attestation::GapAttestationEngine;
use shpa::h2p::H2pEngine;

#[test]
fn test_gap_proof_generation_and_verification() {
    let seed: BigUint = 1000000000000000001u64.into();
    let (_prime, offset) = H2pEngine::find_first_prime(&seed).expect("Prime search failed");

    let proof = GapAttestationEngine::generate_gap_proof(&seed, offset).expect("Proof generation failed");
    assert!(GapAttestationEngine::verify_gap_proof(&proof));

    // Tampered offset must fail verification
    let mut tampered = proof.clone();
    tampered.offset_k += 2;
    assert!(!GapAttestationEngine::verify_gap_proof(&tampered));
}
