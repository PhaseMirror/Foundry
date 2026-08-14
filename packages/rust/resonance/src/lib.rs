pub mod ccre;
pub mod crmf;
pub mod mcrm;

pub use ccre::*;
pub use crmf::*;
pub use mcrm::*;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ccre_resonance_guard() {
        assert!(ccre::check_resonance_guard(0.5, &ccre::PilotConfig {
            drift_threshold: 0.3,
            resonance_min: 0.1,
            resonance_max: 0.9,
        }));
    }

    #[test]
    fn test_issue_certificate() {
        let cert = crmf::certify(0.5, 0.5, 0.5, 0.5);
        assert_eq!(cert.status, "PASS");
        assert!(!cert.proof_hash.is_empty());
    }
}
