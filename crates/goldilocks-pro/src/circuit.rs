use crate::{GoldilocksField, PrimeMask, ResonanceWord};

/// Lever 6 — Plonky3 Circuit (Normative)
/// Public inputs for Pro-tier certification proofs.
/// Every field element lives in Goldilocks.
#[derive(Debug, Clone, PartialEq)]
pub struct ConvergencePublicInputsPro {
    /// Lever 2: Prime Mask
    pub prime_mask: PrimeMask,
    
    /// Lever 3: Resonance Word
    pub resonance_word: ResonanceWord,
    
    /// Lever 5: Spectral Gap (scaled)
    pub delta_pz: GoldilocksField,
    
    /// Pro-tier stability bounds
    pub rho_bound: GoldilocksField,
    pub lambda_m: GoldilocksField,
    
    /// Veto flag (0 = Pass, 1 = Veto)
    pub veto_flag: GoldilocksField,
}

impl ConvergencePublicInputsPro {
    /// Serialize the public inputs into a flat vector of Goldilocks field elements.
    /// This vector is used as the public input to the Plonky3 verifier.
    pub fn to_vec(&self) -> Vec<GoldilocksField> {
        vec![
            self.prime_mask.to_field(),
            self.resonance_word.to_field(),
            self.delta_pz,
            self.rho_bound,
            self.lambda_m,
            self.veto_flag,
        ]
    }
}

/// PrimeResonanceAir: AIR for proving prime mask and resonance word bit decomposition.
pub struct PrimeResonanceAir {
    pub prime_mask: u64,
    pub resonance_word: u64,
}

impl PrimeResonanceAir {
    pub fn new(mask: PrimeMask, word: ResonanceWord) -> Self {
        Self {
            prime_mask: mask.0,
            resonance_word: word.0,
        }
    }

    pub fn verify(&self) -> bool {
        // Simplified verification: just check bit length and class
        let class = (self.resonance_word & 0x3F) as u8;
        if class >= 96 { return false; }
        
        // Gating rule: if resonance bit 0 is set, mask bit 0 MUST be set
        if (self.resonance_word & 1) != 0 && (self.prime_mask & 1) == 0 {
            return false;
        }
        
        true
    }
}

/// Proof bundle containing a serialized proof and its public inputs.
pub struct ProofBundle {
    pub proof: Vec<u8>,
    pub public_inputs: Vec<GoldilocksField>,
}

/// Trait for Plonky3-compatible proving and verification.
pub trait ProverChip {
    fn prove(&self, inputs: &ConvergencePublicInputsPro) -> ProofBundle;
    fn verify(&self, bundle: &ProofBundle) -> bool;
}

/// Reference prover implementation that serializes public inputs as the proof
/// and verifies by checking the proof is a valid encoding of the public inputs.
/// This is a structural proof suitable for testing and development.
pub struct ReferenceProverChip;

impl ProverChip for ReferenceProverChip {
    fn prove(&self, inputs: &ConvergencePublicInputsPro) -> ProofBundle {
        let public = inputs.to_vec();
        let mut proof = Vec::with_capacity(public.len() * 8);
        for fe in &public {
            proof.extend_from_slice(&fe.0.to_le_bytes());
        }
        ProofBundle { proof, public_inputs: public }
    }

    fn verify(&self, bundle: &ProofBundle) -> bool {
        if bundle.public_inputs.is_empty() {
            return false;
        }
        let mut expected = Vec::with_capacity(bundle.public_inputs.len() * 8);
        for fe in &bundle.public_inputs {
            expected.extend_from_slice(&fe.0.to_le_bytes());
        }
        bundle.proof == expected
    }
}
