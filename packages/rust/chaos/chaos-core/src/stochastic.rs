use rand::prelude::*;
use rand_distr::{Cauchy, Normal, Distribution};

pub enum NoiseMode {
    Gaussian,
    Cauchy,
}

pub struct NoiseGenerator {
    pub mode: NoiseMode,
    pub scale: f64,
    pub rng: StdRng,
}

impl NoiseGenerator {
    pub fn new(mode: NoiseMode, scale: f64, seed: Option<u64>) -> Self {
        let rng = match seed {
            Some(s) => StdRng::seed_from_u64(s),
            None => StdRng::from_entropy(),
        };
        Self { mode, scale, rng }
    }

    pub fn sample(&mut self, size: usize) -> Vec<f64> {
        match self.mode {
            NoiseMode::Gaussian => {
                let dist = Normal::new(0.0, self.scale).unwrap();
                (0..size).map(|_| dist.sample(&mut self.rng)).collect()
            }
            NoiseMode::Cauchy => {
                let dist = Cauchy::new(0.0, self.scale).unwrap();
                (0..size).map(|_| dist.sample(&mut self.rng)).collect()
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_noise_generation() {
        let mut noise_gen = NoiseGenerator::new(NoiseMode::Gaussian, 0.15, Some(42));
        let sample = noise_gen.sample(3);
        assert_eq!(sample.len(), 3);
    }
}
