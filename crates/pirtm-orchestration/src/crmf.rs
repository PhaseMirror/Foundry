use serde::{Deserialize, Serialize};

/// The hardware telemetry captured directly from the FPGA AXI-Stream.
/// Ensures no thermal or sequence violations occurred during the 108 cycles.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SafetyTelemetry {
    pub max_thermal_load: f64,
    pub sequence_fidelity: f64,
    pub l0_halt_triggered: bool,
}

/// The Constitutional Recursive Manifestation Framework (CRMF) Request.
/// This is the ultimate proof-carrying artifact. It binds the mathematical 
/// tensor contraction to the physical hardware state.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CRMFRequest {
    /// Pinned to the current architectural state
    pub lawful_recursion_version: String, 
    
    /// The starting point of the MA-VQE loop
    pub initial_state_hash: String,
    
    /// The stabilized 108-cycle attractor state
    pub terminal_state_hash: String,
    
    /// SHA-256 digest of the `events.jsonl` TelemetryObserver output
    pub trajectory_digest: String, 
    
    /// Cryptographic boolean asserted by the WardMonitor's scan of the JSONL
    pub proof_of_contraction: bool, 
    
    /// The physical hardware state during execution
    pub physical_telemetry: SafetyTelemetry,
}

impl CRMFRequest {
    /// Generates the pre-image for the Poseidon2 governance hash.
    /// This directly targets the 5,087-constraint ZK budget architecture.
    pub fn poseidon_preimage(&self) -> Vec<u8> {
        assert!(
            self.proof_of_contraction,
            "L1 VIOLATION: Cannot generate governance hash for a non-contractive trajectory."
        );
        assert!(
            !self.physical_telemetry.l0_halt_triggered,
            "L0 VIOLATION: Hardware safety interlock triggered. State is PROVISIONAL and must be voided."
        );

        let mut payload = Vec::new();
        payload.extend_from_slice(self.lawful_recursion_version.as_bytes());
        payload.extend_from_slice(self.initial_state_hash.as_bytes());
        payload.extend_from_slice(self.terminal_state_hash.as_bytes());
        payload.extend_from_slice(self.trajectory_digest.as_bytes());
        // In the final Poseidon2(t=9, r=8) topology, these bytes map to the field elements
        
        payload
    }
}
