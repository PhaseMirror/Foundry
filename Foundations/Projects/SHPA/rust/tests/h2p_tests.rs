use num_bigint::BigUint;
use shpa::h2p::H2pEngine;

#[test]
fn test_primality_miller_rabin() {
    let prime_small: BigUint = 104729u32.into();
    assert!(H2pEngine::is_prime(&prime_small));

    let composite_small: BigUint = 104730u32.into();
    assert!(!H2pEngine::is_prime(&composite_small));
}

#[test]
fn test_h2p_seed_derivation_and_search() {
    let hash = [0x5Au8; 32];
    let seed = H2pEngine::derive_seed(&hash);
    assert_eq!(&seed % 2u32, 1u32.into(), "Seed must be odd");

    let (prime, offset) = H2pEngine::find_first_prime(&seed).expect("Prime search failed");
    assert!(H2pEngine::is_prime(&prime));
    assert_eq!(offset % 2, 0, "Offset must be even");
    assert!(offset <= H2pEngine::K_MAX);
}
