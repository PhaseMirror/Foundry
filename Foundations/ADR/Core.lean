import Lean

open Lean

/-!
# Architecture Decision Records (ADR) — Formal Core Model

This module provides the foundational formal specifications for Architecture Decision Records (ADRs)
as dependent types in Lean 4. Architectural governance decisions are represented as machine-checkable
records equipped with structural invariants, lifecycle transition constraints, embedded propositional
entailment semantics, and registry coherence properties.
-/

namespace Foundations.ADR

/-- Unique identifier for an Architecture Decision Record (e.g., "ADR-001"). -/
abbrev ADRId := String

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

/-- Formal lifecycle status of an Architecture Decision Record. -/
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

/-- The core Architecture Decision Record dependent structure. -/
structure ADR where
  /-- Unique identifier. -/
  id : ADRId
  /-- Descriptive title. -/
  title : String
  /-- Current lifecycle status. -/
  status : ADRStatus
  /-- Problem statement, context, and operational forces. -/
  context : String
  /-- Active decision or prescriptive rule. -/
  decision : String
  /-- Consequence propositions resulting from the decision. -/
  consequences : List String
  /-- Target ADR replaced by this record, if any. -/
  supersedes : Option ADRId
  /-- Linked code declarations, Git commits, or specifications. -/
  links : List ArtifactLink
  deriving DecidableEq, Repr, Inhabited

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
inductive PropTerm where
  | atom    : String → PropTerm
  | not     : PropTerm → PropTerm
  | and     : PropTerm → PropTerm → PropTerm
  | or      : PropTerm → PropTerm → PropTerm
  | implies : PropTerm → PropTerm → PropTerm
  deriving DecidableEq, Repr, Inhabited

/-- Semantic valuation of an embedded propositional term under an environment. -/
def PropTerm.eval (env : String → Prop) : PropTerm → Prop
  | .atom s      => env s
  | .not p       => ¬ (p.eval env)
  | .and p q     => p.eval env ∧ q.eval env
  | .or p q      => p.eval env ∨ q.eval env
  | .implies p q => p.eval env → q.eval env

/-- Decidable Boolean valuation of an embedded proposition under a Boolean environment.
This is the computational mirror of `PropTerm.eval` used by the registry's
semantic conflict checker. -/
def PropTerm.evalB (env : String → Bool) : PropTerm → Bool
  | .atom s      => env s
  | .not p       => !p.evalB env
  | .and p q     => p.evalB env && q.evalB env
  | .or p q      => p.evalB env || q.evalB env
  | .implies p q => !p.evalB env || q.evalB env

/-- **Soundness of Boolean evaluation.** The Boolean semantics agrees with the
propositional semantics whenever the two environments are coherent. -/
theorem PropTerm.evalB_sound (p : PropTerm) (envP : String → Prop) (envB : String → Bool)
    (h : ∀ s, envP s ↔ envB s = true) :
    (p.eval envP ↔ p.evalB envB = true) := by
  induction p with
  | atom s => exact h s
  | not p ih => simp [eval, evalB, ih]
  | and p q ihp ihq => simp [eval, evalB, ihp, ihq]
  | or p q ihp ihq => simp [eval, evalB, ihp, ihq]
  | implies p q ihp ihq =>
    simp only [eval, evalB]
    constructor
    · intro himp
      cases hp : p.evalB envB with
      | false => simp
      | true =>
        cases hq : q.evalB envB with
        | true => simp
        | false =>
          exfalso
          have hqe : q.evalB envB = true := ihq.mp (himp (ihp.mpr hp))
          rw [hq] at hqe
          exact Bool.noConfusion hqe
    · intro hor hpe
      rw [ihp.mp hpe] at hor
      simp at hor
      exact ihq.mpr hor

/-- Semantic entailment: every environment satisfying all premises satisfies the conclusion. -/
def Entails (premises : List PropTerm) (consequence : PropTerm) : Prop :=
  ∀ (env : String → Prop), (∀ p ∈ premises, p.eval env) → consequence.eval env

/-- **Semantic contradiction between compound formulas.**
Two propositions are contradictory when *no* Boolean environment satisfies both.
Unlike syntactic string-level checks, this detects conflicts between arbitrary
compound decisions (e.g. `WritesEnabled ∧ CacheCoherent` vs `¬WritesEnabled`),
at the cost of requiring proof effort per pair rather than a single decidable
syntactic test. Soundness is unconditional; completeness for large claim sets
is bounded by shared-vocabulary case analysis. -/
def Contradictory (p q : PropTerm) : Prop :=
  ∀ env : String → Bool, ¬ (p.evalB env && q.evalB env)

/-- Contradiction is symmetric. -/
theorem contradictory_symm {p q : PropTerm} (h : Contradictory p q) :
    Contradictory q p := by
  intro env hconj
  rw [Bool.and_comm] at hconj
  exact h env hconj

/-- A witness environment jointly satisfying two propositions certifies
non-contradiction. This is the constructive workhorse for discharging
`noClaimConflicts` obligations on concrete registries. -/
theorem not_contradictory_of_jointly_satisfied {p q : PropTerm}
    (env : String → Bool) (h : (p.evalB env && q.evalB env) = true) :
    ¬ Contradictory p q :=
  fun hall => hall env h

/-! ## Lifecycle State Transition Calculus -/

/-- Valid governance state transitions between ADR lifecycle states. -/
inductive ValidTransition : ADRStatus → ADRStatus → Option ADRId → Prop where
  /-- A proposed ADR may be accepted without superseding. -/
  | proposeToAccept :
      ValidTransition .Proposed .Accepted none
  /-- A proposed ADR may be rejected/deprecated directly. -/
  | proposeToDeprecate :
      ValidTransition .Proposed .Deprecated none
  /-- An accepted ADR can only become superseded by an explicit successor ADR. -/
  | acceptToSupersede (successorId : ADRId) :
      ValidTransition .Accepted .Superseded (some successorId)
  /-- An accepted ADR may be deprecated without replacement. -/
  | acceptToDeprecate :
      ValidTransition .Accepted .Deprecated none

/-! ## Registry and Graph Invariants -/

/-- Direct supersession relation on ADR identifiers within a collection. -/
def SupersedesRel (adrs : List ADR) (child parent : ADRId) : Prop :=
  ∃ a ∈ adrs, a.id = child ∧ a.supersedes = some parent

/-- Reflexive-transitive closure of supersession (historical provenance path). -/
inductive ProvenancePath (adrs : List ADR) : ADRId → ADRId → Prop where
  | refl (id : ADRId) :
      ProvenancePath adrs id id
  | step (child intermediate parent : ADRId) :
      SupersedesRel adrs child intermediate →
      ProvenancePath adrs intermediate parent →
      ProvenancePath adrs child parent

/-- Acyclicity constraint on the supersession graph: no ADR can strictly supersede itself. -/
def StrictAcyclic (adrs : List ADR) : Prop :=
  ∀ id : ADRId, ¬ (∃ parent : ADRId, SupersedesRel adrs id parent ∧ ProvenancePath adrs parent id)

/-- Architectural conflict predicate: two active decisions are mutually incompatible.
This is the *syntactic* layer: it catches literal negation-shaped decision strings
but not compound-formula contradictions. The semantic layer is `Contradictory`
over embedded `PropTerm` claims, enforced by `ADRRegistry.noClaimConflicts`. -/
def ConflictsWith (a b : ADR) : Prop :=
  a.id ≠ b.id ∧ a.status = .Accepted ∧ b.status = .Accepted ∧
  (a.decision = "NOT(" ++ b.decision ++ ")" ∨ b.decision = "NOT(" ++ a.decision ++ ")")

/-- Decidable Boolean conflict test between two records. -/
def ConflictsWithB (a b : ADR) : Bool :=
  (a.id != b.id) &&
  (match a.status, b.status with
   | .Accepted, .Accepted => true
   | _, _ => false) &&
  (a.decision == "NOT(" ++ b.decision ++ ")" || b.decision == "NOT(" ++ a.decision ++ ")")

/-- Soundness of the Boolean conflict test. -/
theorem conflicts_with_sound (a b : ADR) (h : ConflictsWith a b) : ConflictsWithB a b = true := by
  rcases h with ⟨hne, ha, hb, hdisj⟩
  simp only [ConflictsWithB, ha, hb]
  have hneB : (a.id != b.id) = true := by
    rw [bne_iff_ne]
    exact hne
  rw [hneB]
  simp only [Bool.true_and]
  rcases hdisj with hd | hd
  · simp [hd]
  · simp [hd]

/-- Computable decision procedure checking absence of syntactic conflicts in a list of ADRs. -/
def ADRListNoConflicts (adrs : List ADR) : Bool :=
  adrs.all (fun a => adrs.all (fun b => !ConflictsWithB a b))

/-- Soundness of list-level syntactic conflict checking. -/
theorem no_conflicts_of_list_check (adrs : List ADR) (h : ADRListNoConflicts adrs = true) :
    ∀ a ∈ adrs, ∀ b ∈ adrs, ¬ ConflictsWith a b := by
  intro a ha b hb hconf
  have hB := conflicts_with_sound a b hconf
  simp only [ADRListNoConflicts, List.all_eq_true] at h
  have hall_a := h a ha
  have hall_b := hall_a b hb
  simp only [hB, Bool.not_true] at hall_b
  exact Bool.noConfusion hall_b

/-- An embedded formal claim asserted by an accepted ADR. -/
structure Claim where
  /-- Owning ADR identifier. -/
  owner : ADRId
  /-- Embedded proposition the accepted decision commits to. -/
  claim : PropTerm
  deriving DecidableEq, Repr, Inhabited

/-- Comprehensive consistency predicate for an entire ADR registry. -/
structure ADRRegistry where
  /-- Complete list of registered ADRs. -/
  adrs : List ADR
  /-- All record identifiers are unique. -/
  uniqueIds : (adrs.map ADR.id).Nodup
  /-- The supersession graph contains no cycles. -/
  acyclic : StrictAcyclic adrs
  /-- Every referenced superseded target exists in the registry. -/
  supersedesExist : ∀ a ∈ adrs, ∀ sid, a.supersedes = some sid → ∃ target ∈ adrs, target.id = sid
  /-- Every superseded ADR has status Superseded. -/
  supersededStatusConsistent :
    ∀ a ∈ adrs, ∀ sid, a.supersedes = some sid →
      ∃ target ∈ adrs, target.id = sid ∧ target.status = .Superseded
  /-- Absence of syntactically conflicting accepted decisions. -/
  noConflicts : ∀ a ∈ adrs, ∀ b ∈ adrs, ¬ ConflictsWith a b
  /-- Embedded propositional claims asserted by active records. -/
  claims : List Claim
  /-- Every embedded claim is owned by an Accepted record in the registry. -/
  claimsOwnedByAccepted :
    ∀ c ∈ claims, ∃ a ∈ adrs, a.id = c.owner ∧ a.status = .Accepted
  /-- Semantic coherence: no two claims owned by distinct records are contradictory. -/
  noClaimConflicts :
    ∀ c₁ ∈ claims, ∀ c₂ ∈ claims,
      c₁.owner ≠ c₂.owner → ¬ Contradictory c₁.claim c₂.claim

end Foundations.ADR
