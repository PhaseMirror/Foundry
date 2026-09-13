//! Port of `app/mapper.py` — PR -> StateTransition serialization.

use crate::TransitionData;

/// The numeric metrics `map_pr_to_transition` consumes from a PullRequest.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PullRequestMetrics {
    pub number: u64,
    pub additions: u64,
    pub deletions: u64,
    pub changed_files: u64,
}

pub const BASE_R_SC: f64 = 47.0;
pub const L_EFF_BASE: f64 = 0.02;
pub const L_EFF_SCALE: f64 = 0.12;
pub const MAX_DIFF_SIZE: f64 = 1000.0;
pub const MAX_FILES: f64 = 20.0;

/// Mirrors Python `round(x, 6)` for the realistic value domain (exact
/// multiples of 0.001 / 0.006, so banker's-rounding half-cases cannot occur).
pub fn round_6(x: f64) -> f64 {
    (x * 1e6).round() / 1e6
}

/// Maps PR metrics to a `sigma::StateTransition`-compatible dict.
///
/// - `r_sc = 47.0 + min((additions+deletions)/1000, 1.0)`
/// - `l_eff = 0.02 + min(changed_files/20, 1.0) * 0.12`
/// - `id = "pr-{number}"`
pub fn map_pr_to_transition(metrics: &PullRequestMetrics) -> TransitionData {
    let additions = metrics.additions as f64;
    let deletions = metrics.deletions as f64;
    let changed_files = metrics.changed_files as f64;

    let diff_size = additions + deletions;
    let diff_factor = (diff_size / MAX_DIFF_SIZE).min(1.0);
    let r_sc = BASE_R_SC + (diff_factor * 1.0);

    let file_factor = (changed_files / MAX_FILES).min(1.0);
    let l_eff = L_EFF_BASE + (file_factor * L_EFF_SCALE);

    TransitionData {
        id: format!("pr-{}", metrics.number),
        r_sc: round_6(r_sc),
        l_eff: round_6(l_eff),
    }
}
