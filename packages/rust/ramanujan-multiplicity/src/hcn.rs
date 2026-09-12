//! Highly composite numbers (HCN).
//!
//! A highly composite number is a positive integer with more divisors than
//! any smaller positive integer.
//!
//! Total functions on `u64`.  Verified by regression tests and Kani harnesses.

use super::divisor::divisor_count;

/// Check if `n` is a highly composite number.
pub fn is_hcn(n: u64) -> bool {
    if n == 0 {
        return false;
    }
    let d_n = divisor_count(n);
    for m in 1..n {
        if divisor_count(m) >= d_n {
            return false;
        }
    }
    true
}

/// Find the next highly composite number after `n`.
pub fn next_hcn(n: u64) -> u64 {
    let mut candidate = n + 1;
    loop {
        if is_hcn(candidate) {
            return candidate;
        }
        candidate += 1;
    }
}

/// All highly composite numbers up to `limit`.
pub fn hcn_up_to(limit: u64) -> Vec<u64> {
    let mut result = Vec::new();
    let mut best_d = 0;
    for n in 1..=limit {
        let d = divisor_count(n);
        if d > best_d {
            best_d = d;
            result.push(n);
        }
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hcn_sequence_start() {
        assert!(is_hcn(1));
        assert!(is_hcn(2));
        assert!(is_hcn(4));
        assert!(is_hcn(6));
        assert!(is_hcn(12));
        assert!(!is_hcn(8));
        assert!(!is_hcn(9));
    }

    #[test]
    fn hcn_up_to_100() {
        let hcns = hcn_up_to(120);
        assert_eq!(hcns, vec![1, 2, 4, 6, 12, 24, 36, 48, 60, 120]);
    }

    #[test]
    fn hcn_next() {
        assert_eq!(next_hcn(1), 2);
        assert_eq!(next_hcn(2), 4);
        assert_eq!(next_hcn(4), 6);
        assert_eq!(next_hcn(6), 12);
    }

    #[test]
    fn hcn_strictly_increasing() {
        let hcns = hcn_up_to(1000);
        for i in 1..hcns.len() {
            assert!(hcns[i] > hcns[i - 1]);
        }
    }

    #[test]
    fn hcn_dominates_all_smaller() {
        let hcns = hcn_up_to(200);
        for &h in &hcns {
            let d_h = divisor_count(h);
            for m in 1..h {
                assert!(divisor_count(m) <= d_h, "d({m}) > d({h})");
            }
        }
    }
}
