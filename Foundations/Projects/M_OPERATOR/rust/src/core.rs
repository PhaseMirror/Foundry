use serde::{Deserialize, Serialize};

/// Golden ratio phi = (1 + sqrt(5)) / 2 ~ 1.6180339887...
pub const PHI: f64 = 1.6180339887498949;

/// Inverse Golden Ratio lambda_m = (sqrt(5) - 1) / 2 ~ 0.6180339887...
pub const LAMBDA_M: f64 = 0.6180339887498949;

/// Interaction Depth Constant delta_I = phi^-2 = 1 - lambda_m ~ 0.3819660112...
pub const DELTA_I: f64 = 0.38196601125010515;

/// Non-linear Regularization Factor alpha
pub const ALPHA_NL: f64 = 0.5;

/// Default Categorical Semantic Lawfulness (CSL) Coherence threshold epsilon
pub const EPSILON_CSL: f64 = 0.05;

/// Default Fixed-Point Denominator
pub const FP_DEN: i64 = 1000;

/// 3D Vectorized State Point in Continuous and Discrete Multiplicity Space.
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct MVector3 {
    pub x: f64,
    pub y: f64,
    pub z: f64,
}

impl MVector3 {
    pub const fn new(x: f64, y: f64, z: f64) -> Self {
        Self { x, y, z }
    }

    pub const fn zero() -> Self {
        Self { x: 0.0, y: 0.0, z: 0.0 }
    }

    pub const fn phi_target() -> Self {
        Self { x: PHI, y: PHI, z: PHI }
    }

    pub const fn lambda_m_target() -> Self {
        Self { x: LAMBDA_M, y: LAMBDA_M, z: LAMBDA_M }
    }

    pub fn e_target() -> Self {
        let e = std::f64::consts::E;
        Self { x: e, y: e, z: e }
    }

    pub fn pi_over_4_target() -> Self {
        let p = std::f64::consts::FRAC_PI_4;
        Self { x: p, y: p, z: p }
    }

    pub fn inv_sqrt_2_target() -> Self {
        let inv = 1.0 / std::f64::consts::SQRT_2;
        Self { x: inv, y: inv, z: inv }
    }

    pub fn prime_target(p: u64) -> Self {
        let inv_sqrt = 1.0 / (p as f64).sqrt();
        Self { x: inv_sqrt, y: inv_sqrt, z: inv_sqrt }
    }

    pub fn norm_sq(&self) -> f64 {
        self.x * self.x + self.y * self.y + self.z * self.z
    }

    pub fn norm(&self) -> f64 {
        self.norm_sq().sqrt()
    }

    pub fn dist_sq(&self, other: &MVector3) -> f64 {
        (self.x - other.x).powi(2) + (self.y - other.y).powi(2) + (self.z - other.z).powi(2)
    }

    pub fn dist(&self, other: &MVector3) -> f64 {
        self.dist_sq(other).sqrt()
    }

    pub fn add(&self, other: &MVector3) -> Self {
        Self {
            x: self.x + other.x,
            y: self.y + other.y,
            z: self.z + other.z,
        }
    }

    pub fn sub(&self, other: &MVector3) -> Self {
        Self {
            x: self.x - other.x,
            y: self.y - other.y,
            z: self.z - other.z,
        }
    }

    pub fn scale(&self, s: f64) -> Self {
        Self {
            x: self.x * s,
            y: self.y * s,
            z: self.z * s,
        }
    }

    pub fn clamp(&self, max_bound: f64) -> Self {
        Self {
            x: self.x.clamp(-max_bound, max_bound),
            y: self.y.clamp(-max_bound, max_bound),
            z: self.z.clamp(-max_bound, max_bound),
        }
    }

    pub fn to_fixed_point(&self) -> (i64, i64, i64) {
        (
            (self.x * FP_DEN as f64).round() as i64,
            (self.y * FP_DEN as f64).round() as i64,
            (self.z * FP_DEN as f64).round() as i64,
        )
    }

    pub fn from_fixed_point(fx: i64, fy: i64, fz: i64) -> Self {
        Self {
            x: fx as f64 / FP_DEN as f64,
            y: fy as f64 / FP_DEN as f64,
            z: fz as f64 / FP_DEN as f64,
        }
    }
}

/// Agent state during Categorical Semantic Lawfulness (CSL) multi-agent dynamics.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct AgentState {
    pub id: usize,
    pub time: u64,
    pub position: MVector3,
    pub drift: f64,
    pub collapse_count: u64,
    pub is_coherent: bool,
}

impl AgentState {
    pub fn new(id: usize, time: u64, position: MVector3, target: &MVector3, epsilon: f64) -> Self {
        let drift = position.dist(target);
        let is_coherent = drift <= epsilon;
        Self {
            id,
            time,
            position,
            drift,
            collapse_count: if is_coherent { 0 } else { 1 },
            is_coherent,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_constants_golden_ratio() {
        assert!((PHI * LAMBDA_M - 1.0).abs() < 1e-10);
        assert!((PHI - (1.0 + LAMBDA_M)).abs() < 1e-10);
        assert!((DELTA_I - (1.0 - LAMBDA_M)).abs() < 1e-10);
    }

    #[test]
    fn test_vector_algebra() {
        let v1 = MVector3::new(1.0, 2.0, 3.0);
        let v2 = MVector3::new(4.0, 6.0, 3.0);
        assert_eq!(v1.dist(&v2), 5.0);

        let clamped = MVector3::new(15.0, -20.0, 5.0).clamp(10.0);
        assert_eq!(clamped.x, 10.0);
        assert_eq!(clamped.y, -10.0);
        assert_eq!(clamped.z, 5.0);
    }

    #[test]
    fn test_fixed_point_roundtrip() {
        let v = MVector3::new(1.618, -0.618, 0.382);
        let (fx, fy, fz) = v.to_fixed_point();
        assert_eq!(fx, 1618);
        assert_eq!(fy, -618);
        assert_eq!(fz, 382);

        let v_back = MVector3::from_fixed_point(fx, fy, fz);
        assert!((v.x - v_back.x).abs() < 1e-4);
    }
}
