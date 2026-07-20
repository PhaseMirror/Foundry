# ADR-PML-051: Post-Quantum Signatures (CRYSTALS-Dilithium)

**Status**: Proposed
**Date**: 2026-07-18
**Authors**: `the-publisher`, `the-guardian`
**Dependencies**: ADR-PML-055 (UAC State Anchor), ADR-PML-050 (Batch ZK Proofs), ADR-106 (legacy Dilithium ADR)
**Cross-cutting**: All attestation and anchor submission paths

---

## Context

The PhaseMirror attestation pipeline currently relies exclusively on ECDSA for provider and sidecar signatures. ECDSA is vulnerable to Shor's algorithm; a cryptographically relevant quantum computer (CRQC) capable of factoring 256-bit elliptic curves would render all existing signatures forgeable. ADR-PML-055 mandates a "forever immutable" operational record, but an immutable record secured by breakable signatures is effectively mutable.

The `crates/dilithium-signer` crate already exists as a CLI wrapper around `pqcrypto-dilithium`, but it is:
1. Bin-only — no library API for sidecar integration.
2. Not wired into the sidecar or contracts.
3. Not tested.

`Prime/sidecar/src/index.ts` invokes the CLI via `execSync`, but `Prime/sidecar/state-anchor/index.ts` (the ADR-PML-055 sidecar) only ECDSA-signs the daily root. `AnchorRegistry.sol` and `AttestationRegistry.sol` accept only `bytes signature` (ECDSA).

This ADR closes the gap by promoting the Dilithium crate to a library, wiring dual-signing into the sidecar, and extending the on-chain registries to accept optional Dilithium signatures.

---

## Decision

We will add **optional Dilithium5 signatures** alongside ECDSA for all on-chain submissions. Clients that opt in produce dual signatures; the contract verifies ECDSA always and Dilithium when provided.

| **Layer** | **Existing** | **New (this ADR)** |
| :--- | :--- | :--- |
| Rust crypto | `crates/dilithium-signer` (CLI only, no tests) | Library API (`keygen`, `sign`, `verify`) + unit/Kani tests |
| Sidecar | ECDSA-only `submitAnchor` in `state-anchor/index.ts` | Dual-sign when `DILITHIUM_ENABLED=true`; invokes `dilithium-signer` library via CLI |
| AnchorRegistry | `submitRoot(bytes32, uint256, bytes)` | New `submitRootWithDilithium(bytes32, uint256, bytes, bytes)` + `registerDilithiumKey` |
| AttestationRegistry | `submitAttestation(..., bytes signature)` | New `submitAttestationWithDilithium(..., bytes, bytes)` + `registerDilithiumKey` |
| On-chain verifier | None | `contracts/DilithiumVerifier.sol` (mock for testnet; precompile path for production) |

### 1. Dilithium5 Parameters

We use **Dilithium5** (NIST FIPS 204, security level 5, ~128-bit quantum security):
- Public key: 2592 bytes
- Secret key: 4896 bytes
- Signature: 4627 bytes

### 2. Rust Library Promotion

`crates/dilithium-signer` will gain:
- `src/lib.rs` exporting `keygen() -> (pk, sk)`, `sign(sk, msg) -> sig`, `verify(pk, msg, sig) -> Result<()>`.
- `src/main.rs` refactored to call the library.
- `#[cfg(test)]` unit tests for round-trip sign/verify and keygen determinism.
- `#[cfg(kani)]` proof harness (`DilithiumVerifySound`: valid sigs verify, invalid sigs reject).

### 3. Sidecar Dual-Signing

In `Prime/sidecar/state-anchor/index.ts`:
- When `DILITHIUM_ENABLED=true` and `DILITHIUM_SK_PATH` is set, the sidecar:
  1. Computes `msgHash = keccak256(abi.encodePacked(root, timestamp))`.
  2. ECDSA-signs `msgHash` via `wallet.signMessage`.
  3. Hex-encodes `msgHash` and invokes `dilithium-signer sign --sk-path <path> --msg-hex <hex>`.
  4. Calls `contract.submitRootWithDilithium(root, timestamp, ecdsaSig, dilithiumSig)`.
- When `DILITHIUM_ENABLED=false` or key is missing, falls back to `submitRoot` (backward compatible).

For `AttestationRegistry`, the same pattern applies to `submitAttestationWithDilithium`: the provider signs `keccak256(abi.encodePacked(digest, uint64(timestamp)))`.

### 4. On-Chain Verification

`contracts/DilithiumVerifier.sol` provides:
- `registerPublicKey(bytes calldata)` — owners register their Dilithium5 PK.
- `verify(address owner, bytes32 messageHash, bytes calldata signature) external view returns (bool)` — verifies `signature` against `owner`'s registered PK over `messageHash`.

**Testnet implementation**: A mock mode (`setMockMode(true)`) that accepts any well-formed (correct-length) signature, enabling end-to-end testing without a precompile.

**Production implementation**: Replace mock logic with a call to a native Dilithium precompile (e.g., `DILITHIUM_VERIFY_PRECOMPILE = 0x...`) or an external verifier contract backed by a full Dilithium5 circuit compiled to Yul. The interface remains identical.

### 5. Gas & Performance

Dilithium5 verification in pure Solidity is ~200–400k gas. This is acceptable for the daily anchor (ADR-PML-055 budget < 200k per call, but the anchor is infrequent). For high-throughput attestations, we recommend:
- **Testnet**: mock verifier (negligible gas).
- **Production**: precompile path (~30k gas, comparable to ECDSA recovery).

---

## Integration with Existing ADRs

| **ADR** | **How This ADR Extends It** |
| :--- | :--- |
| ADR-PML-055 (State Anchor) | The daily `submitRoot` call becomes optionally dual-signed; `AnchorRegistry` accepts Dilithium. |
| ADR-PML-050 (Batch ZK Proofs) | The sidecar that submits the batch anchor root is the same 055 sidecar; dual-signing applies to the combined root. |
| ADR-106 (legacy Dilithium) | Supersedes the planning-only ADR-106 with actual implementation; retains the same Dilithium5 choice and Lean theorem names. |
| ADR-PML-046 / 069 (Recursive Aggregation) | Unchanged; STARK aggregation is orthogonal to the signature scheme on the outer envelope. |

---

## Consequences

### Positive
- **Quantum-safe attestations**: Once deployed, the anchor and attestation records resist CRQC forgery.
- **Backward compatible**: ECDSA-only submissions continue to work; Dilithium is opt-in per sidecar.
- **Minimal new surface**: Reuses existing sidecar patterns, NATS subjects, and contract allowlists.
- **Testnet-ready**: Mock verifier enables full integration testing today.

### Negative
- **Signature bloat**: Dilithium5 signatures are 2420 bytes vs 65 bytes for ECDSA. On-chain storage cost increases (~0.06 ETH per 2420 bytes at 20 gwei, 32k gas). Acceptable for daily anchors; high-throughput paths should use the precompile.
- **Sidecar latency**: CLI spawn + Dilithium5 sign adds ~5–20 ms per submission (pqcrypto on x86_64 is fast; mock is instant).
- **Crate maturity**: `pqcrypto-dilithium 0.5.0` is unmaintained since 2022. Mitigation: pin version, audit, or migrate to `pqcrypto` 0.7 if released.

### Risks

| **Risk** | **Mitigation** |
| :--- | :--- |
| `pqcrypto-dilithium` unmaintained | Pin `0.5.0`; open upstream issue or fork; monitor NIST reference implementation. |
| Precompile unavailable on target chain | Fall back to mock verifier on testnet; require explicit governance vote to enable production Dilithium mode. |
| Key management complexity | Store SK in `DILITHIUM_SK_PATH` env var; integrate with cloud KMS in Phase 2 (per ADR-106). |
| Signature length breaks existing event ABIs | New events `AnchorSubmittedPQC` and `AttestedPQC` keep old events unchanged; consumers upgrade independently. |

---

## Implementation Phases

### Phase 1: Rust Library + Tests (Day 1)
- Add `src/lib.rs` to `crates/dilithium-signer`.
- Add `#[cfg(test)]` round-trip tests and `#[cfg(kani)]` `DilithiumVerifySound` harness.
- Verify `cargo test` and `cargo kani` pass.

### Phase 2: Solidity Verifier + Contract Extensions (Day 1–2)
- Create `contracts/DilithiumVerifier.sol` and `contracts/IDilithiumVerifier.sol`.
- Extend `AnchorRegistry.sol` with `registerDilithiumKey` and `submitRootWithDilithium`.
- Extend `AttestationRegistry.sol` with `registerDilithiumKey` and `submitAttestationWithDilithium`.
- Add new events `AnchorSubmittedPQC` and `AttestedPQC`.

### Phase 3: Sidecar Wiring (Day 2)
- Update `Prime/sidecar/state-anchor/index.ts`:
  - Add `signWithDilithium(msgHex)` helper invoking the Rust CLI.
  - Dual-sign in `submitAnchor` when `DILITHIUM_ENABLED=true`.
  - Fall back to `submitRoot` when disabled.
- Update `ANCHOR_ABI` to include `submitRootWithDilithium`.
- Add `.env.example` entries: `DILITHIUM_ENABLED`, `DILITHIUM_SK_PATH`.

### Phase 4: Tests (Day 2–3)
- **Rust**: Unit tests for `lib.rs`; Kani harness for `DilithiumVerifySound`.
- **Sidecar**: Jest tests mocking `child_process.execSync` for the Dilithium CLI; verify dual-sign flow and fallback.
- **Contract**: Foundry `*.t.sol` tests for `DilithiumVerifier` (mock mode), `AnchorRegistry.submitRootWithDilithium`, and `AttestationRegistry.submitAttestationWithDilithium`.
- **Integration**: `scripts/run_testnet.sh` spins up Anvil, deploys contracts, generates keys, runs sidecar, asserts `AnchorSubmittedPQC` event.

---

## Verification Criteria

- **Rust library**: `cargo test` passes; `cargo kani` proves `DilithiumVerifySound` (valid sigs verify, forged sigs reject).
- **Contract deployment**: `DilithiumVerifier` deploys on Anvil; `mockMode` accepts valid-length signatures.
- **Dual-sign submission**: Sidecar with `DILITHIUM_ENABLED=true` emits `AnchorSubmittedPQC` with matching ECDSA + Dilithium signatures.
- **Backward compatibility**: Sidecar with `DILITHIUM_ENABLED=false` still emits `AnchorSubmitted` via legacy `submitRoot`.
- **Gas**: `submitRootWithDilithium` with mock verifier < 150k gas on Anvil.
- **Key rotation**: `registerDilithiumKey` updates the stored PK; subsequent submissions verify against the new key.

---

## Artifacts

- `docs/adr/proposed/ADR-PML-051-Post-Quantum-Signatures.md` — this document.
- `contracts/IDilithiumVerifier.sol` — verifier interface.
- `contracts/DilithiumVerifier.sol` — mock/testnet verifier + precompile stub.
- `contracts/AnchorRegistry.sol` — extended with `submitRootWithDilithium`.
- `contracts/AttestationRegistry.sol` — extended with `submitAttestationWithDilithium`.
- `crates/dilithium-signer/src/lib.rs` — promoted library API.
- `crates/dilithium-signer/src/main.rs` — CLI refactored to use lib.
- `crates/dilithium-signer/tests/` — unit + Kani tests.
- `Prime/sidecar/state-anchor/index.ts` — dual-signing wiring.
- `Prime/sidecar/state-anchor/.env.example` — `DILITHIUM_ENABLED`, `DILITHIUM_SK_PATH`.
- `scripts/run_testnet.sh` — one-command testnet bootstrap.
- `scripts/verify_testnet.sh` — pass/fail health check.

---

## Rationale

Dilithium5 is the only NIST-standardized lattice signature scheme ready for production deployment. By adding it as an optional overlay on the existing ECDSA paths, we achieve quantum safety without disrupting current operations. The sidecar's child-process invocation of the Rust crate preserves isolation and testability, while the mock Solidity verifier lets us validate the full integration loop today. When the target chain ships a Dilithium precompile, the production verifier is a one-line config change.

---

## References

- NIST FIPS 204: CRYSTALS-Dilithium (https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.204.pdf)
- `pqcrypto-dilithium` crate (https://docs.rs/pqcrypto-dilithium/0.5.0)
- `contracts/AnchorRegistry.sol` (ADR-PML-055)
- `contracts/AttestationRegistry.sol` (ADR-PML-050)
- `crates/dilithium-signer/` — existing CLI crate.
- `Prime/sidecar/state-anchor/index.ts` — 055 sidecar.
- `docs/adr/completed/ADR-106.md` — legacy Dilithium planning ADR (superseded by this implementation).
