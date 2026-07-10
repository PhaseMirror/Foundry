use ndarray::Array2;
use libm::jn;
use std::f64::consts::PI;

/// Moonshine Operator ℳ embeds modular features into DRMM tensor evolution.
/// 
/// Parity with: drmm/src/moonshine.py -> MoonshineOperator
pub struct MoonshineOperator {
    pub group_id: i32,
    pub frequency: f64,
}

impl MoonshineOperator {
    pub fn new(group_id: i32, frequency: Option<f64>) -> Self {
        Self {
            group_id,
            frequency: frequency.unwrap_or(2.0 * PI),
        }
    }

    /// Simulate a modular function using a Bessel modulation.
    pub fn modular_waveform(&self, x: &Array2<f64>) -> Array2<f64> {
        x.mapv(|val| jn(self.group_id, self.frequency * val))
    }

    /// Apply the Moonshine modulation to tensor X at time t.
    pub fn apply(&self, x: &Array2<f64>, t: f64) -> Array2<f64> {
        let waveform = self.modular_waveform(&(t * x));
        x * &waveform
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_moonshine_parity() {
        let x = Array2::from_elem((2, 2), 0.5);
        let moon = MoonshineOperator::new(1, None);
        let result = moon.apply(&x, 1.0);
        
        // J1(2*PI * 0.5) = J1(PI) approx 0.2846
        // Result = 0.5 * 0.2846 = 0.1423
        assert!(result[[0, 0]] < 0.5);
        assert!((result[[0, 0]] - 0.1423).abs() < 1e-3);
    }
}
