use goldilocks::{GoldilocksField, PrimeMask, ResonanceWord};
use serde::{Deserialize, Serialize};

/// AIR for proving prime mask and resonance word bit decomposition and validation.
/// 
/// Trace layout (64 rows):
/// Col 0: prime_mask_bits (b_i)
/// Col 1: prime_mask_acc (sum b_j * 2^j)
/// Col 2: resonance_word_bits (r_i)
/// Col 3: resonance_word_acc (sum r_j * 2^j)
/// 
/// Constraints:
/// 1. b_i * (1 - b_i) = 0
/// 2. r_i * (1 - r_i) = 0
/// 3. pm_acc[i] = pm_acc[i-1] + b_i * 2^i  (with pm_acc[-1] = 0)
/// 4. rw_acc[i] = rw_acc[i-1] + r_i * 2^i  (with rw_acc[-1] = 0)
/// 5. r_6 * r_5 = 0  (Class validation: class < 96)
/// 
/// Public Inputs:
/// - pm_acc[63] == prime_mask
/// - rw_acc[63] == resonance_word
pub struct PrimeResonanceAir {
    pub prime_mask: u64,
    pub resonance_word: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrimeResonanceTrace {
    pub columns: Vec<Vec<GoldilocksField>>,
}

impl PrimeResonanceAir {
    pub fn new(prime_mask: PrimeMask, resonance_word: ResonanceWord) -> Self {
        Self {
            prime_mask: prime_mask.0,
            resonance_word: resonance_word.0,
        }
    }

    /// Generate the trace for the AIR.
    pub fn generate_trace(&self) -> PrimeResonanceTrace {
        let mut pm_bits = Vec::with_capacity(64);
        let mut pm_acc = Vec::with_capacity(64);
        let mut rw_bits = Vec::with_capacity(64);
        let mut rw_acc = Vec::with_capacity(64);

        let mut current_pm_acc = 0u64;
        let mut current_rw_acc = 0u64;

        for i in 0..64 {
            let b_i = (self.prime_mask >> i) & 1;
            let r_i = (self.resonance_word >> i) & 1;

            pm_bits.push(GoldilocksField::from_canonical(b_i));
            rw_bits.push(GoldilocksField::from_canonical(r_i));

            current_pm_acc += b_i << i;
            current_rw_acc += r_i << i;

            pm_acc.push(GoldilocksField::from_canonical(current_pm_acc));
            rw_acc.push(GoldilocksField::from_canonical(current_rw_acc));
        }

        PrimeResonanceTrace {
            columns: vec![pm_bits, pm_acc, rw_bits, rw_acc],
        }
    }

    /// Verify the trace against constraints (simulated AIR verification).
    pub fn verify_trace(&self, trace: &PrimeResonanceTrace) -> bool {
        if trace.columns.len() != 4 { return false; }
        if trace.columns[0].len() != 64 { return false; }

        let pm_bits = &trace.columns[0];
        let pm_acc = &trace.columns[1];
        let rw_bits = &trace.columns[2];
        let rw_acc = &trace.columns[3];

        let mut last_pm_acc = GoldilocksField::ZERO;
        let mut last_rw_acc = GoldilocksField::ZERO;

        for i in 0..64 {
            let b_i = pm_bits[i];
            let r_i = rw_bits[i];

            // 1 & 2. Booleanity
            if b_i != GoldilocksField::ZERO && b_i != GoldilocksField::ONE { return false; }
            if r_i != GoldilocksField::ZERO && r_i != GoldilocksField::ONE { return false; }

            // 3 & 4. Accumulation
            let two_pow_i = GoldilocksField::new(1u64 << i);
            let expected_pm_acc = last_pm_acc.add(&b_i.mul(&two_pow_i));
            let expected_rw_acc = last_rw_acc.add(&r_i.mul(&two_pow_i));

            if pm_acc[i] != expected_pm_acc { return false; }
            if rw_acc[i] != expected_rw_acc { return false; }

            last_pm_acc = pm_acc[i];
            last_rw_acc = rw_acc[i];
        }

        // 5. Class validation: class < 96
        // class = bits 0-6. bits 5 and 6 cannot both be 1.
        let r_5 = rw_bits[5];
        let r_6 = rw_bits[6];
        if r_5 == GoldilocksField::ONE && r_6 == GoldilocksField::ONE { return false; }

        // Final values check
        if pm_acc[63] != GoldilocksField::from_canonical(self.prime_mask) { return false; }
        if rw_acc[63] != GoldilocksField::from_canonical(self.resonance_word) { return false; }

        true
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use goldilocks::{PrimeMask, ResonanceWord};

    #[test]
    fn test_trace_generation_and_verification() {
        let pm = PrimeMask(0x123456789ABCDEF0);
        let rw = ResonanceWord::pack(95, 0x1234567890ABC);
        
        let air = PrimeResonanceAir::new(pm, rw);
        let trace = air.generate_trace();
        
        assert!(air.verify_trace(&trace));
    }

    #[test]
    fn test_invalid_class() {
        // We can't use ResonanceWord::pack with 96 because it asserts.
        // But we can manually create an invalid resonance word to test AIR validation.
        let pm = PrimeMask(0);
        let rw_val = (1 << 5) | (1 << 6); // class 96
        let air = PrimeResonanceAir {
            prime_mask: pm.0,
            resonance_word: rw_val,
        };
        let trace = air.generate_trace();
        assert!(!air.verify_trace(&trace));
    }
}
