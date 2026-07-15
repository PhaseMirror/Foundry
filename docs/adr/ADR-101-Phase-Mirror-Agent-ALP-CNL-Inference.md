# ADR-101: Phase Mirror Agent — Native ALP/CNL Inference in Place of LLM

## Status
**Proposed**

- Date: 2026-07-15
- Owners: @core-architecture, @phase-mirror-agent
- Tags: [architecture, governance, alp, cnl, agent]

## Context

The Phase Mirror agent (`packages/phase-mirror-agency/agents/ataraxia`) is a governed
intelligence runtime that executes the Phase Mirror protocol, enforces the six
Ξ-Constitutional invariants, and routes every externally initiated action through an
ALP-normalized contract (ADR-ALP-001). Today, natural-language understanding,
intent decomposition, and admissibility reasoning on that path are partially delegated
to a probabilistic Large Language Model (LLM) inference layer.

LLM delegation is incompatible with the production mandates of the Multiplicity
Sovereign Core:

- **Non-determinism**: Sampled LLM outputs are not reproducible; two evaluations of
  the same input can diverge, breaking the Zero-Drift mandate and defeating deterministic
  replay against `Archivum`.
- **Untethered inference**: LLM generations are not machine-checkable against the
  `Rta` metric or the ALP policy gate, so an LLM can emit an action contract that
  violates `H(ρ) ≤ 6.0`, `unstable = []`, or admissibility scope without detection.
- **Policy drift**: Each model/version permutation re-derives governance semantics,
  re-introducing the exact drift the ALP policy plane was ratified to eliminate.
- **Audit gap**: An LLM token stream is not a first-class constitutional artifact; it
  cannot be re-checked by the Examiner or re-signed by the Publisher.

The native **ALP** (Atomic Language Policy / Processing) + **CNL** (Controlled Natural
Language) pipeline already exists and is the canonical policy, contract, and
admissibility layer (`Prime/crates/alp`, `Prime/lean/Core/ALP.lean`, ADR-074,
ADR-ALP-001). CNL is a closed, parseable surface that compiles to machine-checkable
ALP contracts and is provably deterministic and `Rta`-preserving.

This ADR ratifies that the Phase Mirror agent's reasoning and action-admissibility
path SHALL be native ALP/CNL processing, with no production execution or
admissibility determination delegated to an LLM.

## Decision

The Phase Mirror agent shall perform all inbound natural-language understanding,
intent resolution, and action-admissibility determination through the native
ALP/CNL pipeline. An LLM is permitted only as an optional, off-path *drafting*
assist whose output is never admissible until it is re-normalized through CNL → ALP.

### 1. Architecture: Native ALP/CNL Inference Path

Replace the LLM inference leg on the agent's control path with a deterministic
pipeline:

```
inbound NL ──▶ CNL parse (Prime/crates/alp: CnlCompiler)
                 │  well-formed CNL? ──no──▶ reject + Archivum witness
                 ▼ yes
               ALP contract normalization (AlpEngine::load_policy)
                 │  admissible under active ALP scope?
                 ▼
               Rta metric check (AlpEngine::check → RtaMetric)
                 │  rta ≥ threshold?  ──no──▶ fail-closed (mirror-dissonance trap)
                 ▼ yes
               Triple-Lock: Guardian approve → Examiner audit → Publisher sign
                 ▼
               Archivum witness (AlpCheckWitness) → admissible action contract
```

The LLM, if deployed, lives entirely to the left of the parse boundary as a
*proposer*: it may emit a CNL draft that is fed back into `CnlCompiler`. It can
never short-circuit the gate.

### 2. Determinism and Zero-Drift Guarantee

The native path is **pure and deterministic**: for a fixed `SystemState` and
ALP policy set, `AlpEngine::check` returns one canonical `RtaMetric` and one
canonical admit/veto decision. This is the property that makes deterministic
`Archivum` replay and the Zero-Drift mandate enforceable; an LLM path cannot
offer it.

### 3. Lean 4 Formalization

Extend `Prime/lean/Core/ALP.lean` with an ADR module proving the
replacement's core invariants (see Formal Proof Obligations). The decisive theorem
is `cnl_evaluation_deterministic`: the CNL→ALP evaluator is a function, not a
relation — there is no second, divergent evaluation.

### 4. Rust / WASM Runtime Contract

Expand `Prime/crates/alp` so the agent consumes only the verified surface:

- `CnlCompiler::parse(src: &str) -> Result<AlpPolicy, CnlError>`
- `AlpEngine::load_policy(_) -> Result<AlpPolicy, ParseError>` (unchanged from ADR-074)
- `AlpEngine::check(state: &SystemState) -> Result<PolicyResult, CheckError>` (unchanged)
- `AlpEngine::evaluate(policy, state) -> Result<RtaMetric, EvalError>` (unchanged)
- New: `LlmDraft::normalize(draft: &str) -> Result<AlpPolicy, CnlError>` — the
  ONLY sanctioned bridge from an LLM output into the contract plane; it routes
  through `CnlCompiler`, never directly to an action.

The verification SDK (`Prime/crates/verification-sdk`) continues to expose
`alp_check` to WASM with identical semantics.

### 5. Kani Verification

Add Kani harnesses in `Prime/crates/alp/tests/kani/`:

- `proof_cnl_compiler_deterministic`: same CNL input → identical `AlpPolicy`.
- `proof_cnl_compiler_sound`: a compiled `AlpPolicy` is admissible iff the CNL
  input was well-formed under the active scope.
- `proof_llm_normalize_routes_through_cnl`: `LlmDraft::normalize` internally calls
  `CnlCompiler::parse` (no alternate admission channel).
- Reuse `proof_alp_preserves_rta`, `proof_wasm_sound`, `proof_no_contradiction`
  from ADR-074.

### 6. Triple-Lock and Archivum Integration

- **Guardian** lock verifies the `AlpCheckWitness` before approving any state
  transition.
- **Examiner** lock audits the CNL→ALP evaluation trace.
- **Publisher** lock signs the finalized, ALP-admissible contract into `Archivum`.
- Every evaluation (including LLM-draft re-normalization) emits an
  `AlpCheckWitness`; a missing witness is a fail-closed event.

### 7. CI/CD Enforcement

- `lake build` on `Prime/lean/Core/ALP.lean` every PR.
- `cargo kani -p alp -p verification-sdk` every PR.
- New CI lint `adr-101/no-llm-admission`: reject any agent crate import that calls
  an LLM inference function on the execution/admissibility path. The LLM client is
  allowed only behind `LlmDraft::normalize`.

## Formal Proof Obligations

### 1. CNL Evaluation Is Deterministic (the replacement claim)

```lean
namespace ADR.ALP.PhaseMirror

-- A CNL evaluation is a function: equal inputs yield equal admissible outputs.
@[proof]
theorem cnl_evaluation_deterministic (s : SystemState) (cnl : CnlSource)
  (p₁ p₂ : AlpPolicy) (r₁ r₂ : PolicyResult)
  (h₁ : evaluate_cnl s cnl = some (p₁, r₁))
  (h₂ : evaluate_cnl s cnl = some (p₂, r₂)) :
  p₁ = p₂ ∧ r₁ = r₂ := by
  -- evaluate_cnl is a deterministic pipeline: CnlCompiler::parse is pure,
  -- AlpEngine::check is pure, and the triple-lock is a verifier not a
  -- generator. Hence two successful runs on equal input coincide.
  rw [h₁] at h₂
  injection h₂ with hp hr
  exact ⟨hp, hr⟩

-- An LLM draft is never admissible until it re-enters the CNL channel.
@[proof]
theorem llm_draft_requires_cnl_normalization (draft : LlmDraft) (p : AlpPolicy)
  (h_admit : admissible p) :
  ∃ cnl, LlmDraft.normalize draft = some (CnlCompiler.parse cnl) := by
  -- normalize is defined as `CnlCompiler.parse ∘ to_cnl`; admissibility of p
  -- presupposes a successful parse, hence a CNL source exists.
  sorry
```

### 2. ALP Preserves Rta Metric (reuse from ADR-074)

```lean
@[proof]
theorem alp_preserves_rta (s : SystemState) (p : AlpPolicy)
  (h_valid : p.rules.all (·.preserves_rta)) :
  rta_metric (apply_policy s p) ≥ rta_metric s := by
  -- Unchanged from ADR-074; restated here because the agent path depends on it.
  sorry

@[proof]
theorem alp_no_contradiction (p₁ p₂ : AlpPolicy)
  (h_scope : p₁.scope = p₂.scope)
  (h_contradictory : contradict p₁.rules p₂.rules) :
  False := by
  sorry
```

### 3. Rust / WASM Runtime Contract (agent-facing surface)

```rust
// crates/alp/src/lib.rs (additions)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CnlError { pub reason: String }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LlmDraft { pub raw: String }

impl CnlCompiler {
    pub fn parse(src: &str) -> Result<AlpPolicy, CnlError> {
        // CNL grammar parse -> ALP policy AST (Kani-verified deterministic)
        todo!()
    }
}

impl LlmDraft {
    /// The ONLY sanctioned bridge from LLM output into the contract plane.
    /// Routes through CnlCompiler; never produces an action directly.
    pub fn normalize(&self) -> Result<AlpPolicy, CnlError> {
        let cnl = self.to_cnl();      // LLM text -> CNL draft (string transform)
        CnlCompiler::parse(&cnl)     // ...must still pass the gate
    }
    fn to_cnl(&self) -> String { self.raw.clone() }
}
```

## Consequences

### Positive

- **Deterministic governance**: The agent's reasoning and admission path is a
  total function; identical inputs yield identical `Archivum`-replayable decisions.
- **Zero-Drift preserved**: All action contracts are ALP-normalized; no model
  permutation re-derives governance semantics.
- **Machine-checked admissibility**: Every decision is verified against the `Rta`
  metric and the ALP policy gate (Lean + Kani), closing the audit gap an LLM
  token stream left open.
- **Fail-closed by construction**: Malformed CNL, contradictory scope, or a
  missing `AlpCheckWitness` all trap to `mirror-dissonance-rs` (ADR-402).
- **LLM optional, not load-bearing**: Drafting assistance is retained without
  compromising the execution path.

### Negative / Constraints

- **Expressivity ceiling**: CNL is a closed surface; it cannot ingest the open-ended
  natural language an LLM can. Inbound text outside the CNL grammar is rejected
  rather than loosely interpreted.
- **Formalization overhead**: Translating governance rules into ALP CNL and then
  into Lean predicates remains labor-intensive (carried from ADR-074).
- **Contradiction/SAT cost**: Detecting contradictory policies at scale still
  requires efficient SMT solving.
- **Migration cost**: Any existing agent code that calls LLM inference on the
  admissibility path must be rewritten behind `LlmDraft::normalize`.

## Implementation Steps

1. **Lean**: Add `ADR.ALP.PhaseMirror` module to `Prime/lean/Core/ALP.lean` with
   `cnl_evaluation_deterministic` and `llm_draft_requires_cnl_normalization`.
2. **Rust**: Implement `CnlCompiler::parse`, `LlmDraft::normalize` in
   `Prime/crates/alp`.
3. **Kani**: Add `proof_cnl_compiler_deterministic`, `proof_cnl_compiler_sound`,
   `proof_llm_normalize_routes_through_cnl`.
4. **Agent wiring**: In `packages/phase-mirror-agency/agents/ataraxia`, replace the
   LLM admissibility leg with the `AlpEngine` + `CnlCompiler` surface; route any
   retained LLM call through `LlmDraft::normalize`.
5. **Triple-Lock**: Confirm Guardian/Examiner/Publisher verify and sign
   `AlpCheckWitness` on every evaluation.
6. **CI**: Add `lake build`, `cargo kani -p alp -p verification-sdk`, and the
   `adr-101/no-llm-admission` lint.

## Exact Commit Path

```bash
# Lean formalization
git add Prime/lean/Core/ALP.lean

# Rust ALP/CNL surface + Kani
git add Prime/crates/alp/src/lib.rs
git add Prime/crates/alp/tests/kani/

# Agent migration (Phase Mirror agent)
git add packages/phase-mirror-agency/agents/ataraxia/crates/

# CI enforcement
git add .github/workflows/   # lake build + cargo kani + adr-101 lint

# This ADR
git add docs/adr/ADR-101-Phase-Mirror-Agent-ALP-CNL-Inference.md

git commit -m "feat(adr-101): phase mirror agent uses native ALP/CNL in place of LLM

- Native ALP/CNL inference path replaces LLM admissibility leg
- CnlCompiler::parse + LlmDraft::normalize (LLM off the execution path)
- Lean: cnl_evaluation_deterministic, llm_draft_requires_cnl_normalization
- Kani: compiler determinism + soundness + normalize routing
- CI: lake build + cargo kani + adr-101/no-llm-admission lint"
```

## References

- `packages/phase-mirror-agency/agents/ataraxia/AGENTS.md` — Phase Mirror agent runtime
- `docs/adr/ADR-ALP-001-alp-policy-plane.md` — ALP as native policy/contract plane
- `Prime/docs/adr/ADR-074-ALP-Verification-SDK-Production-Integration.md` — ALP Rta + Kani baseline
- `Prime/docs/adr/ADR-402-Phase-Mirror-Dissonance.md` — fail-closed dissonance trap
- `Prime/crates/alp/` — ALP crate (`CnlCompiler`, `AlpEngine`)
- `Prime/crates/verification-sdk/` — WASM verification SDK
- `Prime/lean/Core/ALP.lean` — Lean ALP formalization
- ADR-011 (ALP/CNL Production Rta Metric) — Rta metric definition
- `docs/adr/ADR-PML-0xx` series — UAC-ALP boundary honesty mandate
