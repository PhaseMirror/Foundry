use serde::{Deserialize, Serialize};
use ndarray::Array1;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum WassersteinError {
    #[error("Dimension mismatch")]
    DimensionMismatch,
    #[error("Invalid distribution")]
    InvalidDistribution,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WassersteinMetric {
    pub p: f64,
}

impl WassersteinMetric {
    pub fn new(p: f64) -> Self {
        Self { p }
    }

    pub fn compute(&self, u: &Array1<f64>, v: &Array1<f64>) -> Result<f64, WassersteinError> {
        if u.len() != v.len() {
            return Err(WassersteinError::DimensionMismatch);
        }
        
        let mut u_cdf = vec![0.0; u.len()];
        let mut v_cdf = vec![0.0; v.len()];
        
        let mut u_sum = 0.0;
        let mut v_sum = 0.0;
        for i in 0..u.len() {
            u_sum += u[i];
            u_cdf[i] = u_sum;
            v_sum += v[i];
            v_cdf[i] = v_sum;
        }

        let mut distance = 0.0;
        for i in 0..u.len() {
            distance += (u_cdf[i] - v_cdf[i]).abs().powf(self.p);
        }
        
        Ok(distance.powf(1.0 / self.p))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::array;

    #[test]
    fn test_wasserstein_distance() {
        let metric = WassersteinMetric::new(1.0);
        let u = array![0.5, 0.5];
        let v = array![0.4, 0.6];
        let d = metric.compute(&u, &v).unwrap();
        // u_cdf = [0.5, 1.0], v_cdf = [0.4, 1.0]
        // |0.5-0.4| + |1.0-1.0| = 0.1
        assert!((d - 0.1).abs() < 1e-10);
    }
}
