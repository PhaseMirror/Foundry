//! Cross-Layer Merkle Root Binding (ADR-0037 §3)

use sha2::{Digest, Sha256};

pub struct MerkleBinding;

impl MerkleBinding {
    /// Compute Merkle root binding Lean proof artifacts, commitment leaf, and policy hash.
    pub fn compute_merkle_root(
        lean_artifact_sha: &str,
        commitment_x_hex: &str,
        commitment_y_hex: &str,
        preimage_sha: &str,
        policy_hash: &str,
    ) -> String {
        // commitment_leaf = SHA256(C.x || C.y || artifact_sha || preimage_sha)
        let mut leaf_hasher = Sha256::new();
        leaf_hasher.update(commitment_x_hex.as_bytes());
        leaf_hasher.update(commitment_y_hex.as_bytes());
        leaf_hasher.update(lean_artifact_sha.as_bytes());
        leaf_hasher.update(preimage_sha.as_bytes());
        let commitment_leaf = hex::encode(leaf_hasher.finalize());

        // MerkleRoot = SHA256(commitment_leaf || artifact_sha || preimage_sha || policy_hash)
        let mut root_hasher = Sha256::new();
        root_hasher.update(commitment_leaf.as_bytes());
        root_hasher.update(lean_artifact_sha.as_bytes());
        root_hasher.update(preimage_sha.as_bytes());
        root_hasher.update(policy_hash.as_bytes());
        hex::encode(root_hasher.finalize())
    }
}
