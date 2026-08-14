//! Kani harnesses for `ramanujan_multiplicity::partitions`.

use crate::{partition_count, pentagonal_bound};

/// `p(0) = 1`.
#[cfg(kani)]
#[kani::proof]
fn verify_partition_zero() {
    kani::assert(partition_count(0) == 1, "p(0) = 1");
}

/// `p(n) ≥ 1` for all `n ≥ 1`.
#[cfg(kani)]
#[kani::proof]
fn verify_partition_positive() {
    let n: u64 = kani::any();
    kani::assume(n >= 1 && n <= 100);
    kani::assert(partition_count(n) >= 1, "p(n) >= 1");
}

/// `p(n)` is strictly increasing for `n ≥ 1`.
#[cfg(kani)]
#[kani::proof]
fn verify_partition_monotonic() {
    let n: u64 = kani::any();
    kani::assume(n >= 1 && n <= 50);
    let pn = partition_count(n);
    let pn1 = partition_count(n + 1);
    kani::assert(pn1 > pn, "p(n+1) > p(n)");
}

/// `pentagonal_bound(n)` returns the largest k with g(k) ≤ n.
#[cfg(kani)]
#[kani::proof]
fn verify_pentagonal_bound() {
    let n: u64 = kani::any();
    kani::assume(n >= 0 && n <= 500);
    let k = pentagonal_bound(n);
    if k > 0 {
        kani::assert(pentagonal(k) <= n as i64, "pentagonal(k) <= n");
    }
    if k < 100 {
        kani::assert(pentagonal(k + 1) > n as i64, "pentagonal(k+1) > n");
    }
}

fn pentagonal(k: i64) -> i64 {
    k * (3 * k - 1) / 2
}
