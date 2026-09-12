/-
F1 square — **the reciprocal / clamped-reciprocal LOWER bound** (`ClampedInvLower.lean`): the mirror of
`Rinv_le_ofQ_inv` (the floor cap `u ≥ a ⟹ 1/u ≤ 1/a`). Here the CEILING lift:

    `u ≤ B  ⟹  1/B ≤ 1/u`     (`ofQ_inv_le_Rinv`),
    `x ≤ B, a ≤ B  ⟹  1/B ≤ clampedInv a x = 1/max(x,a)`   (`ofQ_inv_le_clampedInv`).

The repo carried only reciprocal UPPER bounds (`Rinv_le_ofQ_inv`, `recipTest.hbd`); the LOWER bound is what
a decay estimate on the multiplicative convolution needs — bounding `f(x·(1/max(t,a)))` requires
`1/max(t,a) ≥ 1/K` on the bounded `t`-window (`K = max(lo+w,a)`), i.e. a lower bound on `clampedInv`.

`ofQ_inv_le_Rinv` is the exact algebraic mirror of `Rinv_le_ofQ_inv`: `1/B ≈ (1/u · u)·(1/B) ≈ (1/u)·(u·(1/B))
≤ (1/u)·(B·(1/B)) ≈ 1/u` (using `u ≤ B` and `1/B ≥ 0`). `ofQ_inv_le_clampedInv` composes it with the clamp
ceiling `max(x,a) ≤ B` (`Rle_qClampQ_ofQ`, from `Qmax_le`).

HONEST SCOPE. A reusable order primitive on the clamped reciprocal. It builds NO convolution decay, NO
half-line assembly, NO factorization `M[f⋆g]=M[f]·M[g]`, NO positivity, NO crux. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.ClampedInv

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The reciprocal's ceiling lift**: `u ≤ B > 0 ⟹ 1/B ≤ 1/u`. The mirror of `Rinv_le_ofQ_inv`, route
    `1/B ≈ ((1/u)·u)·(1/B) ≈ (1/u)·(u·(1/B)) ≤ (1/u)·(B·(1/B)) ≈ 1/u`. -/
theorem ofQ_inv_le_Rinv {B : Q} (hBd : 0 < B.den) (hBn : 0 < B.num) {u : Real} {k : Nat}
    (hk : Qlt (Qbound k) (u.seq k)) (hu : Rle u (ofQ B hBd)) :
    Rle (ofQ (Qinv B) (Qinv_den_pos hBn)) (Rinv u k hk) := by
  have hX0 : Rnonneg (ofQ (Qinv B) (Qinv_den_pos hBn)) :=
    Rnonneg_ofQ (Qinv_den_pos hBn) (Int.le_of_lt (Qinv_num_pos hBd))
  have hstep : Req (ofQ (Qinv B) (Qinv_den_pos hBn))
      (Rmul (Rinv u k hk) (Rmul u (ofQ (Qinv B) (Qinv_den_pos hBn)))) := by
    refine Req_symm ?_
    refine Req_trans (Req_symm (Rmul_assoc (Rinv u k hk) u (ofQ (Qinv B) (Qinv_den_pos hBn)))) ?_
    refine Req_trans (Rmul_congr
      (Req_trans (Rmul_comm (Rinv u k hk) u) (Rmul_Rinv_self hk)) (Req_refl _)) ?_
    exact Rone_mul _
  refine Rle_trans (Rle_of_Req hstep) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_Rinv u k hk)
    (Rmul_le_Rmul_right hX0 hu)) ?_
  refine Rle_of_Req ?_
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (Rmul_ofQ_ofQ hBd (Qinv_den_pos hBn))
      (ofQ_congr (Qmul_den_pos hBd (Qinv_den_pos hBn)) (by decide) (Qmul_Qinv hBn)))) ?_
  exact Rmul_one (Rinv u k hk)

/-- **The clamp ceiling**: `x ≤ B` and `a ≤ B ⟹ max(x,a) ≤ B` — `Qmax_le` index by index. -/
theorem Rle_qClampQ_ofQ {a B : Q} (had : 0 < a.den) (hBd : 0 < B.den) {x : Real}
    (hxB : Rle x (ofQ B hBd)) (haB : Qle a B) :
    Rle (qClampQ a had x) (ofQ B hBd) := by
  intro n
  show Qle (Qmax (x.seq n) a) (add B (⟨2, n + 1⟩ : Q))
  exact Qmax_le (hxB n) (Qle_trans hBd haB (Qle_self_add (by show (0 : Int) ≤ 2; decide)))

/-- **The clamped reciprocal's lower bound**: `x ≤ B, a ≤ B (B > 0) ⟹ 1/B ≤ clampedInv a x = 1/max(x,a)`.
    Composes `ofQ_inv_le_Rinv` (the reciprocal ceiling lift) with `Rle_qClampQ_ofQ` (the clamp ceiling). -/
theorem ofQ_inv_le_clampedInv {a B : Q} (han : 0 < a.num) (had : 0 < a.den) (hBd : 0 < B.den)
    (hBn : 0 < B.num) {x : Real} (hxB : Rle x (ofQ B hBd)) (haB : Qle a B) :
    Rle (ofQ (Qinv B) (Qinv_den_pos hBn)) (clampedInv a han had x) :=
  ofQ_inv_le_Rinv hBd hBn (qClampQ_witness a han had x) (Rle_qClampQ_ofQ had hBd hxB haB)

end Multiplicity.UOR.Bridge.F1Square.Analysis
