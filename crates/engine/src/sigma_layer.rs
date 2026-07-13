use std::collections::HashMap;
use thiserror::Error;

/// The threshold mandated by the Sedona Spine Architectural Matrix
const SEDONA_CONTRACTION_MARGIN: f64 = 1.0 - 1e-6;

#[derive(Debug, Error)]
pub enum CertificationError {
    #[error("ZM Contractivity Violation: rho {rho} exceeds margin {margin}")]
    ContractivityViolation { rho: f64, margin: f64 },
    #[error("Missing ZM metrics for prime {0}")]
    MissingPrimeMetric(u64),
}

/// Represents the Zero-Mode structural quantities for a given state
#[derive(Debug, Clone)]
pub struct ZeroModeQuantities {
    /// The base skeleton magnitude: |Xi(t)|
    pub xi_magnitude: f64,
    /// Lipschitz constant of the tensor map: L_T
    pub lipschitz_t: f64,
    /// Active prime channels and their absolute weights: |lambda_p(t)|
    pub prime_weights: HashMap<u64, f64>,
}

impl ZeroModeQuantities {
    /// Computes the effective ZM gain bound: G_ZM(t) = L_T * sum(|lambda_p|)
    pub fn compute_zm_gain(&self) -> f64 {
        let sum_lambda: f64 = self.prime_weights.values().sum();
        self.lipschitz_t * sum_lambda
    }

    /// Computes the total contractivity ratio rho
    pub fn compute_rho(&self) -> f64 {
        self.xi_magnitude + self.compute_zm_gain()
    }
}

/// The certification gate that will be integrated into the main engine
pub fn certify_state(zm_quantities: &ZeroModeQuantities) -> Result<(), CertificationError> {
    let rho = zm_quantities.compute_rho();
    
    if rho >= SEDONA_CONTRACTION_MARGIN {
        return Err(CertificationError::ContractivityViolation {
            rho,
            margin: SEDONA_CONTRACTION_MARGIN,
        });
    }
    
    // Additional policy checks can be wired here (e.g. tracking inert policies)
    
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_zm_certification_fails_on_margin_breach() {
        // Setup an adversarial ZM state that pushes rho over 1.0 - 1e-6
        let mut prime_weights = HashMap::new();
        prime_weights.insert(2, 0.05);
        prime_weights.insert(3, 0.05);
        
        let adversarial_zm = ZeroModeQuantities {
            xi_magnitude: 0.90,     // Base skeleton
            lipschitz_t: 1.0,       // L_T
            prime_weights,          // Sum = 0.10. Total rho = 0.90 + 0.10 = 1.0
        };

        // This MUST return a ContractivityViolation
        let result = certify_state(&adversarial_zm);
        
        assert!(
            matches!(result, Err(CertificationError::ContractivityViolation { .. })),
            "Expected ContractivityViolation, but got {:?}", 
            result
        );
    }
}

/// Trait to securely extract Zero-Mode quantities from upstream operator states
pub trait ZeroModeExtractable {
    /// Consumes the current state/word and safely projects its metrics into ZM space
    fn extract_zm_quantities(&self) -> Result<ZeroModeQuantities, CertificationError>;
}
