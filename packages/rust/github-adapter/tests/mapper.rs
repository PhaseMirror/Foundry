//! Port of `app/mapper.py` semantics (no Python test file exists upstream, so
//! the contract is asserted from the module's docstring + `sigma` contract).

use github_adapter::mapper::{map_pr_to_transition, round_6, PullRequestMetrics};
use serde_json::json;

fn metrics(number: u64, additions: u64, deletions: u64, changed_files: u64) -> PullRequestMetrics {
    PullRequestMetrics {
        number,
        additions,
        deletions,
        changed_files,
    }
}

#[test]
fn small_pr_uses_base_r_sc_and_minimal_l_eff() {
    // 10 additions, no deletions, 1 file.
    let t = map_pr_to_transition(&metrics(7, 10, 0, 1));
    assert_eq!(t.id, "pr-7");
    // diff_factor = 10 / 1000 = 0.01 -> r_sc = 47.01
    assert_eq!(t.r_sc, 47.01);
    // file_factor = 1 / 20 = 0.05 -> l_eff = 0.02 + 0.006 = 0.026
    assert_eq!(t.l_eff, 0.026);
}

#[test]
fn large_pr_caps_factors_at_one() {
    // diff_size >= 1000 lines and >= 20 files are the assumed maxima.
    let t = map_pr_to_transition(&metrics(1, 1000, 999, 40));
    assert_eq!(t.r_sc, 48.0); // 47.0 + 1.0
    assert_eq!(t.l_eff, 0.14); // 0.02 + 0.12
}

#[test]
fn halfway_pr_matches_python_math() {
    // 500 + 500 lines -> factor 1.0; 10 of 20 files -> 0.5.
    let t = map_pr_to_transition(&metrics(42, 500, 500, 10));
    assert_eq!(t.r_sc, 48.0);
    assert_eq!(t.l_eff, 0.08);
}

#[test]
fn serialization_matches_sigma_state_transition() {
    let t = map_pr_to_transition(&metrics(42, 500, 500, 10));
    let value = serde_json::to_value(&t).unwrap();
    assert_eq!(value, json!({ "id": "pr-42", "r_sc": 48.0, "l_eff": 0.08 }));
}

#[test]
fn round_6_does_not_choke_on_binary_float() {
    // 47.0 + 999/1000 * 1.0 has a non-terminating binary expansion; the
    // round-to-6 keeps the Python `round(x, 6)` result exact.
    let r_sc = 47.0 + (999.0_f64 / 1000.0);
    assert_eq!(round_6(r_sc), 47.999);
}
