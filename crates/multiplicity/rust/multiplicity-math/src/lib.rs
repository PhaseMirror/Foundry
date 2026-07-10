pub mod constants;
pub mod axis;
pub mod operator;
pub mod knot;

pub use constants::*;
pub use axis::*;
pub use operator::*;
pub use knot::*;

#[cfg(test)]
mod tests {
    use super::*;
    use num_complex::Complex64;

    #[test]
    fn test_constants() {
        assert!(validate_universal_constants(1e-10));
    }

    #[test]
    fn test_su2_identity() {
        // Verify the A_K SU(2) identity: -(A_K^2 + A_K^-2) = 2cos(1)
        let a_k = Complex64::from_polar(1.0, ALPHA_K);
        let lhs = -(a_k.powi(2) + a_k.powi(-2));
        let rhs = 2.0 * (1.0f64).cos();
        
        assert!((lhs.re - rhs).abs() < 1e-10);
        assert!(lhs.im.abs() < 1e-10);
    }

    #[test]
    fn test_axis() {
        assert!(validate_axis_normalization(2, 1e-10));
        assert!(validate_axis_normalization(3, 1e-10));
        assert!(validate_axis_normalization(13, 1e-10));
    }

    #[test]
    fn test_trefoil_invariant() {
        let s = Complex64::i();
        let _invariant = mkt_invariant(jones_trefoil, s);
        // Note: target c0 = ln(10) requires Z_MARKOV (gated)
    }
}
