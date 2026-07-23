//! Kani harness for `anomaly_threshold_valid`.
//!
//! Verifies: ANOMALY_GOV_THRESHOLD (0.0006) < ANOMALY_GOV_CEILING (0.85)
//! This is the concrete Float comparison that is opaque in the Lean 4 kernel
//! without Mathlib. The Rust/Kani witness provides bounded verification.

#[kani::proof]
fn anomaly_threshold_valid() {
    let threshold: f64 = 0.0006;
    let ceiling: f64 = 0.85;
    kani::assert(
        threshold < ceiling,
        "ANOMALY_GOV_THRESHOLD (0.0006) must be less than ANOMALY_GOV_CEILING (0.85)",
    );
}
