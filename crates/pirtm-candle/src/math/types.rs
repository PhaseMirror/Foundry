use serde::{Deserialize, Serialize};

pub use goldilocks::{AtomicPrime, PirtmModulus, PrimeMask, ResonanceWord, SquarefreeComposite};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StepInfo {
    pub step: usize,
    pub q: f64,
    pub epsilon: f64,
    pub n_xi: f64,
    pub n_lam: f64,
    pub projected: bool,
    pub residual: f64,
    pub note: Option<String>,
    pub resonance_word: Option<ResonanceWord>,
    pub prime_mask: Option<PrimeMask>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Status {
    pub converged: bool,
    pub safe: bool,
    pub steps: usize,
    pub residual: f64,
    pub epsilon: f64,
    pub note: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Certificate {
    pub certified: bool,
    pub margin: f64,
    pub tail_bound: f64,
    pub details: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PETCReport {
    pub satisfied: bool,
    pub chain_length: usize,
    pub coverage: f64,
    pub gap_violations: Vec<(u64, u64)>,
    pub monotonic: bool,
    pub violations: Vec<u64>,
    pub primes_checked: Vec<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PETCEntry<T> {
    pub prime: u64,
    pub event: Option<T>,
    pub info: Option<StepInfo>,
    pub timestamp: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MonitorRecord {
    pub step: usize,
    pub info: StepInfo,
    pub status: Option<Status>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeightSchedule {
    pub xi_seq: Vec<nalgebra::DMatrix<f64>>,
    pub lam_seq: Vec<nalgebra::DMatrix<f64>>,
    pub q_targets: Vec<f64>,
    pub primes_used: Vec<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CSCBudget {
    pub xi_norm_max: f64,
    pub lam_norm_max: f64,
    pub q_star: f64,
    pub epsilon: f64,
    pub op_norm_t: f64,
    pub alpha: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CSCMargin {
    pub margin: f64,
    pub q_actual: f64,
    pub q_target: f64,
    pub t_headroom: f64,
    pub epsilon_headroom: f64,
    pub safe: bool,
}
