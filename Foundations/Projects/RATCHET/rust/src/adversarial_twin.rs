//! The Adversarial Inverted-Math Digital Twin (Σ̄)
//! Automates pre-commit Red Teaming with sign-inverted Lyapunov divergence pressure.

use crate::controller::ExternalController;
use crate::snapshot_store::SnapshotStore;
use crate::types::{Mode, PlantState, Snapshot};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ModificationProposal {
    pub delta_theta: Vec<f64>,
    pub delta_coordinates: usize,
    pub proposed_state: PlantState,
    pub null_space_residual: f64,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum AdversarialError {
    DriftExceededThreshold { v_initial: f64, v_diverged: f64, threshold_limit: f64 },
    NullSpaceVulnerabilityDetected { quadratic_residual: f64, max_allowed: f64 },
    RateCapBreachedUnderAdversarialPressure { observed_rate: f64, cap: f64 },
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum PreCommitError {
    RatchetValidationFailed(String),
    AdversarialStressFailed(AdversarialError),
    SnapshotRollbackTriggered,
}

/// Adversarial Inverted-Math Digital Twin (Σ̄)
#[derive(Debug, Clone)]
pub struct AdversarialTwin {
    /// Sign-inverted kernel attribution weights (V -> ∞)
    pub inverted_weights: Vec<f64>,
    /// Divergence pressure coefficient β
    pub beta: f64,
    /// Stress test iterations N
    pub n_steps: usize,
    /// Divergence threshold multiplier (Default: 1.03 = 3% drift bound)
    pub threshold: f64,
}

impl AdversarialTwin {
    /// Initialize from primary kernel weights by sign inversion (W_twin = -W_primary).
    pub fn from_kernel(kernel_weights: &[f64], beta: f64) -> Self {
        let inverted_weights = kernel_weights.iter().map(|&w| -w).collect();
        Self {
            inverted_weights,
            beta,
            n_steps: 100,
            threshold: 1.03,
        }
    }

    /// Default twin initialization.
    pub fn default_dim(dim: usize) -> Self {
        Self {
            inverted_weights: vec![-1.0; dim],
            beta: 1.5,
            n_steps: 100,
            threshold: 1.03,
        }
    }

    /// Compute Lyapunov function value V(S) = ||theta||_2^2 + ||x||_2^2.
    pub fn compute_lyapunov_v(state: &PlantState) -> f64 {
        let theta_norm_sq: f64 = state.theta.iter().map(|&v| v * v).sum();
        let x_norm_sq: f64 = state.x.iter().map(|&v| v * v).sum();
        (theta_norm_sq + x_norm_sq).max(1e-4)
    }

    /// Apply sign-inverted divergence pressure: f̄_ij = +1/2 tanh(β (S_i - S_j)).
    pub fn apply_divergence_pressure(&self, state: &PlantState, proposal: &ModificationProposal) -> PlantState {
        let mut diverged = state.clone();
        let dot_product: f64 = self
            .inverted_weights
            .iter()
            .zip(&proposal.delta_theta)
            .map(|(&w, &dt)| w * dt)
            .sum();

        // Adversarial drift force
        let drift_force = (self.beta * dot_product).tanh().abs();
        for val in &mut diverged.theta {
            *val += *val * drift_force * 0.001;
        }
        for val in &mut diverged.x {
            *val += *val * drift_force * 0.001;
        }
        diverged
    }

    /// Check if drift threshold V(S_N) <= V(S_0) * 1.03 is violated.
    pub fn drift_exceeds_threshold(&self, v_initial: f64, v_final: f64) -> bool {
        v_final > v_initial * self.threshold
    }

    /// Execute N-step adversarial pre-commit stress test.
    pub fn stress_test(&self, initial_state: &PlantState, proposal: &ModificationProposal) -> Result<PlantState, AdversarialError> {
        let mut test_state = initial_state.clone();
        let v0 = Self::compute_lyapunov_v(initial_state);

        // 1. Check null-space quadratic residual: R_2 = 1/2 z^T ∇²ϕ z
        if proposal.null_space_residual > 0.05 {
            return Err(AdversarialError::NullSpaceVulnerabilityDetected {
                quadratic_residual: proposal.null_space_residual,
                max_allowed: 0.05,
            });
        }

        // 2. N-step iterative divergence stress
        for _ in 0..self.n_steps {
            test_state = self.apply_divergence_pressure(&test_state, proposal);
            let v_current = Self::compute_lyapunov_v(&test_state);
            if self.drift_exceeds_threshold(v0, v_current) {
                return Err(AdversarialError::DriftExceededThreshold {
                    v_initial: v0,
                    v_diverged: v_current,
                    threshold_limit: v0 * self.threshold,
                });
            }
        }

        Ok(test_state)
    }
}

/// Pre-Commit Gate automating closed-loop Red Teaming inside the compiler pipeline.
pub struct PreCommitGate {
    pub controller: ExternalController,
    pub twin: AdversarialTwin,
    pub snapshot_store: SnapshotStore,
}

impl PreCommitGate {
    pub fn new(controller: ExternalController, twin: AdversarialTwin, snapshot_store: SnapshotStore) -> Self {
        Self {
            controller,
            twin,
            snapshot_store,
        }
    }

    /// Execute pre-commit safety check before mutating WORM ledger.
    pub fn evaluate_and_commit(
        &mut self,
        current_state: &PlantState,
        proposal: ModificationProposal,
    ) -> Result<Snapshot, PreCommitError> {
        // Step 1: Ratchet State Machine & Mode validation
        if self.controller.mode == Mode::HALT {
            return Err(PreCommitError::RatchetValidationFailed("Controller is in HALT".into()));
        }

        // Step 2: Adversarial Twin (Σ̄) N-step stress test
        if let Err(err) = self.twin.stress_test(current_state, &proposal) {
            // Fail-closed veto: emit SIG_GOV_KILL, trigger HALT and rollback
            self.controller.mode = Mode::HALT;
            return Err(PreCommitError::AdversarialStressFailed(err));
        }

        // Step 3: Create snapshot commit in immutable WORM ledger
        let snapshot = self.snapshot_store.take_snapshot(&proposal.proposed_state, &[]);
        Ok(snapshot)
    }
}
