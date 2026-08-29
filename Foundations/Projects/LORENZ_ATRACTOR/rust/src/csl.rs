use serde::{Deserialize, Serialize};
use crate::core::{LorenzState, LorenzParams};
use crate::jacobian::Jacobian3D;

/// Configuration for Cognitive Sovereign Logic (CSL) fail-closed invariants.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CSLConstraintConfig {
    pub max_allowed_coordinate: f64,
    pub max_allowed_velocity: f64,
    pub min_dissipation_rate: f64,
    pub allow_non_monotonic_stability: bool,
}

impl Default for CSLConstraintConfig {
    fn default() -> Self {
        Self {
            max_allowed_coordinate: 150.0,
            max_allowed_velocity: 1000.0,
            min_dissipation_rate: 0.1,
            allow_non_monotonic_stability: false,
        }
    }
}

/// Result of CSL invariant verification for a state transition.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CSLValidationResult {
    pub is_lawful: bool,
    pub reason: String,
    pub witness_digest: String,
}

impl CSLValidationResult {
    pub fn success() -> Self {
        Self {
            is_lawful: true,
            reason: "All Multiplicity CSL constraints satisfied lawfully".to_string(),
            witness_digest: "CSL_WITNESS_VERIFIED_STABLE".to_string(),
        }
    }

    pub fn failure(reason: &str, digest: &str) -> Self {
        Self {
            is_lawful: false,
            reason: reason.to_string(),
            witness_digest: digest.to_string(),
        }
    }
}

/// CSL Gatekeeper: Validates all physical and formal invariants on state transition.
///
/// Fail-closed semantics: Any violation immediately marks the state unlawful.
pub fn validate_csl_transition(
    config: &CSLConstraintConfig,
    st_prev: &LorenzState,
    st_curr: &LorenzState,
    params: &LorenzParams,
) -> CSLValidationResult {
    // Invariant 1: Temporal monotonicity
    if st_curr.time != st_prev.time + 1 {
        return CSLValidationResult::failure(
            "Temporal progression broken: st_curr.time != st_prev.time + 1",
            "ERR_CSL_TEMPORAL_NON_MONOTONIC",
        );
    }

    // Invariant 2: Bounding domain confinement
    let p = &st_curr.point;
    if p.x.abs() > config.max_allowed_coordinate
        || p.y.abs() > config.max_allowed_coordinate
        || p.z.abs() > config.max_allowed_coordinate
    {
        return CSLValidationResult::failure(
            "Phase space coordinate exceeded maximum allowable compact domain",
            "ERR_CSL_DOMAIN_OVERFLOW",
        );
    }

    // Invariant 3: Velocity boundedness
    if st_curr.velocity.norm() > config.max_allowed_velocity {
        return CSLValidationResult::failure(
            "Phase space velocity exceeded stability ceiling",
            "ERR_CSL_VELOCITY_CEILING_BREACH",
        );
    }

    // Invariant 4: Dissipative contraction rate Tr(J) < 0
    let trace = Jacobian3D::theoretical_trace(params);
    if trace > -config.min_dissipation_rate {
        return CSLValidationResult::failure(
            "Jacobian trace does not guarantee strictly dissipative volume contraction",
            "ERR_CSL_NON_DISSIPATIVE_REGIME",
        );
    }

    // Invariant 5: Stability functional monotonicity S(t+1) >= S(t)
    if !config.allow_non_monotonic_stability && st_curr.stability_integral < st_prev.stability_integral {
        return CSLValidationResult::failure(
            "Stability functional S(t) decreased over transition",
            "ERR_CSL_STABILITY_DECREASE",
        );
    }

    CSLValidationResult::success()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::LorenzPoint;

    #[test]
    fn test_csl_validation_success() {
        let config = CSLConstraintConfig::default();
        let params = LorenzParams::canonical();
        let st0 = LorenzState::initial(LorenzPoint::standard_initial());
        let st1 = LorenzState::new(
            1,
            LorenzPoint::new(1.0, 1.2, 0.98),
            LorenzPoint::new(0.0, 20.0, -2.0),
            -13.6,
            0.02,
        );

        let res = validate_csl_transition(&config, &st0, &st1, &params);
        assert!(res.is_lawful);
        assert_eq!(res.witness_digest, "CSL_WITNESS_VERIFIED_STABLE");
    }

    #[test]
    fn test_csl_fail_on_temporal_gap() {
        let config = CSLConstraintConfig::default();
        let params = LorenzParams::canonical();
        let st0 = LorenzState::initial(LorenzPoint::standard_initial());
        let st2 = LorenzState::new(
            2,
            LorenzPoint::new(1.0, 1.2, 0.98),
            LorenzPoint::new(0.0, 20.0, -2.0),
            -13.6,
            0.02,
        );

        let res = validate_csl_transition(&config, &st0, &st2, &params);
        assert!(!res.is_lawful);
        assert_eq!(res.witness_digest, "ERR_CSL_TEMPORAL_NON_MONOTONIC");
    }

    #[test]
    fn test_csl_fail_on_domain_overflow() {
        let config = CSLConstraintConfig::default();
        let params = LorenzParams::canonical();
        let st0 = LorenzState::initial(LorenzPoint::standard_initial());
        let st1 = LorenzState::new(
            1,
            LorenzPoint::new(200.0, 1.2, 0.98),
            LorenzPoint::new(0.0, 20.0, -2.0),
            -13.6,
            0.02,
        );

        let res = validate_csl_transition(&config, &st0, &st1, &params);
        assert!(!res.is_lawful);
        assert_eq!(res.witness_digest, "ERR_CSL_DOMAIN_OVERFLOW");
    }
}
