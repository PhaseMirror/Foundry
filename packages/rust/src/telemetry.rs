use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BeatSpectrumStats {
    pub peak_frequencies: Vec<f64>,
    pub mean_spacing: f64,
    pub level_repulsion_dip: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KernelTelemetry {
    pub xn_kernel: f64,
    pub wt_max_kernel: f64,
    pub protection_zeta: f64,
    pub is_valid_kernel: bool,
    pub zeta_shadow: f64,
    pub first_zero_approx: f64,
    pub beat_spectrum_stats: BeatSpectrumStats,
    pub gue_deviation: f64,
    pub telemetry_version: u32,
}
