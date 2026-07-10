# ADR-002: Sedona Spine (Rust Kernel) as the Sole Source of Truth

## Status
**Adopted**

## Context
In a distributed system involving LLM-driven agents and interactive UI components, there is a severe risk of **architectural drift and logical fragmentation**. If an autonomous agent or a frontend interface independently computes critical legal parameters—such as ESI (Electronically Stored Information) retention durations, litigation hold status, or spoliation risk levels—the system becomes legally indefensible. 

The **Sedona Spine Mandate** strictly dictates that no agent, UI component, or backend microservice may independently calculate preservation risk levels or retention durations. Discrepancies in these calculations can result in non-compliance, legal liability, and catastrophic system failure.

## Decision
We designate the **Sedona Spine (Rust Engine)** as the *sole mandatory source of truth* for all structural, ecological, and legal logic in the system.

1. **Path of Integrity:** All ESI-related decisions and risk calculations MUST route through the explicit path: `Policy → Event Log → Engine (Rust) → SDK (TS/WASM) → Contract (CONTRACT.md) → UI/Agent`.
2. **Transformation Only:** Agents and UI layers are permitted only to *transform* engine-computed facts into legal narratives and motion skeletons.
3. **Immutability of Risk:** Agents are strictly forbidden from overriding, circumventing, or re-interpreting engine risk levels (e.g., `Critical`, `High`, `Medium`).
4. **Declarative Policy:** All domain-specific legal variation must live in declarative YAML policies (e.g., `templates/*.yaml`), which are ingested by the Rust engine, rather than hardcoded in the frontend or agent prompts.

## Formal Proof Obligations

To ensure this mandate is architecturally enforced, we require formal Lean 4 proofs that validate the data flow integrity.

### 1. Engine State Exhaustiveness
We must prove that any valid output decision (e.g., a Risk Level) is a direct, deterministic mapping from the Engine's authenticated state.

**Lean 4 Formalization Sketch:**
```lean
import ADR.Core

namespace ADR.SedonaSpine

inductive RiskLevel
| Critical
| High
| Medium

/-- Represents the authenticated state within the Rust Engine -/
structure EngineState where
  policy : String
  eventLog : List String
  -- Mathematical encapsulation of the state
  
/-- Represents a decision emitted to the UI/Agent layer -/
structure AgentOutput where
  narrative : String
  risk : RiskLevel

/-- The only valid constructor for AgentOutput requires the EngineState as proof -/
def generateAgentOutput (state : EngineState) (narrative_transformation : EngineState → String) : AgentOutput :=
  { narrative := narrative_transformation state,
    risk := computeRiskLevel state } -- computeRiskLevel is an internal engine function

@[proof]
theorem risk_originates_from_engine (out : AgentOutput) (state : EngineState) 
  (h : out = generateAgentOutput state trans_fn) : 
  out.risk = computeRiskLevel state := by
  -- Proof that the output risk level matches the engine's internal calculation exactly,
  -- verifying that no agent transformation function (trans_fn) can mutate the risk field.
  simp [generateAgentOutput] at h
  exact h.right
```

## Consequences

### Positive
- **Legal Defensibility**: Every piece of ESI retention or litigation hold data presented to a user can be mathematically traced back to the Rust Engine and the declarative policy log.
- **Agent Safety**: By constraining LLM agents to a "Transformation Only" role, we mitigate hallucination risks regarding critical system facts.
- **Zero-Drift Architecture**: The system enforces consistency across all clients (Web, CLI, Agents).

### Negative
- **Bottlenecked Development**: The frontend and agent teams cannot rapidly prototype new risk logic on the client side; they must wait for the Rust engine to expose the necessary state.
- **Complexity in State Syncing**: The client must continuously sync with the Rust engine's WASM SDK to remain up to date, adding asynchronous complexity.

## Implementation Steps
1. Define the core `EsiEngine` struct in `src/engine.rs` to handle all risk and retention calculations.
2. Expose the Rust engine as a read-only WASM SDK for the frontend (`src/wasm.rs`).
3. Strip all computational logic from existing UI components and agent prompts, replacing them with strict queries to the WASM SDK.
4. Implement runtime validation in the Agent interface that halts execution if an agent attempts to hallucinate or manually construct a `[PRESERVATION ALERT]` that does not perfectly match the Engine's output.
5. Formalize the `risk_originates_from_engine` theorem in the Lean 4 `Proofs.lean` module to mathematically enforce this constraint at compile time.
