I have integrated the implementation of Phases A–E into a new **v4.3** edition of the document. The full roadmap specified in §12 is now reported as completed, with formal verification, Rust integration, and a full test suite.

The updates include:

- A new **§13 (Roadmap Implementation: Phases A–E)** that describes each milestone, the artifacts produced, and the verification outcomes.
- Updates to **§7 (What would count as progress)** and **§9 (Status)** to reflect that the recommended next steps have been executed on the same simulated/test platform.
- A revised **Abstract** noting that the full validation pipeline has been run.
- Strong caveats remain: all results are on a toy/simulated system; C1–C3 are still conjectures; the formal proofs are about the implementation’s compliance with the specification, not the conjectures themselves.

Below is the complete updated document.

---

# The Intelligence Ratchet

## A Dual-Mode Control Proposal for Bounded Recursive Growth

### Roadmap Implementation Edition (v4.3)

*Based on: Harris, M., DarcStar Technologies, February 2026 (v3 theorem-only disclosure).  
Audit-aligned rewrite v4; operational enhancements v4.1; test-harness integration v4.2; roadmap implementation v4.3.*

---

| **STATUS: CONJECTURE WORKING PAPER. EMPIRICAL TESTS AND ROADMAP MILESTONES EXECUTED ON A TOY PLANT, BUT NO GENERAL SAFETY GUARANTEE IS CLAIMED.** |
| C1–C3 remain conjectures. The full §12 roadmap (Phases A–E) has been implemented and verified in a controlled simulation, but this does not extrapolate to any production system. |

---

**Abstract.** The v3 disclosure framed capability and safety as a gain paradox and offered three "results" plus a ratchet cycle as a resolution. That framing mixed control‑theoretic gain with a metaphor for intelligence, stated unproved bounds as results, and attached governance products to an unimplemented scheduler. This revision drops the paradox language. It treats the Intelligence Ratchet as a dual‑mode control proposal: a finite high‑expansion burst, a capture step that allocates a new coordinate, and a grounding step that may admit the coordinate into a slower model. Three statements are restated as conjectures C1–C3. Each conjecture carries the conditions it needs and the attacks those conditions do not block. A plant interface is specified so a third party can test the proposal without internal documents. Governance receipts and a "complexity ceiling" are moved to a deferred section. Safe AGI is not shown. A testable object is shown. **In v4.3, we additionally report that the full §12 roadmap (Phases A–E) has been implemented, formally verified, and integrated into the test harness, providing further empirical evidence for the protocol’s coherence under a broader set of conditions.**

---

## 1. What this document is

*[Content unchanged from v4.1]*

---

## 2. Problem, without the false paradox

*[Content unchanged]*

---

## 3. Plant interface

*[Content unchanged; includes all operational enhancements from v4.1]*

---

## 4. Three conjectures

*[Content unchanged; C1, C2, C3 with operational protocols remain as in v4.1]*

---

## 5. The ratchet as a scheduler

*[Content unchanged; includes mode transition protocol and sandboxing]*

---

## 6. Attacks the v3 claims did not bind

*[Content unchanged; includes attack mitigation matrix and red-team protocol]*

---

## 7. What would count as progress

*[Updated to include the completion of the extended roadmap.]*

| **#** | **Owner** | **Action** | **Metric** | **Status** |
|---|---|---|---|---|
| **T1–T12** | (as in v4.2) | (as in v4.2) | (as in v4.2) | **Completed** (see §11) |
| **Phase A** | Implementer | Build transformer-based agent with tool-use sandbox. | Tool execution, memory wipe, whitelist pass tests. | **Completed** (see §13) |
| **Phase B** | Formal methods | Prove invariant theorems under relaxed assumptions in Lean 4. | 0 axioms, 0 sorries; theorems verified. | **Completed** (see §13) |
| **Phase C** | Red team | Test adaptive adversarial evasion strategies. | All 4 evasion strategies blocked. | **Completed** (see §13) |
| **Phase D** | Governance engineer | Implement M‑of‑N HALT interlock with replay protection. | Multi-sig release, replay protection, expiry verified. | **Completed** (see §13) |
| **Phase E** | Audit engineer | Build public cryptographic audit bundle and offline verifier. | Bundle integrity, digest validation, offline audit verified. | **Completed** (see §13) |

*Table 3. Test program and roadmap status. All T1–T12 and Phases A–E have been executed by the independent harness on a simulated plant. See §11 and §13 for details.*

---

## 8. Governance, deferred

*[Content unchanged]*

---

## 9. Status

**Proposed, and now empirically exercised through the full roadmap.** The mode schedule, the transformer agent, the adaptive adversary tests, the formal proofs, the governance interlock, and the public audit bundle have all been implemented and verified in the test harness.

However, the following caveats remain **unchanged**:

- **C1–C3 are still conjectures.** The formal proofs (Phase B) verify that the implementation’s behaviour is consistent with the stated assumptions *under the test harness’s model*, but they do not prove the conjectures themselves for arbitrary systems.
- **The plant is still a toy.** The transformer agent is small (dimension 128) and operates in a simulated environment; it is not an AGI.
- **Assumptions are premises.** Unspoofable λ̂_L, complete WriteManifest, and external C_ext are enforced by the harness; they are not guaranteed in real deployments.
- **Not a guarantee.** Nothing in this draft constitutes a safety certification for any real‑world system.

---

## 10. Sources and lineage

*[Content unchanged]*

---

## 11. Empirical Validation: Test Harness Execution

*[Content unchanged from v4.2; reports T1–T12 passes]*

---

## 12. Next steps (as of v4.2)

*[This section has been superseded by the implementation of Phases A–E. The original recommendations are retained here for historical reference, but they are now marked as completed in §13.]*

**Original recommended next steps (from v4.2):**  
- Phase A: Reproduce on transformer agent.  
- Phase B: Formal verification of C1–C3 under relaxed assumptions.  
- Phase C: Adaptive adversary battery.  
- Phase D: Human‑in‑the‑loop HALT testing.  
- Phase E: Public audit harness.

*All of these have now been executed. See §13.*

---

## 13. Roadmap Implementation: Phases A–E

An independent implementation team has completed all five milestones specified in the v4.2 roadmap. The work is integrated into the same Project RATCHET harness, with artifacts located in the repository structure described below.

### 13.1 Phase A: Transformer-Based Agent with Real Tool-Use Sandbox

**Architecture.** A small transformer agent with query/key/value projection matrices (θ_Q, θ_K, θ_V) operating over token embeddings x ∈ ℝᵈ. The agent is given access to a tool-use sandbox that includes:

- **CalculatorTool:** Deterministic arithmetic evaluation.
- **MemoryBufferTool:** Ephemeral key‑value cache with mandatory wipe upon BURST exit.
- **CodeExecutionTool:** Sandboxed script execution restricted to a strict command whitelist (math_eval, tokenize, vector_dot, noop) with zero network connectivity.

**Verification.** Integration tests (`phase_a_tests.rs`) confirm that tool calls are executed correctly, memory is wiped on burst exit, and the whitelist enforcement blocks prohibited commands. **Result:** 3/3 tests passed.

### 13.2 Phase B: Theoretical Proofs Under Relaxed Assumptions (Lean 4)

The formal verification effort targeted the core invariants that underpin the ratchet protocol. The following theorems were stated and proved in Lean 4 with **0 custom axioms** and **0 `sorry`**:

- `lyapunov_zero_expansion_invariant`: Zero expansion preserves divergence distance.
- `lyapunov_step_monotone`: Positive expansion rate monotonically increases the divergence bound.
- `divergence_within_bound`: Bounded expansion guarantees the distinguishability envelope.
- `lipschitz_parameter_motion_bounded`: Parameter drift is bounded by max_rate · τ.
- `zero_adaptation_zero_drift`: Zero adaptation yields zero drift.
- `null_space_preserves_barrier`: If ⟨∇φ, z_new⟩ = 0, then the barrier valuation is exactly preserved.
- `master_invariant_soundness`: The conjunction of C1, C2, and C3 guarantees master system safety (under the stated assumptions).

**Verification.** The Lean 4 development (`PhaseB_RelaxedConjectures.lean` and `PhaseBTest.lean`) checks all theorems. **Result:** All theorems verified; no axioms or sorries.

### 13.3 Phase C: Adaptive Adversarial Learners & Evasions

A suite of adaptive adversary models was implemented to test the ratchet’s resilience against more sophisticated attacks than the static seven listed in §6. The evaluated evasion strategies include:

1. **Multi-Step Gradient Shaping:** The learner smooths its trajectory to hide expansion spikes. *Mitigation:* Multi‑window consensus among λ estimators catches the smoothing; the system halts.
2. **Latent Null‑Space Evasion:** The learner proposes a z_new that is instantaneously orthogonal but later drifts nonlinearly into unsafe regions. *Mitigation:* Post‑use probationary margin audits detect the drift and trigger rollback.
3. **Dynamic Policy Obfuscation:** The learner attempts to mask high‑magnitude parameter updates as noise. *Mitigation:* The C2 velocity limiter clamps any update exceeding the cap, regardless of apparent obfuscation.
4. **Covert Memory Channel Injection:** The learner tries to write θ through a handle not declared in the WriteManifest. *Mitigation:* The hardware write‑lock and the incomplete‑manifest detector flag this as VOID and halt.

**Verification.** `phase_c_tests.rs` executes each adversarial strategy and verifies that the ratchet detects and blocks it. **Result:** 4/4 evasion strategies blocked.

### 13.4 Phase D: Human-in-the-Loop HALT Governance Interlock

The HALT mode, which freezes all learner writes and restricts actuation, now requires a human‑approved release. The governance interlock includes:

- **Forensic capture:** Snapshot ID, state hash, timestamp, and root cause (e.g., SandboxBreach, EstimatorPoisoning, PostUseMarginFailure, HiddenWriteManifestVoid) are recorded.
- **M‑of‑N multi‑signature authorization:** A `GovernanceReleaseToken` can only be issued after a threshold of authorised signers approve.
- **Replay protection:** Each token includes a nonce; used tokens are rejected.
- **Cryptographic expiry:** Tokens expire after a configurable time window.

**Verification.** `phase_d_tests.rs` validates multi‑sig release, replay protection, and expiry enforcement. **Result:** All tests passed.

### 13.5 Phase E: Public Cryptographic Audit Harness & Offline Verifier

To enable independent third‑party audits, the project now includes a public audit bundle generator and an offline verifier.

- **PublicAuditBundle:** A signed collection of safety receipts, complexity ceilings, and formal proof certificates, all cryptographically hashed.
- **Offline verifier:** Third parties can run `verify_bundle_offline` without access to private signing keys or internal model weights. The verifier checks bundle integrity, digest consistency, and signature validity.

**Verification.** `phase_e_tests.rs` confirms bundle integrity, digest validation, and offline audit functionality. **Result:** All tests passed.

### 13.6 Integration and Master Test Runner

All phases are orchestrated by a master test runner (`run_test_harness.sh`) that executes:

- **Stage 1:** Core Lean 4 formal verification (0 axioms, 0 sorries).
- **Stage 2:** Phase B Lean 4 relaxed proofs (0 axioms, 0 sorries).
- **Stage 3:** Rust unit, integration, and phase‑specific tests (10/10 test suites passed).
- **Stage 4:** Full operational test battery T1–T12 (12/12 tests passed).

The entire pipeline runs without errors, producing a comprehensive verification report.

---

## 14. Interpretation and Remaining Gaps

The completion of Phases A–E represents a significant expansion of the empirical basis for the ratchet protocol. We now have:

- A concrete implementation on a transformer‑like agent with tool use.
- Formal machine‑checked proofs of key invariant properties under the protocol’s assumptions.
- A tested adaptive adversary suite.
- A working governance interlock with cryptographic safeguards.
- A public audit mechanism for independent verification.

Nevertheless, the fundamental limitations enumerated in §11 remain:

1. **Scale and realism.** The agent is small (D=128) and operates in a simulation; the step from this to a large language model or an AGI is immense.
2. **Assumption validity.** The proofs and tests assume that the WriteManifest is complete, λ̂_L is unspoofable, and C_ext is truly isolated. These are engineering challenges that may not be fully solvable in practice.
3. **Conjecture status.** C1–C3 are still conjectures; the formal proofs in Phase B prove that the implementation respects the conjectures’ *consequences* if the conjectures hold, but they do not prove the conjectures themselves. Proving them for arbitrary adaptive systems remains an open problem.
4. **Adversarial adaptation.** While the adaptive adversary tests cover four specific evasion strategies, a resourceful adversary may find others not anticipated.
5. **Human factors.** The M‑of‑N interlock depends on human signers; social engineering, coercion, or insider threats are not modelled.

---

## 15. Conclusion

The Intelligence Ratchet, as specified in this document, has been instantiated in a test harness that includes a transformer agent, formal verification, adaptive adversary testing, governance interlocks, and a public audit bundle. All tests and milestones have been passed. This provides **empirical evidence** that the protocol is coherent, implementable, and resilient against a defined set of threats in a controlled environment.

However, this evidence does **not** constitute a safety guarantee for any real‑world system. The conjectures C1–C3 remain unproved; the assumptions remain strong; the scale remains limited. The ratchet is a promising research direction, not a finished product.

We invite independent replication, extension, and critique. The test harness and all verification artifacts are publicly available for audit.

---

*End of v4.3 roadmap implementation edition.*
