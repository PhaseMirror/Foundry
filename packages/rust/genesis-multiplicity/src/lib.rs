//! Rust port of
//! `packages/rust/genesis-ode/src/genesis_governance/multiplicity/` — the
//! quarantined prime-band allocation, multiplicity encoding, and multiplicity
//! decoding logic (ADR-007, ADR-009, ADR-008 threshold state).
//!
//! Fidelity contract (see `genesis-ode/tests/unit/test_multiplicity.py` and
//! `test_allocator.py`):
//! * `MultiplicityEncoder` reproduces the prime signature, exponent vector
//!   (with `int()` truncation toward zero), sparsity index, and the
//!   `switching_threshold or 0.5` semantics exactly.
//! * `MultiplicityDecoder` reproduces the mid-bin reconstruction, the L2 +
//!   categorical reconstruction score, and the locality-delta perturbation.
//! * `PrimeBandAllocator` reproduces the band rotation, sensitivity heuristics
//!   (`np.std` population standard deviation when >10 history samples), and
//!   the `[-50:]` reconstruction window used by `sensitivity_sweep`.
//! * `HistoryStore` reproduces the JSON run-history persistence, fragility
//!   classification, and `get_reconstruction_history` extraction.
//!
//! The Python layers depended on `numpy`; this port uses only `f64` arithmetic
//! and std collections, which is sufficient and exactly equivalent for the
//! operations used here (mean, population std-dev, max, sqrt, exp).

pub mod allocator;
pub mod decoder;
pub mod encoder;
pub mod history;
pub mod shrapnel;
pub mod types;

pub use allocator::PrimeBandAllocator;
pub use decoder::MultiplicityDecoder;
pub use encoder::MultiplicityEncoder;
pub use history::HistoryStore;
pub use shrapnel::{ShrapnelFragment, ShrapnelMap};
pub use types::{MultiplicityEncoding, SurfaceState};

/// Population standard deviation, mirroring `numpy.std` with the default
/// `ddof = 0` (used by `PrimeBandAllocator::analyze_feature_sensitivity`).
pub fn population_std(values: &[f64]) -> f64 {
    if values.is_empty() {
        return 0.0;
    }
    let n = values.len() as f64;
    let mean = values.iter().sum::<f64>() / n;
    let variance = values.iter().map(|v| (v - mean) * (v - mean)).sum::<f64>() / n;
    variance.sqrt()
}

/// `switching_threshold or 0.5` from the Python: `None` and `0.0` collapse to
/// the `0.5` default, every other value is used verbatim.
pub(crate) fn effective_switching_threshold(value: Option<f64>) -> f64 {
    value.filter(|&v| v != 0.0).unwrap_or(0.5)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn population_std_matches_numpy_default() {
        // numpy.std([1.0, 2.0, 3.0, 4.0]) == sqrt(1.25) ~ 1.118.
        let std = population_std(&[1.0, 2.0, 3.0, 4.0]);
        assert!((std - 1.118033988749895).abs() < 1e-12);
    }

    #[test]
    fn threshold_fallthrough_mirrors_python_or() {
        assert_eq!(effective_switching_threshold(None), 0.5);
        assert_eq!(effective_switching_threshold(Some(0.0)), 0.5);
        assert_eq!(effective_switching_threshold(Some(0.5)), 0.5);
        assert_eq!(effective_switching_threshold(Some(0.2)), 0.2);
    }
}
