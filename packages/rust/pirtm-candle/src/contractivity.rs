use crate::{ContractivityReceipt, GovernanceStatus, LambdaTrace, PirtmError, Result, SedonaSpineEvaluator};

/// Configuration for the Λ_m^op(t) contractive operator.
#[derive(Debug, Clone, Copy)]
pub struct LambdaMConfig {
    pub lambda_m: f64,
    pub contraction_factor: f64,
    pub max_lip: f64,
}

impl Default for LambdaMConfig {
    fn default() -> Self {
        Self {
            lambda_m: 0.95,
            contraction_factor: 0.97,
            max_lip: 1.0,
        }
    }
}

/// The prime-indexed contractive operator Λ_m^op(t).
/// Wraps a function f and applies Λ_m scaling to ensure contractivity.
#[derive(Debug, Clone)]
pub struct LambdaMOp {
    config: LambdaMConfig,
}

impl LambdaMOp {
    pub fn new(config: LambdaMConfig) -> Self {
        Self { config }
    }

    pub fn with_defaults() -> Self {
        Self::new(LambdaMConfig::default())
    }

    pub fn config(&self) -> &LambdaMConfig {
        &self.config
    }

    /// Apply Λ_m scaling to a residual tensor value.
    /// Returns scaled value and updated zero_spacings witness.
    pub fn scale_residual(&self, residual_norm: f64, zero_spacings: &mut Vec<f64>) -> Result<f64> {
        let scaled = residual_norm * self.config.lambda_m * self.config.contraction_factor;
        let effective_lip = self.config.lambda_m * self.config.max_lip;
        
        if effective_lip >= 1.0 {
            return Err(PirtmError::ContractivityViolation(effective_lip));
        }

        zero_spacings.push(scaled);
        Ok(scaled)
    }

    /// Verify that the current configuration satisfies the contractivity bound.
    pub fn verify_contractivity(&self, lip_estimate: f64) -> Result<GovernanceStatus> {
        let effective_lip = self.config.lambda_m * lip_estimate;
        if effective_lip >= self.config.max_lip {
            return Ok(GovernanceStatus::Kill);
        }
        Ok(GovernanceStatus::Ok)
    }

    /// Build a LambdaTrace from current state.
    pub fn build_trace(
        &self,
        zero_spacings: Vec<f64>,
        lip_estimate: f64,
    ) -> Result<ContractivityReceipt> {
        let trace = LambdaTrace {
            lambda_p: self.config.lambda_m,
            l_p: lip_estimate,
            zero_spacings,
            signature: "SIGNED_HASH".to_string(),
            signer_pubkey: "ed25519:twin-prime-042".to_string(),
            proof_hash: "LEAN_PROOF_HASH_108_CORE".to_string(),
        };

        let status = SedonaSpineEvaluator::evaluate_stop_rules(&trace)?;
        let status_str = match status {
            GovernanceStatus::Ok => "OK",
            GovernanceStatus::Warn => "WARN",
            GovernanceStatus::Kill => "KILL",
        };

        let receipt = ContractivityReceipt {
            status: status_str.to_string(),
            witness_id: format!("sha256:{}", hex::encode([0u8; 32])),
            lambda_trace: trace,
        };

        Ok(receipt)
    }
}

impl LambdaMConfig {
    pub fn lambda_m(&self) -> f64 {
        self.lambda_m
    }
}
