pub mod groups;
pub mod spectra;
pub mod unitary;
pub mod graph_energetics;
pub mod transformer;

pub use groups::*;
pub use spectra::*;
pub use unitary::*;
pub use graph_energetics::*;

#[cfg(test)]
mod tests {
    use super::*;
    use nalgebra::DMatrix;

    #[test]
    fn test_affine_compose() {
        let g1 = AffineElement::new(2, 1, 7).unwrap();
        let g2 = AffineElement::new(3, 2, 7).unwrap();
        let g3 = g1.compose(&g2);
        // g1(g2(x)) = 2*(3*x + 2) + 1 = 6*x + 4 + 1 = 6*x + 5 (mod 7)
        assert_eq!(g3.u, 6);
        assert_eq!(g3.k, 5);
    }

    #[test]
    fn test_affine_inverse() {
        let g = AffineElement::new(2, 3, 7).unwrap();
        let g_inv = g.inverse();
        // 2*u_inv = 1 mod 7 => u_inv = 4
        // 4*(x-3) = 4*x - 12 = 4*x - 5 = 4*x + 2 mod 7
        assert_eq!(g_inv.u, 4);
        assert_eq!(g_inv.k, 2);
        
        let identity = g.compose(&g_inv);
        assert_eq!(identity.u, 1);
        assert_eq!(identity.k, 0);
    }

    #[test]
    fn test_exp_unitary() {
        let b = DMatrix::from_vec(2, 2, vec![0.5, 0.5, 0.5, 0.5]);
        let res = exp_unitary(&b);
        assert_eq!(res.path, "exp");
        assert!(res.residual < 1e-10);
    }
}
