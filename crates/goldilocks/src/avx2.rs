use std::arch::x86_64::*;
use crate::GOLDILOCKS_PRIME;

#[derive(Clone, Copy, Debug)]
#[repr(transparent)]
pub struct Avx2Goldilocks(pub __m256i);

impl Avx2Goldilocks {
    /// Load four u64 values into a 256-bit register.
    #[inline]
    #[target_feature(enable = "avx2")]
    pub unsafe fn load(vals: &[u64; 4]) -> Self {
        Self(_mm256_loadu_si256(vals.as_ptr() as *const __m256i))
    }

    /// Store the four u64 values into a slice.
    #[inline]
    #[target_feature(enable = "avx2")]
    pub unsafe fn store(&self, vals: &mut [u64; 4]) {
        _mm256_storeu_si256(vals.as_mut_ptr() as *mut __m256i, self.0);
    }

    /// Lane-wise addition: a + b
    #[inline]
    #[target_feature(enable = "avx2")]
    pub unsafe fn add(a: Self, b: Self) -> Self {
        let sum = _mm256_add_epi64(a.0, b.0);
        Self(reduce_after_add(a.0, sum))
    }

    /// Lane-wise subtraction: a - b
    #[inline]
    #[target_feature(enable = "avx2")]
    pub unsafe fn sub(a: Self, b: Self) -> Self {
        let diff = _mm256_sub_epi64(a.0, b.0);
        Self(reduce_after_sub(a.0, b.0, diff))
    }

    /// Lane-wise multiplication: a * b
    #[inline]
    #[target_feature(enable = "avx2")]
    pub unsafe fn mul(a: Self, b: Self) -> Self {
        let (lo, hi) = mul_64x64_to_128(a.0, b.0);
        Self(reduce_wide(lo, hi))
    }

    /// Butterfly operation: (u, v) -> (u + t, u - t) where t = v * omega
    #[inline]
    #[target_feature(enable = "avx2")]
    pub unsafe fn butterfly(u: Self, v: Self, omega: Self) -> (Self, Self) {
        let t = Self::mul(v, omega);
        (Self::add(u, t), Self::sub(u, t))
    }
}

/// Unsigned 64-bit comparison: a < b
#[inline]
#[target_feature(enable = "avx2")]
unsafe fn cmplt_u64(a: __m256i, b: __m256i) -> __m256i {
    let offset = _mm256_set1_epi64x(i64::MIN);
    let a_signed = _mm256_xor_si256(a, offset);
    let b_signed = _mm256_xor_si256(b, offset);
    _mm256_cmpgt_epi64(b_signed, a_signed)
}

/// Unsigned 64-bit comparison: a >= b
#[inline]
#[target_feature(enable = "avx2")]
unsafe fn cmpge_u64(a: __m256i, b: __m256i) -> __m256i {
    let lt = cmplt_u64(a, b);
    _mm256_xor_si256(lt, _mm256_set1_epi64x(-1))
}

/// Reduction after addition.
#[inline]
#[target_feature(enable = "avx2")]
unsafe fn reduce_after_add(a: __m256i, sum: __m256i) -> __m256i {
    let p = _mm256_set1_epi64x(GOLDILOCKS_PRIME as i64);
    let overflow_mask = cmplt_u64(sum, a);
    let overflow_correction = _mm256_and_si256(overflow_mask, _mm256_set1_epi64x(0xFFFFFFFF));
    let reduced = _mm256_add_epi64(sum, overflow_correction);
    let mask = cmpge_u64(reduced, p);
    _mm256_sub_epi64(reduced, _mm256_and_si256(mask, p))
}

/// Reduction after subtraction.
#[inline]
#[target_feature(enable = "avx2")]
unsafe fn reduce_after_sub(a: __m256i, b: __m256i, diff: __m256i) -> __m256i {
    let p = _mm256_set1_epi64x(GOLDILOCKS_PRIME as i64);
    let mask = cmplt_u64(a, b);
    _mm256_add_epi64(diff, _mm256_and_si256(mask, p))
}

/// Multiply four 64-bit lanes into four 128-bit results (lo/hi parts).
#[inline]
#[target_feature(enable = "avx2")]
unsafe fn mul_64x64_to_128(a: __m256i, b: __m256i) -> (__m256i, __m256i) {
    let a_lo = a;
    let b_lo = b;
    let a_hi = _mm256_srli_epi64(a, 32);
    let b_hi = _mm256_srli_epi64(b, 32);
    
    let ll = _mm256_mul_epu32(a_lo, b_lo);
    let lh = _mm256_mul_epu32(a_lo, b_hi);
    let hl = _mm256_mul_epu32(a_hi, b_lo);
    let hh = _mm256_mul_epu32(a_hi, b_hi);
    
    let mid = _mm256_add_epi64(lh, hl);
    let carry_mask = cmplt_u64(mid, lh);
    let mid_carry = _mm256_and_si256(carry_mask, _mm256_set1_epi64x(1));
    
    let hh_final = _mm256_add_epi64(hh, _mm256_slli_epi64(mid_carry, 32));
    
    let mid_lo = _mm256_slli_epi64(mid, 32);
    let mid_hi = _mm256_srli_epi64(mid, 32);
    
    let res_lo = _mm256_add_epi64(ll, mid_lo);
    let carry_mask2 = cmplt_u64(res_lo, ll);
    let res_hi_carry = _mm256_add_epi64(mid_hi, _mm256_and_si256(carry_mask2, _mm256_set1_epi64x(1)));
    
    let res_hi = _mm256_add_epi64(hh_final, res_hi_carry);
    
    (res_lo, res_hi)
}

/// Reduce a 128-bit value (lo, hi) modulo Goldilocks prime.
#[inline]
#[target_feature(enable = "avx2")]
unsafe fn reduce_wide(lo: __m256i, hi: __m256i) -> __m256i {
    let p = _mm256_set1_epi64x(GOLDILOCKS_PRIME as i64);
    
    let hi_lo = _mm256_and_si256(hi, _mm256_set1_epi64x(0xFFFFFFFF));
    let hi_hi = _mm256_srli_epi64(hi, 32);
    
    let hi_lo_32 = _mm256_slli_epi64(hi_lo, 32);
    let mut reduced = _mm256_add_epi64(lo, hi_lo_32);
    
    let carry1 = cmplt_u64(reduced, lo);
    let carry1_val = _mm256_and_si256(carry1, _mm256_set1_epi64x(0xFFFFFFFF));
    reduced = _mm256_add_epi64(reduced, carry1_val);
    
    let mask_sub1 = cmplt_u64(reduced, hi_lo);
    reduced = _mm256_sub_epi64(reduced, hi_lo);
    reduced = _mm256_add_epi64(reduced, _mm256_and_si256(mask_sub1, p));

    let mask_sub2 = cmplt_u64(reduced, hi_hi);
    reduced = _mm256_sub_epi64(reduced, hi_hi);
    reduced = _mm256_add_epi64(reduced, _mm256_and_si256(mask_sub2, p));
    
    let mask_final = cmpge_u64(reduced, p);
    _mm256_sub_epi64(reduced, _mm256_and_si256(mask_final, p))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::GoldilocksField;

    #[cfg(target_feature = "avx2")]
    #[test]
    fn test_avx2_mul_edge_cases() {
        let edges = [
            0, 1, 2, 0xFFFFFFFF, 0x100000000, 
            GOLDILOCKS_PRIME - 1, GOLDILOCKS_PRIME - 2,
            0x12345678, 0xABCDEF01,
        ];
        
        for &a_val in &edges {
            for &b_val in &edges {
                unsafe {
                    let a_avx = Avx2Goldilocks::load(&[a_val, b_val, a_val, b_val]);
                    let b_avx = Avx2Goldilocks::load(&[b_val, a_val, b_val, a_val]);
                    let c_avx = Avx2Goldilocks::mul(a_avx, b_avx);
                    let mut c_vals = [0u64; 4];
                    c_avx.store(&mut c_vals);
                    
                    let fa = GoldilocksField::new(a_val);
                    let fb = GoldilocksField::new(b_val);
                    let expected = fa.mul(&fb).to_canonical();
                    
                    assert_eq!(c_vals[0], expected);
                    assert_eq!(c_vals[1], expected);
                }
            }
        }
    }
}
