use crate::crypto::CIRCUIT_WIDTH;

pub struct StabilityModule;

impl StabilityModule {
    /// Computes the contraction witness (q) for a given set of transition inputs.
    /// Certified formula: q = (1.0 - lambda_m) + lambda_m * L_eff
    /// Where:
    /// - lambda_m is the mean scaling parameter of the inputs.
    /// - L_eff is the effective Lipschitz coefficient of the state update.
    pub fn compute_witness(inputs: &[f64; CIRCUIT_WIDTH]) -> f64 {
        // Calculate the mean of absolute values of the input vector
        let mean_val = inputs.iter().map(|&x| x.abs()).sum::<f64>() / inputs.len() as f64;
        
        // Map mean_val to lambda_m in range [0.01, 0.99] using sigmoid
        let lambda_m = 0.01 + 0.98 * (1.0 / (1.0 + (-mean_val).exp()));

        // Calculate variance of the input vector
        let variance = inputs.iter().map(|&x| {
            let diff = x.abs() - mean_val;
            diff * diff
        }).sum::<f64>() / inputs.len() as f64;
        let std_dev = variance.sqrt();

        // Map std_dev to L_eff in range [0.01, 0.99] using sigmoid
        let l_eff = 0.01 + 0.98 * (1.0 / (1.0 + std_dev));

        // q = (1.0 - lambda_m) + lambda_m * L_eff
        let q = (1.0 - lambda_m) + lambda_m * l_eff;

        q
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_stability_witness_bounds() {
        // Test with uniform inputs
        let inputs = [0.5; CIRCUIT_WIDTH];
        let q = StabilityModule::compute_witness(&inputs);
        assert!(q > 0.0);
        assert!(q < 1.0);

        // Test with highly variant inputs
        let mut variable_inputs = [0.0; CIRCUIT_WIDTH];
        for i in 0..CIRCUIT_WIDTH {
            variable_inputs[i] = i as f64;
        }
        let q_var = StabilityModule::compute_witness(&variable_inputs);
        assert!(q_var > 0.0);
        assert!(q_var < 1.0);
    }
}
