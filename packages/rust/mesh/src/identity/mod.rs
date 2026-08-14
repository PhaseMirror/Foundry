pub mod agent_id;
pub use agent_id::{PrivilegeRing, AgentIdentity, AgentDID};
pub mod credentials;
pub mod mtls;
pub mod risk;
pub mod delegation;
pub mod rotation;
pub mod keystore;
pub mod keystore_http;
pub mod registry;
pub mod registry_http;
pub mod attestation;
pub mod escalation;
pub use escalation::{EscalationRequest, EscalationEvent, EscalationOutcome, approval_payload};

#[cfg(test)]
mod tests {
    use super::*;
}
