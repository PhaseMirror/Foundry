# ADR-ALP-003: Atomic Language Processing Lean 4 Formalization Plan

## Status
Proposed

## Owners
- **Stack Owner**: Substrates / Lean Formalization Lead
- **Budget Owner**: Substrates Lead

## Context

This document constitutes the formalization plan for the complete semantic
specification of the Atomic Language Policy (ALP) subsystem in Lean 4. It is
produced in response to the project sweep conducted on 2026-06-27, which
identified a critical gap between the informal Rust implementation and the
constitutional governance requirements.

### Current ALP Subsystem State

**Rust Implementation**: `models/the-commander/crates/alp/`  
**Lean Formalization Target**: `Prime/substrates/lean/ALP/`  
**Rust Counterpart Ignition Crate**: `Prime/pirtm-candle/`

The ALP crate (`multiplicity-alp`) provides:
- `PolicyEngine` struct wrapping a `ConstitutionModel`
- `Action` type (id, payload, mutating, server_binding)
- `AdmissibilityReport` (allowed: bool, reason: String)
- `TrustLevel` enum (Internal / External)
- Experimental `GraphemeDecomposer` with PETC vector encoding

**Critical Gap**: `PolicyEngine::validate_action()` (lines 37-47 of `src/lib.rs`)
is a mock implementation returning hardcoded `allowed: true`. Per L0 Invariant
#3, constitutional validation (`constitution.validate()`) MUST be called by the
`PolicyEngine` before admitting any action.

### Constitutional Frame

All ALP behavior derives from the Ξ-Constitution as encoded in
`models/the-commander/crates/common/src/constitution.rs`:

```
ConstitutionModel.validate() checks:
  L0-1: state_norm is finite and positive
  L0-2: drift_rate < threshold
  L0-3: All 10 critique gates pass
  L0-4: Prime gate values are prime
  L0-5: contractivity_score ∈ (0, 1]
  L0-6: Kill switch not active
  L0-7: Circuit breaker not tripped (consecutive_failures < 3)
  L0-9: Proof anchor recognized
```

### Existing Lean 4 Infrastructure

Lean 4 formalizations exist in two locations but contain NO ALP semantics:

1. `Prime/projects/genesis-ode/src/` — 16 files formalizing ADRs,
   governance checkers, Kantian tests, and BRA verification. Style is
   `structure` + `def` + `theorem sorry` (declarative, unproven claims).

2. `models/agiOS/src/governance_consumers/observatory/PhaseMirror/` — 30+
   files formalizing mathematical foundations:
   - `AffineCore/PolicyProjector.lean` — projection onto closed convex
     feasible sets, nonexpansive mapping theorem (unproven)
   - `AffineCore/UniformContraction.lean` — contraction mappings
   - `Foundations/Primes.lean` — prime uniqueness
   - `L0Invariants/Nonce.lean` — nonce injectivity
   - `Dissonance/Detection.lean` — dissonance detection
   - `FockContraction.lean`, `Semantics.lean`, `Lawfulness.lean`

Both projects use Mathlib, Lake build system, and a common style of
`structure` / `theorem` declarations with `sorry` placeholders.

## Decision

ALP policy semantics will be fully formalized in Lean 4 as the authoritative
specification against which the Rust implementation is verified. The
formalization is decomposed into eight sequential ADRs, each producing
compilable Lean code and a member of the `sorry`-free proof obligation set.

### Formalization Modules

The Lean 4 ALP library will reside at:

```
Prime/substrates/lean/ALP/
├── Lakefile.lean                    # Build config, Mathlib dep, reference to root lakefile.toml
├── Basic.lean                       # Type aliases, imports
├── Types/
│   ├── Action.lean                  # Action record w/ properties
│   ├── TrustLevel.lean              # TrustLevel enum + properties
│   └── AdmissibilityReport.lean     # Report record + props
├── Constitution/
│   ├── Model.lean                   # ConstitutionModel record
│   └── L0_Invariants.lean           # L0-1 through L0-9 as predicates
├── PolicyEngine/
│   ├── Core.lean                    # PolicyEngine record + validate_action spec
│   ├── Admissibility.lean           # Admissibility semantics (allowed ↔ invariant pass)
│   └── Proofs.lean                  # Core theorems about PolicyEngine
├── Contracts/
│   ├── NonBypassability.lean        # ALP gate cannot be circumvented
│   └── TrustArbitration.lean        # Internal vs External routing theorems
├── MCP/
│   └── GovernanceBinding.lean       # MCP tool calls must clear ALP gate
├── Archivum/
│   └── WitnessContract.lean         # UnifiedWitness invariants
├── Candle/
│   └── PirtmBridge.lean             # Lean specs for pirtm-candle Rust counterpart
└── Tests/
    ├── L0_Specs.lean                # Spec-level tests for each invariant
    └── Integration.lean             # End-to-end ALP gate correctness
```

### Pirtm-Candle Ignition

The `pirtm-candle` workspace at `Prime/pirtm-candle/` serves as the **Rust
ignition substrate** for the Lean ALP formalization. The copy-from-Prime rule
(ADR-0xx) dictates that governed inference projects copy the `pirtm-candle`
tree into their own source tree rather than depending on it as a workspace
path. The same rule governs the ALP implementation:

- **Lean spec is canonical**: `Prime/substrates/lean/ALP/` defines the
  authoritative ALP semantics, type contracts, and proof obligations.
- **Rust substrate is compliant**: `Prime/pirtm-candle/` (and downstream
  copies) implements the Rust side of the spec — `PolicyEngine`,
  `ConstitutionModel`, `TrustLevel`, and associated validation logic.
- **Ignition boundary**: The `Candle/PirtmBridge.lean` module marks the
  seam where Lean proofs correspond to Rust types. Every field in
  `ConstitutionModel`, every variant of `TrustLevel`, every result of
  `validate_action` has a matched Rust struct in pirtm-candle or
  multiplicity-common.

**Substrate Structure (pirtm-candle):**
```
Prime/pirtm-candle/
├── Cargo.toml                      # Workspace root (candle-core, candle-transformers, nalgebra)
├── src/
│   ├── lib.rs                      # Public API, PirtmError, core types
│   ├── contractivity.rs            # LambdaMOp, LambdaMConfig, LambdaTrace
│   ├── witness.rs                  # GenerationWitness, WitnessEmitter
│   ├── model.rs                    # TinyLlamaConfig, TinyLlamaModel, GovernedGeneration
│   └── math/
│       ├── mod.rs                  # Re-exports spectral substrate
│       ├── spectral.rs             # Spectral governor (from Prime/crates/core)
│       ├── recurrence.rs           # Recurrence relations
│       ├── lambda_bridge.rs        # Lambda_m ↔ spectral mapping
│       ├── gate.rs                 # Gate evaluation
│       ├── types.rs                # Core type aliases
│       ├── certify.rs              # Contractivity certification
│       └── audit.rs                # Audit trail utilities
```

The ignition process:
1. Lean proofs establish the admissibility contract: `validate_action` is
   sound w.r.t. the constitution.
2. pirtm-candle's `SedonaSpineEvaluator` embeds the same stop-rule logic in
   Rust, using the same `LambdaTrace` struct defined in the Lean spec.
3. CI runs `lake build` on the Lean ALP library and `cargo test` on
   pirtm-candle in parallel. Any divergence in contract semantics is a CI
   failure.
4. The copy-from-Prime rule ensures that when pirtm-candle advances, all
   downstream governed inference tools (phase-mirror-mcp, mirror-dissonance-cli)
   receive identical Rust code, preserving ALP compliance.

### Type Mapping (Rust → Lean)

| Rust (`multiplicity-common`) | Lean | Notes |
|------------------------------|------|-------|
| `ConstitutionModel` | `ConstitutionModel` | Fields map 1:1 |
| `ConstitutionViolation` | `ConstitutionViolation` | `invariant: String`, `detail: String` |
| `TrustLevel::Internal` | `TrustLevel.Internal` | Constructor-based |
| `TrustLevel::External` | `TrustLevel.External` | Constructor-based |
| `Action` | `Action` | `id: String`, `payload: JSONValue`, `mutating: Bool`, `server_binding: Option String` |
| `AdmissibilityReport` | `AdmissibilityReport` | `allowed: Bool`, `reason: String` |
| `UnifiedWitness` | `UnifiedWitness` | Required fields per L0 |
| `PrimeGate` | `PrimeGate` | `action_name: String`, `gate_value: Nat` |

### Verification Strategy

Each ADR in the sequence will:
1. Produce compilable Lean code under the `Prime/substrates/lean/ALP/` hierarchy
2. Eliminate at least one `sorry` placeholder per theorem
3. Include a `Tests/` file with `#eval` and `example` proofs
4. Update the Rust `PolicyEngine::validate_action()` in the pirtm-candle
   ignition crate (or multiplicity-common substrate) to implement the
   spec-verified logic
5. Add or update `tests/governance.rs` to cover the newly formalized behavior

The **Lean 4 library** at `Prime/substrates/lean/ALP/` is the authoritative
specification. The **Rust substrate** in `Prime/pirtm-candle/` (and downstream
copies per the copy-from-Prime rule) is the compliant implementation. CI will
compile both and run Rust governance tests on every commit; a future CI step
will invoke `lake build` on the Lean project.

**Ignition Protocol (pirtm-candle ↔ Lean ALP):**
- Every theorem in `Prime/substrates/lean/ALP/` maps 1:1 to a Rust type or
  function in `Prime/pirtm-candle/src/`.
- `Constitution/L0_Invariants.lean` ↔ `pirtm-candle/src/math/spectral.rs`
- `PolicyEngine/Core.lean` ↔ `multiplicity-alp::PolicyEngine` in the
  commander-core substrate
- `Contracts/NonBypassability.lean` ↔ `CommanderCore::run_workflow` ALP gate
- `Candle/PirtmBridge.lean` documents the traceability table; CI checks that
  no theorem remains `sorry` without a corresponding Rust implementation stub
  or verified test.

## Sequenced ADR Plan

### ADR-ALP-003-01: Lean 4 Scaffold and Constitution Foundation

**Status**: Proposed  
**Depends on**: ADR-ALP-002 (accepted)

**Objective**: Establish the Lean 4 project scaffold, import Mathlib, and port
the `ConstitutionModel` and L0 invariants as Lean predicates.

**Deliverables**:
- `Prime/substrates/lean/ALP/Lakefile.lean`
- `Prime/substrates/lean/ALP/Basic.lean`
- `Prime/substrates/lean/ALP/Constitution/Model.lean`
- `Prime/substrates/lean/ALP/Constitution/L0_Invariants.lean`
- Proof that each L0 predicate is computable (decision procedure)

**Outstanding Obligations**:
- `sorry` in `proof_anchor_recognized` if `active_anchors` is `List String`
- All other L0 predicates decidable from `Rat` / `Bool` / `Nat` arithmetic

**Acceptance Criterion**:
`lake build` succeeds on `Prime/substrates/lean/ALP/Constitution/L0_Invariants.lean`.

---

### ADR-ALP-003-02: Action and Trust Level Types

**Status**: Proposed  
**Depends on**: ADR-ALP-003-01

**Objective**: Port `Action`, `TrustLevel`, and `AdmissibilityReport` to Lean
with derived properties.

**Deliverables**:
- `Prime/substrates/lean/ALP/Types/Action.lean`
- `Prime/substrates/lean/ALP/Types/TrustLevel.lean`
- `Prime/substrates/lean/ALP/Types/AdmissibilityReport.lean`

**Definitions**:
```lean
-- Informal sketch — actual file uses Mathlib encodable instances
structure Action where
  id : String
  payload : JSONValue
  mutating : Bool
  server_binding : Option String

inductive TrustLevel
  | Internal | External

structure AdmissibilityReport where
  allowed : Bool
  reason : String
```

**Key Property**: `isMutating : Action → Bool` is decidable.

**Acceptance Criterion**: `lake build` + `Prime/substrates/lean/ALP/Tests/L0_Specs.lean` contains at
least one `example` proving `isMutating` is a proposition.

---

### ADR-ALP-003-03: PolicyEngine Core and Admissibility Semantics

**Status**: Proposed  
**Depends on**: ADR-ALP-003-02

**Objective**: Specify `PolicyEngine.validate_action` as a pure function in Lean
and prove that it correctly implements the constitutional admissibility contract.

**Deliverables**:
- `Prime/substrates/lean/ALP/PolicyEngine/Core.lean`
- `Prime/substrates/lean/ALP/PolicyEngine/Admissibility.lean`

**Core Theorem**:
```lean
theorem validate_action_sound :
  ∀ (pe : PolicyEngine) (a : Action) (t : TrustLevel),
  let r := pe.validate_action a t
  (r.allowed = true) →
    pe.constitution.validate = Except.ok Unit
```

**Acceptance Criterion**: `sorry` count in `PolicyEngine/Admissibility.lean` == 0.

---

### ADR-ALP-003-04: Non-Bypassability of the ALP Gate

**Status**: Proposed  
**Depends on**: ADR-ALP-003-03

**Objective**: Formalize that no execution path in the system can reach
Sigma/Archivum without clearing `PolicyEngine.validate_action`.

**Deliverables**:
- `Prime/substrates/lean/ALP/Contracts/NonBypassability.lean`

**Formulation**:
Model the system as a finite-state transition system where every
state transition labeled `execute_action` must be preceded by a transition
`alp_gate` with positive outcome.

**Key Lemma**:
```lean
theorem no_unaligned_execution :
  ∀ trace : Trace (State × Action),
  trace.reaches (σ_execute a) →
    ∃ prefix, trace = prefix ++ [alp_admit a] ++ [σ_execute a]
```

**Acceptance Criterion**: Proof of `no_unaligned_execution` under the
operational semantics model (stubs for Sigma/Archivum states permitted).

---

### ADR-ALP-003-05: Trust Arbitration and External Blocking

**Status**: Proposed  
**Depends on**: ADR-ALP-003-03

**Objective**: Prove that internal-trusted actions may execute governed MCP
calls, while external-untrusted actions are deterministically blocked from
accessing governed MCP resources.

**Deliverables**:
- `Prime/substrates/lean/ALP/Contracts/TrustArbitration.lean`

**Theorems**:
```lean
theorem internal_admits_mcp :
  ∀ (pe : PolicyEngine) (a : Action) (s : McpServerDescriptor),
  a.server_binding = some s.descriptor_id →
    pe.constitution.validate = ok →
      (pe.validate_action a TrustLevel.Internal).allowed = true

theorem external_blocks_governed_mcp :
  ∀ (pe : PolicyEngine) (a : Action) (s : McpServerDescriptor),
  s.alp_required = true →
    (pe.validate_action a TrustLevel.External).allowed = false
```

**Acceptance Criterion**: Both theorems proved (or `sorry` eliminated).

---

### ADR-ALP-003-06: MCP Governance Binding Contract

**Status**: Proposed  
**Depends on**: ADR-ALP-003-05

**Objective**: Specify that every MCP tool invocation in the governed surface
must present a valid SAT token whose issuance is contingent on prior ALP
admission.

**Deliverables**:
- `Prime/substrates/lean/ALP/MCP/GovernanceBinding.lean`

**Key Definitions**:
- `SatIssuer.issue : Action → TrustLevel → Except Error SignedAdmissionToken`
- `SatVerifier.verify : SignedAdmissionToken → Bool`

**Contract**:
```lean
theorem sat_requires_alp_admission :
  ∀ (a : Action) (t : TrustLevel) (tok : SignedAdmissionToken),
    SatVerifier.verify tok = true →
      ∃ pe, pe.validate_action a t = ⟨true, _⟩
```

**Acceptance Criterion**: ADR-MCP-002 (hash-on-attestation) compatibility
verified in Lean.

---

### ADR-ALP-003-07: Archivum Witness Contract

**Status**: Proposed  
**Depends on**: ADR-ALP-003-04

**Objective**: Formalize the invariants that every `UnifiedWitness` must satisfy
per L0-1 and the Archivum ledger requirement.

**Deliverables**:
- `Prime/substrates/lean/ALP/Archivum/WitnessContract.lean`

**Invariants**:
1. `witness_id` is non-empty and unique
2. `action_id` matches the action being witnessed
3. `timestamp` is ISO-8601 valid
4. `veto_status` ∈ {ADMITTED, VETOED}
5. `execution_receipt` populated iff status == ADMITTED

**Theorem**:
```lean
theorem witness_after_decision :
  ∀ (pe : PolicyEngine) (a : Action) (w : UnifiedWitness),
  w.action_id = a.id →
    w.veto_status = "VETOED" →
      (pe.validate_action a anyTrustLevel).allowed = false
```

**Acceptance Criterion**: All five invariants proved as lemmas.

---

### ADR-ALP-003-08: End-to-End Integration and Rust Compliance

**Status**: Proposed  
**Depends on**: ADR-ALP-003-06, ADR-ALP-003-07

**Objective**: Tie all formal specifications to the Rust implementation,
eliminating `sorry` placeholders, and ensuring `cargo test --test governance`
passes with the now-complete ALP gate.

**Deliverables**:
- Full `sorry`-free Lean 4 ALP library (all 8 modules)
- Updated `models/the-commander/crates/alp/src/lib.rs` replacing mock with
  actual `constitution.validate()` call
- Updated `tests/governance.rs` covering trust-level MCP blocking and
  external sandboxing
- CI integration step for `lake build`
- `ADR-ALP-003-08-integration-report.md` documenting traceability from each
  Lean theorem to its Rust counterpart

**Rust Compliance Changes**:
```rust
// Replace mock in PolicyEngine::validate_action
pub fn validate_action(
    &self,
    action: &Action,
    trust: &policy::TrustLevel,
) -> anyhow::Result<admission::AdmissibilityReport> {
    self.constitution.validate()
        .map_err(|e| anyhow::anyhow!("{:?}", e))?;

    // Trust arbitration per ADR-ALP-003-05
    let allowed = match trust {
        TrustLevel::Internal => true,
        TrustLevel::External => {
            !action.mutating && action.server_binding.is_none()
        }
    };

    Ok(AdmissibilityReport { allowed, reason: ... })
}
```

**Acceptance Criterion**:
1. `lake build` produces zero errors and zero `sorry` placeholders
2. `cargo test --test governance` passes
3. `lake test` passes (Lean test suite)
4. Integration report shows 1:1 theorem-to-Rust mapping for all L0 invariants

## Traceability Matrix

| Lean Module | Formal Property | L0 Invariant | Rust Counterpart | ADR |
|-------------|-----------------|---------------|-------------------|-----|
| `Constitution/Model` | `ConstitutionModel` record | L0-1..L0-9 | `crates/common/src/constitution.rs:37-50` | 03-01 |
| `Constitution/L0_Invariants` | `l0_1` (state_norm) | L0-1 | `constitution.rs:65-73` | 03-01 |
| `Constitution/L0_Invariants` | `l0_2` (drift_rate) | L0-2 | `constitution.rs:75-84` | 03-01 |
| `Constitution/L0_Invariants` | `l0_3` (critique gates) | L0-3 | `constitution.rs:86-102` | 03-01 |
| `Constitution/L0_Invariants` | `l0_4` (prime gates) | L0-4 | `constitution.rs:104-129` | 03-01 |
| `Constitution/L0_Invariants` | `l0_5` (contractivity) | L0-5 | `constitution.rs:131-145` | 03-01 |
| `Constitution/L0_Invariants` | `l0_6` (kill switch) | L0-6 | `constitution.rs:147-155` | 03-01 |
| `Constitution/L0_Invariants` | `l0_7` (circuit breaker) | L0-7 | `constitution.rs:157-165` | 03-01 |
| `Constitution/L0_Invariants` | `l0_9` (proof anchor) | L0-9 | `constitution.rs:167-177` | 03-01 |
| `PolicyEngine/Core` | `validate_action` signature | L0-3 | `alp/src/lib.rs:37-47` | 03-03 |
| `PolicyEngine/Admissibility` | soundness (allowed → valid) | L0-3 | `alp/src/lib.rs:37-47` | 03-03 |
| `Contracts/NonBypassability` | all_executions_gated | L0-3 | `commander-core/src/lib.rs:259-275` | 03-04 |
| `Contracts/TrustArbitration` | internal_mcp_allowed | ADR-ALP-002 | `commander-core/src/lib.rs:259-275` | 03-05 |
| `Contracts/TrustArbitration` | external_blocks_governed_mcp | ADR-ALP-002 | `commander-core/src/lib.rs:259-275` | 03-05 |
| `MCP/GovernanceBinding` | sat_requires_alp_admission | ADR-MCP-002 | `crates/mcp/` | 03-06 |
| `Archivum/WitnessContract` | witness_after_decision | L0-1 | `commander-core/src/archivum.rs` | 03-07 |

## Escalation Protocol

Per the Ξ-Constitution:
- If any ADR-ALP-003-* step requires modifying `multiplicity-common` types,
  halt and file an amendment ADR against the canonical schema.
- If a proof obligation conflicts with existing L0 invariant semantics,
  escalate via `<!-- LawfulRecursionVersion:1.0 -->` block.
- No Rust execution path may be accepted as compliant without the
  corresponding Lean theorem proved and checked in CI.

## Verification

- `cargo test --test governance` passes on every commit involving ALP code.
- `lake build` and `lake test` are added to CI for the `Prime/substrates/lean/ALP/` project.
- Each sub-ADR specifies its own acceptance criterion; the composite criterion
  is zero `sorry` placeholders across the entire ALP formalization tree.

