//! Port of the basis generation and valuation logic from
//! `export_basis.py` (`generate_basis` / `compute_valuations`).
//!
//! Python uses arbitrary-precision integers; this port is defined over `u64`
//! and documents the constraint that `max(p) ** max_exp * ...` must stay below
//! `u64::MAX`. The production basis (`[2, 3, 5, 7]`, `max_exp = 3`) peaks at
//! `9_261_000`, far inside the domain.

/// Enumerate the multiplicative basis: all `n = p1^e1 * ... * pk^ek` with
/// `0 <= ei <= max_exp`, deduplicated and sorted ascending — the port of
/// `sorted(set(numbers))` in `generate_basis`.
pub fn generate_basis(primes: &[u64], max_exp: u64) -> Vec<u64> {
    let mut numbers = Vec::new();
    if primes.is_empty() {
        return numbers;
    }
    let mut exps = vec![0u64; primes.len()];
    loop {
        let product = product_of(primes, &exps);
        if let Some(n) = product {
            if n > 0 {
                numbers.push(n);
            }
        }
        let mut i = 0;
        loop {
            if i == exps.len() {
                numbers.sort_unstable();
                numbers.dedup();
                return numbers;
            }
            exps[i] += 1;
            if exps[i] <= max_exp {
                break;
            }
            exps[i] = 0;
            i += 1;
        }
    }
}

fn product_of(primes: &[u64], exps: &[u64]) -> Option<u64> {
    let mut n: u64 = 1;
    for (&p, &e) in primes.iter().zip(exps.iter()) {
        let exp = u32::try_from(e).ok()?;
        let power = u64::checked_pow(p, exp)?;
        n = n.checked_mul(power)?;
    }
    Some(n)
}

/// Port of `compute_valuations`: the exponent vector of each `n` under each
/// prime, computed by repeated exact division.
///
/// Preconditions mirroring Python: `primes` must contain values `>= 2`
/// (`p = 1` would loop forever, `p = 0` would divide by zero).
pub fn compute_valuations(numbers: &[u64], primes: &[u64]) -> Vec<Vec<u64>> {
    numbers
        .iter()
        .map(|&n| {
            primes
                .iter()
                .map(|&p| {
                    let mut v = 0u64;
                    let mut tmp = n;
                    while tmp % p == 0 {
                        v += 1;
                        tmp /= p;
                    }
                    v
                })
                .collect()
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn small_basis_matches_python_semantics() {
        let basis = generate_basis(&[2, 3], 2);
        assert_eq!(basis, vec![1, 2, 3, 4, 6, 9, 12, 18, 36]);
    }

    #[test]
    fn single_prime_is_exact_powers() {
        assert_eq!(generate_basis(&[5], 3), vec![1, 5, 25, 125]);
    }

    #[test]
    fn empty_primes_yield_empty_basis() {
        assert!(generate_basis(&[], 3).is_empty());
    }

    #[test]
    fn valuations_divide_each_number() {
        let primes = vec![2, 3, 5, 7];
        let basis = generate_basis(&primes, 3);
        let valuations = compute_valuations(&basis, &primes);
        for (&n, v) in basis.iter().zip(valuations.iter()) {
            let mut restored = 1u64;
            for (&p, &e) in primes.iter().zip(v.iter()) {
                for _ in 0..e {
                    restored *= p;
                }
            }
            assert_eq!(restored, n);
        }
    }

    #[test]
    fn production_basis_has_256_states() {
        let primes = vec![2, 3, 5, 7];
        let basis = generate_basis(&primes, 3);
        assert_eq!(basis.len(), 256);
        assert_eq!(basis[0], 1);
        assert_eq!(*basis.last().unwrap(), 9_261_000);
    }
}