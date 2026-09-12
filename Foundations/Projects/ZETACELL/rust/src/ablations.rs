//! Comparative Ablation Engine: True Zeros vs Shuffled Zeros vs Random Frequencies

use crate::bridge::{BridgeKernel, PRIMES, RIEMANN_ZEROS};
use crate::cell::{ZetaCell, ZetaCellConfig};
use crate::state::ZetaState;
use rand::seq::SliceRandom;
use rand::Rng;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AblationResult {
    pub variant: String,
    pub final_norm: f64,
    pub contraction_rate: f64,
    pub prime_entropy: f64,
    pub zero_entropy: f64,
    pub is_stable: bool,
}

pub struct AblationSuite;

impl AblationSuite {
    /// Run comparison across the 3 core architectures:
    /// 1. True Riemann Zeros
    /// 2. Shuffled Zeros
    /// 3. Random Frequencies
    pub fn run_ablation_experiment(n_p: usize, n_z: usize, n_f: usize, n_g: usize, steps: usize) -> Vec<AblationResult> {
        let mut results = Vec::new();
        let config = ZetaCellConfig::default();

        let primes_subset = &PRIMES[..n_p];

        // 1. True Zeros
        let zeros_true = &RIEMANN_ZEROS[..n_z];
        let bridge_true = BridgeKernel::new_explicit(n_p, n_z, zeros_true, primes_subset);
        let cell_true = ZetaCell::new(config.clone(), bridge_true);
        results.push(Self::evaluate_variant("True Riemann Zeros", &cell_true, n_p, n_f, n_z, n_g, steps));

        // 2. Shuffled Zeros
        let mut rng = rand::thread_rng();
        let mut zeros_shuffled = zeros_true.to_vec();
        zeros_shuffled.shuffle(&mut rng);
        let bridge_shuffled = BridgeKernel::new_explicit(n_p, n_z, &zeros_shuffled, primes_subset);
        let cell_shuffled = ZetaCell::new(config.clone(), bridge_shuffled);
        results.push(Self::evaluate_variant("Shuffled Zeros Baseline", &cell_shuffled, n_p, n_f, n_z, n_g, steps));

        // 3. Random Frequencies
        let zeros_random: Vec<f64> = (0..n_z).map(|_| rng.gen_range(10.0..100.0)).collect();
        let bridge_random = BridgeKernel::new_explicit(n_p, n_z, &zeros_random, primes_subset);
        let cell_random = ZetaCell::new(config.clone(), bridge_random);
        results.push(Self::evaluate_variant("Random Frequency Baseline", &cell_random, n_p, n_f, n_z, n_g, steps));

        results
    }

    fn evaluate_variant(
        variant_name: &str,
        cell: &ZetaCell,
        n_p: usize,
        n_f: usize,
        n_z: usize,
        n_g: usize,
        steps: usize,
    ) -> AblationResult {
        let mut state = ZetaState::new(n_p, n_f, n_z, n_g);
        // Initialize state with uniform non-zero values
        for x in &mut state.psi {
            *x = 1.0;
        }
        for x in &mut state.chi {
            *x = 1.0;
        }

        let initial_norm = state.norm();
        let mut final_hp = 0.0;
        let mut final_hz = 0.0;

        for _ in 0..steps {
            let (next_state, hp, hz) = cell.step(&state, 0.5);
            state = next_state;
            final_hp = hp;
            final_hz = hz;
        }

        let final_norm = state.norm();
        let contraction_rate = final_norm / initial_norm.max(1e-8);
        let is_stable = final_norm < initial_norm * 2.0 && !final_norm.is_nan();

        AblationResult {
            variant: variant_name.to_string(),
            final_norm,
            contraction_rate,
            prime_entropy: final_hp,
            zero_entropy: final_hz,
            is_stable,
        }
    }
}
