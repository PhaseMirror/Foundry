use std::collections::HashMap;
use serde::{Deserialize, Serialize};

/// A WORM Tick, matching the Lean 4 Jubilee specification.
pub type Tick = u64;

/// Cryptographic anchors (e.g. Dual signatures: SHA-256 + Ed25519)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CryptoAnchors {
    pub sha256_hash: [u8; 32],
    pub ed25519_sig: Vec<u8>,
}

/// The Morphism Record stored in the RegHom Registry.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MorphismRecord {
    /// Pre-verified Λ_m-stability certificate hash
    pub lam_certificate: [u8; 32],
    /// CRMF-integrated anchor for the higher-order RSL 6-language proof
    pub merkle_root: [u8; 32],
    /// Dual signatures proving ratification by Constitutional Quorum
    pub crypto_anchors: CryptoAnchors,
    /// Time-weaponized validity boundary, tied to the Jubilee window
    pub expiration_tick: Tick,
}

/// The RegHom Registry (Adaptive Immunity Clonal Selection).
/// Maps `(src_prime, tgt_prime)` to a `MorphismRecord`.
pub struct RegHomManager {
    registry: HashMap<(u32, u32), MorphismRecord>,
}

impl RegHomManager {
    /// Creates a new, empty RegHom registry.
    pub fn new() -> Self {
        Self {
            registry: HashMap::new(),
        }
    }

    /// O(1) lookup for a registered morphism.
    /// Returns `None` if the morphism is not registered or if it has expired.
    pub fn reg_hom_lookup(&self, src_prime: u32, tgt_prime: u32, current_tick: Tick) -> Option<&MorphismRecord> {
        if let Some(record) = self.registry.get(&(src_prime, tgt_prime)) {
            // Weaponized time check: ensure the morphism hasn't expired.
            // Stale pathways are naturally pruned.
            if current_tick <= record.expiration_tick {
                return Some(record);
            }
        }
        None
    }

    /// Insertion path for Governed Bridge Amendments.
    /// Note: The actual amendment packet must be validated (e.g., `jubilee_admissible`)
    /// and verified via the Lean 4 FFI before calling this function.
    pub fn insert_morphism(
        &mut self,
        src_prime: u32,
        tgt_prime: u32,
        record: MorphismRecord,
    ) {
        // Phase 2: FFI bridge allowing the Rust kernel to ingest verified .olean artifacts.
        if !crate::ffi::verify_lam_certificate(&record.lam_certificate) {
             panic!("Constitutional Reject: Invalid Lambda_m stability certificate.");
        }
        
        self.registry.insert((src_prime, tgt_prime), record);
    }
}
