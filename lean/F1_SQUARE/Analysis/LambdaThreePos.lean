/-
F1 square — v0.22.0 crux frontier: **`Pos Rlambda3`** (the `n = 3` coupling coefficient), the capstone
of the constant-precision work. With all six constants now two-sided bracketed —
`γ ∈ [0.577, 0.578]` (`Rgamma_h_ge_577`/`Rgamma_h_le_578`), `γ₁ ∈ [−0.0762, −0.055]`
(`Rgamma1_ge_neg0762`/`Rgamma1_le_neg055`), `γ₂ ≥ −0.02` (`Rgamma2_ge_neg002`), `ζ(2) ≥ 1.644`
(`zeta2_lower_tight`), `ζ(3) ≤ 1.217` (`zeta3_upper`), `log 4π ≤ 2.5316` — the closed form

  `λ₃ = 1 + (3/2)γ − 3γ² − 6γ₁ + γ³ + 3γγ₁ + (3/2)γ₂ − (3/2)log 4π + (9/4)ζ(2) − (7/8)ζ(3)`

(`LambdaThree.lean`: `Rlambda3 = Rlambda3_arith + genuineArchSeq 3`, with `genuineArchSeq 3 =
1 − (3/2)(γ + log 4π) + (9/4)ζ(2) − (7/8)ζ(3)`) has a certified rational lower bound `≈ +0.058 > 0`.

THIS CONQUERS `n = 3` of the prime–archimedean coupling (`coupling_n3_iff_pos_lambda3`). It does NOT
close the crux, which is the uniform `∀ n` (= RH); the crux fields stay `none`.

THIS FILE proves `Pos Rlambda3` (`Rlambda3_pos`): the product/parabola bounds (`γ²`,`γ³`,`γγ₁`), the
archimedean lower `genuineArchSeq3_ge`, the rounded η-anchor bounds, and the assembly.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.LambdaThree
import F1Square.Analysis.GammaZeroBracket
import F1Square.Analysis.GammaOneBracket
import F1Square.Analysis.GammaTwoBracket
import F1Square.Analysis.ZetaTwo
import F1Square.Analysis.LambdaTwo

namespace UOR.Bridge.F1Square.Analysis

/-- `γ ≥ 0` (from `γ ≥ 0.577`). -/
theorem Rgamma_h_nonneg : Rnonneg Rgamma_h :=
  Rnonneg_of_Rle_zero (Rle_trans (Rle_zero_of_Rnonneg
    (Rnonneg_ofQ (by decide) (by decide))) Rgamma_h_ge_577)

/-- **`γ² ≤ (578/1000)²`** — upper bound on `γ²`. -/
theorem Rgamma_sq_le : Rle (Rmul Rgamma_h Rgamma_h)
    (ofQ (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q)) (by decide)) :=
  Rle_trans (Rmul_le_Rmul_right Rgamma_h_nonneg Rgamma_h_le_578)
    (Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_h_le_578)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide))))

/-- **`(577/1000)² ≤ γ²`** — lower bound on `γ²`. -/
theorem Rgamma_sq_ge : Rle (ofQ (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (by decide))
    (Rmul Rgamma_h Rgamma_h) :=
  Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
    (Rle_trans (Rmul_le_Rmul_right (Rnonneg_ofQ (by decide) (by decide)) Rgamma_h_ge_577)
      (Rmul_le_Rmul_left Rgamma_h_nonneg Rgamma_h_ge_577))

/-- **`(577/1000)³ ≤ γ³`** — lower bound on `γ³`. -/
theorem Rgamma_cube_ge :
    Rle (ofQ (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q)) (by decide))
      (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) := by
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide)))) ?_
  refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_ofQ (by decide) (by decide)) Rgamma_sq_ge) ?_
  exact Rmul_le_Rmul_left (Rnonneg_Rmul Rgamma_h_nonneg Rgamma_h_nonneg) Rgamma_h_ge_577

/-- **`(578/1000)·(−762/10000) ≤ γ·γ₁`** — lower bound on `γ·γ₁` (`γ > 0`, `γ₁ < 0`), via the
    two-sided product keystone `Rneg_mul_le_of_abs` with `|γ| ≤ 578/1000`, `|γ₁| ≤ 762/10000`. -/
theorem Rgamma_gamma1_ge :
    Rle (ofQ (mul (⟨578, 1000⟩ : Q) (⟨-762, 10000⟩ : Q)) (by decide)) (Rmul Rgamma_h Rgamma1) := by
  have hx1 : Rle (Rneg (ofQ (⟨578, 1000⟩ : Q) (by decide))) Rgamma_h :=
    Rle_trans (Rle_trans (Rle_of_Req (Rneg_ofQ (⟨578, 1000⟩ : Q) (by decide)))
      (Rle_ofQ_ofQ (by decide) (by decide) (by decide))) Rgamma_h_ge_577
  have hy1 : Rle (Rneg (ofQ (⟨762, 10000⟩ : Q) (by decide))) Rgamma1 :=
    Rle_trans (Rle_of_Req (Rneg_ofQ (⟨762, 10000⟩ : Q) (by decide))) Rgamma1_ge_neg0762
  have hy2 : Rle Rgamma1 (ofQ (⟨762, 10000⟩ : Q) (by decide)) :=
    Rle_trans Rgamma1_le_neg055 (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  have hmain : Rle (Rneg (Rmul (ofQ (⟨578, 1000⟩ : Q) (by decide)) (ofQ (⟨762, 10000⟩ : Q) (by decide))))
      (Rmul Rgamma_h Rgamma1) :=
    Rneg_mul_le_of_abs hx1 Rgamma_h_le_578 hy1 hy2
  refine Rle_trans (Rle_of_Req ?_) hmain
  have hq : Req (ofQ (mul (⟨578, 1000⟩ : Q) (⟨-762, 10000⟩ : Q)) (by decide))
      (ofQ (neg (mul (⟨578, 1000⟩ : Q) (⟨762, 10000⟩ : Q))) (by decide)) :=
    Req_of_seq_Qeq (fun n => by
      show Qeq (mul (⟨578, 1000⟩ : Q) (⟨-762, 10000⟩ : Q)) (neg (mul (⟨578, 1000⟩ : Q) ⟨762, 10000⟩));
      decide)
  exact Req_trans hq (Req_trans
    (Req_symm (Rneg_ofQ (mul (⟨578, 1000⟩ : Q) (⟨762, 10000⟩ : Q)) (by decide)))
    (Rneg_congr (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide)))))

/-- **`log 4π ≤ 25316/10000`** (`= 2.5316`), reconstructed from `Rlog2c_le`/`Rlogπc_le` (cf. `λ₂`). -/
theorem Rlog4pic_le : Rle Rlog4pic (ofQ (⟨25316, 10000⟩ : Q) (by decide)) := by
  have h2d : 0 < (mul (⟨2, 1⟩ : Q) (add (artSum ⟨1, 3⟩ 8) ⟨1, 8 * npow 3 (2 * 8 + 1)⟩)).den :=
    Qmul_den_pos (by decide) (add_den_pos (artSum_den_pos (by decide) 8)
      (Nat.mul_pos (by decide) (npow_pos (by decide) _)))
  have hpd : 0 < (mul (⟨2, 1⟩ : Q) (add (artSum ⟨15, 29⟩ 6) ⟨npow 15 15, npow 29 13 * 616⟩)).den :=
    Qmul_den_pos (by decide) (add_den_pos (artSum_den_pos (by decide) 6) (by decide))
  unfold Rlog4pic
  refine Rle_trans (Radd_le_add (Rle_trans (Radd_le_add Rlog2c_le Rlog2c_le)
      (Radd_Rle_ofQ_add h2d h2d)) Rlogπc_le) ?_
  refine Rle_trans (Radd_Rle_ofQ_add (add_den_pos h2d h2d) hpd) ?_
  exact Rle_ofQ_ofQ (add_den_pos (add_den_pos h2d h2d) hpd) (by decide) (by decide)

/-- `γ_hi + log4π_hi = 578/1000 + 25316/10000` (archimedean linear upper bound). -/
def xuQ : Q := add (⟨578, 1000⟩ : Q) (⟨25316, 10000⟩ : Q)

theorem xuQ_den_pos : 0 < xuQ.den := add_den_pos (by decide) (by decide)

/-- **Symbolic `nsmulR 3` collapse**: `X ≤ ofQ xu ⟹ 3·X ≤ ofQ (3·xu)`, proven with `ring_uor`
    on `xu` as a *variable* — so the denominator stays `xu.den` instead of cubing to `xu.den³`. -/
theorem nsmulR3_le_mul3 {X : Real} {xu : Q} (hxu : 0 < xu.den) (h : Rle X (ofQ xu hxu)) :
    Rle (nsmulR 3 X) (ofQ (mul (⟨3, 1⟩ : Q) xu) (Qmul_den_pos (by decide) hxu)) := by
  show Rle (Radd (Radd X X) X) _
  refine Rle_trans (Radd_le_add (Radd_le_add h h) h) (Rle_of_Req ?_)
  refine Req_of_seq_Qeq (fun n => ?_)
  show Qeq (add (add xu xu) xu) (mul (⟨3, 1⟩ : Q) xu)
  simp only [Qeq, add, mul]; push_cast; ring_uor

/-- The certified rational lower bound on the archimedean side `genuineArchSeq 3`. -/
def archLoQ : Q :=
  add (Qsub (⟨1, 1⟩ : Q) (mul (⟨1, 2⟩ : Q) (mul (⟨3, 1⟩ : Q) xuQ)))
    (add (add (⟨0, 1⟩ : Q) (mul (⟨9, 4⟩ : Q) (⟨1644, 1000⟩ : Q))) (mul (⟨-7, 8⟩ : Q) (⟨1217, 1000⟩ : Q)))

theorem m3xu_den_pos : 0 < (mul (⟨3, 1⟩ : Q) xuQ).den := Qmul_den_pos (by decide) xuQ_den_pos

theorem half_m3xu_den_pos : 0 < (mul (⟨1, 2⟩ : Q) (mul (⟨3, 1⟩ : Q) xuQ)).den :=
  Qmul_den_pos (by decide) m3xu_den_pos

theorem ilq_den_pos : 0 < (Qsub (⟨1, 1⟩ : Q) (mul (⟨1, 2⟩ : Q) (mul (⟨3, 1⟩ : Q) xuQ))).den :=
  Qsub_den_pos (by decide) half_m3xu_den_pos

theorem iilq_den_pos : 0 < (add (add (⟨0, 1⟩ : Q) (mul (⟨9, 4⟩ : Q) (⟨1644, 1000⟩ : Q)))
    (mul (⟨-7, 8⟩ : Q) (⟨1217, 1000⟩ : Q))).den :=
  add_den_pos (add_den_pos (by decide) (Qmul_den_pos (by decide) (by decide)))
    (Qmul_den_pos (by decide) (by decide))

theorem archLoQ_den_pos : 0 < archLoQ.den := add_den_pos ilq_den_pos iilq_den_pos

set_option maxRecDepth 8192 in
set_option maxHeartbeats 4000000 in
/-- Archimedean part (I): `one − (3/2)(γ + log 4π) ≥ 1 − (3/2)·xuQ`. -/
theorem archI_ge :
    Rle (ofQ (Qsub (⟨1, 1⟩ : Q) (mul (⟨1, 2⟩ : Q) (mul (⟨3, 1⟩ : Q) xuQ))) ilq_den_pos)
      (Rsub one (Rhalf (nsmulR 3 (Radd Rgamma_h Rlog4pic)))) := by
  have hX : Rle (Radd Rgamma_h Rlog4pic) (ofQ xuQ xuQ_den_pos) :=
    Rle_trans (Radd_le_add Rgamma_h_le_578 Rlog4pic_le)
      (Rle_of_Req (Radd_ofQ_ofQ (a := (⟨578, 1000⟩ : Q)) (b := (⟨25316, 10000⟩ : Q))
        (by decide) (by decide)))
  have hHalf : Rle (Rhalf (nsmulR 3 (Radd Rgamma_h Rlog4pic)))
      (ofQ (mul (⟨1, 2⟩ : Q) (mul (⟨3, 1⟩ : Q) xuQ)) half_m3xu_den_pos) :=
    Rle_trans (Rhalf_le_Rhalf (nsmulR3_le_mul3 xuQ_den_pos hX))
      (Rle_of_Req (Rhalf_ofQ _ m3xu_den_pos))
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_ofQ_ofQ (by decide) half_m3xu_den_pos))) ?_
  exact Rsub_le_sub (Rle_refl _) hHalf

set_option maxRecDepth 8192 in
/-- `(9/4)·ζ(2) ≤ genArchTerm 3 2` — via `unfold genArchTerm` (NOT `show`), so Lean keeps
    `genArchTerm`'s own `zeta 2` term and never reconciles two distinct `zeta` proof terms
    (which forces the heavy `zeta` to unfold). -/
theorem archTerm2_ge :
    Rle (ofQ (mul (⟨9, 4⟩ : Q) (⟨1644, 1000⟩ : Q)) (by decide)) (genArchTerm 3 2 (by decide)) := by
  unfold genArchTerm
  exact Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
    (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta2_lower_tight)

set_option maxRecDepth 8192 in
/-- `(−7/8)·ζ(3) ≤ genArchTerm 3 3` — likewise via `unfold`, keeping `genArchTerm`'s own `zeta 3`. -/
theorem archTerm3_ge :
    Rle (ofQ (mul (⟨-7, 8⟩ : Q) (⟨1217, 1000⟩ : Q)) (by decide)) (genArchTerm 3 3 (by decide)) := by
  unfold genArchTerm
  -- `(7/8)·ζ(3) ≤ (7/8)·(1217/1000)`
  have hup : Rle (Rmul (ofQ (⟨7, 8⟩ : Q) (by decide)) (zeta 3 (by decide)))
      (ofQ (mul (⟨7, 8⟩ : Q) (⟨1217, 1000⟩ : Q)) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta3_upper)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
  -- `−((7/8)·ζ(3)) = (−7/8)·ζ(3)`
  have heq2 : Req (Rneg (Rmul (ofQ (⟨7, 8⟩ : Q) (by decide)) (zeta 3 (by decide))))
      (Rmul (ofQ (⟨-7, 8⟩ : Q) (by decide)) (zeta 3 (by decide))) :=
    Req_trans (Req_symm (Rmul_neg_left (ofQ (⟨7, 8⟩ : Q) (by decide)) (zeta 3 (by decide))))
      (Rmul_congr (Rneg_ofQ (⟨7, 8⟩ : Q) (by decide)) (Req_refl _))
  -- `(−7/8)·(1217/1000) = −((7/8)·(1217/1000))`
  have heq1 : Req (ofQ (mul (⟨-7, 8⟩ : Q) (⟨1217, 1000⟩ : Q)) (by decide))
      (Rneg (ofQ (mul (⟨7, 8⟩ : Q) (⟨1217, 1000⟩ : Q)) (by decide))) :=
    Req_trans (Req_of_seq_Qeq (fun n => by
        show Qeq (mul (⟨-7, 8⟩ : Q) (⟨1217, 1000⟩ : Q)) (neg (mul (⟨7, 8⟩ : Q) (⟨1217, 1000⟩ : Q)));
        decide))
      (Req_symm (Rneg_ofQ (mul (⟨7, 8⟩ : Q) (⟨1217, 1000⟩ : Q)) (by decide)))
  exact Rle_trans (Rle_of_Req heq1) (Rle_trans (Rle_Rneg hup) (Rle_of_Req heq2))

set_option maxRecDepth 8192 in
/-- Archimedean part (II): `genArchTail 3 3 ≥ (9/4)ζ(2) − (7/8)ζ(3)`. -/
theorem archII_ge :
    Rle (ofQ (add (add (⟨0, 1⟩ : Q) (mul (⟨9, 4⟩ : Q) (⟨1644, 1000⟩ : Q)))
      (mul (⟨-7, 8⟩ : Q) (⟨1217, 1000⟩ : Q))) iilq_den_pos) (genArchTail 3 3) := by
  show Rle _ (Radd (Radd zero (genArchTerm 3 2 (by decide))) (genArchTerm 3 3 (by decide)))
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ (by decide) (by decide)))) ?_
  refine Radd_le_add ?_ archTerm3_ge
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ (by decide) (by decide)))) ?_
  exact Radd_le_add (Rle_of_Req (Req_refl _)) archTerm2_ge

set_option maxRecDepth 8192 in
set_option maxHeartbeats 4000000 in
/-- **`genuineArchSeq 3 ≥ archLoQ`** — lower bound on the archimedean side
    `1 − (3/2)(γ + log 4π) + (9/4)ζ(2) − (7/8)ζ(3)`. -/
theorem genuineArchSeq3_ge : Rle (ofQ archLoQ archLoQ_den_pos) (genuineArchSeq 3) := by
  unfold genuineArchSeq
  refine Rle_trans (Rle_of_Req ?_) (Radd_le_add archI_ge archII_ge)
  show Req (ofQ archLoQ _) _
  exact Req_symm (Radd_ofQ_ofQ ilq_den_pos iilq_den_pos)

/-! ### Arithmetic side `Rlambda3_arith = 3γ − 3γ² − 6γ₁ + γ³ + 3γγ₁ + (3/2)γ₂` -/

/-- `η₁`-upper `= γ_hi² + 2·γ₁_hi`. -/
def reta1UpQ : Q := add (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q)) (mul (⟨2, 1⟩ : Q) (⟨-55, 1000⟩ : Q))
/-- `γ_lo³`. -/
def gloCubeQ : Q := mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q)
/-- `η₂`-upper `= −γ_lo³ − 3·(γ_hi·γ₁_lo) − (3/2)·γ₂_lo`. -/
def reta2UpQ : Q :=
  Qsub (Qsub (neg gloCubeQ) (mul (⟨3, 1⟩ : Q) (mul (⟨578, 1000⟩ : Q) (⟨-762, 10000⟩ : Q))))
    (mul (⟨3, 2⟩ : Q) (⟨-1, 50⟩ : Q))
/-- Upper bound on the inner sum `S` of `Rlambda3_arith = −S`. -/
def arithSupQ : Q :=
  add (add (add (⟨0, 1⟩ : Q) (mul (⟨3, 1⟩ : Q) (⟨-577, 1000⟩ : Q))) (mul (⟨3, 1⟩ : Q) reta1UpQ)) reta2UpQ
/-- Certified rational lower bound on `Rlambda3_arith`. -/
def arithLoQ : Q := neg arithSupQ

theorem reta1UpQ_den_pos : 0 < reta1UpQ.den :=
  add_den_pos (Qmul_den_pos (by decide) (by decide)) (Qmul_den_pos (by decide) (by decide))
theorem gloCubeQ_den_pos : 0 < gloCubeQ.den :=
  Qmul_den_pos (Qmul_den_pos (by decide) (by decide)) (by decide)
theorem reta2UpQ_den_pos : 0 < reta2UpQ.den :=
  Qsub_den_pos (Qsub_den_pos gloCubeQ_den_pos
    (Qmul_den_pos (by decide) (Qmul_den_pos (by decide) (by decide))))
    (Qmul_den_pos (by decide) (by decide))
theorem m3reta1_den_pos : 0 < (mul (⟨3, 1⟩ : Q) reta1UpQ).den := Qmul_den_pos (by decide) reta1UpQ_den_pos
theorem arithSupQ_den_pos : 0 < arithSupQ.den :=
  add_den_pos (add_den_pos (add_den_pos (by decide) (Qmul_den_pos (by decide) (by decide)))
    m3reta1_den_pos) reta2UpQ_den_pos
theorem arithLoQ_den_pos : 0 < arithLoQ.den := arithSupQ_den_pos

/-- `η₀ = −γ ≤ −577/1000`. -/
theorem reta0_le : Rle Reta0 (ofQ (⟨-577, 1000⟩ : Q) (by decide)) := by
  unfold Reta0
  exact Rle_trans (Rle_Rneg Rgamma_h_ge_577) (Rle_of_Req (Rneg_ofQ (⟨577, 1000⟩ : Q) (by decide)))

set_option maxRecDepth 8192 in
/-- `η₁ = γ² + 2γ₁ ≤ reta1UpQ`. -/
theorem reta1_le : Rle Reta1 (ofQ reta1UpQ reta1UpQ_den_pos) := by
  unfold Reta1
  have hlin : Rle (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) Rgamma1)
      (ofQ (mul (⟨2, 1⟩ : Q) (⟨-55, 1000⟩ : Q)) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma1_le_neg055)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
  exact Rle_trans (Radd_le_add Rgamma_sq_le hlin)
    (Rle_of_Req (Radd_ofQ_ofQ (Qmul_den_pos (by decide) (by decide)) (Qmul_den_pos (by decide) (by decide))))

/-! ### Arithmetic side and the assembly `Pos Rlambda3`

    Every bound rational is rounded to a fixed small denominator (`10⁶`) and stated in **expression**
    form (`mul ⟨3,1⟩ ⟨q⟩`, `neg ⟨q⟩`), never a pre-multiplied literal: the Lean elaborator's
    `isDefEq` reconciling a literal with a `mul`/`neg`-expression `Q` inside an `ofQ` is pathologically
    slow (the denominator-blowup wall), whereas a final `decide` on the same comparison is fast. So the
    collapses match expressions and only the terminal `Qle` against the rounded literal uses `decide`. -/

set_option maxRecDepth 4096 in
/-- **`η₂ = −γ³ − 3γγ₁ − (3/2)γ₂ ≤ −29968/10⁶`** — rounded η₂ upper bound (true `≈ −0.029969`). -/
theorem reta2_le : Rle Reta2 (ofQ (⟨-29968, 1000000⟩ : Q) (by decide)) := by
  unfold Reta2
  have hN : Rle (Rneg (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h)) (ofQ (⟨-192100, 1000000⟩ : Q) (by decide)) :=
    Rle_trans (Rle_Rneg (Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) Rgamma_cube_ge))
      (Rle_of_Req (Rneg_ofQ (⟨192100, 1000000⟩ : Q) (by decide)))
  have hC : Rle (ofQ (mul (⟨3, 1⟩ : Q) (⟨-44044, 1000000⟩ : Q)) (by decide))
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma1)) := by
    have hgg : Rle (ofQ (⟨-44044, 1000000⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma1) :=
      Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) Rgamma_gamma1_ge
    exact Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) hgg)
  have hD : Rle (ofQ (mul (⟨3, 2⟩ : Q) (⟨-1, 50⟩ : Q)) (by decide))
      (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) Rgamma2) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma2_ge_neg002)
  refine Rle_trans (Rsub_le_sub (Rsub_le_sub hN hC) hD) ?_
  refine Rle_trans (Rle_of_Req (Rsub_congr
    (Rsub_ofQ_ofQ (by decide) (Qmul_den_pos (by decide) (by decide))) (Req_refl _))) ?_
  refine Rle_trans (Rle_of_Req (Rsub_ofQ_ofQ
    (Qsub_den_pos (by decide) (Qmul_den_pos (by decide) (by decide)))
    (Qmul_den_pos (by decide) (by decide)))) ?_
  exact Rle_ofQ_ofQ (Qsub_den_pos (Qsub_den_pos (by decide) (Qmul_den_pos (by decide) (by decide)))
    (Qmul_den_pos (by decide) (by decide))) (by decide) (by decide)

set_option maxRecDepth 4096 in
/-- **`η₁ = γ² + 2γ₁ ≤ 224085/10⁶`** — rounded η₁ upper bound (true `≈ 0.18`). -/
theorem reta1_le_r : Rle Reta1 (ofQ (⟨224085, 1000000⟩ : Q) (by decide)) :=
  Rle_trans reta1_le (Rle_ofQ_ofQ reta1UpQ_den_pos (by decide) (by decide))

set_option maxRecDepth 4096 in
set_option maxHeartbeats 2000000 in
/-- **`Rlambda3_arith ≥ 1088713/10⁶`** (`= 3γ − 3γ² − 6γ₁ + γ³ + 3γγ₁ + (3/2)γ₂`, true `≈ 1.0887`),
    assembled from the rounded η-anchor bounds `reta0_le`, `reta1_le_r`, `reta2_le` via the symbolic
    `nsmulR 3` collapse. -/
theorem Rlambda3_arith_ge_r : Rle (ofQ (neg (⟨-1088713, 1000000⟩ : Q)) (by decide)) Rlambda3_arith := by
  unfold Rlambda3_arith
  refine Rle_trans (Rle_of_Req (Req_symm (Rneg_ofQ (⟨-1088713, 1000000⟩ : Q) (by decide)))) (Rle_Rneg ?_)
  have h0 : Rle (nsmulR (choose 3 1) Reta0) (ofQ (mul (⟨3, 1⟩ : Q) (⟨-577, 1000⟩ : Q)) (by decide)) :=
    nsmulR3_le_mul3 (by decide) reta0_le
  have h1 : Rle (nsmulR (choose 3 2) Reta1) (ofQ (mul (⟨3, 1⟩ : Q) (⟨224085, 1000000⟩ : Q)) (by decide)) :=
    nsmulR3_le_mul3 (by decide) reta1_le_r
  have h2 : Rle (nsmulR (choose 3 3) Reta2) (ofQ (⟨-29968, 1000000⟩ : Q) (by decide)) := reta2_le
  have hz : Rle zero (ofQ (⟨0, 1⟩ : Q) (by decide)) := Rle_refl _
  refine Rle_trans (Radd_le_add (Radd_le_add (Radd_le_add hz h0) h1) h2) ?_
  refine Rle_trans (Radd_le_add (Radd_le_add (Radd_Rle_ofQ_add (by decide)
    (Qmul_den_pos (by decide) (by decide))) (Rle_refl _)) (Rle_refl _)) ?_
  refine Rle_trans (Radd_le_add (Radd_Rle_ofQ_add
    (add_den_pos (by decide) (Qmul_den_pos (by decide) (by decide)))
    (Qmul_den_pos (by decide) (by decide))) (Rle_refl _)) ?_
  refine Rle_trans (Radd_Rle_ofQ_add
    (add_den_pos (add_den_pos (by decide) (Qmul_den_pos (by decide) (by decide)))
      (Qmul_den_pos (by decide) (by decide))) (by decide)) ?_
  exact Rle_ofQ_ofQ (add_den_pos (add_den_pos (add_den_pos (by decide)
    (Qmul_den_pos (by decide) (by decide))) (Qmul_den_pos (by decide) (by decide))) (by decide))
    (by decide) (by decide)

set_option maxRecDepth 4096 in
/-- **`genuineArchSeq 3 ≥ −1030276/10⁶`** — the archimedean lower `archLoQ` rounded to `10⁶`. -/
theorem archLoR_le : Rle (ofQ (⟨-1030276, 1000000⟩ : Q) (by decide)) (genuineArchSeq 3) :=
  Rle_trans (Rle_ofQ_ofQ (by decide) archLoQ_den_pos (by decide)) genuineArchSeq3_ge

set_option maxRecDepth 4096 in
/-- **`Pos Rlambda3`** — the third Li coefficient is positive, the first kernel-certified `Pos λₙ`
    beyond `n = 2`. Certified lower bound `λ₃ ≥ 58437/10⁶ ≈ +0.0584` (true `λ₃ ≈ 0.2076`), assembled
    from `Rlambda3_arith ≥ 1.0887` and `genuineArchSeq 3 ≥ −1.0303`, i.e. from the six bracketed
    constants `γ ∈ [0.577,0.578]`, `γ₁ ∈ [−0.0762,−0.055]`, `γ₂ ≥ −0.02`, `ζ(2) ≥ 1.644`,
    `ζ(3) ≤ 1.217`, `log 4π ≤ 2.5316`.

    Conquers the `n = 3` prime–archimedean coupling coefficient (`coupling_n3_iff_pos_lambda3`). This
    is `n = 3` ONLY — NOT the crux, which is the uniform `∀ n` (= RH); `liPositivityHolds` stays
    `none`, RH open. -/
theorem Rlambda3_pos : Pos Rlambda3 := by
  have hμ : Rle (ofQ (add (neg (⟨-1088713, 1000000⟩ : Q)) (⟨-1030276, 1000000⟩ : Q)) (by decide)) Rlambda3 :=
    Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ (by decide) (by decide))))
      (Radd_le_add Rlambda3_arith_ge_r archLoR_le)
  exact Pos_of_Rle_ofQ (by decide) (by decide) hμ

end UOR.Bridge.F1Square.Analysis
