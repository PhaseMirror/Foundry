use serde::{Deserialize, Serialize};
use crate::{ContractivityReceipt, GovernanceStatus, PirtmError, Result};

/// Per-generation-step witness capturing spectral arrays and drift.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenerationWitness {
    pub step: usize,
    pub token_id: u32,
    pub residual_norm: f64,
    pub scaled_norm: f64,
    pub zero_spacings: Vec<f64>,
    pub lambda_p: f64,
    pub l_p: f64,
    pub contractivity_status: String,
    pub timestamp_ns: u128,
}

/// Emits witnesses for every generation step, enforcing L0 bounds.
#[derive(Debug, Clone)]
pub struct WitnessEmitter {
    lambda_op: crate::contractivity::LambdaMOp,
    max_steps: usize,
}

impl WitnessEmitter {
    pub fn new(lambda_op: crate::contractivity::LambdaMOp, max_steps: usize) -> Self {
        Self { lambda_op, max_steps }
    }

    pub fn with_defaults() -> Self {
        Self::new(crate::contractivity::LambdaMOp::with_defaults(), 512)
    }

    /// Emit a witness for a single generation step.
    /// Returns Err if contractivity is violated.
    pub fn emit_step(
        &mut self,
        step: usize,
        token_id: u32,
        residual_norm: f64,
        zero_spacings: &mut Vec<f64>,
        lip_estimate: f64,
    ) -> Result<GenerationWitness> {
        if step >= self.max_steps {
            return Err(PirtmError::WitnessError("Max generation steps exceeded".into()));
        }

        let scaled_norm = self.lambda_op.scale_residual(residual_norm, zero_spacings)?;
        let status = self.lambda_op.verify_contractivity(lip_estimate)?;
        let status_str = match status {
            GovernanceStatus::Ok => "OK",
            GovernanceStatus::Warn => "WARN",
            GovernanceStatus::Kill => "KILL",
        };

        Ok(GenerationWitness {
            step,
            token_id,
            residual_norm,
            scaled_norm,
            zero_spacings: zero_spacings.clone(),
            lambda_p: self.lambda_op.config().lambda_m,
            l_p: lip_estimate,
            contractivity_status: status_str.to_string(),
            timestamp_ns: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| d.as_nanos())
                .unwrap_or(0),
        })
    }

    /// Finalize emission and produce a ContractivityReceipt.
    pub fn finalize(&self, zero_spacings: Vec<f64>, lip_estimate: f64) -> Result<ContractivityReceipt> {
        self.lambda_op.build_trace(zero_spacings, lip_estimate)
    }
}
