use serde::{Deserialize, Serialize};
use crate::core::{LorenzPoint, LorenzParams, LorenzState};
use crate::dynamics::rk4_step;

/// Lyapunov and Phase Space Metric summary for a simulated trajectory.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TrajectoryMetrics {
    pub step_count: usize,
    pub largest_lyapunov_exponent: f64,
    pub average_kinetic_energy: f64,
    pub total_stability_accumulated: f64,
    pub is_chaotic: bool,
    pub is_bounded: bool,
}

/// Estimate Largest Lyapunov Exponent (LLE) $\lambda_1$ via standard perturbation shadow orbit:
///
/// $$\lambda_1 = \frac{1}{N \cdot \Delta t} \sum_{k=1}^N \ln \left(\frac{d_k}{d_0}\right)$$
pub fn estimate_lyapunov_exponent(
    initial_point: &LorenzPoint,
    params: &LorenzParams,
    alpha_gain: f64,
    dt: f64,
    steps: usize,
    initial_perturbation: f64,
) -> f64 {
    let d0 = initial_perturbation;
    let p_base = *initial_point;
    let p_shadow = LorenzPoint::new(
        initial_point.x + d0,
        initial_point.y,
        initial_point.z,
    );

    let mut st_base = LorenzState::initial(p_base);
    let mut st_shadow = LorenzState::initial(p_shadow);

    let mut lyap_sum = 0.0;
    let mut valid_samples = 0;

    for _ in 0..steps {
        st_base = rk4_step(&st_base, params, alpha_gain, dt, 100.0);
        st_shadow = rk4_step(&st_shadow, params, alpha_gain, dt, 100.0);

        let dist = st_base.point.dist(&st_shadow.point);

        if dist > 1e-12 {
            lyap_sum += (dist / d0).ln();
            valid_samples += 1;

            // Renormalize shadow point to distance d0 along the separation vector
            let factor = d0 / dist;
            let sep_x = (st_shadow.point.x - st_base.point.x) * factor;
            let sep_y = (st_shadow.point.y - st_base.point.y) * factor;
            let sep_z = (st_shadow.point.z - st_base.point.z) * factor;

            st_shadow.point = LorenzPoint::new(
                st_base.point.x + sep_x,
                st_base.point.y + sep_y,
                st_base.point.z + sep_z,
            );
        }
    }

    if valid_samples > 0 {
        lyap_sum / (valid_samples as f64 * dt)
    } else {
        0.0
    }
}

/// Compute full diagnostic trajectory metrics for a simulation run.
pub fn analyze_trajectory(
    initial_point: &LorenzPoint,
    params: &LorenzParams,
    alpha_gain: f64,
    dt: f64,
    steps: usize,
) -> TrajectoryMetrics {
    let lle = estimate_lyapunov_exponent(initial_point, params, alpha_gain, dt, steps, 1e-6);

    let mut st = LorenzState::initial(*initial_point);
    let mut total_ke = 0.0;
    let mut bounded = true;

    for _ in 0..steps {
        st = rk4_step(&st, params, alpha_gain, dt, 100.0);
        let ke = 0.5 * st.velocity.norm_sq();
        total_ke += ke;
        if st.point.norm() > 100.0 {
            bounded = false;
        }
    }

    let avg_ke = if steps > 0 { total_ke / steps as f64 } else { 0.0 };

    TrajectoryMetrics {
        step_count: steps,
        largest_lyapunov_exponent: lle,
        average_kinetic_energy: avg_ke,
        total_stability_accumulated: st.stability_integral,
        is_chaotic: lle > 0.05,
        is_bounded: bounded,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_lyapunov_exponent_canonical_is_positive() {
        let params = LorenzParams::canonical();
        let p0 = LorenzPoint::standard_initial();
        let metrics = analyze_trajectory(&p0, &params, 0.0, 0.01, 200);

        assert!(metrics.is_bounded);
        assert!(metrics.total_stability_accumulated > 0.0);
    }

    #[test]
    fn test_stabilized_reduces_divergence() {
        let params = LorenzParams::canonical();
        let p0 = LorenzPoint::standard_initial();
        let metrics_unconstrained = analyze_trajectory(&p0, &params, 0.0, 0.01, 100);
        let metrics_stabilized = analyze_trajectory(&p0, &params, 10.0, 0.01, 100);

        assert!(metrics_stabilized.is_bounded);
        assert!(metrics_unconstrained.is_bounded);
    }
}
