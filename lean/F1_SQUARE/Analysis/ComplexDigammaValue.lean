/-
F1 square — v0.22.0 Track 1: **the complex digamma value anchor** `ψ(1) = −γ` (`CDigamma_one`), the
convention witness that the constructed `CDigamma` is genuinely the digamma (complex lift of the
real-line `Digamma_one_eq_neg_gamma`).

At `s = 1` the factored term `Cterm_n = (s−1)·P_n` vanishes (`s − 1 = 0`), so every term of the series
is `≈ 0` (`CdigammaTerm_one_eq_zero`), the partial sums are `≈ 0`, and the limit is `0`
(`CDigammaCore_one_eq_zero`, via `genSum_congr`/`Rlim_zero`). Hence `ψ(1) = −γ + 0 = −γ`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import F1Square.Analysis.ComplexDigamma
import F1Square.Analysis.ComplexDigammaConj
import F1Square.Analysis.RlimProps

namespace UOR.Bridge.F1Square.Analysis

/-- Local ℂ-multiplication congruence. -/
private theorem cdval_Cmul_congr {z z' w w' : Complex} (hz : Ceq z z') (hw : Ceq w w') :
    Ceq (Cmul z w) (Cmul z' w') :=
  ⟨Rsub_congr (Rmul_congr hz.1 hw.1) (Rmul_congr hz.2 hw.2),
   Radd_congr (Rmul_congr hz.1 hw.2) (Rmul_congr hz.2 hw.1)⟩

/-- `0 · P ≈ 0` in ℂ. -/
private theorem cdval_Cmul_zero_left (P : Complex) : Ceq (Cmul Czero P) Czero := by
  refine ⟨?_, ?_⟩
  · show Req (Rsub (Rmul zero P.re) (Rmul zero P.im)) zero
    exact Req_trans (Rsub_congr (Req_trans (Rmul_comm zero P.re) (Rmul_zero P.re))
      (Req_trans (Rmul_comm zero P.im) (Rmul_zero P.im))) (Rsub_zero zero)
  · show Req (Radd (Rmul zero P.im) (Rmul zero P.re)) zero
    exact Req_trans (Radd_congr (Req_trans (Rmul_comm zero P.im) (Rmul_zero P.im))
      (Req_trans (Rmul_comm zero P.re) (Rmul_zero P.re))) (Radd_zero zero)

/-- `genSum` of the all-zero sequence is `0`. -/
theorem genSum_const_zero (N : Nat) : Req (genSum (fun _ => zero) N) zero := by
  induction N with
  | zero => exact Req_refl zero
  | succ N ih => exact Req_trans (Radd_congr ih (Req_refl zero)) (Radd_zero zero)

/-- **The `n`-th term vanishes at `s = 1`**: `Cterm_n(1) ≈ 0`. From the factored form
    `Cterm = (s−1)·P` with `s − 1 = 1 − 1 ≈ 0` (`Cadd_neg`) and `0·P ≈ 0`. -/
theorem CdigammaTerm_one_eq_zero {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcs : Rle (ofQ c hcd) Cone.re) (n : Nat) :
    Ceq (CdigammaTerm Cone hcn hcd hcs n) Czero :=
  Ceq_trans (CdigammaTerm_factored Cone hcn hcd hcs n)
    (Ceq_trans (cdval_Cmul_congr (Cadd_neg Cone) (Ceq_refl _)) (cdval_Cmul_zero_left _))

/-- **The complex digamma core vanishes at `s = 1`**: both `Re` and `Im` of `Σ-core(1)` are `≈ 0`. The
    `Re`/`Im` partial sums are pointwise `≈ 0` (`genSum_congr` to the all-zero sequence), so `Rlim_zero`
    gives the limits `0`. -/
theorem CDigammaCore_one_eq_zero {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcs : Rle (ofQ c hcd) Cone.re) {B1 B2 : Q} (hB1d : 0 < B1.den) (hB2d : 0 < B2.den)
    (hB10 : 0 ≤ B1.num) (hB20 : 0 ≤ B2.num)
    (hB1lo : Rle (Rneg (ofQ B1 hB1d)) (Rsub Cone.re one)) (hB1hi : Rle (Rsub Cone.re one) (ofQ B1 hB1d))
    (hB2lo : Rle (Rneg (ofQ B2 hB2d)) Cone.im) (hB2hi : Rle Cone.im (ofQ B2 hB2d)) :
    Req (CDigammaCore Cone hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi).re zero
    ∧ Req (CDigammaCore Cone hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi).im zero := by
  refine ⟨?_, ?_⟩
  · exact Rlim_zero
      (fun j => genSum (fun n => (CdigammaTerm Cone hcn hcd hcs n).re)
        (digammaMidx (add B1 (mul B2 B2)) j))
      (CdigammaReSum_RReg Cone hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi)
      (fun j => Req_trans
        (genSum_congr _ _ (fun n => (CdigammaTerm_one_eq_zero hcn hcd hcs n).1) _)
        (genSum_const_zero _))
  · exact Rlim_zero
      (fun j => genSum (fun n => (CdigammaTerm Cone hcn hcd hcs n).im)
        (digammaMidx (add (mul B1 B2) B2) j))
      (CdigammaImSum_RReg Cone hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi)
      (fun j => Req_trans
        (genSum_congr _ _ (fun n => (CdigammaTerm_one_eq_zero hcn hcd hcs n).2) _)
        (genSum_const_zero _))

/-- **★ `ψ(1) = −γ`** (`CDigamma_one`): the complex digamma at `s = 1` equals the real `−γ` (embedded),
    the convention anchor confirming `CDigamma` is genuinely `Γ′/Γ`. From `ψ(1) = −γ + core(1)` with
    `core(1) ≈ 0` (`CDigammaCore_one_eq_zero`). -/
theorem CDigamma_one {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcs : Rle (ofQ c hcd) Cone.re) {B1 B2 : Q} (hB1d : 0 < B1.den) (hB2d : 0 < B2.den)
    (hB10 : 0 ≤ B1.num) (hB20 : 0 ≤ B2.num)
    (hB1lo : Rle (Rneg (ofQ B1 hB1d)) (Rsub Cone.re one)) (hB1hi : Rle (Rsub Cone.re one) (ofQ B1 hB1d))
    (hB2lo : Rle (Rneg (ofQ B2 hB2d)) Cone.im) (hB2hi : Rle Cone.im (ofQ B2 hB2d)) :
    Ceq (CDigamma Cone hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi)
      (ofReal (Rneg Rgamma_h)) := by
  obtain ⟨hre, him⟩ := CDigammaCore_one_eq_zero hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi
  refine ⟨?_, ?_⟩
  · -- (−γ) + core.re ≈ −γ
    show Req (Radd (Rneg Rgamma_h) (CDigammaCore Cone hcn hcd hcs hB1d hB2d hB10 hB20
        hB1lo hB1hi hB2lo hB2hi).re) (Rneg Rgamma_h)
    exact Req_trans (Radd_congr (Req_refl _) hre) (Radd_zero (Rneg Rgamma_h))
  · -- 0 + core.im ≈ 0
    show Req (Radd zero (CDigammaCore Cone hcn hcd hcs hB1d hB2d hB10 hB20
        hB1lo hB1hi hB2lo hB2hi).im) zero
    exact Req_trans (Radd_congr (Req_refl _) him) (Radd_zero zero)

end UOR.Bridge.F1Square.Analysis
