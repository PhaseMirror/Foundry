/-
F1 square — Track 1, item 3/6: **the general-σ theta–Mellin integrand** `t^{σ−1}·ψ(t)` and its
integral `∫₁^∞ t^{σ−1}ψ(t) dt` (`ThetaMellinPow.lean`).

`thetaMellin1` (`ThetaMellin.lean`) is the `σ = 1` case `∫₁^∞ ψ`. The general exponent `e = σ−1 ≤ 0`
multiplies in the power factor `gPowClamp e` (`RpowClampLip.lean`). Both factors are total, bounded by `1`,
and Lipschitz, so the product is Lipschitz (`Rmul_lipschitz`) and bounded; the per-interval decay reuses
`integralTerm_thetaClamp_le` (the product `≤ ψ` there, since `0 ≤ t^e ≤ 1`). This assembles the σ-general
real Mellin object the roadmap's item-3 bridge `ThetaModular ⟹ CompletedZetaFE` consumes.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.RpowClampLip
import Core.F1.Analysis.ThetaMellin
import Core.F1.Analysis.RmulLipschitz

namespace UOR.Bridge.F1Square.Analysis

/-- `gPowClamp e t ≥ 0` (it is an `exp`). -/
theorem gPowClamp_nonneg (e t : Real) : Rnonneg (gPowClamp e t) := by
  unfold gPowClamp; exact RexpReal_nonneg _

/-- `gPowClamp e t ≤ 1` for `e ≤ 0` (since `max(t,1) ≥ 1`). -/
theorem gPowClamp_le_one (e : Real) (he : Rle e zero) (t : Real) : Rle (gPowClamp e t) one := by
  unfold gPowClamp
  exact RrpowPos_le_one_of_nonpos (qClampOne t) 1 (ge1_pos_witness (qClampOne t) (qClampOne_ge1 t 1))
    (Rle_one_of_seq_ge1 (qClampOne_ge1 t)) e he

/-- `|gPowClamp e t| ≤ 1` for `e ≤ 0` — the integral-interface bound (`ofQ 1`-valued, `one = ofQ ⟨1,1⟩`). -/
theorem gPowClamp_abs_le_one (e : Real) (he : Rle e zero) (t : Real) :
    Rle (Rabs (gPowClamp e t)) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
  Rle_trans (Rle_of_Req (Rabs_of_nonneg (gPowClamp_nonneg e t))) (gPowClamp_le_one e he t)

/-- `|thetaClamp t| ≤ 1` — the integral-interface bound for the ψ factor. -/
theorem thetaClamp_abs_le_one (t : Real) :
    Rle (Rabs (thetaClamp t)) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
  Rle_trans (Rle_of_Req (Rabs_of_nonneg (thetaClamp_nonneg t)))
    (thetaFn_le_one (clampOne t) (clampOne_ge_one t))

-- ===========================================================================
-- The σ-general product integrand  t^{e}·ψ(t)  with an ABSTRACT real exponent.
-- ===========================================================================

/-- **The σ-general theta–Mellin integrand** `gPowTheta e t = max(t,1)^e · ψ(max(t,1))` — the product
    of the totalized power factor (`gPowClamp e`, `RpowClampLip.lean`) and the totalized ψ factor
    (`thetaClamp`, `ThetaMellin.lean`). On `[1,∞)` this is `t^e·ψ(t)`, the integrand of the `σ`-general
    Mellin transform `∫₁^∞ t^{σ−1}ψ(t)` (`e = σ−1`). The exponent stays an abstract `Real`. -/
def gPowTheta (e t : Real) : Real := Rmul (gPowClamp e t) (thetaClamp t)

/-- **`gPowTheta e` is Lipschitz with a real constant** `1·(32/3) + 1·(4·|e|)` for `e ≤ 0` — assembled
    by `Rmul_lipschitz_real` from the power factor (`4·|e|`-Lipschitz, `≤ 1`) and the ψ factor
    (`32/3`-Lipschitz, `≤ 1`). The constant is a genuine real (it contains `|e|` for abstract `e`), so
    no `ofQ q` enters and the `whnf` cascade never fires. -/
theorem gPowTheta_lip (e : Real) (he : Rle e zero) (x y : Real) :
    Rle (Rabs (Rsub (gPowTheta e x) (gPowTheta e y)))
        (Rmul (Radd (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (ofQ (⟨32, 3⟩ : Q) (by decide)))
                    (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide))
                          (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs e))))
             (Rabs (Rsub x y))) :=
  Rmul_lipschitz_real (Lf := Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs e))
    (Lg := ofQ (⟨32, 3⟩ : Q) (by decide)) (Mf := ofQ (⟨1, 1⟩ : Q) (by decide))
    (Mg := ofQ (⟨1, 1⟩ : Q) (by decide))
    (Rnonneg_ofQ (by decide) (by decide)) (Rnonneg_ofQ (by decide) (by decide))
    (gPowClamp_lipschitz e he) thetaClamp_lip (gPowClamp_abs_le_one e he) thetaClamp_abs_le_one x y

/-- **`gPowTheta e` respects `≈`** — the integral's `hfc` hypothesis, from the two factors' congruences. -/
theorem gPowTheta_congr (e : Real) (he : Rle e zero) {x y : Real} (hxy : Req x y) :
    Req (gPowTheta e x) (gPowTheta e y) :=
  Rmul_congr (gPowClamp_congr e he hxy) (thetaClamp_congr hxy)

/-- **`gPowTheta e t ≥ 0`** — a product of non-negatives. -/
theorem gPowTheta_nonneg (e t : Real) : Rnonneg (gPowTheta e t) :=
  Rnonneg_Rmul (gPowClamp_nonneg e t) (thetaClamp_nonneg t)

/-- **Rational over-bound on the product Lipschitz constant**: given a rational bound `|e| ≤ ofQ B`,
    the real constant `1·(32/3) + 1·(4·|e|)` is `≤ ofQ (32/3 + 4·B)` — the schedule modulus the integral
    layer consumes. (`Rone_mul` collapses the unit `M`-factors, then `4·|e| ≤ 4·B`.) -/
theorem gPowTheta_L_le_ofQ (e : Real) (B : Q) (hB : 0 < B.den)
    (heB : Rle (Rabs e) (ofQ B hB)) :
    Rle (Radd (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (ofQ (⟨32, 3⟩ : Q) (by decide)))
              (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide))
                    (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs e))))
        (ofQ (add (⟨32, 3⟩ : Q) (mul (⟨4, 1⟩ : Q) B))
          (add_den_pos (by decide) (Qmul_den_pos (by decide) hB))) := by
  refine Rle_trans (Rle_of_Req (Radd_congr (Rone_mul _) (Rone_mul _))) ?_
  refine Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _))
      (Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) heB)
        (Rle_of_Req (Rmul_ofQ_ofQ (by decide) hB)))) ?_
  exact Rle_of_Req (Radd_ofQ_ofQ (by decide) (Qmul_den_pos (by decide) hB))

/-- Constant integrand is Lipschitz for *any* modulus `Lq` (`|c − c| = 0 ≤ Lq·|x−y|`). -/
private theorem const_lip_any (c : Real) {Lq : Q} (hLqd : 0 < Lq.den) (hLqn : 0 ≤ Lq.num) :
    ∀ x y, Rle (Rabs (Rsub c c)) (Rmul (ofQ Lq hLqd) (Rabs (Rsub x y))) := fun x y =>
  Rle_trans (Rle_of_Req (Req_trans (Rabs_congr (Radd_neg c)) Rabs_zero))
    (Rle_zero_of_Rnonneg (Rnonneg_Rmul (Rnonneg_ofQ hLqd hLqn) (Rnonneg_Rabs _)))

/-- `∫_a^{a+w} c = w·c` for any modulus `Lq` (the constant survives the affine pullback). -/
private theorem riemannIntegralI_const_any (c : Real) {Lq : Q} (hLqd : 0 < Lq.den)
    (hLqn : 0 ≤ Lq.num) (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Req (riemannIntegralI (f := fun _ => c) hLqd hLqn (const_lip_any c hLqd hLqn)
          (fun _ _ _ => Req_refl c) a w ha hw hwn) (Rmul (ofQ w hw) c) :=
  Rmul_congr (Req_refl _) (riemannIntegral_const_gen c _ _ _ _)

/-- **Per-interval decay for the product** `∫_{m+1}^{m+2} t^e·ψ ≤ 2/((m+1)m)` (`m ≥ 1`, generic over the
    rational schedule modulus `Lq`). On the interval, `0 ≤ t^e ≤ 1` and `ψ ≥ 0`, so the integrand is
    `≤ ψ(t) ≤ ψ(m+1)`; integrate the constant and apply the σ=1 value decay. Same `K = 2` bound as the
    σ=1 integrand, so the half-line sum converges on the *same* schedule. -/
theorem integralTerm_gPowTheta_le (e : Real) (he : Rle e zero) {Lq : Q} (hLqd : 0 < Lq.den)
    (hLqn : 0 ≤ Lq.num)
    (hlipq : ∀ x y, Rle (Rabs (Rsub (gPowTheta e x) (gPowTheta e y)))
      (Rmul (ofQ Lq hLqd) (Rabs (Rsub x y))))
    (m : Nat) (hm : 1 ≤ m) :
    Rle (integralTerm hLqd hLqn hlipq (fun _ _ h => gPowTheta_congr e he h) m)
      (ofQ (mul (⟨2, 1⟩ : Q) (⟨1, (m + 1) * m⟩ : Q))
        (Qmul_den_pos (by decide) (digamma_succ_mul_pos hm))) := by
  have hub : Rle (integralTerm hLqd hLqn hlipq (fun _ _ h => gPowTheta_congr e he h) m)
      (riemannIntegralI (f := fun _ => thetaFn (RnatSucc m) (one_le_RnatSucc m))
        hLqd hLqn (const_lip_any _ hLqd hLqn) (fun _ _ _ => Req_refl _)
        (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)) := by
    refine riemannIntegralI_le_unit hLqd hLqn hlipq (fun _ _ h => gPowTheta_congr e he h)
      (const_lip_any _ hLqd hLqn) (fun _ _ _ => Req_refl _)
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide) (fun x hx0 hx1 => ?_)
    have hxnn : Rnonneg x := Rnonneg_of_Rle_zero hx0
    have hpge : Rle (RnatSucc m) (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos
        (by decide) x) :=
      Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) hxnn)
    have hp1 : Rle one (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x) :=
      Rle_trans (one_le_RnatSucc m) hpge
    -- `t^e·ψ(t) ≤ 1·ψ(t) = ψ(t) ≤ ψ(m+1)` on the interval.
    show Rle (gPowTheta e _) _
    unfold gPowTheta
    refine Rle_trans (Rmul_le_Rmul_right (thetaClamp_nonneg _) (gPowClamp_le_one e he _)) ?_
    refine Rle_trans (Rle_of_Req (Rone_mul _)) ?_
    refine Rle_trans (Rle_of_Req (thetaFn_congr (clampOne_ge_one _) hp1
        (clampOne_eq_of_ge hp1))) ?_
    exact thetaFn_antitone (one_le_RnatSucc m) hp1 hpge
  refine Rle_trans hub ?_
  refine Rle_trans (Rle_of_Req (riemannIntegralI_const_any _ _ _ _ _ _ _ _)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_comm _ _)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_one _)) ?_
  refine Rle_trans (thetaFn_value_decay m hm (one_le_RnatSucc m)) ?_
  exact Rle_of_Req (ofQ_congr (Nat.mul_pos (Nat.succ_pos m) hm)
    (Qmul_den_pos (by decide) (digamma_succ_mul_pos hm)) (by simp only [Qeq, mul]; push_cast; ring_uor))

/-- **The σ-general theta–Mellin integral** `∫₁^∞ t^{σ−1}ψ(t) dt` (`e = σ−1 ≤ 0`), a genuine
    constructive real for *any* abstract exponent `e` with a rational magnitude bound `|e| ≤ ofQ B`.
    The schedule modulus is the rational `32/3 + 4·B` (from `gPowTheta_L_le_ofQ`), while the genuine
    Lipschitz modulus stays the real `32/3 + 4·|e|`; convergence is the same `K = 2` decay as the σ=1
    case (`integralTerm_gPowTheta_le`). This is the σ-general Mellin object item-3's bridge consumes. -/
def thetaMellinPow (e : Real) (he : Rle e zero) (B : Q) (hB : 0 < B.den) (hBn : 0 ≤ B.num)
    (heB : Rle (Rabs e) (ofQ B hB)) : Real :=
  improperIntegral1 (add_den_pos (by decide) (Qmul_den_pos (by decide) hB))
    (by have h1 : (0 : Int) ≤ B.num := hBn
        have h2 : (0 : Int) ≤ (B.den : Int) := Int.ofNat_nonneg _
        show 0 ≤ (add (⟨32, 3⟩ : Q) (mul (⟨4, 1⟩ : Q) B)).num
        simp only [add, mul]; push_cast; omega)
    (lip_q_of_lip_real (add_den_pos (by decide) (Qmul_den_pos (by decide) hB))
      (gPowTheta_L_le_ofQ e B hB heB) (gPowTheta_lip e he))
    (fun _ _ h => gPowTheta_congr e he h) (by decide : 0 < (⟨2, 1⟩ : Q).den) (by decide)
    (fun m hm => ⟨Rle_trans
        (Rle_trans (Rle_Rneg (Rle_zero_of_Rnonneg (Rnonneg_ofQ
          (Qmul_den_pos (by decide) (digamma_succ_mul_pos hm)) (by show (0 : Int) ≤ 2 * 1; decide))))
          (Rle_of_Req Rneg_zero))
        (Rle_zero_of_Rnonneg (riemannIntegralI_nonneg _ _ _ _ (gPowTheta_nonneg e) _ _ _ _ _)),
      integralTerm_gPowTheta_le e he _ _ _ m hm⟩)

/-- **`∫₁^∞ t^{σ−1}ψ ≥ 0`** — the integrand is non-negative. -/
theorem thetaMellinPow_nonneg (e : Real) (he : Rle e zero) (B : Q) (hB : 0 < B.den) (hBn : 0 ≤ B.num)
    (heB : Rle (Rabs e) (ofQ B hB)) : Rnonneg (thetaMellinPow e he B hB hBn heB) :=
  improperIntegral1_nonneg _ _ _ _ _ _ _ (gPowTheta_nonneg e)

-- ===========================================================================
-- The SYMMETRIC two-power Mellin kernel  (t^{e₁}+t^{e₂})·ψ(t)  and its s↔1−s swap
-- symmetry — the structural core of the completed-ζ functional equation, over the
-- certified half-line integral.
-- ===========================================================================

/-- **Pointwise `t^e·ψ(t) ≤ ψ(t)`** for `e ≤ 0` (since `0 ≤ t^e ≤ 1`) — the reusable factor-drop. -/
theorem gPowTheta_le_thetaClamp (e : Real) (he : Rle e zero) (t : Real) :
    Rle (gPowTheta e t) (thetaClamp t) := by
  unfold gPowTheta
  exact Rle_trans (Rmul_le_Rmul_right (thetaClamp_nonneg t) (gPowClamp_le_one e he t))
    (Rle_of_Req (Rone_mul _))

/-- **`ψ(max(t,1)) ≤ ψ(m+1)`** when `t ≥ m+1 ≥ 1` — the antitone drop to the interval's left endpoint. -/
theorem thetaClamp_le_succ (m : Nat) (t : Real) (hp1 : Rle one t) (hpge : Rle (RnatSucc m) t) :
    Rle (thetaClamp t) (thetaFn (RnatSucc m) (one_le_RnatSucc m)) :=
  Rle_trans (Rle_of_Req (thetaFn_congr (clampOne_ge_one t) hp1 (clampOne_eq_of_ge hp1)))
    (thetaFn_antitone (one_le_RnatSucc m) hp1 hpge)

/-- **The symmetric two-power integrand** `gPowThetaSym e₁ e₂ t = t^{e₁}·ψ + t^{e₂}·ψ` (on `[1,∞)`).
    Under `s ↦ 1−s` the Mellin exponents `e₁ = s/2−1`, `e₂ = (1−s)/2−1` swap, so this kernel is the
    `s↔1−s`-symmetric part of the completed-ζ integral. -/
def gPowThetaSym (e1 e2 t : Real) : Real := Radd (gPowTheta e1 t) (gPowTheta e2 t)

/-- `gPowThetaSym e₁ e₂ t ≥ 0`. -/
theorem gPowThetaSym_nonneg (e1 e2 t : Real) : Rnonneg (gPowThetaSym e1 e2 t) :=
  Rnonneg_Radd (gPowTheta_nonneg e1 t) (gPowTheta_nonneg e2 t)

/-- `gPowThetaSym e₁ e₂` respects `≈`. -/
theorem gPowThetaSym_congr (e1 e2 : Real) (he1 : Rle e1 zero) (he2 : Rle e2 zero) {x y : Real}
    (hxy : Req x y) : Req (gPowThetaSym e1 e2 x) (gPowThetaSym e1 e2 y) :=
  Radd_congr (gPowTheta_congr e1 he1 hxy) (gPowTheta_congr e2 he2 hxy)

/-- **`gPowThetaSym e₁ e₂ ≈ gPowThetaSym e₂ e₁`** pointwise — addition commutes (the bare swap). -/
theorem gPowThetaSym_swap (e1 e2 t : Real) : Req (gPowThetaSym e1 e2 t) (gPowThetaSym e2 e1 t) :=
  Radd_comm (gPowTheta e1 t) (gPowTheta e2 t)

/-- **`gPowThetaSym e₁ e₂` is Lipschitz** with the real constant `C(e₁) + C(e₂)` (sum of the two
    factor constants), via `Radd_lipschitz_real`. -/
theorem gPowThetaSym_lip (e1 e2 : Real) (he1 : Rle e1 zero) (he2 : Rle e2 zero) (x y : Real) :
    Rle (Rabs (Rsub (gPowThetaSym e1 e2 x) (gPowThetaSym e1 e2 y)))
        (Rmul (Radd
          (Radd (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (ofQ (⟨32, 3⟩ : Q) (by decide)))
                (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide))
                      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs e1))))
          (Radd (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (ofQ (⟨32, 3⟩ : Q) (by decide)))
                (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide))
                      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs e2)))))
          (Rabs (Rsub x y))) :=
  Radd_lipschitz_real (gPowTheta_lip e1 he1) (gPowTheta_lip e2 he2) x y

/-- **Rational over-bound on the symmetric constant**: given `|e₁| ≤ ofQ B` and `|e₂| ≤ ofQ B`, the
    real constant `C(e₁)+C(e₂)` is `≤ ofQ (2·(32/3 + 4·B))`. Symmetric in `e₁, e₂` (depends only on `B`),
    so both swap-orderings share the schedule. -/
theorem gPowThetaSym_L_le_ofQ (e1 e2 : Real) (B : Q) (hB : 0 < B.den)
    (heB1 : Rle (Rabs e1) (ofQ B hB)) (heB2 : Rle (Rabs e2) (ofQ B hB)) :
    Rle (Radd
          (Radd (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (ofQ (⟨32, 3⟩ : Q) (by decide)))
                (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide))
                      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs e1))))
          (Radd (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (ofQ (⟨32, 3⟩ : Q) (by decide)))
                (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide))
                      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs e2)))))
        (ofQ (mul (⟨2, 1⟩ : Q) (add (⟨32, 3⟩ : Q) (mul (⟨4, 1⟩ : Q) B)))
          (Qmul_den_pos (by decide) (add_den_pos (by decide) (Qmul_den_pos (by decide) hB)))) := by
  refine Rle_trans (Radd_le_add (gPowTheta_L_le_ofQ e1 B hB heB1)
    (gPowTheta_L_le_ofQ e2 B hB heB2)) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (add_den_pos (by decide) (Qmul_den_pos (by decide) hB))
    (add_den_pos (by decide) (Qmul_den_pos (by decide) hB)))) ?_
  exact Rle_of_Req (ofQ_congr (add_den_pos (add_den_pos (by decide) (Qmul_den_pos (by decide) hB))
      (add_den_pos (by decide) (Qmul_den_pos (by decide) hB)))
    (Qmul_den_pos (by decide) (add_den_pos (by decide) (Qmul_den_pos (by decide) hB)))
    (by simp only [Qeq, add, mul]; push_cast; ring_uor))

/-- **Per-interval decay for the symmetric integrand** `∫_{m+1}^{m+2}(t^{e₁}+t^{e₂})ψ ≤ 4/((m+1)m)`
    (`m ≥ 1`, `K = 4`): on the interval each summand is `≤ ψ(t) ≤ ψ(m+1)`, so the sum is `≤ 2ψ(m+1)`. -/
theorem integralTerm_gPowThetaSym_le (e1 e2 : Real) (he1 : Rle e1 zero) (he2 : Rle e2 zero) {Lq : Q}
    (hLqd : 0 < Lq.den) (hLqn : 0 ≤ Lq.num)
    (hlipq : ∀ x y, Rle (Rabs (Rsub (gPowThetaSym e1 e2 x) (gPowThetaSym e1 e2 y)))
      (Rmul (ofQ Lq hLqd) (Rabs (Rsub x y))))
    (m : Nat) (hm : 1 ≤ m) :
    Rle (integralTerm hLqd hLqn hlipq (fun _ _ h => gPowThetaSym_congr e1 e2 he1 he2 h) m)
      (ofQ (mul (⟨4, 1⟩ : Q) (⟨1, (m + 1) * m⟩ : Q))
        (Qmul_den_pos (by decide) (digamma_succ_mul_pos hm))) := by
  have hub : Rle (integralTerm hLqd hLqn hlipq (fun _ _ h => gPowThetaSym_congr e1 e2 he1 he2 h) m)
      (riemannIntegralI (f := fun _ => Radd (thetaFn (RnatSucc m) (one_le_RnatSucc m))
            (thetaFn (RnatSucc m) (one_le_RnatSucc m)))
        hLqd hLqn (const_lip_any _ hLqd hLqn) (fun _ _ _ => Req_refl _)
        (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)) := by
    refine riemannIntegralI_le_unit hLqd hLqn hlipq (fun _ _ h => gPowThetaSym_congr e1 e2 he1 he2 h)
      (const_lip_any _ hLqd hLqn) (fun _ _ _ => Req_refl _)
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide) (fun x hx0 hx1 => ?_)
    have hxnn : Rnonneg x := Rnonneg_of_Rle_zero hx0
    have hpge : Rle (RnatSucc m) (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos
        (by decide) x) :=
      Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) hxnn)
    have hp1 : Rle one (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x) :=
      Rle_trans (one_le_RnatSucc m) hpge
    show Rle (gPowThetaSym e1 e2 _) _
    unfold gPowThetaSym
    exact Radd_le_add
      (Rle_trans (gPowTheta_le_thetaClamp e1 he1 _) (thetaClamp_le_succ m _ hp1 hpge))
      (Rle_trans (gPowTheta_le_thetaClamp e2 he2 _) (thetaClamp_le_succ m _ hp1 hpge))
  refine Rle_trans hub ?_
  refine Rle_trans (Rle_of_Req (riemannIntegralI_const_any _ _ _ _ _ _ _ _)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_comm _ _)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_one _)) ?_
  -- `2·ψ(m+1) ≤ 4/((m+1)m)`
  refine Rle_trans (Radd_le_add (thetaFn_value_decay m hm (one_le_RnatSucc m))
    (thetaFn_value_decay m hm (one_le_RnatSucc m))) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (Nat.mul_pos (Nat.succ_pos m) hm)
    (Nat.mul_pos (Nat.succ_pos m) hm))) ?_
  exact Rle_of_Req (ofQ_congr (add_den_pos (Nat.mul_pos (Nat.succ_pos m) hm)
      (Nat.mul_pos (Nat.succ_pos m) hm)) (Qmul_den_pos (by decide) (digamma_succ_mul_pos hm))
    (by simp only [Qeq, add, mul]; push_cast; ring_uor))

/-- **The symmetric theta–Mellin integral** `∫₁^∞ (t^{e₁}+t^{e₂})ψ(t) dt`, for abstract `e₁,e₂ ≤ 0`
    both with magnitude `≤ ofQ B`. Schedule modulus `2·(32/3+4B)`, decay `K = 4`. -/
def thetaMellinPowSym (e1 e2 : Real) (he1 : Rle e1 zero) (he2 : Rle e2 zero) (B : Q) (hB : 0 < B.den)
    (hBn : 0 ≤ B.num) (heB1 : Rle (Rabs e1) (ofQ B hB)) (heB2 : Rle (Rabs e2) (ofQ B hB)) : Real :=
  improperIntegral1
    (Qmul_den_pos (by decide) (add_den_pos (by decide) (Qmul_den_pos (by decide) hB)))
    (by have h1 : (0 : Int) ≤ B.num := hBn
        have h2 : (0 : Int) ≤ (B.den : Int) := Int.ofNat_nonneg _
        show 0 ≤ (mul (⟨2, 1⟩ : Q) (add (⟨32, 3⟩ : Q) (mul (⟨4, 1⟩ : Q) B))).num
        simp only [add, mul]; push_cast; omega)
    (lip_q_of_lip_real (Qmul_den_pos (by decide) (add_den_pos (by decide) (Qmul_den_pos (by decide) hB)))
      (gPowThetaSym_L_le_ofQ e1 e2 B hB heB1 heB2) (gPowThetaSym_lip e1 e2 he1 he2))
    (fun _ _ h => gPowThetaSym_congr e1 e2 he1 he2 h) (by decide : 0 < (⟨4, 1⟩ : Q).den) (by decide)
    (fun m hm => ⟨Rle_trans
        (Rle_trans (Rle_Rneg (Rle_zero_of_Rnonneg (Rnonneg_ofQ
          (Qmul_den_pos (by decide) (digamma_succ_mul_pos hm)) (by show (0 : Int) ≤ 4 * 1; decide))))
          (Rle_of_Req Rneg_zero))
        (Rle_zero_of_Rnonneg (riemannIntegralI_nonneg _ _ _ _ (gPowThetaSym_nonneg e1 e2) _ _ _ _ _)),
      integralTerm_gPowThetaSym_le e1 e2 he1 he2 _ _ _ m hm⟩)

/-- **`∫₁^∞ (t^{e₁}+t^{e₂})ψ ≥ 0`**. -/
theorem thetaMellinPowSym_nonneg (e1 e2 : Real) (he1 : Rle e1 zero) (he2 : Rle e2 zero) (B : Q)
    (hB : 0 < B.den) (hBn : 0 ≤ B.num) (heB1 : Rle (Rabs e1) (ofQ B hB))
    (heB2 : Rle (Rabs e2) (ofQ B hB)) :
    Rnonneg (thetaMellinPowSym e1 e2 he1 he2 B hB hBn heB1 heB2) :=
  improperIntegral1_nonneg _ _ _ _ _ _ _ (gPowThetaSym_nonneg e1 e2)

/-- **★ The s↔1−s symmetry of the completed-ζ Mellin kernel, over the certified integral**:
    `∫₁^∞ (t^{e₁}+t^{e₂})ψ = ∫₁^∞ (t^{e₂}+t^{e₁})ψ`. Both orderings share the schedule (the modulus
    `2·(32/3+4B)` and decay `K=4` are symmetric in `e₁,e₂`), and the integrands agree pointwise
    (`gPowThetaSym_swap`), so `improperIntegral1_congr` lifts the swap to the integral. This is the
    constructive face of `Z(s)=Z(1−s)`'s symmetric integral representation — the part reachable without
    the Mellin/Poisson identity that still gates the full `CompletedZetaFE`. -/
theorem thetaMellinPowSym_symm (e1 e2 : Real) (he1 : Rle e1 zero) (he2 : Rle e2 zero) (B : Q)
    (hB : 0 < B.den) (hBn : 0 ≤ B.num) (heB1 : Rle (Rabs e1) (ofQ B hB))
    (heB2 : Rle (Rabs e2) (ofQ B hB)) :
    Req (thetaMellinPowSym e1 e2 he1 he2 B hB hBn heB1 heB2)
        (thetaMellinPowSym e2 e1 he2 he1 B hB hBn heB2 heB1) :=
  improperIntegral1_congr _ _ _ _ _ _ _ _ _ _ (fun t => gPowThetaSym_swap e1 e2 t)

-- ===========================================================================
-- Uniform upper bound  ∫₁^∞ t^{σ−1}ψ ≤ 2  for σ ≤ 1  (independent of σ).
-- ===========================================================================

/-- **All-`m` per-interval bound for the product** `∫_{m+1}^{m+2} t^e·ψ ≤ 2/((m+1)(m+2))` (every `m`,
    `e ≤ 0`): `t^e·ψ ≤ ψ(t) ≤ ψ(m+1) ≤ 2/((m+1)(m+2))` (the all-`m` value decay `thetaFn_value_decay2`).
    The telescoping denominators sum to `≤ 1`. -/
theorem integralTerm_gPowTheta_le2 (e : Real) (he : Rle e zero) {Lq : Q} (hLqd : 0 < Lq.den)
    (hLqn : 0 ≤ Lq.num)
    (hlipq : ∀ x y, Rle (Rabs (Rsub (gPowTheta e x) (gPowTheta e y)))
      (Rmul (ofQ Lq hLqd) (Rabs (Rsub x y))))
    (m : Nat) :
    Rle (integralTerm hLqd hLqn hlipq (fun _ _ h => gPowTheta_congr e he h) m)
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (boundTele m)) := by
  have hub : Rle (integralTerm hLqd hLqn hlipq (fun _ _ h => gPowTheta_congr e he h) m)
      (riemannIntegralI (f := fun _ => thetaFn (RnatSucc m) (one_le_RnatSucc m))
        hLqd hLqn (const_lip_any _ hLqd hLqn) (fun _ _ _ => Req_refl _)
        (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)) := by
    refine riemannIntegralI_le_unit hLqd hLqn hlipq (fun _ _ h => gPowTheta_congr e he h)
      (const_lip_any _ hLqd hLqn) (fun _ _ _ => Req_refl _)
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide) (fun x hx0 hx1 => ?_)
    have hxnn : Rnonneg x := Rnonneg_of_Rle_zero hx0
    have hpge : Rle (RnatSucc m) (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos
        (by decide) x) :=
      Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) hxnn)
    have hp1 : Rle one (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x) :=
      Rle_trans (one_le_RnatSucc m) hpge
    show Rle (gPowTheta e _) _
    exact Rle_trans (gPowTheta_le_thetaClamp e he _) (thetaClamp_le_succ m _ hp1 hpge)
  refine Rle_trans hub ?_
  refine Rle_trans (Rle_of_Req (riemannIntegralI_const_any _ _ _ _ _ _ _ _)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_comm _ _)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_one _)) ?_
  refine Rle_trans (thetaFn_value_decay2 m) (Rle_of_Req ?_)
  refine Req_trans ?_ (Req_symm (Rmul_ofQ_ofQ (by decide)
    (Qmul_den_pos (by decide) (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos (m + 1))))))
  exact ofQ_congr (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos (m + 1)))
    (Qmul_den_pos (by decide) (Qmul_den_pos (by decide)
      (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos (m + 1))))) (by simp only [Qeq, mul]; push_cast; ring_uor)

/-- **`∫₁^∞ t^{σ−1}ψ ≤ 2`** (`σ = e+1 ≤ 1`), uniformly in `σ` — since `0 ≤ t^e ≤ 1`, the product is
    dominated by `ψ`, whose integral is `≤ 2` (telescoping `Σ 2/((m+1)(m+2)) = 2N/(N+1) ≤ 2`). -/
theorem thetaMellinPow_le_two (e : Real) (he : Rle e zero) (B : Q) (hB : 0 < B.den) (hBn : 0 ≤ B.num)
    (heB : Rle (Rabs e) (ofQ B hB)) :
    Rle (thetaMellinPow e he B hB hBn heB) (ofQ (⟨2, 1⟩ : Q) (by decide)) := by
  unfold thetaMellinPow improperIntegral1
  refine Rlim_le_ofQ _ (by decide) (fun j => ?_)
  have hbt : Rle (genSum boundTele (digammaMidx (⟨2, 1⟩ : Q) j)) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
    Rle_trans (Rle_of_Req (genSum_boundTele (digammaMidx (⟨2, 1⟩ : Q) j)))
      (Rle_ofQ_ofQ (Nat.succ_pos _) (by decide) (by simp only [Qle]; push_cast; omega))
  refine Rle_trans (genSum_le_genSum
    (fun m => integralTerm_gPowTheta_le2 e he _ _ _ m) (digammaMidx (⟨2, 1⟩ : Q) j)) ?_
  refine Rle_trans (Rle_of_Req (genSum_Rmul_const (ofQ (⟨2, 1⟩ : Q) (by decide)) boundTele
    (digammaMidx (⟨2, 1⟩ : Q) j))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) hbt) ?_
  exact Rle_of_Req (Rmul_one (ofQ (⟨2, 1⟩ : Q) (by decide)))

end UOR.Bridge.F1Square.Analysis
