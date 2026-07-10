use crate::{GoldilocksField, PrimeMask, ResonanceWord, SpectralWitness, FormalStabilityCertificate, CertificationStatus};
use crate::hamiltonian::Hamiltonian;
use std::collections::HashMap;

pub const N0_CIRCUIT: usize = 64;
pub const EPS_SPECTRAL: f64 = 0.15;

/// First 64 nontrivial zeta zero imaginary parts (gamma_j).
/// (Placeholder values, in a real system these would be precise constants).
pub fn get_reference_zeta_zeros() -> Vec<f64> {
    let mut zeros = vec![
        14.134725, 21.022040, 25.010858, 30.424876, 32.935062, 37.586178, 40.918719, 43.327073,
        48.005151, 49.773832, 52.970321, 56.446248, 59.347044, 60.831779, 65.112544, 67.079811,
        69.546402, 72.067158, 75.704691, 77.144840, 79.337375, 82.910381, 84.735493, 87.425275,
        88.809111, 92.491899, 94.651344, 95.870634, 98.831194, 101.31785, 103.72554, 105.44662,
        107.16861, 111.02954, 111.87466, 114.29540, 116.22668, 118.79073, 121.37013, 122.94683,
        124.25682, 127.51626, 129.57870, 131.08769, 133.49774, 134.75651, 138.11604, 139.73621,
        141.12371, 143.11185, 146.00098, 147.42276, 150.05352, 150.92526, 153.02469, 156.11291,
        157.59759, 158.84999, 161.18896, 163.03071, 165.53707, 167.32970, 169.09452, 172.27083,
    ];
    while zeros.len() < N0_CIRCUIT {
        let last = *zeros.last().unwrap();
        zeros.push(last + 2.5); // dummy extension
    }
    zeros
}

pub fn to_gold_fp(val: f64) -> GoldilocksField {
    // SCALE_GOLDILOCKS = 2^40
    let scale = 1u64 << 40;
    let scaled = (val * (scale as f64)).round() as i64;
    // We'll treat it as signed, then wrap to Goldilocks
    if scaled >= 0 {
        GoldilocksField::new(scaled as u64)
    } else {
        GoldilocksField::new((scaled as i128 + 0xFFFF_FFFF_0000_0001_i128) as u64)
    }
}

pub struct AzTftcSimulation {
    pub zeros: Vec<GoldilocksField>,
    pub hamiltonian: Hamiltonian,
}

impl AzTftcSimulation {
    pub fn new() -> Self {
        let ref_zeros = get_reference_zeta_zeros();
        let zeros = ref_zeros.into_iter().map(to_gold_fp).collect();
        
        let mut hamiltonian = Hamiltonian::new(N0_CIRCUIT);
        // Add some sample terms
        hamiltonian.add_term(PrimeMask::from_bit(0), to_gold_fp(0.1), Some(0));
        hamiltonian.add_term(PrimeMask::from_bit(1), to_gold_fp(0.05), Some(1));
        
        Self { zeros, hamiltonian }
    }

    pub fn run_step(&self, active_mask: PrimeMask, resonance_state: &HashMap<u8, ResonanceWord>) -> FormalStabilityCertificate {
        // 1. Evaluate Hamiltonian
        let _coeffs = self.hamiltonian.evaluate(active_mask, resonance_state);
        
        // 2. Generate Spectral Witness
        // Simplified: compute delta_pz as the first spacing
        let d0 = if self.zeros.len() >= 2 {
            self.zeros[1].0.wrapping_sub(self.zeros[0].0)
        } else {
            0
        };
        let delta_pz = GoldilocksField::new(d0);
        
        // Compute all spacings
        let mut zero_spacings = Vec::new();
        for i in 0..self.zeros.len() - 1 {
            zero_spacings.push(GoldilocksField::new(self.zeros[i+1].0.wrapping_sub(self.zeros[i].0)));
        }
        
        let witness = SpectralWitness {
            delta_pz,
            zero_spacings,
            gap_trend: 1, // Trending up for demo
        };

        // 3. Pro Certification
        // floor = N0_CIRCUIT ** -(0.5 + eps)
        let floor_val = (N0_CIRCUIT as f64).powf(-(0.5 + EPS_SPECTRAL));
        let floor = to_gold_fp(floor_val);

        let mut cert = FormalStabilityCertificate::new(
            CertificationStatus::PROVISIONAL,
            to_gold_fp(0.9),
            to_gold_fp(0.8),
        );
        cert.spectral = Some(witness);

        if cert.spectral_healthy(floor) {
            cert.status = CertificationStatus::PASS;
        } else {
            cert.status = cert.tier4_recovery_check();
        }

        cert
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_simulation_pass() {
        let sim = AzTftcSimulation::new();
        let mut resonance_state = HashMap::new();
        resonance_state.insert(0, ResonanceWord::pack_q29_29(0, 1.0));
        
        let cert = sim.run_step(PrimeMask::from_bit(0), &resonance_state);
        println!("Cert status: {:?}", cert.status);
        assert!(cert.status == CertificationStatus::PASS || cert.status == CertificationStatus::CONDITIONAL);
    }

    #[test]
    fn test_az_tftc_full_lifecycle() {
        println!("=== AZ-TFTC 1D Simulation Start ===");
        
        let sim = AzTftcSimulation::new();
        let mut resonance_state = HashMap::new();
        resonance_state.insert(0, ResonanceWord::pack_q29_29(0, 1.0));
        
        // 1. Production: ZetaBridge generates a spectral witness (simulated by run_step)
        // 2. Certification: Formal certificate Issued
        let cert = sim.run_step(PrimeMask::from_bit(0), &resonance_state);
        println!("SpectralWitness Generated: delta_pz={:?}", cert.spectral.as_ref().unwrap().delta_pz);
        println!("Certificate Result: status={:?}", cert.status);
        
        // 3. Export: Bundle extracted for ZK proving
        let inputs = cert.export_proof_inputs();
        println!("Exported Pro-tier Bundle: mask={:x}, word={:?}", inputs.prime_mask.0, inputs.resonance_word);
        
        // 4. Attestation: Proof generated and verified (cross-check)
        let public_vec = inputs.to_vec();
        println!("Wiring Cross-check: STARK Public Inputs Length = {}", public_vec.len());
        assert_eq!(public_vec.len(), 6);
        
        // Use PrimeResonanceAir for verification
        let air = crate::circuit::PrimeResonanceAir::new(inputs.prime_mask, inputs.resonance_word);
        assert!(air.verify());
        
        println!("Proof Verification: SUCCESS");
        println!("=== AZ-TFTC 1D Simulation COMPLETE ===");
    }
}
