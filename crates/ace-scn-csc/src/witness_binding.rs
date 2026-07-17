use crate::scn::KernelTelemetry;

#[derive(Debug, Clone)]
pub struct CSCWitnessBinding {
    pub h_commitment: [u8; 32],
    pub xn_kernel: f64,
    pub retention_rate: f64,
    pub max_wac_product: f64,
    pub retry_nonce: u64,
    pub cas_commitment: [u8; 32],
}

impl CSCWitnessBinding {
    pub fn bind_telemetry(
        &self,
        telemetry: &KernelTelemetry,
    ) -> Result<Self, CSCBindingError> {
        // Verify that witness fields match kernel telemetry within quantization tolerance.
        let xn_tolerance = 1e-9;
        if (self.xn_kernel - telemetry.xn_kernel).abs() > xn_tolerance {
            return Err(CSCBindingError::TelemetryMismatch {
                field: "xn_kernel",
                witness: self.xn_kernel,
                kernel: telemetry.xn_kernel,
            });
        }
        // Similar checks for other fields could go here...
        Ok(Self {
            xn_kernel: telemetry.xn_kernel,
            ..self.clone()
        })
    }
}

#[derive(Debug, thiserror::Error, PartialEq)]
pub enum CSCBindingError {
    #[error("telemetry mismatch on {field}: witness={witness}, kernel={kernel}")]
    TelemetryMismatch { field: &'static str, witness: f64, kernel: f64 },
    #[error("constraint budget exceeded: {0} > 5087")]
    ConstraintBudgetExceeded(usize),
    #[error("Poseidon2 topology violation")]
    Poseidon2TopologyViolation,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_bind_telemetry_success() {
        let kt = KernelTelemetry {
            xn_kernel: 0.1,
            wt_max_kernel: 0.2,
            protection_zeta: 0.3,
            is_valid_kernel: true,
            telemetry_version: 1,
        };
        let witness = CSCWitnessBinding {
            h_commitment: [0; 32],
            xn_kernel: 0.1,
            retention_rate: 0.5,
            max_wac_product: 0.8,
            retry_nonce: 0,
            cas_commitment: [0; 32],
        };
        assert!(witness.bind_telemetry(&kt).is_ok());
    }

    #[test]
    fn test_bind_telemetry_failure() {
        let kt = KernelTelemetry {
            xn_kernel: 0.1,
            wt_max_kernel: 0.2,
            protection_zeta: 0.3,
            is_valid_kernel: true,
            telemetry_version: 1,
        };
        let witness = CSCWitnessBinding {
            h_commitment: [0; 32],
            xn_kernel: 0.2, // mismatch
            retention_rate: 0.5,
            max_wac_product: 0.8,
            retry_nonce: 0,
            cas_commitment: [0; 32],
        };
        assert!(matches!(
            witness.bind_telemetry(&kt),
            Err(CSCBindingError::TelemetryMismatch { .. })
        ));
    }
}
