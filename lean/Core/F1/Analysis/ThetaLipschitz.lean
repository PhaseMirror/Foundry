/-
F1 square — Track 1, item 3 substrate: the **Jacobi-theta Lipschitz bound** on `[1, ∞)`, the modulus
of continuity the Mellin integrand `t^{σ−1}·ψ(t)` needs to enter the certified-integration framework.

The per-term step `|e^{−aₘs} − e^{−aₘt}| ≤ rₘ·|s−t|` would normally need a case split on `s ≤ t` vs
`t ≤ s` (which constructively is undecidable). The **RmaxZero trick** removes it: the order-free bound

  `1 − e^{−z} ≤ 4·max(z, 0)`  for ALL real `z`

(here, via `1 − e^{−z} ≤ 1 − e^{−max(z,0)} ≤ 4·max(z,0)`, monotone in the exponent + the global
`RexpReal_one_sub_neg_le_global` on the nonneg argument `max(z,0)`) is symmetric enough that the signed
per-term difference factors through `max` with no dichotomy.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ThetaValueDecay
import Core.F1.Analysis.ExpVarGlobal
import Core.F1.Analysis.ClampOne

namespace UOR.Bridge.F1Square.Analysis

/-- `z ≤ max(z, 0)` (the tent dominates its argument). -/
theorem Rle_RmaxZero_self (z : Real) : Rle z (RmaxZero z) := by
  show Rle z (Rhalf (Radd z (Rabs z)))
  exact Rle_trans (Rle_of_Req (Req_symm (Rhalf_add_self z)))
    (Rhalf_le_Rhalf (Radd_le_add (Rle_refl z) (Rle_Rabs_self z)))

/-- `max(z, 0) ≤ |z|` (the tent is dominated by the absolute value). -/
theorem RmaxZero_le_Rabs (z : Real) : Rle (RmaxZero z) (Rabs z) := by
  show Rle (Rhalf (Radd z (Rabs z))) (Rabs z)
  exact Rle_trans (Rhalf_le_Rhalf (Radd_le_add (Rle_Rabs_self z) (Rle_refl (Rabs z))))
    (Rle_of_Req (Rhalf_add_self (Rabs z)))

/-- **Order-free global exp variation** `1 − e^{−z} ≤ 4·max(z, 0)` for EVERY real `z` (no `z ≥ 0`).
    `1 − e^{−z} ≤ 1 − e^{−max(z,0)}` (since `max(z,0) ≥ z` ⟹ `e^{−max(z,0)} ≤ e^{−z}`), and the latter
    is `≤ 4·max(z,0)` by the nonneg-argument bound. The `max` makes the signed per-term theta difference
    boundable without a real case split. -/
theorem RexpReal_one_sub_neg_le_maxZero (z : Real) :
    Rle (Rsub one (RexpReal (Rneg z))) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (RmaxZero z)) := by
  have hexp : Rle (RexpReal (Rneg (RmaxZero z))) (RexpReal (Rneg z)) :=
    RexpReal_le_of_le (Rle_Rneg (Rle_RmaxZero_self z))
  have hsub : Rle (Rsub one (RexpReal (Rneg z))) (Rsub one (RexpReal (Rneg (RmaxZero z)))) :=
    Radd_le_add (Rle_refl one) (Rle_Rneg hexp)
  exact Rle_trans hsub (RexpReal_one_sub_neg_le_global (Rnonneg_RmaxZero z))

/-- The theta-term coefficient `aₘ = (m+1)²·π` (so `thetaArg t m ≈ aₘ·t`). -/
def thetaCoeff (m : Nat) : Real := Rmul (RofNat ((m + 1) * (m + 1))) Rpi

/-- `thetaArg t m ≈ aₘ·t` (associativity of `(m+1)²·π·t`). -/
theorem thetaArg_eq_coeff (t : Real) (m : Nat) :
    Req (thetaArg t m) (Rmul (thetaCoeff m) t) :=
  Req_symm (Rmul_assoc (RofNat ((m + 1) * (m + 1))) Rpi t)

private theorem Rpi_nn : Rnonneg Rpi :=
  Rnonneg_of_Rle_zero (Rle_trans (Rle_zero_of_Rnonneg (Rnonneg_ofQ (by decide) (by decide)))
    Rpi_lower_three)

/-- `aₘ ≥ 0`. -/
theorem thetaCoeff_nonneg (m : Nat) : Rnonneg (thetaCoeff m) :=
  Rnonneg_Rmul (Rnonneg_ofQ Nat.one_pos (Int.ofNat_nonneg _)) Rpi_nn

/-- `aₘ ≥ 3·(m+1)²` (since `π ≥ 3`). -/
theorem thetaCoeff_lower (m : Nat) :
    Rle (ofQ (⟨3 * (((m + 1) * (m + 1) : Nat) : Int), 1⟩ : Q) Nat.one_pos) (thetaCoeff m) := by
  refine Rle_trans (Rle_of_Req ?_)
    (Rmul_le_Rmul_left (Rnonneg_ofQ Nat.one_pos (Int.ofNat_nonneg _)) Rpi_lower_three)
  refine Req_symm (Req_trans (Rmul_ofQ_ofQ Nat.one_pos (by decide)) (ofQ_congr _ Nat.one_pos ?_))
  simp only [Qeq, mul]; push_cast; ring_uor

/-- **The summable per-term coefficient bound** `aₘ·e^{−aₘ} ≤ 4/(3(m+1)²)` (quadratic decay). Via the
    half-split `aₘ·e^{−aₘ} = (aₘ·e^{−aₘ/2})·e^{−aₘ/2} ≤ 2·e^{−aₘ/2}` (peak bound `X·e^{−X} ≤ 1` at
    `X = aₘ/2`) and `e^{−aₘ/2} ≤ 1/(1+3(m+1)²/2) ≤ 2/(3(m+1)²)` (`Rexp_neg_le_ratio`, `aₘ/2 ≥ 3(m+1)²/2`).
    No upper bound on `π` (the peak bound carries the real `aₘ`). -/
theorem thetaCoeff_exp_le (m : Nat) :
    Rle (Rmul (thetaCoeff m) (RexpReal (Rneg (thetaCoeff m))))
      (ofQ (⟨4, 3 * ((m + 1) * (m + 1))⟩ : Q)
        (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos m)))) := by
  have hMpos : 0 < (m + 1) * (m + 1) := Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos m)
  have h3Mpos : 0 < 3 * ((m + 1) * (m + 1)) := Nat.mul_pos (by decide) hMpos
  have hMI : (0 : Int) < (((m + 1) * (m + 1) : Nat) : Int) := by exact_mod_cast hMpos
  let e : Real := RexpReal (Rneg (Rhalf (thetaCoeff m)))
  have he_nn : Rnonneg e := RexpReal_nonneg _
  -- `aₘ/2 ≥ 3(m+1)²/2`
  have hhalf_lower : Rle (ofQ (⟨3 * (((m + 1) * (m + 1) : Nat) : Int), 2⟩ : Q)
        (by show (0 : Nat) < 2; decide))
      (Rhalf (thetaCoeff m)) :=
    Rle_trans (Rle_of_Req (Req_symm (Req_trans (Rhalf_ofQ _ Nat.one_pos)
      (ofQ_congr (Qmul_den_pos (by decide) Nat.one_pos) (by show (0 : Nat) < 2; decide) (by
        simp only [Qeq, mul]; push_cast; ring_uor))))) (Rhalf_le_Rhalf (thetaCoeff_lower m))
  have hhalf_nn : Rnonneg (Rhalf (thetaCoeff m)) := Rhalf_nonneg (thetaCoeff_nonneg m)
  -- `e^{−aₘ/2} ≤ 2/(3(m+1)²)`
  have hexp_half : Rle e (ofQ (⟨2, 3 * ((m + 1) * (m + 1))⟩ : Q) h3Mpos) := by
    refine Rle_trans (Rexp_neg_le_ratio (τ := (⟨3 * (((m + 1) * (m + 1) : Nat) : Int), 2⟩ : Q))
        (by show (0 : Int) < 3 * (((m + 1) * (m + 1) : Nat) : Int); omega)
        (by show (0 : Nat) < 2; decide) hhalf_lower) ?_
    refine Rle_ofQ_ofQ (Qinv_den_pos (by
        show (0 : Int) < (add (⟨1, 1⟩ : Q) (⟨3 * (((m + 1) * (m + 1) : Nat) : Int), 2⟩ : Q)).num
        simp only [add]; omega)) h3Mpos ?_
    simp only [Qle, Qinv, add]; omega
  -- `aₘ ≈ 2·(aₘ/2)`
  have hheq : Req (thetaCoeff m) (Radd (Rhalf (thetaCoeff m)) (Rhalf (thetaCoeff m))) :=
    Req_symm (Req_trans (Req_symm (Rhalf_Radd (thetaCoeff m) (thetaCoeff m)))
      (Rhalf_add_self (thetaCoeff m)))
  -- `aₘ·e^{−aₘ/2} ≤ 2`  (peak: `aₘ·e^{−aₘ/2} = (aₘ/2)·e + (aₘ/2)·e ≤ 1 + 1`)
  have hpeak : Rle (Rmul (Rhalf (thetaCoeff m)) e) one := Rmul_self_exp_neg_le_one hhalf_nn
  have ha_half_le : Rle (Rmul (thetaCoeff m) e) (ofQ (⟨2, 1⟩ : Q) (by decide)) := by
    refine Rle_trans (Rle_of_Req (Rmul_congr hheq (Req_refl e))) ?_
    refine Rle_trans (Rle_of_Req (Rmul_distrib_right (Rhalf (thetaCoeff m)) (Rhalf (thetaCoeff m)) e)) ?_
    refine Rle_trans (Radd_le_add hpeak hpeak) (Rle_of_Req ?_)
    exact Req_trans (Radd_ofQ_ofQ (by decide) (by decide))
      (ofQ_congr (add_den_pos (by decide) (by decide)) (by decide) (by decide))
  -- split `e^{−aₘ} ≈ e·e`
  have hsplit : Req (RexpReal (Rneg (thetaCoeff m))) (Rmul e e) :=
    Req_trans (RexpReal_congr (Req_trans (Rneg_congr hheq)
        (Rneg_Radd (Rhalf (thetaCoeff m)) (Rhalf (thetaCoeff m)))))
      (RexpReal_add (Rneg (Rhalf (thetaCoeff m))) (Rneg (Rhalf (thetaCoeff m))))
  -- assemble: `aₘ·e^{−aₘ} = aₘ·(e·e) = (aₘ·e)·e ≤ 2·e ≤ 2·(2/(3(m+1)²)) = 4/(3(m+1)²)`
  refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl _) hsplit)) ?_
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_assoc (thetaCoeff m) e e))) ?_
  refine Rle_trans (Rmul_le_Rmul_right he_nn ha_half_le) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) hexp_half) ?_
  refine Rle_of_Req (Req_trans (Rmul_ofQ_ofQ (by decide) h3Mpos)
    (ofQ_congr (Qmul_den_pos (by decide) h3Mpos) _ ?_))
  simp only [Qeq, mul]; push_cast; ring_uor

-- ===========================================================================
-- Absolute-value helpers and the per-term theta Lipschitz bound.
-- ===========================================================================

/-- `|x| ≤ x` for `x ≥ 0` (factor the common denominator, then a sign case split). -/
theorem Rabs_le_self_of_nonneg {x : Real} (hx : Rnonneg x) : Rle (Rabs x) x := by
  intro n
  have h := hx n
  show Qle (Qabs (x.seq n)) (add (x.seq n) (⟨2, n + 1⟩ : Q))
  have hd : (0 : Int) < (↑(x.seq n).den : Int) := by exact_mod_cast (x.den_pos n)
  have hh : -(1 : Int) * (↑(x.seq n).den) ≤ (x.seq n).num * ((n : Int) + 1) := by
    have := h; simp only [Qle, neg, Qbound] at this; push_cast at this; omega
  have hkey : (↑(x.seq n).num.natAbs : Int) * ((n : Int) + 1)
      ≤ (x.seq n).num * ((n : Int) + 1) + 2 * (↑(x.seq n).den : Int) := by
    by_cases hp : 0 ≤ (x.seq n).num
    · rw [Int.natAbs_of_nonneg hp]; omega
    · rw [Int.ofNat_natAbs_of_nonpos (Int.le_of_lt (Int.not_le.mp hp)), Int.neg_mul]; omega
  have hmul := Int.mul_le_mul_of_nonneg_left hkey (Int.le_of_lt hd)
  show (↑(x.seq n).num.natAbs : Int) * (↑(x.seq n).den * ((n : Int) + 1))
      ≤ ((x.seq n).num * ((n : Int) + 1) + 2 * ↑(x.seq n).den) * ↑(x.seq n).den
  rw [Int.mul_left_comm (↑(x.seq n).num.natAbs : Int) (↑(x.seq n).den) ((n : Int) + 1),
    Int.mul_comm ((x.seq n).num * ((n : Int) + 1) + 2 * ↑(x.seq n).den) (↑(x.seq n).den)]
  exact hmul

/-- `|x| = x` for `x ≥ 0`. -/
theorem Rabs_of_nonneg {x : Real} (hx : Rnonneg x) : Req (Rabs x) x :=
  Rle_antisymm (Rabs_le_self_of_nonneg hx) (Rle_Rabs_self x)

/-- `|x| ≤ B` from `x ≤ B` and `−x ≤ B` (the two-sided constructor, sign case split). -/
theorem Rabs_le_of_both {x B : Real} (h1 : Rle x B) (h2 : Rle (Rneg x) B) : Rle (Rabs x) B := by
  intro n
  have a1 := h1 n
  have a2 := h2 n
  show Qle (Qabs (x.seq n)) (add (B.seq n) (⟨2, n + 1⟩ : Q))
  simp only [Qle, Qabs, Rneg, neg] at a1 a2 ⊢
  by_cases hp : 0 ≤ (x.seq n).num
  · rw [Int.natAbs_of_nonneg hp]; omega
  · rw [Int.ofNat_natAbs_of_nonpos (Int.le_of_lt (Int.not_le.mp hp))]; omega

/-- `thetaTerm u m ≈ e^{−aₘ·u}` (re-expressing the exponent via `aₘ = thetaCoeff m`). -/
theorem thetaTerm_eq_coeff (u : Real) (m : Nat) :
    Req (thetaTerm u m) (RexpReal (Rneg (Rmul (thetaCoeff m) u))) :=
  RexpReal_congr (Rneg_congr (thetaArg_eq_coeff u m))

/-- `thetaTerm one m ≈ e^{−aₘ}`. -/
theorem thetaTerm_one_eq (m : Nat) :
    Req (thetaTerm one m) (RexpReal (Rneg (thetaCoeff m))) :=
  Req_trans (thetaTerm_eq_coeff one m) (RexpReal_congr (Rneg_congr (Rmul_one (thetaCoeff m))))

/-- **Per-term directed difference** (order-free in `t`; needs only `s ≥ 1`):
    `e^{−aₘs} − e^{−aₘt} ≤ (16/(3(m+1)²))·|s−t|`. The `RmaxZero` factorization avoids a case split
    on `s ≤ t`; the modulus is summable (quadratic) by `thetaCoeff_exp_le`. -/
theorem thetaTerm_diff_le (m : Nat) (s t : Real) (hs : Rle one s) :
    Rle (Rsub (thetaTerm s m) (thetaTerm t m))
      (Rmul (ofQ (⟨16, 3 * ((m + 1) * (m + 1))⟩ : Q)
          (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos m))))
        (Rabs (Rsub s t))) := by
  have h3Mpos : 0 < 3 * ((m + 1) * (m + 1)) := Nat.mul_pos (by decide)
    (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos m))
  -- abbreviations
  let a : Real := thetaCoeff m
  let w : Real := Rabs (Rsub s t)
  have hw_nn : Rnonneg w := Rnonneg_Rabs _
  have ha_nn : Rnonneg a := thetaCoeff_nonneg m
  have hts_nn : Rnonneg (thetaTerm s m) := RexpReal_nonneg _
  -- identity `Tₘ(s) − Tₘ(t) = Tₘ(s)·(1 − e^{−aₘ(t−s)})`
  have hprod : Req (Rmul (thetaTerm s m) (RexpReal (Rneg (Rmul a (Rsub t s))))) (thetaTerm t m) := by
    refine Req_trans (Rmul_congr (thetaTerm_eq_coeff s m) (Req_refl _)) ?_
    refine Req_trans (Req_symm (RexpReal_add (Rneg (Rmul a s)) (Rneg (Rmul a (Rsub t s))))) ?_
    refine Req_trans (RexpReal_congr ?_) (Req_symm (thetaTerm_eq_coeff t m))
    refine Req_trans (Req_symm (Rneg_Radd (Rmul a s) (Rmul a (Rsub t s)))) (Rneg_congr ?_)
    exact Req_trans (Req_symm (Rmul_distrib a s (Rsub t s))) (Rmul_congr (Req_refl a) (Radd_Rsub_self s t))
  have hid : Req (Rsub (thetaTerm s m) (thetaTerm t m))
      (Rmul (thetaTerm s m) (Rsub one (RexpReal (Rneg (Rmul a (Rsub t s)))))) := by
    refine Req_symm (Req_trans (Req_trans (Rmul_distrib (thetaTerm s m) one
        (Rneg (RexpReal (Rneg (Rmul a (Rsub t s))))))
      (Radd_congr (Req_refl _) (Rmul_neg_right (thetaTerm s m) _))) ?_)
    exact Rsub_congr (Rmul_one (thetaTerm s m)) hprod
  -- `Tₘ(s) ≤ e^{−aₘ}`
  have hts_le : Rle (thetaTerm s m) (RexpReal (Rneg a)) :=
    Rle_trans (thetaTerm_antitone hs m) (Rle_of_Req (thetaTerm_one_eq m))
  -- `max(aₘ(t−s),0) ≤ aₘ·|s−t|`
  have hmax : Rle (RmaxZero (Rmul a (Rsub t s))) (Rmul a w) := by
    refine Rle_trans (RmaxZero_le_Rabs _) (Rle_of_Req ?_)
    refine Req_trans (Rabs_Rmul a (Rsub t s)) (Rmul_congr (Rabs_of_nonneg ha_nn) ?_)
    exact Req_trans (Req_symm (Rabs_Rneg (Rsub t s))) (Rabs_congr (Rneg_Rsub t s))
  -- coefficient: `Tₘ(s)·(4·aₘ) ≤ 16/(3(m+1)²)`
  have hcoeff : Rle (Rmul (thetaTerm s m) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) a))
      (ofQ (⟨16, 3 * ((m + 1) * (m + 1))⟩ : Q) h3Mpos) := by
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) ha_nn)
      hts_le) ?_
    refine Rle_trans (Rle_of_Req (Req_trans (Rmul_left_comm_loc (RexpReal (Rneg a))
        (ofQ (⟨4, 1⟩ : Q) (by decide)) a)
      (Rmul_congr (Req_refl _) (Rmul_comm (RexpReal (Rneg a)) a)))) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) (thetaCoeff_exp_le m)) ?_
    refine Rle_of_Req (Req_trans (Rmul_ofQ_ofQ (by decide) h3Mpos)
      (ofQ_congr (Qmul_den_pos (by decide) h3Mpos) h3Mpos ?_))
    simp only [Qeq, mul]; push_cast; ring_uor
  -- assemble
  refine Rle_trans (Rle_of_Req hid) ?_
  refine Rle_trans (Rmul_le_Rmul_left hts_nn (RexpReal_one_sub_neg_le_maxZero (Rmul a (Rsub t s)))) ?_
  refine Rle_trans (Rmul_le_Rmul_left hts_nn (Rmul_le_Rmul_left
    (Rnonneg_ofQ (by decide) (by decide)) hmax)) ?_
  -- `Tₘ(s)·(4·(aₘ·w)) = (Tₘ(s)·(4·aₘ))·w ≤ (16/(3(m+1)²))·w`
  refine Rle_trans (Rle_of_Req ?_) (Rmul_le_Rmul_right hw_nn hcoeff)
  refine Req_trans (Rmul_congr (Req_refl _) (Req_symm (Rmul_assoc (ofQ (⟨4, 1⟩ : Q) (by decide)) a w)))
    (Req_symm (Rmul_assoc (thetaTerm s m) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) a) w))

/-- **The per-term theta Lipschitz bound** `|e^{−aₘs} − e^{−aₘt}| ≤ (16/(3(m+1)²))·|s−t|`
    (for `s, t ≥ 1`), symmetric form via `Rabs_le_of_both` and the directed bound both ways. -/
theorem thetaTerm_lip (m : Nat) (s t : Real) (hs : Rle one s) (ht : Rle one t) :
    Rle (Rabs (Rsub (thetaTerm s m) (thetaTerm t m)))
      (Rmul (ofQ (⟨16, 3 * ((m + 1) * (m + 1))⟩ : Q)
          (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos m))))
        (Rabs (Rsub s t))) := by
  refine Rabs_le_of_both (thetaTerm_diff_le m s t hs) ?_
  -- `−(Tₘ(s)−Tₘ(t)) = Tₘ(t)−Tₘ(s) ≤ rₘ·|t−s| = rₘ·|s−t|`
  refine Rle_trans (Rle_of_Req (Rneg_Rsub (thetaTerm s m) (thetaTerm t m))) ?_
  refine Rle_trans (thetaTerm_diff_le m t s ht) (Rmul_le_Rmul_left
    (Rnonneg_ofQ (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos m)))
      (by show (0 : Int) ≤ 16; decide)) (Rle_of_Req ?_))
  exact Req_trans (Req_symm (Rabs_Rneg (Rsub t s))) (Rabs_congr (Rneg_Rsub t s))

end UOR.Bridge.F1Square.Analysis
