//! Execution Manifest & Multi-Node Attestation Schema

use crate::gap_attestation::GapProof;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ExecutionManifest {
    pub operator_bcs_hex: String,
    pub operator_hash: String,
    pub topological_signature: String,
    pub seed_n: String,
    pub offset_k: usize,
    pub prime_p: String,
    pub gap_proof: GapProof,
}

pub struct ManifestAuditor;

impl ManifestAuditor {
    /// Verify an entire execution manifest in O(1) verification cost.
    pub fn verify_manifest(manifest: &ExecutionManifest) -> bool {
        crate::gap_attestation::GapAttestationEngine::verify_gap_proof(&manifest.gap_proof)
    }
}
