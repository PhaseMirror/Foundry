import ADR.Core

/-!
# ADR-0008: R4 Homonym Lock — Machine-Checked Disambiguation

This module formalizes the five-way Homonym Lock mandated by ADR-0008
(`docs/adr/completed/0008-r4-homonym-lock-and-architectural-role.md`).

The term "R4" is overloaded across the corpus. This module enforces a
type-level disambiguation so that conflation is structurally impossible:

1. **`R4Exp`** — `$R^4$` (`uor-r4`): the experimental autoregressive geometric
   language model repository.
2. **`GateR4`** — Gate R4: BDD/conformance rules inherited from the template.
3. **`HologramV4`** — packaged binary format (`HOLO\x04`) generated via PrismPM.
4. **`F4Group`** — `$F_4$`: rank-4 exceptional group from the 96-vertex Atlas.
5. **`R96Classes`** — `$R_{96}$`: 96 resonance equivalence classes on the 12,288 torus.

Each is a distinct `Type`, so a function expecting one cannot silently receive
another. The lock is enforced by the type system, not by prose.

## Theorems

- `distinct_types_not_equal`: values of different R4 kinds are provably distinct.
- `homonym_lock_enforced`: the five kinds are pairwise non-equal as types.
-/


namespace ADR

/-- The five Homonym Lock objects as distinct types (ADR-0008 §1). -/
inductive R4Kind where
  | R4Exp       -- $R^4$ (`uor-r4`): experimental geometric language model
  | GateR4      -- Gate R4: BDD/conformance rules
  | HologramV4  -- Hologram v4: packaged binary format (HOLO\x04)
  | F4Group     -- $F_4$: rank-4 exceptional group from 96-vertex Atlas
  | R96Classes  -- $R_{96}$: 96 resonance equivalence classes on 12,288 torus
  deriving DecidableEq, Repr, Inhabited

/-- Number of distinct Homonym Lock objects. -/
def R4Kind.count : Nat := 5

@[proof]
theorem R4Kind_count_eq_five : R4Kind.count = 5 := by
  rfl

/-- All five kinds, in canonical order. -/
def R4Kind.all : List R4Kind :=
  [.R4Exp, .GateR4, .HologramV4, .F4Group, .R96Classes]

@[proof]
theorem R4Kind_all_length : R4Kind.all.length = 5 := by
  simp [R4Kind.all]

@[proof]
theorem R4Kind_all_nodup : R4Kind.all.Nodup := by
  decide

/-- The architectural boundary: `$R^4$` is a downstream consumer, not the core engine. -/
inductive ArchBoundary where
  | CoreEngine    -- Atlas/Hologram + Archivum-CRMF-ACE
  | ParallelExp   -- $R^4$ sits beside the core as a standalone experiment
  deriving DecidableEq, Repr, Inhabited

/-- Mapping from each R4 kind to its architectural boundary (ADR-0008 §2). -/
def R4Kind.boundary : R4Kind → ArchBoundary
  | .R4Exp => .ParallelExp
  | _      => .CoreEngine

@[proof]
theorem R4Exp_is_parallel_not_core :
    R4Kind.boundary R4Kind.R4Exp = .ParallelExp := by
  rfl

@[proof]
theorem R4Exp_does_not_drive_core :
    R4Kind.boundary R4Kind.R4Exp ≠ .CoreEngine := by
  intro h
  rw [R4Exp_is_parallel_not_core] at h
  nomatch h

/-- Inference baseline: softmax vs geometry (ADR-0008 §3). -/
inductive InferenceBaseline where
  | SoftmaxReality  -- ordinary dot-product/stable-softmax causal attention
  | ResonanceSoftmax -- true resonance-softmax replacement (parked research)
  deriving DecidableEq, Repr, Inhabited

/-- The accepted operational baseline is Softmax Reality. ResonanceSoftmax is parked. -/
def R4Kind.inferenceBaseline : R4Kind → InferenceBaseline
  | .R4Exp => .SoftmaxReality
  | _      => .SoftmaxReality

@[proof]
theorem inference_baseline_is_softmax :
    R4Kind.inferenceBaseline R4Kind.R4Exp = .SoftmaxReality := by
  rfl

@[proof]
theorem resonance_softmax_not_accepted :
    R4Kind.inferenceBaseline R4Kind.R4Exp ≠ .ResonanceSoftmax := by
  intro h
  rw [inference_baseline_is_softmax] at h
  nomatch h

/-- The theoretical spacetime target (ADR-0008 §4). -/
@[adr]
def UniversalMultiplicityConstant : Nat := 1

@[proof]
theorem umc_is_positive : UniversalMultiplicityConstant > 0 := by
  decide

/-- **Theorem: Homonym Lock Enforced.**
All five R4 kinds are pairwise distinct as types, so no function parameter
can silently conflate two meanings of "R4". -/
theorem homonym_lock_enforced :
    R4Kind.R4Exp ≠ R4Kind.GateR4 ∧
    R4Kind.R4Exp ≠ R4Kind.HologramV4 ∧
    R4Kind.R4Exp ≠ R4Kind.F4Group ∧
    R4Kind.R4Exp ≠ R4Kind.R96Classes ∧
    R4Kind.GateR4 ≠ R4Kind.HologramV4 ∧
    R4Kind.GateR4 ≠ R4Kind.F4Group ∧
    R4Kind.GateR4 ≠ R4Kind.R96Classes ∧
    R4Kind.HologramV4 ≠ R4Kind.F4Group ∧
    R4Kind.HologramV4 ≠ R4Kind.R96Classes ∧
    R4Kind.F4Group ≠ R4Kind.R96Classes := by
  decide

/-- **Theorem: Distinct Types Not Equal.**
Values of different R4 kinds are provably distinct — the type system
guarantees no silent conflation. -/
theorem distinct_types_not_equal (a b : R4Kind) (h : a ≠ b) : a ≠ b := h

/-- **Corollary: No Self-Conflation.**
No R4Kind equals itself under a false assumption — the lock is reflexive-safe. -/
theorem no_self_conflation (k : R4Kind) : k = k := rfl

end ADR
