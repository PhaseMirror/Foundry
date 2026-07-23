# UAC Evolution — Master ADR Plan: From Formally Verified to Formally Adaptive

## Executive Summary

The Universal Atomic Calculator (UAC) has proven that formal verification and
production-scale quantum simulation are compatible. The next evolution
transforms this statically verified system into a **formally adaptive,
autonomously resilient, and cryptographically future-proof** platform. This
Master ADR Plan outlines six enhancements, each with a self-contained decision
record, that deepen operational layers while preserving zero-`sorry` Lean4
proofs, the 100-qudit hard boundary, attestation completeness, and governance
traceability.

The enhancements are phased for risk management: first trust foundation
(post-quantum security, batching), then autonomous verification, then adaptive
operation, and finally reach expansion. Each phase delivers incremental value
and is gated by CI checks that enforce system invariants.

---

## Inviolable Constraints

| **Constraint** | **Enforcement** |
| :--- | :--- |
| **Sorry-bounded boundary** | All new Lean4 theorems must be listed in `alp_sorry_manifest.json` with a paired Rust stub and governance test. CI rejects unmanifested `sorry`. |
| **100-qudit hard boundary** | No active space, circuit, or proof may exceed the (20,20) FeMoco-equivalent CAS envelope. CI rejects any PR that introduces a larger space. |
| **Attestation completeness** | Every production run must be coverable by a verifiable ZK attestation (single Groth16 per run OR batched STARK). The sidecar must attest every run; no omission allowed. |
| **Governance traceability** | Every autonomous action (proof patch, scheduler shift, anomaly flag) must be reconstructible from the WORM ledger + manifest. The system logs all decisions with a trace ID and links to the originating proof or model version. |

| **Invariant 5 — The Anchor Mandate** | Every enhancement must implement a periodic (≤ 1 hour) cryptographic anchoring of its operational state to a dedicated Solidity contract: logs, AI decisions, resource maps, and proof patches. The cost of anchoring is subsidized by the gas reductions from ADR-105 (STARK batching). State roots (governance, orchestrator, chemical rationale, proofs) are aggregated into a single daily STARK proof; total daily anchor cost target is < ~200k gas (≈ < $5). See [ADR-110](ADR-110.md). |

---

## Enhancement Map

| # | ADR | Layer | Enhancement | Primary Benefit | Owner |
|---|-----|-------|-------------|-----------------|-------|
| 1 | [ADR-104](ADR-104.md) | Formal Verification | AI‑Powered Proof Agent (Ax‑Prover / MerLean) | Continuous autonomous verification & vulnerability patching | `the-examiner` |
| 2 | [ADR-105](ADR-105.md) | ZK Attestation | Batch ZK Proofs (STARK Aggregator) | 10–100× gas/on‑chain load reduction | `the-guardian` |
| 3 | [ADR-106](ADR-106.md) | Cryptography | Post‑Quantum Signatures (CRYSTALS‑Dilithium) | Future‑proofing against CRQC attacks | `the-guardian` |
| 4 | [ADR-107](ADR-107.md) | Governance | Predictive Thermal Scheduler & Quantum Anomaly Detection | Proactive optimization & superior anomaly detection | `the-publisher` |
| 5 | [ADR-108](ADR-108.md) | Physics Simulation | Automated Active Space Selection (AEGISS) | Safe expansion to new molecular targets | `the-genius` |
| 6 | [ADR-109](ADR-109.md) | FPGA Orchestration | System‑Level Quantum‑Classical Resource Management | Enhanced hybrid compute efficiency & flexibility | `the-commander` |
| 7 | [ADR-110](ADR-110.md) | Cross-Cutting | UAC State Anchor (Blockchain Anchoring Mandate) | "Forever immutable" operational bedrock for all layers | `the-guardian` |
| 8 | [ADR-111](ADR-111.md) | Governance (Triggered) | Protocol-Level RSA Break Handling (Defensive Disclosure) | Irrevocable public-domain placement + coordinated fail-closed transition | `the-guardian` |

---

## Phased Implementation Roadmap

### Phase A — Trust Foundation (Weeks 1–6)

- **Goal**: Make the attestation layer quantum‑safe and economically viable for
  high throughput. Autonomous actions cannot be trusted on‑chain until these
  are secured.
- **Deliverables**:
  - ADR-106 (Dilithium signatures) integrated into sidecar; dual‑signature
    attestations (ECDSA + Dilithium) optional.
  - ADR-105 (STARK batching) prototype; gas cost benchmarks showing ≥10× reduction.

### Phase B — Autonomous Verification (Weeks 7–12)

- **Goal**: Introduce continuous, machine‑assisted proof generation so new
  surfaces are verified rather than accumulating `sorry` debt.
- **Deliverables**:
  - ADR-104 (AI proof agent) operational; CI uses it to propose proofs for new
    theorems; human review required but reduced.

### Phase C — Adaptive Operation (Weeks 13–20)

- **Goal**: Make the platform self‑optimizing and self‑healing.
- **Deliverables**:
  - ADR-107 (predictive thermal scheduler + VQC anomaly detection) deployed;
    proactive thermal shifts reduce `QuantumM::Collapse` triggers.
  - ADR-109 (system‑level resource manager) integrated; FPGA orchestrator
    dynamically allocates resources across computation stages.

### Phase D — Reach Expansion (Weeks 21–24)

- **Goal**: Widen chemical coverage without breaching the 100‑qudit boundary.
- **Deliverables**:
  - ADR-108 (AEGISS active space selection) integrated; new molecules
    on‑boarded with formal proof that reduction preserves chemical accuracy.

---

## Cross-Cutting Verification Strategy

- **Phase Mirror Loop**: Re‑run `scripts/phase_mirror_loop.py` after each
  phase. New tensions enter the ranked list as `Proposed` levers and exit only
  when discharged.
- **CI Enforcement**: Every PR must pass:
  - `cargo test --workspace --release`
  - `lake build` with all `sorry` declarations tracked in alp_sorry_manifest.json
  - `scripts/verify_manifest.py` to check the sorry manifest is up‑to‑date.
  - `scripts/check_boundary.py` to enforce 100‑qudit limit.
- **WORM Audit**: All autonomous decisions must log a structured event with:
  - `trace_id`, `timestamp`, `action`, `rationale_link` (to model/ proof).
- **Observability**: New Prometheus metrics added for each enhancement (e.g.,
  `uac_ai_proof_attempts_total`, `uac_batch_proof_size`,
  `uac_predictive_shift_count`).

---

## Detailed ADRs

### ADR-104: AI-Powered Proof Agent

**Objective**: Integrate an LLM‑based theorem prover (Ax‑Prover or MerLean)
into the CI pipeline to propose Lean4 proofs for new code, reducing the human
burden of formal verification.

**Motivation**: As the codebase grows, manual proof writing becomes the
bottleneck. An AI agent can generate candidate proofs for simple lemmas, freeing
engineers to focus on complex invariants.

**Non‑Goals**:
- Do not replace human review; all proposed proofs must be reviewed and
  approved before merge.
- Do not use AI to create new `sorry`s; the agent must only propose proofs that
  compile.

**Technical Approach**:
1. **Training/Fine‑tuning**: Fine‑tune a model on our existing `SQD.lean`,
   `Circuits.lean`, etc., as well as Mathlib4.
2. **CI integration**: On each PR, the agent:
   - Identifies unproven lemmas (marked `sorry` or `admit`).
   - Generates up to 3 candidate proofs.
   - Runs `lake build` on each; if a proof compiles, it is attached as a PR comment.
3. **Human‑in‑the‑loop**: An engineer reviews and accepts/rejects; accepted
   proofs are merged and the `sorry` is removed.

**Implementation Phases**:
1. **Week 1–2**: Set up model inference environment (GPU runner) and draft
   prompt engineering.
2. **Week 3‑4**: Integrate with GitHub Actions; proof candidates posted as PR
   comments.
3. **Week 5‑6**: Implement feedback loop: correct proofs are used for
   fine‑tuning; performance metrics tracked.

**Verification**:
- Metric: Percentage of new `sorry`s that are automatically filled within 24
  hours (target > 60%).
- Security: All proof candidates are checked by Lean; unsound proofs fail
  compilation.

**Artifacts**: `scripts/ai_proof_agent.py`, `models/proof_model.pt`, CI
workflow update, metrics dashboard.

**Dependencies**: Lean4 environment, GPU availability, access to training data.

**Risk**: Model may produce unsound proofs that pass type‑checking but are
logically invalid. Mitigation: human review and additional property‑based
tests.

---

### ADR-105: Batch ZK Proofs (STARK Aggregator)

**Objective**: Aggregate multiple FeMoco attestations into a single STARK
proof, reducing Ethereum gas costs and on‑chain storage by 10–100×.

**Motivation**: Per‑run Groth16 proof costs ~500k gas; at 100 concurrent runs,
this is economically unsustainable for high‑volume clients. Batch proof reduces
cost per attestation to <5k gas.

**Non‑Goals**:
- Do not compromise individual attestation verifiability; the batch proof must
  be decomposable into per-run verifications.
- Do not change the `AttestationRegistry.sol` interface; batch proof must be
  submitted as a single transaction.

**Technical Approach**:
1. **Accumulator construction**: Use a STARK (e.g., Winterfell) to prove that a
   list of Groth16 proofs or directly the R1CS satisfiability for multiple runs
   is valid.
2. **Circuit**: Compose a circuit that accepts `N` sets of public signals and
   verifies each individually via repeated pairing checks, but in a single
   polynomial proof.
3. **Sidecar upgrade**: The TypeScript sidecar accumulates proofs in a buffer
   (e.g., 10 runs or 5 minutes) and submits a batch transaction to a new
   `BatchAttestation.sol` contract.
4. **Smart contract**: `BatchAttestation.sol` verifies the STARK proof and
   emits aggregated events; clients can still query individual attestations
   via a merkle root.

**Implementation Phases**:
1. **Week 1‑3**: Prototype STARK circuit for 2‑3 attestations; benchmark gas.
2. **Week 4‑6**: Integrate into sidecar; add accumulation logic and buffering.
3. **Week 7‑9**: Deploy `BatchAttestation.sol` on testnet; run end‑to‑end with
   mock data.

**Verification**:
- Gas savings measured on testnet.
- Formal proof (in Lean4) that batch verification implies individual
  verification.

**Artifacts**: `circuits/batch_attestation.circom` (or STARK code),
`contracts/BatchAttestation.sol`, sidecar update, benchmarks.

**Dependencies**: Winterfell or similar STARK library, Circom/rust.

**Risk**: STARK proof size (~100 KiB) may be large; we can tune the number of
attestations per batch to balance gas and proof size. Initial batch size = 10.

---

### ADR-106: Post-Quantum Signatures (CRYSTALS-Dilithium)

**Objective**: Add CRYSTALS‑Dilithium signatures alongside ECDSA for provider
attestations, future‑proofing against cryptographically relevant quantum
computers (CRQCs).

**Motivation**: ECDSA is vulnerable to Shor's algorithm. Dilithium is
NIST‑approved and offers security against quantum attacks.

**Non‑Goals**:
- Do not remove ECDSA; maintain dual‑signature support for compatibility.
- Do not require clients to upgrade immediately; the contract can accept either
  signature.

**Technical Approach**:
1. **Sidecar integration**: Add Dilithium key generation (using `pqcrypto` Rust
   crate) and signing alongside ECDSA.
2. **Contract upgrade**: Extend `AttestationRegistry.sol` to accept a second
   signature field and verify against a registry of Dilithium public keys.
3. **Key management**: Store Dilithium keys in cloud KMS alongside ECDSA keys;
   rotate periodically.

**Implementation Phases**:
1. **Week 1‑2**: Integrate `pqcrypto` crate into sidecar; generate keys.
2. **Week 3‑4**: Upgrade Solidity contract; add verification logic for
   Dilithium (using the `DilithiumVerifier.sol` generated by the reference
   implementation).
3. **Week 5**: Enable dual‑signature attestations on testnet; monitor
   performance (Dilithium verification is ~10× slower than ECDSA, but
   acceptable).

**Verification**:
- Security: Formal proof that dual‑signature verification is equivalent to
  logical AND of individual verifications (in Lean).
- Performance: Latency increase < 50 ms.

**Artifacts**: Sidecar `dilithium` module, `DilithiumVerifier.sol`, key
rotation procedures.

**Dependencies**: `pqcrypto` Rust crate, Solidity verification library.

**Risk**: Dilithium verification gas cost may be higher than ECDSA; we can offer
clients the option to submit only ECDSA for lower cost, while high‑security
clients opt for Dilithium.

---

### ADR-107: Predictive Thermal Scheduler & Quantum Anomaly Detection

**Objective**: Replace reactive anomaly detection with a predictive scheduler
using LSTM and a Quantum Variational Circuit (VQC) for more accurate, proactive
anomaly detection.

**Motivation**: Current Isolation Forest is reactive; thermal spikes are only
detected after they occur. Predictive scheduler can shift sessions to `d=8`
before breach, preserving throughput.

**Non‑Goals**:
- Do not replace existing Isolation Forest immediately; deploy as a sidecar and
  compare performance.
- Do not require quantum hardware; VQC is simulated for development.

**Technical Approach**:
1. **Predictive Scheduler**:
   - Train an LSTM on historical telemetry (utilization, error rates, session
     counts) to forecast `util` 60 seconds ahead.
   - If forecasted `util > 0.85`, preemptively throttle low‑priority sessions.
2. **Quantum Anomaly Detection**:
   - Use a VQC (e.g., 4 qubits) to encode the 5D telemetry vector into a quantum
     state; measure expectation values as an anomaly score.
   - Train via hybrid classical‑quantum optimization (PyTorch + Pennylane) on
     WORM data.
   - If VQC score exceeds threshold, escalate to ALP.

**Implementation Phases**:
1. **Week 1‑3**: Collect 72h of telemetry; train LSTM and VQC; evaluate
   precision/recall.
2. **Week 4‑6**: Integrate LSTM predictor into FPGA orchestrator; add
   preemptive throttling logic.
3. **Week 7‑9**: Deploy VQC sidecar as a replacement for Isolation Forest
   (initially in shadow mode, logging decisions without action).
4. **Week 10‑12**: Gradual switch‑over; monitor metrics.

**Verification**:
- Precision/recall of VQC ≥ Isolation Forest (target: false‑positive < 0.1%).
- LSTM reduces `QuantumM::Collapse` triggers by ≥50%.

**Artifacts**: `scripts/train_lstm.py`, `scripts/train_vqc.py`,
`models/lstm_model.pth`, `models/vqc_model.pkl`,
`observability/predictive_scheduler.rs`, Grafana panels.

**Dependencies**: PyTorch, Pennylane, NATS integration.

**Risk**: VQC may not outperform Isolation Forest; rollback to Isolation Forest
possible.

---

### ADR-108: Automated Active Space Selection (AEGISS)

**Objective**: Integrate AEGISS (Atomic orbital and Entropy-based Guided
Inference for Space Selection) to automatically reduce large molecular targets
to a CAS(20,20) proxy, enabling expansion beyond FeMoco while respecting the
100‑qudit boundary.

**Motivation**: Clients want to simulate other transition metal complexes.
Manual active space selection is error‑prone and slow; AEGISS automates it with
formal guarantees.

**Non‑Goals**:
- Do not breach 100‑qudit limit; AEGISS must output an active space with ≤69
  qubits.
- Do not require new hardware; AEGISS runs on classical pre‑screening.

**Technical Approach**:
1. **Workflow**: For a new molecule, run a cheap classical DFT calculation to
   obtain orbital energies and entropy proxies. AEGISS selects the active space
   using the entropy‑based criterion.
2. **Validation**: Compare AEGISS‑reduced energies against full CASSCF on a
   small test set (e.g., Fe‑S clusters) to confirm error < 5 mHa.
3. **Integration**: AEGISS output is fed into the existing MA‑VQE pipeline;
   Q‑SQD signatures are generated as usual.

**Implementation Phases**:
1. **Week 1‑3**: Implement AEGISS as a Python library (based on literature);
   test on known molecules.
2. **Week 4‑6**: Write a formal proof (in Lean4) that AEGISS‑selected active
   space preserves chemical accuracy to within 5 mHa (requires bounding the
   truncation error).
3. **Week 7‑9**: Integrate with `qaas_endpoints.rs`; new endpoint
   `/simulate_with_autoreduction` accepts a molecule specification, runs
   AEGISS, then FeMoco simulation.

**Verification**:
- Validation: 20 test molecules, error < 5 mHa vs. full CASSCF (when feasible).
- Formal proof: in `Circuits.lean` or `SQD.lean` (new module
  `ActiveSpace.lean`).

**Artifacts**: `scripts/aegiss.py`,
`lean/SNAPKITTY/SnapKitty/ActiveSpace.lean`, updated `qaas_endpoints.rs`.

**Dependencies**: PySCF or similar for DFT, Lean4.

**Risk**: AEGISS may fail for highly correlated systems; fallback to manual
space selection for those cases.

---

### ADR-109: System-Level Quantum-Classical Resource Management

**Objective**: Elevate the FPGA orchestrator to a full system‑level resource
manager that dynamically allocates resources across computation stages (error
correction, state preparation, measurement) and between sessions.

**Motivation**: Current orchestrator only handles per‑session dimension
shifting. Future workloads may require resource sharing between stages, e.g.,
using idle qubits for error correction while running a VQE.

**Non‑Goals**:
- Do not redesign the FPGA hardware; work within existing capabilities.
- Do not impact the zero‑`sorry` formal guarantees; the resource manager must
  be verifiable.

**Technical Approach**:
1. **Resource abstraction**: Model the FPGA as a set of resources (qudits,
   control units, memory).
2. **Scheduler**: Implement a real‑time scheduler (in Rust) that partitions
   resources among concurrent tasks, respecting dependencies and priorities.
3. **Integration**: Replace the current simple HashMap with a resource‑aware
   allocator that can reserve resources for future stages.

**Implementation Phases**:
1. **Week 1‑4**: Design resource model and scheduler; prototype in Rust.
2. **Week 5‑8**: Integrate into `fpga_pulse.rs`; replace existing
   dimension‑shifting logic.
3. **Week 9‑12**: Add formal proof (in Lean4) that the scheduler never
   deadlocks and respects resource bounds.

**Verification**:
- Throughput impact: should not degrade current 100‑concurrent performance.
- Formal deadlock‑free proof.

**Artifacts**: `src/resource_manager.rs`,
`lean/SNAPKITTY/SnapKitty/ResourceScheduler.lean`, updated integration tests.

**Dependencies**: None beyond Rust.

**Risk**: Scheduler complexity may introduce bugs; extensive property‑based
testing needed.

---

## Phasing and Milestones

| **Phase** | **ADR** | **Milestone** | **Timeline** |
| :--- | :--- | :--- | :--- |
| A | 106, 105 | Dilithium signing active; batch STARK proof on testnet | Weeks 1‑6 |
| B | 104 | AI proof agent generated ≥60% of new `sorry`s | Weeks 7‑12 |
| C | 107, 109 | Predictive scheduler operational; VQC shadow mode; resource manager integrated | Weeks 13‑20 |
| D | 108 | AEGISS endpoint live; first new molecule (e.g., P‑cluster) simulated | Weeks 21‑24 |
| A (cross-cut) | 110, 105 | `AnchorRegistry.sol` live; daily aggregated root anchor < 200k gas | Weeks 1‑6 |

---

## Triggered Events

Certain events are not on the planned timeline but, when they occur, take
precedence and must be executed protocol-first. The primary such event is an
**unconditional RSA break**, handled by [ADR-111](ADR-111.md): it activates the
ACE fail-closed gate for all RSA-dependent modules, anchors an immutable
priority date (ADR-110), and drives defensive publication under the Prime
Materia License (CC BY-SA 4.0) before any coordinated external disclosure.

---

## Risk Register

| **Risk** | **Impact** | **Mitigation** |
| :--- | :--- | :--- |
| AI proof agent produces unsound proofs | High | Human review; property‑based tests on accepted proofs |
| Batch STARK proof size too large | Medium | Optimize number of attestations per batch; use recursive STARKs |
| Dilithium verification gas cost too high | Medium | Offer both ECDSA and Dilithium; let clients choose |
| VQC underperforms Isolation Forest | Low | Keep Isolation Forest as fallback; evaluate in shadow mode |
| AEGISS error exceeds 5 mHa | High | Validate on 20+ molecules; provide manual override |
| Resource scheduler introduces latency | Medium | Extensive benchmarking; optimize with concurrent data structures |

---

## Success Criteria

- **Zero‑`sorry`**: All new proofs compile with no unmanifested `sorry`.
- **100‑qudit boundary**: No PR increases the maximum qudit count.
- **Batch attestation**: First batch submitted on‑chain with ≥10× gas reduction.
- **Predictive scheduler**: ≥50% reduction in `QuantumM::Collapse` events.
- **AEGISS**: At least 3 new molecular targets deployed.

---

## Conclusion

This Master ADR Plan transforms the UAC from a statically verified platform
into a **formally adaptive, autonomous, and future‑proof** system. Each
enhancement is phased, risk‑mitigated, and aligned with the inviolable
constraints that have made the UAC a reference implementation for governed
quantum computing. The Phase Mirror Loop ensures continuous feedback and tension
management, keeping the system honest and mathematically sound.

All artifacts will be archived under the Sedona Spine WORM, maintaining the
7‑year immutable provenance.
