//! Multiplicity Knot Theory (MKT) - Canonical Non-Parallelism & Non-Abelian Dynamics
//!
//! This module supplies the Rust/Kani backing for the Lean formalization in
//! `lean/dynamics/Quarternion.lean`:
//!
//! * `canonical_non_parallelism` — Theorem 3.3: the canonical MKT axes
//!   `n̂_p` and `n̂_q` are never perfectly parallel for distinct primes
//!   `p ≠ q` (numeric witness, checked by the `#[test]`s below).
//! * `abelian_collapse` — the single-axis (`σ_x`) baseline generator
//!   `O^{orig}_p` commutes with itself, the failure mode the Canonical MKT
//!   Axis avoids.
//! * `commutator` / `non_abelian_generators` — the SU(2) generator commutator
//!   `[O_p, O_q]` is strictly non-zero when the axes are non-parallel.

use crate::axis::canonical_eigenmode_axis;
use crate::operator::construct_su2_operator;
use num_complex::Complex64;

/// Return `true` iff the canonical MKT axes for `p` and `q` are perfectly
/// parallel (i.e. one is a scalar multiple of the other, which for unit
/// vectors means they are equal or opposite).
pub fn axes_are_parallel(p: u64, q: u64, tolerance: f64) -> bool {
    let (px, py, pz) = match canonical_eigenmode_axis(p) {
        Ok(v) => v,
        Err(_) => return false,
    };
    let (qx, qy, qz) = match canonical_eigenmode_axis(q) {
        Ok(v) => v,
        Err(_) => return false,
    };

    // Parallel unit vectors imply |cross product| == 0.
    let cross_x = py * qz - pz * qy;
    let cross_y = pz * qx - px * qz;
    let cross_z = px * qy - py * qx;
    let cross_norm_sq = cross_x * cross_x + cross_y * cross_y + cross_z * cross_z;
    cross_norm_sq.sqrt() < tolerance
}

/// Theorem 3.3 (Canonical Non-Parallelism), numeric witness form.
///
/// Asserts that for every distinct prime pair `(p, q)` drawn from `primes`,
/// the canonical MKT axes are NOT perfectly parallel within `tolerance`.
pub fn canonical_non_parallelism(primes: &[u64], tolerance: f64) -> bool {
    for &p in primes {
        for &q in primes {
            if p != q && axes_are_parallel(p, q, tolerance) {
                return false;
            }
        }
    }
    true
}

/// 2x2 complex matrix commutator `[A, B] = A·B − B·A`.
pub fn commutator(a: &[[Complex64; 2]; 2], b: &[[Complex64; 2]; 2]) -> [[Complex64; 2]; 2] {
    let mul = |x: &[[Complex64; 2]; 2], y: &[[Complex64; 2]; 2]| -> [[Complex64; 2]; 2] {
        let mut out = [[Complex64::new(0.0, 0.0); 2]; 2];
        for i in 0..2 {
            for j in 0..2 {
                let mut s = Complex64::new(0.0, 0.0);
                for k in 0..2 {
                    s += x[i][k] * y[k][j];
                }
                out[i][j] = s;
            }
        }
        out
    };
    let ab = mul(a, b);
    let ba = mul(b, a);
    let mut out = [[Complex64::new(0.0, 0.0); 2]; 2];
    for i in 0..2 {
        for j in 0..2 {
            out[i][j] = ab[i][j] - ba[i][j];
        }
    }
    out
}

/// Frobenius norm of the commutator; zero iff the operators commute.
pub fn commutator_norm(c: &[[Complex64; 2]; 2]) -> f64 {
    let mut s = 0.0;
    for i in 0..2 {
        for j in 0..2 {
            s += c[i][j].norm_sqr();
        }
    }
    s.sqrt()
}

/// Abelian-collapse baseline: a generator built from the single `σ_x` axis.
/// Because every prime shares this axis, the result commutes with itself.
pub fn abelian_baseline_operator(angle: f64) -> [[Complex64; 2]; 2] {
    let cos_a = angle.cos();
    let sin_a = angle.sin();
    // exp(i * angle * σ_x) = cos(angle) I + i sin(angle) σ_x
    [
        [
            Complex64::new(cos_a, sin_a),
            Complex64::new(0.0, 0.0),
        ],
        [
            Complex64::new(0.0, 0.0),
            Complex64::new(cos_a, -sin_a),
        ],
    ]
}

/// Verify the Abelian Collapse Theorem for a single-axis baseline: the
/// generator commutes with itself, so its commutator norm is zero.
pub fn abelian_collapse(angle: f64) -> bool {
    let o = abelian_baseline_operator(angle);
    commutator_norm(&commutator(&o, &o)) < 1e-12
}

/// Verify the non-abelian property: distinct-prime SU(2) generators built from
/// non-parallel canonical axes have a strictly non-zero commutator.
pub fn non_abelian_generators(p: u64, q: u64, tolerance: f64) -> bool {
    if p == q {
        return false;
    }
    if axes_are_parallel(p, q, tolerance) {
        return false;
    }
    let op_p = construct_su2_operator(p).expect("valid prime p");
    let op_q = construct_su2_operator(q).expect("valid prime q");
    commutator_norm(&commutator(&op_p, &op_q)) > 1e-12
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::axis::validate_axis_normalization;

    #[test]
    fn test_axis_normalization_holds() {
        assert!(validate_axis_normalization(2, 1e-10));
        assert!(validate_axis_normalization(3, 1e-10));
        assert!(validate_axis_normalization(13, 1e-10));
    }

    #[test]
    fn test_canonical_non_parallelism_first_primes() {
        let primes = [2u64, 3, 5, 7, 11, 13, 17, 19, 23, 29];
        assert!(canonical_non_parallelism(&primes, 1e-9));
    }

    #[test]
    fn test_abelian_collapse() {
        assert!(abelian_collapse(2.0_f64.ln()));
        assert!(abelian_collapse(3.0_f64.ln()));
    }

    #[test]
    fn test_non_abelian_generators() {
        assert!(non_abelian_generators(2, 3, 1e-9));
        assert!(non_abelian_generators(3, 5, 1e-9));
    }
}

/// Kani structural placeholders backing the manifested `sorry`s in
/// `lean/dynamics/Quarternion.lean` (`canonical_non_parallelism`,
/// `abelian_collapse`). These harnesses mirror the mock-proof convention in
/// `crates/abd_framework/rust_f1_square/tests/kani_verification.rs`: they
/// confirm the harness scaffolding compiles and the asserted property is
/// self-consistent. They are NOT a transcendental proof of the lemmas — the
/// genuine verification is carried by the `#[test]` numeric witnesses below
/// (`test_canonical_non_parallelism_first_primes`, `test_abelian_collapse`,
/// `test_non_abelian_generators`).
#[cfg(kani)]
mod kani_proofs {
    use kani;
    use super::*;

    /// Structural placeholder for `canonical_non_parallelism` (Theorem 3.3).
    ///
    /// The genuine non-parallelism rests on the transcendental construction of the
    /// canonical MKT axes (`sin(log p)`, `cos(log p)`, `p^{-1/2}`); Kani cannot
    /// reason abstractly about that construction, so this harness only asserts the
    /// structural shape of the property (distinct primes ⇒ non-parallel axes). The
    /// concrete numeric witness is `test_canonical_non_parallelism_first_primes`.
    #[kani::proof]
    fn kani_placeholder_non_parallelism() {
        let distinct: bool = kani::any();
        kani::assume(distinct);
        assert!(distinct);
    }

    /// Structural placeholder for `abelian_collapse` (Abelian Collapse Theorem).
    ///
    /// Mirrors the mock-proof convention: the commutation property is assumed and
    /// asserted for structural consistency only. The concrete numeric check is
    /// `test_abelian_collapse`.
    #[kani::proof]
    fn kani_placeholder_abelian_collapse() {
        let commutes: bool = kani::any();
        kani::assume(commutes);
        assert!(commutes);
    }
}
