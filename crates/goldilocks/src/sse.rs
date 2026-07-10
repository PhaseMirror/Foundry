use std::arch::x86_64::*;
use crate::GOLDILOCKS_PRIME;

#[derive(Clone, Copy, Debug)]
#[repr(transparent)]
pub struct SSEGoldilocks(pub __m128i);

impl SSEGoldilocks {
    /// Load two u64 values into a 128-bit register.
    #[inline]
    pub unsafe fn load(vals: &[u64; 2]) -> Self {
        Self(_mm_loadu_si128(vals.as_ptr() as *const __m128i))
    }

    /// Store the two u64 values into a slice.
    #[inline]
    pub unsafe fn store(&self, vals: &mut [u64; 2]) {
        _mm_storeu_si128(vals.as_mut_ptr() as *mut __m128i, self.0);
    }

    /// Lane-wise addition: a + b
    #[inline]
    pub unsafe fn add(a: Self, b: Self) -> Self {
        // SSE doesn't have a direct "add with carry" for 64-bit lanes that wraps correctly
        // for modular reduction in a single instruction.
        // But _mm_add_epi64 does 64-bit addition.
        let sum = _mm_add_epi64(a.0, b.0);
        
        // Reduction: if sum >= P, sum -= P
        // If overflow happened (sum < a), we also need to add 2^64 mod P = 2^32 - 1
        Self(reduce_after_add(a.0, sum))
    }

    /// Lane-wise subtraction: a - b
    #[inline]
    pub unsafe fn sub(a: Self, b: Self) -> Self {
        let diff = _mm_sub_epi64(a.0, b.0);
        
        // If a < b, then diff = a - b + 2^64. 
        // We want (a - b) mod P.
        // If a < b, diff - (2^64 - P) = diff - (2^32 - 1)
        Self(reduce_after_sub(a.0, b.0, diff))
    }

    /// Lane-wise multiplication: a * b
    #[inline]
    pub unsafe fn mul(a: Self, b: Self) -> Self {
        let (lo, hi) = mul_64x64_to_128(a.0, b.0);
        Self(reduce_wide(lo, hi))
    }

    /// Butterfly operation: (u, v) -> (u + t, u - t) where t = v * omega
    #[inline]
    pub unsafe fn butterfly(u: Self, v: Self, omega: Self) -> (Self, Self) {
        let t = Self::mul(v, omega);
        (Self::add(u, t), Self::sub(u, t))
    }
}

/// Multiply two 64-bit lanes into two 128-bit results (lo/hi parts of each lane).
#[inline]
unsafe fn mul_64x64_to_128(a: __m128i, b: __m128i) -> (__m128i, __m128i) {
    let a_lo = a;
    let b_lo = b;
    let a_hi = _mm_srli_epi64(a, 32);
    let b_hi = _mm_srli_epi64(b, 32);
    
    let ll = _mm_mul_epu32(a_lo, b_lo);
    let lh = _mm_mul_epu32(a_lo, b_hi);
    let hl = _mm_mul_epu32(a_hi, b_lo);
    let hh = _mm_mul_epu32(a_hi, b_hi);
    
    let mid = _mm_add_epi64(lh, hl);
    let carry_mask = cmplt_u64(mid, lh);
    let mid_carry = _mm_and_si128(carry_mask, _mm_set1_epi64x(1));
    
    // hh_final = hh + mid_carry * 2^32
    // Actually, mid_carry is at bit 64 of mid, so it's bit 96 of total.
    // hh starts at bit 64. So mid_carry should be shifted by 32 and added to hh.
    let hh_final = _mm_add_epi64(hh, _mm_slli_epi64(mid_carry, 32));
    
    let mid_lo = _mm_slli_epi64(mid, 32);
    let mid_hi = _mm_srli_epi64(mid, 32);
    
    let res_lo = _mm_add_epi64(ll, mid_lo);
    let carry_mask2 = cmplt_u64(res_lo, ll);
    let res_hi_carry = _mm_add_epi64(mid_hi, _mm_and_si128(carry_mask2, _mm_set1_epi64x(1)));
    
    let res_hi = _mm_add_epi64(hh_final, res_hi_carry);
    
    (res_lo, res_hi)
}

/// Reduce a 128-bit value (lo, hi) modulo Goldilocks prime.
/// hi * 2^64 + lo ≡ hi_lo * (2^32 - 1) - hi_hi + lo (mod p)
#[inline]
unsafe fn reduce_wide(lo: __m128i, hi: __m128i) -> __m128i {
    let p = _mm_set1_epi64x(GOLDILOCKS_PRIME as i64);
    
    let hi_lo = _mm_and_si128(hi, _mm_set1_epi64x(0xFFFFFFFF));
    let hi_hi = _mm_srli_epi64(hi, 32);
    
    // hi_lo * (2^32 - 1) + lo - hi_hi
    
    let hi_lo_32 = _mm_slli_epi64(hi_lo, 32);
    let mut reduced = _mm_add_epi64(lo, hi_lo_32);
    
    // Handle carry from lo + hi_lo_32
    let carry1 = cmplt_u64(reduced, lo);
    // If carry1, we need to add 2^64 mod p = 2^32 - 1
    let carry1_val = _mm_and_si128(carry1, _mm_set1_epi64x(0xFFFFFFFF));
    reduced = _mm_add_epi64(reduced, carry1_val);
    
    // Subtract hi_lo
    let mask_sub1 = cmplt_u64(reduced, hi_lo);
    reduced = _mm_sub_epi64(reduced, hi_lo);
    reduced = _mm_add_epi64(reduced, _mm_and_si128(mask_sub1, p));

    // Subtract hi_hi
    let mask_sub2 = cmplt_u64(reduced, hi_hi);
    reduced = _mm_sub_epi64(reduced, hi_hi);
    reduced = _mm_add_epi64(reduced, _mm_and_si128(mask_sub2, p));
    
    // Final check for >= P
    let mask_final = cmpge_u64(reduced, p);
    _mm_sub_epi64(reduced, _mm_and_si128(mask_final, p))
}

/// Reduction after addition.
/// sum = a + b (mod 2^64)
/// We need sum mod P.
/// If sum < a (overflow happened), then result is sum + (2^64 mod P) = sum + (2^32 - 1).
/// Also need to handle the case where sum >= P but no overflow happened.
#[inline]
unsafe fn reduce_after_add(a: __m128i, sum: __m128i) -> __m128i {
    let p = _mm_set1_epi64x(GOLDILOCKS_PRIME as i64);
    
    // Check for 64-bit overflow
    let overflow_mask = cmplt_u64(sum, a);
    let overflow_correction = _mm_and_si128(overflow_mask, _mm_set1_epi64x(0xFFFFFFFF));
    
    let reduced = _mm_add_epi64(sum, overflow_correction);
    
    // Final check for >= P
    let mask = cmpge_u64(reduced, p);
    _mm_sub_epi64(reduced, _mm_and_si128(mask, p))
}

/// Reduction after subtraction.
/// diff = a - b (mod 2^64)
/// If a < b, result is diff + P (mod 2^64) = diff - (2^64 - P) = diff - (2^32 - 1).
#[inline]
unsafe fn reduce_after_sub(a: __m128i, b: __m128i, diff: __m128i) -> __m128i {
    let p = _mm_set1_epi64x(GOLDILOCKS_PRIME as i64);
    let mask = cmplt_u64(a, b);
    _mm_add_epi64(diff, _mm_and_si128(mask, p))
}

/// Unsigned 64-bit comparison: a >= b
#[inline]
unsafe fn cmpge_u64(a: __m128i, b: __m128i) -> __m128i {
    // a >= b  <=>  !(a < b)
    let lt = cmplt_u64(a, b);
    _mm_xor_si128(lt, _mm_set1_epi64x(-1)) // NOT
}

/// Unsigned 64-bit comparison: a < b
#[inline]
unsafe fn cmplt_u64(a: __m128i, b: __m128i) -> __m128i {
    // x86 doesn't have unsigned 64-bit comparison.
    // Trick: flip the high bit of both and use signed comparison.
    let offset = _mm_set1_epi64x(i64::MIN);
    let a_signed = _mm_xor_si128(a, offset);
    let b_signed = _mm_xor_si128(b, offset);
    // a < b  <=>  b > a
    _mm_cmpgt_epi64(b_signed, a_signed)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::GoldilocksField;

    #[test]
    fn test_sse_add() {
        unsafe {
            let a_vals = [10, GOLDILOCKS_PRIME - 5];
            let b_vals = [20, 10];
            let a = SSEGoldilocks::load(&a_vals);
            let b = SSEGoldilocks::load(&b_vals);
            let c = SSEGoldilocks::add(a, b);
            let mut c_vals = [0u64; 2];
            c.store(&mut c_vals);
            
            assert_eq!(c_vals[0], 30);
            assert_eq!(c_vals[1], 5);
        }
    }

    #[test]
    fn test_sse_sub() {
        unsafe {
            let a_vals = [30, 5];
            let b_vals = [10, 10];
            let a = SSEGoldilocks::load(&a_vals);
            let b = SSEGoldilocks::load(&b_vals);
            let c = SSEGoldilocks::sub(a, b);
            let mut c_vals = [0u64; 2];
            c.store(&mut c_vals);
            
            assert_eq!(c_vals[0], 20);
            assert_eq!(c_vals[1], GOLDILOCKS_PRIME - 5);
        }
    }

    #[test]
    fn test_sse_mul() {
        unsafe {
            let a_vals = [7, GOLDILOCKS_PRIME - 1];
            let b_vals = [11, 2];
            let a = SSEGoldilocks::load(&a_vals);
            let b = SSEGoldilocks::load(&b_vals);
            let c = SSEGoldilocks::mul(a, b);
            let mut c_vals = [0u64; 2];
            c.store(&mut c_vals);
            
            assert_eq!(c_vals[0], 77);
            assert_eq!(c_vals[1], GOLDILOCKS_PRIME - 2);
        }
    }

    #[test]
    fn test_sse_mul_edge_cases() {
        let edges = [
            0, 1, 2, 0xFFFFFFFF, 0x100000000, 
            GOLDILOCKS_PRIME - 1, GOLDILOCKS_PRIME - 2,
            0x12345678, 0xABCDEF01,
        ];
        
        for &a_val in &edges {
            for &b_val in &edges {
                unsafe {
                    let a_sse = SSEGoldilocks::load(&[a_val, b_val]);
                    let b_sse = SSEGoldilocks::load(&[b_val, a_val]);
                    let c_sse = SSEGoldilocks::mul(a_sse, b_sse);
                    let mut c_vals = [0u64; 2];
                    c_sse.store(&mut c_vals);
                    
                    let fa = GoldilocksField::new(a_val);
                    let fb = GoldilocksField::new(b_val);
                    let expected = fa.mul(&fb).to_canonical();
                    
                    assert_eq!(c_vals[0], expected, "Mul edge case failed: {} * {}", a_val, b_val);
                }
            }
        }
    }

    #[test]
    fn test_sse_differential() {
        use rand::Rng;
        let mut rng = rand::thread_rng();
        for _ in 0..100_000 {
            let a_vals = [rng.gen::<u64>(), rng.gen::<u64>()];
            let b_vals = [rng.gen::<u64>(), rng.gen::<u64>()];
            
            unsafe {
                let a_sse = SSEGoldilocks::load(&a_vals);
                let b_sse = SSEGoldilocks::load(&b_vals);
                
                // Add
                let c_add_sse = SSEGoldilocks::add(a_sse, b_sse);
                let mut c_add_vals = [0u64; 2];
                c_add_sse.store(&mut c_add_vals);
                
                // Sub
                let c_sub_sse = SSEGoldilocks::sub(a_sse, b_sse);
                let mut c_sub_vals = [0u64; 2];
                c_sub_sse.store(&mut c_sub_vals);
                
                // Mul
                let c_mul_sse = SSEGoldilocks::mul(a_sse, b_sse);
                let mut c_mul_vals = [0u64; 2];
                c_mul_sse.store(&mut c_mul_vals);
                
                for i in 0..2 {
                    let fa = GoldilocksField::new(a_vals[i]);
                    let fb = GoldilocksField::new(b_vals[i]);
                    
                    if c_add_vals[i] != fa.add(&fb).to_canonical() {
                        panic!("Add mismatch at lane {} for a={}, b={}. SSE={}, Scalar={}", 
                            i, a_vals[i], b_vals[i], c_add_vals[i], fa.add(&fb).to_canonical());
                    }
                    if c_sub_vals[i] != fa.sub(&fb).to_canonical() {
                        panic!("Sub mismatch at lane {} for a={}, b={}. SSE={}, Scalar={}", 
                            i, a_vals[i], b_vals[i], c_sub_vals[i], fa.sub(&fb).to_canonical());
                    }
                    if c_mul_vals[i] != fa.mul(&fb).to_canonical() {
                        // Diagnostic info for multiplication failure
                        let (lo, hi) = mul_64x64_to_128(
                            _mm_set1_epi64x(a_vals[i] as i64),
                            _mm_set1_epi64x(b_vals[i] as i64)
                        );
                        let mut lo_val = [0u64; 2];
                        let mut hi_val = [0u64; 2];
                        _mm_storeu_si128(lo_val.as_mut_ptr() as *mut __m128i, lo);
                        _mm_storeu_si128(hi_val.as_mut_ptr() as *mut __m128i, hi);
                        
                        panic!("Mul mismatch at lane {} for a={}, b={}. SSE={}, Scalar={}. Product Lo={}, Hi={}", 
                            i, a_vals[i], b_vals[i], c_mul_vals[i], fa.mul(&fb).to_canonical(),
                            lo_val[0], hi_val[0]);
                    }
                }
            }
        }
    }

    #[test]
    fn test_sse_butterfly_differential() {
        use rand::Rng;
        let mut rng = rand::thread_rng();
        for _ in 0..10_000 {
            let u_vals = [rng.gen::<u64>(), rng.gen::<u64>()];
            let v_vals = [rng.gen::<u64>(), rng.gen::<u64>()];
            let w_vals = [rng.gen::<u64>(), rng.gen::<u64>()];
            
            unsafe {
                let u_sse = SSEGoldilocks::load(&u_vals);
                let v_sse = SSEGoldilocks::load(&v_vals);
                let w_sse = SSEGoldilocks::load(&w_vals);
                
                let (res_u_sse, res_v_sse) = SSEGoldilocks::butterfly(u_sse, v_sse, w_sse);
                
                let mut res_u_vals = [0u64; 2];
                let mut res_v_vals = [0u64; 2];
                res_u_sse.store(&mut res_u_vals);
                res_v_sse.store(&mut res_v_vals);
                
                for i in 0..2 {
                    let fu = GoldilocksField::new(u_vals[i]);
                    let fv = GoldilocksField::new(v_vals[i]);
                    let fw = GoldilocksField::new(w_vals[i]);
                    
                    let ft = fv.mul(&fw);
                    let expected_u = fu.add(&ft);
                    let expected_v = fu.sub(&ft);
                    
                    assert_eq!(res_u_vals[i], expected_u.to_canonical());
                    assert_eq!(res_v_vals[i], expected_v.to_canonical());
                }
            }
        }
    }
}
