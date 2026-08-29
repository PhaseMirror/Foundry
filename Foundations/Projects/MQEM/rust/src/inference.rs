//! Sequential Monte Carlo / Particle Filter Likelihood Estimation (M³EM §5.2)

use crate::dynamics::MqemSimulator;
use crate::observation::ObservationModel;
use crate::types::{HabitatGraph, ModelConfig, ObservationRecord, PatchState};

/// Particle filter for non-Gaussian, delayed network-coupled state-space inference.
pub struct ParticleFilter {
    pub num_particles: usize,
    pub config: ModelConfig,
    pub obs_model: ObservationModel,
}

impl ParticleFilter {
    pub fn new(num_particles: usize, config: ModelConfig, obs_model: ObservationModel) -> Self {
        Self {
            num_particles,
            config,
            obs_model,
        }
    }

    /// Evaluates unbiased marginal log-likelihood ln p(y_{1:T}) over observation sequence.
    pub fn estimate_log_likelihood<R: rand::Rng>(
        &self,
        graph: &HabitatGraph,
        observations: &[Vec<ObservationRecord>], // time series of observations per step
        rng: &mut R,
    ) -> f64 {
        let n = graph.num_nodes;
        let d = self.config.dim_d;

        // Initialize particles
        let mut particles: Vec<MqemSimulator> = (0..self.num_particles)
            .map(|_| {
                let init_states = vec![PatchState::new(vec![1.0; d]); n];
                MqemSimulator::new(graph.clone(), self.config.clone(), init_states)
            })
            .collect();

        let mut total_log_likelihood = 0.0;

        for obs_step in observations {
            let mut weights = vec![0.0; self.num_particles];

            for (p_idx, sim) in particles.iter_mut().enumerate() {
                // Propagate particle dynamics
                sim.step(None, rng);

                // Compute observation log-likelihood for this particle
                let mut log_weight = 0.0;
                for obs in obs_step {
                    if obs.node_id < n {
                        let latent_x = sim.states[obs.node_id].values[0];
                        log_weight += self.obs_model.log_likelihood(obs.value, latent_x);
                    }
                }
                weights[p_idx] = log_weight;
            }

            // Log-Sum-Exp over particles for numerical stability
            let max_log_w = weights.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
            let sum_exp: f64 = weights.iter().map(|&w| (w - max_log_w).exp()).sum();
            let step_log_lik = max_log_w + (sum_exp / self.num_particles as f64).ln();

            if step_log_lik.is_finite() {
                total_log_likelihood += step_log_lik;
            }

            // Resample particles based on normalized weights
            let norm_weights: Vec<f64> = weights
                .iter()
                .map(|&w| ((w - max_log_w).exp() / sum_exp.max(1e-9)).max(0.0))
                .collect();

            let mut resampled = Vec::with_capacity(self.num_particles);
            for _ in 0..self.num_particles {
                let r: f64 = rng.gen();
                let mut cum = 0.0;
                let mut chosen = 0;
                for (i, &w) in norm_weights.iter().enumerate() {
                    cum += w;
                    if r <= cum {
                        chosen = i;
                        break;
                    }
                }
                resampled.push(particles[chosen].clone_sim());
            }
            particles = resampled;
        }

        total_log_likelihood
    }
}

impl MqemSimulator {
    pub fn clone_sim(&self) -> Self {
        Self {
            graph: self.graph.clone(),
            config: self.config.clone(),
            states: self.states.clone(),
            history_ring: self.history_ring.clone(),
            current_time: self.current_time,
        }
    }
}
