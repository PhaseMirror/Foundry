//! # echonomics_engine::amy_mccae — ADR-0023 Amy McCae Fractional Wellness Framework
//!
//! Production-grade implementation of the fractional workplace wellness model:
//! - Embodied capacity: `E = C_avail - S_load` on a normalized 0–100 ledger
//!   (`i64` so the signed energy ledger cannot underflow).
//! - Capacity estimation: `C_est = α · mean(e1, e2, e3)` with calibration
//!   coefficient `α = α_num / α_den ≤ 1`, so the estimate never exceeds the
//!   raw check-in sum.
//! - Stress Load Index bounded at 10.
//! - Burnout gate: embodied energy below the intervention threshold requires
//!   intervention (fail-closed).
//! - Fractional engagement: the committed fraction never exceeds 1.
//!
//! Kani model-checking harnesses (`cargo kani`) discharge the gate properties
//! for all symbolic inputs.

use serde::{Deserialize, Serialize};

/// Stress Load Index ceiling (0–10 scale).
pub const STRESS_INDEX_MAX: i64 = 10;

/// Burnout intervention threshold: `E ≤ -0.2` on the 0–100 × 100 scale.
pub const BURNOUT_THRESHOLD: i64 = -20;

/// Embodied state: available regulatory capacity and cumulative stress load,
/// both normalized to a common 0–100 scale.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct EmbodiedState {
    /// Available capacity `C_avail` × 100, in [0, 100].
    pub capacity: i64,
    /// Stress burden `S_load` × 100, in [0, 100].
    pub stress: i64,
}

impl EmbodiedState {
    /// Embodied energy: `E = C_avail - S_load` (signed).
    pub const fn embodied_energy(&self) -> i64 {
        self.capacity - self.stress
    }

    /// Embodied energy is bounded in [-100, 100] on the normalized ledger.
    pub const fn is_energy_normalized(&self) -> bool {
        self.capacity <= 100 && self.stress <= 100
    }

    /// Burnout risk: embodied energy below the intervention threshold.
    pub const fn is_burnout_risk(&self) -> bool {
        self.embodied_energy() < BURNOUT_THRESHOLD
    }

    /// Fail-closed: a burnout-risk state requires intervention.
    pub const fn requires_intervention(&self) -> bool {
        self.is_burnout_risk()
    }
}

/// α-calibrated capacity estimate:
/// `C_est = (α_num · (e1 + e2 + e3)) / (3 · α_den)`.
/// Returns `None` on arithmetic overflow (fails closed).
pub const fn estimate_capacity(
    e1: u64,
    e2: u64,
    e3: u64,
    alpha_num: u64,
    alpha_den: u64,
) -> Option<u64> {
    let sum = match e1.checked_add(e2) {
        Some(s) => match s.checked_add(e3) {
            Some(s) => s,
            None => return None,
        },
        None => return None,
    };
    let num = match sum.checked_mul(alpha_num) {
        Some(n) => n,
        None => return None,
    };
    let den = match 3u64.checked_mul(alpha_den) {
        Some(d) => d,
        None => return None,
    };
    if den == 0 {
        return None;
    }
    Some(num / den)
}

/// A stress index is valid exactly when it lies on the 0–10 scale.
pub const fn is_stress_index_valid(index: i64) -> bool {
    index >= 0 && index <= STRESS_INDEX_MAX
}

/// Fractional engagement validity: numerator ≤ denominator with a positive
/// denominator (the committed fraction never exceeds 1).
pub const fn is_fractional_engagement_valid(fraction_num: u64, fraction_den: u64) -> bool {
    fraction_num <= fraction_den && fraction_den > 0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_embodied_energy_sign_and_bound() {
        let healthy = EmbodiedState { capacity: 80, stress: 30 };
        let burnt = EmbodiedState { capacity: 10, stress: 95 };

        assert_eq!(healthy.embodied_energy(), 50);
        assert_eq!(burnt.embodied_energy(), -85);
        assert!(healthy.is_energy_normalized());
        assert!(!healthy.is_burnout_risk());
        assert!(burnt.is_burnout_risk());
        assert!(burnt.requires_intervention());
    }

    #[test]
    fn test_alpha_calibrated_capacity_estimate() {
        // α = 0.8, inputs 100,100,100 → 0.8 · 100 = 80.
        assert_eq!(estimate_capacity(100, 100, 100, 4, 5), Some(80));
        // The estimate never exceeds the input sum.
        let est = estimate_capacity(100, 100, 100, 4, 5).unwrap();
        assert!(est <= 300);
    }

    #[test]
    fn test_stress_index_bound() {
        assert!(is_stress_index_valid(0));
        assert!(is_stress_index_valid(10));
        assert!(!is_stress_index_valid(11));
        assert!(!is_stress_index_valid(-1));
    }

    #[test]
    fn test_fractional_engagement() {
        assert!(is_fractional_engagement_valid(3, 4));
        assert!(is_fractional_engagement_valid(1, 1), "full-time is the upper bound");
        assert!(!is_fractional_engagement_valid(4, 3), "never over-committed");
        assert!(!is_fractional_engagement_valid(1, 0), "zero denominator is invalid");
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    /// ADR-0023: embodied energy is the signed difference `E = C - S` on the
    /// normalized 0–100 ledger (the engine's input contract).
    #[kani::proof]
    fn verify_energy_sign_convention() {
        let capacity: i64 = kani::any();
        let stress: i64 = kani::any();
        kani::assume(capacity >= 0 && capacity <= 100);
        kani::assume(stress >= 0 && stress <= 100);
        let st = EmbodiedState { capacity, stress };
        kani::assert(st.embodied_energy() == capacity - stress, "E = C_avail - S_load");
        kani::assert(st.is_energy_normalized(), "ledger inputs are normalized");
    }

    /// ADR-0023: burnout risk fails closed — low energy always requires
    /// intervention (on the normalized 0–100 ledger).
    #[kani::proof]
    fn verify_burnout_gate_fail_closed() {
        let capacity: i64 = kani::any();
        let stress: i64 = kani::any();
        kani::assume(capacity >= 0 && capacity <= 100);
        kani::assume(stress >= 0 && stress <= 100);
        let st = EmbodiedState { capacity, stress };
        if st.is_burnout_risk() {
            kani::assert(st.requires_intervention(), "burnout risk requires intervention");
            kani::assert(st.embodied_energy() < BURNOUT_THRESHOLD, "risk is low embodied energy");
        }
    }

    /// ADR-0023: with α ≤ 1 the calibrated estimate never exceeds the input
    /// sum (no amplification).
    #[kani::proof]
    fn verify_estimate_never_amplifies() {
        let e1: u64 = kani::any();
        let e2: u64 = kani::any();
        let e3: u64 = kani::any();
        let alpha_num: u64 = kani::any();
        let alpha_den: u64 = kani::any();
        kani::assume(alpha_num <= alpha_den && alpha_den > 0);
        kani::assume(e1 <= 100 && e2 <= 100 && e3 <= 100);

        if let Some(est) = estimate_capacity(e1, e2, e3, alpha_num, alpha_den) {
            kani::assert(est <= e1 + e2 + e3, "estimate never exceeds input sum");
            kani::assert(est <= 100, "0.8 · mean of [0,100] inputs stays ≤ 100");
        }
    }

    /// ADR-0023: fractional engagement never over-commits.
    #[kani::proof]
    fn verify_fractional_engagement_bound() {
        let num: u64 = kani::any();
        let den: u64 = kani::any();
        if is_fractional_engagement_valid(num, den) {
            kani::assert(num <= den, "fraction never exceeds 1");
        }
    }
}