use std::sync::atomic::{AtomicU64, Ordering};
use serde::Serialize;

#[derive(Debug, Default, Clone, Serialize)]
pub struct TelemetryMetrics {
    pub rho: f64,
    pub delta: f64,
    pub lambda_l_product: f64,
    pub op_count: u64,
}

// Global metric counters.
static OP_COUNT: AtomicU64 = AtomicU64::new(0);

pub fn simulate_telemetry_collection() -> TelemetryMetrics {
    TelemetryMetrics {
        rho: 0.1,
        delta: 1e-6,
        lambda_l_product: 0.5,
        op_count: OP_COUNT.load(Ordering::SeqCst) + 10, // Simulated operations
    }
}

pub fn collect_execution_metrics(stdout_len: usize, stderr_len: usize, return_code: i32) -> TelemetryMetrics {
    TelemetryMetrics {
        rho: if return_code == 0 { 0.0 } else { 1.1 },
        delta: 1e-6,
        lambda_l_product: 0.5,
        op_count: (stdout_len + stderr_len) as u64,
    }
}
