use ndarray::{Array1, Array2};
use num_complex::Complex64;

pub struct Hamiltonian {
    pub primes: Array1<f64>,
    pub alpha: f64,
    pub eta: f64,
    pub gaps: Array1<f64>,
}

impl Hamiltonian {
    pub fn new(primes: Vec<f64>, alpha: f64, eta: f64) -> Self {
        let n = primes.len();
        let gaps = Array1::from_iter(primes.windows(2).map(|w| w[1] - w[0]));
        Hamiltonian {
            primes: Array1::from(primes),
            alpha,
            eta,
            gaps,
        }
    }

    pub fn construct_h(&self, t: f64, zero_freqs: &[f64], gammas: &[f64], phases: &[f64]) -> Array2<Complex64> {
        let n = self.primes.len();
        let mut h = Array2::zeros((n, n));

        // H_prime
        for i in 0..n {
            h[[i, i]] = Complex64::new(self.alpha / self.primes[i], 0.0);
        }

        // H_gap (simplified v1 without feedback delay)
        let lambda = 1.0 + gammas.iter().zip(zero_freqs).zip(phases)
            .map(|((g, w), p)| g * (w * t + p).cos())
            .sum::<f64>();

        for i in 0..n - 1 {
            let coupling = self.eta * self.gaps[i] * lambda;
            h[[i, i+1]] = Complex64::new(coupling, 0.0);
            h[[i+1, i]] = Complex64::new(coupling, 0.0);
        }

        h
    }
}
