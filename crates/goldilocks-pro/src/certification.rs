use crate::{GoldilocksField, ConvergencePublicInputsPro};

/// Lever 5 — Spectral Witness (Normative)
/// Preserves the full spectral evidence required for Tier 4 recovery.
#[derive(Debug, Clone, PartialEq)]
pub struct SpectralWitness {
    /// Scalar gap to the GUE floor.
    pub delta_pz: GoldilocksField,
    
    /// Full array of nearest-neighbor spacings.
    /// MUST be preserved for Tier 4 Kolmogorov-Smirnov checks.
    pub zero_spacings: Vec<GoldilocksField>,
    
    /// Trend of the spectral gap (positive = widening).
    pub gap_trend: i64,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CertificationStatus {
    PASS,
    CONDITIONAL,
    VETO,
    PROVISIONAL,
}

/// Formal Stability Certificate (Lever 5)
#[derive(Debug, Clone, PartialEq)]
pub struct FormalStabilityCertificate {
    pub status: CertificationStatus,
    pub spectral: Option<SpectralWitness>,
    pub rho_bound: GoldilocksField,
    pub lambda_m: GoldilocksField,
    pub epoch: u64,
}

impl FormalStabilityCertificate {
    pub fn new(status: CertificationStatus, rho_bound: GoldilocksField, lambda_m: GoldilocksField) -> Self {
        Self {
            status,
            spectral: None,
            rho_bound,
            lambda_m,
            epoch: 0,
        }
    }

    /// spectral_healthy: Basic L1 health check based on delta_pz.
    pub fn spectral_healthy(&self, floor: GoldilocksField) -> bool {
        if let Some(ref witness) = self.spectral {
            witness.delta_pz.0 >= floor.0
        } else {
            false
        }
    }

    /// tier4_recovery_check: Lever 5 recovery logic.
    /// Uses the full zero_spacings array to determine if a sub-floor gap is recoverable.
    pub fn tier4_recovery_check(&self) -> CertificationStatus {
        if let Some(ref witness) = self.spectral {
            // Placeholder for KS-test logic against GUE distribution
            let is_gue_like = !witness.zero_spacings.is_empty();
            let is_trending_up = witness.gap_trend >= 0;
            
            if is_gue_like && is_trending_up {
                CertificationStatus::CONDITIONAL
            } else {
                CertificationStatus::VETO
            }
        } else {
            CertificationStatus::VETO
        }
    }

    pub fn export_proof_inputs(&self) -> ConvergencePublicInputsPro {
        let (mask, resonance_word) = if self.spectral.is_some() {
            // Simulated bundle extraction
            (crate::PrimeMask(0xFFFFFFFF), crate::ResonanceWord(42))
        } else {
            (crate::PrimeMask::EMPTY, crate::ResonanceWord(0))
        };

        ConvergencePublicInputsPro {
            prime_mask: mask,
            resonance_word,
            delta_pz: self.spectral.as_ref().map(|w| w.delta_pz).unwrap_or(GoldilocksField::ZERO),
            rho_bound: self.rho_bound,
            lambda_m: self.lambda_m,
            veto_flag: if self.status == CertificationStatus::VETO { GoldilocksField(1) } else { GoldilocksField(0) },
        }
    }
}
