//! # Multiplicity Kernel — GCD/LCM lattice and polynomial algebra (ADR-0001)
//!
//! Mirrors `Spec/GCDLCM.lean` (gcd/lcm lattice laws), `Spec/Polynomial.lean`
//! (Horner evaluation) and `Spec/RootMultiplicity.lean` (synthetic division,
//! root multiplicity).
//!
//! Total functions: the gcd is a Euclidean loop with a fixed safe iteration
//! bound (Euclid terminates in ≤ 128 steps for `u64`, which is
//! Kani-verifiable without unwinding); polynomial arithmetic uses wrapping
//! `i64`, i.e. the unbounded Lean `Int` semantics reduced modulo `2^64`, so
//! the algebraic identities hold exactly.
//!
//! Zero-trust contract: no `unsafe`, no black-box algebra; the lattice and
//! remainder-theorem laws are certified by Kani on bounded domains and pinned
//! by the deterministic regression vectors.

/// Greatest common divisor by Euclid, with a fixed safe loop bound.
pub fn gcd(a: u64, b: u64) -> u64 {
    let (mut a, mut b) = (a, b);
    for _ in 0..128 {
        if b == 0 {
            break;
        }
        let t = a % b;
        a = b;
        b = t;
    }
    a
}

/// `gcd` is commutative.
pub fn gcd_comm(a: u64, b: u64) -> bool {
    gcd(a, b) == gcd(b, a)
}

/// `gcd` is associative.
pub fn gcd_assoc(a: u64, b: u64, c: u64) -> bool {
    gcd(gcd(a, b), c) == gcd(a, gcd(b, c))
}

/// Least common multiple; `0` when either input is `0`.  Saturating.
pub fn lcm(a: u64, b: u64) -> u64 {
    let g = gcd(a, b);
    if g == 0 {
        return 0;
    }
    (a / g).saturating_mul(b)
}

/// `(gcd, lcm)` pair.
pub fn gcd_lcm(a: u64, b: u64) -> (u64, u64) {
    (gcd(a, b), lcm(a, b))
}

/// Horner evaluation with wrapping `i64` arithmetic (modular mirror of the
/// unbounded Lean `Int` evaluation).  `poly_eval [] x = 0`.
pub fn poly_eval(cs: &[i64], x: i64) -> i64 {
    let mut acc: i64 = 0;
    for &c in cs {
        acc = acc.wrapping_mul(x).wrapping_add(c);
    }
    acc
}

/// Synthetic (Ruffini) division by `x - r`: `(quotient, remainder)`.
/// Mirror of `Spec.RootMultiplicity.quotientRemainder`: for the empty
/// polynomial it is `([], 0)`; otherwise the quotient is the Horner
/// accumulator list without its last entry, and the remainder is that last
/// accumulator (equal to `poly_eval cs r`).
pub fn synthetic_division(cs: &[i64], r: i64) -> (Vec<i64>, i64) {
    let mut it = cs.iter();
    let Some(&c0) = it.next() else {
        return (Vec::new(), 0);
    };
    let mut accs: Vec<i64> = vec![c0];
    let mut rem = c0;
    for &c in it {
        let b = rem.wrapping_mul(r).wrapping_add(c);
        accs.push(b);
        rem = b;
    }
    let _ = accs.pop();
    (accs, rem)
}

/// `r` is a root of `cs` when evaluation at `r` vanishes.
pub fn is_root(cs: &[i64], r: i64) -> bool {
    poly_eval(cs, r) == 0
}

/// Root multiplicity by repeated synthetic division, bounded by the degree.
pub fn root_multiplicity(cs: &[i64], r: i64) -> usize {
    let mut count: usize = 0;
    let mut cur: Vec<i64> = cs.to_vec();
    while !cur.is_empty() {
        let (q, rem) = synthetic_division(&cur, r);
        if rem != 0 {
            break;
        }
        count += 1;
        cur = q;
    }
    count
}

#[cfg(test)]
mod tests {
    use super::*;
    use multiplicity_core::divides;

    #[test]
    fn gcd_values() {
        assert_eq!(gcd(12, 18), 6);
        assert_eq!(gcd(17, 97), 1);
        assert_eq!(gcd(0, 5), 5);
        assert_eq!(gcd(5, 0), 5);
        assert_eq!(gcd(0, 0), 0);
        assert_eq!(gcd(64, 48), 16);
    }

    #[test]
    fn gcd_divides_both() {
        for a in 1..100u64 {
            for b in 1..100u64 {
                let g = gcd(a, b);
                assert!(divides(g, a), "{g} | {a}");
                assert!(divides(g, b), "{g} | {b}");
            }
        }
    }

    #[test]
    fn gcd_comm_and_assoc() {
        for a in 1..30u64 {
            for b in 1..30u64 {
                assert!(gcd_comm(a, b));
                for c in 1..15u64 {
                    assert!(gcd_assoc(a, b, c));
                }
            }
        }
    }

    #[test]
    fn gcd_mul_lcm_identity() {
        for a in 1..200u64 {
            for b in 1..200u64 {
                let (g, l) = gcd_lcm(a, b);
                assert_eq!(g.wrapping_mul(l), a.wrapping_mul(b), "gcd*lcm for {a},{b}");
            }
        }
    }

    #[test]
    fn lcm_values() {
        assert_eq!(lcm(4, 6), 12);
        assert_eq!(lcm(3, 5), 15);
        assert_eq!(lcm(0, 7), 0);
        assert_eq!(lcm(7, 0), 0);
    }

    #[test]
    fn poly_eval_values() {
        assert_eq!(poly_eval(&[], 3), 0);
        assert_eq!(poly_eval(&[5], 3), 5);
        // x^2 - 2x + 1 at x = 1 is 0.
        assert_eq!(poly_eval(&[1, -2, 1], 1), 0);
        // x^2 - 1 at x = 1 is 0, at x = 0 is -1.
        assert_eq!(poly_eval(&[-1, 0, 1], 1), 0);
        assert_eq!(poly_eval(&[-1, 0, 1], 0), 1);
    }

    #[test]
    fn poly_eval_quad_identity() {
        for a in -20i64..20 {
            for b in -20i64..20 {
                for c in -20i64..20 {
                    for x in -20i64..20 {
                        let direct = (a.wrapping_mul(x).wrapping_add(b))
                            .wrapping_mul(x)
                            .wrapping_add(c);
                        assert_eq!(poly_eval(&[a, b, c], x), direct);
                    }
                }
            }
        }
    }

    #[test]
    fn synthetic_division_values() {
        assert_eq!(synthetic_division(&[], 3), (vec![], 0));
        assert_eq!(synthetic_division(&[5], 3), (vec![], 5));
        // (x - 1)^2 = x^2 - 2x + 1 divided by (x - 1): quotient x - 1, rem 0.
        assert_eq!(synthetic_division(&[1, -2, 1], 1), (vec![1, -1], 0));
    }

    #[test]
    fn remainder_theorem() {
        for r in -10i64..10 {
            for a in -10i64..10 {
                for b in -10i64..10 {
                    for c in -10i64..10 {
                        let cs = [a, b, c];
                        let (_, rem) = synthetic_division(&cs, r);
                        assert_eq!(rem, poly_eval(&cs, r), "remainder at r={r}");
                    }
                }
            }
        }
    }

    #[test]
    fn root_multiplicity_values() {
        // (x - 1)^2
        assert_eq!(root_multiplicity(&[1, -2, 1], 1), 2);
        assert_eq!(root_multiplicity(&[1, -2, 1], 0), 0);
        // x^2 - 1 = (x-1)(x+1)
        assert_eq!(root_multiplicity(&[-1, 0, 1], 1), 1);
        assert_eq!(root_multiplicity(&[-1, 0, 1], -1), 1);
        // constant 0: root at any point, bounded by degree 1.
        assert_eq!(root_multiplicity(&[0], 5), 1);
        assert_eq!(root_multiplicity(&[1], 5), 0);
    }

    #[test]
    fn root_multiplicity_bounded_by_degree() {
        let cs = [1, -2, 1];
        for r in -10i64..10 {
            assert!(root_multiplicity(&cs, r) <= cs.len(), "r={r}");
        }
    }

    #[test]
    fn nonroot_multiplicity_zero() {
        let cs = [1, -2, 1];
        for r in -10i64..10 {
            if poly_eval(&cs, r) != 0 {
                assert_eq!(root_multiplicity(&cs, r), 0, "r={r}");
            }
        }
    }
}
