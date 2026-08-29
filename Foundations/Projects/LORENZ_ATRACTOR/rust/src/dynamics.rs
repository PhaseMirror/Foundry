use serde::{Deserialize, Serialize};
use crate::core::{LorenzPoint, LorenzParams, LorenzState};
use crate::jacobian::{compute_spectral_multiplicity, instantaneous_stability_rate};

/// 3-Axis 3rd-Order Tensor Interaction contributions $(T_x, T_y, T_z)$.
///
/// $$T_{ijk} = x_i \otimes y_j \otimes z_k$$
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct TensorCoupling {
    pub tx: f64,
    pub ty: f64,
    pub tz: f64,
}

impl TensorCoupling {
    pub fn zero() -> Self {
        Self { tx: 0.0, ty: 0.0, tz: 0.0 }
    }

    /// Compute 3rd-order tensor network interaction across coordinates.
    pub fn compute(p: &LorenzPoint, scale: f64) -> Self {
        let xyz = p.x * p.y * p.z;
        let t = (xyz * scale).clamp(-50.0, 50.0);
        Self { tx: t, ty: t, tz: t }
    }
}

/// Harmonic and stochastic oscillator feedback terms at time step `t`.
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct HarmonicFeedback {
    pub hx: f64,
    pub hy: f64,
    pub hz: f64,
}

impl HarmonicFeedback {
    pub fn zero() -> Self {
        Self { hx: 0.0, hy: 0.0, hz: 0.0 }
    }

    /// Compute harmonic feedback oscillations using prime frequency modulations.
    pub fn compute(t: u64, amplitude: f64) -> Self {
        let omega = (t as f64 * 0.07) % (2.0 * std::f64::consts::PI);
        let hx = amplitude * omega.cos() * 0.2;
        let hy = amplitude * omega.sin() * 0.2;
        let hz = amplitude * (-0.01 * t as f64).exp() * 0.2;
        Self { hx, hy, hz }
    }
}

/// Multiplicity Adaptive Negative Feedback damping $f_i(t) = \alpha_i \cdot \frac{\partial S}{\partial \lambda_i}$.
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct MultiplicityFeedback {
    pub fx: f64,
    pub fy: f64,
    pub fz: f64,
}

impl MultiplicityFeedback {
    pub fn zero() -> Self {
        Self { fx: 0.0, fy: 0.0, fz: 0.0 }
    }

    /// Compute restorative feedback when eigenvalue multiplicity indicates instability ($\Lambda(t) < 0$).
    pub fn compute(p: &LorenzPoint, lambda_mult: f64, alpha_gain: f64) -> Self {
        let damping = if lambda_mult < 0.0 {
            (alpha_gain * (-lambda_mult) * 0.001).clamp(0.0, 10.0)
        } else {
            0.0
        };

        Self {
            fx: -p.x * damping * 0.01,
            fy: -p.y * damping * 0.01,
            fz: -p.z * damping * 0.01,
        }
    }
}

/// Classical Lorenz system velocity field:
///
/// $$\dot{x} = \sigma (y - x)$$
/// $$\dot{y} = x (\rho - z) - y$$
/// $$\dot{z} = x y - \beta z$$
pub fn classical_velocity(p: &LorenzPoint, params: &LorenzParams) -> LorenzPoint {
    let dx = params.sigma * (p.y - p.x);
    let dy = p.x * (params.rho - p.z) - p.y;
    let dz = p.x * p.y - params.beta * p.z;
    LorenzPoint::new(dx, dy, dz)
}

/// Unified Multiplicity velocity field incorporating classical flow, tensor coupling, harmonic feedback, and Multiplicity stabilization:
///
/// $$\mathbf{v}_{\text{unified}} = \mathbf{v}_{\text{classical}} + \mathbf{f}_{\text{multiplicity}} + \mathbf{T} + \mathbf{h}$$
pub fn unified_velocity(
    p: &LorenzPoint,
    t: u64,
    params: &LorenzParams,
    lambda_mult: f64,
    alpha_gain: f64,
) -> LorenzPoint {
    let v_class = classical_velocity(p, params);
    let tensor = TensorCoupling::compute(p, 0.0001);
    let harmonic = HarmonicFeedback::compute(t, 1.0);
    let mult_fb = MultiplicityFeedback::compute(p, lambda_mult, alpha_gain);

    LorenzPoint::new(
        v_class.x + mult_fb.fx + tensor.tx + harmonic.hx,
        v_class.y + mult_fb.fy + tensor.ty + harmonic.hy,
        v_class.z + mult_fb.fz + tensor.tz + harmonic.hz,
    )
}

/// Single integration step using Euler's method.
pub fn euler_step(
    state: &LorenzState,
    params: &LorenzParams,
    alpha_gain: f64,
    dt: f64,
    max_bound: f64,
) -> LorenzState {
    let lambda_mult = compute_spectral_multiplicity(&state.point, params);
    let v = unified_velocity(&state.point, state.time, params, lambda_mult, alpha_gain);

    let next_p = LorenzPoint::new(
        state.point.x + v.x * dt,
        state.point.y + v.y * dt,
        state.point.z + v.z * dt,
    ).clamp(max_bound);

    let inst_rate = instantaneous_stability_rate(lambda_mult);
    let next_stability = state.stability_integral + inst_rate * dt;

    LorenzState {
        time: state.time + 1,
        point: next_p,
        velocity: v,
        lambda_multiplicity: lambda_mult,
        stability_integral: next_stability,
    }
}

/// Single high-precision integration step using 4th-Order Runge-Kutta (RK4).
pub fn rk4_step(
    state: &LorenzState,
    params: &LorenzParams,
    alpha_gain: f64,
    dt: f64,
    max_bound: f64,
) -> LorenzState {
    let lambda_mult = compute_spectral_multiplicity(&state.point, params);
    let t = state.time;

    // k1 = f(y_n)
    let k1 = unified_velocity(&state.point, t, params, lambda_mult, alpha_gain);

    // k2 = f(y_n + 0.5*dt*k1)
    let p_k2 = state.point.add(&k1.scale(0.5 * dt));
    let k2 = unified_velocity(&p_k2, t, params, lambda_mult, alpha_gain);

    // k3 = f(y_n + 0.5*dt*k2)
    let p_k3 = state.point.add(&k2.scale(0.5 * dt));
    let k3 = unified_velocity(&p_k3, t, params, lambda_mult, alpha_gain);

    // k4 = f(y_n + dt*k3)
    let p_k4 = state.point.add(&k3.scale(dt));
    let k4 = unified_velocity(&p_k4, t, params, lambda_mult, alpha_gain);

    // next_point = y_n + (dt/6) * (k1 + 2*k2 + 2*k3 + k4)
    let net_dx = (k1.x + 2.0 * k2.x + 2.0 * k3.x + k4.x) / 6.0;
    let net_dy = (k1.y + 2.0 * k2.y + 2.0 * k3.y + k4.y) / 6.0;
    let net_dz = (k1.z + 2.0 * k2.z + 2.0 * k3.z + k4.z) / 6.0;
    let net_v = LorenzPoint::new(net_dx, net_dy, net_dz);

    let next_p = LorenzPoint::new(
        state.point.x + net_dx * dt,
        state.point.y + net_dy * dt,
        state.point.z + net_dz * dt,
    ).clamp(max_bound);

    let inst_rate = instantaneous_stability_rate(lambda_mult);
    let next_stability = state.stability_integral + inst_rate * dt;

    LorenzState {
        time: state.time + 1,
        point: next_p,
        velocity: net_v,
        lambda_multiplicity: lambda_mult,
        stability_integral: next_stability,
    }
}

/// Numerical Integrator Method choice.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IntegratorMethod {
    Euler,
    RungeKutta4,
}

/// Multi-step trajectory generator.
pub fn simulate_trajectory(
    initial: LorenzState,
    params: &LorenzParams,
    alpha_gain: f64,
    dt: f64,
    steps: usize,
    method: IntegratorMethod,
    max_bound: f64,
) -> (LorenzState, Vec<LorenzPoint>) {
    let mut history = Vec::with_capacity(steps);
    let mut current = initial;

    for _ in 0..steps {
        current = match method {
            IntegratorMethod::Euler => euler_step(&current, params, alpha_gain, dt, max_bound),
            IntegratorMethod::RungeKutta4 => rk4_step(&current, params, alpha_gain, dt, max_bound),
        };
        history.push(current.point);
    }

    (current, history)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_origin_is_stationary_equilibrium() {
        let params = LorenzParams::canonical();
        let v0 = classical_velocity(&LorenzPoint::origin(), &params);
        assert_eq!(v0, LorenzPoint::origin());
    }

    #[test]
    fn test_velocity_at_initial_point() {
        let params = LorenzParams::canonical();
        let p0 = LorenzPoint::standard_initial();
        let v = classical_velocity(&p0, &params);
        // dx = 10 * (1 - 1) = 0
        // dy = 1 * (28 - 1) - 1 = 26
        // dz = 1 * 1 - (8/3) * 1 = -5/3 ~ -1.6666...
        assert_eq!(v.x, 0.0);
        assert_eq!(v.y, 26.0);
        assert!((v.z - (-5.0 / 3.0)).abs() < 1e-10);
    }

    #[test]
    fn test_rk4_step_monotonic_clock_and_boundedness() {
        let params = LorenzParams::canonical();
        let st0 = LorenzState::initial(LorenzPoint::standard_initial());
        let st1 = rk4_step(&st0, &params, 0.5, 0.01, 100.0);

        assert_eq!(st1.time, 1);
        assert!(st1.stability_integral >= st0.stability_integral);
        assert!(st1.point.norm() < 100.0);
    }

    #[test]
    fn test_trajectory_simulation_length() {
        let params = LorenzParams::canonical();
        let st0 = LorenzState::initial(LorenzPoint::standard_initial());
        let (final_st, history) = simulate_trajectory(
            st0,
            &params,
            0.5,
            0.01,
            50,
            IntegratorMethod::RungeKutta4,
            100.0,
        );

        assert_eq!(final_st.time, 50);
        assert_eq!(history.len(), 50);
        assert!(final_st.point.norm() < 100.0);
    }
}
