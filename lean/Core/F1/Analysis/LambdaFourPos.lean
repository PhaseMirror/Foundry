/-
F1 square — v0.22.0 crux frontier: **`Pos Rlambda4`** (the `n = 4` prime–archimedean coupling
coefficient), the next rung beyond `Pos Rlambda3`.

Assembled from the three tightened constant brackets — `γ₁ ≤ −0.0677` (`Rgamma1_le_neg0677`),
`γ₂ ≤ 1/40` (`Rgamma2_le`), `γ₃ ≤ 1/8` (`Rgamma3_le`) — together with `γ ∈ [0.577,0.578]`,
`γ₂ ≥ −0.02`, `ζ(2) ≥ 1.644`, `ζ(3) ≤ 1.217`, `ζ(4) ≥ 1.082`, `log 4π ≤ 2.5316`.

`λ₄ = λ₄^{arith} + λ₄^{∞}`, `λ₄^{arith} = −(4η₀ + 6η₁ + 4η₂ + η₃)`,
`η₃ = γ⁴ + 4γ²γ₁ + 2γ₁² + 2γγ₂ + (2/3)γ₃`. The η-anchor uppers give `λ₄^{arith} ≥ ≈ +1.0897` and the
archimedean lower (`arch(4) = 1 − 2(γ+log4π) + (9/2)ζ(2) − (7/2)ζ(3) + (15/16)ζ(4)`) gives
`λ₄^{∞} ≥ ≈ −1.0663`, so `λ₄ ≥ ≈ +0.023` (true `λ₄ ≈ 0.370`).  This is `n = 4` ONLY — NOT the crux
(the uniform `∀ n` = RH); `liPositivityHolds` stays `none`, RH open.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.GammaTwoUpper
import Core.F1.Analysis.LambdaThreePos
import Core.F1.Analysis.LambdaFour

namespace UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

-- ===========================================================================
-- (P) The `η₃` product UPPER bounds.
-- ===========================================================================

/-- `ofQ q ≤ 0` when `q.num ≤ 0`. -/
theorem ofQ_nonpos {q : Q} (hd : 0 < q.den) (hn : q.num ≤ 0) : Rle (ofQ q hd) zero := by
  refine Rle_of_Rnonneg_Rsub (Rnonneg_congr ?_
    (Rnonneg_ofQ (c := neg q) hd (by show (0 : Int) ≤ -q.num; omega)))
  exact Req_symm (Req_trans (Req_trans (Radd_comm zero (Rneg (ofQ q hd))) (Radd_zero _))
    (Rneg_ofQ q hd))

/-- `b·c ≤ a·c` when `a ≤ b` and `c ≤ 0` (antitone in mult by a nonpositive factor). -/
theorem Rmul_le_Rmul_right_nonpos {a b c : Real} (hab : Rle a b) (hc : Rle c zero) :
    Rle (Rmul b c) (Rmul a c) := by
  have hcn : Rnonneg (Rneg c) :=
    Rnonneg_congr (Req_trans (Radd_comm zero (Rneg c)) (Radd_zero (Rneg c)))
      (Rnonneg_Rsub_of_Rle hc)
  have h := Rmul_le_Rmul_right hcn hab
  have h' : Rle (Rneg (Rmul a c)) (Rneg (Rmul b c)) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_neg_right a c)))
      (Rle_trans h (Rle_of_Req (Rmul_neg_right b c)))
  exact Rle_trans (Rle_of_Req (Req_symm (Rneg_neg (Rmul b c))))
    (Rle_trans (Rle_Rneg h') (Rle_of_Req (Rneg_neg (Rmul a c))))

/-- **`γ⁴ ≤ (578/1000)⁴`** — `γ⁴ = ((γ·γ)·γ)·γ`, four `≤ γ_hi` steps. -/
theorem Rgamma_pow4_le :
    Rle (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma_h)
      (ofQ (mul (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q)) (⟨578, 1000⟩ : Q)) (⟨578, 1000⟩ : Q))
        (by decide)) := by
  have hcube : Rle (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h)
      (ofQ (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q)) (⟨578, 1000⟩ : Q)) (by decide)) := by
    refine Rle_trans (Rmul_le_Rmul_right Rgamma_h_nonneg Rgamma_sq_le) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_h_le_578) ?_
    exact Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide))
  refine Rle_trans (Rmul_le_Rmul_right Rgamma_h_nonneg hcube) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_h_le_578) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide))

/-- **`γ²·γ₁ ≤ (577/1000)²·(−677/10000)`** — sharp upper (`γ² ≥ γ_lo²`, `γ₁ ≤ 0`, `γ₁ ≤ γ₁_hi`). -/
theorem Rgamma_sq_gamma1_le :
    Rle (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma1)
      (ofQ (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨-677, 10000⟩ : Q)) (by decide)) := by
  have hg1nonpos : Rle Rgamma1 zero :=
    Rle_trans Rgamma1_le_neg0677 (ofQ_nonpos (by decide) (by decide))
  -- γ²·γ₁ ≤ γ_lo²·γ₁
  refine Rle_trans (Rmul_le_Rmul_right_nonpos Rgamma_sq_ge hg1nonpos) ?_
  -- γ_lo²·γ₁ ≤ γ_lo²·γ₁_hi
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma1_le_neg0677) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide))

/-- **`γ₁² ≤ (762/10000)²`** — `|γ₁| ≤ 762/10000` (`Rmul_le_mul_of_abs`). -/
theorem Rgamma1_sq_le :
    Rle (Rmul Rgamma1 Rgamma1) (ofQ (mul (⟨762, 10000⟩ : Q) (⟨762, 10000⟩ : Q)) (by decide)) := by
  have hlo : Rle (Rneg (ofQ (⟨762, 10000⟩ : Q) (by decide))) Rgamma1 :=
    Rle_trans (Rle_of_Req (Rneg_ofQ (⟨762, 10000⟩ : Q) (by decide))) Rgamma1_ge_neg0762
  have hhi : Rle Rgamma1 (ofQ (⟨762, 10000⟩ : Q) (by decide)) :=
    Rle_trans Rgamma1_le_neg0677 (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  exact Rle_trans (Rmul_le_mul_of_abs hlo hhi hlo hhi)
    (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))

/-- **`γ·γ₂ ≤ (578/1000)·(1/40)`** — `γ₂ ≤ 1/40`, `γ ≤ γ_hi`, both `≥ 0`. -/
theorem Rgamma_gamma2_le :
    Rle (Rmul Rgamma_h Rgamma2) (ofQ (mul (⟨578, 1000⟩ : Q) (⟨1, 40⟩ : Q)) (by decide)) := by
  refine Rle_trans (Rmul_le_Rmul_left Rgamma_h_nonneg Rgamma2_le) ?_
  refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_ofQ (by decide) (by decide)) Rgamma_h_le_578) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide))

-- ===========================================================================
-- (E) η-anchor uppers (η₁ tightened to γ₁≤−0.0677; η₃ new) and the `nsmulR` collapses.
-- ===========================================================================

/-- **`η₁ = γ² + 2γ₁ ≤ 198685/10⁶`** — tightened with `γ₁ ≤ −0.0677` (vs `reta1_le`'s `−0.055`). -/
theorem reta1_le4 : Rle Reta1 (ofQ (⟨198685, 1000000⟩ : Q) (by decide)) := by
  unfold Reta1
  have hlin : Rle (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) Rgamma1)
      (ofQ (mul (⟨2, 1⟩ : Q) (⟨-677, 10000⟩ : Q)) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma1_le_neg0677)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
  refine Rle_trans (Radd_le_add Rgamma_sq_le hlin) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (by decide) (by decide))) ?_
  exact Rle_ofQ_ofQ (by decide) (by decide) (by decide)

set_option maxRecDepth 8192 in
/-- **`η₃ ≤ 145303/10⁶`** — `η₃ = γ⁴ + 4γ²γ₁ + 2γ₁² + 2γγ₂ + (2/3)γ₃` bounded by the five product
    uppers (`Rgamma_pow4_le`, `Rgamma_sq_gamma1_le`, `Rgamma1_sq_le`, `Rgamma_gamma2_le`, `Rgamma3_le`),
    each rounded to a `10⁶` literal so the sum keeps denominator `10⁶` (`Radd_ofQ_same`). -/
theorem reta3_le : Rle Reta3 (ofQ (⟨145303, 1000000⟩ : Q) (by decide)) := by
  unfold Reta3
  have hT1 : Rle (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma_h)
      (ofQ (⟨111613, 1000000⟩ : Q) (by decide)) :=
    Rle_trans Rgamma_pow4_le (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  have hT2 : Rle (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma1))
      (ofQ (⟨-90157, 1000000⟩ : Q) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_sq_gamma1_le)
      (Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
        (Rle_ofQ_ofQ (by decide) (by decide) (by decide)))
  have hT3 : Rle (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul Rgamma1 Rgamma1))
      (ofQ (⟨11613, 1000000⟩ : Q) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma1_sq_le)
      (Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
        (Rle_ofQ_ofQ (by decide) (by decide) (by decide)))
  have hT4 : Rle (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma2))
      (ofQ (⟨28900, 1000000⟩ : Q) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_gamma2_le)
      (Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
        (Rle_ofQ_ofQ (by decide) (by decide) (by decide)))
  have hT5 : Rle (Rmul (ofQ (⟨2, 3⟩ : Q) (by decide)) Rgamma3)
      (ofQ (⟨83334, 1000000⟩ : Q) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma3_le)
      (Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
        (Rle_ofQ_ofQ (by decide) (by decide) (by decide)))
  refine Rle_trans (Radd_le_add (Radd_le_add (Radd_le_add (Radd_le_add hT1 hT2) hT3) hT4) hT5) ?_
  have hD : 0 < (1000000 : Nat) := by decide
  refine Rle_of_Req (Req_trans (Radd_congr (Radd_congr (Radd_congr
    (Radd_ofQ_same 111613 (-90157) 1000000 hD) (Req_refl _)) (Req_refl _)) (Req_refl _)) ?_)
  refine Req_trans (Radd_congr (Radd_congr (Radd_ofQ_same 21456 11613 1000000 hD)
    (Req_refl _)) (Req_refl _)) ?_
  refine Req_trans (Radd_congr (Radd_ofQ_same 33069 28900 1000000 hD) (Req_refl _)) ?_
  exact Radd_ofQ_same 61969 83334 1000000 hD

/-- `nsmulR 4 X ≤ 4·xu`. -/
theorem nsmulR4_le {X : Real} {xu : Q} (hxu : 0 < xu.den) (h : Rle X (ofQ xu hxu)) :
    Rle (nsmulR 4 X) (ofQ (mul (⟨4, 1⟩ : Q) xu) (Qmul_den_pos (by decide) hxu)) := by
  show Rle (Radd (Radd (Radd X X) X) X) _
  refine Rle_trans (Radd_le_add (Radd_le_add (Radd_le_add h h) h) h) (Rle_of_Req ?_)
  refine Req_of_seq_Qeq (fun n => ?_)
  show Qeq (add (add (add xu xu) xu) xu) (mul (⟨4, 1⟩ : Q) xu)
  simp only [Qeq, add, mul]; push_cast; ring_uor

/-- `nsmulR 6 X ≤ 6·xu`. -/
theorem nsmulR6_le {X : Real} {xu : Q} (hxu : 0 < xu.den) (h : Rle X (ofQ xu hxu)) :
    Rle (nsmulR 6 X) (ofQ (mul (⟨6, 1⟩ : Q) xu) (Qmul_den_pos (by decide) hxu)) := by
  show Rle (Radd (Radd (Radd (Radd (Radd X X) X) X) X) X) _
  refine Rle_trans (Radd_le_add (Radd_le_add (Radd_le_add (Radd_le_add (Radd_le_add h h) h) h) h) h)
    (Rle_of_Req ?_)
  refine Req_of_seq_Qeq (fun n => ?_)
  show Qeq (add (add (add (add (add xu xu) xu) xu) xu) xu) (mul (⟨6, 1⟩ : Q) xu)
  simp only [Qeq, add, mul]; push_cast; ring_uor

-- ===========================================================================
-- (A) The archimedean lower bound `genuineArchSeq 4 ≥ archLoQ4` (`arch(4) ≈ −1.0663`).
--     arch(4) = 1 − 2(γ+log4π) + (9/2)ζ(2) − (7/2)ζ(3) + (15/16)ζ(4).
-- ===========================================================================

theorem m4xu_den_pos : 0 < (mul (⟨4, 1⟩ : Q) xuQ).den := Qmul_den_pos (by decide) xuQ_den_pos
theorem half_m4xu_den_pos : 0 < (mul (⟨1, 2⟩ : Q) (mul (⟨4, 1⟩ : Q) xuQ)).den :=
  Qmul_den_pos (by decide) m4xu_den_pos
theorem ilq4_den_pos : 0 < (Qsub (⟨1, 1⟩ : Q) (mul (⟨1, 2⟩ : Q) (mul (⟨4, 1⟩ : Q) xuQ))).den :=
  Qsub_den_pos (by decide) half_m4xu_den_pos
theorem iilq4_den_pos : 0 < (add (add (add (⟨0, 1⟩ : Q) (mul (⟨18, 4⟩ : Q) (⟨1644, 1000⟩ : Q)))
    (mul (⟨-28, 8⟩ : Q) (⟨1217, 1000⟩ : Q))) (mul (⟨15, 16⟩ : Q) (⟨1082, 1000⟩ : Q))).den :=
  add_den_pos (add_den_pos (add_den_pos (by decide) (Qmul_den_pos (by decide) (by decide)))
    (Qmul_den_pos (by decide) (by decide))) (Qmul_den_pos (by decide) (by decide))

/-- The certified rational lower bound on `genuineArchSeq 4`. -/
def archLoQ4 : Q :=
  add (Qsub (⟨1, 1⟩ : Q) (mul (⟨1, 2⟩ : Q) (mul (⟨4, 1⟩ : Q) xuQ)))
    (add (add (add (⟨0, 1⟩ : Q) (mul (⟨18, 4⟩ : Q) (⟨1644, 1000⟩ : Q)))
        (mul (⟨-28, 8⟩ : Q) (⟨1217, 1000⟩ : Q))) (mul (⟨15, 16⟩ : Q) (⟨1082, 1000⟩ : Q)))

theorem archLoQ4_den_pos : 0 < archLoQ4.den := add_den_pos ilq4_den_pos iilq4_den_pos

set_option maxRecDepth 8192 in
set_option maxHeartbeats 4000000 in
/-- Archimedean part (I): `one − 2(γ + log 4π) ≥ 1 − 2·xuQ`. -/
theorem archI4_ge :
    Rle (ofQ (Qsub (⟨1, 1⟩ : Q) (mul (⟨1, 2⟩ : Q) (mul (⟨4, 1⟩ : Q) xuQ))) ilq4_den_pos)
      (Rsub one (Rhalf (nsmulR 4 (Radd Rgamma_h Rlog4pic)))) := by
  have hX : Rle (Radd Rgamma_h Rlog4pic) (ofQ xuQ xuQ_den_pos) :=
    Rle_trans (Radd_le_add Rgamma_h_le_578 Rlog4pic_le)
      (Rle_of_Req (Radd_ofQ_ofQ (a := (⟨578, 1000⟩ : Q)) (b := (⟨25316, 10000⟩ : Q))
        (by decide) (by decide)))
  have hHalf : Rle (Rhalf (nsmulR 4 (Radd Rgamma_h Rlog4pic)))
      (ofQ (mul (⟨1, 2⟩ : Q) (mul (⟨4, 1⟩ : Q) xuQ)) half_m4xu_den_pos) :=
    Rle_trans (Rhalf_le_Rhalf (nsmulR4_le xuQ_den_pos hX))
      (Rle_of_Req (Rhalf_ofQ _ m4xu_den_pos))
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_ofQ_ofQ (by decide) half_m4xu_den_pos))) ?_
  exact Rsub_le_sub (Rle_refl _) hHalf

set_option maxRecDepth 8192 in
/-- `(9/2)·ζ(2) ≤ genArchTerm 4 2`. -/
theorem archTerm4_2_ge :
    Rle (ofQ (mul (⟨18, 4⟩ : Q) (⟨1644, 1000⟩ : Q)) (by decide)) (genArchTerm 4 2 (by decide)) := by
  unfold genArchTerm
  exact Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
    (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta2_lower_tight)

set_option maxRecDepth 8192 in
/-- `(−7/2)·ζ(3) ≤ genArchTerm 4 3` (negative coeff `−28/8`, via the `Rneg` trick). -/
theorem archTerm4_3_ge :
    Rle (ofQ (mul (⟨-28, 8⟩ : Q) (⟨1217, 1000⟩ : Q)) (by decide)) (genArchTerm 4 3 (by decide)) := by
  unfold genArchTerm
  have hup : Rle (Rmul (ofQ (⟨28, 8⟩ : Q) (by decide)) (zeta 3 (by decide)))
      (ofQ (mul (⟨28, 8⟩ : Q) (⟨1217, 1000⟩ : Q)) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta3_upper)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
  have heq2 : Req (Rneg (Rmul (ofQ (⟨28, 8⟩ : Q) (by decide)) (zeta 3 (by decide))))
      (Rmul (ofQ (⟨-28, 8⟩ : Q) (by decide)) (zeta 3 (by decide))) :=
    Req_trans (Req_symm (Rmul_neg_left (ofQ (⟨28, 8⟩ : Q) (by decide)) (zeta 3 (by decide))))
      (Rmul_congr (Rneg_ofQ (⟨28, 8⟩ : Q) (by decide)) (Req_refl _))
  have heq1 : Req (ofQ (mul (⟨-28, 8⟩ : Q) (⟨1217, 1000⟩ : Q)) (by decide))
      (Rneg (ofQ (mul (⟨28, 8⟩ : Q) (⟨1217, 1000⟩ : Q)) (by decide))) :=
    Req_trans (Req_of_seq_Qeq (fun n => by
        show Qeq (mul (⟨-28, 8⟩ : Q) (⟨1217, 1000⟩ : Q)) (neg (mul (⟨28, 8⟩ : Q) (⟨1217, 1000⟩ : Q)));
        decide))
      (Req_symm (Rneg_ofQ (mul (⟨28, 8⟩ : Q) (⟨1217, 1000⟩ : Q)) (by decide)))
  exact Rle_trans (Rle_of_Req heq1) (Rle_trans (Rle_Rneg hup) (Rle_of_Req heq2))

set_option maxRecDepth 8192 in
/-- `(15/16)·ζ(4) ≤ genArchTerm 4 4`. -/
theorem archTerm4_4_ge :
    Rle (ofQ (mul (⟨15, 16⟩ : Q) (⟨1082, 1000⟩ : Q)) (by decide)) (genArchTerm 4 4 (by decide)) := by
  unfold genArchTerm
  exact Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
    (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta4_lower)

set_option maxRecDepth 8192 in
/-- Archimedean part (II): `genArchTail 4 4 ≥ (9/2)ζ(2) − (7/2)ζ(3) + (15/16)ζ(4)`. -/
theorem archII4_ge :
    Rle (ofQ (add (add (add (⟨0, 1⟩ : Q) (mul (⟨18, 4⟩ : Q) (⟨1644, 1000⟩ : Q)))
      (mul (⟨-28, 8⟩ : Q) (⟨1217, 1000⟩ : Q))) (mul (⟨15, 16⟩ : Q) (⟨1082, 1000⟩ : Q))) iilq4_den_pos)
      (genArchTail 4 4) := by
  show Rle _ (Radd (Radd (Radd zero (genArchTerm 4 2 (by decide))) (genArchTerm 4 3 (by decide)))
    (genArchTerm 4 4 (by decide)))
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ (by decide) (by decide)))) ?_
  refine Radd_le_add ?_ archTerm4_4_ge
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ (by decide) (by decide)))) ?_
  refine Radd_le_add ?_ archTerm4_3_ge
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ (by decide) (by decide)))) ?_
  exact Radd_le_add (Rle_of_Req (Req_refl _)) archTerm4_2_ge

set_option maxRecDepth 8192 in
set_option maxHeartbeats 4000000 in
/-- **`genuineArchSeq 4 ≥ archLoQ4`** — lower bound on the archimedean side. -/
theorem genuineArchSeq4_ge : Rle (ofQ archLoQ4 archLoQ4_den_pos) (genuineArchSeq 4) := by
  unfold genuineArchSeq
  refine Rle_trans (Rle_of_Req ?_) (Radd_le_add archI4_ge archII4_ge)
  show Req (ofQ archLoQ4 _) _
  exact Req_symm (Radd_ofQ_ofQ ilq4_den_pos iilq4_den_pos)

set_option maxRecDepth 8192 in
/-- **`genuineArchSeq 4 ≥ −1066325/10⁶`** — `archLoQ4` rounded to `10⁶`. -/
theorem archLoR4_le : Rle (ofQ (⟨-1066325, 1000000⟩ : Q) (by decide)) (genuineArchSeq 4) :=
  Rle_trans (Rle_ofQ_ofQ (by decide) archLoQ4_den_pos (by decide)) genuineArchSeq4_ge

-- ===========================================================================
-- (L) The arithmetic side `Rlambda4_arith ≥ 1090459/10⁶` and `Pos Rlambda4`.
-- ===========================================================================

/-- Collapse five same-denominator `ofQ` literals and compare in ONE `decide` — the intermediate
    sums stay SYMBOLIC `Int` variables (no kernel reduction of large negatives), so the only
    arithmetic is the final `Qle` `decide`. (The `Radd_ofQ_same` defeq chain on concrete negative
    literals blows up `Int.subNatNat`/`Int.neg`; this routes around it.) -/
theorem Radd5_ofQ_le (a b c d e t : Int) (D : Nat) (hD : 0 < D)
    (h : Qle (⟨a + b + c + d + e, D⟩ : Q) (⟨t, D⟩ : Q)) :
    Rle (Radd (Radd (Radd (Radd (ofQ (⟨a, D⟩ : Q) hD) (ofQ (⟨b, D⟩ : Q) hD)) (ofQ (⟨c, D⟩ : Q) hD))
        (ofQ (⟨d, D⟩ : Q) hD)) (ofQ (⟨e, D⟩ : Q) hD)) (ofQ (⟨t, D⟩ : Q) hD) := by
  refine Rle_trans (Rle_of_Req (Req_trans (Radd_congr (Radd_congr (Radd_congr
      (Radd_ofQ_same a b D hD) (Req_refl _)) (Req_refl _)) (Req_refl _))
      (Req_trans (Radd_congr (Radd_congr (Radd_ofQ_same (a + b) c D hD) (Req_refl _)) (Req_refl _))
      (Req_trans (Radd_congr (Radd_ofQ_same (a + b + c) d D hD) (Req_refl _))
      (Radd_ofQ_same (a + b + c + d) e D hD))))) ?_
  exact Rle_ofQ_ofQ hD hD h

set_option maxRecDepth 8192 in
set_option maxHeartbeats 4000000 in
/-- The inner sum `S = 4η₀ + 6η₁ + 4η₂ + η₃ ≤ −1090459/10⁶` (`Rlambda4_arith = −S`), with the η-anchors
    in explicit `nsmulR` form so neither `Rlambda4_arith`'s `choose` nor `Reta3` is whnf-normalised. -/
theorem Rlambda4_S_le :
    Rle (Radd (Radd (Radd (Radd zero (nsmulR 4 Reta0)) (nsmulR 6 Reta1)) (nsmulR 4 Reta2))
        (nsmulR 1 Reta3)) (ofQ (⟨-1090459, 1000000⟩ : Q) (by decide)) := by
  have h0 : Rle (nsmulR 4 Reta0) (ofQ (⟨-2308000, 1000000⟩ : Q) (by decide)) :=
    Rle_trans (nsmulR4_le (by decide) reta0_le) (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  have h1 : Rle (nsmulR 6 Reta1) (ofQ (⟨1192110, 1000000⟩ : Q) (by decide)) :=
    Rle_trans (nsmulR6_le (by decide) reta1_le4) (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  have h2 : Rle (nsmulR 4 Reta2) (ofQ (⟨-119872, 1000000⟩ : Q) (by decide)) :=
    Rle_trans (nsmulR4_le (by decide) reta2_le) (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  have h3 : Rle (nsmulR 1 Reta3) (ofQ (⟨145303, 1000000⟩ : Q) (by decide)) := by
    show Rle Reta3 _; exact reta3_le
  have hz : Rle zero (ofQ (⟨0, 1000000⟩ : Q) (by decide)) :=
    Rle_zero_of_Rnonneg (Rnonneg_ofQ (by decide) (by decide))
  refine Rle_trans (Radd_le_add (Radd_le_add (Radd_le_add (Radd_le_add hz h0) h1) h2) h3) ?_
  exact Radd5_ofQ_le 0 (-2308000) 1192110 (-119872) 145303 (-1090459) 1000000 (by decide) (by decide)

set_option maxRecDepth 8192 in
set_option maxHeartbeats 4000000 in
/-- **`Rlambda4_arith ≥ 1090459/10⁶`** (`= −(4η₀ + 6η₁ + 4η₂ + η₃)`, true `≈ 1.39`), from the
    η-anchor uppers `reta0_le`, `reta1_le4`, `reta2_le`, `reta3_le` via `Rlambda4_S_le`. -/
theorem Rlambda4_arith_ge_r :
    Rle (ofQ (neg (⟨-1090459, 1000000⟩ : Q)) (by decide)) Rlambda4_arith := by
  unfold Rlambda4_arith
  refine Rle_trans (Rle_of_Req (Req_symm (Rneg_ofQ (⟨-1090459, 1000000⟩ : Q) (by decide))))
    (Rle_Rneg Rlambda4_S_le)

set_option maxRecDepth 8192 in
/-- **`Pos Rlambda4`** — the fourth Li coefficient is positive, certified `λ₄ ≥ 24134/10⁶ ≈ +0.0241`
    (true `λ₄ ≈ 0.370`), assembled from `Rlambda4_arith ≥ 1.0905` and `genuineArchSeq 4 ≥ −1.0663`,
    i.e. from `γ ∈ [0.577,0.578]`, `γ₁ ∈ [−0.0762,−0.0677]`, `γ₂ ∈ [−0.02, 1/40]`, `γ₃ ≤ 1/8`,
    `ζ(2) ≥ 1.644`, `ζ(3) ≤ 1.217`, `ζ(4) ≥ 1.082`, `log 4π ≤ 2.5316`.

    Conquers the `n = 4` prime–archimedean coupling coefficient — the first `Pos λₙ` to carry `γ₃`.
    This is `n = 4` ONLY — NOT the crux (the uniform `∀ n` = RH); `liPositivityHolds` stays `none`,
    RH open. -/
theorem Rlambda4_pos : Pos Rlambda4 := by
  have hμ : Rle (ofQ (add (neg (⟨-1090459, 1000000⟩ : Q)) (⟨-1066325, 1000000⟩ : Q)) (by decide))
      Rlambda4 :=
    Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ (by decide) (by decide))))
      (Radd_le_add Rlambda4_arith_ge_r archLoR4_le)
  exact Pos_of_Rle_ofQ (by decide) (by decide) hμ

end UOR.Bridge.F1Square.Analysis
