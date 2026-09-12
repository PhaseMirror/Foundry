//! Prime-Weighted Execution Hashing (PWEH) integrity chain for ADR-0013.
//!
//! ADR-0013 §"The Theorem-Level Execution Lock":
//!
//! ```text
//! S_integrity(t) = Hash_PQC(S_integrity(t-1) ‖ p_i^t ‖ ‖A_{p_i^t} T(t)‖ ‖ M(t))
//! ```
//!
//! The step binds (1) the previous integrity state, (2) the selected prime
//! index, (3) the multiplicity-weighted tensor norm, and (4) strict governance
//! metadata into a single chained object. Because the binding is a lossless
//! concatenation of fixed-width big-endian fields, the exact sequence of
//! applied operators matters: distinct histories produce distinct hash inputs,
//! so tampering is a path-collision problem across the whole chain
//! (ADR-0013 §"Path-Dependent Tamper Resistance").
//!
//! The 32-byte `preimage`/`bind` layer is the formal backbone: the Lean mirror
//! in `lean/MTPI/ADR0013.lean` proves its injectivity and fixed length. The
//! final `hash_bind` is the SHA-256 instantiation of the `Hash_PQC` slot.

use sha2::{Digest, Sha256};

use crate::canonical::be_u64;

/// Width of every PWEH field (`[u8; 32]`).
pub const BLOCK_LEN: usize = 32;

/// Width of the four-field binding.
pub const BIND_LEN: usize = 4 * BLOCK_LEN;

/// 256-bit big-endian encoding of a small integer field (prime index, tensor
/// norm, or compact metadata). Values larger than `u64` use a caller-provided
/// 32-byte digest instead.
#[inline]
pub fn be256(v: u64) -> [u8; BLOCK_LEN] {
    let mut block = [0u8; BLOCK_LEN];
    block[BLOCK_LEN - 8..].copy_from_slice(&be_u64(v));
    block
}

/// Governance metadata `M(t)` digest. Strict governance metadata is bound via
/// its digest so that arbitrary-length policy payloads fold into the fixed
/// 32-byte PWEH field.
#[inline]
pub fn hash_meta(meta: &[u8]) -> [u8; BLOCK_LEN] {
    Sha256::digest(meta).into()
}

/// Lossless four-field binding for one PWEH step, in exact ADR order.
///
/// This function is deliberately pure and allocation-free beyond its result, so
/// that its injectivity and fixed length are mechanically checkable (Lean) and
/// Kani-verifiable at the field level.
#[inline]
pub fn bind_step(
    prev: [u8; BLOCK_LEN],
    prime: [u8; BLOCK_LEN],
    norm: [u8; BLOCK_LEN],
    meta: [u8; BLOCK_LEN],
) -> [u8; BIND_LEN] {
    let mut block = [0u8; BIND_LEN];
    block[..BLOCK_LEN].copy_from_slice(&prev);
    block[BLOCK_LEN..2 * BLOCK_LEN].copy_from_slice(&prime);
    block[2 * BLOCK_LEN..3 * BLOCK_LEN].copy_from_slice(&norm);
    block[3 * BLOCK_LEN..].copy_from_slice(&meta);
    block
}

/// The `Hash_PQC` slot instantiated with SHA-256.
#[inline]
pub fn hash_bind(block: &[u8; BIND_LEN]) -> [u8; BLOCK_LEN] {
    Sha256::digest(block).into()
}

/// Rolling PWEH integrity state `S_integrity(t)`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PwevhIntegrity {
    state: [u8; BLOCK_LEN],
}

impl PwevhIntegrity {
    pub const fn new(seed: [u8; BLOCK_LEN]) -> Self {
        Self { state: seed }
    }

    pub const fn attested(&self) -> [u8; BLOCK_LEN] {
        self.state
    }

    /// Apply one prime-weighted execution step.
    pub fn step(&mut self, prime: [u8; BLOCK_LEN], norm: [u8; BLOCK_LEN], meta: [u8; BLOCK_LEN]) {
        self.state = hash_bind(&bind_step(self.state, prime, norm, meta));
    }

    /// Convenience step with `u64`-sized fields for `prime`, `norm` and a
    /// pre-digested metadata block.
    pub fn step_u64(&mut self, prime: u64, norm: u64, meta: [u8; BLOCK_LEN]) {
        self.step(be256(prime), be256(norm), meta);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn seed() -> [u8; BLOCK_LEN] {
        [0xab; BLOCK_LEN]
    }

    /// The chain is deterministic: the same trace always reproduces the same
    /// attestation.
    #[test]
    fn chain_is_deterministic_adr_0013() {
        let meta_a = hash_meta(b"epoch-1 governance");
        let meta_b = hash_meta(b"epoch-2 governance");

        let mut left = PwevhIntegrity::new(seed());
        left.step(be256(2), be256(9), meta_a);
        left.step(be256(3), be256(27), meta_b);

        let mut right = PwevhIntegrity::new(seed());
        right.step(be256(2), be256(9), meta_a);
        right.step(be256(3), be256(27), meta_b);

        assert_eq!(left.attested(), right.attested());
    }

    /// The exact sequence of applied operators matters: reordering the two
    /// prime-weighted steps yields a different attestation (path dependence).
    #[test]
    fn path_dependence_reorder_adr_0013() {
        let meta_a = hash_meta(b"epoch-1 governance");
        let meta_b = hash_meta(b"epoch-2 governance");

        let mut ab = PwevhIntegrity::new(seed());
        ab.step(be256(2), be256(9), meta_a);
        ab.step(be256(3), be256(27), meta_b);

        let mut ba = PwevhIntegrity::new(seed());
        ba.step(be256(3), be256(27), meta_b);
        ba.step(be256(2), be256(9), meta_a);

        assert_ne!(ab.attested(), ba.attested());
    }

    /// Forbidden prime channel: substituting the prime index changes the
    /// attestation at the binding level, so forgery is a path-collision
    /// problem over the whole chain.
    #[test]
    fn forbidden_prime_channel_changes_trace_adr_0013() {
        let meta = hash_meta(b"rules of engagement");
        let mut lawful = PwevhIntegrity::new(seed());
        lawful.step(be256(2), be256(9), meta);

        let mut forged = PwevhIntegrity::new(seed());
        forged.step(be256(7), be256(9), meta);

        assert_ne!(lawful.attested(), forged.attested());
    }

    /// The binding is lossless: all four fields are recoverable from the
    /// 128-byte block, in order.
    #[test]
    fn bind_is_lossless_and_ordered_adr_0013() {
        let prev = [1u8; BLOCK_LEN];
        let prime = [2u8; BLOCK_LEN];
        let norm = [3u8; BLOCK_LEN];
        let meta = [4u8; BLOCK_LEN];
        let block = bind_step(prev, prime, norm, meta);

        assert_eq!(block.len(), 128);
        assert_eq!(&block[0..32], &prev);
        assert_eq!(&block[32..64], &prime);
        assert_eq!(&block[64..96], &norm);
        assert_eq!(&block[96..128], &meta);
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    /// The big-endian field encoder is injective: two equal 32-byte encoded
    /// fields must have encoded equal values (the reconstruction argument
    /// behind the binding's losslessness).
    #[kani::proof]
    pub fn be256_is_injective() {
        let a: u64 = kani::any();
        let b: u64 = kani::any();
        kani::assume(be256(a) == be256(b));
        assert_eq!(a, b);
    }

    /// The two-field prefix bind is injective: equal blocks imply equal
    /// (prev, prime) fields. This is the Kani witness for the Lean theorem
    /// `bind_injective` in `MTPI.ADR0013`.
    #[kani::proof]
    pub fn two_field_bind_injective() {
        let a: u64 = kani::any();
        let b: u64 = kani::any();
        let c: u64 = kani::any();
        let d: u64 = kani::any();

        let mut left = [0u8; 2 * BLOCK_LEN];
        left[..BLOCK_LEN].copy_from_slice(&be256(a));
        left[BLOCK_LEN..].copy_from_slice(&be256(b));

        let mut right = [0u8; 2 * BLOCK_LEN];
        right[..BLOCK_LEN].copy_from_slice(&be256(c));
        right[BLOCK_LEN..].copy_from_slice(&be256(d));

        kani::assume(left == right);
        assert_eq!(a, c);
        assert_eq!(b, d);
    }
}