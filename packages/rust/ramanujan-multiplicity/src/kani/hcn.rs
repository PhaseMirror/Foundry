//! Kani harnesses for `ramanujan_multiplicity::hcn`.

use crate::{is_hcn, divisor_count, hcn_up_to};

/// `is_hcn` agrees with `hcn_up_to` on 1..=1000.
#[cfg(kani)]
#[kani::proof]
fn verify_hcn_consistency() {
    let n: u64 = kani::any();
    kani::assume(n >= 1 && n <= 1000);
    let hcns = hcn_up_to(1000);
    let expected = hcns.contains(&n);
    kani::assert(is_hcn(n) == expected, "is_hcn agrees with hcn_up_to");
}

/// `d(n)` is strictly increasing on the HCN sequence up to 1000.
#[cfg(kani)]
#[kani::proof]
fn verify_hcn_strictly_increasing_d() {
    let hcns = hcn_up_to(1000);
    for i in 1..hcns.len() {
        let d_prev = divisor_count(hcns[i - 1]);
        let d_curr = divisor_count(hcns[i]);
        kani::assert(d_curr > d_prev, "HCN d(n) strictly increasing");
    }
}

/// `1` is always an HCN.
#[cfg(kani)]
#[kani::proof]
fn verify_one_is_hcn() {
    kani::assert(is_hcn(1), "1 is HCN");
}
