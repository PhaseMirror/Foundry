/-
F1 square — **the pre-Hilbert layer, brick 50** (`MomentPairingLaws.lean`): **THE MOMENT PAIRING
IS SYMMETRIC AND UNIFORMLY BOUNDED** — the two laws that make brick 49's `⟪φ, ψ⟫` behave like an
inner product rather than an arbitrary limit:

    `⟪φ, ψ⟫ ≈ ⟪ψ, φ⟫`                     (`crossMomL2_symm`)
    `|⟪φ, ψ⟫| ≤ 2·M_φ·M_ψ`                (`crossMomL2_abs_le`)

Symmetry is not free, because the two limits are taken along *different rescale schedules*:
`crossScale φ ψ` and `crossScale ψ φ` are equal only up to `Nat.mul_comm`, so the sequences are
not syntactically the same. Rewriting by `crossScale_comm` aligns the cuts, and then the finite
`innerN_symm` matches the sequences termwise, so `Rlim_congr` transfers the equality.

The bound is the pairing's window bound read from the cut `a = 0`: *every* partial cross sum is
already within `2·M_φ·M_ψ` of zero (a window from `0` of any length), so the limit inherits the
bound from both sides — `Rlim_le_ofQ` above and `const_le_Rlim` below. On the diagonal it
recovers `momentL2Sq φ ≤ 2·M_φ²`, brick 40's bound, from the pairing side.

HONEST SCOPE. Two algebraic laws for the `ℓ²` pairing of moment sequences of bounded-Lipschitz
tests on `[0,1]`. Nothing here touches the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MomentPairing

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The rescale schedule is symmetric — up to `Nat.mul_comm`, which is exactly why symmetry of
    the pairing needs an argument. -/
theorem crossScale_comm (φ ψ : L2Test) : crossScale φ ψ = crossScale ψ φ := by
  show 2 * (φ.M.num.natAbs * ψ.M.num.natAbs) + 1
      = 2 * (ψ.M.num.natAbs * φ.M.num.natAbs) + 1
  rw [Nat.mul_comm φ.M.num.natAbs ψ.M.num.natAbs]

/-- **THE PAIRING IS SYMMETRIC**: `⟪φ, ψ⟫ ≈ ⟪ψ, φ⟫`. The cuts are aligned by `crossScale_comm`,
    after which `innerN_symm` matches the two sequences termwise. -/
theorem crossMomL2_symm (φ ψ : L2Test) : Req (crossMomL2 φ ψ) (crossMomL2 ψ φ) := by
  refine Rlim_congr _ _ (crossIdx_RReg φ ψ) (crossIdx_RReg ψ φ) (fun j => ?_)
  show Req (crossMomSum φ ψ (crossScale φ ψ * (j + 1)))
    (crossMomSum ψ φ (crossScale ψ φ * (j + 1)))
  rw [crossScale_comm φ ψ]
  exact innerN_symm (momSeq φ) (momSeq ψ) _

-- ===========================================================================
-- The uniform bound.
-- ===========================================================================

/-- Every cross partial sum is a window from the cut `0`, hence within `2·M_φ·M_ψ` of zero. -/
theorem crossMomSum_abs_le (φ ψ : L2Test) (N : Nat) :
    Rle (Rabs (crossMomSum φ ψ N)) (ofQ (crossBound φ ψ 0) (crossBound_den φ ψ 0)) := by
  have h := crossMomSum_diff_abs_le φ ψ 0 N
  rw [Nat.zero_add] at h
  refine Rle_trans (Rle_of_Req (Rabs_congr ?_)) h
  show Req (crossMomSum φ ψ N) (Rsub (crossMomSum φ ψ N) zero)
  exact Req_symm (Req_trans (Radd_congr (Req_refl _) Rneg_zero) (Radd_zero _))

/-- **THE PAIRING IS UNIFORMLY BOUNDED**: `|⟪φ, ψ⟫| ≤ 2·M_φ·M_ψ`. -/
theorem crossMomL2_abs_le (φ ψ : L2Test) :
    Rle (Rabs (crossMomL2 φ ψ)) (ofQ (crossBound φ ψ 0) (crossBound_den φ ψ 0)) := by
  refine Rabs_le_of_both ?_ ?_
  · exact Rlim_le_ofQ (crossIdx_RReg φ ψ) (crossBound_den φ ψ 0)
      (fun k => Rle_of_Rabs_le (crossMomSum_abs_le φ ψ (crossScale φ ψ * (k + 1))))
  · -- the lower side: `−(2M_φM_ψ) ≤ ⟪φ,ψ⟫`, then flip
    have hlow : Rle (Rneg (ofQ (crossBound φ ψ 0) (crossBound_den φ ψ 0))) (crossMomL2 φ ψ) := by
      refine const_le_Rlim (crossIdx_RReg φ ψ) (fun k => ?_)
      refine Rle_trans (Rle_Rneg (Rle_of_Rabs_le
        (Rle_trans (Rle_of_Req (Rabs_Rneg _))
          (crossMomSum_abs_le φ ψ (crossScale φ ψ * (k + 1)))))) ?_
      exact Rle_of_Req (Rneg_neg _)
    refine Rle_trans (Rle_Rneg hlow) ?_
    exact Rle_of_Req (Rneg_neg _)

/-- On the diagonal the bound reads `momentL2Sq φ ≤ 2·M_φ²` — brick 40's bound, recovered from
    the pairing side. -/
theorem momentL2Sq_le_via_pairing (φ : L2Test) :
    Rle (momentL2Sq φ) (ofQ (crossBound φ φ 0) (crossBound_den φ φ 0)) :=
  Rle_trans (Rle_of_Req (Req_symm (crossMomL2_diag φ)))
    (Rle_of_Rabs_le (crossMomL2_abs_le φ φ))

end Multiplicity.UOR.Bridge.F1Square.Square
