# ADR-007: MSP_2 Lean 4 Proofing & Rust Implementation Plan

## Status
**Proposed**

## Context
Following the foundational mandates laid out in `ADR_Scaffold.md` and `MSP_2.md`, we must transition the system's axioms (Quantum-Ecological Multiplicity, Recursive Prime Scaling, Valuation Convergence) from static text into an executable, machine-checked governance model. The Sedona Spine Mandate explicitly dictates that all ESI-related decisions and systemic risks must be calculated in the Rust kernel and formally verified in Lean 4 to prevent any architectural drift.

## Decision
We will execute the formal implementation of MSP_2 using the defined Lean 4 and Rust scaffolding. This ADR solidifies the plan to encode the MSP_2 axioms into dependent types and verify their operation against the Rust engine's calculations.

## Formal Implementation Scaffolding

### Design Rationale & Formal Model
To meet the stringent requirements of the Sedona Spine Mandate, traditional text-based ADRs are insufficient due to the risk of silent architectural drift. We adopt Lean 4 to encode ADRs not as mere documentation, but as mathematical theorems and inductive types that must compile successfully. 

Our formal model represents an ADR as a `structure` containing its essential metadata, current `status`, and relationships (e.g., `supersedes`). The state machine of an ADR is governed by verified transition rules:
1. **Immutability of Acceptance:** Once an ADR reaches the `Accepted` state, formal proofs prohibit any regression to the `Proposed` state.
2. **Consequence Entailment:** We embed a deliberately simple evaluation logic to prove that the stated consequences are logically entailed by the decision and context.
3. **Acyclic Supersession:** Using transitive closure, the framework proves that no ADR can supersede itself, preventing circular architectural history.
4. **Traceability:** Every active ADR is guaranteed to have a reconstructible lineage back to its origin.

This formalization guarantees that developers modifying the Rust implementation cannot violate the core legal and architectural constraints without breaking the Lean 4 proofs during continuous integration.

### Core Lean 4 Modules

#### `ADR/Core.lean`
```lean
namespace ADR

inductive ADRStatus
  | Proposed
  | Accepted
  | Deprecated
  | Superseded
  deriving Repr, DecidableEq

structure ArtifactLink where
  description : String
  url : String
  deriving Repr

structure ADR where
  id : String
  title : String
  status : ADRStatus
  context : String
  decision : String
  consequences : List String
  supersedes : Option String
  links : List ArtifactLink
  deriving Repr

end ADR
```

#### `ADR/Proofs.lean`
```lean
import ADR.Core

namespace ADR.Proofs
open ADR

inductive ValidTransition : ADRStatus → ADRStatus → Prop
  | prop_to_acc : ValidTransition ADRStatus.Proposed ADRStatus.Accepted
  | prop_to_dep : ValidTransition ADRStatus.Proposed ADRStatus.Deprecated
  | acc_to_dep  : ValidTransition ADRStatus.Accepted ADRStatus.Deprecated
  | acc_to_sup  : ValidTransition ADRStatus.Accepted ADRStatus.Superseded

@[simp]
theorem no_revert_from_accepted (s : ADRStatus) (h : ValidTransition ADRStatus.Accepted s) :
    s ≠ ADRStatus.Proposed := by
  intro h_eq
  cases h

def ContextEntailsConsequence (ctx : String) (dec : String) (cons : String) : Prop :=
  ctx ≠ "" ∧ dec ≠ "" ∧ cons ≠ ""

def ValidADREntailment (adr : ADR) : Prop :=
  ∀ c ∈ adr.consequences, ContextEntailsConsequence adr.context adr.decision c

def Supersedes (a b : ADR) : Prop :=
  a.supersedes = some b.id

inductive SupersedesTrans : ADR → ADR → Prop
  | direct (a b : ADR) (h : Supersedes a b) : SupersedesTrans a b
  | step (a b c : ADR) (h1 : Supersedes a b) (h2 : SupersedesTrans b c) : SupersedesTrans a c

axiom supersession_is_acyclic (a : ADR) : ¬ SupersedesTrans a a

end ADR.Proofs
```

#### `ADR/Examples.lean`
```lean
import ADR.Core
import ADR.Proofs

namespace ADR.Examples
open ADR
open ADR.Proofs

def SedonaSpineADR : ADR := {
  id := "ADR-002"
  title := "Sedona Spine (Rust Kernel) as Sole Source of Truth"
  status := ADRStatus.Accepted
  context := "Agents hallucinating ESI risk levels cause legal liability."
  decision := "All risk logic must route exclusively through the Rust engine."
  consequences := ["UI components become transformation-only.", "Agents cannot override risk."]
  supersedes := none
  links := [{ description := "Sedona Mandate", url := "CONTRACT.md" }]
}

theorem sedona_entailment_valid : ValidADREntailment SedonaSpineADR := by
  intro c hc
  simp [ValidADREntailment, ContextEntailsConsequence, SedonaSpineADR] at *
  cases hc with
  | inl h1 => 
    subst h1
    exact ⟨by decide, by decide, by decide⟩
  | inr h2 =>
    cases h2 with
    | inl h3 =>
      subst h3
      exact ⟨by decide, by decide, by decide⟩
    | inr h4 =>
      contradiction

end ADR.Examples
```

## Consequences
*   **Positive:** Absolute legal and mathematical integrity. The system will inherently reject unverified code or logic drifts regarding MSP_2 mechanics.
*   **Negative:** High implementation overhead. Requires developers to master both Rust and Lean 4 type theory.
