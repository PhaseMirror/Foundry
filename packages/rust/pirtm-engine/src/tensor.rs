//! Prime-indexed tensor overlay and the 2×2 `GainMatrix`.
//!
//! ADR-0066 §"1. Semantic and Dimensional Mapping":
//! the PrismPM calculator operations are lifted onto a prime-indexed tensor
//! overlay where `Add ↦ p₁ = 2` and `Multiply ↦ p₂ = 3`. The recursive
//! transition between the two operations is a 2×2 **gain matrix** Ψ whose
//! spectral radius ρ(Ψ) decides contractivity.
//!
//! The spectral radius is deliberately computed from the quadratic
//! characteristic polynomial so it is exact for the 2×2 case:
//!
//! ```text
//! det(λI − Ψ) = λ² − tr(Ψ)·λ + det(Ψ)
//! ```
//!
//! with real roots when `tr² − 4·det ≥ 0` and modulus `√det` otherwise.

/// A 2×2 gain matrix over the prime-indexed tensor overlay.
///
/// Entry `(i, j)` is the recursive transition weight from the `j`-th
/// operation lane to the `i`-th. The ADR's adversarial injection is
/// `psi.set_weights(1.0, 0.5, 0.5, 1.0)`, whose spectral radius is `1.5`
/// — expansive beyond the `1 − ε` contractivity bound.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct GainMatrix {
    /// a11 — transition `Add → Add`.
    pub w00: f64,
    /// a12 — transition `Add → Multiply`.
    pub w01: f64,
    /// a21 — transition `Multiply → Add`.
    pub w10: f64,
    /// a22 — transition `Multiply → Multiply`.
    pub w11: f64,
}

impl Default for GainMatrix {
    fn default() -> Self {
        Self::new_2x2()
    }
}

impl GainMatrix {
    /// The zero 2×2 matrix (no coupling between the overlay lanes).
    #[must_use]
    pub const fn new_2x2() -> Self {
        Self {
            w00: 0.0,
            w01: 0.0,
            w10: 0.0,
            w11: 0.0,
        }
    }

    /// Assign the four transition weights in row-major order.
    pub fn set_weights(&mut self, a00: f64, a01: f64, a10: f64, a11: f64) {
        self.w00 = a00;
        self.w01 = a01;
        self.w10 = a10;
        self.w11 = a11;
    }

    /// Trace `tr(Ψ) = a11 + a22`.
    #[must_use]
    pub fn trace(&self) -> f64 {
        self.w00 + self.w11
    }

    /// Determinant `det(Ψ) = a11·a22 − a12·a21`.
    #[must_use]
    pub fn det(&self) -> f64 {
        self.w00 * self.w11 - self.w01 * self.w10
    }

    /// Spectral radius `ρ(Ψ)` — the largest eigenvalue modulus.
    ///
    /// Exact for the 2×2 case; see the module docs for the formula.
    #[must_use]
    pub fn spectral_radius(&self) -> f64 {
        spectral_radius_2x2(self)
    }
}

/// Spectral radius of a 2×2 matrix from its characteristic polynomial.
#[must_use]
pub fn spectral_radius_2x2(psi: &GainMatrix) -> f64 {
    let tr = psi.trace();
    let det = psi.det();
    let disc = tr * tr - 4.0 * det;
    if disc >= 0.0 {
        let root = disc.sqrt();
        let lambda_max = (tr + root).abs() / 2.0;
        let lambda_min = (tr - root).abs() / 2.0;
        lambda_max.max(lambda_min)
    } else {
        // Complex-conjugate eigenvalue pair: modulus is sqrt(det).
        det.abs().sqrt()
    }
}

/// Scale used to map the architectural contractivity invariant `Λ_m` to a
/// fixed-point unsigned integer. `Λ_m < 1` becomes `lambda_m < SCALE`
/// (mirrors `crmf::failgate::CONTRACTIVITY_SCALE`).
pub const CONTRACTIVITY_SCALE: u64 = 1_000_000_000;

#[cfg(test)]
mod tests {
    use super::*;

    fn close(a: f64, b: f64) -> bool {
        (a - b).abs() < 1e-9
    }

    #[test]
    fn zero_matrix_is_contractive() {
        let psi = GainMatrix::new_2x2();
        assert!(close(psi.spectral_radius(), 0.0));
    }

    #[test]
    fn identity_matrix_has_spectral_radius_one() {
        let mut psi = GainMatrix::new_2x2();
        psi.set_weights(1.0, 0.0, 0.0, 1.0);
        assert!(close(psi.spectral_radius(), 1.0));
    }

    /// The ADR's adversarial gain matrix `[[1, 0.5], [0.5, 1]]` must have
    /// `ρ(Ψ) = 1.5` — strictly expansive (the veto gate must kill).
    #[test]
    fn adr_0066_adversarial_injection_radius_is_1_5() {
        let mut psi = GainMatrix::new_2x2();
        psi.set_weights(1.0, 0.5, 0.5, 1.0);
        assert!(close(psi.spectral_radius(), 1.5));
    }

    #[test]
    fn diagonal_eigenvalues() {
        let mut psi = GainMatrix::new_2x2();
        psi.set_weights(0.25, 0.0, 0.0, 0.5);
        assert!(close(psi.spectral_radius(), 0.5));
    }

    #[test]
    fn complex_pair_modulus_is_sqrt_det() {
        // Rotation by 90°: eigenvalues ±i, radius 1.0.
        let mut psi = GainMatrix::new_2x2();
        psi.set_weights(0.0, -1.0, 1.0, 0.0);
        assert!(close(psi.spectral_radius(), 1.0));
        assert!(close(psi.det(), 1.0));
    }

    #[test]
    fn antisymmetric_small_gain_is_contractive() {
        let mut psi = GainMatrix::new_2x2();
        psi.set_weights(0.0, 0.25, -0.25, 0.0);
        assert!(psi.spectral_radius() < 0.5);
    }
}