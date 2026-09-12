//! AGL(1,p) group actions, CRT embeddings, and Legendre symbol.
//!
//! The automorphic group $G_p = \text{AGL}(1,p)$ acts on token indices
//! $\{1, \dots, n\}$ via affine transformations $i \mapsto u \cdot i + k$
//! where $u \in \mathbb{F}_p^\times$ and $k \in \mathbb{F}_p$.

use nalgebra::{DMatrix, DVector};
use num_integer::Integer;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum GroupError {
    #[error("prime p must be odd, got {0}")]
    NotOddPrime(u32),
    #[error("index {index} out of range for prime {p}")]
    IndexOutOfRange { index: usize, p: u32 },
    #[error("CRT embedding requires p1*p2 >= n, got {p1}*{p2} < {n}")]
    CrtInsufficient { p1: u32, p2: u32, n: usize },
}

/// Compute the Legendre symbol $\chi_p(a)$.
///
/// Returns:
/// - `1` if `a` is a quadratic residue mod `p` (and `a != 0`)
/// - `-1` if `a` is a quadratic non-residue mod `p`
/// - `0` if `a == 0`
pub fn legendre_symbol(a: i64, p: u32) -> i8 {
    let a_mod = ((a % p as i64 + p as i64) % p as i64) as u32;
    if a_mod == 0 {
        return 0;
    }
    // Euler's criterion: a^((p-1)/2) mod p
    let exp = (p - 1) / 2;
    let mut result: u32 = 1;
    let mut base = a_mod;
    let mut e = exp;
    while e > 0 {
        if e & 1 == 1 {
            result = result * base % p;
        }
        base = base * base % p;
        e >>= 1;
    }
    if result == 1 {
        1
    } else {
        -1
    }
}

/// A single AGL(1,p) element: $i \mapsto u \cdot i + k \pmod{p}$.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct AglElement {
    pub u: u32,
    pub k: u32,
    pub p: u32,
}

impl AglElement {
    pub fn new(u: u32, k: u32, p: u32) -> Result<Self, GroupError> {
        if p < 2 || p % 2 == 0 {
            return Err(GroupError::NotOddPrime(p));
        }
        Ok(Self {
            u: u % p,
            k: k % p,
            p,
        })
    }

    /// Identity element: $i \mapsto i$.
    pub fn identity(p: u32) -> Result<Self, GroupError> {
        Self::new(1, 0, p)
    }

    /// Apply this element to index $i \pmod{p}$.
    pub fn apply(&self, i: u32) -> u32 {
        (self.u * i + self.k) % self.p
    }

    /// Compose: self ∘ other, i.e., self(other(i)).
    pub fn compose(&self, other: &AglElement) -> Result<Self, GroupError> {
        assert_eq!(self.p, other.p);
        Ok(Self {
            u: (self.u * other.u) % self.p,
            k: (self.u * other.k + self.k) % self.p,
            p: self.p,
        })
    }

    /// Inverse element.
    pub fn inverse(&self) -> Result<Self, GroupError> {
        // u^{-1} mod p via Fermat's little theorem
        let u_inv = mod_pow(self.u, self.p - 2, self.p);
        let k_inv = (self.p - (u_inv * self.k % self.p)) % self.p;
        Ok(Self {
            u: u_inv,
            k: k_inv,
            p: self.p,
        })
    }

    /// Generate the permutation matrix $P_g$ for this element acting on $\{0, \dots, n-1\}$.
    pub fn permutation_matrix(&self, n: usize) -> DMatrix<f64> {
        let mut P = DMatrix::<f64>::zeros(n, n);
        for i in 0..n {
            let j = self.apply(i as u32) as usize;
            if j < n {
                P[(j, i)] = 1.0;
            }
        }
        P
    }
}

/// Full AGL(1,p) group.
#[derive(Debug, Clone)]
pub struct AgpGroup {
    pub p: u32,
    elements: Vec<AglElement>,
}

impl AgpGroup {
    /// Create the full AGL(1,p) group.
    pub fn new(p: u32) -> Result<Self, GroupError> {
        if p < 2 || p % 2 == 0 {
            return Err(GroupError::NotOddPrime(p));
        }
        let mut elements = Vec::with_capacity(((p - 1) * p) as usize);
        for u in 1..p {
            for k in 0..p {
                elements.push(AglElement::new(u, k, p)?);
            }
        }
        Ok(Self { p, elements })
    }

    /// Number of elements: $(p-1) \cdot p$.
    pub fn order(&self) -> usize {
        self.elements.len()
    }

    /// All elements.
    pub fn elements(&self) -> &[AglElement] {
        &self.elements
    }

    /// Sample a random minibatch of generators/compositions.
    pub fn sample_batch(
        &self,
        size: usize,
        rng: &mut impl rand::Rng,
    ) -> Vec<AglElement> {
        use rand::seq::SliceRandom;
        let mut batch = self.elements.clone();
        batch.shuffle(rng);
        batch.into_iter().take(size).collect()
    }

    /// Compute the action $A \mapsto P_g A P_g^\top$ on a matrix.
    pub fn conjugate(&self, g: &AglElement, A: &DMatrix<f64>) -> DMatrix<f64> {
        let P = g.permutation_matrix(A.nrows());
        &P * A * P.transpose()
    }
}

/// CRT embedding: $\phi: \{1, \dots, n\} \hookrightarrow \mathbb{F}_{p_1} \times \mathbb{F}_{p_2}$.
#[derive(Debug, Clone)]
pub struct CrtEmbedding {
    pub p1: u32,
    pub p2: u32,
    pub n: usize,
}

impl CrtEmbedding {
    pub fn new(p1: u32, p2: u32, n: usize) -> Result<Self, GroupError> {
        if (p1 as u64) * (p2 as u64) < n as u64 {
            return Err(GroupError::CrtInsufficient { p1, p2, n });
        }
        Ok(Self { p1, p2, n })
    }

    /// Embed index $i$ into $\mathbb{F}_{p_1} \times \mathbb{F}_{p_2}$.
    pub fn embed(&self, i: usize) -> (u32, u32) {
        let i = i as u32;
        (i % self.p1, i % self.p2)
    }

    /// Compute the Legendre mask between two embedded indices.
    ///
    /// $M_p[i,j] = \mathbf{1}\{\chi_p(\phi(i) - \phi(j)) = +1\}$
    pub fn legendre_mask_single(&self, i: usize, j: usize, prime_idx: usize) -> i8 {
        let (ai, aj) = self.embed(i);
        let p = if prime_idx == 0 { self.p1 } else { self.p2 };
        let diff = (ai as i64 - aj as i64 + p as i64) % p as i64;
        legendre_symbol(diff, p)
    }

    /// Full residue mask: $M[i,j] = \prod_{k} \mathbf{1}\{\chi_{p_k}(\phi_k(i)-\phi_k(j))=+1\}$.
    pub fn residue_mask(&self) -> DMatrix<f64> {
        let n = self.n;
        let mut M = DMatrix::<f64>::zeros(n, n);
        for i in 0..n {
            for j in 0..n {
                let chi1 = self.legendre_mask_single(i, j, 0);
                let chi2 = self.legendre_mask_single(i, j, 1);
                // Residue if both components are residues
                M[(i, j)] = if chi1 == 1 && chi2 == 1 { 1.0 } else { 0.0 };
            }
        }
        M
    }
}

/// Modular exponentiation.
fn mod_pow(mut base: u32, mut exp: u32, modulus: u32) -> u32 {
    let mut result: u32 = 1;
    base %= modulus;
    while exp > 0 {
        if exp & 1 == 1 {
            result = result * base % modulus;
        }
        exp >>= 1;
        base = base * base % modulus;
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_legendre_symbol() {
        // χ_7(1) = 1, χ_7(2) = 1, χ_7(3) = -1, χ_7(0) = 0
        assert_eq!(legendre_symbol(1, 7), 1);
        assert_eq!(legendre_symbol(2, 7), 1);
        assert_eq!(legendre_symbol(3, 7), -1);
        assert_eq!(legendre_symbol(0, 7), 0);
    }

    #[test]
    fn test_agl_identity() {
        let g = AglElement::identity(7).unwrap();
        for i in 0..7 {
            assert_eq!(g.apply(i), i);
        }
    }

    #[test]
    fn test_agl_compose() {
        let p = 5;
        let g = AglElement::new(2, 1, p).unwrap(); // 2i+1
        let h = AglElement::new(3, 0, p).unwrap(); // 3i
        let gh = g.compose(&h).unwrap(); // 2(3i)+1 = 6i+1 = i+1
        for i in 0..p {
            assert_eq!(gh.apply(i), (i + 1) % p);
        }
    }

    #[test]
    fn test_agl_inverse() {
        let p = 7;
        let g = AglElement::new(3, 2, p).unwrap();
        let g_inv = g.inverse().unwrap();
        let id = g.compose(&g_inv).unwrap();
        assert_eq!(id.u, 1);
        assert_eq!(id.k, 0);
    }

    #[test]
    fn test_agl_group_order() {
        let group = AgpGroup::new(5).unwrap();
        assert_eq!(group.order(), 20); // (5-1)*5 = 20
    }

    #[test]
    fn test_permutation_matrix() {
        let g = AglElement::new(2, 1, 5).unwrap();
        let P = g.permutation_matrix(5);
        // Should be a permutation matrix
        for i in 0..5 {
            assert_eq!(P.row(i).sum(), 1.0);
            assert_eq!(P.column(i).sum(), 1.0);
        }
    }

    #[test]
    fn test_crt_embedding() {
        let crt = CrtEmbedding::new(7, 11, 50).unwrap();
        let (a, b) = crt.embed(0);
        assert_eq!(a, 0);
        assert_eq!(b, 0);
        let (a, b) = crt.embed(13);
        assert_eq!(a, 6);
        assert_eq!(b, 2);
    }

    #[test]
    fn test_conjugation_preserves_permutation() {
        let p = 5;
        let group = AgpGroup::new(p).unwrap();
        let A = DMatrix::<f64>::identity(p as usize, p as usize);
        let g = AglElement::new(2, 1, p).unwrap();
        let A_g = group.conjugate(&g, &A);
        // Conjugation of identity should return identity
        assert!((A_g - DMatrix::<f64>::identity(p as usize, p as usize)).norm() < 1e-10);
    }
}
