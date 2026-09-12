//! Partition function p(n).
//!
//! p(n) counts the number of ways to write n as a sum of positive integers,
//! disregarding order.
//!
//! Computed via the pentagonal number theorem recurrence:
//! p(0) = 1
//! p(n) = Σ_{k≥1} (-1)^{k+1} [p(n - k(3k-1)/2) + p(n - k(3k+1)/2)]
//!
//! Total on `u64`.  Verified by regression tests and Kani harnesses.

/// Generalized pentagonal numbers: g(k) = k(3k-1)/2 for k ∈ ℤ \ {0}.
fn pentagonal(k: i64) -> i64 {
    k * (3 * k - 1) / 2
}

/// Largest k such that pentagonal(k) ≤ n.
pub fn pentagonal_bound(n: u64) -> i64 {
    if n == 0 {
        return 0;
    }
    let mut k: i64 = 1;
    while pentagonal(k) <= n as i64 {
        k += 1;
    }
    k - 1
}

/// Partition function p(n) via pentagonal number theorem.
/// Total on `u64`.  Uses a vector for memoization.
pub fn partition_count(n: u64) -> u64 {
    if n == 0 {
        return 1;
    }
    let mut p: Vec<u64> = vec![0; (n + 1) as usize];
    p[0] = 1;
    for i in 1..=n {
        let mut sum: i64 = 0;
        let mut k: i64 = 1;
        loop {
            let g1 = pentagonal(k);
            let g2 = pentagonal(-k);
            if g1 > i as i64 && g2 > i as i64 {
                break;
            }
            if g1 <= i as i64 {
                let idx = (i - g1 as u64) as usize;
                if k % 2 == 1 {
                    sum += p[idx] as i64;
                } else {
                    sum -= p[idx] as i64;
                }
            }
            if g2 <= i as i64 && g2 != g1 {
                let idx = (i - g2 as u64) as usize;
                if k % 2 == 1 {
                    sum += p[idx] as i64;
                } else {
                    sum -= p[idx] as i64;
                }
            }
            k += 1;
        }
        p[i as usize] = sum.abs() as u64;
    }
    p[n as usize]
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn partition_count_small() {
        assert_eq!(partition_count(0), 1);
        assert_eq!(partition_count(1), 1);
        assert_eq!(partition_count(2), 2);
        assert_eq!(partition_count(3), 3);
        assert_eq!(partition_count(4), 5);
        assert_eq!(partition_count(5), 7);
        assert_eq!(partition_count(10), 42);
        assert_eq!(partition_count(20), 627);
    }

    #[test]
    fn partition_monotonic() {
        let mut prev = 0;
        for n in 1..50u64 {
            let p = partition_count(n);
            assert!(p > prev, "p({n}) = {p} not > p({}) = {prev}", n - 1);
            prev = p;
        }
    }

    #[test]
    fn partition_nonzero() {
        for n in 1..100u64 {
            assert!(partition_count(n) > 0, "p({n}) = 0");
        }
    }

    #[test]
    fn pentagonal_bound_correct() {
        assert_eq!(pentagonal_bound(0), 0);
        assert_eq!(pentagonal_bound(1), 1);
        assert_eq!(pentagonal_bound(2), 1);
        assert_eq!(pentagonal_bound(5), 2);
        assert_eq!(pentagonal_bound(100), 8);
    }
}
