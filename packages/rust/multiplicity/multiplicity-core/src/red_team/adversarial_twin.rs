use super::ModificationProposal;
use sha2::{Digest, Sha256};

/// Runs the adversarial twin check. Returns `true` if the proposal is rejected.
pub fn run(proposal: &ModificationProposal) -> bool {
    // Compute a deterministic hash of the proposal details.
    let mut hasher = Sha256::new();
    hasher.update(proposal.details.as_bytes());
    let hash = hasher.finalize();
    // Invert the bits to model the sign‑inverted mirror kernel.
    let inverted: Vec<u8> = hash.iter().map(|b| !b).collect();
    // Simple rejection rule: if the least‑significant bit of the first inverted byte is set,
    // consider the proposal unsafe.
    inverted[0] & 1 == 1
}
