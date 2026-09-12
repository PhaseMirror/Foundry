/-
F1 square — Track 1, item 2 (finish): **the ξ conjugation symmetry, with both factor conjugations
discharged** — `ξ(s̄) = conj ξ(s)` for the ξ built from the constructed `Γ(s/2)` (`CSpougeGammaW`) and
`ζ(s)` (`CzetaStrip`), with no conjugation hypotheses left open.

`Cxi_conj` (`ComplexXiConj.lean`) reduces `ξ(s̄) = conj ξ(s)` to the two analytic factor symmetries
`hg` (Γ-side) and `hz` (ζ-side). Both are now proven theorems: `CSpougeGammaW_conj`
(`ComplexGammaConj.lean`) and `CzetaStrip_conj` (`ComplexZetaConj.lean`). This wrapper feeds them in,
closing the symmetry for the genuinely-built ξ — the remaining seams are only the construction
witnesses (`Re`-bounds, ρ-bounds, η-blocks, inverse witnesses) and the standard Γ-side relocations
(`hre` modulus-log congruence, `hbc` conjugate ratio bound), no longer any conjugation hypothesis.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.ComplexXiConj
import Foundations.F1.Analysis.ComplexGammaConj
import Foundations.F1.Analysis.ComplexZetaConj

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **`ξ(s̄) = conj ξ(s)` with both factor conjugations discharged** — `Cxi_conj` fed the proven
    Γ-side (`CSpougeGammaW_conj`) and ζ-side (`CzetaStrip_conj`) symmetries. The Γ argument `w` is the
    `s/2` passed to `CSpougeGammaW` (caller sets `w = s/2`); `gammaHalf`/`zeta` and their conjugates
    infer from the two conjugation theorems. -/
theorem Cxi_conj_built (s w : Complex)
    {cΓ : Q} (hcnΓ : 0 < cΓ.num) (hcdΓ : 0 < cΓ.den)
    (hcwΓ : Rle (ofQ cΓ hcdΓ) w.re) (hcwcΓ : Rle (ofQ cΓ hcdΓ) (Cconj w).re)
    (bΓ : Q) (hbdΓ : 0 < bΓ.den) (hbnΓ : 0 ≤ bΓ.num)
    (ρΓ : Q) (hρ0Γ : 0 ≤ ρΓ.num) (hρdΓ : 0 < ρΓ.den) (hρltΓ : ρΓ.num.toNat < ρΓ.den)
    (hρ2Γ : Qle (⟨1, 2⟩ : Q) (Qsub (⟨1, 1⟩ : Q) (mul ρΓ ρΓ)))
    (hbΓ : ∀ n, Qle (Qabs ((Rdiv (CspougeBase w bΓ hbdΓ).im (CspougeBase w bΓ hbdΓ).re
      (digammaArgK cΓ) (CspougeBase_re_witness hcnΓ hcdΓ hcwΓ hbdΓ hbnΓ)).seq n)) ρΓ)
    (hbcΓ : ∀ n, Qle (Qabs ((Rdiv (CspougeBase (Cconj w) bΓ hbdΓ).im (CspougeBase (Cconj w) bΓ hbdΓ).re
      (digammaArgK cΓ) (CspougeBase_re_witness hcnΓ hcdΓ hcwcΓ hbdΓ hbnΓ)).seq n)) ρΓ)
    (hreΓ : Req (RlogPos (cnormSq (CspougeBase (Cconj w) bΓ hbdΓ)) (CdigK cΓ)
        (CspougeBase_cnormSq_witness hcnΓ hcdΓ hcwcΓ hbdΓ hbnΓ))
      (RlogPos (cnormSq (CspougeBase w bΓ hbdΓ)) (CdigK cΓ)
        (CspougeBase_cnormSq_witness hcnΓ hcdΓ hcwΓ hbdΓ hbnΓ)))
    (aΓ : Q) (hadpΓ : 0 < aΓ.den) (NΓ : Nat)
    (haΓ : ∀ (k : Nat), 1 ≤ k → k ≤ NΓ → Qlt (⟨1, 1⟩ : Q) (Qsub aΓ ⟨(k : Int), 1⟩))
    {sbZ TZ : Q} (hsbdZ : 0 < sbZ.den) (hsb0Z : 0 ≤ sbZ.num) (hTdZ : 0 < TZ.den) (hT0Z : 0 ≤ TZ.num)
    (hσZ : Rnonneg s.re) (hsbZ : Rle s.re (ofQ sbZ hsbdZ))
    (hT1Z : Rle (Rneg (ofQ TZ hTdZ)) s.im) (hT2Z : Rle s.im (ofQ TZ hTdZ))
    {τZ : Q} (hτnZ : 0 < τZ.num) (hτdZ : 0 < τZ.den)
    (hblkZ : ∀ k, 1 ≤ k → Rle (Rsub (EtaVSum s TZ hTdZ (2 ^ (k + 1))) (EtaVSum s TZ hTdZ (2 ^ k)))
        (ofQ (mul (Vconst sbZ TZ) (qpow (Qinv (add ⟨1, 1⟩ τZ)) k))
          (Qmul_den_pos (Vconst_den_pos hsbdZ hTdZ)
            (qpow_den_pos (Qinv_den_pos (by simp only [add]; push_cast; omega)) k))))
    (hT1cZ : Rle (Rneg (ofQ TZ hTdZ)) (Cconj s).im) (hT2cZ : Rle (Cconj s).im (ofQ TZ hTdZ))
    (hblkcZ : ∀ k, 1 ≤ k → Rle (Rsub (EtaVSum (Cconj s) TZ hTdZ (2 ^ (k + 1)))
          (EtaVSum (Cconj s) TZ hTdZ (2 ^ k)))
        (ofQ (mul (Vconst sbZ TZ) (qpow (Qinv (add ⟨1, 1⟩ τZ)) k))
          (Qmul_den_pos (Vconst_den_pos hsbdZ hTdZ)
            (qpow_den_pos (Qinv_den_pos (by simp only [add]; push_cast; omega)) k))))
    (kZ : Nat) (hkZ : Qlt (Qbound kZ) ((CnormSq (etaDenom s)).seq kZ))
    (kZ' : Nat) (hkZ' : Qlt (Qbound kZ') ((CnormSq (etaDenom (Cconj s))).seq kZ')) :
    Ceq (Cxi (Cconj s)
          (CSpougeGammaW (Cconj w) hcnΓ hcdΓ hcwcΓ bΓ hbdΓ hbnΓ ρΓ hρ0Γ hρdΓ hρltΓ hbcΓ aΓ hadpΓ NΓ haΓ)
          (CzetaStrip (Cconj s) hsbdZ hsb0Z hTdZ hT0Z hσZ hsbZ hT1cZ hT2cZ hτnZ hτdZ hblkcZ kZ' hkZ'))
        (Cconj (Cxi s
          (CSpougeGammaW w hcnΓ hcdΓ hcwΓ bΓ hbdΓ hbnΓ ρΓ hρ0Γ hρdΓ hρltΓ hbΓ aΓ hadpΓ NΓ haΓ)
          (CzetaStrip s hsbdZ hsb0Z hTdZ hT0Z hσZ hsbZ hT1Z hT2Z hτnZ hτdZ hblkZ kZ hkZ))) :=
  Cxi_conj s _ _ _ _
    (CSpougeGammaW_conj w hcnΓ hcdΓ hcwΓ hcwcΓ bΓ hbdΓ hbnΓ ρΓ hρ0Γ hρdΓ hρltΓ hρ2Γ hbΓ hbcΓ hreΓ
      aΓ hadpΓ NΓ haΓ)
    (CzetaStrip_conj s hsbdZ hsb0Z hTdZ hT0Z hσZ hsbZ hT1Z hT2Z hτnZ hτdZ hblkZ hT1cZ hT2cZ hblkcZ
      kZ hkZ kZ' hkZ')

end Multiplicity.UOR.Bridge.F1Square.Analysis
