/// Polynomial operations over Goldilocks field
/// 
/// Implements FFT/NTT for efficient polynomial evaluation and interpolation

use crate::{GoldilocksField, GOLDILOCKS_PRIME};

#[cfg(target_arch = "x86_64")]
use crate::sse::SSEGoldilocks;
#[cfg(target_arch = "x86_64")]
use crate::avx2::Avx2Goldilocks;

/// Compute NTT (Number Theoretic Transform) in-place
pub fn ntt(coeffs: &mut [GoldilocksField]) {
    let n = coeffs.len();
    assert!(n.is_power_of_two(), "NTT requires power-of-2 size");
    
    if n <= 1 {
        return;
    }
    
    // Bit-reverse permutation
    bit_reverse_permute(coeffs);
    
    // Find primitive root of unity
    let omega = get_root_of_unity(n);
    
    // Cooley-Tukey butterfly operations
    let mut m = 1;
    while m < n {
        let omega_m = omega.pow((n / (2 * m)) as u64);
        
        // Try SIMD path if possible
        let mut handled = false;
        #[cfg(target_arch = "x86_64")]
        {
            if m >= 8 { // Heuristic threshold for SIMD benefit
                unsafe {
                    if is_x86_feature_detected!("avx2") {
                        ntt_layer_avx2(coeffs, m, &omega_m);
                        handled = true;
                    } else if is_x86_feature_detected!("sse4.2") {
                        ntt_layer_sse(coeffs, m, &omega_m);
                        handled = true;
                    }
                }
            }
        }

        if !handled {
            for k in (0..n).step_by(2 * m) {
                let mut omega_power = GoldilocksField::ONE;
                
                for j in 0..m {
                    let t = omega_power.mul(&coeffs[k + j + m]);
                    let u = coeffs[k + j];
                    
                    coeffs[k + j] = u.add(&t);
                    coeffs[k + j + m] = u.sub(&t);
                    
                    omega_power = omega_power.mul(&omega_m);
                }
            }
        }
        
        m *= 2;
    }
}

#[cfg(target_arch = "x86_64")]
#[target_feature(enable = "sse4.2")]
unsafe fn ntt_layer_sse(coeffs: &mut [GoldilocksField], m: usize, omega_m: &GoldilocksField) {
    let n = coeffs.len();
    for k in (0..n).step_by(2 * m) {
        let mut omega_power = GoldilocksField::ONE;
        for j in (0..m).step_by(2) {
            let next_w = omega_power.mul(omega_m);
            let w_vals = [omega_power.to_canonical(), next_w.to_canonical()];
            let w_sse = SSEGoldilocks::load(&w_vals);
            
            let u_vals = [coeffs[k + j].to_canonical(), coeffs[k + j + 1].to_canonical()];
            let v_vals = [coeffs[k + j + m].to_canonical(), coeffs[k + j + m + 1].to_canonical()];
            
            let u_sse = SSEGoldilocks::load(&u_vals);
            let v_sse = SSEGoldilocks::load(&v_vals);
            
            let (res_u, res_v) = SSEGoldilocks::butterfly(u_sse, v_sse, w_sse);
            
            let mut res_u_vals = [0u64; 2];
            let mut res_v_vals = [0u64; 2];
            res_u.store(&mut res_u_vals);
            res_v.store(&mut res_v_vals);
            
            coeffs[k + j] = GoldilocksField::from_canonical(res_u_vals[0]);
            coeffs[k + j + 1] = GoldilocksField::from_canonical(res_u_vals[1]);
            coeffs[k + j + m] = GoldilocksField::from_canonical(res_v_vals[0]);
            coeffs[k + j + m + 1] = GoldilocksField::from_canonical(res_v_vals[1]);
            
            omega_power = next_w.mul(omega_m);
        }
    }
}

#[cfg(target_arch = "x86_64")]
#[target_feature(enable = "avx2")]
unsafe fn ntt_layer_avx2(coeffs: &mut [GoldilocksField], m: usize, omega_m: &GoldilocksField) {
    let n = coeffs.len();
    for k in (0..n).step_by(2 * m) {
        let mut omega_power = GoldilocksField::ONE;
        for j in (0..m).step_by(4) {
            let mut w_vals = [0u64; 4];
            let mut curr_w = omega_power;
            for i in 0..4 {
                w_vals[i] = curr_w.to_canonical();
                curr_w = curr_w.mul(omega_m);
            }
            let w_avx = Avx2Goldilocks::load(&w_vals);
            
            let mut u_vals = [0u64; 4];
            let mut v_vals = [0u64; 4];
            for i in 0..4 {
                u_vals[i] = coeffs[k + j + i].to_canonical();
                v_vals[i] = coeffs[k + j + m + i].to_canonical();
            }
            
            let u_avx = Avx2Goldilocks::load(&u_vals);
            let v_avx = Avx2Goldilocks::load(&v_vals);
            
            let (res_u, res_v) = Avx2Goldilocks::butterfly(u_avx, v_avx, w_avx);
            
            let mut res_u_vals = [0u64; 4];
            let mut res_v_vals = [0u64; 4];
            res_u.store(&mut res_u_vals);
            res_v.store(&mut res_v_vals);
            
            for i in 0..4 {
                coeffs[k + j + i] = GoldilocksField::from_canonical(res_u_vals[i]);
                coeffs[k + j + m + i] = GoldilocksField::from_canonical(res_v_vals[i]);
            }
            
            omega_power = curr_w;
        }
    }
}

/// Compute inverse NTT in-place
pub fn intt(values: &mut [GoldilocksField]) {
    let n = values.len();
    assert!(n.is_power_of_two(), "INTT requires power-of-2 size");
    
    if n <= 1 {
        return;
    }
    
    // NTT with inverse root
    let omega_inv = get_root_of_unity(n).inverse().expect("Root must be invertible");
    
    bit_reverse_permute(values);
    
    let mut m = 1;
    while m < n {
        let omega_m = omega_inv.pow((n / (2 * m)) as u64);
        
        for k in (0..n).step_by(2 * m) {
            let mut omega_power = GoldilocksField::ONE;
            
            for j in 0..m {
                let t = omega_power.mul(&values[k + j + m]);
                let u = values[k + j];
                
                values[k + j] = u.add(&t);
                values[k + j + m] = u.sub(&t);
                
                omega_power = omega_power.mul(&omega_m);
            }
        }
        
        m *= 2;
    }
    
    // Scale by 1/n
    let n_inv = GoldilocksField::new(n as u64).inverse().expect("n must be invertible");
    for val in values.iter_mut() {
        *val = val.mul(&n_inv);
    }
}

/// Evaluate polynomial at a single point using Horner's method
pub fn eval_poly(coeffs: &[GoldilocksField], x: &GoldilocksField) -> GoldilocksField {
    if coeffs.is_empty() {
        return GoldilocksField::ZERO;
    }
    
    let mut result = coeffs[coeffs.len() - 1];
    for i in (0..coeffs.len() - 1).rev() {
        result = result.mul(x).add(&coeffs[i]);
    }
    result
}

/// Interpolate polynomial from evaluations using INTT
pub fn interpolate(evaluations: &[GoldilocksField]) -> Vec<GoldilocksField> {
    let mut coeffs = evaluations.to_vec();
    intt(&mut coeffs);
    coeffs
}

/// Evaluate polynomial on a coset of the standard domain
pub fn eval_on_coset(
    coeffs: &[GoldilocksField],
    coset_shift: &GoldilocksField,
) -> Vec<GoldilocksField> {
    let n = coeffs.len();
    assert!(n.is_power_of_two());
    
    // Multiply coefficients by powers of coset shift
    let mut shifted_coeffs = Vec::with_capacity(n);
    let mut shift_power = GoldilocksField::ONE;
    
    for coeff in coeffs {
        shifted_coeffs.push(coeff.mul(&shift_power));
        shift_power = shift_power.mul(coset_shift);
    }
    
    // Evaluate using NTT
    ntt(&mut shifted_coeffs);
    shifted_coeffs
}

/// Get primitive n-th root of unity for Goldilocks field
/// 
/// omega_n = g^((p-1)/n)
fn get_root_of_unity(n: usize) -> GoldilocksField {
    assert!(n.is_power_of_two());
    assert!((n as u64) <= (1u64 << 32), "Order too large for Goldilocks");
    
    // Generator of multiplicative group
    let g = GoldilocksField::new(7);
    
    // omega = g^((p-1)/n)
    let exp = (GOLDILOCKS_PRIME - 1) / (n as u64);
    g.pow(exp)
}

/// Bit-reverse permutation for FFT
fn bit_reverse_permute(values: &mut [GoldilocksField]) {
    let n = values.len();
    let log_n = n.trailing_zeros() as usize;
    
    for i in 0..n {
        let j = reverse_bits(i, log_n);
        if i < j {
            values.swap(i, j);
        }
    }
}

/// Reverse the bottom `bits` bits of a number
fn reverse_bits(mut x: usize, bits: usize) -> usize {
    let mut result = 0;
    for _ in 0..bits {
        result = (result << 1) | (x & 1);
        x >>= 1;
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ntt_intt_roundtrip() {
        let coeffs: Vec<GoldilocksField> = (1..=16).map(GoldilocksField::new).collect();
        
        let mut values = coeffs.clone();
        ntt(&mut values);
        intt(&mut values);
        
        for (a, b) in coeffs.iter().zip(values.iter()) {
            assert_eq!(a, b);
        }
    }

    #[test]
    fn test_eval_poly() {
        let coeffs = vec![
            GoldilocksField::new(1),
            GoldilocksField::new(2),
            GoldilocksField::new(3),
        ];
        assert_eq!(eval_poly(&coeffs, &GoldilocksField::ZERO), GoldilocksField::new(1));
        assert_eq!(eval_poly(&coeffs, &GoldilocksField::ONE), GoldilocksField::new(6));
        assert_eq!(eval_poly(&coeffs, &GoldilocksField::new(2)), GoldilocksField::new(17));
    }

    #[test]
    fn test_interpolate() {
        let coeffs: Vec<GoldilocksField> = (1..=32).map(GoldilocksField::new).collect();
        let mut evals = coeffs.clone();
        ntt(&mut evals);
        let interpolated = interpolate(&evals);
        for (a, b) in coeffs.iter().zip(interpolated.iter()) {
            assert_eq!(a, b);
        }
    }
}
