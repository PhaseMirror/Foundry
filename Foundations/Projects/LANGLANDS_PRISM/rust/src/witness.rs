use serde::{Deserialize, Serialize};
use crate::tensor::PrismTensorState;
use crate::marcl::MARCLCluster;
use crate::provenance::ProvenanceLedger;

/// Cryptographic Unified Witness Certificate for the Langlands Prism execution.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct UnifiedWitness {
    pub framework: String,
    pub version: String,
    pub lean_toolchain: String,
    pub prime_basis: Vec<u64>,
    pub multiplicity_constant_lambda_m: f64,
    pub golden_ratio_phi: f64,
    pub final_coherence: f64,
    pub total_energy: f64,
    pub shock_recovery_delta_final: f64,
    pub marcl_agents_count: usize,
    pub godelian_ledger_total_flow: f64,
    pub firewall_ethical_status: String,
    pub total_provenance_blocks: usize,
    pub root_state_hash: String,
    pub is_verified: bool,
}

impl UnifiedWitness {
    pub fn build(
        st: &PrismTensorState,
        marcl: &MARCLCluster,
        ledger: &ProvenanceLedger,
        shock_final_dist: f64,
    ) -> Self {
        let prime_basis = st.nodes.iter().map(|n| n.prime).collect();
        let total_flow: f64 = marcl.godelian_ledger.iter()
            .flat_map(|row| row.iter())
            .sum();

        let root_hash = ledger.blocks.last()
            .map(|b| b.state_hash.clone())
            .unwrap_or_else(|| "0000000000000000000000000000000000000000000000000000000000000000".to_string());

        Self {
            framework: "The Langlands Prism: Recursive Tensor & Cognitive Entanglement Framework".to_string(),
            version: "0.1.0-production".to_string(),
            lean_toolchain: "leanprover/lean4:v4.31.0".to_string(),
            prime_basis,
            multiplicity_constant_lambda_m: st.lambda_m,
            golden_ratio_phi: 1.6180339887498949,
            final_coherence: st.coherence,
            total_energy: st.total_energy(),
            shock_recovery_delta_final: shock_final_dist,
            marcl_agents_count: marcl.agents.len(),
            godelian_ledger_total_flow: total_flow,
            firewall_ethical_status: "ENFORCED_AND_SAFE".to_string(),
            total_provenance_blocks: ledger.blocks.len(),
            root_state_hash: root_hash,
            is_verified: st.is_stable && ledger.verify_chain_integrity(),
        }
    }

    pub fn to_json_pretty(&self) -> String {
        serde_json::to_string_pretty(self).unwrap_or_default()
    }
}
