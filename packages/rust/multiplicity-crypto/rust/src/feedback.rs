//! Contractivity feedback gate (ADR-012, QKD v1.0.1 feedback module).
//!
//! Mirrors `ts/src/feedback.ts` `computeFeedback` and `primeUpperBound`:
//!
//! - **L0-5 gate** (ConstitutionModel Art. VIII §8.1): `0 < contractivity_score ≤ 1.0`
//! - **Prime-indexed tightening**: `contractivity_score ≤ p/(p+1)`
//!
//! On success, the profile advances (`state_index` increments, `prime_index`
//! increments). On failure, the profile is returned unchanged.

use crate::profile::MultiplicityProfile;

/// Input to the feedback gate.
#[derive(Debug, Clone)]
pub struct FeedbackInput {
    pub current_profile: MultiplicityProfile,
    pub error_rate: f64,
    pub latency: f64,
    pub load: f64,
}

/// Contractivity metrics from the pipeline.
#[derive(Debug, Clone)]
pub struct FeedbackContractivity {
    pub contractivity_score: f64,
}

/// Output of the feedback gate.
#[derive(Debug, Clone, PartialEq)]
pub struct FeedbackOutput {
    pub next_profile: MultiplicityProfile,
    pub transitioned: bool,
}

/// Prime-indexed upper bound: `p / (p + 1)`, as a `f64`.
#[must_use]
pub fn prime_upper_bound_f64(prime_index: usize) -> f64 {
    crate::prime::prime_upper_bound_f64(prime_index)
}

/// Prime-indexed upper bound: `p / (p + 1)`, as a scaled `u64` (×1e9).
///
/// Mirrors `pirtm-engine`'s fixed-point `CONTRACTIVITY_SCALE` convention:
/// the bound is `(p / (p+1)) * 1_000_000_000` rounded to `u64`.
#[must_use]
pub fn prime_upper_bound(prime_index: usize) -> u64 {
    let p = crate::prime::get_prime_at_index(prime_index) as f64;
    ((p / (p + 1.0)) * 1e9) as u64
}

/// The fixed-point contractivity scale (1e9), matching `pirtm-engine`.
pub const CONTRACTIVITY_SCALE: u64 = 1_000_000_000;

/// The L0-5 + prime-indexed contractivity gate.
///
/// Returns the advanced profile if both gates pass; otherwise returns the
/// current profile unchanged with `transitioned = false`.
#[must_use]
pub fn compute_feedback(input: &FeedbackInput, contractivity: &FeedbackContractivity) -> FeedbackOutput {
    let p = crate::prime::get_prime_at_index(input.current_profile.prime_index as usize) as f64;
    let upper_bound = p / (p + 1.0);

    let score = contractivity.contractivity_score;
    let l0_5_ok = score > 0.0 && score <= 1.0;
    let prime_ok = score <= upper_bound;

    if l0_5_ok && prime_ok {
        let mut next = input.current_profile;
        next.state_index = next.state_index.wrapping_add(1);
        next.prime_index = next.prime_index.wrapping_add(1);
        FeedbackOutput {
            next_profile: next,
            transitioned: true,
        }
    } else {
        FeedbackOutput {
            next_profile: input.current_profile,
            transitioned: false,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::profile::MultiplicityProfile;

    #[test]
    fn prime_upper_bound_monotonic_increasing() {
        let b0 = prime_upper_bound_f64(0); // 2/3
        let b3 = prime_upper_bound_f64(3); // 7/8
        assert!((b0 - 2.0/3.0).abs() < 1e-12);
        assert!((b3 - 7.0/8.0).abs() < 1e-12);
        assert!(b0 < b3);
        assert!(b3 < 1.0);
    }

    #[test]
    fn prime_upper_bound_scaled_matches_float() {
        let f = prime_upper_bound_f64(3);
        let s = prime_upper_bound(3);
        assert!((s as f64 - f * 1e9).abs() < 1.0);
    }

    #[test]
    fn contractive_score_passes_both_gates() {
        let profile = MultiplicityProfile::new(0, 1, 0, 0); // prime 2, bound 2/3
        let input = FeedbackInput {
            current_profile: profile,
            error_rate: 0.01,
            latency: 10.0,
            load: 0.5,
        };
        let contractivity = FeedbackContractivity { contractivity_score: 0.5 };
        let out = compute_feedback(&input, &contractivity);
        assert!(out.transitioned);
        assert_eq!(out.next_profile.prime_index, 1);
        assert_eq!(out.next_profile.state_index, 1);
    }

    #[test]
    fn score_above_one_fails_l0_5() {
        let profile = MultiplicityProfile::new(0, 1, 0, 0);
        let input = FeedbackInput {
            current_profile: profile,
            error_rate: 0.01,
            latency: 10.0,
            load: 0.5,
        };
        let contractivity = FeedbackContractivity { contractivity_score: 1.5 };
        let out = compute_feedback(&input, &contractivity);
        assert!(!out.transitioned);
        assert_eq!(out.next_profile, profile);
    }

    #[test]
    fn score_at_prime_upper_bound_is_accepted() {
        let profile = MultiplicityProfile::new(0, 1, 0, 0); // bound = 2/3
        let input = FeedbackInput {
            current_profile: profile,
            error_rate: 0.01,
            latency: 10.0,
            load: 0.5,
        };
        let upper = prime_upper_bound_f64(0);
        let contractivity = FeedbackContractivity { contractivity_score: upper };
        let out = compute_feedback(&input, &contractivity);
        assert!(out.transitioned, "score at p/(p+1) boundary should pass (<=)");
    }

    #[test]
    fn zero_score_fails_l0_5() {
        let profile = MultiplicityProfile::new(0, 1, 0, 0);
        let input = FeedbackInput {
            current_profile: profile,
            error_rate: 0.01,
            latency: 10.0,
            load: 0.5,
        };
        let contractivity = FeedbackContractivity { contractivity_score: 0.0 };
        let out = compute_feedback(&input, &contractivity);
        assert!(!out.transitioned);
    }
}
