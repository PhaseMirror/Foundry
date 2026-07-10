use crate::GoldilocksField;

#[cfg(target_arch = "aarch64")]
use std::arch::aarch64::*;

pub fn vec_add(a: &[GoldilocksField], b: &[GoldilocksField], out: &mut [GoldilocksField]) {
    assert_eq!(a.len(), b.len());
    assert_eq!(a.len(), out.len());

    #[allow(unused_mut)]
    let mut i = 0;
    #[cfg(target_arch = "aarch64")]
    {
        let eps = unsafe { vdupq_n_u64(0x0000_0000_FFFF_FFFF) };
        while i + 2 <= a.len() {
            unsafe {
                let va = vld1q_u64(a[i..].as_ptr() as *const u64);
                let vb = vld1q_u64(b[i..].as_ptr() as *const u64);
                let sum = vaddq_u64(va, vb);
                let sum_eps = vaddq_u64(sum, eps);
                
                // mask = sum_eps < sum (unsigned)
                // aarch64 has vcltq_u64 for unsigned less than
                let mask = vcltq_u64(sum_eps, sum);
                
                // Bitwise select: vbslq_u64(mask, true_val, false_val)
                let res = vbslq_u64(mask, sum_eps, sum);
                vst1q_u64(out[i..].as_mut_ptr() as *mut u64, res);
            }
            i += 2;
        }
    }

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
