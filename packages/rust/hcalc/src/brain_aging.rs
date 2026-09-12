use serde::{Deserialize, Serialize};
use nalgebra::{DMatrix, DVector};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BrainAgingParams {
    pub a0: f64,
    pub a1: f64,
    pub a2: f64,
    pub a3: f64,
    pub b1: f64,
    pub b2: f64,
    pub b3: f64,
    pub bC: f64,
    pub s0: f64,
    pub s2: f64,
    pub k0: f64,
    pub k1: f64,
    pub c1: f64,
    pub c0: f64,
    pub t0: f64,
    pub tW: f64,
    pub tS: f64,
    pub tI: f64,
    pub lC: f64,
    pub p0: f64,
    pub pW: f64,
    pub pS: f64,
    pub pI: f64,
    pub lM: f64,
    pub qW: f64,
    pub qS: f64,
    pub qI: f64,
    pub qC: f64,
    pub qM: f64,
    pub m0: f64,
    pub m1: f64,
    pub b0: f64,
    pub d0: f64,
    pub d1: f64,
    pub e0: f64,
    pub e1: f64,
    pub p16_0: f64,
    pub p16_1: f64,
    pub r0: f64,
    pub rS: f64,
    pub rI: f64,
    pub ps0: f64,
    pub ps1: f64,
    pub f0: f64,
    pub f1: f64,
    pub g0: f64,
    pub g1: f64,
    pub h0: f64,
    pub h1: f64,
    pub measurement_noise: f64,
}

impl Default for BrainAgingParams {
    fn default() -> Self {
        BrainAgingParams {
            a0: 0.020, a1: 0.25, a2: 0.06, a3: 0.05,
            b1: 0.10, b2: 0.05, b3: 0.08, bC: 0.04,
            s0: 0.010, s2: 0.06, k0: 0.10, k1: 0.30,
            c1: 0.50, c0: 0.60,
            t0: 0.00, tW: 0.80, tS: 0.20, tI: 0.20, lC: 0.50,
            p0: 0.00, pW: 0.70, pS: 0.15, pI: 0.15, lM: 0.60,
            qW: 0.03, qS: 0.03, qI: 0.05, qC: 0.06, qM: 0.06,
            m0: 0.50, m1: 0.20, b0: 0.10,
            d0: 0.05, d1: 0.15, e0: 0.08, e1: 0.12,
            p16_0: 0.06, p16_1: 0.20,
            r0: 0.04, rS: 0.08, rI: 0.10,
            ps0: 0.02, ps1: 0.16,
            f0: 0.03, f1: 0.14,
            g0: 0.01, g1: 0.10,
            h0: 0.01, h1: 0.11,
            measurement_noise: 0.05,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BrainAgingState {
    pub w: f64,
    pub s: f64,
    pub i: f64,
    pub c: f64,
    pub m: f64,
    pub a: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct BrainAgingInput {
    pub u_e: f64,
    pub u_n: f64,
    pub u_l: f64,
    pub u_m: f64,
    pub u_eng: f64,
}

pub fn sigma(u: f64) -> f64 {
    u / (1.0 + u)
}

pub fn state_derivative(
    state: &BrainAgingState,
    inputs: &BrainAgingInput,
    params: &BrainAgingParams,
) -> DVector<f64> {
    let dw = -params.a0
        - params.a1 * state.w
        - params.a2 * state.s
        - params.a3 * state.i
        + params.b1 * sigma(inputs.u_e)
        + params.b2 * sigma(inputs.u_n)
        + params.b3 * sigma(inputs.u_m)
        + params.bC * state.c;
    
    let ds = params.s0 + params.s2 * state.i - params.k0 * state.s - params.k1 * sigma(inputs.u_l) * state.s;
    let di = params.c1 * state.s - params.c0 * state.i;
    let dc = params.t0 + params.tW * state.w - params.tS * state.s - params.tI * state.i - params.lC * state.c + 0.1 * inputs.u_eng;
    let dm = params.p0 + params.pW * state.w - params.pS * state.s - params.pI * state.i - params.lM * state.m;
    let da = 1.0;
    
    DVector::from_vec(vec![dw, ds, di, dc, dm, da])
}

pub fn step_state(
    state: &BrainAgingState,
    inputs: &BrainAgingInput,
    params: &BrainAgingParams,
    dt: f64,
) -> BrainAgingState {
    let delta = state_derivative(state, inputs, params);
    BrainAgingState {
        w: state.w + dt * delta[0],
        s: state.s + dt * delta[1],
        i: state.i + dt * delta[2],
        c: state.c + dt * delta[3],
        m: state.m + dt * delta[4],
        a: state.a + dt * delta[5],
    }
}

pub fn observation_model(state: &BrainAgingState, params: &BrainAgingParams) -> DVector<f64> {
    DVector::from_vec(vec![
        params.a0 + params.a1 * state.w,
        params.m0 - params.m1 * state.w,
        params.b0 + params.b1 * state.w,
        params.d0 + params.d1 * (1.0 - state.w),
        params.e0 + params.e1 * state.i,
        params.p16_0 + params.p16_1 * state.s,
        params.r0 + params.rS * state.s + params.rI * state.i,
        params.ps0 + params.ps1 * state.c,
        params.f0 + params.f1 * state.c,
        params.g0 + params.g1 * state.m,
        params.h0 + params.h1 * state.m,
    ])
}

pub fn measurement_jacobian(params: &BrainAgingParams) -> DMatrix<f64> {
    let mut h = DMatrix::zeros(11, 6);
    h[(0, 0)] = params.a1;
    h[(1, 0)] = -params.m1;
    h[(2, 0)] = params.b1;
    h[(3, 0)] = -params.d1;
    h[(4, 2)] = params.e1;
    h[(5, 1)] = params.p16_1;
    h[(6, 1)] = params.rS;
    h[(6, 2)] = params.rI;
    h[(7, 3)] = params.ps1;
    h[(8, 3)] = params.f1;
    h[(9, 4)] = params.g1;
    h[(10, 4)] = params.h1;
    h
}

pub fn state_jacobian(state: &BrainAgingState, inputs: &BrainAgingInput, params: &BrainAgingParams) -> DMatrix<f64> {
    let mut f = DMatrix::zeros(6, 6);
    f[(0, 0)] = -params.a1;
    f[(0, 1)] = -params.a2;
    f[(0, 2)] = -params.a3;
    f[(0, 3)] = params.bC;
    f[(1, 1)] = -params.k0 - params.k1 * sigma(inputs.u_l);
    f[(1, 2)] = params.s2;
    f[(2, 1)] = params.c1;
    f[(2, 2)] = -params.c0;
    f[(3, 0)] = params.tW;
    f[(3, 1)] = -params.tS;
    f[(3, 2)] = -params.tI;
    f[(3, 3)] = -params.lC;
    f[(4, 0)] = params.pW;
    f[(4, 1)] = -params.pS;
    f[(4, 2)] = params.pI;
    f[(4, 4)] = -params.lM;
    f
}

pub fn process_noise_covariance(params: &BrainAgingParams, dt: f64) -> DMatrix<f64> {
    DMatrix::from_diagonal(&DVector::from_vec(vec![
        (params.qW * dt).powi(2),
        (params.qS * dt).powi(2),
        (params.qI * dt).powi(2),
        (params.qC * dt).powi(2),
        (params.qM * dt).powi(2),
        1e-6,
    ]))
}

pub fn measurement_noise_covariance(params: &BrainAgingParams) -> DMatrix<f64> {
    DMatrix::identity(11, 11) * params.measurement_noise.powi(2)
}

pub fn ekf_predict(
    x: &DVector<f64>,
    p: &DMatrix<f64>,
    state: &BrainAgingState,
    inputs: &BrainAgingInput,
    params: &BrainAgingParams,
    dt: f64,
) -> (DVector<f64>, DMatrix<f64>) {
    let f_jac = state_jacobian(state, inputs, params);
    let x_pred = x + dt * state_derivative(state, inputs, params);
    let p_pred = &f_jac * p * f_jac.transpose() + process_noise_covariance(params, dt);
    (x_pred, p_pred)
}

pub fn ekf_update(
    x_pred: &DVector<f64>,
    p_pred: &DMatrix<f64>,
    observation: &DVector<f64>,
    params: &BrainAgingParams,
) -> (DVector<f64>, DMatrix<f64>) {
    let h_jac = measurement_jacobian(params);
    let state_pred = BrainAgingState {
        w: x_pred[0], s: x_pred[1], i: x_pred[2], c: x_pred[3], m: x_pred[4], a: x_pred[5]
    };
    let y_pred = observation_model(&state_pred, params);
    let r = measurement_noise_covariance(params);
    let s = &h_jac * p_pred * h_jac.transpose() + r;
    
    // Pseudo-inverse using SVD
    let svd = s.svd(true, true);
    let s_inv = svd.pseudo_inverse(1e-12).unwrap();
    
    let k_gain = p_pred * h_jac.transpose() * s_inv;
    let delta = observation - y_pred;
    let x_updated = x_pred + &k_gain * delta;
    let p_updated = p_pred - &k_gain * h_jac * p_pred;
    (x_updated, p_updated)
}
