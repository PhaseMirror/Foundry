/// Core dataclasses for the ACE protocol as defined in IFMD v0.1.
/// Rust port of src/ace/types.py with mathematical parity guarantees.

use serde::{Deserialize, Serialize};
use std::fmt;

/// Stage 1 Physical/Biological Commitments
/// 
/// Frozen dataclass equivalent with strict L0 invariants from IFMD v0.1.
/// All fields immutable after construction via validation.
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
pub struct ThetaBase {
    pub epsilon: f64,
    pub supp_epsilon: f64,        // Independent WHT spectral noise floor threshold
    pub delta: f64,
    pub n_0: i32,                  // N_0 in Python
    pub k: i32,                    // K in Python
    pub m: i32,                    // M in Python
    pub beta: f64,
    pub tau_min: f64,
    pub alpha_m: f64,              // alpha_M in Python
    pub retry_nonce: i32,
    pub wac_mode: WacMode,
}

/// WAC (Window Accumulator Channel) operating mode
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum WacMode {
    /// Strict mode: M >= 1
    Strict,
    /// Windowed mode: M >= 2 (default)
    Windowed,
}

impl fmt::Display for WacMode {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            WacMode::Strict => write!(f, "strict"),
            WacMode::Windowed => write!(f, "windowed"),
        }
    }
}

impl ThetaBase {
    /// Construct ThetaBase with strict L0 invariant validation.
    ///
    /// # Invariants (IFMD v0.1)
    /// - `0 < beta < 1` (holdout split must be proper fraction)
    /// - `tau_min > 0` (governor guard strictly positive)
    /// - `0 < epsilon < 1` (contraction gap in valid range)
    /// - `0 < supp_epsilon < 1` (spectral noise threshold in valid range)
    /// - If `wac_mode == Strict`: `M >= 1`
    /// - If `wac_mode == Windowed`: `M >= 2`
    /// - `retry_nonce >= 0`
    ///
    /// # Errors
    /// Returns descriptive error if any invariant violated.
    pub fn new(
        epsilon: f64,
        supp_epsilon: f64,
        delta: f64,
        n_0: i32,
        k: i32,
        m: i32,
        beta: f64,
        tau_min: f64,
        alpha_m: f64,
        retry_nonce: i32,
        wac_mode: WacMode,
    ) -> Result<Self, String> {
        // Holdout split validation
        if !(0.0 < beta && beta < 1.0) {
            return Err(format!(
                "Holdout split beta must be in (0, 1), got {}",
                beta
            ));
        }

        // WAC mode M validation
        match wac_mode {
            WacMode::Strict => {
                if m < 1 {
                    return Err(format!(
                        "Strict WAC mode requires M >= 1, got {}",
                        m
                    ));
                }
            }
            WacMode::Windowed => {
                if m < 2 {
                    return Err(format!(
                        "Windowed WAC mode requires M >= 2, got {}",
                        m
                    ));
                }
            }
        }

        // Governor guard validation
        if tau_min <= 0.0 {
            return Err(format!(
                "Governor guard tau_min must be positive, got {}",
                tau_min
            ));
        }

        // Retry nonce validation
        if retry_nonce < 0 {
            return Err("retry_nonce cannot be negative".to_string());
        }

        // Contraction gap epsilon validation
        if !(0.0 < epsilon && epsilon < 1.0) {
            return Err("Contraction gap epsilon must be in (0, 1)".to_string());
        }

        // Spectral noise threshold validation
        if !(0.0 < supp_epsilon && supp_epsilon < 1.0) {
            return Err(
                "Spectral noise threshold supp_epsilon must be in (0, 1)".to_string(),
            );
        }

        Ok(ThetaBase {
            epsilon,
            supp_epsilon,
            delta,
            n_0,
            k,
            m,
            beta,
            tau_min,
            alpha_m,
            retry_nonce,
            wac_mode,
        })
    }

    /// Unsafe construction bypassing validation (for testing/deserialization only).
    pub fn unchecked(
        epsilon: f64,
        supp_epsilon: f64,
        delta: f64,
        n_0: i32,
        k: i32,
        m: i32,
        beta: f64,
        tau_min: f64,
        alpha_m: f64,
        retry_nonce: i32,
        wac_mode: WacMode,
    ) -> Self {
        ThetaBase {
            epsilon,
            supp_epsilon,
            delta,
            n_0,
            k,
            m,
            beta,
            tau_min,
            alpha_m,
            retry_nonce,
            wac_mode,
        }
    }
}

/// Stage 3 Final Registry Bundle
///
/// Contains the validated base configuration plus the deterministic
/// Fiat-Shamir derived shuffle seed for CAS registry derivation.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ThetaC6 {
    pub base: ThetaBase,
    pub shuffle_seed: Vec<u8>,
}

impl ThetaC6 {
    /// Construct ThetaC6 from validated base and seed bytes.
    pub fn new(base: ThetaBase, shuffle_seed: Vec<u8>) -> Self {
        ThetaC6 { base, shuffle_seed }
    }
}

/// Diagnostic information emitted by the recurrence loop per IFMD §6.
///
/// Each step of the three-split protocol generates one StepInfo record
/// containing convergence, trajectory, and validation metrics.
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
pub struct StepInfo {
    pub step: i32,
    pub q: f64,                  // Contraction metric
    pub epsilon: f64,            // Current epsilon threshold
    pub kkt_residual: f64,       // KKT condition residual
    pub wac_product: f64,        // Windowed accumulator channel product
    pub xi_telemetry: f64,       // Spectral isolation metric
    pub delta_sigma: f64,        // Burn-in drift
    pub delta_m: f64,            // Holdout drift
    pub projected: bool,         // Whether step was projected
    pub residual: f64,           // Final trajectory residual
}

impl StepInfo {
    /// Construct StepInfo with all diagnostic fields.
    pub fn new(
        step: i32,
        q: f64,
        epsilon: f64,
        kkt_residual: f64,
        wac_product: f64,
        xi_telemetry: f64,
        delta_sigma: f64,
        delta_m: f64,
        projected: bool,
        residual: f64,
    ) -> Self {
        StepInfo {
            step,
            q,
            epsilon,
            kkt_residual,
            wac_product,
            xi_telemetry,
            delta_sigma,
            delta_m,
            projected,
            residual,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_theta_base_valid_windowed() {
        let result = ThetaBase::new(
            0.5,    // epsilon
            0.05,   // supp_epsilon
            1.0,    // delta
            100,    // n_0
            10,     // k
            2,      // m (minimum for windowed)
            0.8,    // beta
            0.1,    // tau_min
            0.95,   // alpha_m
            0,      // retry_nonce
            WacMode::Windowed,
        );
        assert!(result.is_ok());
    }

    #[test]
    fn test_theta_base_valid_strict() {
        let result = ThetaBase::new(
            0.5, 0.05, 1.0, 100, 10, 1, 0.8, 0.1, 0.95, 0, WacMode::Strict,
        );
        assert!(result.is_ok());
    }

    #[test]
    fn test_theta_base_invalid_beta_zero() {
        let result = ThetaBase::new(
            0.5, 0.05, 1.0, 100, 10, 2, 0.0, 0.1, 0.95, 0, WacMode::Windowed,
        );
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("beta"));
    }

    #[test]
    fn test_theta_base_invalid_epsilon() {
        let result = ThetaBase::new(
            0.0, 0.05, 1.0, 100, 10, 2, 0.8, 0.1, 0.95, 0, WacMode::Windowed,
        );
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("epsilon"));
    }

    #[test]
    fn test_theta_base_windowed_m_too_small() {
        let result = ThetaBase::new(
            0.5, 0.05, 1.0, 100, 10, 1, 0.8, 0.1, 0.95, 0, WacMode::Windowed,
        );
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("Windowed"));
    }

    #[test]
    fn test_theta_base_strict_m_valid() {
        let result = ThetaBase::new(
            0.5, 0.05, 1.0, 100, 10, 1, 0.8, 0.1, 0.95, 0, WacMode::Strict,
        );
        assert!(result.is_ok());
    }

    #[test]
    fn test_theta_c6_serialization() {
        let base = ThetaBase::new(
            0.5, 0.05, 1.0, 100, 10, 2, 0.8, 0.1, 0.95, 0, WacMode::Windowed,
        )
        .unwrap();
        let seed = vec![1, 2, 3, 4, 5];
        let tc6 = ThetaC6::new(base, seed.clone());

        let json = serde_json::to_string(&tc6).unwrap();
        let deserialized: ThetaC6 = serde_json::from_str(&json).unwrap();

        assert_eq!(deserialized.base, base);
        assert_eq!(deserialized.shuffle_seed, seed);
    }

    #[test]
    fn test_step_info_construction() {
        let step = StepInfo::new(
            1,      // step
            0.95,   // q
            0.5,    // epsilon
            1e-6,   // kkt_residual
            0.98,   // wac_product
            0.01,   // xi_telemetry
            0.002,  // delta_sigma
            0.003,  // delta_m
            false,  // projected
            1e-7,   // residual
        );

        assert_eq!(step.step, 1);
        assert_eq!(step.q, 0.95);
        assert!((step.residual - 1e-7).abs() < 1e-10);
    }
}
