# Legalese Scopist: Agent Contract

## Sedona Spine Mandate
The Engine (Rust) + SDK (TS/WASM) is the **sole mandatory source of truth** for all ESI retention, litigation hold, and spoliation risk logic.

## [PRESERVATION ALERT] Protocol
Every preservation alert must adhere to this exact protocol. Agents must never independently calculate or override the engine-computed risk levels (Critical, High, Medium).

### UAC Preservation Alert Sub-Protocol
For Universal Atomic Calculator (UAC) tasks, the protocol ensures:
- All UAC computational substrates MUST route through the path: Sedona Spine (Rust) → SDK → Contract → UI.
- The UAC must operate with prime-indexed invariants, zero-drift, and formal Lean 4 proofs (no Mathlib, no sorry).
- Self-simulation must commute with Phase Mirror Φ(e) = -e (exponent negation on signatures) and strictly conserve multiplicity M(A).
- **Sedona Spine Governance Protocol**:
  - **Read-Only Facts**: UAC outputs MUST be parsed to an immutable `ReadOnlySignatureFact` without mutable assumptions.
  - **Dual-Gate CI**: Formal Lean L0 invariants MUST be enforced before Rust fact routing.
  - **L0 Enforcement**: Any mutable attempt or norm violation MUST fail-closed.
  - **Phase Mirror Levers**: Explicit dissonance (hardware error vs exact) MUST be resolved via an explicit physical error witness (e.g., 1.3 mHa for H2) and rollback without approximation leakage. Sedona Phase Mirror duality ($\Phi(e) = -e$) serves as the L0 governance layer: it enforces symmetry in read-only facts, preserves norm (M-conservation), and commutes with dependent casts. This involution ($\Phi \circ \Phi = s$) keeps the `3900` H2 bound immutable under agent auditing.
  - **Neutral-Atom Calibration Protocol**: Hardware errors (e.g., Pasqal Orion CZ fidelities, ZNE mitigation, and blockade radius mappings) MUST be bound via an explicit mathematical `H2ErrorWitness` tolerance check, maintaining exact L0 fail-closed semantics across varying calibration states.
  - **Witness Sealing Workflow**: UAC H2 outputs MUST be parsed to an immutable `ReadOnlySignatureFact`. All calibration parameters ($R_b$, $\alpha_{ZNE}$) MUST be sealed via integer-only scaling multipliers to prohibit float approximations from compromising the Sedona Spine invariant bounds. The L0 parameter explicitly maps physical variance through the pure `Nat` scaling formula (`exactZneTolerance 1300 3`), locking the maximum permitted drift unconditionally at `3900`. This bound is dynamically preserved via generalized hardware variance handling across arbitrary measurement differences (e.g., $measuredNorm \neq norm$). Dual-gate CI enforces the exact Lean proof prior to Rust fact routing.
  - **L0 Agent Firewall & FFI-Validated Ecosystem Protocol (ADR-010)**: The exact `3900` ceiling is sealed as an unconditional L0 firewall rule across all LLM interaction interfaces, external Qiskit simulator scaling hooks, and massive, unbounded agent arrays. As formally proven via the explicit `ecosystem_deployment_witness` test case, any arbitrary deployment of stochastic agents (`∀ out ∈ ecosystem`) is mathematically constrained by the strict L0 limit via `decide` computational reduction. The Lean 4 kernel actively performs beta/delta/iota reduction on the core `Nat.decLe` instance, unfolding it via structural recursion to `true`. This proven numerical boundary is dynamically communicated to the engine via exact Rust FFI (`lean_ecosystem_witness_extract_bound() -> u32`). The L0 invariant is a non-negotiable floor: exact Nat scaling, Phase Mirror involution, and fail-closed `QiskitReadOnlyFact` immutability via FFI binding. Any deployment operation declaring a value `> 3900` MUST trigger a hard, synchronous `SIG_GOV_KILL` rejection. Lean formally guarantees via native `Decidable` execution that unbounded stochastic variance within ecosystem deployments cannot mutate or circumvent the exact `Nat` bounds, effectively extracting the mathematical truth natively into Rust memory without bridging abstractions. This end-to-end formal pipeline fully seals the governance boundary, authorizing live generalized ecosystem deployment.
  - **Gate 0.5 (Fitting Check)**: Any proposed state update MUST satisfy `Δ_fit = R(t) - R(t-1) + contraction_margin ≥ 0` prior to envelope evaluation, explicitly rejecting operations that degrade established resonance fitting without a commensurate increase in contractive slack.
  - **Gate 0.75 (Ṛta Metric Bounds Check)**: The dynamic dissonance is measured via `D_Ṛ(s) = || s - Fit(s) ||_M`. Any proposed state where `D_Ṛ(s) > ε_max` MUST be hard-rejected as an irreversible rupture, ensuring un-fittable states never breach the Bindu convergence basin.

## Agent Operational Integrity
All AI-generated work product touching ESI must satisfy the provenance chain:
`Policy -> Event Log -> Kernel Computation -> Narrative`

Any deviation is a breach of the Sedona Spine mandate.

---

## FFI L3 Failure Handling (ADR-XXX)

### Classification
RAII wrapper failures (double-free, use-after-free, leak) are **L3-lever-eligible** but **not L0-adjacent**. The compilation unit completes while emitting a mandatory dissonance report.

### Required Fields for L3 FFI Violations
Every FFI dissonance report MUST include:
- `signal_id`: `"FFI_RUST_LEAN_VIOLATION"` (auto-generated)
- `owner`: `"Compiler Engineering"` (non-overrideable)
- `metric`: `"test_lean_rc.rs harness coverage 100%"` (non-overrideable)
- `horizon`: `"7 days"` (SLA for resolution)
- `escalation_slapath`: `"L3 -> L0 review"` (on ignored lever)

### Non-Override Rule
Ignored L3 FFI levers bind subsequent L0 reviews. The HoE (Highest Order Executive) trigger monitors accumulated unresolved FFI dissonances.

### Secondary L0 Gate
When an L3 FFI violation is detected:
1. The compilation unit **completes** (no SIG_GOV_KILL)
2. A dissonance report is emitted to `audit_ledger`
3. If unresolved for > 24 hours, the HoE trigger forces a secondary L0 gate review
4. Secondary gate can engage `SIG_GOV_KILL` if cumulative FFI violations indicate systemic drift

### Dissonance Report Schema v1.1.0
```json
{
  "signal_id": "FFI_RUST_LEAN_VIOLATION",
  "severity": "high",
  "summary": "Double-free detected in LeanOwned Drop",
  "owner": "Compiler Engineering",
  "metric": "test_lean_rc.rs passes",
  "horizon_days": 7,
  "escalation_slapath": "L3 -> L0 review",
  "witness_data": {
    "drop_sequence": [...],
    "refcount_delta": -1,
    "allocation_trace": "..."
  }
}
```
