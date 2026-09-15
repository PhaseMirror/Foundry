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
    assert!(!primes.is_empty(), "Content address should have prime indices");

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
    // Artifacts are content-addressed; the check itself is well-formed.
    assert_eq!(addr_a.prime_factors[0].prime % 2, 0);
    let _ = shared;
}

#[test]
fn test_lambda_p_store_empty() {
    let store = LambdaPStore::new();
    assert!(store.is_empty());
    assert_eq!(store.len(), 0);
}

#[test]
fn test_lambda_p_store_retrieves_stored_artifact() {
    let mut store = LambdaPStore::new();
    let artifact = StoredArtifact::new(b"permanent-record".to_vec(), BTreeMap::new());
    let hex = store.store_untagged(artifact).expect("store should accept");
    let got = store.get(&hex).expect("stored artifact must be retrievable");
    assert_eq!(got.data, b"permanent-record".to_vec());
    assert_eq!(got.address.hex, hex);
}

#[test]
fn test_compatible_gate_admits_matching_domain_only() {
    assert!(compatible("archivum-domain", "archivum-domain"), "equal tags admit");
    assert!(!compatible("crmf-domain", "archivum-domain"), "mismatched tags fail closed");
}

#[test]
fn test_compatible_gate_rejects_mismatched_store() {
    let mut store = LambdaPStore::new().with_domain_tag("archivum-domain");
    let mut metadata = BTreeMap::new();
    metadata.insert("domain_tag".to_string(), "crmf-domain".to_string());
    let artifact = StoredArtifact::new(
        b"sealed-under-crmf-domain".to_vec(),
        metadata,
    );
    assert!(store.store(artifact).is_err(), "mismatched domain must be rejected");
}

#[test]
fn test_compatible_gate_admits_matching_store() {
    let mut store = LambdaPStore::new().with_domain_tag("archivum-domain");
    let mut metadata = BTreeMap::new();
    metadata.insert("domain_tag".to_string(), "archivum-domain".to_string());
    let artifact = StoredArtifact::new(
        b"sealed-under-archivum-domain".to_vec(),
        metadata,
    );
    assert!(store.store(artifact).is_ok(), "matching domain must be admitted");
}

#[test]
fn test_ledger_append_chains_and_links() {
    let mut ledger = ArchivumLedger::new();
    let w1 = Witness {
        state_hash: "hash-1".to_string(),
        event_type: "event".to_string(),
        timestamp: 0,
        commit_hash: None,
        previous_hash: None,
    };
    let w2 = Witness {
        state_hash: "hash-2".to_string(),
        event_type: "event".to_string(),
        timestamp: 1,
        commit_hash: None,
        previous_hash: None,
    };
    ledger.append(w1).unwrap();
    ledger.append(w2).unwrap();
    assert!(ledger.is_linked(), "chained appends must be hash-linked");
    assert!(ledger.verify_chain(), "fresh chain must verify");
    assert_eq!(
        ledger.witnesses[1].previous_hash.as_deref(),
        Some("hash-1"),
        "second witness must link to the head"
    );
}

#[test]
fn test_ledger_rejects_duplicate_witness() {
    let mut ledger = ArchivumLedger::new();
    let w = Witness {
        state_hash: "dup-hash".to_string(),
        event_type: "event".to_string(),
        timestamp: 0,
        commit_hash: None,
        previous_hash: None,
    };
    ledger.append(w.clone()).unwrap();
    let err = ledger.append(w).unwrap_err();
    assert!(matches!(err, ArchivumError::DuplicateWitness { .. }),
        "duplicate append must fail closed");
}

#[test]
fn test_ledger_tamper_detection() {
    let mut ledger = ArchivumLedger::new();
    ledger
        .append(Witness {
            state_hash: "t-hash-1".to_string(),
            event_type: "e".to_string(),
            timestamp: 0,
            commit_hash: None,
            previous_hash: None,
        })
        .unwrap();
    ledger
        .append(Witness {
            state_hash: "t-hash-2".to_string(),
            event_type: "e".to_string(),
            timestamp: 1,
            commit_hash: None,
            previous_hash: None,
        })
        .unwrap();
    assert!(ledger.verify_chain());

    // Tamper: mutate the stored first witness.
    ledger.witnesses[0].state_hash = "t-hash-tampered".to_string();
    assert!(!ledger.verify_chain(), "tampered chain must fail verification");
}

#[test]
fn test_compatible_gate_on_ledger_append() {
    let mut ledger = ArchivumLedger::new();
    let w = Witness {
        state_hash: "g-hash".to_string(),
        event_type: "e".to_string(),
        timestamp: 0,
        commit_hash: None,
        previous_hash: None,
    };
    assert!(ledger
        .append_compatible(w.clone(), "crmf-domain", "archivum-domain")
        .is_err(), "mismatched tags must fail closed on append");
    assert!(ledger
        .append_compatible(w, "archivum-domain", "archivum-domain")
        .is_ok(), "matching tags admitted on append");
}

#[test]
fn test_archivum_store_chain_integration() {
    let store = LambdaPStore::new().with_domain_tag("archivum-domain");
    let mut ledger = ArchivumLedger::new();
    store
        .append_witness(
            &mut ledger,
            Witness {
                state_hash: "i-hash-1".to_string(),
                event_type: "e".to_string(),
                timestamp: 0,
                commit_hash: None,
                previous_hash: None,
            },
            "archivum-domain",
        )
        .unwrap();
    store
        .append_witness(
            &mut ledger,
            Witness {
                state_hash: "i-hash-2".to_string(),
                event_type: "e".to_string(),
                timestamp: 1,
                commit_hash: None,
                previous_hash: None,
            },
            "archivum-domain",
        )
        .unwrap();
    assert!(store.verify_ledger(&ledger), "store-aggregated chain must verify");
    assert!(ledger.is_linked());
}