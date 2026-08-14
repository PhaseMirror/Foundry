#![allow(clippy::missing_safety_doc)]

/// Computes the multiplicity operator $\Phi^{op} = \Lambda \cdot I$ in-place.
#[no_mangle]
pub unsafe extern "C" fn multiplicity_op_f64(lambda: f64, x: *const f64, out: *mut f64, len: usize) {
    if x.is_null() || out.is_null() { return; }
    let x_slice = std::slice::from_raw_parts(x, len);
    let out_slice = std::slice::from_raw_parts_mut(out, len);
    for i in 0..len {
        out_slice[i] = lambda * x_slice[i];
    }
}

/// Computes the update operator $\Phi(x) = \Xi(U)x + Fx = (\sum_p \alpha_p \pi_p M_p) x + Fx$.
#[no_mangle]
pub unsafe extern "C" fn update_op_f64(
    alpha_pi: *const f64,
    m_ops: *const f64, 
    f_op: *const f64,  
    x: *const f64,
    out: *mut f64,
    n: usize,
    num_primes: usize
) {
    if alpha_pi.is_null() || m_ops.is_null() || f_op.is_null() || x.is_null() || out.is_null() { return; }
    
    let alpha_pi = std::slice::from_raw_parts(alpha_pi, num_primes);
    let m_ops = std::slice::from_raw_parts(m_ops, num_primes * n * n);
    let f_op = std::slice::from_raw_parts(f_op, n * n);
    let x = std::slice::from_raw_parts(x, n);
    let out = std::slice::from_raw_parts_mut(out, n);

    for i in 0..n { out[i] = 0.0; }

    // F x
    for i in 0..n {
        for j in 0..n {
            out[i] += f_op[i * n + j] * x[j];
        }
    }

    // sum_p (alpha_pi[p] * M_p) x
    for p_idx in 0..num_primes {
        let w = alpha_pi[p_idx];
        let m_p = &m_ops[p_idx * n * n .. (p_idx + 1) * n * n];
        for i in 0..n {
            for j in 0..n {
                out[i] += w * m_p[i * n + j] * x[j];
            }
        }
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    #[kani::unwind(4)]
    fn verify_multiplicity_op_bounded() {
        let lambda: f64 = kani::any();
        kani::assume(lambda.is_finite());
        
        let mut x = [0.0; 3];
        for v in &mut x { 
            *v = kani::any();
            kani::assume(v.is_finite());
        }
        
        let mut out = [0.0; 3];
        unsafe { multiplicity_op_f64(lambda, x.as_ptr(), out.as_mut_ptr(), 3); }
        
        // Boundedness property: output is exactly scaled
        for i in 0..3 {
            if (lambda * x[i]).is_finite() {
                assert_eq!(out[i], lambda * x[i]);
            }
        }
    }

    #[kani::proof]
    #[kani::unwind(3)]
    fn verify_update_op_memory_safety() {
        let n = 2;
        let num_primes = 2;
        
        let alpha_pi: [f64; 2] = kani::any();
        let m_ops: [f64; 8] = kani::any();
        let f_op: [f64; 4] = kani::any();
        let x: [f64; 2] = kani::any();
        let mut out = [0.0; 2];

        // Memory safety check: this should not panic or access out of bounds
        unsafe {
            update_op_f64(
                alpha_pi.as_ptr(),
                m_ops.as_ptr(),
                f_op.as_ptr(),
                x.as_ptr(),
                out.as_mut_ptr(),
                n,
                num_primes
            );
        }
    }
}
