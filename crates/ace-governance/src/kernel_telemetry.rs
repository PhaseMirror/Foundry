use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KernelTelemetry {
    pub xn_kernel: f64,
    pub wt_max_kernel: f64,
    pub protection_zeta: f64,
    pub is_valid_kernel: bool,
    pub telemetry_version: u32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TelemetrySource {
    LegacyACE,
    PhaseMirrorKernel,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StepState {
    pub xn: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ACECertificate {
    pub xn_kernel: f64,
    pub wt_max_kernel: f64,
    pub protection_zeta: f64,
    pub is_valid_kernel: bool,
    pub telemetry_version: u32,
    pub outputs: Vec<u8>,
}

pub struct LegacyDriftEngine;

impl LegacyDriftEngine {
    pub fn new() -> Self { Self }
    pub fn compute_xn(&self, state: &StepState) -> f64 {
        state.xn
    }
}

pub mod zeno {
    use super::*;
    pub fn compute_kernel_telemetry(state: &StepState) -> Result<KernelTelemetry, GovernanceError> {
        Ok(KernelTelemetry {
            xn_kernel: state.xn,
            wt_max_kernel: 0.0,
            protection_zeta: 0.0,
            is_valid_kernel: true,
            telemetry_version: 1,
        })
    }
}

pub struct ACEGovernanceLayer {
    pub source: TelemetrySource,
    pub parity_mode: bool,
    pub legacy_drift_logic: Option<LegacyDriftEngine>,
}

impl ACEGovernanceLayer {
    pub fn new(source: TelemetrySource, parity_mode: bool) -> Self {
        Self {
            source,
            parity_mode,
            legacy_drift_logic: if parity_mode {
                Some(LegacyDriftEngine::new())
            } else {
                None
            },
        }
    }

    pub fn get_drift_metrics(&self, step_state: &StepState) -> Result<KernelTelemetry, GovernanceError> {
        match self.source {
            TelemetrySource::PhaseMirrorKernel => {
                let kt = zeno::compute_kernel_telemetry(step_state)?;
                if self.parity_mode {
                    if let Some(ref legacy) = self.legacy_drift_logic {
                        let legacy_xn = legacy.compute_xn(step_state);
                        if (legacy_xn - kt.xn_kernel).abs() >= 1e-9 {
                            return Err(GovernanceError::ParityViolation);
                        }
                    }
                }
                Ok(kt)
            }
            TelemetrySource::LegacyACE => Err(GovernanceError::DeprecatedAuthority),
        }
    }

    pub fn certificate_payload(&self, telemetry: KernelTelemetry, outputs: &[u8]) -> ACECertificate {
        ACECertificate {
            xn_kernel: telemetry.xn_kernel,
            wt_max_kernel: telemetry.wt_max_kernel,
            protection_zeta: telemetry.protection_zeta,
            is_valid_kernel: telemetry.is_valid_kernel,
            telemetry_version: telemetry.telemetry_version,
            outputs: outputs.to_vec(),
        }
    }
}

#[derive(Debug, thiserror::Error)]
pub enum GovernanceError {
    #[error("Legacy ACE authority is deprecated; use PhaseMirrorKernel")]
    DeprecatedAuthority,
    #[error("Kernel telemetry computation failed: {0}")]
    KernelTelemetryError(String),
    #[error("Parity mode assertion failed")]
    ParityViolation,
}
