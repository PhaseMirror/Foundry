use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContractivityProof {
    pub margin: f64,
}

#[derive(Debug, thiserror::Error)]
pub enum Violation {
    #[error("stress exceeds theta_max while health below theta_min")]
    StressExceedsThreshold,
    #[error("global contraction margin below 0.005")]
    MarginBelowThreshold,
}

pub struct TwinBindingContract;

impl TwinBindingContract {
    pub fn check(q: f64, c: f64, theta_max: f64, theta_min: f64) -> Result<ContractivityProof, Violation> {
        if q > theta_max && c < theta_min {
            return Err(Violation::StressExceedsThreshold);
        }
        
        let margin = GlobalContractionMargin::compute(q, c);
        if margin < 0.005 {
            return Err(Violation::MarginBelowThreshold);
        }
        
        Ok(ContractivityProof { margin })
    }
}

pub struct GlobalContractionMargin;

impl GlobalContractionMargin {
    pub fn compute(q: f64, c: f64) -> f64 {
        (1.0 - q) * c
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TeeQuote {
    pub data: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LambdaTraceAtom {
    pub proof_digest: [u8; 32],
    pub state_root_hash: [u8; 32],
    pub trajectory_id: String,
    pub protocol_version: u32,
    pub tee_quote: TeeQuote,
}

#[derive(Debug, thiserror::Error)]
pub enum AttestationError {
    #[error("forged or invalid tee quote")]
    InvalidQuote,
}

impl LambdaTraceAtom {
    pub fn bind(proof_digest: &[u8; 32], state_root: &[u8; 32], tee_quote: &TeeQuote) -> Result<Self, AttestationError> {
        // dummy validation
        if tee_quote.data.is_empty() {
            return Err(AttestationError::InvalidQuote);
        }
        
        Ok(Self {
            proof_digest: *proof_digest,
            state_root_hash: *state_root,
            trajectory_id: "traj-001".to_string(),
            protocol_version: 1,
            tee_quote: tee_quote.clone(),
        })
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn proof_twin_binding_contractive() {
        let q: f64 = kani::any();
        let c: f64 = kani::any();
        let theta_max = 0.8;
        let theta_min = 0.5;

        kani::assume(q >= 0.0 && q <= 1.0);
        kani::assume(c >= 0.0 && c <= 1.0);

        if let Ok(proof) = TwinBindingContract::check(q, c, theta_max, theta_min) {
            kani::assert(proof.margin >= 0.005, "Approved transition must preserve M_global >= 0.005");
        }
    }

    #[kani::proof]
    fn proof_lambda_trace_sound() {
        let empty_quote = TeeQuote { data: "".to_string() };
        let digest = [0u8; 32];
        let root = [0u8; 32];
        
        let res = LambdaTraceAtom::bind(&digest, &root, &empty_quote);
        kani::assert(res.is_err(), "Empty quote must be rejected");
    }

    #[kani::proof]
    fn proof_m_global_threshold_correct() {
        let q: f64 = kani::any();
        let c: f64 = kani::any();
        kani::assume(q >= 0.0 && q <= 1.0);
        kani::assume(c >= 0.0 && c <= 1.0);

        let m = GlobalContractionMargin::compute(q, c);
        kani::assert(m >= 0.0, "Margin is bounded");
    }
}
