use ndarray::Array1;

/// Represents a mathematical boundary for a forbidden state-space region
/// (i.e. an "unethical" or recursively harmful attractor state).
pub trait Attractor {
    /// Compute the soft lawfulness penalty (L_CSL) given the current state.
    /// This should act as a repulsive force (e.g., inverse-square distance or log barrier)
    /// increasing as the state approaches the forbidden region.
    fn penalty(&self, state: &Array1<f64>) -> f64;

    /// Compute the gradient of the penalty with respect to the state.
    fn penalty_gradient(&self, state: &Array1<f64>) -> Array1<f64>;
}

/// A simple spherical forbidden attractor.
pub struct SphericalAttractor {
    pub center: Array1<f64>,
    pub radius: f64,
    pub barrier_strength: f64,
}

impl Attractor for SphericalAttractor {
    fn penalty(&self, state: &Array1<f64>) -> f64 {
        let dist_sq = state
            .iter()
            .zip(self.center.iter())
            .map(|(s, c)| (s - c).powi(2))
            .sum::<f64>();
        let dist = dist_sq.sqrt();
        if dist <= self.radius {
            // Hard boundary: large finite penalty (avoids f64::INFINITY which
            // can poison downstream arithmetic / Kani bounds).
            self.barrier_strength / 1e-12
        } else {
            // Inverse distance penalty (repulsive barrier)
            self.barrier_strength / (dist - self.radius)
        }
    }

    fn penalty_gradient(&self, state: &Array1<f64>) -> Array1<f64> {
        let dist_sq = state
            .iter()
            .zip(self.center.iter())
            .map(|(s, c)| (s - c).powi(2))
            .sum::<f64>();
        let dist = dist_sq.sqrt();
        let mut grad = Array1::zeros(state.len());

        if dist <= self.radius || dist == 0.0 {
            return grad;
        }

        let diff = (dist - self.radius).max(1e-12);
        let denom = diff.powi(2) * dist.max(1e-12);
        let coeff = -self.barrier_strength / denom;
        for i in 0..state.len() {
            grad[i] = coeff * (state[i] - self.center[i]);
        }
        grad
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn penalty_increases_as_state_approaches_center() {
        let center = Array1::from_vec(vec![0.0, 0.0]);
        let attr = SphericalAttractor {
            center,
            radius: 1.0,
            barrier_strength: 0.5,
        };
        let far = Array1::from_vec(vec![5.0, 0.0]);
        let near = Array1::from_vec(vec![1.5, 0.0]);
        assert!(attr.penalty(&near) > attr.penalty(&far));
    }

    #[test]
    fn gradient_points_toward_center_inside_radius_region() {
        // At a point to the +x of the origin, the repulsive gradient must point
        // in -x (away from center, since step = state - lr*grad moves away).
        let center = Array1::from_vec(vec![0.0, 0.0]);
        let attr = SphericalAttractor {
            center,
            radius: 1.0,
            barrier_strength: 0.5,
        };
        let state = Array1::from_vec(vec![3.0, 0.0]);
        let grad = attr.penalty_gradient(&state);
        // coeff is negative, so grad[0] = coeff * (3 - 0) < 0 => step moves +x.
        assert!(grad[0] < 0.0);
        assert!(grad[1].abs() < 1e-9);
    }

    #[test]
    fn penalty_finite_outside_radius() {
        let center = Array1::from_vec(vec![0.0, 0.0]);
        let attr = SphericalAttractor {
            center,
            radius: 1.0,
            barrier_strength: 0.5,
        };
        let state = Array1::from_vec(vec![2.0, 0.0]);
        let p = attr.penalty(&state);
        assert!(p.is_finite() && p > 0.0);
    }
}
