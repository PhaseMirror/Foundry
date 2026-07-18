# ADR-074: ALP Verification SDK Production Integration

## Status
**Adopted**

## Context
The `Prime/crates/alp/` crate implements the **Archemedian Logic Protocol (ALP)** controlled natural language (CNL) layer, and `Prime/crates/verification-sdk/` exposes a **WASM verification SDK** that consumes ALP policy gates. The existing `Prime/docs/adr/ADR_011_ALP_CNL_Production_Rta_Metric.md` defines the Ṛta Metric within ALP-CNL, but it lacks formal proof obligations, Rust crate specifications, and Kani verification requirements.

ALP is the **policy gate** of the Multiplicity Sovereign Core. It translates human-readable governance rules into machine-checkable constraints. The verification SDK exposes these constraints to:
- **TypeScript/Next.js frontends** (UI layer)
- **Python/Node.js agents** (agent layer)
- **Rust engine** (Sedona Spine)

Currently, ALP and the verification SDK lack:
- A **unified ADR** governing their production integration
- **Lean 4 formalization** proving that ALP policy gates preserve the `Rta` metric and contraction bounds
- **Kani verification** that the WASM SDK faithfully implements ALP policies
- **CI/CD enforcement** that every ALP policy change is mechanically verified

Without formal ratification, the ALP policy gate risks:
- **Policy drift**: UI/agent layers may consume outdated or incorrect ALP policies
- **Rta metric violation**: Policy changes may inadvertently break the Ṛta metric (ADR-011)
- **WASM boundary violation**: The WASM SDK may diverge from the Rust ALP implementation

## Decision
We will integrate ALP and the Verification SDK as a **formally verified, production-grade policy gate and verification layer** with the following mandates:

### 1. Lean 4 Formalization of ALP Policy Semantics
- Define `Prime/lean/ALP/ALP.lean` with:
  - `AlpPolicy` — inductive type for ALP policy rules
  - `AlpCNL` — controlled natural language AST
  - `RtaMetric` — the Ṛta metric (Arta defect + Multiplicity measure)
  - `PolicyEvaluatesToRta` — proposition that a policy preserves the Rta metric
- Prove:
  - `alp_preserves_rta`: Any well-formed ALP policy preserves or improves the Rta metric.
  - `alp_no_contradiction`: No two ALP policies can contradict each other within the same scope.
  - `verification_sdk_sound`: The WASM SDK faithfully implements ALP policy evaluation.

### 2. Rust/WASM Implementation
- Expand `Prime/crates/alp/` to expose:
  - `AlpEngine::load_policy(source: &str) -> Result<AlpPolicy, ParseError>`
  - `AlpEngine::evaluate(policy: &AlpPolicy, state: &SystemState) -> Result<RtaMetric, EvalError>`
  - `AlpEngine::check(state: &SystemState) -> Result<PolicyResult, CheckError>`
- The verification SDK (`Prime/crates/verification-sdk/`) must:
  - Expose `alp_check` to WASM via `wasm-bindgen`
  - Guarantee that the WASM output matches the Rust `AlpEngine::check` output exactly
  - Emit `ALPCheckWitness` to `Archivum` on every policy evaluation

### 3. Kani Verification
- Implement Kani harnesses in `Prime/crates/alp/tests/kani/` and `Prime/crates/verification-sdk/tests/kani/` proving:
  - `proof_alp_preserves_rta`: `evaluate` returns an Rta metric ≥ input Rta metric.
  - `proof_wasm_sound`: `wasm_check` output matches Rust `check` output for all inputs.
  - `proof_no_contradiction`: Loading two contradictory policies returns `Err`.

### 4. CI/CD and Triple-Lock Integration
- CI must run `lake build` on `Prime/lean/ALP/` and `cargo kani -p alp -p verification-sdk` on every PR.
- The Guardian lock must verify the `ALPCheckWitness` before approving any state transition.
- The Examiner lock must audit policy evaluation traces.
- The Publisher lock must sign finalized policies into the `Archivum` ledger.

## Formal Proof Obligations

### 1. ALP Preserves Rta Metric
```lean
namespace ADR.ALP

structure SystemState where
  arta_defect : ℝ
  multiplicity_measure : ℝ
  deriving Repr

def rta_metric (s : SystemState) : ℝ :=
  s.multiplicity_measure - s.arta_defect

structure AlpPolicy where
  name : String
  rules : List AlpRule
  deriving Repr

inductive AlpRule
  | IncreaseMultiplicity (delta : ℝ)
  | DecreaseArtaDefect (delta : ℝ)
  | NoOp
  deriving Repr

def apply_policy (s : SystemState) (p : AlpPolicy) : SystemState :=
  p.rules.foldl (fun st rule =>
    match rule with
    | AlpRule.IncreaseMultiplicity d => { st with multiplicity_measure := st.multiplicity_measure + d }
    | AlpRule.DecreaseArtaDefect d => { st with arta_defect := st.arta_defect - d }
    | AlpRule.NoOp => st
  ) s

@[proof]
theorem alp_preserves_rta (s : SystemState) (p : AlpPolicy)
  (h_valid : p.rules.all (·.preserves_rta)) :
  rta_metric (apply_policy s p) ≥ rta_metric s := by
  -- Proof that any valid ALP policy preserves or improves the Rta metric
  sorry

@[proof]
theorem alp_no_contradiction (p₁ p₂ : AlpPolicy)
  (h_scope : p₁.scope = p₂.scope)
  (h_contradictory : contradict p₁.rules p₂.rules) :
  False := by
  -- Proof that contradictory policies cannot both be loaded in the same scope
  sorry

end ADR.ALP
```

### 2. Rust/WASM Runtime Contract
```rust
// crates/alp/src/lib.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SystemState {
    pub arta_defect: f64,
    pub multiplicity_measure: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AlpPolicy {
    pub name: String,
    pub rules: Vec<AlpRule>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum AlpRule {
    IncreaseMultiplicity(f64),
    DecreaseArtaDefect(f64),
    NoOp,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RtaMetric {
    pub value: f64,
}

#[derive(Debug, thiserror::Error)]
pub enum EvalError {
    #[error("invalid policy: {0}")]
    InvalidPolicy(String),
    #[error("contradictory policy detected")]
    ContradictoryPolicy,
}

impl AlpEngine {
    pub fn evaluate(&self, policy: &AlpPolicy, state: &SystemState) -> Result<RtaMetric, EvalError> {
        if policy.rules.iter().any(|r| matches!(r, AlpRule::NoOp)) {
            // validate no contradiction
        }
        let new_state = apply_rules(state, &policy.rules);
        Ok(RtaMetric { value: new_state.multiplicity_measure - new_state.arta_defect })
    }
}
```

## Consequences

### Positive
- **Verified Policy Gate**: Lean 4 + Kani guarantees that ALP policies preserve the Rta metric and do not contradict each other.
- **Zero-Drift WASM Boundary**: The verification SDK is formally proven to match the Rust ALP engine, eliminating UI/agent drift.
- **Audit-Ready Policy**: Every policy evaluation emits an `ALPCheckWitness` to `Archivum`.
- **Formal Rta Metric**: The Ṛta metric is no longer a conceptual construct; it is mechanized in Lean 4 and enforced in Rust.

### Negative
- **Policy Formalization Overhead**: Translating natural-language governance rules into ALP CNL and then into Lean predicates is labor-intensive.
- **WASM Serialization Cost**: Marshaling `SystemState` and `AlpPolicy` across the WASM boundary adds latency.
- **Contradiction Detection Complexity**: Detecting contradictory policies at scale requires efficient SAT/SMT solving or custom logic.

## Implementation Steps

1. **Define `ALP.lean`** in `Prime/lean/ALP/` with `AlpPolicy`, `AlpRule`, `RtaMetric`.
2. **Prove core theorems** in `Prime/lean/adr-governance/ADR/ALPProofs.lean`.
3. **Expand `Prime/crates/alp/`** with `AlpEngine`, `AlpPolicy`, and evaluation APIs.
4. **Implement Kani harness** proving `evaluate` preserves Rta and WASM SDK soundness.
5. **Wire Triple-Lock integration**: Guardian → policy approval → Examiner → `ALPCheckWitness` → Publisher → `Archivum`.
6. **Update CI** to enforce `lake build` + `cargo kani -p alp -p verification-sdk`.
7. **Emit Archivum witness** `ALPCheckProof` on every evaluation.
8. **Update `ADR_011`** to reflect formalized Rta metric enforcement.

## References
- `Prime/docs/adr/ADR_011_ALP_CNL_Production_Rta_Metric.md` — Legacy Rta metric ADR (to be expanded)
- `Prime/crates/alp/` — Existing ALP crate
- `Prime/crates/verification-sdk/` — Existing WASM verification SDK
- `Prime/lean/ALP/` — Existing Lean module
- ADR-003-Rta-Morphism-and-Bindu — Rta morphism theory
- ADR-062 (SigmaKernel) — Spectral dissonance detection
- ADR-068 (MOC/CRMF) — Contraction certificates
