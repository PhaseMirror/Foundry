use crate::primes::generate_first_n_primes;
use crate::spectral::{SpectralTransform, compute_bin_energies};
use ndarray::{Array1, ArrayViewMutD, ArrayViewD};
use num_complex::Complex;
use std::collections::HashMap;

pub struct OptimizerConfig {
    pub lr: f64,
    pub alpha: f64,
    pub eps: f64,
    pub lambda_min: f64,
    pub lambda_max: f64,
    pub momentum: f64,
    pub ema_beta: f64,
    pub num_bins: usize,
    pub weight_decay: f64,
}

impl Default for OptimizerConfig {
    fn default() -> Self {
        Self {
            lr: 1e-2,
            alpha: 1.2,
            eps: 1e-8,
            lambda_min: 0.01,
            lambda_max: 5.0,
            momentum: 0.9,
            ema_beta: 0.99,
            num_bins: 32,
            weight_decay: 0.0,
        }
    }
}

pub struct ParameterState {
    pub lambda_ema: f64,
    pub momentum_buffer: Array1<Complex<f64>>,
    pub lambda_history: Vec<f64>,
    pub energy_history: Vec<Vec<f64>>,
}

pub struct DRMMOptimizer {
    pub config: OptimizerConfig,
    pub primes: Vec<f64>,
    pub transform: SpectralTransform,
    pub states: HashMap<usize, ParameterState>,
    pub global_step: usize,
    pub log_every: usize,
}

impl DRMMOptimizer {
    pub fn new(config: OptimizerConfig) -> Self {
        let prime_count = config.num_bins.max(256);
        let primes = generate_first_n_primes(prime_count).into_iter().map(|p| p as f64).collect();
        Self {
            config,
            primes,
            transform: SpectralTransform::new(),
            states: HashMap::new(),
            global_step: 0,
            log_every: 1,
        }
    }

    pub fn step(&mut self, param_id: usize, param: &mut ArrayViewMutD<f64>, grad: &ArrayViewD<f64>) {
        let original_len = grad.len();
        let flat_grad = grad.as_standard_layout().to_owned().into_shape(original_len).unwrap();
        
        let (spectrum, padded_size, original_size) = self.transform.forward(flat_grad.view());
        let energies = compute_bin_energies(spectrum.view(), self.config.num_bins);
        
        // _weighted_sum
        let mut weighted_sum = 0.0;
        for (i, &energy) in energies.iter().enumerate() {
            let weight = self.primes[i].powf(-self.config.alpha);
            weighted_sum += energy * weight;
        }

        let lambda_raw = (1.0 / (weighted_sum + self.config.eps).sqrt())
            .clamp(self.config.lambda_min, self.config.lambda_max);

        let state = self.states.entry(param_id).or_insert_with(|| {
            ParameterState {
                lambda_ema: lambda_raw,
                momentum_buffer: Array1::from_elem(spectrum.len(), Complex::new(0.0, 0.0)),
                lambda_history: Vec::new(),
                energy_history: Vec::new(),
            }
        });

        // EMA Update
        state.lambda_ema = state.lambda_ema * self.config.ema_beta + lambda_raw * (1.0 - self.config.ema_beta);
        
        if self.global_step % self.log_every == 0 {
            state.lambda_history.push(state.lambda_ema);
            state.energy_history.push(energies.to_vec());
        }

        let lambda_smoothed = state.lambda_ema;
        
        // Contracted spectrum
        let contracted = spectrum.mapv(|c| c * lambda_smoothed);

        // Momentum update
        for (m, &c) in state.momentum_buffer.iter_mut().zip(contracted.iter()) {
            *m = *m * self.config.momentum + c * (1.0 - self.config.momentum);
        }

        // Inverse transform
        let delta = self.transform.inverse(state.momentum_buffer.view(), padded_size, original_size);

        // Update parameter
        let param_len = param.len();
        let mut param_flat = param.view_mut().into_shape(param_len).unwrap();
        
        if self.config.weight_decay > 0.0 {
            for p in param_flat.iter_mut() {
                *p *= 1.0 - self.config.lr * self.config.weight_decay;
            }
        }

        for (p, &d) in param_flat.iter_mut().zip(delta.iter()) {
            *p -= self.config.lr * d;
        }

        self.global_step += 1;
    }
}
