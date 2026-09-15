//! End-to-end ensemble manifest lifecycle (ADR-0066 §"The Ensemble Manifest
//! Structure"), exercised from the crate's public boundary: provision →
//! compile → enter, including each veto path.

use pirtm_engine::ace::radius_scaled;
use pirtm_engine::manifest::{
    EnsembleError, PrismOperation, compile_manifest, default_spectral_limit,
};
use pirtm_engine::tensor::GainMatrix;

const UOR: [u8; 32] = [0xa5; 32];

#[test]
fn contractive_add_overlay_enters_and_verifies() {
    let manifest = compile_manifest(
        UOR,
        2,
        default_spectral_limit(),
        &[PrismOperation::Add; 3],
        400_000_000,
    )
    .expect("contractive Add overlay compiles");
    assert_eq!(manifest.verify_seal(), Ok(()));
    assert_eq!(manifest.prime_topology, 2);
    assert_eq!(manifest.multiplicity_signature, pirtm_engine::manifest::multiplicity_signature(&[2, 2, 2]));
}

#[test]
fn multiply_overlay_enters_for_multiply_chains() {
    let manifest = compile_manifest(
        UOR,
        3,
        default_spectral_limit(),
        &[PrismOperation::Multiply; 2],
        0,
    )
    .expect("Multiply overlay compiles for Multiply chains");
    assert_eq!(manifest.verify_seal(), Ok(()));
    assert_eq!(manifest.multiplicity_signature, pirtm_engine::manifest::multiplicity_signature(&[3, 3]));
}

/// ADR-0066 adversarial scenario: the upstream gain is expansive, so the
/// compiled artifact must be refused at the manifold entry — even from the
/// most wholesome operation chain.
#[test]
fn adversarial_gain_refuses_manifest_entry() {
    let mut psi = GainMatrix::new_2x2();
    psi.set_weights(1.0, 0.5, 0.5, 1.0);
    let radius = radius_scaled(&psi);
    assert!(radius >= default_spectral_limit(), "ρ=1.5 must trip the limit");

    let result = compile_manifest(
        UOR,
        2,
        default_spectral_limit(),
        &[PrismOperation::Add, PrismOperation::Add],
        radius,
    );
    assert_eq!(result, Err(EnsembleError::RadiusBreachesSpectralLimit));
}

#[test]
fn manifest_canonical_bytes_roundtrip_via_seal() {
    let manifest = compile_manifest(
        UOR,
        2,
        default_spectral_limit(),
        &[PrismOperation::Add; 4],
        100_000_000,
    )
    .expect("compiles");
    let bytes = manifest.to_canonical_bytes();
    assert_eq!(bytes.len(), 32 + 8 + 8 + 32 + 32);
    // The seal is reproducible from the core alone.
    assert_eq!(manifest.compute_seal(), manifest.crmf_seal);
}

#[test]
fn lane_crossing_into_wrong_overlay_is_vetoed() {
    let result = compile_manifest(
        UOR,
        2,
        default_spectral_limit(),
        &[PrismOperation::Add, PrismOperation::Multiply],
        0,
    );
    assert_eq!(result, Err(EnsembleError::LaneOutsideTopology(3)));
}