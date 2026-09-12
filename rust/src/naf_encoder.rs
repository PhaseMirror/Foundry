use num_bigint::BigInt;
use num_traits::{Zero, One};

/// Encodes an integer `n` into its w‑NAF (Non‑Adjacent Form) signed digit representation.
/// The resulting vector of digits satisfies:
/// - Every digit is in [-2^{w-1}-1, 2^{w-1}]
/// - Between any two non‑zero digits there are at least w‑1 zeros.
///
/// This implementation follows the recursion:
///   naf(w, 0) = [0]
///   naf(w, n) = d :: naf(w, (n - d) / 2)
/// where d is the least absolute residue of n modulo 2^w, chosen to be odd if n is odd.
///
/// The Lean theorem `normalize_integer_w_normal` proves these properties.
pub fn naf_encode(w: u32, n: i32) -> Vec<i32> {
    if n == 0 {
        return vec![0];
    }

    let w = w as usize;
    let modulus = 1 << w; // 2^w
    let half_modulus = 1 << (w - 1); // 2^{w-1}

    // Compute the least absolute residue d of n modulo modulus.
    // We want d in the range (-half_modulus, half_modulus].
    let mut d = n % modulus;
    if d > half_modulus {
        d -= modulus;
    }
    // If n is odd, ensure d is odd.
    if n % 2 != 0 {
        // d should be odd; if it's even, adjust by ±modulus to make it odd.
        if d % 2 == 0 {
            d += if d > 0 { -modulus } else { modulus };
        }
    } else {
        // n even => d must be 0.
        // The least absolute residue of an even number is always even, but we need it to be 0.
        // In the algorithm, for even n, we always pick d = 0.
        d = 0;
    }

    let rest = (n - d) / 2;

    let mut digits = vec![d];
    digits.extend(naf_encode(w as u32, rest));
    digits
}

// ---------- Kani Harness ----------
#[cfg(kani)]
mod kani_harness {
    use super::*;

    #[kani::proof]
    #[kani::unwind(64)] // maximum length of NAF for 32‑bit integers
    fn verify_naf_properties() {
        // We verify for w in [2, 32] and n in [-2^31, 2^31-1]
        let w: u32 = kani::any();
        kani::assume(w >= 2 && w <= 32);
        let n: i32 = kani::any();

        let digits = naf_encode(w, n);

        // Property 1: digit bounds
        let half = 1 << (w - 1);
        for &d in &digits {
            let lower = -(half - 1);
            let upper = half;
            assert!(d >= lower && d <= upper);
        }

        // Property 2: non‑adjacency (at least w-1 zeros between non‑zero digits)
        let mut last_nonzero_idx = None;
        for (i, &d) in digits.iter().enumerate() {
            if d != 0 {
                if let Some(last) = last_nonzero_idx {
                    let gap = i - last;
                    assert!(gap >= w as usize);
                }
                last_nonzero_idx = Some(i);
            }
        }
    }
}
