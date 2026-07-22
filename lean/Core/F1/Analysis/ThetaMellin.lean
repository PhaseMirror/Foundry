/-
F1 square — Track 1, item 3: the **theta Mellin integral** `∫₁^∞ ψ(t) dt` as a genuine constructive
real (the `σ = 1` Mellin transform of the Jacobi theta function). This is the first fully assembled
Mellin object — it consumes the entire analytic profile of `ψ` built in the theta stack:

- the **totalized integrand** `thetaClamp t = ψ(max(t,1))` (total `Real → Real`, `= ψ(t)` on `[1,∞)`),
  Lipschitz with constant `32/3` (`clampOne` is `1`-Lipschitz ∘ `ψ` is `32/3`-Lipschitz: `thetaFn_lip`),
  non-negative and `≈`-respecting — exactly the certified-integration interface;
- the **decay** `|∫_{m+1}^{m+2} ψ| ≤ 2/((m+1)m)` (`m ≥ 1`): on `[m+1, m+2]` the clamp is inert and `ψ`
  is antitone, so the integrand is `≤ ψ(m+1) ≤ 2/((m+1)m)` (`thetaFn_value_decay`); bounding the integral
  by that per-interval constant uses the interval-local `riemannIntegralI_le_unit`;
- the convergent sum `Σ_{n≥1} ∫_n^{n+1} ψ` via `improperIntegral1` (`K = 2`).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ThetaLipschitzFn
import Core.F1.Analysis.IntegralLocal

namespace UOR.Bridge.F1Square.Analysis

/-- **The totalized theta integrand** `thetaClamp t = ψ(max(t,1))` — total `Real → Real`, `= ψ(t)` on
    `[1, ∞)`, `32/3`-Lipschitz, non-negative. -/
def thetaClamp (t : Real) : Real := thetaFn (clampOne t) (clampOne_ge_one t)

/-- `thetaClamp` respects `≈`. -/
theorem thetaClamp_congr {x y : Real} (h : Req x y) : Req (thetaClamp x) (thetaClamp y) :=
  thetaFn_congr (clampOne_ge_one x) (clampOne_ge_one y) (clampOne_congr h)

/-- `thetaClamp` is `32/3`-Lipschitz (clamp `1`-Lipschitz, `ψ` `32/3`-Lipschitz). -/
theorem thetaClamp_lip (x y : Real) :
    Rle (Rabs (Rsub (thetaClamp x) (thetaClamp y)))
      (Rmul (ofQ (⟨32, 3⟩ : Q) (by decide)) (Rabs (Rsub x y))) :=
  Rle_trans (thetaFn_lip (clampOne_ge_one x) (clampOne_ge_one y))
    (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) (clampOne_lipschitz x y))

/-- `thetaClamp t ≥ 0`. -/
theorem thetaClamp_nonneg (t : Real) : Rnonneg (thetaClamp t) :=
  thetaFn_nonneg (clampOne t) (clampOne_ge_one t)

/-- The constant integrand is `32/3`-Lipschitz (trivially, `|c − c| = 0`). -/
private theorem const_lip32 (c : Real) (x y : Real) :
    Rle (Rabs (Rsub c c)) (Rmul (ofQ (⟨32, 3⟩ : Q) (by decide)) (Rabs (Rsub x y))) :=
  Rle_trans (Rle_of_Req (Req_trans (Rabs_congr (Radd_neg c)) Rabs_zero))
    (Rle_zero_of_Rnonneg (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) (Rnonneg_Rabs _)))

/-- The interval integral of a constant, general modulus: `∫_a^{a+w} c = w·c`. -/
private theorem riemannIntegralI_const32 (c : Real) (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den)
    (hwn : 0 ≤ w.num) :
    Req (riemannIntegralI (f := fun _ => c) (L := (⟨32, 3⟩ : Q)) (by decide) (by decide)
          (const_lip32 c) (fun _ _ _ => Req_refl c) a w ha hw hwn) (Rmul (ofQ w hw) c) :=
  Rmul_congr (Req_refl _) (riemannIntegral_const_gen c _ _ _ _)

/-- **Per-interval decay** `∫_{m+1}^{m+2} ψ ≤ 2/((m+1)m)` (`m ≥ 1`). On the interval the clamp is inert
    and `ψ` is antitone, so the integrand is `≤ ψ(m+1)`; integrate the constant and apply the value decay. -/
theorem integralTerm_thetaClamp_le (m : Nat) (hm : 1 ≤ m) :
    Rle (integralTerm (by decide : 0 < (⟨32, 3⟩ : Q).den) (by decide) thetaClamp_lip
        (fun _ _ h => thetaClamp_congr h) m)
      (ofQ (mul (⟨2, 1⟩ : Q) (⟨1, (m + 1) * m⟩ : Q))
        (Qmul_den_pos (by decide) (digamma_succ_mul_pos hm))) := by
  -- compare to the constant `ψ(m+1)` on the interval
  have hub : Rle (integralTerm (by decide : 0 < (⟨32, 3⟩ : Q).den) (by decide) thetaClamp_lip
        (fun _ _ h => thetaClamp_congr h) m)
      (riemannIntegralI (f := fun _ => thetaFn (RnatSucc m) (one_le_RnatSucc m))
        (L := (⟨32, 3⟩ : Q)) (by decide) (by decide) (const_lip32 _) (fun _ _ _ => Req_refl _)
        (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)) := by
    refine riemannIntegralI_le_unit (by decide) (by decide) thetaClamp_lip
      (fun _ _ h => thetaClamp_congr h) (const_lip32 _) (fun _ _ _ => Req_refl _)
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide) (fun x hx0 hx1 => ?_)
    -- `ψ(clampOne(affineMap x)) ≤ ψ(m+1)`
    have hxnn : Rnonneg x := Rnonneg_of_Rle_zero hx0
    have hpge : Rle (RnatSucc m) (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos
        (by decide) x) :=
      Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) hxnn)
    have hp1 : Rle one (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x) :=
      Rle_trans (one_le_RnatSucc m) hpge
    refine Rle_trans (Rle_of_Req (thetaFn_congr (clampOne_ge_one _) hp1
        (clampOne_eq_of_ge hp1))) ?_
    exact thetaFn_antitone (one_le_RnatSucc m) hp1 hpge
  refine Rle_trans hub ?_
  refine Rle_trans (Rle_of_Req (riemannIntegralI_const32 _ _ _ _ _ _)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_comm _ _)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_one _)) ?_
  -- `ψ(m+1) ≤ 2/((m+1)m) = mul ⟨2,1⟩ ⟨1,(m+1)m⟩`
  refine Rle_trans (thetaFn_value_decay m hm (one_le_RnatSucc m)) ?_
  exact Rle_of_Req (ofQ_congr (Nat.mul_pos (Nat.succ_pos m) hm)
    (Qmul_den_pos (by decide) (digamma_succ_mul_pos hm)) (by simp only [Qeq, mul]; push_cast; ring_uor))

/-- **The theta Mellin integral** `∫₁^∞ ψ(t) dt`, a genuine constructive real (`σ = 1` Mellin transform
    of `ψ`). Convergent by the per-interval decay `integralTerm_thetaClamp_le` (`K = 2`). -/
def thetaMellin1 : Real :=
  improperIntegral1 (by decide : 0 < (⟨32, 3⟩ : Q).den) (by decide) thetaClamp_lip
    (fun _ _ h => thetaClamp_congr h) (by decide : 0 < (⟨2, 1⟩ : Q).den) (by decide)
    (fun m hm => ⟨Rle_trans
        (Rle_trans (Rle_Rneg (Rle_zero_of_Rnonneg (Rnonneg_ofQ
          (Qmul_den_pos (by decide) (digamma_succ_mul_pos hm)) (by show (0 : Int) ≤ 2 * 1; decide))))
          (Rle_of_Req Rneg_zero))
        (Rle_zero_of_Rnonneg (riemannIntegralI_nonneg _ _ _ _ thetaClamp_nonneg _ _ _ _ _)),
      integralTerm_thetaClamp_le m hm⟩)

/-- **`∫₁^∞ ψ ≥ 0`** — the integrand is non-negative. -/
theorem thetaMellin1_nonneg : Rnonneg thetaMellin1 :=
  improperIntegral1_nonneg _ _ _ _ _ _ _ thetaClamp_nonneg

-- ===========================================================================
-- An explicit upper bound `∫₁^∞ ψ ≤ 2`, via an all-`m` value decay
-- `e^{−π(m+1)} ≤ 1/((m+1)(m+2))` (square trick with `τ = m+1`, no `m ≥ 1` needed).
-- ===========================================================================

/-- **All-`m` `0`-th theta term value bound** `e^{−π(m+1)} ≤ 1/((m+1)(m+2))` (every `m`, via the square
    trick with `τ = m+1` — needs no `m ≥ 1`). The telescoping denominator `(m+1)(m+2)` sums to `≤ 1`. -/
theorem thetaTerm0_value_le2 (m : Nat) :
    Rle (thetaTerm (RnatSucc m) 0)
      (ofQ (⟨1, (m + 1) * (m + 2)⟩ : Q) (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos (m + 1)))) := by
  have he1 : Rle (RexpReal (Rneg (RnatSucc m))) (ofQ (⟨1, m + 2⟩ : Q) (Nat.succ_pos (m + 1))) := by
    refine Rle_trans (Rexp_neg_le_ratio (θ := RnatSucc m) (τ := (⟨(m : Int) + 1, 1⟩ : Q))
        (by show (0 : Int) < (m : Int) + 1; omega) Nat.one_pos
        (Rle_of_Req (Req_refl _))) ?_
    refine Rle_ofQ_ofQ (Qinv_den_pos (by
        show (0 : Int) < (add (⟨1, 1⟩ : Q) (⟨(m : Int) + 1, 1⟩ : Q)).num
        simp only [add]; push_cast; omega)) (Nat.succ_pos (m + 1)) ?_
    simp only [Qle, Qinv, add]; push_cast; omega
  have hprod : Rle (Rmul (RexpReal (Rneg (RnatSucc m))) (RexpReal (Rneg (RnatSucc m))))
      (Rmul (ofQ (⟨1, m + 2⟩ : Q) (Nat.succ_pos (m + 1))) (ofQ (⟨1, m + 2⟩ : Q) (Nat.succ_pos (m + 1)))) :=
    Rmul_le_Rmul_both (RexpReal_nonneg _) (Rnonneg_ofQ (Nat.succ_pos (m + 1))
      (by show (0 : Int) ≤ 1; decide)) he1 he1
  have hLHS : Req (RexpReal (Rneg (Radd (RnatSucc m) (RnatSucc m))))
      (Rmul (RexpReal (Rneg (RnatSucc m))) (RexpReal (Rneg (RnatSucc m)))) :=
    Req_trans (RexpReal_congr (Rneg_Radd (RnatSucc m) (RnatSucc m)))
      (RexpReal_add (Rneg (RnatSucc m)) (Rneg (RnatSucc m)))
  have hpit : Req (thetaArg (RnatSucc m) 0) (Rmul Rpi (RnatSucc m)) := by
    show Req (Rmul (RofNat 1) (Rmul Rpi (RnatSucc m))) (Rmul Rpi (RnatSucc m))
    exact Req_trans (Rmul_comm (RofNat 1) (Rmul Rpi (RnatSucc m))) (Rmul_one (Rmul Rpi (RnatSucc m)))
  have heq2t : Req (Radd (RnatSucc m) (RnatSucc m))
      (Rmul (ofQ (⟨2, 1⟩ : Q) Nat.one_pos) (RnatSucc m)) := by
    unfold RnatSucc
    refine Req_trans (Radd_ofQ_ofQ Nat.one_pos Nat.one_pos)
      (Req_trans (ofQ_congr (add_den_pos Nat.one_pos Nat.one_pos)
          (Qmul_den_pos Nat.one_pos Nat.one_pos) ?_)
        (Req_symm (Rmul_ofQ_ofQ Nat.one_pos Nat.one_pos)))
    simp only [Qeq, add, mul]; push_cast; ring_uor
  have h2pi : Rle (ofQ (⟨2, 1⟩ : Q) Nat.one_pos) Rpi :=
    Rle_trans (Rle_ofQ_ofQ Nat.one_pos Nat.one_pos (by decide)) Rpi_lower_three
  have hle_arg : Rle (Radd (RnatSucc m) (RnatSucc m)) (thetaArg (RnatSucc m) 0) :=
    Rle_trans (Rle_of_Req heq2t)
      (Rle_trans (Rmul_le_Rmul_right (Rnonneg_RnatSucc m) h2pi) (Rle_of_Req (Req_symm hpit)))
  have hstep : Rle (thetaTerm (RnatSucc m) 0)
      (RexpReal (Rneg (Radd (RnatSucc m) (RnatSucc m)))) :=
    RexpReal_le_of_le (Rle_Rneg hle_arg)
  refine Rle_trans hstep (Rle_trans (Rle_of_Req hLHS) (Rle_trans hprod ?_))
  refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (Nat.succ_pos (m + 1)) (Nat.succ_pos (m + 1)))) ?_
  refine Rle_ofQ_ofQ (Qmul_den_pos (Nat.succ_pos (m + 1)) (Nat.succ_pos (m + 1)))
    (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos (m + 1))) ?_
  have hnat : (m + 1) * (m + 2) ≤ (m + 2) * (m + 2) := Nat.mul_le_mul (by omega) (Nat.le_refl _)
  have hI : (((m + 1) * (m + 2) : Nat) : Int) ≤ (((m + 2) * (m + 2) : Nat) : Int) := by exact_mod_cast hnat
  simp only [Qle, mul]; omega

/-- **All-`m` theta value decay** `ψ(m+1) ≤ 2/((m+1)(m+2))` (every `m`). -/
theorem thetaFn_value_decay2 (m : Nat) :
    Rle (thetaFn (RnatSucc m) (one_le_RnatSucc m))
      (ofQ (⟨2, (m + 1) * (m + 2)⟩ : Q) (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos (m + 1)))) := by
  refine Rle_trans (thetaFn_decay (RnatSucc m) (one_le_RnatSucc m)) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (thetaTerm0_value_le2 m)) ?_
  refine Rle_of_Req (Req_trans (Rmul_ofQ_ofQ (by decide)
    (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos (m + 1))))
    (ofQ_congr (Qmul_den_pos (by decide) (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos (m + 1))))
      (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos (m + 1))) ?_))
  simp only [Qeq, mul]; push_cast; ring_uor

/-- **Per-interval bound valid for every `m`**: `∫_{m+1}^{m+2} ψ ≤ 2/((m+1)(m+2))`. -/
theorem integralTerm_thetaClamp_le2 (m : Nat) :
    Rle (integralTerm (by decide : 0 < (⟨32, 3⟩ : Q).den) (by decide) thetaClamp_lip
        (fun _ _ h => thetaClamp_congr h) m)
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (boundTele m)) := by
  have hub : Rle (integralTerm (by decide : 0 < (⟨32, 3⟩ : Q).den) (by decide) thetaClamp_lip
        (fun _ _ h => thetaClamp_congr h) m)
      (riemannIntegralI (f := fun _ => thetaFn (RnatSucc m) (one_le_RnatSucc m))
        (L := (⟨32, 3⟩ : Q)) (by decide) (by decide) (const_lip32 _) (fun _ _ _ => Req_refl _)
        (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)) := by
    refine riemannIntegralI_le_unit (by decide) (by decide) thetaClamp_lip
      (fun _ _ h => thetaClamp_congr h) (const_lip32 _) (fun _ _ _ => Req_refl _)
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide) (fun x hx0 hx1 => ?_)
    have hxnn : Rnonneg x := Rnonneg_of_Rle_zero hx0
    have hpge : Rle (RnatSucc m) (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos
        (by decide) x) :=
      Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) hxnn)
    have hp1 : Rle one (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x) :=
      Rle_trans (one_le_RnatSucc m) hpge
    refine Rle_trans (Rle_of_Req (thetaFn_congr (clampOne_ge_one _) hp1
        (clampOne_eq_of_ge hp1))) ?_
    exact thetaFn_antitone (one_le_RnatSucc m) hp1 hpge
  refine Rle_trans hub ?_
  refine Rle_trans (Rle_of_Req (riemannIntegralI_const32 _ _ _ _ _ _)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_comm _ _)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_one _)) ?_
  -- `ψ(m+1) ≤ 2/((m+1)(m+2)) = 2·boundTele m`
  refine Rle_trans (thetaFn_value_decay2 m) (Rle_of_Req ?_)
  refine Req_trans ?_ (Req_symm (Rmul_ofQ_ofQ (by decide)
    (Qmul_den_pos (by decide) (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos (m + 1))))))
  exact ofQ_congr (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos (m + 1)))
    (Qmul_den_pos (by decide) (Qmul_den_pos (by decide)
      (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos (m + 1)))))
    (by simp only [Qeq, mul]; push_cast; ring_uor)

/-- **`∫₁^∞ ψ ≤ 2`** — every partial integral is `≤ Σ 2/((m+1)(m+2)) = 2N/(N+1) ≤ 2`. -/
theorem thetaMellin1_le : Rle thetaMellin1 (ofQ (⟨2, 1⟩ : Q) (by decide)) := by
  unfold thetaMellin1 improperIntegral1
  refine Rlim_le_ofQ _ (by decide) (fun j => ?_)
  have hbt : Rle (genSum boundTele (digammaMidx (⟨2, 1⟩ : Q) j)) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
    Rle_trans (Rle_of_Req (genSum_boundTele (digammaMidx (⟨2, 1⟩ : Q) j)))
      (Rle_ofQ_ofQ (Nat.succ_pos _) (by decide) (by simp only [Qle]; push_cast; omega))
  refine Rle_trans (genSum_le_genSum (fun m => integralTerm_thetaClamp_le2 m) (digammaMidx (⟨2, 1⟩ : Q) j)) ?_
  refine Rle_trans (Rle_of_Req (genSum_Rmul_const (ofQ (⟨2, 1⟩ : Q) (by decide)) boundTele
    (digammaMidx (⟨2, 1⟩ : Q) j))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) hbt) ?_
  exact Rle_of_Req (Rmul_one (ofQ (⟨2, 1⟩ : Q) (by decide)))

end UOR.Bridge.F1Square.Analysis
