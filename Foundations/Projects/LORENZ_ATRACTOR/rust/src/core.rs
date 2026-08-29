use serde::{Deserialize, Serialize};

/// Universal Multiplicity Constant Lambda_m = (sqrt(5) - 1) / 2 ~ 0.6180339887... (phi^-1)
pub const LAMBDA_M: f64 = 0.6180339887498949;

/// Golden ratio phi = (1 + sqrt(5)) / 2 ~ 1.6180339887...
pub const PHI: f64 = 1.6180339887498949;

/// Default Fixed-Point Denominator: 1000 represents 1.000
pub const FP_DEN: i64 = 1000;

/// 3D Phase Space Coordinate.
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct LorenzPoint {
    pub x: f64,
    pub y: f64,
    pub z: f64,
}

impl LorenzPoint {
    pub const fn new(x: f64, y: f64, z: f64) -> Self {
        Self { x, y, z }
    }

    pub const fn origin() -> Self {
        Self { x: 0.0, y: 0.0, z: 0.0 }
    }

    pub const fn standard_initial() -> Self {
        Self { x: 1.0, y: 1.0, z: 1.0 }
    }

    pub fn norm_sq(&self) -> f64 {
        self.x * self.x + self.y * self.y + self.z * self.z
    }

    pub fn norm(&self) -> f64 {
        self.norm_sq().sqrt()
    }

    pub fn dist_sq(&self, other: &LorenzPoint) -> f64 {
        (self.x - other.x).powi(2) + (self.y - other.y).powi(2) + (self.z - other.z).powi(2)
    }

    pub fn dist(&self, other: &LorenzPoint) -> f64 {
        self.dist_sq(other).sqrt()
    }

    pub fn dot(&self, other: &LorenzPoint) -> f64 {
        self.x * other.x + self.y * other.y + self.z * other.z
    }

    pub fn cross(&self, other: &LorenzPoint) -> LorenzPoint {
        LorenzPoint {
            x: self.y * other.z - self.z * other.y,
            y: self.z * other.x - self.x * other.z,
            z: self.x * other.y - self.y * other.x,
        }
    }

    pub fn clamp(&self, max_bound: f64) -> Self {
        Self {
            x: self.x.clamp(-max_bound, max_bound),
            y: self.y.clamp(-max_bound, max_bound),
            z: self.z.clamp(-max_bound, max_bound),
        }
    }

    pub fn add(&self, other: &LorenzPoint) -> Self {
        Self {
            x: self.x + other.x,
            y: self.y + other.y,
            z: self.z + other.z,
        }
    }

    pub fn scale(&self, s: f64) -> Self {
        Self {
            x: self.x * s,
            y: self.y * s,
            z: self.z * s,
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

/// Lorenz system parameters (sigma, rho, beta).
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct LorenzParams {
    pub sigma: f64,
    pub rho: f64,
    pub beta: f64,
}

impl LorenzParams {
    pub const fn canonical() -> Self {
        Self {
            sigma: 10.0,
            rho: 28.0,
            beta: 8.0 / 3.0,
        }
    }

    pub const fn new(sigma: f64, rho: f64, beta: f64) -> Self {
        Self { sigma, rho, beta }
    }

    pub fn from_primes(p1: u64, p2: u64, p3: u64) -> Self {
        Self {
            sigma: p1 as f64,
            rho: p2 as f64,
            beta: p3 as f64,
        }
    }

    /// Compute non-trivial fixed points (C+ and C-) for rho > 1.
    pub fn non_trivial_fixed_points(&self) -> Option<(LorenzPoint, LorenzPoint)> {
        if self.rho > 1.0 && self.beta > 0.0 {
            let xy = (self.beta * (self.rho - 1.0)).sqrt();
            let z = self.rho - 1.0;
            Some((
                LorenzPoint::new(xy, xy, z),
                LorenzPoint::new(-xy, -xy, z),
            ))
        } else {
            None
        }
    }
}

/// Prime-based Parameter Encoding representation.
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct PrimeLorenzParams {
    pub p1: u64,
    pub p2: u64,
    pub p3: u64,
}

impl PrimeLorenzParams {
    pub const fn default_7_29_3() -> Self {
        Self { p1: 7, p2: 29, p3: 3 }
    }

    pub const fn new(p1: u64, p2: u64, p3: u64) -> Self {
        Self { p1, p2, p3 }
    }

    pub fn to_lorenz_params(&self, dynamic_perturbation: f64) -> LorenzParams {
        LorenzParams {
            sigma: (self.p1 as f64) * (1.0 + dynamic_perturbation),
            rho: (self.p2 as f64) * (1.0 + dynamic_perturbation),
            beta: (self.p3 as f64) * (1.0 + dynamic_perturbation),
        }
    }
}

/// Full state of the Multiplicity-Enhanced Lorenz Attractor at time step t.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct LorenzState {
    pub time: u64,
    pub point: LorenzPoint,
    pub velocity: LorenzPoint,
    pub lambda_multiplicity: f64,
    pub stability_integral: f64,
}

impl LorenzState {
    pub fn new(
        time: u64,
        point: LorenzPoint,
        velocity: LorenzPoint,
        lambda_multiplicity: f64,
        stability_integral: f64,
    ) -> Self {
        Self {
            time,
            point,
            velocity,
            lambda_multiplicity,
            stability_integral,
        }
    }

    pub fn initial(point: LorenzPoint) -> Self {
        Self {
            time: 0,
            point,
            velocity: LorenzPoint::origin(),
            lambda_multiplicity: 0.0,
            stability_integral: 0.0,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_point_geometry_and_clamping() {
        let p = LorenzPoint::new(3.0, 4.0, 0.0);
        assert_eq!(p.norm(), 5.0);
        assert_eq!(p.norm_sq(), 25.0);

        let p_large = LorenzPoint::new(150.0, -200.0, 50.0);
        let p_clamped = p_large.clamp(100.0);
        assert_eq!(p_clamped.x, 100.0);
        assert_eq!(p_clamped.y, -100.0);
        assert_eq!(p_clamped.z, 50.0);
    }

    #[test]
    fn test_fixed_point_conversion() {
        let p = LorenzPoint::new(1.234, -5.678, 9.012);
        let (fx, fy, fz) = p.to_fixed_point();
        assert_eq!(fx, 1234);
        assert_eq!(fy, -5678);
        assert_eq!(fz, 9012);

        let p_back = LorenzPoint::from_fixed_point(fx, fy, fz);
        assert!((p.x - p_back.x).abs() < 1e-4);
        assert!((p.y - p_back.y).abs() < 1e-4);
        assert!((p.z - p_back.z).abs() < 1e-4);
    }

    #[test]
    fn test_prime_parameter_mapping() {
        let prime_p = PrimeLorenzParams::default_7_29_3();
        let params = prime_p.to_lorenz_params(0.0);
        assert_eq!(params.sigma, 7.0);
        assert_eq!(params.rho, 29.0);
        assert_eq!(params.beta, 3.0);

        let params_pert = prime_p.to_lorenz_params(0.1);
        assert!((params_pert.sigma - 7.7).abs() < 1e-10);
    }

    #[test]
    fn test_non_trivial_fixed_points() {
        let params = LorenzParams::canonical();
        let fps = params.non_trivial_fixed_points();
        assert!(fps.is_some());
        let (c_plus, c_minus) = fps.unwrap();
        // beta = 8/3, rho = 28 -> xy = sqrt((8/3)*27) = sqrt(72) ~ 8.48528
        let expected_xy = (8.0 / 3.0 * 27.0_f64).sqrt();
        assert!((c_plus.x - expected_xy).abs() < 1e-10);
        assert!((c_minus.x - (-expected_xy)).abs() < 1e-10);
        assert_eq!(c_plus.z, 27.0);
    }
}
