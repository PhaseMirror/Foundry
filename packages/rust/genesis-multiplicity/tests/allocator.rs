//! Port of `genesis-ode/tests/unit/test_allocator.py`.

use genesis_multiplicity::{HistoryStore, PrimeBandAllocator, ShrapnelFragment, ShrapnelMap};
use serde_json::{Map, Value};
use std::collections::HashMap;

fn bad_fragment(target_id: &str) -> ShrapnelFragment {
    // Mirror of `test_sensitivity_sweep_triggers_reallocation`.
    let mut metadata = Map::new();
    let mut multiplicity = Map::new();
    multiplicity.insert(String::from("reconstruction_score"), Value::from(0.5_f64));
    multiplicity.insert(String::from("locality_delta"), Value::from(0.2_f64));
    metadata.insert(String::from("multiplicity"), Value::Object(multiplicity));
    ShrapnelFragment {
        target_id: String::from(target_id),
        baseline_intent: String::from("stability"),
        test_suite: vec![String::from("timing_jitter")],
        observed_drift: HashMap::from([(String::from("coherence_drift"), 0.1)]),
        fragility_class: String::from("robust"),
        tether_tension: 0.0,
        tier: String::from("S"),
        metadata,
    }
}

#[test]
fn sensitivity_sweep_triggers_reallocation() {
    let tmp = tempfile::tempdir().unwrap();
    let history_store = HistoryStore::new(tmp.path().join("test_history.json"));

    // Initial mapping.
    let mut allocator = PrimeBandAllocator::new(Some(history_store));
    assert_eq!(allocator.current_mapping["logical_state"], 7);

    // Add some poor reconstruction history (60 fragments).
    let bad_run = ShrapnelMap {
        fragments: (0..60).map(|_| bad_fragment("Semi")).collect(),
        overall_tau: 1.0,
        coverage: 1.0,
        tier: String::from("S"),
    };
    allocator.history.as_mut().unwrap().add_run(bad_run);

    // Run sweep.
    let reallocated = allocator.sensitivity_sweep(0.8, 0.15);
    assert!(reallocated);
    // logical_state == 7 rotates to 11 in band B.
    assert_eq!(allocator.current_mapping["logical_state"], 11);
}

#[test]
fn banded_allocation_invariants() {
    let allocator = PrimeBandAllocator::new(None);
    let mapping = allocator.allocate();

    // Continuous dynamics should be in Band A [2, 3, 5].
    assert!([2, 3, 5].contains(&mapping["coherence"]));
    assert!([2, 3, 5].contains(&mapping["effective_stress"]));

    // Categorical should be in Band B [7, 11].
    assert!([7, 11].contains(&mapping["logical_state"]));

    // Context should be in Band C [13, 17, 19].
    assert!([13, 17, 19].contains(&mapping["frequency"]));
    assert!([13, 17, 19].contains(&mapping["coupling"]));
}

#[test]
fn default_mapping_matches_python() {
    let allocator = PrimeBandAllocator::new(None);
    assert_eq!(allocator.get_prime_for_feature("logical_state"), 7);
    assert_eq!(allocator.get_prime_for_feature("frequency"), 13);
    // Fallback to high prime for unknown features.
    assert_eq!(allocator.get_prime_for_feature("does_not_exist"), 23);
}

#[test]
fn sweep_without_history_returns_false() {
    let mut allocator = PrimeBandAllocator::new(None);
    assert!(!allocator.sensitivity_sweep(0.8, 0.15));
}

#[test]
fn sweep_with_good_history_does_not_reallocate() {
    let tmp = tempfile::tempdir().unwrap();
    let history_store = HistoryStore::new(tmp.path().join("test_history.json"));

    let mut good_fragments = Vec::new();
    for _ in 0..60 {
        let mut f = bad_fragment("Semi");
        // Reconstruction score 0.95, low delta -> below thresholds.
        if let Some(Value::Object(m_meta)) = f.metadata.get_mut("multiplicity") {
            m_meta.insert(String::from("reconstruction_score"), Value::from(0.95_f64));
            m_meta.insert(String::from("locality_delta"), Value::from(0.02_f64));
        }
        good_fragments.push(f);
    }
    let good_run = ShrapnelMap {
        fragments: good_fragments,
        overall_tau: 1.0,
        coverage: 1.0,
        tier: String::from("S"),
    };

    let mut allocator = PrimeBandAllocator::new(Some(history_store));
    allocator.history.as_mut().unwrap().add_run(good_run);

    assert!(!allocator.sensitivity_sweep(0.8, 0.15));
    assert_eq!(allocator.current_mapping["logical_state"], 7);
}

#[test]
fn sensitivity_analysis_heuristics() {
    let allocator = PrimeBandAllocator::new(None);
    // logical_state is always prioritized.
    assert_eq!(allocator.analyze_feature_sensitivity("logical_state"), 0.9);
    // Without history, mid-band default.
    assert_eq!(allocator.analyze_feature_sensitivity("coherence"), 0.5);
}
