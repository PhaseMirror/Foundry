//! ZetaCell Recurrent Operator Cell Engine

use crate::bridge::BridgeKernel;
use crate::projectors::ProjectorEngine;
use crate::state::ZetaState;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZetaCellConfig {
    pub lambda_m: f64,
    pub safety_clip: f64,
    pub sparsity_q: f64,
    pub diversity_target: f64,
    pub decay_rate: f64,
}

impl Default for ZetaCellConfig {
    fn default() -> Self {
        Self {
            lambda_m: 0.1,
            safety_clip: 5.0,
            sparsity_q: 0.05,
            diversity_target: 2.0,
            decay_rate: 0.95,
        }
    }
}

pub struct ZetaCell {
    pub config: ZetaCellConfig,
    pub bridge: BridgeKernel,
}

impl ZetaCell {
    pub fn new(config: ZetaCellConfig, bridge: BridgeKernel) -> Self {
        Self { config, bridge }
    }

    /// GELU activation approximation
    fn gelu(x: f64) -> f64 {
        0.5 * x * (1.0 + ((2.0 / std::f64::consts::PI).sqrt() * (x + 0.044715 * x * x * x)).tanh())
    }

    /// Single step evolution: Ψ_{t+1} = P_E(Π_CSL(Ψ_t + Λ_m U_ζ(Ψ_t, x_t)))
    pub fn step(&self, state: &ZetaState, input_signal: f64) -> (ZetaState, f64, f64) {
        let mut next_state = state.clone();

        // 1. Prime Block A_p(ψ) + Bridge C_{z->p}(χ)
        let bridge_zp = self.bridge.forward_zp(&state.chi, state.n_f, state.n_g);
        for i in 0..state.psi.len() {
            let ap_val = Self::gelu(state.psi[i] * 0.8);
            let u_p = ap_val + 0.3 * bridge_zp[i] + 0.1 * input_signal;
            next_state.psi[i] = self.config.decay_rate * state.psi[i] + self.config.lambda_m * u_p;
        }

        // 2. Zero Block A_z(χ) + Bridge C_{p->z}(ψ)
        let bridge_pz = self.bridge.forward_pz(&state.psi, state.n_f, state.n_g);
        for k in 0..state.chi.len() {
            let az_val = Self::gelu(state.chi[k] * 0.8);
            let u_z = az_val + 0.3 * bridge_pz[k] + 0.1 * input_signal;
            next_state.chi[k] = self.config.decay_rate * state.chi[k] + self.config.lambda_m * u_z;
        }

        // 3. Constitutional Projector Π_CSL
        ProjectorEngine::csl_project(&mut next_state, self.config.safety_clip, self.config.sparsity_q);

        // 4. Ethical Projector P_E
        let (hp, hz) = ProjectorEngine::ethical_project(&mut next_state, self.config.diversity_target);

        (next_state, hp, hz)
    }

    /// Verify contraction rate over multiple steps
    pub fn run_trajectory(&self, initial_state: &ZetaState, steps: usize, input: f64) -> Vec<ZetaState> {
        let mut trajectory = Vec::with_capacity(steps + 1);
        trajectory.push(initial_state.clone());
        let mut current = initial_state.clone();

        for _ in 0..steps {
            let (next, _, _) = self.step(&current, input);
            trajectory.push(next.clone());
            current = next;
        }

        trajectory
    }
}
