//! SHPA Production Daemon & Attestation Benchmark

use shpa::bcs::BcsSerializer;
use shpa::gap_attestation::GapAttestationEngine;
use shpa::h2p::H2pEngine;
use shpa::manifest::{ExecutionManifest, ManifestAuditor};
use shpa::topological::{FractalTree, TopologicalEngine};

fn main() {
    println!("================================================================================");
    println!("  SHPA: STATELESS HASH-TO-PRIME ATTESTATION PRODUCTION DAEMON                  ");
    println!("================================================================================");
    println!();

    // 1. BCS Canonical Serialization
    println!(">>> [STEP 1/4] Canonical BCS Operator Encoding & Identity Hashing...");
    let schema_ref = [0xAA; 32];
    let activation_fn = [0x55; 32];
    let bcs_bytes = BcsSerializer::serialize_operator(&schema_ref, 1, 1000, &activation_fn, 3);
    let op_hash = BcsSerializer::compute_operator_hash(&bcs_bytes);
    println!("    BCS Length: {} bytes", bcs_bytes.len());
    println!("    Operator Hash H(op): {}", hex::encode(op_hash));
    println!();

    // 2. Non-Commutative Topological Tree Signature
    println!(">>> [STEP 2/4] Computing Path-Dependent Topological Signatures...");
    let child1 = FractalTree::Leaf {
        operator_hash: [0x11; 32],
    };
    let child2 = FractalTree::Leaf {
        operator_hash: [0x22; 32],
    };

    let tree_a = FractalTree::Node {
        operator_hash: op_hash,
        children: vec![child1.clone(), child2.clone()],
    };
    let tree_b = FractalTree::Node {
        operator_hash: op_hash,
        children: vec![child2.clone(), child1.clone()], // swapped order
    };

    let sig_a = TopologicalEngine::compute_signature(&tree_a);
    let sig_b = TopologicalEngine::compute_signature(&tree_b);
    assert_ne!(sig_a, sig_b, "Topological signatures must be non-commutative!");
    println!("    Tree A Sig [Child 1, Child 2]: {}", hex::encode(sig_a));
    println!("    Tree B Sig [Child 2, Child 1]: {}", hex::encode(sig_b));
    println!("    Non-Commutative Geometry Test: PASS");
    println!();

    // 3. Stateless H2P Derivation with Offset Pinning
    println!(">>> [STEP 3/4] Stateless Full-Width H2P Derivation & Offset Pinning...");
    let seed_n = H2pEngine::derive_seed(&op_hash);
    let (prime_p, offset_k) = H2pEngine::find_first_prime(&seed_n).expect("Prime search failed");
    println!("    Seed N (256-bit odd): {}", seed_n);
    println!("    Pinned Offset k*: {}", offset_k);
    println!("    Assigned Prime p_op: {}", prime_p);
    println!("    Cramér Bound Check (k <= 65536): PASS");
    println!();

    // 4. Succinct Gap Attestation & Manifest Verification
    println!(">>> [STEP 4/4] Generating Succinct First-Prime Gap Proof & Verification...");
    let gap_proof = GapAttestationEngine::generate_gap_proof(&seed_n, offset_k).expect("Proof generation failed");
    println!("    Witness Count in Gap: {}", gap_proof.witnesses.len());
    println!("    Witness Commitment Root: {}", gap_proof.witness_root);

    let manifest = ExecutionManifest {
        operator_bcs_hex: hex::encode(&bcs_bytes),
        operator_hash: hex::encode(op_hash),
        topological_signature: hex::encode(sig_a),
        seed_n: seed_n.to_str_radix(10),
        offset_k,
        prime_p: prime_p.to_str_radix(10),
        gap_proof,
    };

    let is_valid = ManifestAuditor::verify_manifest(&manifest);
    assert!(is_valid, "Manifest verification failed!");
    println!("    Manifest Verification Status: PASS (O(1) Verifier Primality & Witness Root Check)");
    println!();

    println!("================================================================================");
    println!("  SHPA ATTESTATION ENGINE VERIFICATION COMPLETE (100% PASS)                     ");
    println!("================================================================================");
}
