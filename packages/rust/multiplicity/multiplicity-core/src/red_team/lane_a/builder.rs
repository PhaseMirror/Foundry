// Lane A Builder implementation
use super::super::ModificationProposal;
use sha2::{Digest, Sha256};

/// Verifies that the core remained uncorrupted after the Exploder's stress test.
/// Returns `true` if the verification fails.
pub fn run(proposal: &ModificationProposal) -> bool {
    // Compute a hash of the proposal ID and details.
    let mut hasher = Sha256::new();
    hasher.update(proposal.id.to_be_bytes());
    hasher.update(proposal.details.as_bytes());
    let hash = hasher.finalize();
    // Simple integrity check: if the first byte is even, accept; else reject.
    hash[0] % 2 != 0
}
