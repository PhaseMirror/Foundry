use crate::scn::KernelTelemetry;

pub struct SCNWeights {
    // Mock weights structure
}

impl SCNWeights {
    pub fn forward(&self, features: &[f64]) -> Vec<f64> {
        // Mock forward pass returning same dimension as features
        features.to_vec()
    }
}

pub struct SCNConditioningLayer {
    pub feature_dim_base: usize,
    pub telemetry_dim: usize,
}

impl SCNConditioningLayer {
    pub fn new() -> Self {
        Self {
            feature_dim_base: 0, // computed from operator A and gap ĝ
            telemetry_dim: 5,    // xn, wt_max, zeta, is_valid, version
        }
    }

    pub fn extend_feature_vector(
        &self,
        base_features: &[f64],
        telemetry: &KernelTelemetry,
    ) -> Vec<f64> {
        let mut extended = base_features.to_vec();
        extended.push(telemetry.xn_kernel);
        extended.push(telemetry.wt_max_kernel);
        extended.push(telemetry.protection_zeta);
        extended.push(if telemetry.is_valid_kernel { 1.0 } else { 0.0 });
        extended.push(telemetry.telemetry_version as f64);
        extended
    }

    pub fn policy_logits(
        &self,
        features: &[f64],
        weights: &SCNWeights,
    ) -> Vec<f64> {
        // SCN forward pass conditioned on extended feature vector.
        // The network architecture is unchanged; only input width increases.
        weights.forward(features)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_extend_feature_vector() {
        let layer = SCNConditioningLayer::new();
        let base_features = vec![0.5, 0.5];
        let kt = KernelTelemetry {
            xn_kernel: 0.1,
            wt_max_kernel: 0.2,
            protection_zeta: 0.3,
            is_valid_kernel: true,
            telemetry_version: 1,
        };
        let extended = layer.extend_feature_vector(&base_features, &kt);
        assert_eq!(extended.len(), 7);
        assert_eq!(extended[2], 0.1);
        assert_eq!(extended[3], 0.2);
        assert_eq!(extended[4], 0.3);
        assert_eq!(extended[5], 1.0);
        assert_eq!(extended[6], 1.0);
    }
}
