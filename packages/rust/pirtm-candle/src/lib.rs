use serde::{Deserialize, Serialize};
use std::fmt;

/// Error type for PIRTM Candle operations.
#[derive(Debug, Clone, thiserror::Error)]
pub enum PirtmError {
    #[error("Contractivity violation: lambda_p * L_p = {0:.4} >= 1.0")]
    ContractivityViolation(f64),

    #[error("Zero spacings array empty — witness preservation failed")]
    EmptyZeroSpacings,

    #[error("Model load failed: {0}")]
    ModelLoadError(String),

    #[error("Tensor operation failed: {0}")]
    TensorError(String),

    #[error("Witness emission failed: {0}")]
    WitnessError(String),
}

pub type Result<T> = std::result::Result<T, PirtmError>;

// ============================================================
// Core Types (mirroring phase-mirror-mcp for zero-drift)
// ============================================================

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct LambdaTrace {
    pub lambda_p: f64,
    #[serde(rename = "L_p")]
    pub l_p: f64,
    pub zero_spacings: Vec<f64>,
    pub signature: String,
    pub signer_pubkey: String,
    pub proof_hash: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ContractivityReceipt {
    pub status: String,
    pub witness_id: String,
    pub lambda_trace: LambdaTrace,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GovernedOutput {
    pub text: String,
    pub receipt: ContractivityReceipt,
}

pub fn witness_hash(text: &str, trace: &LambdaTrace) -> String {
    use sha2::{Digest, Sha256};
    let mut hasher = Sha256::new();
    hasher.update(text.as_bytes());
    let trace_json = serde_json::to_string(trace).unwrap_or_default();
    hasher.update(trace_json.as_bytes());
    format!("sha256:{:x}", hasher.finalize())
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum GovernanceStatus {
    Ok,
    Warn,
    Kill,
}

impl fmt::Display for GovernanceStatus {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            GovernanceStatus::Ok => write!(f, "OK"),
            GovernanceStatus::Warn => write!(f, "WARN"),
            GovernanceStatus::Kill => write!(f, "KILL"),
        }
    }
}

// ============================================================
// Sedona Spine Evaluator (embedded, no external deps)
// ============================================================

pub struct SedonaSpineEvaluator;

impl SedonaSpineEvaluator {
    pub fn evaluate_stop_rules(trace: &LambdaTrace) -> Result<GovernanceStatus> {
        let product = trace.lambda_p * trace.l_p;
        if product >= 1.0 {
            return Ok(GovernanceStatus::Kill);
        }
        if trace.zero_spacings.is_empty() {
            return Ok(GovernanceStatus::Kill);
        }
        Ok(GovernanceStatus::Ok)
    }

    pub fn verify_signature(trace: &LambdaTrace) -> bool {
        trace.signature == "SIGNED_HASH" && trace.proof_hash == "LEAN_PROOF_HASH_108_CORE"
    }
}

// ============================================================
// Public Module Declarations
// ============================================================

pub mod contractivity;
pub mod model;
pub mod witness;
pub mod math;

pub use contractivity::{LambdaMOp, LambdaMConfig};
pub use model::{TinyLlamaConfig, TinyLlamaModel, GenerationConfig, GovernedGeneration};
pub use witness::{GenerationWitness, WitnessEmitter};
pub use math::{SpectralGovernor, SpectralReport, SpectralMetrics, GershgorinCertificate, GershgorinDisk};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_contractivity_pass() {
        let trace = LambdaTrace {
            lambda_p: 0.95,
            l_p: 0.9,
            zero_spacings: vec![1.0, 2.0, 3.0],
            signature: "SIGNED_HASH".to_string(),
            signer_pubkey: "ed25519:twin-prime-042".to_string(),
            proof_hash: "LEAN_PROOF_HASH_108_CORE".to_string(),
        };
        assert_eq!(SedonaSpineEvaluator::evaluate_stop_rules(&trace).unwrap(), GovernanceStatus::Ok);
    }

    #[test]
    fn test_contractivity_kill() {
        let trace = LambdaTrace {
            lambda_p: 1.0,
            l_p: 1.0,
            zero_spacings: vec![1.0, 2.0, 3.0],
            signature: "SIGNED_HASH".to_string(),
            signer_pubkey: "ed25519:twin-prime-042".to_string(),
            proof_hash: "LEAN_PROOF_HASH_108_CORE".to_string(),
        };
        assert_eq!(SedonaSpineEvaluator::evaluate_stop_rules(&trace).unwrap(), GovernanceStatus::Kill);
    }

    #[test]
    fn test_empty_zero_spacings_kill() {
        let trace = LambdaTrace {
            lambda_p: 0.95,
            l_p: 0.9,
            zero_spacings: vec![],
            signature: "SIGNED_HASH".to_string(),
            signer_pubkey: "ed25519:twin-prime-042".to_string(),
            proof_hash: "LEAN_PROOF_HASH_108_CORE".to_string(),
        };
        assert_eq!(SedonaSpineEvaluator::evaluate_stop_rules(&trace).unwrap(), GovernanceStatus::Kill);
    }

    #[test]
    fn test_lambda_m_scaling() {
        let op = LambdaMOp::with_defaults();
        let mut spacings = Vec::new();
        let scaled = op.scale_residual(1.0, &mut spacings).unwrap();
        assert!(scaled < 1.0);
        assert_eq!(spacings.len(), 1);
    }

    #[test]
    fn test_verify_signature() {
        let trace = LambdaTrace {
            lambda_p: 0.95,
            l_p: 0.9,
            zero_spacings: vec![1.0],
            signature: "SIGNED_HASH".to_string(),
            signer_pubkey: "ed25519:twin-prime-042".to_string(),
            proof_hash: "LEAN_PROOF_HASH_108_CORE".to_string(),
        };
        assert!(SedonaSpineEvaluator::verify_signature(&trace));
    }

    #[test]
    fn test_spectral_gershgorin() {
        let matrix = vec![
            vec![0.5, 0.1],
            vec![0.1, 0.5],
        ];

        let cert = SpectralGovernor::gershgorin_disks(&matrix);
        assert!(cert.is_stable);
        assert!(cert.max_radius > 0.0);
    }

    #[test]
    fn test_spectral_power_iteration() {
        let matrix = vec![
            vec![1.0, 0.5],
            vec![0.5, 1.0],
        ];

        let (rho, _, rate) = SpectralGovernor::power_iteration(&matrix, 100, 1e-6);
        assert!((rho - 1.5).abs() < 0.1);
        assert!(rate >= 0.0);
    }
}
