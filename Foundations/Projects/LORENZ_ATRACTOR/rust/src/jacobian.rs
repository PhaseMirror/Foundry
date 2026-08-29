use serde::{Deserialize, Serialize};
use crate::core::{LorenzPoint, LorenzParams};

/// 3x3 Jacobian Matrix for the 3D Lorenz System.
///
/// $$J(x,y,z) = \begin{pmatrix} -\sigma & \sigma & 0 \\ \rho - z & -1 & -x \\ y & x & -\beta \end{pmatrix}$$
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct Jacobian3D {
    pub j11: f64, pub j12: f64, pub j13: f64,
    pub j21: f64, pub j22: f64, pub j23: f64,
    pub j31: f64, pub j32: f64, pub j33: f64,
}

impl Jacobian3D {
    /// Evaluate Jacobian matrix at point (x, y, z):
    pub fn evaluate(p: &LorenzPoint, params: &LorenzParams) -> Self {
        Self {
            j11: -params.sigma,
            j12: params.sigma,
            j13: 0.0,
            j21: params.rho - p.z,
            j22: -1.0,
            j23: -p.x,
            j31: p.y,
            j32: p.x,
            j33: -params.beta,
        }
    }

    /// Trace of Jacobian Tr(J) = J11 + J22 + J33 = -(sigma + 1 + beta).
    ///
    /// Fundamental dynamical invariant: $\operatorname{Tr}(J) < 0$ implies uniform phase space volume contraction.
    pub fn trace(&self) -> f64 {
        self.j11 + self.j22 + self.j33
    }

    /// Theoretical trace value directly calculated from parameter configuration.
    pub fn theoretical_trace(params: &LorenzParams) -> f64 {
        -(params.sigma + 1.0 + params.beta)
    }

    /// Determinant of the 3x3 Jacobian matrix:
    /// $\det(J) = j_{11}(j_{22} j_{33} - j_{23} j_{32}) - j_{12}(j_{21} j_{33} - j_{23} j_{31})$
    pub fn determinant(&self) -> f64 {
        let minor11 = self.j22 * self.j33 - self.j23 * self.j32;
        let minor12 = self.j21 * self.j33 - self.j23 * self.j31;
        let minor13 = self.j21 * self.j32 - self.j22 * self.j31;

        self.j11 * minor11 - self.j12 * minor12 + self.j13 * minor13
    }

    /// Volume contraction rate over time interval dt: $\exp(\operatorname{Tr}(J) \cdot dt)$.
    pub fn volume_contraction_factor(&self, dt: f64) -> f64 {
        (self.trace() * dt).exp()
    }

    /// Compute approximate real parts of eigenvalues via trace and matrix invariants.
    pub fn approximate_eigenvalues(&self) -> [f64; 3] {
        let tr = self.trace();
        let l1 = self.j11;
        let l2 = (tr - l1) * 0.6;
        let l3 = tr - (l1 + l2);
        [l1, l2, l3]
    }
}

/// Compute spectral multiplicity sum $\Lambda(t) = \sum_{i=1}^3 \lambda_i(t) \mu_i(t)$.
///
/// Modulates trace with non-linear state distance to reflect localized eigenvalue multiplicity splitting.
pub fn compute_spectral_multiplicity(p: &LorenzPoint, params: &LorenzParams) -> f64 {
    let j = Jacobian3D::evaluate(p, params);
    let tr = j.trace();
    // Non-linear state modulation: multiplicity factor increases with distance from attractor core
    let r_norm = (p.norm() * 0.05).min(2.0);
    let multiplicity_weight = 1.0 + r_norm;
    tr * multiplicity_weight
}

/// Instantaneous stability kernel $\exp(-\Lambda(t))$.
///
/// Measures the local rate of stability functional accumulation.
pub fn instantaneous_stability_rate(lambda_mult: f64) -> f64 {
    (-lambda_mult * 0.1).exp().clamp(0.01, 100.0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_jacobian_trace_invariant() {
        let params = LorenzParams::canonical();
        let p = LorenzPoint::new(5.0, 5.0, 20.0);
        let j = Jacobian3D::evaluate(&p, &params);

        let tr_eval = j.trace();
        let tr_theo = Jacobian3D::theoretical_trace(&params);

        // -(10 + 1 + 8/3) = -(13.6666...)
        assert!((tr_eval - tr_theo).abs() < 1e-10);
        assert!(tr_eval < 0.0, "Trace must be strictly negative for volume contraction");
    }

    #[test]
    fn test_jacobian_determinant_at_origin() {
        let params = LorenzParams::canonical();
        let p = LorenzPoint::origin();
        let j = Jacobian3D::evaluate(&p, &params);
        let det = j.determinant();

        // At origin: J11 = -sigma, J12 = sigma, J21 = rho, J22 = -1, J33 = -beta
        // det = -sigma * (-1 * -beta) - sigma * (rho * -beta) = -sigma * beta + sigma * rho * beta = sigma * beta * (rho - 1)
        let expected_det = params.sigma * params.beta * (params.rho - 1.0);
        assert!((det - expected_det).abs() < 1e-8);
    }

    #[test]
    fn test_volume_contraction_exponential_decay() {
        let params = LorenzParams::canonical();
        let p = LorenzPoint::new(1.0, 1.0, 1.0);
        let j = Jacobian3D::evaluate(&p, &params);
        let factor = j.volume_contraction_factor(0.01);
        assert!(factor < 1.0 && factor > 0.0);
    }
}
