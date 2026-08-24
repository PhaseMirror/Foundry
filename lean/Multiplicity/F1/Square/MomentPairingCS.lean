/-
F1 square — **the pre-Hilbert layer, brick 51** (`MomentPairingCS.lean`): **CAUCHY–SCHWARZ AT
THE LIMIT** — brick 46's uniform bound on the *finite* cross sums is upgraded to the pairing
itself:

    `⟪φ, ψ⟫²  ≤  ⟪φ, φ⟫ · ⟪ψ, ψ⟫  =  momentL2Sq φ · momentL2Sq ψ`   (`crossMomL2_sq_le`).

With brick 49's convergence, brick 50's symmetry and bound, and this, the moment sequences carry
the full sqrt-free inner-product geometry: a symmetric bilinear pairing, its diagonal the `ℓ²`
energy, obeying Cauchy–Schwarz.

Passing a *squared* bound through a Bishop limit is the interesting step, since the substrate has
no square root and `Rlim` does not commute with multiplication. The route avoids both: by the
difference-of-squares identity `x² − X² = (x − X)(x + X)`, the gap between the limit's square and
a partial sum's square is a PRODUCT of two controlled factors — one small (`|x − X_k| ≤ 2/(k+1)`,
the convergence rate) and one merely bounded (`|x + X_k| ≤ 2·(2M_φM_ψ)`, brick 50 applied to both
terms). So the whole gap is `O(1/(k+1))` for every `k`, and `Rle_of_Rsub_le_eps` — the
Archimedean criterion — converts "below the target up to `C/(k+1)` for all `k`" into "below the
target". No expansion of `(X + e)²`, and no square root, is needed.

HONEST SCOPE. Cauchy–Schwarz for the `ℓ²` pairing of moment sequences of bounded-Lipschitz tests
on `[0,1]`. Nothing here touches the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MomentPairingLaws

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `|a − b| = |b − a|` (local: the copy in brick 49 is private). -/
private theorem abs_Rsub_swap (a b : Real) : Req (Rabs (Rsub a b)) (Rabs (Rsub b a)) :=
  Req_trans (Req_symm (Rabs_Rneg (Rsub a b))) (Rabs_congr (Rneg_Rsub_flip a b))

/-- Twice the pairing bound, with the denominator kept flat. -/
def crossTwo (φ ψ : L2Test) : Q := ⟨4 * φ.M.num * ψ.M.num, φ.M.den * ψ.M.den⟩

theorem crossTwo_den (φ ψ : L2Test) : 0 < (crossTwo φ ψ).den :=
  Nat.mul_pos φ.hMd ψ.hMd

theorem crossTwo_num (φ ψ : L2Test) : 0 ≤ (crossTwo φ ψ).num :=
  Int.mul_nonneg (Int.mul_nonneg (by decide) φ.hMn) ψ.hMn

theorem crossBound_add_self (φ ψ : L2Test) :
    Qeq (add (crossBound φ ψ 0) (crossBound φ ψ 0)) (crossTwo φ ψ) := by
  simp only [Qeq, add, crossBound, crossTwo]
  push_cast
  ring_uor

/-- **The sum of the limit and a partial sum is bounded** by twice the pairing bound. -/
theorem crossMomL2_add_idx_abs_le (φ ψ : L2Test) (k : Nat) :
    Rle (Rabs (Radd (crossMomL2 φ ψ) (crossIdx φ ψ k)))
      (ofQ (crossTwo φ ψ) (crossTwo_den φ ψ)) := by
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add (crossMomL2_abs_le φ ψ)
    (crossMomSum_abs_le φ ψ (crossScale φ ψ * (k + 1)))) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (crossBound_den φ ψ 0) (crossBound_den φ ψ 0))) ?_
  exact Rle_of_Req (ofQ_congr _ (crossTwo_den φ ψ) (crossBound_add_self φ ψ))

/-- The rational gap bound `(2/(k+1))·(2M_φM_ψ)` is below `4·crossScale/(k+1)`. -/
theorem crossGap_le (φ ψ : L2Test) (k : Nat) :
    Qle (mul (⟨2, k + 1⟩ : Q) (crossTwo φ ψ))
      (⟨((4 * crossScale φ ψ : Nat) : Int), k + 1⟩ : Q) := by
  show 2 * (4 * φ.M.num * ψ.M.num) * ((k + 1 : Nat) : Int)
      ≤ ((4 * crossScale φ ψ : Nat) : Int)
        * (((k + 1) * (φ.M.den * ψ.M.den) : Nat) : Int)
  have hnφ : ((φ.M.num.natAbs : Nat) : Int) = φ.M.num := Int.natAbs_of_nonneg φ.hMn
  have hnψ : ((ψ.M.num.natAbs : Nat) : Int) = ψ.M.num := Int.natAbs_of_nonneg ψ.hMn
  push_cast
  have hS : ((crossScale φ ψ : Nat) : Int) = 2 * (φ.M.num * ψ.M.num) + 1 := by
    show ((2 * (φ.M.num.natAbs * ψ.M.num.natAbs) + 1 : Nat) : Int) = _
    push_cast
    rw [hnφ, hnψ]
  have hK : (0 : Int) ≤ (k : Int) + 1 := by omega
  have hD : (1 : Int) ≤ (φ.M.den : Int) * (ψ.M.den : Int) := by
    have h1 : (1 : Int) ≤ (φ.M.den : Int) := by have := φ.hMd; omega
    have h2 : (1 : Int) ≤ (ψ.M.den : Int) := by have := ψ.hMd; omega
    exact Int.mul_le_mul h1 h2 (by decide) (by omega)
  have h4Snn : (0 : Int) ≤ 4 * ((crossScale φ ψ : Nat) : Int) := by
    have := Int.ofNat_nonneg (crossScale φ ψ); omega
  have hSP4 : 8 * (φ.M.num * ψ.M.num) ≤ 4 * ((crossScale φ ψ : Nat) : Int) := by
    rw [hS]; omega
  have h1 : 8 * (φ.M.num * ψ.M.num) * ((k : Int) + 1)
      ≤ 4 * ((crossScale φ ψ : Nat) : Int) * ((k : Int) + 1) :=
    Int.mul_le_mul_of_nonneg_right hSP4 hK
  have h2 : 4 * ((crossScale φ ψ : Nat) : Int) * ((k : Int) + 1) * 1
      ≤ 4 * ((crossScale φ ψ : Nat) : Int) * ((k : Int) + 1)
        * ((φ.M.den : Int) * (ψ.M.den : Int)) :=
    Int.mul_le_mul_of_nonneg_left hD (Int.mul_nonneg h4Snn hK)
  have e1 : 2 * (4 * φ.M.num * ψ.M.num) * ((k : Int) + 1)
      = 8 * (φ.M.num * ψ.M.num) * ((k : Int) + 1) := by ring_uor
  have e2 : 4 * ((crossScale φ ψ : Nat) : Int)
        * (((k : Int) + 1) * ((φ.M.den : Int) * (ψ.M.den : Int)))
      = 4 * ((crossScale φ ψ : Nat) : Int) * ((k : Int) + 1)
        * ((φ.M.den : Int) * (ψ.M.den : Int)) := by ring_uor
  rw [e1, e2]
  omega

/-- **CAUCHY–SCHWARZ AT THE LIMIT**: `⟪φ,ψ⟫² ≤ momentL2Sq φ · momentL2Sq ψ`. -/
theorem crossMomL2_sq_le (φ ψ : L2Test) :
    Rle (Rmul (crossMomL2 φ ψ) (crossMomL2 φ ψ))
        (Rmul (momentL2Sq φ) (momentL2Sq ψ)) := by
  refine Rle_of_Rsub_le_eps (C := 4 * crossScale φ ψ) (fun k => ?_)
  -- drop the target to the partial sum's square (brick 46, at the rescaled cut)
  have hXsq : Rle (Rmul (crossIdx φ ψ k) (crossIdx φ ψ k))
      (Rmul (momentL2Sq φ) (momentL2Sq ψ)) :=
    crossMomSum_sq_le φ ψ (crossScale φ ψ * (k + 1))
  refine Rle_trans (Rsub_le_mono (Rle_refl _) hXsq) ?_
  -- difference of squares: the gap is a product of a small and a bounded factor
  refine Rle_trans (Rle_of_Req (Req_symm
    (Rmul_sub_add_self (crossMomL2 φ ψ) (crossIdx φ ψ k)))) ?_
  refine Rle_trans (Rle_Rabs_self _) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
  have hsmall : Rle (Rabs (Rsub (crossMomL2 φ ψ) (crossIdx φ ψ k)))
      (ofQ (⟨2, k + 1⟩ : Q) (Nat.succ_pos k)) :=
    Rle_trans (Rle_of_Req (abs_Rsub_swap _ _)) (crossMomL2_approx φ ψ k)
  refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs _) hsmall) ?_
  refine Rle_trans (Rmul_le_Rmul_left
    (Rnonneg_ofQ (Nat.succ_pos k) (by show (0 : Int) ≤ 2; decide))
    (crossMomL2_add_idx_abs_le φ ψ k)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (Nat.succ_pos k) (crossTwo_den φ ψ))) ?_
  exact Rle_ofQ_ofQ _ (Nat.succ_pos k) (crossGap_le φ ψ k)

end Multiplicity.UOR.Bridge.F1Square.Square
