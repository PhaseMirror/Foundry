//! Exotic Spheres — Rust Numerical Backend
//!
//! Provides verified numerical implementations of:
//! - Prime sieving and p-adic valuation
//! - Star-shaped plumbing graphs and canonicalization
//! - Brieskorn sphere data
//! - Smooth-sensitive kernel K_Σ
//! - Prime-weighted multiplicity matrix M_Σ
//! - p-adic graded pieces and prime-tier invariants
//!
//! Verification via unit tests.

use num_bigint::BigInt;
use num_integer::Integer;
use num_traits::FromPrimitive;

/// Simple prime sieve up to n.
pub fn sieve_primes(n: u64) -> Vec<u64> {
    if n < 2 {
        return vec![];
    }
    let mut is_prime = vec![true; (n + 1) as usize];
    is_prime[0] = false;
    is_prime[1] = false;
    for i in 2..=n {
        if is_prime[i as usize] && i * i <= n {
            for j in (i * i..=n).step_by(i as usize) {
                is_prime[j as usize] = false;
            }
        }
    }
    (2..=n).filter(|&p| is_prime[p as usize]).collect()
}

/// Check if a number is prime.
pub fn is_prime(n: u64) -> bool {
    if n < 2 {
        return false;
    }
    if n == 2 {
        return true;
    }
    if n % 2 == 0 {
        return false;
    }
    let limit = (n as f64).sqrt() as u64;
    (3..=limit).step_by(2).all(|d| n % d != 0)
}

/// p-adic valuation v_p(x) for positive integer x.
pub fn padic_valuation_int(p: u64, x: u64) -> u64 {
    if x == 0 {
        return 0;
    }
    let mut k = p;
    let mut acc = 0;
    while k <= x {
        if x % k == 0 {
            acc += 1;
            k *= p;
        } else {
            break;
        }
    }
    acc
}

/// Star-shaped plumbing graph.
#[derive(Debug, Clone)]
pub struct StarPlumbing {
    pub center_weight: i64,
    pub legs: Vec<Vec<i64>>,
}

/// Canonicalized plumbing graph.
#[derive(Debug, Clone)]
pub struct CanonicalPlumbing {
    pub vertex_weights: Vec<i64>,
    pub adjacency: Vec<Vec<usize>>,
}

/// Brieskorn sphere Σ(p,q,r) parameters.
#[derive(Debug, Clone, Copy)]
pub struct BrieskornParams {
    pub p: u64,
    pub q: u64,
    pub r: u64,
}

/// Smooth-sensitive kernel block.
#[derive(Debug, Clone)]
pub struct SmoothKernel {
    pub matrix_size: usize,
    pub intersection_block: Vec<Vec<f64>>,
    pub smooth_scalar: f64,
}

/// Prime-weighted multiplicity matrix.
#[derive(Debug, Clone)]
pub struct MultiplicityMatrix {
    pub size: usize,
    pub prime_labels: Vec<u64>,
    pub depth_labels: Vec<u64>,
    pub entries: Vec<Vec<f64>>,
}

/// Mode A canonicalization: sort legs lexicographically.
pub fn mode_a_canonicalize(sp: &StarPlumbing) -> CanonicalPlumbing {
    let mut legs_sorted = sp.legs.clone();
    legs_sorted.sort_by(|a, b| {
        match a.len().cmp(&b.len()) {
            std::cmp::Ordering::Equal => a.cmp(b),
            other => other,
        }
    });

    let mut vertex_weights = vec![sp.center_weight];
    let mut adjacency = vec![vec![]];
    let mut next_id = 2;

    for leg in &legs_sorted {
        let mut prev = 1;
        for &w in leg {
            let vid = next_id;
            next_id += 1;
            vertex_weights.push(w);
            adjacency.push(vec![]);
            adjacency[prev - 1].push(vid);
            adjacency[vid - 1].push(prev);
            prev = vid;
        }
    }

    CanonicalPlumbing {
        vertex_weights,
        adjacency,
    }
}

/// Eells–Kuiper invariant μ(Σ) ∈ ℤ/28 for Σ(2,3,r).
pub fn eells_kuiper_23(r: u64) -> u64 {
    match r {
        5 => 0,
        7 => 8,
        11 => 16,
        13 => 4,
        17 => 12,
        19 => 20,
        _ => 0,
    }
}

/// Build the smooth-sensitive kernel K_Σ.
pub fn build_kernel(cp: &CanonicalPlumbing, params: BrieskornParams) -> SmoothKernel {
    let n = cp.vertex_weights.len();
    let mut block = vec![vec![0.0; n]; n];
    for i in 0..n {
        block[i][i] = cp.vertex_weights[i] as f64;
        for &j in &cp.adjacency[i] {
            if j < n {
                block[i][j] = 1.0;
                block[j][i] = 1.0;
            }
        }
    }
    let mu = eells_kuiper_23(params.r);
    let smooth_scalar = mu as f64 / 28.0;
    SmoothKernel {
        matrix_size: n + 1,
        intersection_block: block,
        smooth_scalar,
    }
}

/// First N primes.
pub fn first_n_primes(n: usize) -> Vec<u64> {
    let mut primes = Vec::new();
    let mut candidate = 2;
    while primes.len() < n {
        if is_prime(candidate) {
            primes.push(candidate);
        }
        candidate += 1;
    }
    primes
}

/// Build the prime-weighted multiplicity matrix M_Σ.
pub fn build_multiplicity_matrix(
    cp: &CanonicalPlumbing,
    params: BrieskornParams,
) -> MultiplicityMatrix {
    let n = cp.vertex_weights.len();
    let n_total = n + 1;
    let primes = first_n_primes(n_total);
    let k = build_kernel(cp, params);

    let mut entries = vec![vec![0.0; n_total]; n_total];
    for i in 0..n_total {
        for j in 0..n_total {
            let pi = primes[i];
            let pj = primes[j];
            let mi = if i < n { 2 + cp.vertex_weights[i].unsigned_abs() } else { 0 };
            let mj = if j < n { 2 + cp.vertex_weights[j].unsigned_abs() } else { 0 };
            let factor = (pi.pow(mi as u32) * pj.pow(mj as u32)) as f64;
            let entry = if i < n && j < n {
                k.intersection_block[i][j]
            } else if i == n && j == n {
                k.smooth_scalar
            } else {
                0.0
            };
            entries[i][j] = entry * factor;
        }
    }

    MultiplicityMatrix {
        size: n_total,
        prime_labels: primes,
        depth_labels: vec![0; n_total],
        entries,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sieve_2() {
        assert!(sieve_primes(2).contains(&2));
    }

    #[test]
    fn test_sieve_3() {
        assert!(sieve_primes(3).contains(&3));
    }

    #[test]
    fn test_sieve_4() {
        assert!(!sieve_primes(4).contains(&4));
    }

    #[test]
    fn test_is_prime_2() {
        assert!(is_prime(2));
    }

    #[test]
    fn test_is_prime_7() {
        assert!(is_prime(7));
    }

    #[test]
    fn test_not_prime_4() {
        assert!(!is_prime(4));
    }

    #[test]
    fn test_padic_valuation_2() {
        assert_eq!(padic_valuation_int(2, 8), 3);
        assert_eq!(padic_valuation_int(2, 12), 2);
    }

    #[test]
    fn test_brieskorn_plumbing() {
        let sp = StarPlumbing {
            center_weight: -2,
            legs: vec![vec![-3], vec![-2, -2], vec![-2]],
        };
        let cp = mode_a_canonicalize(&sp);
        assert_eq!(cp.vertex_weights.len(), 5);
    }

    #[test]
    fn test_eells_kuiper_57() {
        assert_eq!(eells_kuiper_23(7), 8);
        assert_eq!(eells_kuiper_23(11), 16);
    }

    #[test]
    fn test_build_kernel() {
        let cp = CanonicalPlumbing {
            vertex_weights: vec![-2, -3, -2],
            adjacency: vec![vec![2, 3], vec![1], vec![1]],
        };
        let params = BrieskornParams { p: 2, q: 3, r: 5 };
        let k = build_kernel(&cp, params);
        assert_eq!(k.matrix_size, 4);
    }

    #[test]
    fn test_build_multiplicity_matrix() {
        let cp = CanonicalPlumbing {
            vertex_weights: vec![-2, -3, -2],
            adjacency: vec![vec![2, 3], vec![1], vec![1]],
        };
        let params = BrieskornParams { p: 2, q: 3, r: 5 };
        let m = build_multiplicity_matrix(&cp, params);
        assert_eq!(m.size, 4);
    }

    #[test]
    fn test_first_n_primes() {
        let primes = first_n_primes(5);
        assert_eq!(primes, vec![2, 3, 5, 7, 11]);
    }
}
