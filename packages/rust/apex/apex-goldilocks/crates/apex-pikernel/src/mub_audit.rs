use ndarray::{Array1, ArrayView1};
use serde::{Serialize, Deserialize};
use crate::l1proj::Rational;
use num_traits::{ToPrimitive};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MubAuditResult {
    pub d_t: f64,
    pub max_energy: f64,
    pub mean_energy: f64,
    pub threshold: f64,
    pub alarm: bool,
    pub action: String,
}

pub fn mub_drift_audit(x: &Array1<Rational>, threshold: f64) -> MubAuditResult {
    let n = x.len();
    
    // Convert Rational to f64 for spectral analysis
    let x_f64: Array1<f64> = x.mapv(|r| {
        let n = r.numer().to_f64().unwrap_or(0.0);
        let d = r.denom().to_f64().unwrap_or(1.0);
        n / d
    });
    
    // Check if n is power of 2 for Hadamard
    let ux = if (n > 0) && (n & (n - 1)) == 0 {
        fast_walsh_hadamard(x_f64)
    } else {
        x_f64
    };

    let energy = ux.mapv(|a| a.powi(2));
    let max_energy = energy.iter().fold(0.0, |a: f64, &b| a.max(b));
    let sum_energy: f64 = energy.sum();
    let mean_energy = sum_energy / (n as f64);

    let d_t = max_energy * (n as f64) - sum_energy;
    let alarm = d_t > threshold;

    MubAuditResult {
        d_t,
        max_energy,
        mean_energy,
        threshold,
        alarm,
        action: if alarm { "shrink_tau".to_string() } else { "accept".to_string() },
    }
}

pub fn fast_walsh_hadamard(mut x: Array1<f64>) -> Array1<f64> {
    let n = x.len();
    if n == 0 { return x; }
    assert!((n & (n - 1)) == 0, "Length must be a power of 2");

    let mut h = 1;
    while h < n {
        for i in (0..n).step_by(h * 2) {
            for j in i..i+h {
                let a = x[j];
                let b = x[j + h];
                x[j] = a + b;
                x[j + h] = a - b;
            }
        }
        h *= 2;
    }

    let sqrt_n = (n as f64).sqrt();
    x.mapv(|a| a / sqrt_n)
}
