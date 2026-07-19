# ADR Index — Universal Atomic Calculator (UAC)

Machine-checkable Architecture Decision Records for the Phase Mirror Prime UAC.
Artifacts are organized by lifecycle status under this directory:

| Directory | Meaning |
| :--- | :--- |
| `proposed/` | Drafted, not yet accepted. Open for review. |
| `accepted/` | Approved and owned; implementation in progress or complete. |
| `completed/` | Shipped and verified (includes production-implementation ADRs ADR-03x–073). |
| `uncategorized/` | Parked / not yet sorted into the lifecycle above. |

The auto-generated master plan (`accepted/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`)
tracks document-vs-Lean4 dissonance and is produced by `scripts/phase_mirror_loop.py`.

## Status of ADR-PML-055 (UAC State Anchor)

- **File**: `proposed/ADR-PML-055-UAC-State-Anchor.md`
- **Status**: `Proposed` — design accepted for implementation; **offline-validated**.
- **Related**: `proposed/ADR-PML-050-Batch-ZK-Proofs.md` (batch attestations → single STARK APO → fold root into the daily anchor).
- **Artifacts implemented**:
  - `contracts/AnchorRegistry.sol` — on-chain anchor (compiles; `authorizedSidecars` allowlist + ECDSA `onlySidecar`).
  - `sidecar/state-anchor/index.ts` — NATS JetStream aggregation + per-category Merkle roots + combined SHA-256 root (typechecks).
  - `lean/gated/SNAPKITTY/SnapKitty/AnchorRegistry.lean` — Lean 4 formal verification (builds; replay / zero-root / auth / uniqueness / monotonicity).
  - `scripts/verify_anchor.py` — WORM reconstruction vs on-chain root.
  - `scripts/anchor_math.py` — canonical root math (parity with the sidecar via `ethers.keccak256`).
  - `scripts/mock_state_emitter.py`, `scripts/test_state_anchor.sh` — offline end-to-end harness.
- **Validation**: `scripts/test_state_anchor.sh` exits 0; `verify_anchor.py --onchain-root <expected>` reports `MATCH — operational record is cryptographically consistent` (15 events, reconstruction == expected combined root).
- **Not yet done (gates `accepted`→`completed`)**:
  - Live on-chain submission not executed here (no `anvil`/`forge`/`cast`/`docker`/`nats-server` in this environment). `test_state_anchor.sh` auto-runs the on-chain branch once those tools are on PATH.
  - No daily cron / K8s CronJob wired to the sidecar in production.
  - No Grafana "Last Anchor Block / Verification Status" panel.

## Status of ADR-PML-050 (Batch ZK Proofs)

- **File**: `proposed/ADR-PML-050-Batch-ZK-Proofs.md`
- **Status**: `Proposed` — design grounded in the existing `recursive-prover` crate + `AttestationRegistry.submitBatchAttestation` + ADR-055 `AnchorRegistry`.
- **Artifacts implemented**:
  - `crates/recursive-prover/src/bin/batch_anchor.rs` — daily FeMoco batch → APO → `batch_root` (builds + smoke-tested; 3 attestations → valid APO with 3 member roots, `batch_root` computed byte-identical to `AttestationRegistry._computeMerkleRoot`).
  - `crates/recursive-prover/Cargo.toml` — `batch_anchor` bin entry.
- **Design note**: two distinct roots — `batch_root` (chained keccak over per-run `(digest,ts,consent,nullifier)`, the value fed to the ADR-055 anchor `attestations` category AND checked by `submitBatchAttestation.batchMerkleRoot`) vs the APO `aggregate_root` (the STARK proof commitment, keccak over member `inner_root`s). They are cryptographically linked (each member root is a prefix of the `batch_root` chain) but not byte-equal; the anchor uses `batch_root`.
- **Not yet done (gates `accepted`→`completed`)**: wire `batch_anchor` output into the ADR-055 sidecar's `attestations` category; on-chain `submitBatchAttestation` submitter; CI gas check < 200k.

## All ADRs (by directory)

See `proposed/`, `accepted/`, `completed/`, `uncategorized/` for the full set.
Highlights:
- `proposed/ADR-PML-055-UAC-State-Anchor.md` — current focus (see above).
- `accepted/ADR-113-CI-Ledger-Anchoring.md` — complementary CI→ledger witness anchoring.
- `completed/ADR-067-Archivum-Immutable-Ledger-Production-Deployment.md` — immutable ledger deployment this anchors into.
- `completed/ADR-069-Recursive-Proof-Aggregation-Production-Pipeline.md` — batch/STARK aggregation (next lever per ADR-PML-050).
