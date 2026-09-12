use anyhow::{Result, Context};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ResonanceBufferState {
    pub session_id: String,
    pub proposed_weight: u64,
    pub schema_hash: String,
    pub permission_bits: u32,
}

pub struct L0VerificationGate {
    pub expected_schema_hash: String,
    pub required_permission_bits: u32,
}

impl L0VerificationGate {
    pub fn new(expected_schema_hash: &str, required_permission_bits: u32) -> Self {
        Self {
            expected_schema_hash: expected_schema_hash.to_string(),
            required_permission_bits,
        }
    }

    /// Verifies the Resonance Buffer state against L0 invariants.
    /// Returns Ok(()) if the state is lawful, otherwise returns an Error (SIG_GOV_KILL).
    pub fn verify_state(&self, state: &ResonanceBufferState) -> Result<()> {
        // 1. Schema Hash Validation
        if state.schema_hash != self.expected_schema_hash {
            anyhow::bail!(
                "SIG_GOV_KILL: Schema hash mismatch. Expected {}, found {}",
                self.expected_schema_hash, state.schema_hash
            );
        }

        // 2. Permission Bits Validation
        if (state.permission_bits & self.required_permission_bits) != self.required_permission_bits {
            anyhow::bail!(
                "SIG_GOV_KILL: Permission bits rejected. Required {}, found {}",
                self.required_permission_bits, state.permission_bits
            );
        }

        // 3. Prime-Indexed Provenance Checks
        // We enforce that the state weight contains Governance (P3) and Attestation (P5)
        // according to the GIK pirtm-dialect schema.
        if state.proposed_weight % 3 != 0 {
            anyhow::bail!("SIG_GOV_KILL: Missing Governance Prime (P3). Operation lacks mechanism constraints.");
        }

        if state.proposed_weight % 5 != 0 {
            anyhow::bail!("SIG_GOV_KILL: Missing Attestation Prime (P5). Operation lacks witness trace.");
        }

        // State is L0-lawful.
        Ok(())
    }
}
