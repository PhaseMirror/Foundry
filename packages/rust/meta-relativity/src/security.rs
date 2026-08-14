//! Security, fail-safe, and rollback protocols for Meta-Relativity.
//!
//! Based on ADR-096: Meta-Relativity — Security, Fail-Safe, and Rollback Protocols.

use anyhow::{anyhow, Result};

/// Security Context for MR-certified artifacts.
pub struct SecurityContext<T> {
    pub golden_set: Vec<T>,
    pub whitelist: Vec<String>,
}

impl<T: Clone> SecurityContext<T> {
    pub fn new(golden_set: Vec<T>, whitelist: Vec<String>) -> Self {
        Self {
            golden_set,
            whitelist,
        }
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

/// Symbolic verification for rollback safety.
#[cfg(kani)]
mod verification {
    use super::*;

    /// Symbolic proof: rollback on a non-empty golden set always returns Ok.
    #[kani::proof]
    fn proof_rollback_safe() {
        let n: usize = kani::any();
        kani::assume(n >= 1 && n <= 8);

        let mut golden_set: Vec<u64> = Vec::new();
        for _ in 0..n {
            golden_set.push(kani::any());
        }

        let ctx = SecurityContext::new(golden_set, vec![]);
        let result = ctx.rollback();
        kani::assert(result.is_ok(), "rollback on non-empty golden set returns Ok");
    }

    /// Symbolic proof: rollback returns the last element of golden_set.
    #[kani::proof]
    fn proof_rollback_returns_last() {
        let n: usize = kani::any();
        kani::assume(n >= 1 && n <= 8);

        let mut golden_set: Vec<u64> = Vec::new();
        for _ in 0..n {
            golden_set.push(kani::any());
        }

        let last_val = *golden_set.last().unwrap();
        let ctx = SecurityContext::new(golden_set, vec![]);
        let result = ctx.rollback().unwrap();
        kani::assert(result == last_val, "rollback returns last golden-set value");
    }

    /// Symbolic proof: rollback on empty golden set returns Err.
    #[kani::proof]
    fn proof_rollback_empty_is_err() {
        let ctx: SecurityContext<u64> = SecurityContext::new(vec![], vec![]);
        let result = ctx.rollback();
        kani::assert(result.is_err(), "rollback on empty golden set returns Err");
    }

    /// Symbolic proof: is_dynamic_code_present catches eval().
    #[kani::proof]
    fn proof_dynamic_code_detection() {
        let s: &str = kani::any();
        let patterns = ["eval(", "exec(", "import", "os.system", "subprocess"];
        for pat in patterns {
            if s.contains(pat) {
                kani::assert(is_dynamic_code_present(s), "detects forbidden pattern");
            }
        }
    }
}
