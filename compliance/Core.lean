/-!
# Architecture Decision Records (ADR) — Policy Formal Core Model

This module provides the foundational formal specifications for Architecture Decision Records (ADRs)
governing the Multiplicity **Policy** package. Architectural governance decisions are represented as
machine-checkable records equipped with structural invariants, lifecycle transition constraints,
embedded propositional entailment semantics, and registry coherence properties.

The model is intentionally isomorphic to the canonical `ADR.*` namespace in `packages/Foundry/`
so that policy-level and kernel-level ADRs share a single verification surface and can be
cross-referenced through a shared `ArtifactLink` vocabulary (Git commits, Lean declarations,
source files, specification documents).
-/

namespace Policy.ADR

/-! ## Foundational Types -/

/-- Unique identifier for a Policy Architecture Decision Record (e.g., "POL-001"). -/
abbrev PolicyId := String

/-- Classification of linked architectural artifacts. -/
inductive ArtifactKind where
  | GitCommit       : ArtifactKind
  | LeanDeclaration : ArtifactKind
  | SourceFile      : ArtifactKind
  | SpecificationDoc : ArtifactKind
  deriving DecidableEq, Repr, Inhabited

/-- Machine-checkable link to external code, proofs, or artifacts. -/
structure ArtifactLink where
  /-- Target URI, commit hash, file path, or declaration name. -/
  uri : String
  /-- Classification of the target artifact. -/
  kind : ArtifactKind
  /-- Descriptive summary of the governance relationship. -/
  description : String
  deriving DecidableEq, Repr, Inhabited

/-- Formal lifecycle status of a Policy Architecture Decision Record. -/
inductive ADRStatus where
  | Proposed   : ADRStatus
  | Accepted   : ADRStatus
  | Deprecated : ADRStatus
  | Superseded : ADRStatus
  deriving DecidableEq, Repr, Inhabited

/-- String representation of lifecycle status. -/
def ADRStatus.toString : ADRStatus → String
  | Proposed   => "Proposed"
  | Accepted   => "Accepted"
  | Deprecated => "Deprecated"
  | Superseded => "Superseded"

instance : ToString ADRStatus := ⟨ADRStatus.toString⟩

/-- The core Policy Architecture Decision Record dependent structure.

This is structurally identical to the kernel-level `ADR.ADR` record; the
aliasing is deliberate so that policy-level and kernel-level ADRs share
a single verification surface. -/
abbrev ADR := ADR.ADR

/-- Re-export the canonical `ADRId` from the kernel model so that Policy
records can be cross-linked by identifier. -/
abbrev ADRId := ADR.ADRId

/-! ## Embedded Logic for Consequence Entailment -/

/-- Embedded propositional syntax for formalizing decision-to-consequence entailment.

**Extension seam for first-order logic:** the atom payload is deliberately opaque.
A predicate-calculus layer can be layered on without touching this type or any
downstream theorem by introducing a first-order term type and reinterpreting
atoms as (predicate, terms) pairs, e.g.:

```
structure PredicateAtom where
  pred : String
  args : List String   -- first-order terms; generalize later

abbrev FOPropTerm := PropTerm  -- atoms range over PredicateAtom instead of String
```

Because every semantic function below is parameterized by an environment over
atoms, quantification can be added as a new constructor (`all`/`exists`) with a
Kripke-style environment extension while keeping `eval`, `evalB`, `Entails`,
and `Contradictory` structurally recursive and sound. -/
abbrev PropTerm := ADR.PropTerm

/-- Semantic valuation of an embedded propositional term under an environment. -/
abbrev PropTerm.eval := ADR.PropTerm.eval

/-- Decidable Boolean valuation of an embedded proposition under a Boolean environment. -/
abbrev PropTerm.evalB := ADR.PropTerm.evalB

/-- Semantic entailment: every environment satisfying all premises satisfies the conclusion. -/
abbrev Entails := ADR.Entails

/-- Semantic contradiction between compound formulas. -/
abbrev Contradictory := ADR.Contradictory

/-! ## Lifecycle State Transition Calculus -/

/-- Valid governance state transitions between ADR lifecycle states. -/
abbrev ValidTransition := ADR.ValidTransition

/-! ## Registry and Graph Invariants -/

/-- Direct supersession relation on ADR identifiers within a collection. -/
abbrev SupersedesRel := ADR.SupersedesRel

/-- Reflexive-transitive closure of supersession (historical provenance path). -/
abbrev ProvenancePath := ADR.ProvenancePath

/-- Acyclicity constraint on the supersession graph: no ADR can strictly supersede itself. -/
abbrev StrictAcyclic := ADR.StrictAcyclic

/-- Architectural conflict predicate: two active decisions are mutually incompatible. -/
abbrev ConflictsWith := ADR.ConflictsWith

/-- Decidable Boolean conflict test between two records. -/
abbrev ConflictsWithB := ADR.ConflictsWithB

/-- Computable decision procedure checking absence of syntactic conflicts in a list of ADRs. -/
abbrev ADRListNoConflicts := ADR.ADRListNoConflicts

/-- An embedded formal claim asserted by an accepted ADR. -/
abbrev Claim := ADR.Claim

/-- Comprehensive consistency predicate for an entire ADR registry. -/
abbrev ADRRegistry := ADR.ADRRegistry

end Policy.ADR
