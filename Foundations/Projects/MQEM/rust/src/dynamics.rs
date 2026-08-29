//! Delayed Network-Coupled Stochastic State-Space Dynamics (M³EM Eq. 1)

use crate::types::{HabitatGraph, ModelConfig, PatchState};
use rand_distr::{Distribution, Normal};

/// State-space simulation engine managing delayed history buffers and spatial coupling.
pub struct MqemSimulator {
    pub graph: HabitatGraph,
    pub config: ModelConfig,
    pub states: Vec<PatchState>,
    pub history_ring: Vec<Vec<PatchState>>, // ring buffer for delay horizon tau
    pub current_time: usize,
}

impl MqemSimulator {
    pub fn new(graph: HabitatGraph, config: ModelConfig, initial_states: Vec<PatchState>) -> Self {
        let history_size = config.delay_tau + 1;
        let mut history_ring = Vec::with_capacity(history_size);
        for _ in 0..history_size {
            history_ring.push(initial_states.clone());
        }

        Self {
            graph,
            config,
            states: initial_states,
            history_ring,
            current_time: 0,
        }
    }

    /// Evaluates internal ecological drift F(x, u) (e.g. Lotka-Volterra logistic growth).
    pub fn compute_drift(&self, x: f64, u: f64) -> f64 {
        let r = self.config.growth_rate;
        let k = self.config.carrying_capacity;
        if k <= 0.0 {
            return 0.0;
        }
        // Logistic growth with intervention u
        (r * x * (1.0 - x / k)) + u
    }

    /// Step the entire network forward by dt under delayed network coupling and Gaussian noise.
    pub fn step<R: rand::Rng>(&mut self, interventions: Option<&[f64]>, rng: &mut R) {
        let n = self.graph.num_nodes;
        let d = self.config.dim_d;
        let tau = self.config.delay_tau;
        let dt = self.config.dt;
        let sigma = self.config.noise_sigma;

        // Get delayed states at t - tau from ring buffer
        let delayed_idx = (self.current_time + 1) % (tau + 1);
        let delayed_states = &self.history_ring[delayed_idx];

        let mut next_states = vec![PatchState::zeros(d); n];

        for v in 0..n {
            let u_v = interventions.and_then(|u| u.get(v)).cloned().unwrap_or(0.0);

            for c in 0..d {
                let x_v = self.states[v].values[c];
                let drift = self.compute_drift(x_v, u_v);

                // Compute network dispersal flux: sum_{w in N(v)} a_vw * (x_w(t - tau) - x_v(t))
                let mut dispersal = 0.0;
                for w in 0..n {
                    let a_vw = self.graph.adjacency_matrix[v][w];
                    if a_vw > 0.0 {
                        let x_w_delayed = delayed_states[w].values[c];
                        dispersal += a_vw * (x_w_delayed - x_v);
                    }
                }

                let noise: f64 = if sigma > 0.0 {
                    Normal::new(0.0, sigma.sqrt())
                        .map(|dist| dist.sample(rng))
                        .unwrap_or(0.0)
                } else {
                    0.0
                };

                let x_next = x_v + dt * (drift + dispersal) + noise;

                // Ecological states stay non-negative
                next_states[v].values[c] = x_next.max(0.0);
            }
        }

        self.current_time += 1;
        self.states = next_states.clone();
        // Update ring buffer at current slot
        let current_slot = self.current_time % (tau + 1);
        self.history_ring[current_slot] = next_states;
    }
}
