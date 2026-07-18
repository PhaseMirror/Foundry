use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum PirtmError {
    #[error("Dimension mismatch: expected {expected}, found {found}")]
    DimensionMismatch { expected: usize, found: usize },
    #[error("Contractivity violation: bound {bound} >= gamma {gamma}")]
    ContractivityViolation { bound: f64, gamma: f64 },
    #[error("Invalid parameter: {0}")]
    InvalidParameter(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MultiplicityParams {
    pub version: String,
    pub prime_set: Vec<u64>,
    pub scales: [u32; 4],
    pub q: u64,
    pub alpha: f64,
    pub lambda_m: f64,
    pub gamma: f64,
    pub noise_type: String,
    pub noise_k: u32,
    #[serde(default = "default_scales_version")]
    pub scales_version: String,
}

fn default_scales_version() -> String {
    "v1".to_string()
}



pub mod audit;
pub mod audit_api;
pub mod certify;
pub mod csc;
pub mod csl;
pub mod csl_gate;
pub mod gate;
pub mod gate_k;
pub mod hoe_router;


pub mod linker;
pub mod jubilee;
pub mod mlir_emitter;
pub mod orchestrator;
pub mod petc;
pub mod projection;
pub mod qari;
pub mod recurrence;
pub mod rta;
pub mod serialization;
pub mod session_graph_op;
pub mod spectral;




pub mod weights;
pub mod witness;

pub use audit::AuditChain;
pub use certify::{ace_certificate, iss_bound};
pub use csc::{compute_margin, multi_step_margin, sensitivity, solve_budget};
pub use csl::evaluate_csl;
pub use csl_gate::CSLEmissionGate;
pub use gate::{gated_run, EmissionGate, EmissionPolicy};
pub use hoe_router::{EscalationDecision, HoERouter};
pub use lambda_bridge::LambdaTraceBridge;
pub use linker::{
    CouplingConfig, GovernanceSeal, ModuleInput, ModuleMetadata, PIRTMBytecode,
    PirtmLinkWithEnsemble, SessionSpec,
};
pub use orchestrator::SessionOrchestrator;
pub use petc::{infinite_prime_check, PETCLedger};
pub use qari::{QARIConfig, QARISession};
pub use recurrence::{fixed_point_estimate, run, step};
pub use rta::*;
pub use serialization::{
    compute_proof_hash, PIRTMGovernanceSection, PIRTMProofSection, PIRTMRuntime,
};
pub use session_graph_op::SessionGraphOp;
pub use spectral::SpectralGovernor;
pub use spectral::{GershgorinCertificate, GershgorinDisk, SpectralMetrics};
pub use telemetry::{FileSink, MemorySink, Monitor, TelemetryBus, TelemetrySink};
pub use types::*;
pub use weights::{synthesize_weights, validate_schedule, WeightProfile};

#[cfg(test)]
mod tests {
    #[test]
    fn test_csl_gate_basic() {
        use crate::gate_k::CSLGate;
        use crate::types::StepInfo;

        let gate = CSLGate::new(10.0);
        let info = StepInfo {
            step: 0,
            q: 1.0,
            epsilon: 0.05,
            n_xi: 0.8,
            n_lam: 0.1,
            projected: false,
            residual: 0.01,
            note: None,
            resonance_word: None,
            prime_mask: None,
        };

        assert!(gate.check(&info));
    }

    #[test]
    fn test_rate_limiter_convergence() {
        use crate::gate_k::RateLimiter;

        let mut rl = RateLimiter::new(10, 1.1);
        assert!(rl.push(1.0));
        assert!(rl.push(1.05));
    }
}
pub mod adaptive;
pub mod galois;
pub mod gates;
pub mod langlands_zk;
pub mod lambda_bridge;
pub mod telemetry;
pub mod types;
pub mod uac_loss;
pub mod r1cs_constants;
pub mod telemetry_binding;
pub mod tether_policy;
