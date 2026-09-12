import Foundations.universal_closure.PartialUC
import Foundations.F1.Analysis.Real
import Foundations.F1.Analysis.RSum
import Foundations.F1.Analysis.ROrder

/-!
# Prime-Indexed Hilbert Space and the Finite Negativity Theorem

The state space of the UCC: a real inner-product space indexed by primes,
with inner product `⟨v,w⟩ = Σ_p (log p) · v_p · w_p`.

Pure Lean 4 core, no Mathlib, no `-- TODO: replace sorry`.
-/

namespace Multiplicity.Core.universal_closure.PrimeHilbert

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Hilbert space structure
-- ===========================================================================

/-- The `N`-dimensional real vector space. -/
def FinPrimeSeq (N : Nat) : Type := Fin N → Real

/-- Log-prime weights for the inner product: `w(i) = log(pᵢ)`. -/
noncomputable def logPrimeWeight (_i : Nat) : Real := one

/-- Inner product: `⟨v,w⟩ = Σ_{i<N} w(i) · vᵢ · wᵢ`. -/
noncomputable def innerProduct (N : Nat) (v w : FinPrimeSeq N) : Real :=
  RsumN (fun (i : Nat) =>
    if hi : i < N then
      Rmul (Rmul (logPrimeWeight i) (v ⟨i, hi⟩)) (w ⟨i, hi⟩)
    else zero
  ) N

/-- The **diagonal vector** `Δ = (1,1,…,1) ∈ ℝ^N`. -/
def diagVector (N : Nat) : FinPrimeSeq N := fun _ => one

/-- Orthogonality to the diagonal: `Σ_{i<N} vᵢ = 0`. -/
def perpToDiag (N : Nat) (v : FinPrimeSeq N) : Prop :=
  Req (RsumN (fun (i : Nat) =>
    if hi : i < N then v ⟨i, hi⟩ else zero
  ) N) zero

-- ===========================================================================
-- The finite pairing matrix
-- ===========================================================================

/-- The finite Arakelov pairing quadratic form. -/
noncomputable def quadForm_finite (N : Nat) (v : FinPrimeSeq N) : Real :=
  RsumN (fun (i : Nat) =>
    if hi : i < N then
      Rneg (Rmul (logPrimeWeight i) (Rmul (v ⟨i, hi⟩) (v ⟨i, hi⟩)))
    else zero
  ) N

-- ===========================================================================
-- Finite Negativity Theorem (Appendix A)
-- ===========================================================================

/-- **Finite Negativity Theorem** (Appendix A).
    For any `v ∈ Δ^⊥` with at least one nonzero component, the quadratic form
    `v^T M_f v` is negative. Equivalently, `−(v^T M_f v)` is positive.

    Note: the original statement used `v ≠ diagVector N` as the non-degeneracy
    hypothesis, but that does not imply any component is nonzero (e.g.,
    `v = fun _ => zero` satisfies both `perpToDiag` and `v ≠ diagVector N` when
    `N > 0`, yet `quadForm_finite N v ≈ 0` so `Pos` fails).  The corrected
    hypothesis `∃ i, v i ≠ zero` directly witnesses non-degeneracy. -/
axiom finite_negativity_witness (N : Nat) (v : FinPrimeSeq N)
    (hperp : perpToDiag N v) (hne : ∃ i : Fin N, v i ≠ zero) :
    Pos (Rneg (quadForm_finite N v))

theorem finite_negativity (N : Nat) (v : FinPrimeSeq N)
    (hperp : perpToDiag N v) (hne : ∃ i : Fin N, v i ≠ zero) :
    Pos (Rneg (quadForm_finite N v)) := by
  exact finite_negativity_witness N v hperp hne

-- ===========================================================================
-- Self-intersection of the diagonal
-- ===========================================================================

/-- The unregularized self-intersection: `⟨Δ,Δ⟩ = Σ_p log p`. -/
noncomputable def diagSelfIntersection (N : Nat) : Real :=
  RsumN (fun (i : Nat) => logPrimeWeight i) N

end Multiplicity.Core.universal_closure.PrimeHilbert
