use serde::{Deserialize, Serialize};
use crate::core::{DELTA_I, ALPHA_NL};
use crate::algebra::nonlinear_regularization;

/// Complex number representation for quantum state amplitudes.
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct Complex64 {
    pub re: f64,
    pub im: f64,
}

impl Complex64 {
    pub const fn new(re: f64, im: f64) -> Self {
        Self { re, im }
    }

    pub fn norm_sq(&self) -> f64 {
        self.re * self.re + self.im * self.im
    }

    pub fn add(&self, other: &Complex64) -> Self {
        Self {
            re: self.re + other.re,
            im: self.im + other.im,
        }
    }

    pub fn mul(&self, other: &Complex64) -> Self {
        Self {
            re: self.re * other.re - self.im * other.im,
            im: self.re * other.im + self.im * other.re,
        }
    }

    pub fn scale(&self, s: f64) -> Self {
        Self {
            re: self.re * s,
            im: self.im * s,
        }
    }
}

/// Quantum Bayesian Network State representation.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct QBNState {
    pub time: u64,
    pub amplitudes: Vec<Complex64>,
    pub posterior_probability: f64,
}

impl QBNState {
    pub fn new_2qubit() -> Self {
        // Initialize in equal superposition |00> + |01> + |10> + |11>
        let amp = Complex64::new(0.5, 0.0);
        Self {
            time: 0,
            amplitudes: vec![amp, amp, amp, amp],
            posterior_probability: 0.5,
        }
    }
}

/// Quantum Bayesian update:
///
/// $$P(X_q \mid E) = \frac{P(X_q, E)}{P(E)}$$
pub fn quantum_bayesian_update(p_joint: f64, p_evidence: f64) -> f64 {
    if p_evidence <= 1e-12 {
        0.0
    } else {
        (p_joint / p_evidence).clamp(0.0, 1.0)
    }
}

/// Unitary 2x2 rotation gate $U_q = \exp(-i q H)$.
pub fn apply_unitary_rotation(state: &mut [Complex64], theta: f64) {
    let cos_t = theta.cos();
    let sin_t = theta.sin();

    for amp in state.iter_mut() {
        let new_re = amp.re * cos_t - amp.im * sin_t;
        let new_im = amp.re * sin_t + amp.im * cos_t;
        amp.re = new_re;
        amp.im = new_im;
    }
}

/// Single QMI step evolving quantum Bayesian state:
///
/// $$|\Psi(t+1)\rangle = U_q |\Psi(t)\rangle + \delta_I \cdot T + Q_{\text{Bayes}} + S_f$$
pub fn qmi_step(st: &QBNState, evidence: f64) -> QBNState {
    let mut new_amps = st.amplitudes.clone();
    apply_unitary_rotation(&mut new_amps, 0.05);

    // Add interaction depth term
    for amp in new_amps.iter_mut() {
        amp.re += DELTA_I * 0.01;
    }

    // Normalize quantum amplitudes
    let total_norm_sq: f64 = new_amps.iter().map(|a| a.norm_sq()).sum();
    if total_norm_sq > 1e-12 {
        let norm_factor = 1.0 / total_norm_sq.sqrt();
        for amp in new_amps.iter_mut() {
            *amp = amp.scale(norm_factor);
        }
    }

    let p_joint = new_amps[0].norm_sq();
    let posterior = quantum_bayesian_update(p_joint, evidence.max(0.01));

    QBNState {
        time: st.time + 1,
        amplitudes: new_amps,
        posterior_probability: posterior,
    }
}

/// Recursive weight matrix optimization:
///
/// $$W(t+1) = W(t) + \delta_I \cdot \nabla L(W(t)) + R_{\text{nl}}(W(t)) + Q_{\text{AI}}$$
pub fn recursive_weight_update(
    w: f64,
    grad_l: f64,
    q_ai: f64,
) -> f64 {
    let delta_term = DELTA_I * grad_l;
    let r_term = nonlinear_regularization(w, ALPHA_NL);
    w + delta_term + r_term + q_ai
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_complex_algebra() {
        let c1 = Complex64::new(3.0, 4.0);
        assert_eq!(c1.norm_sq(), 25.0);

        let c2 = Complex64::new(1.0, -1.0);
        let c3 = c1.mul(&c2);
        // (3 + 4i)(1 - i) = 3 - 3i + 4i - 4i^2 = 7 + i
        assert_eq!(c3.re, 7.0);
        assert_eq!(c3.im, 1.0);
    }

    #[test]
    fn test_quantum_bayesian_update_bounds() {
        let p = quantum_bayesian_update(0.3, 0.6);
        assert!((p - 0.5).abs() < 1e-10);

        let p_zero = quantum_bayesian_update(0.0, 0.6);
        assert_eq!(p_zero, 0.0);
    }

    #[test]
    fn test_qmi_state_evolution() {
        let st0 = QBNState::new_2qubit();
        let st1 = qmi_step(&st0, 0.5);

        assert_eq!(st1.time, 1);
        assert!(st1.posterior_probability >= 0.0 && st1.posterior_probability <= 1.0);
    }
}
