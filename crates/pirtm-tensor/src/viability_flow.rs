//! Viability Flow utilities for the pirtm‑tensor crate.

use ndarray::Array1;

/// MetricSpace trait – axiom‑clean definition.
/// `R` must support a total order via `le`.
pub trait MetricSpace<S, R> {
  /// Distance between two states.
  fn dist(&self, a: &S, b: &S) -> R;
  /// Lesser‑or‑equal relation on distances.
  fn le(&self, x: R, y: R) -> bool;
}

/// A simple Euclidean metric on `Array1<f64>`.
pub struct EuclideanMetric;

impl MetricSpace<Array1<f64>, f64> for EuclideanMetric {
  fn dist(&self, a: &Array1<f64>, b: &Array1<f64>) -> f64 {
    // L2 norm of the difference.
    a.iter()
      .zip(b.iter())
      .map(|(x, y)| (x - y).powi(2))
      .sum::<f64>()
      .sqrt()
  }
  fn le(&self, x: f64, y: f64) -> bool {
    x <= y + 1e-12 // epsilon tolerance for floating point
  }
}

/// The ethical projector `P_E`.
/// Here we simply clamp each component of the state to the interval [0, 1].
fn clamp_state(state: &Array1<f64>) -> Array1<f64> {
  state.mapv(|v| v.max(0.0).min(1.0))
}

/// ViabilityKernel bundles a projector and its metric.
pub struct ViabilityKernel {
  pub metric: EuclideanMetric,
  /// Projector function – currently a deterministic clamp.
  pub projector: fn(&Array1<f64>) -> Array1<f64>,
}

impl ViabilityKernel {
  pub fn new() -> Self {
    Self { metric: EuclideanMetric, projector: clamp_state }
  }

  /// Apply the projector to a state.
  pub fn apply(&self, s: &Array1<f64>) -> Array1<f64> {
    (self.projector)(s)
  }

  /// Verify non‑expansiveness for a single step.
  /// Returns `true` iff `dist(P_E(step(s1)), P_E(step(s2))) ≤ dist(step(s1), step(s2))`.
  pub fn flow_containment<F>(&self, step: F, s1: &Array1<f64>, s2: &Array1<f64>) -> bool
    where F: Fn(&Array1<f64>) -> Array1<f64>
  {
    let p1 = self.apply(&step(s1));
    let p2 = self.apply(&step(s2));
    let d_proj = self.metric.dist(&p1, &p2);
    let d_raw = self.metric.dist(&step(s1), &step(s2));
    self.metric.le(d_proj, d_raw)
  }
}

// Kani harness for the non‑expansiveness theorem.
#[cfg(kani)]
mod viability_flow_proofs {
  use super::*;
  use kani::any;

  #[kani::proof]
  fn verify_flow_containment() {
    // Two arbitrary 2‑element states.
    let a0: f64 = any(); let a1: f64 = any();
    let b0: f64 = any(); let b1: f64 = any();
    // Constrain to a reasonable range to keep the search tractable.
    kani::assume(a0 >= -2.0 && a0 <= 3.0);
    kani::assume(a1 >= -2.0 && a1 <= 3.0);
    kani::assume(b0 >= -2.0 && b0 <= 3.0);
    kani::assume(b1 >= -2.0 && b1 <= 3.0);

    let s1 = ndarray::arr1(&[a0, a1]);
    let s2 = ndarray::arr1(&[b0, b1]);

    // Identity step (no dynamics) – the simplest non‑trivial case.
    let identity = |x: &Array1<f64>| x.clone();

    let kernel = ViabilityKernel::new();
    let ok = kernel.flow_containment(identity, &s1, &s2);
    // The projector is a clamp, which is a non‑expansive map in Euclidean norm.
    assert!(ok);
  }
}
