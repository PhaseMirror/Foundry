// umc_wht.rs
// WHT-Epistasis Spectral Encoding with Multiplicity Theory

/// Performs an in-place length-64 Fast Walsh-Hadamard Transform (FWHT).
/// The input array represents the 64-dimensional feature space histogram.
pub fn fwht_64(h: &mut [i64; 64]) {
    // 6-bit feature space requires 6 passes
    let mut h_step = 1;
    for _ in 0..6 {
        for i in (0..64).step_by(h_step * 2) {
            for j in i..(i + h_step) {
                let u = h[j];
                let v = h[j + h_step];
                h[j] = u + v;
                h[j + h_step] = u - v;
            }
        }
        h_step *= 2;
    }
}

/// Computes the Primorial Spectral Weight for a 6-bit binary index \zeta.
/// p_k = {2, 3, 5, 7, 11, 13}
pub fn spectral_weight(zeta: u8) -> u64 {
    let primes = [2, 3, 5, 7, 11, 13];
    let mut weight = 1;
    for (k, &p) in primes.iter().enumerate() {
        if (zeta & (1 << k)) != 0 {
            weight *= p;
        }
    }
    weight
}

#[cfg(kani)]
mod verification {
    use super::*;

    /// Theorem: The DC component (index 0) of the FWHT is exactly the sum of the histogram (Population N).
    #[kani::proof]
    fn verify_dc_population() {
        let mut h: [i64; 64] = [0; 64];
        let mut total_n: i64 = 0;
        
        // Initialize with arbitrary bounded values to prevent overflow during sum
        for i in 0..64 {
            let val: i32 = kani::any();
            kani::assume(val >= 0 && val < 1000);
            h[i] = val as i64;
            total_n += h[i];
        }

        fwht_64(&mut h);

        kani::assert(
            h[0] == total_n,
            "DC component of FWHT must equal the total population N",
        );
    }

    /// Theorem: FWHT is its own inverse multiplied by 64 (2^6).
    #[kani::proof]
    fn verify_fwht_involution() {
        let mut h: [i64; 64] = [0; 64];
        let mut original: [i64; 64] = [0; 64];
        
        for i in 0..64 {
            let val: i16 = kani::any();
            h[i] = val as i64;
            original[i] = h[i];
        }

        // Apply FWHT twice
        fwht_64(&mut h);
        fwht_64(&mut h);

        // Check original scaled by 64
        for i in 0..64 {
            kani::assert(
                h[i] == original[i] * 64,
                "Double FWHT must yield the original array scaled by 64",
            );
        }
    }
}
