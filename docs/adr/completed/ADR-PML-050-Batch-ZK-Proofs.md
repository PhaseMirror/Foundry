# ADR-PML-050: Batch ZK Proofs for the UAC State Anchor

**Status**: Proposed
**Date**: 2026-07-18
**Authors**: `the-publisher`, `the-guardian`
**Dependencies**: ADR-PML-055 (UAC State Anchor), ADR-PML-051 (Post-Quantum Signatures), ADR-PML-046 / ADR-PML-069 (Recursive Proof Aggregation)
**Cross-cutting**: Applies to all operational layers that emit attestations

---

## Context

ADR-PML-055 introduces `AnchorRegistry.sol`, which accepts a single `submitRoot(bytes32 root, uint256 timestamp, bytes signature)` per anchor. The daily anchor root is required to include a **Run Aggregator Root** — "a batch Merkle root of all FeMoco attestations in the last 24 hours" — so the daily anchor is the single source of truth for *both* operational state and run results.

ADR-PML-069 (`Recursive-Prover`) already ships a production-grade aggregation pipeline: `crates/recursive-prover/` exposes `wrap-proof` and `aggregate-proofs`, backed by `StarkVerifierGadget::aggregate_rpos` (Goldilocks/Pasta STARK aggregation). `AttestationRegistry.sol` already has `submitBatchAttestation(bytes batchProof, bytes32 batchMerkleRoot, BatchRunData[] runs, bytes sidecarSignature)` which verifies a recursive Halo2/STARK proof and emits `BatchAttested`.

What is **missing** is the composition layer that turns a day's worth of FeMoco attestations into (a) one verifiable STARK/APO, (b) the `batchMerkleRoot` that ADR-PML-055 expects, and (c) folds that root into the daily `AnchorRegistry` root — all within the < 200k-gas budget the 055 ADR mandates.

---

## Decision

We will add a **batch→anchor composition layer** that reuses the existing `recursive-prover` crate and the two on-chain registries, without forking either. Specifically:

| **Layer** | **Existing** | **New (this ADR)** |
| :--- | :--- | :--- |
| Proof aggregation | `recursive-prover::aggregate-proofs` → `AggregatedProofObject` | `batch_anchor` bin that wraps each day's `Attested` digest into a `RecursiveProofObject`, aggregates to one APO |
| On-chain verification | `AttestationRegistry.submitBatchAttestation` | unchanged; consumes the APO's `aggregate_root` as `batchMerkleRoot` |
| Daily anchor | `AnchorRegistry.submitRoot` (ADR-PML-055) | the batch root is one of the five category roots the 055 sidecar already combines |

### 1. Batch Attestation Root

For each FeMoco run in the 24h window we already have `digest` (keccak256 of the SQD state) from `Attested`. The batch Merkle root is computed **identically** to `AttestationRegistry._computeMerkleRoot`:

```
batchRoot = keccak256-chain( keccak256(prev, digest_i, ts_i, consent_i, nullifier_i) )
```

This is the value passed as `batchMerkleRoot` to `submitBatchAttestation` and, in parallel, as the **Run Aggregator Root** consumed by the 055 sidecar's `combinedRoot`.

### 2. STARK Batching (Gas Strategy)

Per ADR-PML-055 §2, the daily anchor gas must stay < 200k. The APO aggregation moves *all* per-run Groth16 verification off-chain:

- `aggregate-proofs` (Rust) wraps each `Attested` proof into a `RecursiveProofObject` and calls `StarkVerifierGadget::aggregate_rpos`, producing one `AggregatedProofObject { aggregate_root, member_roots, seal }`.
- `AttestationRegistry.submitBatchAttestation` verifies the single APO (`batchVerifier.verifyProof(batchProof, [batchMerkleRoot, MAX_ENTROPY, MAX_UNSTABLE])`) instead of N Groth16 proofs → one `BatchAttested` event.
- The 055 `AnchorRegistry.submitRoot` is a single SSTORE + event (~< 100k gas). Combined: well under 200k.

### 3. Dual-Signature (ADR-PML-051)

The 055 sidecar already dual-signs (`ECDSA` + `Dilithium`). The batch submitter reuses that path: the APO seal is committed on-chain via `submitBatchAttestation`, and the *combined* daily root is dual-signed into `AnchorRegistry` by the 055 sidecar. No new signature scheme is introduced.

### 4. Schedule (per ADR-PML-055 Phase 3)

A `batch_anchor` job runs at UTC 00:00 (the 055 daily boundary). It:
1. reads the last 24h of `Attested`/`BatchAttested` events,
2. aggregates to one APO (or re-uses the latest `BatchAttested` APO for the day),
3. computes `batchRoot`,
4. submits `AttestationRegistry.submitBatchAttestation` if not already batched,
5. hands `batchRoot` to the 055 sidecar, which folds it into the daily `combinedRoot` → `AnchorRegistry.submitRoot`.

---

## Integration with Existing ADRs

| **ADR** | **How This ADR Extends It** |
| :--- | :--- |
| ADR-PML-055 (State Anchor) | Supplies the `Run Aggregator Root` the daily anchor requires; the batch root is one of the five combined categories. |
| ADR-PML-051 (Post-Quantum) | Inherits the dual ECDSA+Dilithium signing already implemented in the 055 sidecar. |
| ADR-PML-046 / 069 (Recursive Aggregation) | Reuses `recursive-prover::aggregate-proofs` and `StarkVerifierGadget` verbatim — this ADR adds *only* the composition/glue, not a new prover. |
| ADR-PML-067 (Archivum Ledger) | The emitted APO + `BatchAttested` event is the immutable record Archivum witnesses. |

---

## Consequences

### Positive
- **Single proof per day**: 100+ concurrent FeMoco runs collapse to one APO → one `BatchAttested` + one `AnchorSubmitted`.
- **Gas < 200k**: per-run Groth16 verification is eliminated on-chain.
- **No new crypto**: builds on `recursive-prover` and the two existing registries.
- **Traceability**: `member_roots` in the APO map back to individual `Attested` digests; the 055 WORM archive preserves the full event log.

### Negative
- **Aggregation latency**: STARK aggregation for deep batches adds off-chain compute (ADR-PML-069 targets ≤5000ns for ≤100 proofs; the daily window can exceed this, requiring chunked aggregation).
- **Replay/ordering**: `submitBatchAttestation` already guards nullifiers; the batch root must be computed over the *same* ordered set the sidecar anchors.
- **Crate maturity**: `goldilocks`/`pasta-curves` are early-stage (per ADR-PML-069).

### Risks

| **Risk** | **Mitigation** |
| :--- | :--- |
| APO `aggregate_root` ≠ sidecar `batchRoot` (drift) | Compute `batchRoot` from the *same* `Attested` event stream the sidecar reads; add a CI check asserting equality. |
| Daily window > 100 proofs (aggregation depth bound) | Chunk into ≤100-proof APOs and recursively aggregate the chunk roots (reuse `aggregate_rpos`). |
| `batchVerifier` not deployed (address(0) guard in registry) | Registry already no-ops verification when `batchVerifier == 0`; gate the anchor on a successful `BatchAttested` only when the verifier is set. |
| WORM loss between batch and anchor | NATS JetStream at-least-once + the 055 sidecar retry; the APO `member_roots` are the independent check. |

---

## Implementation Phases

### Phase 1: Glue Bin (Week 1)
- Add `crates/recursive-prover/src/bin/batch_anchor.rs` that:
  - loads a JSONL of daily `Attested` digests+meta,
  - wraps each into a `RecursiveProofObject` (`StarkVerifierGadget::wrap_stark`),
  - aggregates via `aggregate_rpos` → `AggregatedProofObject`,
  - prints `aggregate_root` (the `batchRoot`) and writes `aggregated_proof.json`.
- Wire as `[[bin]] name = "batch_anchor"` in `Cargo.toml`.

### Phase 2: On-chain Submit (Week 2)
- A submitter (Rust or the 055 sidecar) calls `AttestationRegistry.submitBatchAttestation(batchProof, batchRoot, runs, sidecarSig)`.
- Assert the emitted `BatchAttested.root == batchRoot`.

### Phase 3: Fold into Daily Anchor (Week 3)
- The 055 `state-anchor` sidecar already builds a combined root from five categories. Add `Run Aggregator Root = batchRoot` as the fifth input (currently `attestations` category in the 055 design).
- `batch_anchor` writes `batchRoot` to a file the sidecar reads, OR the sidecar fetches the latest `BatchAttested` event directly.

### Phase 4: Verification (Week 4)
- Extend `scripts/verify_anchor.py` to also fetch the `BatchAttested` root and assert it equals the `attestations` slice of the reconstructed combined root.
- Kani harness: `aggregate_rpos` returns `Ok` iff all member proofs verify (per ADR-PML-069 §3).

---

## Verification Criteria

- **One APO per day**: `batch_anchor` emits exactly one `aggregated_proof.json` whose `aggregate_root == batchRoot`.
- **On-chain batch**: At least one `BatchAttested` event/day with `root == batchRoot`.
- **Anchor includes batch**: `verify_anchor.py` reconstructs the combined root and the `attestations` category equals `batchRoot`.
- **Gas < 200k**: `submitBatchAttestation` + `AnchorRegistry.submitRoot` combined < 200k (with STARK batching).
- **Cross-layer consistency**: `batchRoot` computed by Rust == `batchRoot` computed by Solidity `_computeMerkleRoot`.

---

## Artifacts

- `crates/recursive-prover/src/bin/batch_anchor.rs` — daily batch→APO→root glue.
- `crates/recursive-prover/Cargo.toml` — `batch_anchor` bin entry.
- Extension to `sidecar/state-anchor/index.ts` — read `batchRoot` as the `attestations` category.
- Extension to `scripts/verify_anchor.py` — assert `BatchAttested.root == attestations` slice.
- This ADR (`docs/adr/proposed/ADR-PML-050-Batch-ZK-Proofs.md`).

---

## Rationale

The "forever immutable" mandate (ADR-PML-055) is incomplete without a *verifiable* run history. By reusing `recursive-prover` to collapse a day's FeMoco attestations into one STARK-backed APO and folding its root into the daily anchor, we make the entire run record as immutable and independently checkable as the operational state — at a gas cost compatible with continuous production anchoring.

---

## References

- `contracts/AttestationRegistry.sol` — `submitBatchAttestation`, `_computeMerkleRoot`.
- `contracts/StarkVerifier.sol` — RISC0/SP1 STARK aggregation.
- `crates/recursive-prover/` — `aggregate-proofs`, `wrap-proof`, `StarkVerifierGadget`.
- `contracts/AnchorRegistry.sol` (ADR-PML-055) — `submitRoot`.
- `docs/adr/completed/ADR-PML-069-Recursive-Proof-Aggregation-Production-Pipeline.md`.
- ADR-PML-055 §2/§3 — daily anchor + < 200k gas budget.
