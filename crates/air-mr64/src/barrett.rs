/// Barrett reduction for 64-bit modular arithmetic with full witness generation

use uint::construct_uint;

construct_uint! {
    pub struct U256(4);
}

#[derive(Debug, Clone, Copy, Default)]
pub struct RedStep {
    pub t_lo: u64,
    pub t_hi: u64,
    pub q_lo: u64,
    pub q_hi: u64,
    pub r_lo: u64,
    pub r_hi: u64,
}

/// Compute μ = ⌊2^128 / n⌋ for Barrett reduction
#[inline]
pub fn mu_for(n: u64) -> (u64, u64) {
    let mu = (U256::one() << 128) / U256::from(n);
    let mu_lo = mu.low_u128() as u64;
    let mu_hi = (mu >> 64).low_u128() as u64;
    (mu_lo, mu_hi)
}

/// Barrett reduction: compute (u * v) mod n with full witness
#[inline]
pub fn barrett_mulred(u: u64, v: u64, n: u64, mu: (u64, u64)) -> (u64, RedStep) {
    let n256 = U256::from(n);
    let t = U256::from(u) * U256::from(v);
    
    let mu256 = (U256::from(mu.1) << 64) + U256::from(mu.0);
    let q = (t * mu256) >> 128;
    
    let mut r = t - q * n256;
    
    // Final correction (at most two subtractions)
    if r >= n256 {
        r -= n256;
    }
    if r >= n256 {
        r -= n256;
    }
    
    let t_lo = t.low_u128() as u64;
    let t_hi = (t >> 64).low_u128() as u64;
    let q_lo = q.low_u128() as u64;
    let q_hi = (q >> 64).low_u128() as u64;
    let r_lo = r.low_u128() as u64;
    let r_hi = (r >> 64).low_u128() as u64;
    
    (r_lo, RedStep { t_lo, t_hi, q_lo, q_hi, r_lo, r_hi })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mu_computation() {
        let n = 17u64;
        let (mu_lo, mu_hi) = mu_for(n);
        
        // μ should be roughly 2^128 / 17
        let mu256 = (U256::from(mu_hi) << 64) + U256::from(mu_lo);
        let expected = (U256::one() << 128) / U256::from(n);
        assert_eq!(mu256, expected);
    }

    #[test]
    fn test_barrett_reduction() {
        let n = 17u64;
        let mu = mu_for(n);
        
        let (result, step) = barrett_mulred(5, 7, n, mu);
        
        // 5 * 7 = 35 ≡ 1 (mod 17)
        assert_eq!(result, 1);
        assert_eq!(step.t_lo, 35);
        assert_eq!(step.t_hi, 0);
        assert!(step.r_lo < n);
    }

    #[test]
    fn test_large_product() {
        let n = (1u64 << 32) - 5; // Large 64-bit modulus
        let mu = mu_for(n);
        
        let a = (1u64 << 31) + 123;
        let b = (1u64 << 31) + 456;
        
        let (result, step) = barrett_mulred(a, b, n, mu);
        
        // Result should be less than n
        assert!(result < n);
        
        // Witness values should be non-zero
        assert!(step.t_lo > 0 || step.t_hi > 0);
        assert_eq!(step.r_lo, result);
    }
}
