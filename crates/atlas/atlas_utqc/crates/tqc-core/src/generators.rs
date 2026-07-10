//! The reflection generators `σ`, `τ`, `μ` as coordinate (class) permutations.
//!
//! Realizes the `reflection-generators` dictionary row. Because each generator is a
//! permutation of the label space, it is automatically orthogonal w.r.t. the Euclidean inner
//! product `Σxᵢ²` (see [`crate::inner`]): unitarity with **no** positivity assumption,
//! established directly.

use crate::params::UseCaseParams;
use alloc::vec::Vec;

/// A permutation of the class space `[0, n)`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Permutation {
    /// `map[i]` is the image of class `i`.
    map: Vec<u64>,
}

impl Permutation {
    /// The identity permutation on `n` classes.
    #[must_use]
    pub fn identity(n: u64) -> Self {
        Self {
            map: (0..n).collect(),
        }
    }

    /// Build from an image table, validating it is a genuine permutation of `[0, len)`.
    #[must_use]
    pub fn from_map(map: Vec<u64>) -> Option<Self> {
        let n = map.len() as u64;
        let mut seen = alloc::vec![false; map.len()];
        for &image in &map {
            if image >= n {
                return None;
            }
            let slot = &mut seen[image as usize];
            if *slot {
                return None;
            }
            *slot = true;
        }
        Some(Self { map })
    }

    /// The number of classes permuted.
    #[must_use]
    pub fn len(&self) -> u64 {
        self.map.len() as u64
    }

    /// Whether this permutation is empty.
    #[must_use]
    pub fn is_empty(&self) -> bool {
        self.map.is_empty()
    }

    /// The image of class `i`.
    #[must_use]
    pub fn apply(&self, i: u64) -> u64 {
        self.map[i as usize]
    }

    /// Compose: `(self ∘ other)(i) = self(other(i))`.
    #[must_use]
    pub fn then(&self, other: &Self) -> Self {
        Self {
            map: (0..self.len())
                .map(|i| other.apply(self.apply(i)))
                .collect(),
        }
    }

    /// The multiplicative order: the least `k ≥ 1` with `selfᵏ = id`.
    #[must_use]
    pub fn order(&self) -> u64 {
        let id = Self::identity(self.len());
        let mut acc = self.clone();
        let mut k = 1;
        while acc != id {
            acc = acc.then(self);
            k += 1;
        }
        k
    }

    /// Permute an amplitude vector: `(g · v)[g(i)] = v[i]`.
    #[must_use]
    pub fn permute_amplitudes(&self, v: &[i64]) -> Vec<i64> {
        let mut out = alloc::vec![0i64; v.len()];
        for (i, &val) in v.iter().enumerate() {
            out[self.apply(i as u64) as usize] = val;
        }
        out
    }
}

/// The three Atlas reflection generators for a use-case, as class permutations.
#[derive(Debug, Clone)]
pub struct Generators {
    /// `σ`: quarter-turn on scope — `h2 → (h2+1) mod scope`. Order `scope`.
    pub sigma: Permutation,
    /// `τ`: inner-twist on context — `l → (l+1) mod context`. Order `context`.
    pub tau: Permutation,
    /// `μ`: modality mirror — `d → (modality-1) - d`. Order `2`.
    pub mu: Permutation,
}

impl Generators {
    /// Build the generators for the given parameters.
    #[must_use]
    pub fn new(p: &UseCaseParams) -> Self {
        let n = p.class_count();
        let build = |f: &dyn Fn(u32, u32, u32) -> (u32, u32, u32)| -> Permutation {
            let map = (0..n)
                .map(|i| {
                    let (h2, d, l) = p.class_coords(i).unwrap_or((0, 0, 0));
                    let (h2b, db, lb) = f(h2, d, l);
                    p.class_index(h2b, db, lb).unwrap_or(i)
                })
                .collect();
            Permutation { map }
        };
        let sigma = build(&|h2, d, l| ((h2 + 1) % p.scope, d, l));
        let tau = build(&|h2, d, l| (h2, d, (l + 1) % p.context));
        let mu = build(&|h2, d, l| (h2, (p.modality - 1) - d, l));
        Self { sigma, tau, mu }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn atlas_generator_orders_match_parameters() {
        let p = UseCaseParams::new(4, 3, 8);
        let g = Generators::new(&p);
        assert_eq!(g.sigma.order(), p.sigma_order() as u64);
        assert_eq!(g.tau.order(), p.tau_order() as u64);
        assert_eq!(g.mu.order(), p.mu_order() as u64);
    }

    #[test]
    fn generators_are_permutations() {
        let p = UseCaseParams::new(4, 3, 8);
        let g = Generators::new(&p);
        for perm in [&g.sigma, &g.tau, &g.mu] {
            assert!(
                Permutation::from_map((0..perm.len()).map(|i| perm.apply(i)).collect()).is_some()
            );
        }
    }

    #[test]
    fn arbitrary_instance_orders_follow_parameters() {
        let p = UseCaseParams::new(5, 2, 3);
        let g = Generators::new(&p);
        assert_eq!(g.sigma.order(), 5);
        assert_eq!(g.tau.order(), 3);
        assert_eq!(g.mu.order(), 2);
    }
}
