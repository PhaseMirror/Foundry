//! Free-Type Signatures (FTS) & Type Conservation Engine

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::BTreeMap;

/// Free-Type Signature mapping named logic atom names to integer exponent weights.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct FreeTypeSignature {
    pub weights: BTreeMap<String, i64>,
}

impl FreeTypeSignature {
    pub fn new() -> Self {
        Self {
            weights: BTreeMap::new(),
        }
    }

    pub fn from_atom(atom: &str, weight: i64) -> Self {
        let mut map = BTreeMap::new();
        if weight != 0 {
            map.insert(atom.to_string(), weight);
        }
        Self { weights: map }
    }

    /// Additive composition of signatures: σ(T ⊗ S) = σ(T) + σ(S).
    pub fn add(&self, other: &Self) -> Self {
        let mut result = self.weights.clone();
        for (atom, &w) in &other.weights {
            let entry = result.entry(atom.clone()).or_insert(0);
            *entry += w;
        }
        // Purge zero weights for canonical form
        result.retain(|_, &mut v| v != 0);
        Self { weights: result }
    }

    /// Check signature conservation: σ_in + σ_param == σ_out.
    pub fn verify_conservation(sig_in: &Self, sig_param: &Self, sig_out: &Self) -> bool {
        let combined = sig_in.add(sig_param);
        &combined == sig_out
    }

    /// Compute canonical prime-based signature digest.
    pub fn compute_digest(&self) -> String {
        let mut hasher = Sha256::new();
        for (atom, weight) in &self.weights {
            hasher.update(atom.as_bytes());
            hasher.update(&weight.to_le_bytes());
        }
        hex::encode(hasher.finalize())
    }
}
