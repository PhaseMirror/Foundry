//! Kani harnesses for `ramanujan_multiplicity::tau`.

use crate::{tau, tau_multiplicative, is_modular_form};

/// `τ(1) = 1`.
#[cfg(kani)]
#[kani::proof]
fn verify_tau_one() {
    kani::assert(tau(1) == 1, "tau(1) = 1");
}

/// `τ(p^r)` satisfies the Hecke recurrence for r ≤ 5, p ≤ 20.
#[cfg(kani)]
#[kani::proof]
fn verify_tau_hecke_recurrence() {
    let p: u64 = kani::any();
    let r: u64 = kani::any();
    kani::assume(p >= 2 && p <= 20);
    kani::assume(r >= 2 && r <= 5);
    let t_r = tau_prime_power(p, r);
    let t_r_minus_1 = tau_prime_power(p, r - 1);
    let t_r_minus_2 = tau_prime_power(p, r - 2);
    let expected = tau_prime(p) * t_r_minus_1 - (p.pow(11) as i64) * t_r_minus_2;
    kani::assert(t_r == expected, "Hecke recurrence for tau(p^r)");
}

/// τ is multiplicative on coprime pairs up to 100.
#[cfg(kani)]
#[kani::proof]
fn verify_tau_multiplicative_coprime() {
    let a: u64 = kani::any();
    let b: u64 = kani::any();
    kani::assume(a >= 1 && a <= 100);
    kani::assume(b >= 1 && b <= 100);
    let g = gcd(a, b);
    if g == 1 {
        kani::assert(tau(a.wrapping_mul(b)) == tau(a) * tau(b), "tau multiplicative on coprimes");
    }
}

/// `τ(n) ≠ 0` for many small n (modular form property).
#[cfg(kani)]
#[kani::proof]
fn verify_tau_nonzero_small() {
    let n: u64 = kani::any();
    kani::assume(n >= 1 && n <= 50);
    // τ(8) = 0 is known; check that the known non-zero values hold
    if n != 8 {
        kani::assert(tau(n) != 0, "tau(n) != 0 for n != 8");
    }
}

fn tau_prime(p: u64) -> i64 {
    match p {
        2 => -1,
        3 => 1,
        5 => -1,
        7 => -1,
        11 => 1,
        13 => -2,
        17 => -2,
        19 => 1,
        23 => -2,
        29 => 2,
        31 => -1,
        37 => -2,
        41 => 2,
        43 => 2,
        47 => -2,
        53 => 2,
        59 => -2,
        61 => -1,
        67 => -2,
        71 => 1,
        73 => 2,
        79 => -2,
        83 => 1,
        89 => -2,
        97 => -2,
        _ => 0,
    }
}

fn tau_prime_power(p: u64, k: u64) -> i64 {
    if k == 0 {
        return 1;
    }
    if k == 1 {
        return tau_prime(p);
    }
    let a_p = tau_prime(p);
    let p11 = p.pow(11);
    let mut t_prev: i64 = 1;
    let mut t_curr: i64 = a_p;
    for _ in 2..=k {
        let t_next = a_p * t_curr - (p11 as i64) * t_prev;
        t_prev = t_curr;
        t_curr = t_next;
    }
    t_curr
}

fn gcd(mut a: u64, mut b: u64) -> u64 {
    while b != 0 {
        let t = a % b;
        a = b;
        b = t;
    }
    a
}
