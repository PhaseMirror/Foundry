//! CRMF-anchored audit chain for the Λ^p-Archivum.
//!
//! This is *not* a legacy WORM (write-once-read-many) file ledger. Records are
//! chained CRMF-sealed witnesses: every append binds the new witness to the
//! preceding record's state hash (`previous_hash` linkage), and the chain root
//! is recomputed from the chained structure. Replaying a state hash is
//! rejected, and any mutation of a past witness is detected by re-deriving
//! the chain (`verify_chain`).
//!
//! ADR-0067 formal invariants (proved in `ADR/Archivum.lean`):
//! - **Append-only preservation:** `∀ w', w' ∈ L -> w' ∈ L'`
//! - **Tamper evidence:** any past record mutation invalidates the chain
//! - **Witness uniqueness:** duplicate state hashes are deterministically rejected

use serde::{Deserialize, Serialize};
#[cfg(not(kani))]
use blake3::Hasher;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum ArchivumError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),
    #[error("Validation error: {0}")]
    Validation(String),
    #[error("Duplicate witness: {state_hash}")]
    DuplicateWitness { state_hash: String },
    #[error("Chain integrity violation")]
    ChainViolation,
    #[error("Domain tag mismatch: sealed {sealed} vs store {store}")]
    DomainTagMismatch { sealed: String, store: String },
}

/// A CRMF-anchored witness record.
///
/// The `state_hash` is the anchor hash of the sealed record (CRMF
/// `DualAnchor::sha256_hex`), and `previous_hash` links this record to the
/// immediately preceding witness in the chain.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Witness {
    pub state_hash: String,
    pub event_type: String,
    pub timestamp: i64,
    pub commit_hash: Option<String>,
    pub previous_hash: Option<String>,
}

/// Append-only hash-linked audit chain.
///
/// `witnesses` is the ordered chain; `root_hash` is the recomputed chain commit.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ArchivumLedger {
    pub witnesses: Vec<Witness>,
    pub root_hash: [u8; 32],
}

impl Default for ArchivumLedger {
    fn default() -> Self {
        Self::new()
    }
}

impl ArchivumLedger {
    pub fn new() -> Self {
        Self {
            witnesses: Vec::new(),
            root_hash: [0u8; 32],
        }
    }

    /// The state hash of the trailing witness, if the chain is non-empty.
    fn head_hash(&self) -> Option<String> {
        self.witnesses.last().map(|w| w.state_hash.clone())
    }

    /// Whether consecutive witnesses are hash-linked
    /// (`w[i+1].previous_hash == Some(w[i].state_hash)`).
    pub fn is_linked(&self) -> bool {
        self.witnesses.windows(2).all(|pair| {
            pair[1].previous_hash.is_some() && pair[1].previous_hash == Some(pair[0].state_hash.clone())
        })
    }

    /// Append a witness, enforcing witness uniqueness and prev-hash linkage.
    ///
    /// If the witness carries no explicit `previous_hash`, it is bound to the
    /// current head of the chain (append semantics). Duplicate `state_hash`
    /// values are deterministically rejected (witness uniqueness).
    pub fn append(&mut self, mut w: Witness) -> Result<[u8; 32], ArchivumError> {
        if self.witnesses.iter().any(|x| x.state_hash == w.state_hash) {
            return Err(ArchivumError::DuplicateWitness {
                state_hash: w.state_hash,
            });
        }
        if w.previous_hash.is_none() {
            w.previous_hash = self.head_hash();
        }
        self.witnesses.push(w);
        self.root_hash = self.compute_root_hash();
        Ok(self.root_hash)
    }

    /// Recompute the chain root and validate linkage: `true` exactly when the
    /// stored chain has not been mutated (tamper evidence).
    pub fn verify_chain(&self) -> bool {
        self.is_linked() && self.root_hash == self.compute_root_hash()
    }

    pub fn root_hash(&self) -> [u8; 32] {
        self.root_hash
    }

    /// The pure chain-commit function: a deterministic digest over the ordered,
    /// hash-linked witness sequence (real Blake3 build, XOR mirror under Kani).
    #[cfg(not(kani))]
    pub fn compute_root_hash(&self) -> [u8; 32] {
        let mut hasher = Hasher::new();
        for w in &self.witnesses {
            let mut buf = w.state_hash.as_bytes().to_vec();
            if let Some(prev) = &w.previous_hash {
                buf.push(0x01);
                buf.extend_from_slice(prev.as_bytes());
            } else {
                buf.push(0x00);
            }
            hasher.update(&buf);
        }
        *hasher.finalize().as_bytes()
    }

    #[cfg(kani)]
    pub fn compute_root_hash(&self) -> [u8; 32] {
        let mut hash = [0u8; 32];
        let witnesses = &self.witnesses;
        let mut j = 0;
        while j < witnesses.len() {
            let bytes = witnesses[j].state_hash.as_bytes();
            let mut prev: &[u8] = &[];
            if let Some(p) = &witnesses[j].previous_hash {
                prev = p.as_bytes();
            }
            let mut i = 0;
            while i < bytes.len() {
                hash[i % 32] ^= bytes[i];
                i += 1;
            }
            let mut k = 0;
            while k < prev.len() {
                hash[k % 32] ^= prev[k];
                k += 1;
            }
            hash[j % 32] ^= if witnesses[j].previous_hash.is_some() { 1 } else { 0 };
            j += 1;
        }
        hash
    }

    #[cfg(not(kani))]
    pub fn produce_tee_quote(&self) -> Result<String, ArchivumError> {
        let root = self.root_hash();
        let quote = format!("TEE-QUOTE-LAMBDA-TRACE-{:?}", root);
        Ok(quote)
    }

    #[cfg(kani)]
    pub fn produce_tee_quote(&self) -> Result<String, ArchivumError> {
        let root = self.root_hash();
        let mut quote = String::from("TEE-QUOTE-LAMBDA-TRACE-");
        for &b in &root {
            quote.push(b as char);
        }
        Ok(quote)
    }

    pub fn stamp_sigma_proof(&mut self, proof: &crate::proofs::SigmaProof) -> Result<(), ArchivumError> {
        let w = Witness {
            state_hash: proof.state_hash.clone(),
            event_type: "SigmaProof".into(),
            timestamp: 0,
            commit_hash: Some(proof.state_hash.clone()),
            previous_hash: None,
        };
        self.append(w)?;
        Ok(())
    }

    pub fn append_block(&mut self, block: &crate::proofs::TransitionBlock) -> Result<(), ArchivumError> {
        let w = Witness {
            state_hash: block.transition_id.clone(),
            event_type: "TransitionBlock".into(),
            timestamp: 0,
            commit_hash: Some(block.transition_id.clone()),
            previous_hash: None,
        };
        self.append(w)?;
        Ok(())
    }

    pub fn stamp_pweh(&mut self, log: &crate::proofs::ConflictLogSchema) -> Result<(), ArchivumError> {
        let w = Witness {
            state_hash: log.receipt_hash.clone(),
            event_type: "ConflictLog".into(),
            timestamp: 0,
            commit_hash: Some(log.receipt_hash.clone()),
            previous_hash: None,
        };
        self.append(w)?;
        Ok(())
    }
}

// ---------------------------------------------------------------------------
// Pure chain-integrity core (Kani-verifiable)
// ---------------------------------------------------------------------------
//
// `ChainLink` mirrors a `Witness` using only primitives so that the chain
// invariants (append-only preservation, tamper evidence, witness uniqueness,
// chain re-derivation) are bounded-model-checkable. `ArchivumLedger` is the
// String-based production wrapper over the same logic; `chain_root` /
// `verify_core` here are the reference semantics the Kani harnesses check.

/// Hash-linked chain element (primitive mirror of `Witness`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ChainLink {
    pub state_hash: u64,
    pub previous: Option<u64>,
    pub is_sealed: bool,
}

/// Alloc-free error for the pure chain core (Kani-verifiable).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ChainError {
    Duplicate,
    Capacity,
}

/// Deterministic chain-root commitment over an ordered sequence of links.
/// Pure function with no allocation; mirrors the Blake3/XOR schemes above.
pub fn chain_root(links: &[ChainLink]) -> [u8; 32] {
    let mut hash = [0u8; 32];
    let n = links.len();
    let mut j = 0;
    while j < n {
        let l = links[j];
        let mut h = l.state_hash;
        let base = (j * 8) % 32;
        let mut i = 0;
        while i < 8 {
            let idx = (base + i) % 32;
            hash[idx] ^= (h & 0xff) as u8;
            h >>= 8;
            i += 1;
        }
        if let Some(p) = l.previous {
            let mut ph = p;
            let base2 = (base + 4) % 32;
            let mut k = 0;
            while k < 8 {
                let idx = (base2 + k) % 32;
                hash[idx] ^= (ph & 0xff) as u8;
                ph >>= 8;
                k += 1;
            }
        }
        if l.is_sealed {
            hash[j % 32] ^= 1;
        }
        j += 1;
    }
    hash
}

/// Linkage predicate: every consecutive pair is hash-linked (next.previous ==
/// previous.state_hash).
pub fn is_linked_core(links: &[ChainLink]) -> bool {
    let n = links.len();
    if n < 2 {
        return true;
    }
    let mut j = 1;
    while j < n {
        if links[j].previous != Some(links[j - 1].state_hash) {
            return false;
        }
        j += 1;
    }
    true
}

/// Chain validity: recomputed root matches the stored root and linkage holds.
/// Tamper evidence: any mutation of a stored link is detected here.
pub fn verify_core(links: &[ChainLink], stored_root: [u8; 32]) -> bool {
    is_linked_core(links) && stored_root == chain_root(links)
}

/// Append one link, enforcing witness uniqueness and prev-hash linkage.
///
/// This is the pure core that the production `Witness` wrapper adapts
/// (the wrapper `ArchivumLedger::append` maps `String` hashes and produces
/// `ArchivumError`). Returns the new chain root on success.
pub fn push_link(links: &mut Vec<ChainLink>, mut w: ChainLink) -> Result<[u8; 32], ChainError> {
    let n = links.len();
    let mut i = 0;
    while i < n {
        if links[i].state_hash == w.state_hash {
            return Err(ChainError::Duplicate);
        }
        i += 1;
    }
    if w.previous.is_none() {
        w.previous = if n == 0 { None } else { Some(links[n - 1].state_hash) };
    }
    links.push(w);
    Ok(chain_root(links))
}

/// Fixed-capacity, allocator-free chain for bounded-model checking.
///
/// `FixedChain` is the reference implementation of the chain-integrity core
/// (append-only preservation, uniqueness, linkage, root re-derivation). It
/// avoids heap allocation so Kani can verify the exact same structural
/// invariants as `ArchivumLedger` without modeling the allocator.
pub const MAX_LINKS: usize = 8;

/// A fixed-capacity hash-linked chain.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct FixedChain {
    links: [ChainLink; MAX_LINKS],
    len: usize,
}

impl FixedChain {
    pub const fn new() -> Self {
        Self {
            links: [ChainLink {
                state_hash: 0,
                previous: None,
                is_sealed: false,
            }; MAX_LINKS],
            len: 0,
        }
    }

    pub fn len(&self) -> usize {
        self.len
    }

    pub fn is_empty(&self) -> bool {
        self.len == 0
    }

    /// Deterministic chain root over the current portion of the chain.
    pub fn chain_root(&self) -> [u8; 32] {
        chain_root_fixed(&self.links, self.len)
    }

    pub fn is_linked(&self) -> bool {
        if self.len < 2 {
            return true;
        }
        let mut j = 1;
        while j < self.len {
            if self.links[j].previous != Some(self.links[j - 1].state_hash) {
                return false;
            }
            j += 1;
        }
        true
    }

    /// Chain validity: recomputed root matches the stored root and linkage.
    pub fn verify(&self, stored_root: [u8; 32]) -> bool {
        self.is_linked() && stored_root == self.chain_root()
    }

    /// Append a link (uniqueness enforced; auto-prev linkage; capacity bounded).
    pub fn push(&mut self, mut w: ChainLink) -> Result<[u8; 32], ChainError> {
        if self.len >= MAX_LINKS {
            return Err(ChainError::Capacity);
        }
        let mut i = 0;
        while i < self.len {
            if self.links[i].state_hash == w.state_hash {
                return Err(ChainError::Duplicate);
            }
            i += 1;
        }
        if w.previous.is_none() {
            w.previous = if self.len == 0 { None } else { Some(self.links[self.len - 1].state_hash) };
        }
        self.links[self.len] = w;
        self.len += 1;
        Ok(self.chain_root())
    }
}

/// Index-based root commitment over the first `len` entries of `links`.
pub fn chain_root_fixed(links: &[ChainLink; MAX_LINKS], len: usize) -> [u8; 32] {
    let mut hash = [0u8; 32];
    let mut j = 0;
    while j < len {
        let l = links[j];
        let mut h = l.state_hash;
        let base = (j * 8) % 32;
        let mut i = 0;
        while i < 8 {
            hash[(base + i) % 32] ^= (h & 0xff) as u8;
            h >>= 8;
            i += 1;
        }
        if let Some(p) = l.previous {
            let mut ph = p;
            let base2 = (base + 4) % 32;
            let mut k = 0;
            while k < 8 {
                hash[(base2 + k) % 32] ^= (ph & 0xff) as u8;
                ph >>= 8;
                k += 1;
            }
        }
        if l.is_sealed {
            hash[j % 32] ^= 1;
        }
        j += 1;
    }
    hash
}

pub const fn chain_link(state_hash: u64, previous: Option<u64>, is_sealed: bool) -> ChainLink {
    ChainLink {
        state_hash,
        previous,
        is_sealed,
    }
}

// ---------------------------------------------------------------------------
// `Compatible()` domain-tag gate (ADR-0067 §"Step A: The Compatible() Domain
// Tag Check"). Fail-closed: a tag mismatch blocks ingestion.
// ---------------------------------------------------------------------------

/// `Compatible():` a sealed record's domain tag is accepted by the store
/// exactly when it matches the store's declared domain.
pub fn compatible(sealed_domain_tag: &str, store_domain: &str) -> bool {
    sealed_domain_tag == store_domain
}

impl ArchivumLedger {
    /// Admit a CRMF-sealed witness only when its domain tag is `Compatible()`
    /// with the store domain. On mismatch the append fails closed.
    pub fn append_compatible(
        &mut self,
        w: Witness,
        sealed_domain_tag: &str,
        store_domain: &str,
    ) -> Result<[u8; 32], ArchivumError> {
        if !compatible(sealed_domain_tag, store_domain) {
            return Err(ArchivumError::DomainTagMismatch {
                sealed: sealed_domain_tag.to_string(),
                store: store_domain.to_string(),
            });
        }
        self.append(w)
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    #[kani::unwind(64)]
    fn proof_compatible_gate_fail_closed() {
        // The `Compatible()` gate must never admit a mismatched domain tag
        // and must always admit an exact match. (Tags are concrete literals
        // here; the symbolic equivalence `admit == (sealed == store)` mirrors
        // the gate's definition and is proved in Lean in `ADR/Archivum.lean`.)
        assert!(!compatible("crmf-domain", "archivum-domain"));
        assert!(compatible("archivum-domain", "archivum-domain"));
    }

    #[kani::proof]
    #[kani::unwind(64)]
    fn proof_append_only_and_chain_integrity() {
        let mut chain = FixedChain::new();
        let w = chain_link(0x1111, None, true);
        let root_before = chain.chain_root();
        let res = chain.push(w);
        assert!(res.is_ok(), "append must succeed on empty chain");
        let root_after = res.unwrap();
        assert!(root_before != root_after, "root changes on append");
        assert!(chain.verify(root_after), "fresh chain must verify");
        assert!(chain.is_linked(), "singleton chain is linked");

        let res2 = chain.push(w);
        assert!(res2.is_err(), "duplicate witness must be rejected");
        assert!(chain.verify(root_after), "no mutation after rejected append");
    }

    #[kani::proof]
    #[kani::unwind(64)]
    fn proof_append_preserves_existing_witnesses() {
        let mut chain = FixedChain::new();
        let w1 = chain_link(0x2222, None, true);
        let w2 = chain_link(0x3333, None, false);
        chain.push(w1).unwrap();
        chain.push(w2).unwrap();
        assert!(chain.len() == 2);
        // Append-only preservation: prior elements are still present (only the
        // new element's prev-link is bound to the preceding state hash).
        assert!(chain.links[0].state_hash == w1.state_hash);
        assert!(chain.links[1].state_hash == w2.state_hash);
        assert!(chain.links[1].previous == Some(w1.state_hash));
    }

    #[kani::proof]
    #[kani::unwind(64)]
    fn proof_chain_root_changes_on_append() {
        let mut chain = FixedChain::new();
        let w1 = chain_link(0x4444, None, true);
        let w2 = chain_link(0x5555, None, false);
        let r1 = chain.push(w1).unwrap();
        let r2 = chain.push(w2).unwrap();
        assert!(r1 != r2, "root must change on each append");
        assert!(chain.is_linked(), "chained appends remain linked");
        assert!(chain.verify(r2), "chain remains verifiable");
    }

    #[kani::proof]
    #[kani::unwind(64)]
    fn proof_tamper_detection() {
        let mut chain = FixedChain::new();
        let w1 = chain_link(0x6666, None, true);
        let w2 = chain_link(0x7777, None, true);
        chain.push(w1).unwrap();
        let root = chain.push(w2).unwrap();
        assert!(chain.verify(root));

        // Tamper the trailing record: linkage still holds (no successor), so
        // evidence of tampering must come from root re-derivation alone.
        chain.links[1].state_hash = 0x7777 ^ 0xFFFF;
        assert!(chain.is_linked(), "linkage survives a payload tamper");
        assert!(!chain.verify(root), "tamper must be detected by recomputation");
    }

    #[kani::proof]
    #[kani::unwind(64)]
    fn proof_tamper_detection_breakage_of_linkage() {
        let mut chain = FixedChain::new();
        let w1 = chain_link(0x8888, None, true);
        let w2 = chain_link(0x9999, None, true);
        chain.push(w1).unwrap();
        let root = chain.push(w2).unwrap();
        assert!(chain.verify(root));

        // Tamper an interior record: the successor's prev-link now points at a
        // different state hash, so linkage itself is broken.
        chain.links[0].state_hash = 0x8888 ^ 0xFFFF;
        assert!(!chain.is_linked(), "interior tamper breaks linkage");
        assert!(!chain.verify(root), "tamper must be detected");
    }

    #[kani::proof]
    #[kani::unwind(64)]
    fn proof_witness_uniqueness_any_hash() {
        let mut chain = FixedChain::new();
        // Symbolic hashes: replay of ANY state hash is rejected because the
        // chain no longer contains it after a failed (rejected) append.
        let a: u64 = kani::any();
        chain.push(chain_link(a, None, true)).unwrap();
        let root = chain.chain_root();
        assert!(chain.push(chain_link(a, None, true)).is_err());
        assert!(chain.verify(root), "rejected append cannot mutate the chain");
    }
}