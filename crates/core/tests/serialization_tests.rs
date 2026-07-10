use pirtm_rs::{compute_proof_hash, PIRTMGovernanceSection, PIRTMProofSection, PIRTMRuntime};
use std::collections::HashMap;
use tempfile::tempdir;

#[test]
fn test_binary_serialization_roundtrip() {
    let dir = tempdir().unwrap();
    let bin_path = dir.path().join("pirtm_runtime.bin");

    let prime = 7;
    let epsilon = 0.05;
    let op_norm_t = 0.8;
    let proof_hash = compute_proof_hash(prime, epsilon, op_norm_t);

    let mut session_map = HashMap::new();
    session_map.insert("SessionA".to_string(), prime);

    let runtime = PIRTMRuntime {
        proof: PIRTMProofSection {
            prime_index: prime,
            epsilon,
            op_norm_t,
            contractivity_check: "PASS".to_string(),
            proof_hash: proof_hash.clone(),
        },
        governance: PIRTMGovernanceSection {
            ensemble_hash: "ensemble123".to_string(),
            global_spectral_radius: 0.85,
            is_contractive: true,
            timestamp: 123456789.0,
            session_map,
        },
        code: b"MLIR_BYTECODE_CONTENT".to_vec(),
    };

    // Save
    runtime
        .save(bin_path.to_str().unwrap())
        .expect("Save failed");

    // Load
    let loaded = PIRTMRuntime::load(bin_path.to_str().unwrap()).expect("Load failed");

    assert_eq!(loaded.proof.prime_index, prime);
    assert_eq!(loaded.proof.proof_hash, proof_hash);
    assert_eq!(loaded.governance.ensemble_hash, "ensemble123");
    assert_eq!(loaded.code, b"MLIR_BYTECODE_CONTENT");
}

#[test]
fn test_inspect_mandatory_output() {
    let mut session_map = HashMap::new();
    session_map.insert("SessionA".to_string(), 7);

    let runtime = PIRTMRuntime {
        proof: PIRTMProofSection {
            prime_index: 7,
            epsilon: 0.05,
            op_norm_t: 0.8,
            contractivity_check: "PASS".to_string(),
            proof_hash: "hash".to_string(),
        },
        governance: PIRTMGovernanceSection {
            ensemble_hash: "govhash".to_string(),
            global_spectral_radius: 0.85,
            is_contractive: true,
            timestamp: 0.0,
            session_map,
        },
        code: vec![],
    };

    let output = runtime.inspect();
    println!("{}", output);

    // L0.7: The pirtm inspect output must always include...
    assert!(output.contains("Audit Chain: NOT EMBEDDED — retrieve via pirtm audit <trace.log>"));
    assert!(output.contains("=== PIRTM SEAL INSPECTION ==="));
}
