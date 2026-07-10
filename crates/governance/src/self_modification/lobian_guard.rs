use std::collections::HashSet;
use std::sync::LazyLock;
use crate::self_modification::proposal::ModificationProposal;
use thiserror::Error;

/// R-03: Löbian Guard — Verification Layer Protection.

pub static VERIFICATION_LAYER_PARAMETERS: LazyLock<HashSet<&'static str>> = LazyLock::new(|| {
    let mut s = HashSet::new();
    s.insert("contractivity_verifier");
    s.insert("spectral_enforcement_pass");
    s.insert("simulation_acceptance_criteria");
    s.insert("kill_switch_interface");
    s.insert("snapshot_integrity_algorithm");
    s
});

#[derive(Error, Debug)]
pub enum LobianGuardError {
    #[error("Proposal {0} targets verification layer parameter '{1}'. Modification of verification infrastructure is architecturally prohibited (Löbian guard).")]
    Violation(String, String),
}

pub fn check_lobian_guard(proposal: &ModificationProposal) -> bool {
    if let Some(delta_obj) = proposal.proposed_delta.as_object() {
        for key in delta_obj.keys() {
            if VERIFICATION_LAYER_PARAMETERS.contains(key.as_str()) {
                return false;
            }
        }
    }
    true
}

pub fn enforce_lobian_guard(proposal: &ModificationProposal) -> Result<(), LobianGuardError> {
    if let Some(delta_obj) = proposal.proposed_delta.as_object() {
        for key in delta_obj.keys() {
            if VERIFICATION_LAYER_PARAMETERS.contains(key.as_str()) {
                return Err(LobianGuardError::Violation(proposal.proposal_id.clone(), key.clone()));
            }
        }
    }
    Ok(())
}

pub fn is_verification_parameter(name: &str) -> bool {
    VERIFICATION_LAYER_PARAMETERS.contains(name)
}
