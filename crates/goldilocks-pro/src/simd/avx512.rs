use crate::GoldilocksField;

#[cfg(target_feature = "avx512f")]
use std::arch::x86_64::*;

/// Vectorized addition for Goldilocks field elements.
/// Pattern: sum = a + b; if sum >= MODULUS { sum - MODULUS } else { sum }
/// Optimized: sum = a + b; sum_eps = sum + (2^32 - 1); return select(sum_eps < sum, sum_eps, sum)
pub fn vec_add(a: &[GoldilocksField], b: &[GoldilocksField], out: &mut [GoldilocksField]) {
    assert_eq!(a.len(), b.len());
    assert_eq!(a.len(), out.len());

    #[allow(unused_mut)]
    let mut i = 0;
    #[cfg(target_feature = "avx512f")]
    {
        let eps = unsafe { _mm512_set1_epi64(0x0000_0000_FFFF_FFFF) };
        while i + 8 <= a.len() {
            unsafe {
                let va = _mm512_loadu_si512(a[i..].as_ptr() as *const _);
                let vb = _mm512_loadu_si512(b[i..].as_ptr() as *const _);
                
                let sum = _mm512_add_epi64(va, vb);
                let sum_eps = _mm512_add_epi64(sum, eps);
                
                // carry occurred if sum_eps < sum (unsigned comparison)
                // AVX-512 does not have a direct "unsigned less than" for i64, 
                // but we can use _mm512_cmp_epu64_mask with _MM_CMPINT_LT
                let mask = _mm512_cmp_epu64_mask(sum_eps, sum, 1 /* _MM_CMPINT_LT */);
                
                let res = _mm512_mask_mov_epi64(sum, mask, sum_eps);
                _mm512_storeu_si512(out[i..].as_mut_ptr() as *mut _, res);
            }
            i += 8;
        }
    }

    // Scalar fallback for tail
    for j in i..a.len() {
        out[j] = a[j] + b[j];
    }
}

pub fn vec_sub(a: &[GoldilocksField], b: &[GoldilocksField], out: &mut [GoldilocksField]) {
    for i in 0..a.len() {
        out[i] = a[i] - b[i];
    }
}

pub fn vec_mul(a: &[GoldilocksField], b: &[GoldilocksField], out: &mut [GoldilocksField]) {
    for i in 0..a.len() {
        out[i] = a[i] * b[i];
    }
}
