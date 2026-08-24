/-
F1 square — **two small schedule-plumbing lemmas for the `∫_t` reconstruction's common evaluation
schedule** (`TwoSidedWeaken.lean`):

- `two_sided_weaken`: a two-sided bound `−B ≤ x ≤ B` weakens to any larger bound `−B' ≤ x ≤ B'`
  (`Qle B B'`) — the tool that lifts `convTwTerm_two_sided` (at the convolution constant `K_conv`) to
  the common constant `K⋆`, so `genSum_RReg` produces the regularity at `K⋆`'s schedule.
- `Qle_self_toNat_add`: a nonnegative rational is `≤` the integer `⟨K.num.toNat + c, 1⟩` (`c ≥ 0`) —
  the `Qle K_conv K⋆` step feeding the weakening (`K⋆ = ⟨K_conv.num.toNat + (Cf·2ⁿ).num.toNat, 1⟩`).

HONEST SCOPE. Two general order lemmas (a Real two-sided weakening and a `Q` bound). No convolution,
no tail assembly, no covariance, no factorization, no positivity, no crux. Step 4 (band-coupling
positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.RealPow
import Multiplicity.F1.Analysis.Pi

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **A two-sided bound weakens to any larger bound.** `−B ≤ x ≤ B` and `B ≤ B'` give `−B' ≤ x ≤ B'`
    (`ofQ` monotone both above and, negated, below). -/
theorem two_sided_weaken {x : Real} {B B' : Q} (hBd : 0 < B.den) (hB'd : 0 < B'.den)
    (hBB' : Qle B B') (h : Rle (Rneg (ofQ B hBd)) x ∧ Rle x (ofQ B hBd)) :
    Rle (Rneg (ofQ B' hB'd)) x ∧ Rle x (ofQ B' hB'd) :=
  ⟨Rle_trans (Rle_Rneg (Rle_ofQ_ofQ hBd hB'd hBB')) h.1,
   Rle_trans h.2 (Rle_ofQ_ofQ hBd hB'd hBB')⟩

/-- **A nonnegative rational is `≤` the integer `⟨K.num.toNat + c, 1⟩`** (`c ≥ 0`). Since `K.num ≥ 0`,
    `K.num ≤ K.num.toNat ≤ (K.num.toNat + c)·K.den`, which is exactly `Qle K ⟨K.num.toNat + c, 1⟩`. -/
theorem Qle_self_toNat_add {K : Q} (hKd : 0 < K.den) (hK0 : 0 ≤ K.num) (c : Int) (hc : 0 ≤ c) :
    Qle K (⟨(K.num.toNat : Int) + c, 1⟩ : Q) := by
  show K.num * (1 : Int) ≤ ((K.num.toNat : Int) + c) * (K.den : Int)
  have hden : (1 : Int) ≤ (K.den : Int) := by have := hKd; omega
  have htn : K.num ≤ (K.num.toNat : Int) := by omega
  have h1 : (K.num.toNat : Int) * 1 ≤ (K.num.toNat : Int) * (K.den : Int) :=
    Int.mul_le_mul_of_nonneg_left hden (Int.ofNat_nonneg _)
  have h2 : (K.num.toNat : Int) * (K.den : Int) ≤ ((K.num.toNat : Int) + c) * (K.den : Int) :=
    Int.mul_le_mul_of_nonneg_right (by omega) (by omega)
  omega

/-- **The `∫_t` reconstruction's per-index rate collapses to `⟨C, j+1⟩`.** The dist bound
    `w·(g.M·(1/a)·3/(j+1))` is `≤ C/(j+1)` for the fixed Nat `C = (w.num·(g.M.num·(1/a).num)·3).toNat`
    (denominators `≥ 1` only inflate the RHS). The `C` that `Rlim_eval_real_rate` consumes. -/
theorem rate_bound_Qle {w gM Qa : Q} (hw0 : 0 ≤ w.num) (hgM0 : 0 ≤ gM.num) (hQa0 : 0 ≤ Qa.num)
    (hwd : 0 < w.den) (hgMd : 0 < gM.den) (hQad : 0 < Qa.den) (j : Nat) :
    Qle (mul w (mul (mul gM Qa) (⟨3, j + 1⟩ : Q)))
        (⟨((w.num * (gM.num * Qa.num) * 3).toNat : Int), j + 1⟩ : Q) := by
  have hA : (0 : Int) ≤ w.num * (gM.num * Qa.num) * 3 :=
    Int.mul_nonneg (Int.mul_nonneg hw0 (Int.mul_nonneg hgM0 hQa0)) (by decide)
  have hAeq : ((w.num * (gM.num * Qa.num) * 3).toNat : Int) = w.num * (gM.num * Qa.num) * 3 :=
    Int.toNat_of_nonneg hA
  have hdenpos : (1 : Int) ≤ (w.den : Int) * ((gM.den : Int) * (Qa.den : Int)) := by
    have h1 : (1 : Int) ≤ (w.den : Int) := by have := hwd; omega
    have h2 : (1 : Int) ≤ (gM.den : Int) := by have := hgMd; omega
    have h3 : (1 : Int) ≤ (Qa.den : Int) := by have := hQad; omega
    calc (1 : Int) = 1 * (1 * 1) := by ring_uor
      _ ≤ (w.den : Int) * ((gM.den : Int) * (Qa.den : Int)) :=
          Int.mul_le_mul h1 (Int.mul_le_mul h2 h3 (by omega) (by omega)) (by omega) (by omega)
  show (mul w (mul (mul gM Qa) (⟨3, j + 1⟩ : Q))).num * ((j + 1 : Nat) : Int)
      ≤ ((w.num * (gM.num * Qa.num) * 3).toNat : Int)
        * ((mul w (mul (mul gM Qa) (⟨3, j + 1⟩ : Q))).den : Int)
  simp only [mul]
  push_cast
  rw [hAeq]
  -- goal (up to ring): A·(j+1) ≤ A·(Dp·(j+1)),  A = w.num·(gM.num·Qa.num)·3 ≥ 0,  Dp = w.den·(gM.den·Qa.den) ≥ 1
  have hle : ((j : Int) + 1) ≤ ((w.den : Int) * ((gM.den : Int) * (Qa.den : Int))) * ((j : Int) + 1) := by
    calc ((j : Int) + 1) = 1 * ((j : Int) + 1) := by ring_uor
      _ ≤ ((w.den : Int) * ((gM.den : Int) * (Qa.den : Int))) * ((j : Int) + 1) :=
          Int.mul_le_mul_of_nonneg_right hdenpos (by omega)
  have hmul := Int.mul_le_mul_of_nonneg_left hle hA
  calc w.num * (gM.num * Qa.num * 3) * ((j : Int) + 1)
      = (w.num * (gM.num * Qa.num) * 3) * ((j : Int) + 1) := by ring_uor
    _ ≤ (w.num * (gM.num * Qa.num) * 3)
          * (((w.den : Int) * ((gM.den : Int) * (Qa.den : Int))) * ((j : Int) + 1)) := hmul
    _ = w.num * (gM.num * Qa.num) * 3
          * ((w.den : Int) * ((gM.den : Int) * (Qa.den : Int) * ((j : Int) + 1))) := by ring_uor

end Multiplicity.UOR.Bridge.F1Square.Square
