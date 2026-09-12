//! Kani symbolic verification of the CSL ethical-projection bounding guarantee.
//!
//! Corresponds to ADR-105 (CSL & Ethical Projection Manifolds) and the Lean
//! `oracle_kani_csl_bounds` axiom in `lean/ADR/CSL/EthicalProjection.lean`.
//!
//! Property under verification: if the initial state starts strictly outside
//! the forbidden spherical attractor's radius, the repulsive CSL gradient step
//! (the penalty component of `ContractiveFit::step`) strictly increases (or
//! maintains, within float tolerance) the distance from the forbidden region
//! and never enters it.

#[cfg(kani)]
mod kani_proofs {
    use ndarray::Array1;
    use pirtm_tensor::csl::{Attractor, SphericalAttractor};

    const N: usize = 2;

    #[kani::proof]
    #[kani::unwind(3)]
    fn verify_csl_bounds() {
        // Discrete grid to prevent SAT solver float explosion.
        let s0_int: i8 = kani::any();
        let s1_int: i8 = kani::any();
        let s0 = (s0_int as f64) / 10.0;
        let s1 = (s1_int as f64) / 10.0;

        kani::assume(s0 >= -10.0 && s0 <= 10.0);
        kani::assume(s1 >= -10.0 && s1 <= 10.0);

        let state = Array1::from_vec(vec![s0, s1]);

        // Forbidden spherical attractor at the origin.
        let center = Array1::from_vec(vec![0.0, 0.0]);
        let radius: f64 = 1.0;
        let barrier_strength: f64 = 0.5;

        let attractor = SphericalAttractor {
            center: center.clone(),
            radius,
            barrier_strength,
        };

        let initial_dist = state
            .iter()
            .zip(center.iter())
            .map(|(s, c)| (s - c).powi(2))
            .sum::<f64>()
            .sqrt();

        // Only care about states strictly outside the forbidden zone.
        kani::assume(initial_dist > radius);

        let grad = attractor.penalty_gradient(&state);

        // Repulsive step: state - lr * grad moves AWAY from the center.
        let lr: f64 = 0.01;
        let next_s0 = state[0] - lr * grad[0];
        let next_s1 = state[1] - lr * grad[1];
        let next_state = Array1::from_vec(vec![next_s0, next_s1]);

        let next_dist = next_state
            .iter()
            .zip(center.iter())
            .map(|(s, c)| (s - c).powi(2))
            .sum::<f64>()
            .sqrt();

        // The repulsive step strictly increases or maintains distance.
        assert!(next_dist >= initial_dist - 1e-6);
        // The state remains outside the forbidden radius.
        assert!(next_dist > radius);
    }
}
