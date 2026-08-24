/-
F1 square — **the pre-Hilbert layer, brick 117** (`ContinuousMomentGenRate.lean`): **the continuous
Mellin transform is the a→0 limit AT EVERY floor, schedule-independently** — the compact moment at any
dyadic floor `1/2^m` is within `2·M_φ·(1/2^m)` of the transform `compactMomentGenLim φ s`:

    `|compactMoment φ (1/2^m) s  −  compactMomentGenLim φ s|  ≤  2·M_φ·(1/2^m)`
      (`compactMomentF_dist_lim`).

WHY (the Sonine route, step 3, the transform PAIR). Brick 112 defined the continuous transform as the
Bishop limit along ONE reindex schedule `r(j) = momRate φ j`. To use the transform as a structured map
(linearity, the pairing of `φ` with its transform) the value must be known to be schedule-independent —
the honest `a → 0` limit at every floor, not just the reindexed ones. This brick supplies exactly that,
with an explicit rate: the compact moment at floor `1/2^m` converges to the transform as `m → ∞`,
uniformly in the reindex. The proof triangulates through the reindexed sequence at depth `j = m + k`
(brick 111's floor-Cauchy bound for the `[m, r(j)]` gap, `Rabs_dist_Rlim` for the `[r(j), lim]` gap),
then the Archimedean collapse `Rle_of_Rsub_le_eps` kills the residual `2/(k+1)`.

HONEST SCOPE. The schedule-independent convergence rate of the compact moment to the continuous
transform, at general real `s`. This is the ingredient the transform's linearity (next brick) consumes;
NOT the transform pair or inversion themselves. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.ContinuousMomentGenLimit

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- Triangle for the distance through a midpoint (local copy of the private `IntegralSplit` version). -/
private theorem abs_sub_tri' (a b c : Real) :
    Rle (Rabs (Rsub a c)) (Radd (Rabs (Rsub a b)) (Rabs (Rsub b c))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Radd_Rsub_Rsub b c a)))) ?_
  refine Rle_trans (Rabs_Radd (Rsub b c) (Rsub a b)) ?_
  exact Rle_of_Req (Radd_comm (Rabs (Rsub b c)) (Rabs (Rsub a b)))

/-- `j ≤ momRate φ j` — the reindex dominates its index. -/
private theorem le_momRate (φ : L2Test) (j : Nat) : j ≤ momRate φ j := by
  unfold momRate
  have h : j + 1 ≤ ((mul φ.M (⟨2, 1⟩ : Q)).num.toNat + 1) * (j + 1) :=
    Nat.le_mul_of_pos_left (j + 1) (by omega)
  omega

set_option maxHeartbeats 1600000 in
/-- **★ THE COMPACT MOMENT CONVERGES TO THE TRANSFORM AT EVERY FLOOR** (schedule-independent):
    `|compactMoment φ (1/2^m) s − compactMomentGenLim φ s| ≤ 2·M_φ·(1/2^m)`. Triangulate through the
    reindexed sequence at depth `j = m + k`: brick 111 bounds the `[m, r(j)]` gap by `2·M_φ/2^m`,
    `Rabs_dist_Rlim` bounds the `[r(j), lim]` gap by `2/(j+1) ≤ 2/(k+1)`; the Archimedean collapse
    removes the residual. -/
theorem compactMomentF_dist_lim (φ : L2Test) {s : Real} (hs : Rnonneg s) (σ : Q) (hσd : 0 < σ.den)
    (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) (m : Nat) :
    Rle (Rabs (Rsub (compactMomentF φ m hs σ hσd hσn hsB)
        (compactMomentGenLim φ hs σ hσd hσn hsB)))
        (ofQ (mul (mul φ.M (⟨2, 1⟩ : Q)) (⟨1, 2 ^ m⟩ : Q))
          (Qmul_den_pos (Qmul_den_pos φ.hMd (by decide)) (two_pow_pos m))) := by
  refine Rle_of_Rsub_le_eps (C := 2) (fun k => ?_)
  refine Rsub_le_of_le_add ?_
  -- goal: Rabs(Rsub (compactMomentF φ m ..)(lim)) ≤ ⟨2,k+1⟩ + B_m
  have hmj : m ≤ momRate φ (m + k) := Nat.le_trans (Nat.le_add_right m k) (le_momRate φ (m + k))
  -- brick 111: `[m, r(m+k)]` gap
  have h1 := compactMoment_floor_diff_bound φ hs σ hσd hσn hsB m (momRate φ (m + k)) hmj
  -- Rabs_dist_Rlim: `[r(m+k), lim]` gap
  have h2 := Rabs_dist_Rlim (compactMomentGenSeq_RReg φ hs σ hσd hσn hsB) (m + k)
  refine Rle_trans (abs_sub_tri' (compactMomentF φ m hs σ hσd hσn hsB)
    (compactMomentF φ (momRate φ (m + k)) hs σ hσd hσn hsB)
    (compactMomentGenLim φ hs σ hσd hσn hsB)) ?_
  refine Rle_trans (Radd_le_add h1 h2) ?_
  -- Radd B_m (ofQ⟨2,(m+k)+1⟩) ≤ Radd (ofQ⟨2,k+1⟩) B_m
  refine Rle_trans (Radd_le_add (Rle_refl _)
    (Rle_ofQ_ofQ (Nat.succ_pos (m + k)) (Nat.succ_pos k) ?_)) (Rle_of_Req (Radd_comm _ _))
  show (2 : Int) * ((k + 1 : Nat) : Int) ≤ (2 : Int) * (((m + k) + 1 : Nat) : Int)
  have : (k : Int) ≤ ((m + k : Nat) : Int) := by exact_mod_cast Nat.le_add_left k m
  push_cast; omega

end Multiplicity.UOR.Bridge.F1Square.Square
