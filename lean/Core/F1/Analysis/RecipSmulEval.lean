/-
F1 square — **the real-scalar reciprocal evaluation** (`RecipSmulEval.lean`).
The `t4` poleB pieces are combinations `C·(1/(c+t)) ± (1/2)·gLx` with a REAL constant
`C` (the cone height `2·log 2`, the half-height `log 2`). The rational-scalar integral
API (`riemannIntegral_smul`) does not cover a real `C`; this file supplies the one
real-scalar evaluation the pieces need, exploiting that the reciprocal family's
Riemann sums are EXACT rationals (`riemannSum_gRecipC = hFold`):

    `∫₀¹ C·(1/(c+t)) dt ≈ C·(log(c+1) − log c)`      (`|C| ≤ B`, `B.num ≤ 5`)

— the dyadic sums scale exactly (`riemannSum_smul`, real scalar), the defect is
`|C|·|hFold − Δlog| ≤ B/(c(c+1)2^m)` (`hFoldC_defect`), and the `5(j+1) ≤ midx`
schedule absorbs it through `lxr_sched`.

HONEST SCOPE. One integral evaluation, generic in the bounded real constant; no slot
field, no positivity. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LogOverXEval

namespace UOR.Bridge.F1Square.Analysis

/-- `hFold` transport along a count equality (private copy of the `HarmonicLogC`
    pattern). -/
private theorem rse_hFold_eq (c : Nat) (hc : 1 ≤ c) {M M' : Nat} (h : M = M')
    (hM : 1 ≤ c * M) (hM' : 1 ≤ c * M') :
    Req (ofQ (hFold (c * M) M) (hFold_den_pos (c * M) hM M))
      (ofQ (hFold (c * M') M') (hFold_den_pos (c * M') hM' M')) := by
  subst h; exact Req_refl _

/-- `D_m(C·gRecipC) ≈ C·hFold(c·2^m, 2^m)`. -/
private theorem rse_dyadicR (c : Nat) (hc : 1 ≤ c) (C : Real) (m : Nat) :
    Req (dyadicR (fun t => Rmul C (gRecipC c t)) m)
      (Rmul C (ofQ (hFold (c * 2 ^ m) (2 ^ m))
        (hFold_den_pos (c * 2 ^ m) (Nat.mul_pos hc (Nat.pos_pow_of_pos m (by omega)))
          (2 ^ m)))) := by
  have hE : 2 ^ m - 1 + 1 = 2 ^ m := by
    have : (1 : Nat) ≤ 2 ^ m := Nat.one_le_two_pow; omega
  refine Req_trans (riemannSum_smul C (gRecipC c) (2 ^ m - 1)) ?_
  refine Rmul_congr (Req_refl C) ?_
  exact Req_trans (riemannSum_gRecipC c (2 ^ m - 1) hc)
    (rse_hFold_eq c hc hE (Nat.mul_pos hc (Nat.succ_pos (2 ^ m - 1)))
      (Nat.mul_pos hc (Nat.pos_pow_of_pos m (by omega))))

/-- **The real-scalar reciprocal evaluation**: `∫₀¹ C·(1/(c+t)) dt ≈ C·(log(c+1) −
    log c)` for `|C| ≤ B` with `B.num ≤ 5`, at any schedule dominating `5(j+1)`. -/
theorem riemannIntegral_recipC_smul (c : Nat) (hc : 1 ≤ c) (C : Real) {B : Q}
    (hBd : 0 < B.den) (hB5 : B.num.toNat ≤ 5) (hCb : Rle (Rabs C) (ofQ B hBd))
    {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (Rmul C (gRecipC c x)) (Rmul C (gRecipC c y))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y : Real, Req x y → Req (Rmul C (gRecipC c x)) (Rmul C (gRecipC c y)))
    (hsch : ∀ j, 5 * (j + 1) ≤ digammaMidx L j) :
    Req (riemannIntegral (f := fun t => Rmul C (gRecipC c t)) hLd hLn hlip hfc)
      (Rmul C (Rsub (logN (c + 1) (by omega)) (logN c hc))) := by
  -- the anchor `D₀ ≈ C·(1/c)`
  have hzero : Req (dyadicR (fun t => Rmul C (gRecipC c t)) 0)
      (Rmul C (ofQ (⟨1, c⟩ : Q) hc)) :=
    Req_trans (riemannSum_smul C (gRecipC c) (2 ^ 0 - 1))
      (Rmul_congr (Req_refl C) (dyadicR_gRecipC_zero c hc))
  -- the defect at depth `m`
  have hdef : ∀ m j : Nat, 5 * (j + 1) ≤ m →
      Rle (Rabs (Rsub (dyadicR (fun t => Rmul C (gRecipC c t)) m)
          (Rmul C (Rsub (logN (c + 1) (by omega)) (logN c hc)))))
        (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
    intro m j hjm
    have hp : 0 < 2 ^ m := Nat.pos_pow_of_pos m (by omega)
    have hp1 : (1 : Nat) ≤ 2 ^ m := hp
    refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans
      (Rsub_congr (rse_dyadicR c hc C m) (Req_refl _))
      (Req_symm (Rmul_sub_distrib C _ _))))) ?_
    refine Rle_trans (Rle_of_Req (Rabs_Rmul C _)) ?_
    refine Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs _) (Rnonneg_ofQ
      (show 0 < (⟨1, c * (c + 1) * 2 ^ m⟩ : Q).den from
        Nat.mul_pos (Nat.mul_pos hc (by omega)) hp)
      (show (0 : Int) ≤ (⟨1, c * (c + 1) * 2 ^ m⟩ : Q).num from
        (by decide : (0 : Int) ≤ 1)))
      hCb (hFoldC_defect c (2 ^ m) hc hp1)) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ hBd
      (Nat.mul_pos (Nat.mul_pos hc (by omega)) hp))) ?_
    refine Rle_ofQ_ofQ (Qmul_den_pos hBd
      (Nat.mul_pos (Nat.mul_pos hc (by omega)) hp)) (Nat.succ_pos j) ?_
    -- `B.num·(j+1) ≤ B.den·c(c+1)·2^m` from `B.num ≤ 5 ≤ 5m+5` and `(5m+5)(j+1) ≤ 2^m`
    show (B.num * 1) * ((j + 1 : Nat) : Int)
      ≤ 1 * ((B.den * (c * (c + 1) * 2 ^ m) : Nat) : Int)
    have hsched : (5 * m + 5) * (j + 1) ≤ 2 ^ m := lxr_sched m j hjm
    have hnum : B.num.toNat * (j + 1) ≤ 2 ^ m := by
      have h1 : B.num.toNat * (j + 1) ≤ 5 * (j + 1) :=
        Nat.mul_le_mul_right (j + 1) hB5
      have h2 : 5 * (j + 1) ≤ (5 * m + 5) * (j + 1) :=
        Nat.mul_le_mul_right (j + 1) (by omega)
      omega
    have hden : 2 ^ m ≤ B.den * (c * (c + 1) * 2 ^ m) := by
      have h3 : 2 ^ m ≤ c * (c + 1) * 2 ^ m :=
        Nat.le_mul_of_pos_left (2 ^ m) (Nat.mul_pos hc (by omega))
      have h4 : c * (c + 1) * 2 ^ m ≤ B.den * (c * (c + 1) * 2 ^ m) :=
        Nat.le_mul_of_pos_left _ hBd
      omega
    have hcast : (B.num.toNat * (j + 1) : Nat) ≤ (B.den * (c * (c + 1) * 2 ^ m) : Nat) := by
      omega
    have hInt : ((B.num.toNat * (j + 1) : Nat) : Int)
        ≤ ((B.den * (c * (c + 1) * 2 ^ m) : Nat) : Int) := Int.ofNat_le.mpr hcast
    have htn : (B.num.toNat : Int) = B.num ∨ B.num ≤ 0 := by omega
    rcases htn with h | h
    · simp only [Int.mul_one, Int.one_mul]
      rw [← h]
      exact_mod_cast hcast
    · simp only [Int.mul_one, Int.one_mul]
      have hj0 : (0 : Int) ≤ ((j + 1 : Nat) : Int) := Int.ofNat_nonneg _
      have hd0 : (0 : Int) ≤ ((B.den * (c * (c + 1) * 2 ^ m) : Nat) : Int) :=
        Int.ofNat_nonneg _
      have hle : B.num * ((j + 1 : Nat) : Int) ≤ 0 := by
        have hmn := Int.mul_nonneg (show (0 : Int) ≤ -B.num by omega) hj0
        rw [Int.neg_mul] at hmn
        omega
      omega
  -- the rate at the schedule, and the limit
  show Req (Radd (dyadicR (fun t => Rmul C (gRecipC c t)) 0) _) _
  have hlim : Req (Rlim (fun j => genSum (dyadicTerm (fun t => Rmul C (gRecipC c t)))
      (digammaMidx L j)) (dyadicSum_RReg hLd hLn hlip hfc))
      (Rsub (Rmul C (Rsub (logN (c + 1) (by omega)) (logN c hc)))
        (Rmul C (ofQ (⟨1, c⟩ : Q) hc))) := by
    refine Rlim_eval_real _ _ (fun j => ?_)
    refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans
      (Rsub_congr (Req_trans (genSum_telescope _ (digammaMidx L j))
        (Rsub_congr (Req_refl _) hzero)) (Req_refl _))
      (Rsub_shift_drop _ (Rmul C (Rsub (logN (c + 1) (by omega)) (logN c hc)))
        (Rmul C (ofQ (⟨1, c⟩ : Q) hc)))))) ?_
    exact hdef (digammaMidx L j) j (hsch j)
  refine Req_trans (Radd_congr hzero hlim) ?_
  exact Radd_Rsub_cancel (Rmul C (Rsub (logN (c + 1) (by omega)) (logN c hc)))
    (Rmul C (ofQ (⟨1, c⟩ : Q) hc))

end UOR.Bridge.F1Square.Analysis
