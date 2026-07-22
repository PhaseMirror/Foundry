/-
F1 square — Track 1: **conjugation symmetry of the complex logarithm** on the principal sector —
`Clog(z̄) = conj(Clog z)` — and its consumer `Cpow(z̄, w̄) = conj(Cpow z w)`.

The imaginary part is `arg(z̄) = −arg(z)` (the existing `Carg_conj`, arctan oddness). The real part is
`½·log|z̄|² = ½·log|z|²` — `|z̄|² = |z|²` exactly (`CnormSq_conj`/`cnormSq`), so it is a `RlogPos`
congruence; here it is carried as the seam `hre`, honestly mirroring `Clog_add`'s `hmod` design (the
`RlogPos` congruence is discharged in the bounded/general modulus regimes by the `RlogPos_congr`
family). `Cpow_conj` then follows from `z^w = exp(w·Clog z)` via `Cexp_conj` + `Cconj_Cmul`.

These are the principal-sector faces of ξ's conjugate-pair zero symmetry; the Γ-side hypothesis of
`Cxi_conj` (`Γ(s̄/2) = conj Γ(s/2)`) is discharged through `CSpougeGammaW`, whose base power
`(w+b)^{w−½}` sits near the positive real axis (principal sector), for which `Cpow_conj` is the core.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ComplexLog
import Core.F1.Analysis.ComplexArgUpper
import Core.F1.Analysis.ComplexArgLower
import Core.F1.Analysis.ComplexDigammaConj
import Core.F1.Analysis.ComplexPowGen
import Core.F1.Analysis.ComplexLimit

namespace UOR.Bridge.F1Square.Analysis

/-- **Conjugate of a limit = limit of conjugates**: `conj(Clim X) = Clim (conj ∘ X)`. Real parts are
    fixed (`Cconj` keeps `re`); imaginary parts negate (`Rlim_neg`). The bridge for conjugating any
    `Rlim`-built complex object (`Ceta`, hence `CzetaStrip`, toward the ζ-side of `Cxi_conj`). -/
theorem Clim_Cconj (X : Nat → Complex) (h : CReg X) (hc : CReg (fun n => Cconj (X n))) :
    Ceq (Clim (fun n => Cconj (X n)) hc) (Cconj (Clim X h)) :=
  ⟨Rlim_congr (fun n => (X n).re) (fun n => (X n).re) hc.1 h.1 (fun _ => Req_refl _),
   Rlim_neg (fun n => (X n).im) h.2 hc.2⟩

/-- **`Clog(z̄) = conj(Clog z)`** on the principal sector: imaginary part `arg(z̄) = −arg(z)`
    (`Carg_conj`); real part `½·log|z̄|² = ½·log|z|²` carried as the `RlogPos`-congruence seam `hre`
    (`|z̄|² = |z|²` exactly, so this is a genuine congruence, discharged in the modulus regimes by the
    `RlogPos_congr` family — the same seam shape as `Clog_add`'s `hmod`). -/
theorem Clog_conj (z : Complex)
    (kn : Nat) (hkn : Qlt (Qbound kn) ((cnormSq z).seq kn))
    (knc : Nat) (hknc : Qlt (Qbound knc) ((cnormSq (Cconj z)).seq knc))
    (kr : Nat) (hkr : Qlt (Qbound kr) (z.re.seq kr))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)))
    (hb : ∀ n, Qle (Qabs ((Rdiv z.im z.re kr hkr).seq n)) ρ)
    (hbc : ∀ n, Qle (Qabs ((Rdiv (Cconj z).im (Cconj z).re kr hkr).seq n)) ρ)
    (hre : Req (RlogPos (cnormSq (Cconj z)) knc hknc) (RlogPos (cnormSq z) kn hkn)) :
    Ceq (Clog (Cconj z) knc hknc kr hkr ρ hρ0 hρd hρlt hbc)
        (Cconj (Clog z kn hkn kr hkr ρ hρ0 hρd hρlt hb)) :=
  ⟨Rmul_congr (Req_refl half) hre, Carg_conj z kr hkr ρ hρ0 hρd hρlt hρ2 hb hbc⟩

/-- **`(z̄)^{w̄} = conj(z^w)`** on the principal sector — `z^w = exp(w·Clog z)`, so conjugation passes
    through `Cexp_conj` and `Cconj_Cmul` once `Clog(z̄) = conj(Clog z)` (`Clog_conj`). This is the
    analytic core of the `Γ(s̄/2) = conj Γ(s/2)` discharge (`CSpougeGammaW`'s base power). -/
theorem Cpow_conj (z w : Complex)
    (kn : Nat) (hkn : Qlt (Qbound kn) ((cnormSq z).seq kn))
    (knc : Nat) (hknc : Qlt (Qbound knc) ((cnormSq (Cconj z)).seq knc))
    (kr : Nat) (hkr : Qlt (Qbound kr) (z.re.seq kr))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)))
    (hb : ∀ n, Qle (Qabs ((Rdiv z.im z.re kr hkr).seq n)) ρ)
    (hbc : ∀ n, Qle (Qabs ((Rdiv (Cconj z).im (Cconj z).re kr hkr).seq n)) ρ)
    (hre : Req (RlogPos (cnormSq (Cconj z)) knc hknc) (RlogPos (cnormSq z) kn hkn)) :
    Ceq (Cpow (Cconj z) knc hknc kr hkr ρ hρ0 hρd hρlt hbc (Cconj w))
        (Cconj (Cpow z kn hkn kr hkr ρ hρ0 hρd hρlt hb w)) := by
  show Ceq (Cexp (Cmul (Cconj w) (Clog (Cconj z) knc hknc kr hkr ρ hρ0 hρd hρlt hbc)))
           (Cconj (Cexp (Cmul w (Clog z kn hkn kr hkr ρ hρ0 hρd hρlt hb))))
  refine Ceq_trans (Cexp_congr ?_) (Cexp_conj (Cmul w (Clog z kn hkn kr hkr ρ hρ0 hρd hρlt hb)))
  refine Ceq_trans (Cmul_congr_loc (Ceq_refl (Cconj w))
      (Clog_conj z kn hkn knc hknc kr hkr ρ hρ0 hρd hρlt hρ2 hb hbc hre)) ?_
  exact Ceq_symm (Cconj_Cmul w (Clog z kn hkn kr hkr ρ hρ0 hρd hρlt hb))

end UOR.Bridge.F1Square.Analysis
