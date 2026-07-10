/-
F1 square — v0.22.0 Track 1, brick (complex lift): **the complex logarithm `Clog` on the principal
sector** — `Clog z = ½·log|z|² + i·arg(z)`, for `Re z > 0` and `|Im z / Re z| ≤ ρ < 1`.

The object `log ξ` and `ζ′/ζ` are built from (toward discharging `bl`). Its real part is the genuine
constructive log of the squared modulus (`½·RlogPos(cnormSq z) = log|z|`), its imaginary part the
principal-sector argument `Carg z` (`ComplexArg.lean`). The principal-branch anchor proved here:
on the positive real axis (`Im = 0`) the imaginary part vanishes (`Clog_ofReal_pos_im`, from
`Carg_ofReal_pos`).

(The substantive analytic properties — `Re (Clog x) = log x` for real `x > 0` via `log(x²) = 2 log x`,
and additivity `Clog (zw) = Clog z + Clog w` via log-multiplicativity and the arctan addition law —
are the next bricks; each needs its own sub-construction.)

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.ComplexArg
import F1Square.Analysis.ZeroGeometry

namespace UOR.Bridge.F1Square.Analysis

/-- **The complex logarithm on the principal sector**: `Clog z = ½·log|z|² + i·arg(z)`. Witnesses:
    `kn` for `|z|² > 0` (so the real log exists), `kr` for `Re z > 0`, and `ρ`-bound for the argument
    ratio `Im z / Re z`. -/
def Clog (z : Complex) (kn : Nat) (hkn : Qlt (Qbound kn) ((cnormSq z).seq kn))
    (kr : Nat) (hkr : Qlt (Qbound kr) (z.re.seq kr))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv z.im z.re kr hkr).seq n)) ρ) : Complex :=
  ⟨Rmul half (RlogPos (cnormSq z) kn hkn), Carg z kr hkr ρ hρ0 hρd hρlt hb⟩

/-- The real part of `Clog z` is `½·log|z|²` (definitional). -/
theorem Clog_re (z : Complex) (kn : Nat) (hkn : Qlt (Qbound kn) ((cnormSq z).seq kn))
    (kr : Nat) (hkr : Qlt (Qbound kr) (z.re.seq kr))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv z.im z.re kr hkr).seq n)) ρ) :
    (Clog z kn hkn kr hkr ρ hρ0 hρd hρlt hb).re = Rmul half (RlogPos (cnormSq z) kn hkn) := rfl

/-- The imaginary part of `Clog z` is the principal-sector argument `arg(z)` (definitional). -/
theorem Clog_im (z : Complex) (kn : Nat) (hkn : Qlt (Qbound kn) ((cnormSq z).seq kn))
    (kr : Nat) (hkr : Qlt (Qbound kr) (z.re.seq kr))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv z.im z.re kr hkr).seq n)) ρ) :
    (Clog z kn hkn kr hkr ρ hρ0 hρd hρlt hb).im = Carg z kr hkr ρ hρ0 hρd hρlt hb := rfl

/-- **`Clog` of a positive real has vanishing imaginary part** (the principal-branch anchor): for
    `x > 0`, `Im (Clog (ofReal x)) = arg(x) = 0` (`Carg_ofReal_pos`). So `Clog` lands on the real
    axis for positive reals, as the principal branch requires. -/
theorem Clog_ofReal_pos_im (x : Real)
    (kn : Nat) (hkn : Qlt (Qbound kn) ((cnormSq (ofReal x)).seq kn))
    (kr : Nat) (hkr : Qlt (Qbound kr) ((ofReal x).re.seq kr))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv (ofReal x).im (ofReal x).re kr hkr).seq n)) ρ) :
    Req (Clog (ofReal x) kn hkn kr hkr ρ hρ0 hρd hρlt hb).im zero :=
  Carg_ofReal_pos x kr hkr ρ hρ0 hρd hρlt hb

end UOR.Bridge.F1Square.Analysis
