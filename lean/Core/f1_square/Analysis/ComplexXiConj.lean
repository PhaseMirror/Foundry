/-
F1 square — v0.22.0 Track 1: **conjugation symmetry of the completed ξ**, reduced to the Γ/ζ factor
conjugations. ξ's zeros come in conjugate pairs, so `ξ(s̄) = conj ξ(s)` is the structural symmetry
behind that; here it is assembled from the factor symmetries of `Cxi = ½s(s−1)·π^{−s/2}·Γ(s/2)·ζ(s)`.

Two factors are conjugation-symmetric outright: the conductor `π^{−s/2}` (`CpiPow_conj`, via the
reusable `Cexp_conj` — a real base, no `Clog`/modulus baggage) and the polynomial `½s(s−1)`
(`CxiPoly_conj`, pure ℂ-ring algebra). The remaining two — `Γ(s/2)` and `ζ(s)` — enter `Cxi` as
supplied values, so their conjugation is taken as explicit hypotheses; `Cxi_conj` then distributes
`Cconj` through the product. This isolates the genuine remaining content (the `Γ`/ζ conjugation, the
former a large `Clog`/`Cpow` chain) as named, audit-visible hypotheses — the program's standard
relocation, not a closure.

Pure Lean 4 core, no Mathlib, no `()`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Core.f1_square.Analysis.ComplexXi
import Core.f1_square.Analysis.ComplexDigammaConj
import Core.f1_square.Analysis.ComplexArgLower

namespace UOR.Bridge.F1Square.Analysis

/-- Local ℂ-multiplication congruence (componentwise). -/
private theorem xiconj_Cmul_congr {z z' w w' : Complex} (hz : Ceq z z') (hw : Ceq w w') :
    Ceq (Cmul z w) (Cmul z' w') :=
  ⟨Rsub_congr (Rmul_congr hz.1 hw.1) (Rmul_congr hz.2 hw.2),
   Radd_congr (Rmul_congr hz.1 hw.2) (Rmul_congr hz.2 hw.1)⟩

/-- `−0 ≈ 0` (for the imaginary part of `Cconj` of a real embedding). -/
private theorem xiconj_neg_zero : Req (Rneg zero) zero :=
  Req_of_seq_Qeq (fun _ => by simp only [Rneg, zero, ofQ, Qeq, neg] <;> decide)

/-- A real embedding is conjugation-fixed: `ofReal x ≈ Cconj (ofReal x)` (`Im = 0`, `−0 = 0`). -/
private theorem xiconj_ofReal_conj (x : Real) : Ceq (ofReal x) (Cconj (ofReal x)) :=
  ⟨Req_refl _, Req_symm xiconj_neg_zero⟩

/-- `Cone` is conjugation-fixed. -/
private theorem xiconj_Cone_conj : Ceq Cone (Cconj Cone) :=
  ⟨Req_refl _, Req_symm xiconj_neg_zero⟩

/-- `Cconj` distributes over `Cadd` (up to `≈`). -/
private theorem xiconj_Cconj_Cadd (z w : Complex) :
    Ceq (Cconj (Cadd z w)) (Cadd (Cconj z) (Cconj w)) :=
  ⟨Req_refl _, Rneg_Radd z.im w.im⟩

/-- `Cconj` commutes with `Cneg` (up to `≈`; in fact componentwise-equal). -/
private theorem xiconj_Cconj_Cneg (z : Complex) : Ceq (Cconj (Cneg z)) (Cneg (Cconj z)) :=
  ⟨Req_refl _, Req_refl _⟩

/-- Local ℂ-addition congruence. -/
private theorem xiconj_Cadd_congr {z z' w w' : Complex} (hz : Ceq z z') (hw : Ceq w w') :
    Ceq (Cadd z w) (Cadd z' w') :=
  ⟨Radd_congr hz.1 hw.1, Radd_congr hz.2 hw.2⟩

/-- Local ℂ-negation congruence. -/
private theorem xiconj_Cneg_congr {z z' : Complex} (h : Ceq z z') : Ceq (Cneg z) (Cneg z') :=
  ⟨Rneg_congr h.1, Rneg_congr h.2⟩

/-- **The conductor factor is conjugation-symmetric** `π^{−s̄/2} = conj(π^{−s/2})` (`CpiPow_conj`). From
    `CpiPow = exp((−s/2)·log π)`: `CnegHalf s̄ ≈ conj(CnegHalf s)`, the real `log π` is conjugation-fixed,
    so the product conjugates (`Cconj_Cmul`) and `exp` carries it through (`Cexp_conj`). -/
theorem CpiPow_conj (s : Complex) : Ceq (CpiPow (Cconj s)) (Cconj (CpiPow s)) := by
  have h1 : Ceq (CnegHalf (Cconj s)) (Cconj (CnegHalf s)) :=
    ⟨Req_refl _, Rneg_congr (Rmul_neg_right (ofQ (⟨1, 2⟩ : Q) (by decide)) s.im)⟩
  have hstep : Ceq (Cmul (CnegHalf (Cconj s)) (ofReal Rlog_pi))
      (Cconj (Cmul (CnegHalf s) (ofReal Rlog_pi))) :=
    Ceq_trans (xiconj_Cmul_congr h1 (xiconj_ofReal_conj Rlog_pi))
      (Ceq_symm (Cconj_Cmul (CnegHalf s) (ofReal Rlog_pi)))
  exact Ceq_trans (Cexp_congr hstep) (Cexp_conj (Cmul (CnegHalf s) (ofReal Rlog_pi)))

/-- **The polynomial prefactor is conjugation-symmetric** `½s̄(s̄−1) = conj(½s(s−1))` (`CxiPoly_conj`).
    Pure ℂ-ring algebra: `Cconj` distributes through the two `Cmul`s, the `Cadd`, and `Cneg`, fixing
    the real `½` and `1`. -/
theorem CxiPoly_conj (s : Complex) : Ceq (CxiPoly (Cconj s)) (Cconj (CxiPoly s)) := by
  -- conj(½·(s·(s−1))) = ½·(s̄·(s̄−1))
  have hX : Ceq (Cadd (Cconj s) (Cneg Cone)) (Cconj (Cadd s (Cneg Cone))) := by
    refine Ceq_symm (Ceq_trans (xiconj_Cconj_Cadd s (Cneg Cone))
      (xiconj_Cadd_congr (Ceq_refl (Cconj s)) ?_))
    exact Ceq_trans (xiconj_Cconj_Cneg Cone) (xiconj_Cneg_congr (Ceq_symm xiconj_Cone_conj))
  have hinner : Ceq (Cmul (Cconj s) (Cadd (Cconj s) (Cneg Cone)))
      (Cconj (Cmul s (Cadd s (Cneg Cone)))) :=
    Ceq_trans (xiconj_Cmul_congr (Ceq_refl (Cconj s)) hX)
      (Ceq_symm (Cconj_Cmul s (Cadd s (Cneg Cone))))
  refine Ceq_trans (xiconj_Cmul_congr (xiconj_ofReal_conj (ofQ (⟨1, 2⟩ : Q) (by decide))) hinner)
    (Ceq_symm (Cconj_Cmul (ofReal (ofQ (⟨1, 2⟩ : Q) (by decide))) (Cmul s (Cadd s (Cneg Cone)))))

/-- **Conjugation symmetry of the completed ξ**, modulo the Γ/ζ factor conjugations:
    `ξ(s̄) = conj ξ(s)` whenever the supplied `Γ(s̄/2)`, `ζ(s̄)` are the conjugates of `Γ(s/2)`, `ζ(s)`
    (`hg`, `hz`). The barrier-free factors (`CpiPow_conj`, `CxiPoly_conj`) and `Cconj_Cmul` distribute
    the conjugation through the product. Reduces ξ's conjugate-pair symmetry to the two analytic factor
    symmetries — the Γ one (a `Clog`/`Cpow` chain) and the ζ one — as explicit hypotheses. -/
theorem Cxi_conj (s gammaHalf zeta gammaHalfConj zetaConj : Complex)
    (hg : Ceq gammaHalfConj (Cconj gammaHalf)) (hz : Ceq zetaConj (Cconj zeta)) :
    Ceq (Cxi (Cconj s) gammaHalfConj zetaConj) (Cconj (Cxi s gammaHalf zeta)) := by
  -- conj of the nested product, distributed outward
  have hd1 : Ceq (Cconj (Cxi s gammaHalf zeta))
      (Cmul (Cconj (Cmul (Cmul (CxiPoly s) (CpiPow s)) gammaHalf)) (Cconj zeta)) :=
    Cconj_Cmul (Cmul (Cmul (CxiPoly s) (CpiPow s)) gammaHalf) zeta
  have hd2 : Ceq (Cconj (Cmul (Cmul (CxiPoly s) (CpiPow s)) gammaHalf))
      (Cmul (Cconj (Cmul (CxiPoly s) (CpiPow s))) (Cconj gammaHalf)) :=
    Cconj_Cmul (Cmul (CxiPoly s) (CpiPow s)) gammaHalf
  have hd3 : Ceq (Cconj (Cmul (CxiPoly s) (CpiPow s)))
      (Cmul (Cconj (CxiPoly s)) (Cconj (CpiPow s))) :=
    Cconj_Cmul (CxiPoly s) (CpiPow s)
  -- assemble conj(ξ s) ≈ ((conj poly · conj π) · conj Γ) · conj ζ
  have hConj : Ceq (Cconj (Cxi s gammaHalf zeta))
      (Cmul (Cmul (Cmul (Cconj (CxiPoly s)) (Cconj (CpiPow s))) (Cconj gammaHalf)) (Cconj zeta)) :=
    Ceq_trans hd1
      (xiconj_Cmul_congr
        (Ceq_trans hd2 (xiconj_Cmul_congr hd3 (Ceq_refl (Cconj gammaHalf))))
        (Ceq_refl (Cconj zeta)))
  -- ξ(s̄) ≈ ((conj poly · conj π) · conj Γ) · conj ζ  (factor symmetries + hypotheses)
  refine Ceq_trans (xiconj_Cmul_congr
    (xiconj_Cmul_congr (xiconj_Cmul_congr (CxiPoly_conj s) (CpiPow_conj s)) hg) hz) (Ceq_symm hConj)

end UOR.Bridge.F1Square.Analysis
