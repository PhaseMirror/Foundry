//! Monotonicity helper for the Universal Atomic Calculator (UAC)
//!
//! Provides a runtime check equivalent to the Lean theorem
//! `gram_points_monotone`. The function returns true iff the supplied
//! function `f : usize -> Ratio<i64>` is monotone non‑decreasing on the
//! interval `[n, m]`.

use num_rational::Ratio;

/// Checks monotonicity of `f` on the discrete range `[n, m]`.
/// Returns `true` if for every `k` with `n ≤ k < m` we have `f(k) ≤ f(k+1)`.
pub fn gram_points_monotone_check<F>(f: &F, n: usize, m: usize) -> bool
where
    F: Fn(usize) -> Ratio<i64>,
{
    if n > m {
        return false;
    }
    let mut prev = f(n);
    for k in (n + 1)..=m {
        let cur = f(k);
        if prev > cur {
            return false;
        }
        prev = cur;
    }
    true
}
