//! # `multiplicity-crypto` — Production-Grade Cryptographic Primitives for the PhaseMirror Governance Manifold
//!
//! Version 1.0.1 — QKD Hybrid Encryption v1.0.1 + ADR-0066 contractivity seams.
//!
//! ## Overview
//!
//! This crate implements the cryptographic substrate that binds the PrismPM
//! semantic packaging layer to the PIRTM dynamic execution manifold. It ports the
//! TypeScript/Python reference (`packages/rust/multiplicity-crypto/`) into a
//! production Rust crate with formal verification hooks (Kani BMC), test vectors
//! from the QKD v1.0.1 specification, and documented substitution seams for
//! circuit-native backends.
//!
//! ## Architecture
//!
//! | Module | Responsibility | Reference |
//! | --- | --- | --- |
//! | [`prime`] | Prime sieve (`get_prime_at_index`), `MAX_PRIME_INDEX = 1000`, `prime_upper_bound` (`p/(p+1)`) | `ts/src/multiplicity.ts`, `ts/src/feedback.ts` |
//! | [`profile`] | 8-byte `MultiplicityProfile` encode/decode (type, version, stateIndex, prime_index) | `ts/src/multiplicity.ts` |
//! | [`chacha20`] | Pure-Rust RFC 8439 ChaCha20 stream cipher (no external deps) | RFC 8439 |
//! | [`kdf`] | HKDF-SHA256 with prime-indexed domain separation | `ts/src/keyderivation.ts`, RFC 5869 |
//! | [`transcript`] | SHA-256 per-sender hash chain + Keccak256 Fiat-Shamir transcript | `ts/src/transcript.ts`, QKD v1.0.1 §1.4 |
//! | [`commitment`] | Domain-separated commitment (HMAC-SHA256 default, Poseidon2 seam) | `ts/src/commitment.ts`, ADR-0066 |
//! | [`aead`] | ChaCha20 + HMAC-SHA256 Encrypt-then-MAC AEAD, prime-indexed nonce domain | `ts/src/aead.ts`, QKD v1.0.1 §1.8 |
//! | [`merkle`] | Sparse Merkle tree (build, prove, verify) using SHA-256 | `py/multiplicity/crypto/__init__.py` |
//! | [`frequency`] | Classical (`F_c`) + quantum (`F_q`) frequency mapping | `ts/src/frequency.ts` |
//! | [`feedback`] | L0-5 contractivity gate + prime-indexed `p/(p+1)` upper bound | `ts/src/feedback.ts`, ADR-012 |
//! | [`signing`] | Ed25519 identity commitments + BLS-like fallback | `py/multiplicity/crypto/__init__.py` |
//! | [`poseidon2`] | Poseidon2 sponge (`t=9, r=8`, M61 field) | `pirtm-engine/src/poseidon2.rs`, ADR-0066 |
//! | [`canonical`] | BCS canonical serialization for envelope wire format | `pirtm-engine/src/canonical.rs`, ADR-0066 |
//! | [`qkd`] | QKD pipeline composition root: transcript → KDF → commitment → AEAD | `ts/src/qkd.ts` |
//!
//! ## Deliberate substitution seams
//!
//! - **AEAD backend:** the default AEAD is ChaCha20 (self-implemented, RFC 8439
//!   test-vector-verified) authenticated with HMAC-SHA256 (Encrypt-then-MAC).
//!   The QKD v1.0.1 spec mandates AES-256-GCM; an `aes-gcm`-backed implementation
//!   is a drop-in behind the same `Aead` trait.
//! - **Commitment backend:** `compute_commitment` defaults to HMAC-SHA256 domain
//!   separation; `Poseidon2Sponge` provides the ZK-compatible alternative used by
//!   the CRMF seal.
//! - **Signing backend:** Ed25519 is the native identity signing scheme; the
//!   BLS-like fallback (HMAC-SHA256) is for environments without BLS libraries.
//!
//! ## Testing
//!
//! - `cargo test` runs unit + integration + property tests.
//! - `cargo kani --harness <name>` runs the bounded-model-checking harnesses
//!   under `tests/kani/` (requires the `kani` cargo subcommand).
//!
//! ## No-std compatibility
//!
//! The core crypto primitives (`prime`, `profile`, `chacha20`, `kdf`,
//! `transcript`, `commitment`, `poseidon2`) are `#![no_std]`-compatible.
//! `merkle`, `aead`, `feedback`, and `signing` require `std` for heap allocation
//! and RNG integration.
#![cfg_attr(not(test), warn(missing_docs))]
#![cfg_attr(docsrs, feature(doc_cfg))]
#![allow(clippy::module_inception)]

pub mod aead;
pub mod canonical;
pub mod chacha20;
pub mod commitment;
pub mod feedback;
pub mod frequency;
pub mod kdf;
pub mod merkle;
pub mod poseidon2;
pub mod prime;
pub mod profile;
pub mod qkd;
pub mod signing;
pub mod transcript;

pub use aead::{AeadCiphertext, AeadError, decrypt_aead, encrypt_aead};
pub use canonical::{CanonicalEnvelope, EnvelopeMetrics, canonical_seal};
pub use chacha20::{ChaCha20, ChaChaKey, ChaChaNonce};
pub use commitment::{Commitment, CommitmentError, compute_commitment, verify_commitment};
pub use feedback::{FeedbackInput, FeedbackOutput, compute_feedback, prime_upper_bound, prime_upper_bound_f64};
pub use frequency::{FrequencyInput, FrequencyOutput, compute_frequency, frequency_classical, frequency_quantum};
pub use kdf::{derive_key, DeriveKeyInput, DeriveKeyOutput};
pub use merkle::{MerkleProof, MerkleTree, verify_proof};
pub use poseidon2::{Poseidon2Sponge, crc32_seal};
pub use prime::{MAX_PRIME_INDEX, get_prime_at_index, prime_sieve};
pub use profile::{DEFAULT_PROFILE_VERSION, MultiplicityProfile, default_profile, decode_profile, encode_profile};
pub use qkd::{QkdInput, QkdOutput, simulate_qkd};
pub use signing::{IdentityCommitment, IdentitySignature, sign_identity, verify_identity};
pub use transcript::{HashChain, HashChainOutput, Keccak256Transcript, compute_context_hash};
