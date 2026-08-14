import Multiplicity.F1.Multiplicity.Axioms

/-!
# Zeta–Multiplicity transform layer

Definitions and derived facts about 𝓕_Λ and its trace coefficients, from the
axioms in `Axioms.lean`.
-/

namespace Multiplicity.RHMultiplicity

/-- The trace coefficient sequence `n ↦ Tr(Π_n T)` summed by the transform. -/
noncomputable def TrSeq (T : TInfinity Nat) (n : Nat) : Rat := TraceProj T n

/-- Every trace coefficient is non-negative (from `trace_coeff_nonneg`). -/
theorem trace_nonneg (T : TInfinity Nat) (n : Nat) (hn : 1 ≤ n) :
    0 ≤ TrSeq T n :=
  trace_coeff_nonneg T n hn

/-- The transform is determined by its trace coefficients (from
`transform_identity`): operators with identical trace sequences have
identical transforms, which is the coefficient-level reflection of the
Dirichlet-series identity 𝓕_Λ(T, s) = Σ_n Tr(Π_n T) / n^s. -/
theorem transform_determined_by_traces {T T' : TInfinity Nat}
    (h : ∀ n : Nat, TrSeq T n = TrSeq T' n) (s : Rat) :
    ZetaMultiplicityTransform T s = ZetaMultiplicityTransform T' s :=
  transform_identity T T' h s

/-- The canonical trace sequence `n ↦ Tr(Π_n T)` for the Zeta operator. -/
noncomputable def ZetaTraceSeq (n : Nat) : Rat := TrSeq ZetaOperator n

/-- Non-negativity of the canonical trace sequence. -/
theorem zeta_trace_nonneg (n : Nat) (hn : 1 ≤ n) : 0 ≤ ZetaTraceSeq n :=
  trace_nonneg ZetaOperator n hn

end Multiplicity.RHMultiplicity
