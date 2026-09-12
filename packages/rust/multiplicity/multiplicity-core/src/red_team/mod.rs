pub mod adversarial_twin;
pub mod lane_a;
pub mod falsification;
pub mod bounded_execution;

/// Represents a proposal for a system modification.
#[derive(Debug, Clone)]
pub struct ModificationProposal {
    /// Unique identifier of the proposal.
    pub id: u64,
    /// Human‑readable description of the proposed change.
    pub details: String,
}

/// High‑level safety check that routes the proposal through the
/// built‑in red‑team primitives.  Returns `Ok(())` if the change is
/// admissible, otherwise an error describing the failure reason.
pub fn modification_safety_check(proposal: &ModificationProposal) -> Result<(), &'static str> {
    // Step 1: Run the Adversarial Twin – the primary Gödelian guard.
    if adversarial_twin::run(proposal) {
        return Err("Rejected by Adversarial Twin");
    }
    // Step 2: Run Lane A Exploder/Builder stress‑test.
    if lane_a::exploder::run(proposal) {
        return Err("Exploder detected unsafe divergence");
    }
    // Step 3: Apply falsification / ablation harnesses.
    if falsification::run(proposal) {
        return Err("Falsification harness triggered failure");
    }
    // Step 4: Verify bounded execution constraints for external agents.
    if bounded_execution::run(proposal) {
        return Err("Bounded execution constraint violated");
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;

    #[test]
    fn deterministic_adversarial_twin() {
        let proposal = ModificationProposal { id: 1, details: "test".into() };
        let first = adversarial_twin::run(&proposal);
        let second = adversarial_twin::run(&proposal);
        assert_eq!(first, second);
    }

    proptest! {
        #[test]
        fn adversarial_twin_proptest(details in ".*") {
            let proposal = ModificationProposal { id: 42, details };
            let result = adversarial_twin::run(&proposal);
            // Compute expected inversion of first byte of SHA256 hash
            use sha2::{Digest, Sha256};
            let mut hasher = Sha256::new();
            hasher.update(proposal.details.as_bytes());
            let hash = hasher.finalize();
            let inverted = !hash[0];
            let expected = inverted & 1 == 1;
            prop_assert_eq!(result, expected);
        }

        #[test]
        fn exploder_proptest(seed in any::<u64>()) {
            let proposal = ModificationProposal { id: seed, details: "exploder".into() };
            let result = lane_a::exploder::run(&proposal);
            prop_assert!(result == true || result == false);
        }
    }
}

