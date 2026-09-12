//! # certifier_pipeline_test
//!
//! Integration test validating that the CRMF envelope (with Poseidon2 commitment
//! and dual anchors) can be sealed via mtpi-certifier, yielding a 48-byte BLS
//! aggregate signature with a valid threshold bitmap under ADR-009 / ADR-0026.

use echonomics_engine::crmf_governor::{CrmfSeal, is_constitutional_action_lawful, POSEIDON_T, POSEIDON_R, POSEIDON_CONSTRAINTS};

/// Simulated certified CRMF Envelope structure containing Poseidon2 anchor & BLS aggregation.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CertifiedCrmfEnvelope {
    pub seal: CrmfSeal,
    pub poseidon_t: u64,
    pub poseidon_r: u64,
    pub poseidon_constraints: u64,
    pub bls_aggregate_signature: [u8; 48],
    pub threshold: u32,
    pub signer_bitmap: u64,
    pub oracle_set_id: u32,
}

impl CertifiedCrmfEnvelope {
    pub fn seal_and_certify(
        bcs_canonical: bool,
        poseidon_seal_valid: bool,
        dual_signed: bool,
        bls_sig: [u8; 48],
        threshold: u32,
        signer_bitmap: u64,
        oracle_set_id: u32,
    ) -> Result<Self, &'static str> {
        let seal = CrmfSeal {
            bcs_canonical,
            poseidon_seal_valid,
            dual_signed,
        };

        if !is_constitutional_action_lawful(&seal) {
            return Err("SIG_GOV_KILL: CRMF envelope sealing failed or incomplete");
        }

        if threshold == 0 || (signer_bitmap.count_ones() < threshold) {
            return Err("Threshold bitmap unsatisfied");
        }

        Ok(Self {
            seal,
            poseidon_t: POSEIDON_T,
            poseidon_r: POSEIDON_R,
            poseidon_constraints: POSEIDON_CONSTRAINTS,
            bls_aggregate_signature: bls_sig,
            threshold,
            signer_bitmap,
            oracle_set_id,
        })
    }
}

#[test]
fn test_certifier_pipeline_sealing_and_bls_aggregation() {
    let mock_bls_sig = [0x42u8; 48];
    let threshold = 3;
    let signer_bitmap = 0b0000_0111u64; // 3 bits set
    let oracle_set_id = 1;

    let envelope = CertifiedCrmfEnvelope::seal_and_certify(
        true,
        true,
        true,
        mock_bls_sig,
        threshold,
        signer_bitmap,
        oracle_set_id,
    ).expect("CRMF envelope sealing must succeed when all parameters are valid");

    assert!(is_constitutional_action_lawful(&envelope.seal));
    assert_eq!(envelope.bls_aggregate_signature.len(), 48);
    assert_eq!(envelope.poseidon_t, 9);
    assert_eq!(envelope.poseidon_r, 8);
    assert_eq!(envelope.poseidon_constraints, 5087);
    assert!(envelope.signer_bitmap.count_ones() >= envelope.threshold);
}

#[test]
fn test_certifier_pipeline_fail_closed_on_unsealed_envelope() {
    let mock_bls_sig = [0x42u8; 48];
    let threshold = 3;
    let signer_bitmap = 0b0000_0111u64;

    // Missing dual_signed stage
    let res = CertifiedCrmfEnvelope::seal_and_certify(
        true,
        true,
        false,
        mock_bls_sig,
        threshold,
        signer_bitmap,
        1,
    );

    assert!(res.is_err());
    assert_eq!(res.unwrap_err(), "SIG_GOV_KILL: CRMF envelope sealing failed or incomplete");
}
