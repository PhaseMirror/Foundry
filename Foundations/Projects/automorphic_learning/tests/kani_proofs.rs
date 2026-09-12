// Integration test harness for Kani verification of the automorphic_learning crate.
// This file resides in `tests/kani_proofs.rs` and is compiled as an integration test.

extern crate automorphic_learning;

use automorphic_learning::{
    group::{AutomorphicGroup, act, is_coprime},
    mask::{legendre_symbol, residue_mask},
    logits::additive_logits,
    csl::csl_loss,
    sinkhorn::sinkhorn,
    unitarize::unitarize_exp,
    projection::{weighted_l1_proj, weighted_l1_kkt},
};

#[cfg(test)]
mod tests {
    use super::*;
    use kani::proof;
    use nalgebra::{matrix, Complex64, U2};
    
    #[proof]
    fn integration_act_is_bijective() {
        let p = 5usize;
        let g = AutomorphicGroup { p, u: 2, k: 3 };
        assert!(is_coprime(g.u, p));
        let mut seen = [false; 5];
        for i in 0..p {
            let j = act(&g, i);
            assert!(j < p);
            seen[j] = true;
        }
        for b in seen.iter() { assert!(*b); }
    }

    #[proof]
    fn integration_legendre_and_mask() {
        let p = 7usize;
        // check a few legendre values
        assert_eq!(legendre_symbol(0, p), 0);
        assert_eq!(legendre_symbol(1, p), 1);
        assert_eq!(legendre_symbol(3, p), -1);
        // generate mask and verify dimensions
        let m = residue_mask(p);
        assert_eq!(m.len(), p);
        for row in &m { assert_eq!(row.len(), p); }
    }

    #[proof]
    fn integration_additive_logits_nonneg() {
        let p = 3usize;
        let q = vec![vec![0.0; p]; p];
        let k = vec![vec![0.0; p]; p];
        let m = vec![vec![true; p]; p];
        let out = additive_logits(&q, &k, &m, 1.0, 2.0);
        for i in 0..p { for j in 0..p { assert!(out[i][j] >= 0.0); } }
    }

    #[proof]
    fn integration_csl_nonneg() {
        let a = vec![vec![1.0, 2.0], vec![3.0, 4.0]];
        let f = |_: &Vec<Vec<f64>>| 0.0f64;
        let loss = csl_loss(&a, f);
        assert!(loss >= 0.0);
    }

    #[proof]
    fn integration_sinkhorn_stochastic() {
        let p = 3usize;
        let m = vec![vec![1.0, 2.0, 1.0], vec![2.0, 1.0, 1.0], vec![1.0, 1.0, 2.0]];
        let s = sinkhorn(&m, 1e-8, 5);
        for i in 0..p { let row_sum: f64 = s[i].iter().sum(); assert!((row_sum - 1.0).abs() < 1e-6); }
        for j in 0..p { let mut col_sum = 0.0; for i in 0..p { col_sum += s[i][j]; } assert!((col_sum - 1.0).abs() < 1e-6); }
    }

    #[proof]
    fn integration_unitarize_exp_is_unitary() {
        let b = matrix![Complex64::new(0.0, 0.0), Complex64::new(0.0, 1.0);
                        Complex64::new(0.0, -1.0), Complex64::new(0.0, 0.0)];
        let u = unitarize_exp(&b);
        let id = nalgebra::MatrixN::<Complex64, U2>::identity();
        let prod = &u * &u.adjoint();
        for i in 0..2 {
            for j in 0..2 {
                let diff = (prod[(i, j)] - id[(i, j)]).norm();
                assert!(diff < 1e-6);
            }
        }
    }

    #[proof]
    fn integration_weighted_l1_proj_feasible() {
        let v = vec![1.0, 2.0, -1.0];
        let w = vec![1.0, 1.0, 1.0];
        let lambda = 3.0;
        let proj = weighted_l1_proj(&v, &w, lambda);
        let norm: f64 = proj.iter().zip(w.iter()).map(|(vi, wi)| wi * vi.abs()).sum();
        assert!(norm <= lambda + 1e-6);
        // KKT condition check (trivial tau = 0)
        assert!(weighted_l1_kkt(&v, &w, lambda, 0.0, &proj));
    }
}
