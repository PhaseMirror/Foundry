use ndarray::Array1;

pub struct EntropyInverseGate {
    pub threshold: f64,
}

impl EntropyInverseGate {
    pub fn new(threshold: f64) -> Self {
        EntropyInverseGate { threshold }
    }

    /// Damps updates if they increase local disorder beyond lawful bounds.
    /// This mirrors the formal 'disorder-based' retraction proven in Lean 4.
    pub fn apply(&self, prev_state: &Array1<f64>, next_state: &Array1<f64>, raw_update: &Array1<f64>) -> Array1<f64> {
        let disorder = calculate_disorder(prev_state, next_state);
        
        if disorder > self.threshold {
            // Damping factor: alpha(t) = threshold / disorder
            let damping = self.threshold / disorder;
            raw_update * damping
        } else {
            raw_update.clone()
        }
    }
}

fn calculate_disorder(p: &Array1<f64>, q: &Array1<f64>) -> f64 {
    // L2 distance as a proxy for disorder/entropy growth in the state space
    (p - q).mapv(|x| x.powi(2)).sum().sqrt()
}
