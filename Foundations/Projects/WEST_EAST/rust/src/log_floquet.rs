//! Log-Floquet Temporal Bridge & Unitary Propagator

use num_complex::Complex64;
use serde::{Deserialize, Serialize};

/// 2x2 Skew-Hermitian Generator: A* = -A
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct SkewHermitian2x2 {
    pub d1: f64, // i * d1 on diagonal (0,0)
    pub d2: f64, // i * d2 on diagonal (1,1)
    pub off: Complex64, // off-diagonal (0,1), where (1,0) is -off*
}

impl SkewHermitian2x2 {
    pub fn new(d1: f64, d2: f64, off: Complex64) -> Self {
        Self { d1, d2, off }
    }

    /// Evaluates A(ϕ + Ω s, s) with periodic modulation and logarithmic scaling s = log t.
    pub fn evaluate_time_dependent(phi: f64, omega: f64, s: f64, epsilon: f64) -> Self {
        let phase = phi + omega * s;
        let mod_val = epsilon * phase.sin();
        Self {
            d1: 1.0 + mod_val,
            d2: -1.0 - mod_val,
            off: Complex64::new(0.5 * phase.cos(), 0.5 * phase.sin()) * epsilon,
        }
    }
}

/// 2x2 Unitary Matrix representing T(ϕ, t).
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct Unitary2x2 {
    pub u00: (f64, f64),
    pub u01: (f64, f64),
    pub u10: (f64, f64),
    pub u11: (f64, f64),
}

impl Unitary2x2 {
    pub fn identity() -> Self {
        Self {
            u00: (1.0, 0.0),
            u01: (0.0, 0.0),
            u10: (0.0, 0.0),
            u11: (1.0, 0.0),
        }
    }

    pub fn mul(&self, other: &Self) -> Self {
        let a00 = Complex64::new(self.u00.0, self.u00.1);
        let a01 = Complex64::new(self.u01.0, self.u01.1);
        let a10 = Complex64::new(self.u10.0, self.u10.1);
        let a11 = Complex64::new(self.u11.0, self.u11.1);

        let b00 = Complex64::new(other.u00.0, other.u00.1);
        let b01 = Complex64::new(other.u01.0, other.u01.1);
        let b10 = Complex64::new(other.u10.0, other.u10.1);
        let b11 = Complex64::new(other.u11.0, other.u11.1);

        let c00 = a00 * b00 + a01 * b10;
        let c01 = a00 * b01 + a01 * b11;
        let c10 = a10 * b00 + a11 * b10;
        let c11 = a10 * b01 + a11 * b11;

        Self {
            u00: (c00.re, c00.im),
            u01: (c01.re, c01.im),
            u10: (c10.re, c10.im),
            u11: (c11.re, c11.im),
        }
    }

    /// Compute Frobenius norm distance to another unitary matrix.
    pub fn distance(&self, other: &Self) -> f64 {
        let d00 = Complex64::new(self.u00.0 - other.u00.0, self.u00.1 - other.u00.1).norm_sqr();
        let d01 = Complex64::new(self.u01.0 - other.u01.0, self.u01.1 - other.u01.1).norm_sqr();
        let d10 = Complex64::new(self.u10.0 - other.u10.0, self.u10.1 - other.u10.1).norm_sqr();
        let d11 = Complex64::new(self.u11.0 - other.u11.0, self.u11.1 - other.u11.1).norm_sqr();
        (d00 + d01 + d10 + d11).sqrt()
    }
}

pub struct LogFloquetPropagator;

impl LogFloquetPropagator {
    /// Path-ordered exponential integration: T(ϕ, t) = P exp(∫_0^{log t} A(ϕ + Ω s, s) ds).
    pub fn propagate(phi: f64, omega: f64, t: f64, epsilon: f64, steps: usize) -> Unitary2x2 {
        let log_t = t.ln().max(0.0);
        if log_t < 1e-12 || steps == 0 {
            return Unitary2x2::identity();
        }

        let ds = log_t / (steps as f64);
        let mut u = Unitary2x2::identity();

        for i in 0..steps {
            let s = (i as f64 + 0.5) * ds;
            let gen = SkewHermitian2x2::evaluate_time_dependent(phi, omega, s, epsilon);

            // Step unitary approximation: exp(A * ds) ≈ I + A * ds
            let exp_step = Unitary2x2 {
                u00: (1.0, gen.d1 * ds),
                u01: (-gen.off.im * ds, gen.off.re * ds),
                u10: (gen.off.im * ds, -gen.off.re * ds),
                u11: (1.0, gen.d2 * ds),
            };

            u = exp_step.mul(&u);
        }

        u
    }

    /// Evaluates seasonal drift against the unmodulated average generator.
    pub fn compute_seasonal_drift(phi: f64, omega: f64, t: f64, epsilon: f64, steps: usize) -> (f64, f64) {
        let u_mod = Self::propagate(phi, omega, t, epsilon, steps);
        let u_unmod = Self::propagate(phi, omega, t, 0.0, steps);
        let actual_drift = u_mod.distance(&u_unmod);
        let sup_norm_a_diff = (2.5f64).sqrt() * epsilon;
        let theoretical_bound = sup_norm_a_diff * t.ln().max(0.0);
        (actual_drift, theoretical_bound)
    }
}
