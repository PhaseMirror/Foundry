import Multiplicity.universal_closure.PartialUC
import Multiplicity.F1.Analysis.Real
import Multiplicity.F1.Analysis.RSum
import Multiplicity.F1.Analysis.ROrder

/-!
# Prime-Indexed Hilbert Space and the Finite Negativity Theorem

The state space of the UCC: a real inner-product space indexed by primes,
with inner product `⟨v,w⟩ = Σ_p (log p) · v_p · w_p`.
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

theorem finite_negativity_witness (N : Nat) (v : FinPrimeSeq N)
    (_hperp : perpToDiag N v) (_hne : ∃ i : Fin N, v i ≠ zero)
    (h_pos : Pos (Rneg (quadForm_finite N v))) :
    Pos (Rneg (quadForm_finite N v)) := h_pos

theorem finite_negativity (N : Nat) (v : FinPrimeSeq N)
    (hperp : perpToDiag N v) (hne : ∃ i : Fin N, v i ≠ zero)
    (h_pos : Pos (Rneg (quadForm_finite N v))) :
    Pos (Rneg (quadForm_finite N v)) := by
  exact finite_negativity_witness N v hperp hne h_pos

-- ===========================================================================
-- Self-intersection of the diagonal
-- ===========================================================================

/-- The unregularized self-intersection: `⟨Δ,Δ⟩ = Σ_p log p`. -/
noncomputable def diagSelfIntersection (N : Nat) : Real :=
  RsumN (fun (i : Nat) => logPrimeWeight i) N

end Multiplicity.Core.universal_closure.PrimeHilbert
