//! Security, fail-safe, and rollback protocols for Meta-Relativity.
//!
//! Based on ADR-096: Meta-Relativity — Security, Fail-Safe, and Rollback Protocols.

use anyhow::{Result, anyhow};

/// Security Context for MR-certified artifacts.
pub struct SecurityContext<T> {
    pub golden_set: Vec<T>,
    pub whitelist: Vec<String>,
}

impl<T: Clone> SecurityContext<T> {
    pub fn new(golden_set: Vec<T>, whitelist: Vec<String>) -> Self {
        Self { golden_set, whitelist }
    }

    /// Triggers a rollback to the last known-good state.
    pub fn rollback(&self) -> Result<T> {
        self.golden_set
            .last()
            .cloned()
            .ok_or(anyhow!("No golden set available for rollback"))
    }
}

/// Simple check for forbidden patterns in dynamic code (stub).
pub fn is_dynamic_code_present(code_str: &str) -> bool {
    let forbidden_patterns = ["eval(", "exec(", "import", "os.system", "subprocess"];
    forbidden_patterns.iter().any(|&pat| code_str.contains(pat))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rollback() {
        let golden_set = vec!["State1".to_string(), "State2".to_string()];
        let whitelist = vec!["Op1".to_string()];
        let context = SecurityContext::new(golden_set, whitelist);
        
        assert_eq!(context.rollback().unwrap(), "State2");
    }

    #[test]
    fn test_security_check() {
        assert!(is_dynamic_code_present("eval(x)"));
        assert!(!is_dynamic_code_present("x + 1"));
    }
}
