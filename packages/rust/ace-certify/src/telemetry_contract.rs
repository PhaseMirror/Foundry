use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct BeatSpectrumStats {
    pub peak_frequencies: Vec<f64>,
    pub mean_spacing: f64,
    pub level_repulsion_dip: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct KernelTelemetry {
    pub xn_kernel: f64,
    pub wt_max_kernel: f64,
    pub protection_zeta: f64,
    pub is_valid_kernel: bool,
    pub telemetry_version: u32,
    pub beat_spectrum_stats: BeatSpectrumStats,
    pub gue_deviation: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ACECertificate {
    pub theta: Vec<u8>,
    pub xn_kernel: f64,
    pub wt_max_kernel: f64,
    pub protection_zeta: f64,
    pub is_valid_kernel: u8,
    pub telemetry_version: u32,
    pub outputs: Vec<u8>,
}

impl ACECertificate {
    pub fn from_telemetry(theta: &[u8], telemetry: KernelTelemetry, outputs: &[u8]) -> Self {
        Self {
            theta: theta.to_vec(),
            xn_kernel: telemetry.xn_kernel,
            wt_max_kernel: telemetry.wt_max_kernel,
            protection_zeta: telemetry.protection_zeta,
            is_valid_kernel: telemetry.is_valid_kernel as u8,
            telemetry_version: telemetry.telemetry_version,
            outputs: outputs.to_vec(),
        }
    }

    pub fn validate_schema(&self) -> Result<(), CertificateSchemaError> {
        match self.telemetry_version {
            1 | 2 => {
                if self.theta.is_empty() || self.outputs.is_empty() {
                    return Err(CertificateSchemaError::EmptyField);
                }
                Ok(())
            }
            v => Err(CertificateSchemaError::UnsupportedVersion(v)),
        }
    }
}

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum CertificateSchemaError {
    #[error("unsupported telemetry version: {0}")]
    UnsupportedVersion(u32),
    #[error("empty required field in certificate")]
    EmptyField,
}
