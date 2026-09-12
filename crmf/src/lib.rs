// crmf/src/lib.rs
//! Core CRMF crate API

pub mod poseidon2;

use ark_bn254::Fr;
use num_rational::Ratio;
use crate::poseidon2::sponge;

/// Seal an event using the Poseidon2 BN254 sponge.
/// Returns a deterministic string identifier for the seal.
pub fn seal_event(phi: Ratio<i64>) -> String {
    // Map rational to field elements (simple deterministic mapping).
    let numer = Fr::from(phi.numer().abs() as u64);
    let denom = Fr::from(*phi.denom() as u64);
    let commitment = sponge(&[numer, denom]);
    format!("crmf_seal_bn254_{:?}", commitment)
}
