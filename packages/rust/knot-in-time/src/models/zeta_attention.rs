use ndarray::{Array1, Array2, Axis};
use std::f64::consts::PI;

pub struct ZetaAttention {
    pub d_model: usize,
    pub n_heads: usize,
    pub vocab_size: usize,
    pub kappa: f64,
    pub gamma: Vec<f64>,
    pub omega_mask: Array2<bool>,
}

impl ZetaAttention {
    pub fn new(d_model: usize, n_heads: usize, vocab_size: usize, kappa: f64) -> Self {
        let gamma = vec![
            14.1347, 21.0220, 25.0109, 30.4249, 32.9351,
            37.5862, 40.9187, 43.3271, 48.0052, 49.7738,
        ];
        
        Self {
            d_model,
            n_heads,
            vocab_size,
            kappa,
            gamma,
            omega_mask: Array2::from_elem((vocab_size, vocab_size), true),
        }
    }

    pub fn load_constitutional_mask(&mut self, charter_matrix: Array2<bool>) {
        self.omega_mask = charter_matrix;
    }

    fn memory_kernel(&self, i: f64, j: f64) -> f64 {
        let delta = (i - j).abs();
        let decay = (-self.kappa * delta).exp();
        
        let log_delta = (delta + 1.0).ln();
        let mut cos_sum = 0.0;
        for &g in &self.gamma {
            cos_sum += (g * log_delta).cos();
        }
        
        decay * cos_sum
    }

    pub fn compute_mask(&self, seq_len: usize) -> Array2<f64> {
        let mut m = Array2::zeros((seq_len, seq_len));
        for i in 0..seq_len {
            for j in 0..seq_len {
                m[[i, j]] = self.memory_kernel(i as f64, j as f64);
            }
        }
        m
    }
}
