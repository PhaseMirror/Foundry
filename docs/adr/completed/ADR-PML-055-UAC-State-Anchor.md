# ADR-PML-055: UAC State Anchor — Blockchain-Backed Immutable Operational Record

**Status**: Proposed
**Date**: 2026-07-18
**Authors**: `the-guardian`, `the-publisher`
**Dependencies**: ADR-PML-050 (Batch ZK Proofs), ADR-PML-051 (Post-Quantum Signatures), ADR-PML-052 (Predictive Governance), ADR-PML-054 (Resource Management)
**Cross-cutting**: Applies to all operational layers

---

## Context

The Universal Atomic Calculator (UAC) already anchors FeMoco simulation results to the EVM via `AttestationRegistry.sol`. However, **operational provenance**—the history of *why* and *how* decisions were made—remains stored in mutable off-chain WORM storage (Elasticsearch, file systems). This creates a gap: if the WORM storage is compromised, corrupted, or retroactively edited, the integrity of the governance log is broken.

The UAC's mandate of "forever immutable" demands that **every autonomous action**—thermal shifts, AI proof patches, resource allocations, anomaly escalations—be cryptographically anchored to a public, immutable ledger. This ADR institutionalizes a mandatory blockchain anchoring requirement for all operational state, ensuring that the full audit trail is as indestructible as the simulation results themselves.

---

## Decision

We will introduce a **UAC State Anchor** service that periodically hashes and submits a Merkle root of operational state to a new `AnchorRegistry.sol` smart contract. This service runs as a sidecar (co-located with the ZK attestation sidecar) and anchors the following state categories:

| **State Category** | **Content** | **Update Frequency** |
| :--- | :--- | :--- |
| **Governance Root** | Hourly rolling hash of all NarrativeAuditor events (anomaly scores, `SIG_GOV_KILL`, ALP escalations) | Every 60 minutes |
| **Orchestrator Root** | Snapshot of FPGA session dimensions (`d=16` vs `d=8`), resource allocations, utilization | Every 10 blocks (lazy) / daily digest |
| **Chemical Rationale Root** | AEGISS pre-screening data (DFT entropy analysis) for reduced active spaces | Per new molecule submission |
| **Proof Patch Root** | SHA-256 hashes of new Lean theorems or `sorry` manifest changes | Per CI merge |
| **Run Aggregator Root** | Batch Merkle root of all FeMoco attestations in the last 24 hours (to complement `AttestationRegistry`) | Every 24 hours |

---

### Technical Architecture

#### 1. State Aggregation

Each component (NarrativeAuditor, FpgaOrchestrator, AEGISS, CI) emits a structured event containing its current state to a NATS subject:

- `uac.state.governance`
- `uac.state.orchestrator`
- `uac.state.chemistry`
- `uac.state.proofs`
- `uac.state.attestations`

The **State Anchor Sidecar** (TypeScript, same as the ZK sidecar) subscribes to these subjects, collects events within a time window, and constructs a Merkle tree. The root hash is computed as:

```
root = SHA-256(
    governance_root ||
    orchestrator_root ||
    chemistry_root ||
    proofs_root ||
    attestation_root
)
```

#### 2. On-Chain Contract: `AnchorRegistry.sol`

Deploys a simple, gas-optimized contract that:

- Accepts `submitRoot(bytes32 root, uint256 timestamp)`.
- Emits `AnchorSubmitted(root, timestamp, blockNumber)`.
- Maintains a mapping of `blockNumber => root` for historical lookup.
- Uses a `onlySidecar` modifier (authenticated via ECDSA or Dilithium signature) to prevent spam.

**Gas Strategy**: With ADR-PML-050 (STARK batching), we can submit multiple roots (e.g., all categories) in a single batch proof, keeping gas below 200k.

#### 3. Schedule

- **High-frequency**: Orchestrator state (snapshots every 10 blocks) anchored lazily via a digest accumulated in an off-chain buffer and submitted hourly.
- **Daily Anchor**: A comprehensive root of all state categories is submitted at UTC 00:00 every day. This serves as the single source of truth for "what the UAC knew and did" on that day.

#### 4. Verification

Off-chain tooling (e.g., `scripts/verify_anchor.py`) will allow anyone to:

- Fetch the on-chain root for a given date.
- Reconstruct the Merkle tree from the WORM archive.
- Verify that the reconstructed root matches the on-chain root.

This creates a **cryptographic proof of existence** for every operational event, independent of the WORM storage provider.

---

### Integration with Existing ADRs

| **ADR** | **How This ADR Extends It** |
| :--- | :--- |
| ADR-PML-050 (Batch ZK Proofs) | The daily attestation root is *included* in the daily anchor root; this creates a single, unified proof of all runs and governance events. |
| ADR-PML-051 (Post-Quantum) | The anchor submission signature will be dual-signed (ECDSA + Dilithium) to future-proof the immutable record. |
| ADR-PML-052 (Predictive Governance) | The LSTM and VQC decisions are emitted to `uac.state.governance`, ensuring the AI's *rationale* is anchored. |
| ADR-PML-054 (Resource Manager) | The orchestrator's session state is emitted to `uac.state.orchestrator`; any dispute about resource allocation can be settled on-chain. |
| ADR-PML-049 (AI Proof Agent) | CI commits that add or modify Lean theorems trigger an event to `uac.state.proofs`; the exact state of the codebase at that commit is anchored. |
| ADR-PML-053 (AEGISS) | The AEGISS pre-screening data (DFT entropy) is hashed and emitted to `uac.state.chemistry`; the reduction rationale is permanently anchored. |

---

## Consequences

### Positive

- **Forever immutable governance**: All operational decisions are anchored to the blockchain, creating a legally defensible audit trail.
- **Cryptographic independence**: The system no longer relies on a single WORM storage provider; the on-chain root is the ultimate source of truth.
- **Enhanced client trust**: Clients can independently verify that their run's context (thermal state, resource allocation, anomaly flags) was not retroactively altered.
- **Cross-layer alignment**: Forces all teams to produce deterministic, hashable state summaries, improving system observability.

### Negative

- **Implementation complexity**: Each component must now emit structured state events; the sidecar must handle NATS subscription and aggregation.
- **Gas costs**: Even with batching, daily anchoring costs ~$5–$10/day (at current ETH prices); this is acceptable for a production platform.
- **Latency**: State anchoring introduces a slight delay (up to 1 hour) before a decision is cryptographically sealed; this is acceptable for non-critical operations.

### Risks

| **Risk** | **Mitigation** |
| :--- | :--- |
| On-chain root mismatches off-chain state due to event loss | NATS JetStream with at-least-once delivery; retry logic in sidecar. |
| Smart contract vulnerability | Formal verification of `AnchorRegistry.sol` in Lean4 (new module `AnchorRegistry.lean`)—part of ADR-PML-055. |
| Gas price spikes | Use a gas price oracle; anchor only during low-traffic periods (e.g., UTC night). |

---

## Implementation Phases

### Phase 1: Contract & Sidecar Skeleton (Weeks 1–2)

- Draft `contracts/AnchorRegistry.sol` (ERC-165 compliant).
- Scaffold TypeScript sidecar in `sidecar/state-anchor/`.
- Implement NATS subscription for `uac.state.*` subjects.
- Add ECDSA authentication.

### Phase 2: Component Emission (Weeks 3–4)

- Extend NarrativeAuditor to emit `GovernanceEvent` to NATS.
- Extend FpgaOrchestrator to emit `OrchestratorState` (snapshot of session dimensions).
- Extend AEGISS script to emit `ChemistryRationale`.
- Extend CI to emit `ProofPatch` on every merge.

### Phase 3: Aggregation & Submission (Weeks 5–6)

- Implement Merkle tree construction.
- Add daily submitter (cron job) that calls `AnchorRegistry.submitRoot`.
- Integrate with ADR-PML-050 (STARK batching) to reduce gas costs.

### Phase 4: Formal Verification (Weeks 7–8)

- Write `AnchorRegistry.lean` proving contract invariants (root uniqueness, no replay, etc.).
- Integrate with `build.rs` to ensure the Lean proof compiles.

---

## Verification Criteria

- **On-chain anchor event**: At least one `AnchorSubmitted` event emitted per day on testnet.
- **Reconstruction**: `scripts/verify_anchor.py` successfully reconstructs the root from off-chain WORM data.
- **Cross-layer consistency**: The governance root includes the exact same anomaly scores as the Elasticsearch logs.
- **Gas cost**: Daily anchor gas < 200k gas (with STARK batching).

---

## Artifacts

- `contracts/AnchorRegistry.sol`
- `sidecar/state-anchor/index.ts`
- `lean/SNAPKITTY/SnapKitty/AnchorRegistry.lean`
- `scripts/verify_anchor.py`
- Updated WORM archival script to include the on-chain root hash.
- Grafana panel showing "Last Anchor Block" and "Anchor Verification Status".

---

## Rationale

This ADR institutionalizes the "forever immutable" principle across all operational layers. By anchoring the full state—not just results—we close the loop on provenance. The UAC is no longer a "black box" that occasionally produces verified outputs; it is a fully auditable, self-documenting system whose entire decision history is as immutable as the chemistry it simulates.

---

## References

- ADR-PML-050 (Batch ZK Proofs) – for gas optimization.
- ADR-PML-051 (Post-Quantum Signatures) – for future-proof signing.
- `AttestationRegistry.sol` – existing on-chain contract.
- Merkle tree specification – as used in batch attestations.

---

## Changelog

- **2026-07-18**: Initial draft.
