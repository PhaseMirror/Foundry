//! PiKernel lineage primitives.
//!
//! Sigma is the direct Rust successor to the Python PiKernel experimental substrate
//! (`packages/experiments/apex/pikernel/`). The concepts below map PiKernel primitives
//! to their Sigma Rust reifications.

/// PiKernel contraction certificate: GapLB = 0.225.
///
/// In PiKernel, GapLB is the lower bound on the contraction gap. In Sigma this maps
/// to `Thresholds.contractivity_margin` (derived from Lean theorems and verified at
/// build time by `build.rs`).
pub const GAP_LB: f64 = 0.225;

/// PiKernel contraction certificate: SlopeUB = 0.775.
///
/// In PiKernel, SlopeUB is the upper bound on the spectral slope. In Sigma this maps
/// to the effective Lipschitz threshold `Thresholds.l_eff_max`.
pub const SLOPE_UB: f64 = 0.775;

/// PiKernel MUB alarm threshold.
///
/// Maps to the dissonance Warning/Critical boundary in `sigma_check`.
pub const MUB_ALARM_THRESHOLD: f64 = 3.0;

/// PiKernel Heartbeat base period (ms).
///
/// Maps to the drift reference `Thresholds.r_sc_reference` in the spectral domain.
pub const HEARTBEAT_TAU_ZERO_MS: f64 = 3.33;

/// Verify that the loaded thresholds are consistent with the PiKernel contraction
/// certificates.
///
/// Returns `Ok(())` if `contractivity_margin >= GAP_LB` and `l_eff_max <= SLOPE_UB`.
pub fn verify_pikernel_consistency(thresholds: &crate::Thresholds) -> Result<(), String> {
    if thresholds.contractivity_margin < GAP_LB {
        return Err(format!(
            "contractivity_margin={} below PiKernel GapLB={}",
            thresholds.contractivity_margin, GAP_LB
        ));
    }
    if thresholds.l_eff_max > SLOPE_UB {
        return Err(format!(
            "l_eff_max={} exceeds PiKernel SlopeUB={}",
            thresholds.l_eff_max, SLOPE_UB
        ));
    }
    Ok(())
}
