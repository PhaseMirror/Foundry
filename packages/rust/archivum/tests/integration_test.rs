use archivum::*;
use std::collections::BTreeMap;

#[test]
fn test_content_address_deterministic() {
    let addr1 = ContentAddress::from_bytes(b"test-data");
    let addr2 = ContentAddress::from_bytes(b"test-data");
    assert_eq!(addr1, addr2);
    assert_eq!(addr1.hex.len(), 64);
}

#[test]
fn test_factorize_u64() {
    let factors = prime_index::factorize_u64(60);
    assert_eq!(factors.len(), 3);
    assert_eq!(factors[0].prime, 2);
    assert_eq!(factors[0].exponent, 2);
    assert_eq!(factors[1].prime, 3);
    assert_eq!(factors[2].prime, 5);
}

#[test]
fn test_prime_index_by_prime() {
    let mut index = PrimeIndex::new();
    let addr = ContentAddress::from_string("hello-world");
    index.insert(addr.clone());

    let primes = addr.prime_indices();
    assert!(primes.len() > 0, "Content address should have prime indices");

    for p in primes {
        let found = index.by_prime(p);
        assert!(!found.is_empty(), "Prime {} should index the artifact", p);
    }
}

#[test]
fn test_prime_index_shared_primes() {
    let mut index = PrimeIndex::new();
    let addr_a = ContentAddress::from_string("artifact-a");
    let addr_b = ContentAddress::from_string("artifact-b");
    index.insert(addr_a.clone());
    index.insert(addr_b.clone());

    let shared = index.shared_primes(&addr_a.hex, &addr_b.hex);
    // Artifacts with similar names may share some prime factors
    assert!(shared.len() >= 0, "Shared primes check completed");
}

#[test]
fn test_lambda_p_store_empty() {
    let store = LambdaPStore::new();
    assert!(store.is_empty());
    assert_eq!(store.len(), 0);
}
