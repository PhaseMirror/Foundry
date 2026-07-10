use serde::{Deserialize, Serialize};
use nalgebra::DMatrix;

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub struct AffineElement {
    pub u: u64, // Multiplier (in F_p^*)
    pub k: u64, // Additive (in F_p)
    pub p: u64, // Prime modulus
}

impl AffineElement {
    pub fn new(u: u64, k: u64, p: u64) -> Result<Self, String> {
        if u == 0 || u >= p {
            return Err(format!("u must be in [1, {}-1]", p));
        }
        if k >= p {
            return Err(format!("k must be in [0, {}-1]", p));
        }
        Ok(AffineElement { u, k, p })
    }

    pub fn compose(&self, other: &AffineElement) -> AffineElement {
        assert_eq!(self.p, other.p, "Modulus mismatch");
        let new_u = (self.u * other.u) % self.p;
        let new_k = (self.u * other.k + self.k) % self.p;
        AffineElement { u: new_u, k: new_k, p: self.p }
    }

    pub fn inverse(&self) -> AffineElement {
        let u_inv = self.mod_inverse(self.u, self.p);
        let k_inv = (self.p - (u_inv * self.k % self.p)) % self.p;
        AffineElement { u: u_inv, k: k_inv, p: self.p }
    }

    pub fn act_index(&self, i: u64) -> u64 {
        (self.u * i + self.k) % self.p
    }

    fn mod_inverse(&self, a: u64, m: u64) -> u64 {
        let mut mn = (m as i64, a as i64);
        let mut xy = (0, 1);
        while mn.1 != 0 {
            xy = (xy.1, xy.0 - (mn.0 / mn.1) * xy.1);
            mn = (mn.1, mn.0 % mn.1);
        }
        while xy.0 < 0 {
            xy.0 += m as i64;
        }
        xy.0 as u64
    }
}

pub fn permutation_matrix(g: &AffineElement, n: usize) -> DMatrix<f64> {
    let mut mat = DMatrix::zeros(n, n);
    for i in 0..n {
        let j = g.act_index(i as u64) as usize;
        if j < n {
            mat[(i, j)] = 1.0;
        }
    }
    mat
}

pub fn conjugate(a: &DMatrix<f64>, p: &DMatrix<f64>) -> DMatrix<f64> {
    p * a * p.transpose()
}
