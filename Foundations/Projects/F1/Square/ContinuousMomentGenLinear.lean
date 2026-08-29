/-
F1 square — **the pre-Hilbert layer, brick 118** (`ContinuousMomentGenLinear.lean`): **the continuous
Mellin transform is ADDITIVE** — `compactMomentGenLim (φ + ψ) s ≈ compactMomentGenLim φ s +
compactMomentGenLim ψ s` (`compactMomentGenLim_add`), the first structural law of the transform pair.

WHY (the Sonine route, step 3, the transform PAIR). The continuous transform (brick 112) is now known
to be the schedule-independent `a → 0` limit at every floor (brick 117), so it can be treated as a map
and its algebra proven. At each floor the compact moment is additive by `innerI_add_left`
(`compactMoment (φ+ψ) = compactMoment φ + compactMoment ψ`); passing to the limit — controlled by the
brick-117 rate on all three of `φ+ψ`, `φ`, `ψ` — gives additivity of the transform. The passage uses a
reusable Archimedean collapse `Req_of_geom_rate`: two reals within `E·(1/2^m)` for every `m` are equal
(the constant `E` absorbed by the `n < 2^n` reindex, as in bricks 109/112).

HONEST SCOPE. Additivity of the continuous transform in the test slot. NOT the full pairing/inversion.
Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.ContinuousMomentGenRate

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The reindex inequality `E·(1/2^{r(k)}) ≤ 1/(k+1)` for `r(k) = (⌈E⌉+1)(k+1)` (generic constant `E`). -/
private theorem geom_reindex_Qle (E : Q) (hEn : 0 ≤ E.num) (hEd : 0 < E.den) (k : Nat) :
    Qle (mul E (⟨1, 2 ^ ((E.num.toNat + 1) * (k + 1))⟩ : Q)) (⟨1, k + 1⟩ : Q) := by
  have hnat : E.num.toNat * (k + 1) ≤ E.den * 2 ^ ((E.num.toNat + 1) * (k + 1)) := by
    have h1 : E.num.toNat * (k + 1) ≤ (E.num.toNat + 1) * (k + 1) :=
      Nat.mul_le_mul (Nat.le_succ _) (Nat.le_refl _)
    have h2 : (E.num.toNat + 1) * (k + 1) < 2 ^ ((E.num.toNat + 1) * (k + 1)) := Nat.lt_two_pow_self
    have h3 : 2 ^ ((E.num.toNat + 1) * (k + 1)) ≤ E.den * 2 ^ ((E.num.toNat + 1) * (k + 1)) :=
      Nat.le_mul_of_pos_left _ hEd
    exact Nat.le_trans (Nat.le_trans h1 (Nat.le_of_lt h2)) h3
  have hc : (E.num.toNat : Int) = E.num := Int.toNat_of_nonneg hEn
  have key : E.num * ((k + 1 : Nat) : Int)
      ≤ ((E.den * 2 ^ ((E.num.toNat + 1) * (k + 1)) : Nat) : Int) := by
    calc E.num * ((k + 1 : Nat) : Int)
          = (E.num.toNat : Int) * ((k + 1 : Nat) : Int) := by rw [hc]
      _ = ((E.num.toNat * (k + 1) : Nat) : Int) := by push_cast; ring_uor
      _ ≤ ((E.den * 2 ^ ((E.num.toNat + 1) * (k + 1)) : Nat) : Int) := Int.ofNat_le.mpr hnat
  show E.num * 1 * ((k + 1 : Nat) : Int)
      ≤ (1 : Int) * ((E.den * 2 ^ ((E.num.toNat + 1) * (k + 1)) : Nat) : Int)
  rw [Int.mul_one, Int.one_mul]; exact key

/-- `|a − b| = |b − a|` (local copy). -/
private theorem abs_sub_swap' (a b : Real) : Req (Rabs (Rsub a b)) (Rabs (Rsub b a)) :=
  Req_trans (Req_symm (Rabs_Rneg (Rsub a b))) (Rabs_congr (Rneg_Rsub_flip a b))

/-- Distance triangle through a midpoint (local copy). -/
private theorem abs_sub_tri'' (a b c : Real) :
    Rle (Rabs (Rsub a c)) (Radd (Rabs (Rsub a b)) (Rabs (Rsub b c))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Radd_Rsub_Rsub b c a)))) ?_
  refine Rle_trans (Rabs_Radd (Rsub b c) (Rsub a b)) ?_
  exact Rle_of_Req (Radd_comm (Rabs (Rsub b c)) (Rabs (Rsub a b)))

/-- **A geometric rate forces equality**: if `|a − b| ≤ E·(1/2^m)` for every `m`, then `a ≈ b`. The
    constant `E` is absorbed by the `n < 2^n` reindex, then the Archimedean collapse closes both
    directions. Reusable for the transform's algebra. -/
theorem Req_of_geom_rate {a b : Real} (E : Q) (hEn : 0 ≤ E.num) (hEd : 0 < E.den)
    (h : ∀ m, Rle (Rabs (Rsub a b))
      (ofQ (mul E (⟨1, 2 ^ m⟩ : Q)) (Qmul_den_pos hEd (two_pow_pos m)))) : Req a b := by
  refine Rle_antisymm ?_ ?_
  · refine Rle_of_Rsub_le_eps (C := 1) (fun k => ?_)
    refine Rle_trans (Rle_Rabs_self _) (Rle_trans (h ((E.num.toNat + 1) * (k + 1))) ?_)
    exact Rle_ofQ_ofQ _ (Nat.succ_pos k) (geom_reindex_Qle E hEn hEd k)
  · refine Rle_of_Rsub_le_eps (C := 1) (fun k => ?_)
    refine Rle_trans (Rle_Rabs_self _) (Rle_trans (Rle_of_Req (abs_sub_swap' b a)) ?_)
    refine Rle_trans (h ((E.num.toNat + 1) * (k + 1))) ?_
    exact Rle_ofQ_ofQ _ (Nat.succ_pos k) (geom_reindex_Qle E hEn hEd k)

set_option maxHeartbeats 1600000 in
/-- **★ THE CONTINUOUS TRANSFORM IS ADDITIVE**: `compactMomentGenLim (φ + ψ) s ≈ compactMomentGenLim φ s
    + compactMomentGenLim ψ s`. At each floor the compact moment is additive (`innerI_add_left`); the
    brick-117 rate on `φ+ψ`, `φ`, `ψ` controls the limit, and `Req_of_geom_rate` closes it. -/
theorem compactMomentGenLim_add (φ ψ : L2Test) {s : Real} (hs : Rnonneg s) (σ : Q) (hσd : 0 < σ.den)
    (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) :
    Req (compactMomentGenLim (L2Test.add φ ψ) hs σ hσd hσn hsB)
        (Radd (compactMomentGenLim φ hs σ hσd hσn hsB) (compactMomentGenLim ψ hs σ hσd hσn hsB)) := by
  refine Req_of_geom_rate
    (add (mul (add φ.M ψ.M) (⟨2, 1⟩ : Q)) (add (mul φ.M (⟨2, 1⟩ : Q)) (mul ψ.M (⟨2, 1⟩ : Q))))
    (Qadd_num_nonneg_loc (Qmul_num_nonneg (Qadd_num_nonneg_loc φ.hMn ψ.hMn) (by decide))
      (Qadd_num_nonneg_loc (Qmul_num_nonneg φ.hMn (by decide)) (Qmul_num_nonneg ψ.hMn (by decide))))
    (add_den_pos (Qmul_den_pos (add_den_pos φ.hMd ψ.hMd) (by decide))
      (add_den_pos (Qmul_den_pos φ.hMd (by decide)) (Qmul_den_pos ψ.hMd (by decide))))
    (fun m => ?_)
  -- the three floor moments and the transform limits
  have hFa : Req (compactMomentF (L2Test.add φ ψ) m hs σ hσd hσn hsB)
      (Radd (compactMomentF φ m hs σ hσd hσn hsB) (compactMomentF ψ m hs σ hσd hσn hsB)) :=
    innerI_add_left φ ψ (compactPowTestF m hs σ hσd hσn hsB)
  have hRa := compactMomentF_dist_lim (L2Test.add φ ψ) hs σ hσd hσn hsB m
  have hRφ := compactMomentF_dist_lim φ hs σ hσd hσn hsB m
  have hRψ := compactMomentF_dist_lim ψ hs σ hσd hσn hsB m
  -- triangle: |La − (Lφ+Lψ)| ≤ |La − (Fφ+Fψ)| + |(Fφ+Fψ) − (Lφ+Lψ)|
  refine Rle_trans (abs_sub_tri'' (compactMomentGenLim (L2Test.add φ ψ) hs σ hσd hσn hsB)
    (Radd (compactMomentF φ m hs σ hσd hσn hsB) (compactMomentF ψ m hs σ hσd hσn hsB))
    (Radd (compactMomentGenLim φ hs σ hσd hσn hsB) (compactMomentGenLim ψ hs σ hσd hσn hsB))) ?_
  -- first term ≤ C_add/2^m (through `Fa = Fφ+Fψ` and brick 117 with abs symmetry)
  have hfst : Rle (Rabs (Rsub (compactMomentGenLim (L2Test.add φ ψ) hs σ hσd hσn hsB)
      (Radd (compactMomentF φ m hs σ hσd hσn hsB) (compactMomentF ψ m hs σ hσd hσn hsB))))
      (ofQ (mul (mul (add φ.M ψ.M) (⟨2, 1⟩ : Q)) (⟨1, 2 ^ m⟩ : Q))
        (Qmul_den_pos (Qmul_den_pos (add_den_pos φ.hMd ψ.hMd) (by decide)) (two_pow_pos m))) := by
    refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_refl _) (Req_symm hFa)))) ?_
    exact Rle_trans (Rle_of_Req (abs_sub_swap' _ _)) hRa
  -- second term ≤ (C_φ + C_ψ)/2^m
  have hsnd : Rle (Rabs (Rsub (Radd (compactMomentF φ m hs σ hσd hσn hsB)
        (compactMomentF ψ m hs σ hσd hσn hsB))
      (Radd (compactMomentGenLim φ hs σ hσd hσn hsB) (compactMomentGenLim ψ hs σ hσd hσn hsB))))
      (Radd (ofQ (mul (mul φ.M (⟨2, 1⟩ : Q)) (⟨1, 2 ^ m⟩ : Q))
              (Qmul_den_pos (Qmul_den_pos φ.hMd (by decide)) (two_pow_pos m)))
            (ofQ (mul (mul ψ.M (⟨2, 1⟩ : Q)) (⟨1, 2 ^ m⟩ : Q))
              (Qmul_den_pos (Qmul_den_pos ψ.hMd (by decide)) (two_pow_pos m)))) := by
    refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_Radd_Radd _ _ _ _))) ?_
    exact Rle_trans (Rabs_Radd _ _) (Radd_le_add hRφ hRψ)
  refine Rle_trans (Radd_le_add hfst hsnd) ?_
  -- combine the three ofQ bounds into `ofQ (E · 1/2^m)`
  refine Rle_of_Req (Req_trans (Radd_congr (Req_refl _) (Radd_ofQ_ofQ _ _)) ?_)
  refine Req_trans (Radd_ofQ_ofQ _ _) (ofQ_congr _ _ ?_)
  simp only [Qeq, add, mul]; push_cast; ring_uor

end Multiplicity.UOR.Bridge.F1Square.Square
