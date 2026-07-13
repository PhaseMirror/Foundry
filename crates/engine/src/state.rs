use crate::sigma_layer::{ZeroModeExtractable, ZeroModeQuantities, CertificationError};
use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct PrimeChannel {
    pub prime_index: u64,
    pub weight: f64,
}

#[derive(Debug, Clone)]
pub struct SkeletonState {
    /// Maps to the base skeleton magnitude: |Xi(t)|
    pub operator_norm: f64, 
}

#[derive(Debug, Clone)]
pub struct TensorMapState {
    /// Maps to the Lipschitz constant of the tensor map: L_T
    pub lipschitz_bound: f64, 
}

#[derive(Debug, Clone)]
pub struct RuntimeState {
    pub skeleton: SkeletonState,
    pub tensor_map: TensorMapState,
    pub active_channels: Vec<PrimeChannel>,
}

impl ZeroModeExtractable for RuntimeState {
    fn extract_zm_quantities(&self) -> Result<ZeroModeQuantities, CertificationError> {
        let mut prime_weights = HashMap::new();

        // Map the active channels into the HashMap expected by the certification layer.
        // We take the absolute value of the weight, as the ZM gain bound 
        // is concerned with absolute magnitude |lambda_p(t)|.
        for channel in &self.active_channels {
            prime_weights.insert(channel.prime_index, channel.weight.abs());
        }

        Ok(ZeroModeQuantities {
            xi_magnitude: self.skeleton.operator_norm,
            lipschitz_t: self.tensor_map.lipschitz_bound,
            prime_weights,
        })
    }
}
