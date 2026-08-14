//! # Multiplicity Kernel — Core primitives (ADR-0001)
//!
//! The Lean side of the kernel (`Spec/Nat.lean`, `Spec/Int.lean`,
//! `Spec/Multiset.lean`) reasons about unbounded `Nat`/`Int`.  On the Rust
//! side the same objects are total functions on `u64`/`i64`; overflow is
//! handled by saturation or wrapping so that *every* function is total (no
//! panic), and the identity laws that hold in the unbounded integers are
//! certified modulo `2^64` (wrapping) where needed.
//!
//! Zero-trust contract: no `unsafe`, no external algebra; everything is
//! derived from the arithmetic of the language and cross-checked by Kani.
//!
//! Mirrors: `Spec/Core.lean` (doctrine), `Spec/Nat.lean` (factorial),
//! `Spec/Int.lean` (floor division), `Spec/Multiset.lean` (occurrences).

/// `n!`, saturating at `u64::MAX`.  Total for all `n`.
pub fn factorial(n: u64) -> u64 {
    let mut acc: u64 = 1;
    for k in 1..=n {
        acc = acc.saturating_mul(k);
    }
    acc
}

/// Divisibility `a ∣ b` mirroring `Nat`: `0 ∣ b` holds exactly for `b = 0`.
pub fn divides(a: u64, b: u64) -> bool {
    if a == 0 {
        b == 0
    } else {
        b % a == 0
    }
}

/// Euclidean (floor) division with non-negative remainder, mirroring Lean's
/// `Int.ediv`/`Int.emod`.  `b = 0` follows the Lean convention
/// `a / 0 = 0`, `a % 0 = a`.  Total (handles `i64::MIN / -1`).
pub fn int_div_mod(a: i64, b: i64) -> (i64, i64) {
    if b == 0 {
        return (0, a);
    }
    if a == i64::MIN && b == -1 {
        // `MIN / -1` overflows truncated division; Lean's `Int` has no such
        // bound, so `MIN = MIN * (-1) + 0` holds wrappingly.
        return (i64::MIN, 0);
    }
    let q = a.div_euclid(b);
    let r = a.rem_euclid(b);
    (q, r)
}

/// Occurrence count (multiplicity) of `a` in `l`, mirroring `Spec/Multiset`.
pub fn occurs(a: u64, l: &[u64]) -> usize {
    l.iter().filter(|&&x| x == a).count()
}

/// Mirror of `Theorem P := P`: a theorem obligation is accepted exactly when
/// its (Boolean) statement holds.
pub fn theorem(statement: bool) -> bool {
    statement
}

/// Mirror of the Lean `FormWitness` four-fold acceptance record
/// (`Spec/Core.lean`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FormWitness {
    pub statement: String,
    pub rust_fn: String,
    pub kani_proof: String,
    pub regression: String,
}

impl FormWitness {
    /// Mirror of `witness_certifies`: a witness is accepted only when it
    /// carries a real statement.
    pub fn certifies(&self) -> bool {
        !self.statement.is_empty()
    }
}

/// Mirror of `Deterministic`: a pure function returns the same output for the
/// same input (checked on one sample; the Lean side makes this structural).
pub fn is_deterministic<A: Copy, B: PartialEq>(f: impl Fn(A) -> B, x: A) -> bool {
    f(x) == f(x)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn factorial_small_values() {
        assert_eq!(factorial(0), 1);
        assert_eq!(factorial(1), 1);
        assert_eq!(factorial(5), 120);
        assert_eq!(factorial(10), 3_628_800);
    }

    #[test]
    fn factorial_positive() {
        for n in 0..64u64 {
            assert!(factorial(n) >= 1);
        }
    }

    #[test]
    fn divides_basic() {
        assert!(divides(3, 9));
        assert!(divides(1, 100));
        assert!(divides(0, 0));
        assert!(!divides(0, 5));
        assert!(!divides(4, 10));
        assert!(divides(7, 7));
    }

    #[test]
    fn int_div_mod_identity() {
        for a in -50i64..50 {
            for b in -10i64..10 {
                let (q, r) = int_div_mod(a, b);
                assert_eq!(q.wrapping_mul(b).wrapping_add(r), a);
                if b != 0 {
                    assert!(r >= 0, "a={a} b={b} r={r}");
                }
            }
        }
    }

    #[test]
    fn int_div_mod_zero_divisor() {
        assert_eq!(int_div_mod(5, 0), (0, 5));
        assert_eq!(int_div_mod(-3, 0), (0, -3));
    }

    #[test]
    fn int_div_mod_min_edge() {
        assert_eq!(int_div_mod(i64::MIN, -1), (i64::MIN, 0));
    }

    #[test]
    fn int_div_mod_euclidean_values() {
        // Lean `Int.emod` is Euclidean: remainder is non-negative.
        assert_eq!(int_div_mod(-7, 3), (-3, 2));
        assert_eq!(int_div_mod(7, -3), (-2, 1));
    }

    #[test]
    fn occurs_counts() {
        assert_eq!(occurs(2, &[2, 1, 2, 2, 5]), 3);
        assert_eq!(occurs(9, &[2, 1, 2, 2, 5]), 0);
        assert_eq!(occurs(1, &[]), 0);
    }

    #[test]
    fn occurs_additive() {
        let l = [1, 2, 1];
        let m = [3, 1];
        let mut u = Vec::new();
        u.extend_from_slice(&l);
        u.extend_from_slice(&m);
        assert_eq!(occurs(1, &u), occurs(1, &l) + occurs(1, &m));
        assert_eq!(occurs(3, &u), occurs(3, &l) + occurs(3, &m));
    }

    #[test]
    fn occurs_perm_swap() {
        for a in 0..8u64 {
            for x in 0..8u64 {
                for y in 0..8u64 {
                    assert_eq!(occurs(a, &[x, y]), occurs(a, &[y, x]));
                }
            }
        }
    }

    #[test]
    fn doctrine() {
        assert!(theorem(true));
        assert!(!theorem(false));
        let w = FormWitness {
            statement: "∀ n, 0 < n!".into(),
            rust_fn: "multiplicity-core/src/lib.rs:factorial".into(),
            kani_proof: "kani/proofs/fact_pos.rs".into(),
            regression: "kani/regression/fact_pos.json".into(),
        };
        assert!(w.certifies());
        assert!(is_deterministic(factorial, 5));
    }
}
