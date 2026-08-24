import Lean

/-!
# FPES Core — Falsification-Preserving Experiment Selection (ADR-0029)

Formal core of the FPES production pipeline (ADR-0029, Decision ID
`ADR-FPES-001`, docs/ADR-0029-The FPES.md).  This module is **core Lean 4
only — no mathlib**.  Per ADR-0029 § Alternatives Considered and the Phase
Mirror layering rule, real-valued statements (`operator_norm < 1` over ℝ,
IEEE-754 edge cases, `f32::exp`/`f64::ln`) are deliberately **not** expressed
here; they are verified in the Rust/Kani layer for bounded inputs
(`strategy: stub_float_on_transcendentals`, `bounds.max_paths = 8`).

## Model

- `Path` / `EquivalenceClass`: an experiment selection trajectory and the
  equivalence class of mechanisms it probes.  Two paths are
  observationally equivalent (`Path.equivalentMechanism`) exactly when they
  probe the same class — same falsification power.
- `HypothesisSpace`: a finite list of paths plus the list of registered
  classes they are drawn from.
- Viability invariants (`NoDupClasses`, `Registered`, `ClassesNonempty`):
  these are the FPES "survival_invariant" preconditions under which a
  contraction is permitted (ADR-0029 §2).
- `countInClass` (a.k.a. `multiplicity`) and `firstPath`: the finite
  combinatorial core that both the Lean theorems and the Kani harnesses
  (`kani_fpes_001_*`, `kani_fpes_002_*`) implement.
- `contractToRepresentatives`: the canonical falsification-preserving
  contraction — keep exactly the first path of every class.
- `Proposal` / `Conflicting`: concurrent-proposal conflict detection
  (ADR-0029 § Edge cases: concurrent decision proposals).

## Conventions

Every definition carries a docstring.  The `@[fpes_adr]` / `@[fpes_proof]`
tag attributes are registered locally (the ADR-System's `ADR.Attributes`
module is a separate Lake package and cannot be imported from this library).
-/

namespace FPES

/-! ## Project attributes

Tag attributes mirroring `ADR.Attributes`: they mark, respectively, formally
registered FPES artifacts and machine-checked FPES proofs.  Queryable via
`fpesAdrAttr.ext` / `fpesProofAttr.ext`. -/

/-- Tag attribute for formally registered FPES artifacts (ADR-0029). -/
initialize fpesAdrAttr : Lean.TagAttribute ←
  Lean.registerTagAttribute `fpes_adr "FPES ADR registry tag" (fun _ => pure ())

/-- Tag attribute for machine-checked FPES theorems (ADR-0029). -/
initialize fpesProofAttr : Lean.TagAttribute ←
  Lean.registerTagAttribute `fpes_proof "FPES theorem tag" (fun _ => pure ())

/-! ### Mechanisms, paths, and equivalence classes -/

/-- A mechanism: the formal denotation of an experiment.  Mechanisms are
grouped into equivalence classes; every path probes exactly one class. -/
structure Mechanism where
  id : Nat
  deriving Repr, BEq, DecidableEq

/-- An equivalence class of mechanisms: all paths in the class carry the
same falsification power, so any single survivor per class is sufficient
(FPES-MULTIPLICITY-001). -/
structure EquivalenceClass where
  id : Nat
  deriving Repr, BEq, DecidableEq

/-- A path: an experiment-selection trajectory.  `cls` is the id of the
equivalence class it probes. -/
structure Path where
  id : Nat
  cls : Nat
  deriving Repr, BEq, DecidableEq

/-- `Path.inClass p c`: the path `p` probes the equivalence class `c`. -/
def Path.inClass (p : Path) (c : EquivalenceClass) : Prop :=
  p.cls = c.id

/-- `Path.equivalentMechanism p p'`: two paths realize the same mechanism
(observe the same equivalence class).  This is the ADR-0029 §2
`equivalent_mechanism` relation. -/
def Path.equivalentMechanism (p p' : Path) : Prop :=
  p.cls = p'.cls

/-! ### Hypothesis space -/

/-- A hypothesis space: the finite pool of candidate experiment paths and
the registered classes they are drawn from.  The space itself is raw data;
viability is decided by the invariants below (so an invalid space can never
be *constructed* into the pipeline, only rejected by the type system). -/
structure HypothesisSpace where
  paths : List Path
  classes : List EquivalenceClass
  deriving Repr, BEq

/-! ### Counting and selection (the combinatorial core) -/

/-- `countInClass l c`: number of paths in `l` probing class `c`.

Induction-friendly core of `multiplicity`; the Kani mirrors
(`count_in_class` in `Multiplicity/kani/src/proofs/fpes.rs`) implement the
same recurrence over bounded `[Path; 8]` arrays. -/
def countInClass : List Path → EquivalenceClass → Nat
  | [], _ => 0
  | p :: rest, c => if p.cls = c.id then countInClass rest c + 1 else countInClass rest c

/-- `firstPath l c`: the first path of `l` probing class `c`, if any.
The representative contraction keeps exactly this path. -/
def firstPath : List Path → EquivalenceClass → Option Path
  | [], _ => none
  | p :: rest, c => if p.cls = c.id then some p else firstPath rest c

/-! ### Viability invariants -/

/-- `NoDupClasses H`: the class list contains no duplicate ids — classes
are a set.  Required for the multiplicity-exactly-one discipline of the
representative contraction. -/
def NoDupClasses (H : HypothesisSpace) : Prop :=
  H.classes.Nodup

/-- `Registered H`: every path's class id is a registered class id.
Survival proofs need this to route a path to its class. -/
def Registered (H : HypothesisSpace) : Prop :=
  ∀ p ∈ H.paths, ∃ c ∈ H.classes, p.cls = c.id

/-- `multiplicity H c` (FPES-MULTIPLICITY-001): the number of paths of `H`
that probe class `c`, i.e. `|{p ∈ Paths : p ↝ c}|`. -/
def multiplicity (H : HypothesisSpace) (c : EquivalenceClass) : Nat :=
  countInClass H.paths c

/-- `ClassesNonempty H`: the ADR-0029 §2 `survival_invariant H` — every
registered equivalence class retains at least one path. -/
def ClassesNonempty (H : HypothesisSpace) : Prop :=
  ∀ c ∈ H.classes, 1 ≤ multiplicity H c

/-- `Viable H`: the conjunction of the FPES viability constraints.  A space
is admitted to the pipeline (and certified) only when `Viable H` holds. -/
def Viable (H : HypothesisSpace) : Prop :=
  NoDupClasses H ∧ Registered H ∧ ClassesNonempty H

/-! ### Decidability instances

Typeclass synthesis does not unfold ordinary `def`s, so `native_decide` and
`decide` need explicit instances.  All FPES predicates are decidable: they
are finite conjunctions/quantifications over concrete `List`s.  These
instances make `lake test`'s runtime checks and the `native_decide` proofs
evaluable — while the *theorems* in `Proofs.lean` remain the real contract. -/

/-- Decidability of `NoDupClasses`. -/
instance decNoDupClasses (H : HypothesisSpace) : Decidable (NoDupClasses H) := by
  unfold NoDupClasses
  infer_instance

/-- Decidability of `Registered`. -/
instance decRegistered (H : HypothesisSpace) : Decidable (Registered H) := by
  unfold Registered
  infer_instance

/-- Decidability of `ClassesNonempty`. -/
instance decClassesNonempty (H : HypothesisSpace) : Decidable (ClassesNonempty H) := by
  unfold ClassesNonempty
  infer_instance

/-- Decidability of `Viable`. -/
instance decViable (H : HypothesisSpace) : Decidable (Viable H) := by
  unfold Viable
  infer_instance

/-! ### Representative selection (implementation of the contraction) -/

/-- `repsGo classes paths`: one representative path per class, in class
order.  Defined by recursion so that membership (`repsGo_mem`) and counting
are provable in core Lean without a `filterMap` membership lemma. -/
def repsGo : List EquivalenceClass → List Path → List Path
  | [], _ => []
  | c :: rest, paths =>
      match firstPath paths c with
      | none => repsGo rest paths
      | some p => p :: repsGo rest paths

/-- `representatives H`: the contracted path list — one survivor per
registered class of `H`. -/
def representatives (H : HypothesisSpace) : List Path :=
  repsGo H.classes H.paths

/-! ### Contraction -/

/-- A contraction operator: a (possibly partial) pruning of a hypothesis
space.  Mirror of the ADR-0029 §2 `ContractionOperator`; the ℝ-valued
`operator_norm` contract is deliberately not modeled in core Lean — see the
module header. -/
structure ContractionOperator where
  apply : HypothesisSpace → HypothesisSpace

/-- `contractToRepresentatives H`: the canonical falsification-preserving
contraction — keep exactly the first path of every registered class. -/
def contractToRepresentatives (H : HypothesisSpace) : HypothesisSpace :=
  { paths := representatives H, classes := H.classes }

/-- The representative contraction as a `ContractionOperator`. -/
def opRep : ContractionOperator :=
  { apply := contractToRepresentatives }

/-- `Survival H H'`: every path of `H` has an observationally equivalent
survivor in `H'` (ADR-0029 §2: `∀ p ∈ H.paths, ∃ p' ∈ H'.paths,
equivalent_mechanism p p'`). -/
def Survival (H H' : HypothesisSpace) : Prop :=
  ∀ p ∈ H.paths, ∃ p' ∈ H'.paths, Path.equivalentMechanism p p'

/-- `FalsificationPreserving H H'`: every class that was nonempty in `H`
remains nonempty in `H'`.  The combinatorial avatar of the ADR-0029
`operator_norm < 1` survival contract; a real-norm version over mathlib's
`ContinuousLinearMap` is deliberately deferred to the Kani layer. -/
def FalsificationPreserving (H H' : HypothesisSpace) : Prop :=
  ∀ c ∈ H.classes, 1 ≤ multiplicity H c → 1 ≤ multiplicity H' c

/-- `Contractive op H`: the operator `op` is a sound contraction of `H` when
it preserves falsification power.  In core Lean this stands in for the
real-norm hypothesis `operator_norm op < 1` of ADR-0029 §2; the Kani layer
checks the concrete float kernel. -/
def Contractive (op : ContractionOperator) (H : HypothesisSpace) : Prop :=
  FalsificationPreserving H (op.apply H)

/-! ### Concurrent proposals and conflict detection -/

/-- A proposal: a candidate selection policy for a hypothesis space.  The
field `select` picks the representative path for a class (or `none` when the
class has none). -/
structure Proposal where
  name : String
  select : HypothesisSpace → EquivalenceClass → Option Path

/-- `Conflicting H P Q c`: the proposals `P` and `Q` each select a path for
class `c`, and the selections differ.  Concurrent proposals that conflict on
a class cannot both be applied without breaking the multiplicity discipline
(ADR-0029 § Edge cases). -/
def Conflicting (H : HypothesisSpace) (P Q : Proposal) (c : EquivalenceClass) : Prop :=
  P.select H c ≠ none ∧ Q.select H c ≠ none ∧ P.select H c ≠ Q.select H c

/-- Decidability of `Conflicting`. -/
instance decConflicting (H : HypothesisSpace) (P Q : Proposal) (c : EquivalenceClass) :
    Decidable (Conflicting H P Q c) := by
  unfold Conflicting
  infer_instance

end FPES
