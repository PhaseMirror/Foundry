# multiplicity-crypto

Consolidated QKD Hybrid Encryption v1.0.1 sources — the cryptographic component built with native multiplicity methodology.

## Contents

| Path | Language | Description |
|------|----------|-------------|
| `ts/src/` | TypeScript | QKD simulator pipeline: transcript → key derivation → commitment → AEAD |
| `py/multiplicity/` | Python | Interop bridge (`multiplicity.crypto`) + CAS registry consumer |
| `rust/src/` | Rust | Keccak256 Fiat-Shamir transcript for prover challenges |
| `docs/` | Markdown | QKD Hybrid Encryption v1.0.1 specification articles |

## TypeScript Module Map

- `qkd.ts` — Pipeline composition root (`computeTranscript → deriveKey → computeCommitment → encryptAEAD`)
- `transcript.ts` — Per-sender SHA-256 hash-chain + context hash
- `keyderivation.ts` — HKDF-SHA256 with prime-indexed domain separation
- `commitment.ts` — Pedersen commitment (WASM-backed BN254, SHA-256 fallback)
- `aead.ts` — AES-256-GCM with prime-indexed nonce domain tag
- `multiplicity.ts` — `MultiplicityProfile` encode/decode, prime sieve `getPrimeAtIndex`
- `frequency.ts` — Classical/quantum frequency mapping
- `feedback.ts` — L0-5 contractivity gate + prime upper bound `p/(p+1)`

## Python Module Map

- `multiplicity/crypto/__init__.py` — `MultiplicityCrypto` bridge with SHA-256 fallback mode
- `multiplicity/math/cas_registry.py` — CAS registry binding ACE witnesses to crypto commitments
- `multiplicity/mkt/mkt_commitment.py` — MBC prototype over braid/invariant payloads
- `multiplicity/cert/test_ace_crypto_integration.py` — Integration tests for bridge + ACE witness registration

## Rust Module Map

- `rust/src/transcript.rs` — `Keccak256Transcript` for verifier challenge generation

## Testing

TypeScript tests are located in `ts/src/__tests__/` and use a zero-dependency mock backend.

Python integration tests are in `py/multiplicity/cert/test_ace_crypto_integration.py`.

Rust tests are inline in `rust/src/transcript.rs`.

## Source References

This folder was consolidated from:
- `packages/agiOS/src/` (TypeScript)
- `packages/agiOS/src/multiplicity/` (Python)
- `packages/agiOS/crates/prover/src/transcript.rs` (Rust)
- `packages/agiOS/src/multiplicity/library/articles/` (Docs)
