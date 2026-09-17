//! Transcript modules: SHA-256 per-sender hash chain (QKD v1.0.1 §1.4) and a
//! Keccak256 Fiat-Shamir transcript (ported from the existing
//! `multiplicity-crypto/rust/src/transcript.rs`).
//!
//! The SHA-256 hash chain follows the QKD v1.0.1 §1.4 rules:
//!
//! ```text
//! SID = SHA256(nonce_A || nonce_B)
//! H_A0 = SHA256(VERSION || SID || ALICE_LABEL)
//! H_B0 = SHA256(VERSION || SID || BOB_LABEL)
//! H_A(i+1) = SHA256(H_A(i) || m_A(i))
//! context_hash = SHA256(H_A_final || H_B_final)
//! ```

use sha2::{Digest, Sha256};

use crate::profile::MultiplicityProfile;
use sha3::Keccak256;

/// Role label: Alice (sender A) or Bob (sender B).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SenderRole {
    Alice,
    Bob,
}

impl SenderRole {
    const ALICE_LABEL: [u8; 8] = *b"ALICE\0\0\0";
    const BOB_LABEL: [u8; 8] = *b"BOB\0\0\0\0\0";
    const VERSION: u8 = 1;

    #[must_use]
    pub fn label(&self) -> &'static [u8; 8] {
        match self {
            Self::Alice => &Self::ALICE_LABEL,
            Self::Bob => &Self::BOB_LABEL,
        }
    }
}

/// Output of a hash-chain computation.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HashChainOutput {
    pub hash_chain: Vec<[u8; 32]>,
    pub context_hash: [u8; 32],
    pub final_prime_index: u32,
}

/// A per-sender SHA-256 hash chain, matching QKD v1.0.1 §1.4.
///
/// Initialize with [`HashChain::new`] for each sender, then call
/// [`HashChain::append`] for each message. The final [`HashChain::context_hash`]
/// is the SHA-256 of the two chains' terminal values.
#[derive(Debug, Clone)]
pub struct HashChain {
    role: SenderRole,
    sid: [u8; 32],
    current: Vec<u8>,
    chain: Vec<[u8; 32]>,
}

impl HashChain {
    /// Create a new chain for the given sender, with the session ID `sid`.
    #[must_use]
    pub fn new(role: SenderRole, sid: [u8; 32]) -> Self {
        let label = role.label();
        let mut h = Sha256::new();
        h.update([SenderRole::VERSION]);
        h.update(&sid);
        h.update(label);
        let genesis = h.finalize().to_vec();
        Self {
            role,
            sid,
            current: genesis,
            chain: Vec::new(),
        }
    }

    /// Compute the session ID from both senders' nonces (QKD v1.0.1 §1.4).
    #[must_use]
    pub fn session_id(nonce_a: &[u8], nonce_b: &[u8]) -> [u8; 32] {
        let mut h = Sha256::new();
        h.update(nonce_a);
        h.update(nonce_b);
        h.finalize().into()
    }

    /// Append a message to the chain: `H(i+1) = SHA256(H(i) || m)`.
    pub fn append(&mut self, message: &[u8]) {
        let mut h = Sha256::new();
        h.update(&self.current);
        h.update(message);
        let next = h.finalize();
        self.chain.push(next.into());
        self.current = next.to_vec();
    }

    /// The terminal hash value of this chain.
    #[must_use]
    pub fn final_hash(&self) -> [u8; 32] {
        if self.chain.is_empty() {
            // Return the genesis if no messages were appended.
            Sha256::digest(&self.current).into()
        } else {
            self.chain.last().copied().unwrap_or_else(|| {
                let mut h = Sha256::new();
                h.update(&self.current);
                h.finalize().into()
            })
        }
    }

    /// Combine two chains' terminal values into a context hash.
    #[must_use]
    pub fn context_hash(chain_a: &[u8; 32], chain_b: &[u8; 32]) -> [u8; 32] {
        let mut h = Sha256::new();
        h.update(chain_a);
        h.update(chain_b);
        h.finalize().into()
    }

    /// The role this chain is bound to.
    #[must_use]
    pub fn role(&self) -> SenderRole {
        self.role
    }
}

/// Compute a full transcript (hash chain + context hash) from a message
/// sequence, matching `ts/src/transcript.ts` `computeTranscript`.
///
/// `initial_prime_index` enforces the ADR-013 monotonicity guard: the
/// profile's `prime_index` must not regress below the pipeline entry point.
#[must_use]
pub fn compute_transcript(
    messages: &[&[u8]],
    nonces: &[&[u8]],
    version: u8,
    profile: &MultiplicityProfile,
    initial_prime_index: Option<u32>,
) -> Result<HashChainOutput, TranscriptError> {
    if messages.len() != nonces.len() {
        return Err(TranscriptError::LengthMismatch {
            messages: messages.len(),
            nonces: nonces.len(),
        });
    }
    if let Some(min) = initial_prime_index {
        if profile.prime_index < min {
            return Err(TranscriptError::PrimeRegression {
                got: profile.prime_index,
                min,
            });
        }
    }
    let sid = HashChain::session_id(
        nonces.first().copied().unwrap_or(&[]),
        nonces.get(1).copied().unwrap_or(&[]),
    );
    let _ = (version, profile);
    let mut chain_a = HashChain::new(SenderRole::Alice, sid);
    let mut chain_b = HashChain::new(SenderRole::Bob, sid);
    let mut hash_chain: Vec<[u8; 32]> = Vec::new();
    for (i, msg) in messages.iter().enumerate() {
        let nonce = nonces.get(i).copied().unwrap_or(&[]);
        let mut data = Vec::new();
        data.extend_from_slice(&chain_a.current);
        data.extend_from_slice(msg);
        data.extend_from_slice(nonce);
        data.push(version);
        let mut h = Sha256::new();
        h.update(&data);
        let next = h.finalize();
        chain_a.chain.push(next.into());
        chain_a.current = next.to_vec();

        // Mirror the same data into Bob's chain (deterministic for single-sender).
        let mut data_b = Vec::new();
        data_b.extend_from_slice(&chain_b.current);
        data_b.extend_from_slice(msg);
        data_b.extend_from_slice(nonce);
        data_b.push(version);
        let mut h_b = Sha256::new();
        h_b.update(&data_b);
        let next_b = h_b.finalize();
        chain_b.chain.push(next_b.into());
        chain_b.current = next_b.to_vec();
        hash_chain.push(chain_a.chain.last().copied().unwrap_or([0u8; 32]));
    }
    let context_hash = HashChain::context_hash(&chain_a.final_hash(), &chain_b.final_hash());
    Ok(HashChainOutput {
        hash_chain: hash_chain,
        context_hash,
        final_prime_index: profile.prime_index,
    })
}

/// Compute the context hash from two per-sender terminal hashes.
#[must_use]
pub fn compute_context_hash(terminal_a: &[u8; 32], terminal_b: &[u8; 32]) -> [u8; 32] {
    HashChain::context_hash(terminal_a, terminal_b)
}

/// Error type for transcript construction.
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum TranscriptError {
    #[error("messages and nonces must have the same length (got {messages} messages, {nonces} nonces)")]
    LengthMismatch { messages: usize, nonces: usize },
    #[error("prime_index regression: got {got}, expected >= {min}")]
    PrimeRegression { got: u32, min: u32 },
}

// ---------------------------------------------------------------------------
// Keccak256 Fiat-Shamir transcript (ported from the existing reference impl)
// ---------------------------------------------------------------------------

/// Keccak256-based Fiat-Shamir transcript for generating verifier challenges.
///
/// Uses a single-hash policy: every `append_message` absorbs a label +
/// length-prefixed message into a rolling Keccak256 state; `challenge`
/// produces a 64-bit squeezed value.
pub struct Keccak256Transcript {
    hasher: Keccak256,
}

impl Keccak256Transcript {
    #[must_use]
    pub fn new(label: &[u8]) -> Self {
        let mut hasher = sha3::Keccak256::new();
        hasher.update(label);
        Self { hasher }
    }

    pub fn append_message(&mut self, label: &[u8], message: &[u8]) {
        self.hasher.update(label);
        self.hasher.update(&(message.len() as u64).to_le_bytes());
        self.hasher.update(message);
    }

    pub fn append_u64(&mut self, label: &[u8], value: u64) {
        self.append_message(label, &value.to_le_bytes());
    }

    pub fn append_commitment(&mut self, label: &[u8], commitment: &[u8]) {
        self.append_message(label, commitment);
    }

    #[must_use]
    pub fn challenge(&mut self, label: &[u8]) -> u64 {
        let mut challenge_hasher = self.hasher.clone();
        challenge_hasher.update(label);
        let hash = challenge_hasher.finalize();
        u64::from_le_bytes(hash[0..8].try_into().expect("hash is 32 bytes"))
    }

    #[must_use]
    pub fn challenge_vec(&mut self, label: &[u8], count: usize) -> Vec<u64> {
        (0..count)
            .map(|i| {
                let mut l = label.to_vec();
                l.extend_from_slice(&i.to_le_bytes());
                self.challenge(&l)
            })
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn session_id_is_deterministic() {
        let na = [0xab; 16];
        let nb = [0xcd; 16];
        let sid1 = HashChain::session_id(&na, &nb);
        let sid2 = HashChain::session_id(&na, &nb);
        assert_eq!(sid1, sid2);
    }

    #[test]
    fn hash_chain_grows_with_messages() {
        let sid = [0x42; 32];
        let mut chain = HashChain::new(SenderRole::Alice, sid);
        let n = chain.chain.len();
        chain.append(b"hello");
        assert_eq!(chain.chain.len(), n + 1);
        assert_ne!(chain.current, [0u8; 32]);
    }

    #[test]
    fn context_hash_is_deterministic() {
        let ha = [0x01; 32];
        let hb = [0x02; 32];
        let ch1 = HashChain::context_hash(&ha, &hb);
        let ch2 = HashChain::context_hash(&ha, &hb);
        assert_eq!(ch1, ch2);
    }

    #[test]
    fn keccak_transcript_is_deterministic() {
        let mut t1 = Keccak256Transcript::new(b"test");
        t1.append_u64(b"value", 42);
        let c1 = t1.challenge(b"challenge");

        let mut t2 = Keccak256Transcript::new(b"test");
        t2.append_u64(b"value", 42);
        let c2 = t2.challenge(b"challenge");

        assert_eq!(c1, c2);
    }

    #[test]
    fn profile_monotonicity_guard_rejects_regression() {
        let profile = MultiplicityProfile::new(0, 1, 0, 5);
        let result = compute_transcript(
            &[b"msg"],
            &[b"nonce"],
            1,
            &profile,
            Some(7),
        );
        assert!(matches!(result, Err(TranscriptError::PrimeRegression { got: 5, min: 7 })));
    }
}
