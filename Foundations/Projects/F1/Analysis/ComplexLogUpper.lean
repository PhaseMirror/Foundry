/-
F1 square — v0.22.0 Track 1, brick (argument axis): **the complex logarithm on the upper sector**
`ClogUpper z = ½·log|z|² + i·(π/2 − arctan(Re z / Im z))`, for `Im z > 0` and `|Re z / Im z| ≤ ρ < 1`.

The principal-sector `Clog` (`ComplexLog.lean`) is defined on `Re z > 0`, `|arg| < π/4`. This file
extends the complex logarithm PAST `|arg| < π/4` — to the upper sector `|arg| ∈ (π/4, π/2]` where
`Im z` dominates — by taking the imaginary part to be the second-sector argument `CargUpper`
(`ComplexArgUpper.lean`). The real part is the same genuine modulus log `½·log|z|²` as the principal
`Clog`. Anchored by `Clog` of the imaginary unit: `Im (ClogUpper i) = π/2` (and `Re (ClogUpper i) =
½·log 1 = 0` after `log 1 = 0`).

`CargUpper` is the genuine argument here (`CargUpper_tan`: `tan(CargUpper z) = Im/Re`), so `ClogUpper`
is the genuine logarithm on the upper sector. Its additivity across sectors (the full-plane atan2) is
the following brick.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Analysis.ComplexLog
import Foundations.F1.Analysis.ComplexArgUpper

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The complex logarithm on the upper sector**: `ClogUpper z = ½·log|z|² + i·(π/2 − arctan(Re z /
    Im z))`. Witnesses: `kn` for `|z|² > 0`, `k` for `Im z > 0`, and `ρ`-bound for the argument
    ratio `Re z / Im z`. The extension of `Clog` past the principal sector `|arg| < π/4`. -/
def ClogUpper (z : Complex) (kn : Nat) (hkn : Qlt (Qbound kn) ((cnormSq z).seq kn))
    (k : Nat) (hk : Qlt (Qbound k) (z.im.seq k))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv z.re z.im k hk).seq n)) ρ) : Complex :=
  ⟨Rmul half (RlogPos (cnormSq z) kn hkn), CargUpper z k hk ρ hρ0 hρd hρlt hb⟩

/-- The real part of `ClogUpper z` is `½·log|z|²` (definitional) — the same modulus log as `Clog`. -/
theorem ClogUpper_re (z : Complex) (kn : Nat) (hkn : Qlt (Qbound kn) ((cnormSq z).seq kn))
    (k : Nat) (hk : Qlt (Qbound k) (z.im.seq k))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv z.re z.im k hk).seq n)) ρ) :
    (ClogUpper z kn hkn k hk ρ hρ0 hρd hρlt hb).re = Rmul half (RlogPos (cnormSq z) kn hkn) := rfl

/-- The imaginary part of `ClogUpper z` is the upper-sector argument `CargUpper z` (definitional). -/
theorem ClogUpper_im (z : Complex) (kn : Nat) (hkn : Qlt (Qbound kn) ((cnormSq z).seq kn))
    (k : Nat) (hk : Qlt (Qbound k) (z.im.seq k))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv z.re z.im k hk).seq n)) ρ) :
    (ClogUpper z kn hkn k hk ρ hρ0 hρd hρlt hb).im = CargUpper z k hk ρ hρ0 hρd hρlt hb := rfl

/-- **`Im (ClogUpper i) = π/2`** — the imaginary part of the logarithm of the imaginary unit is `π/2`,
    the upper-sector anchor (`log i = i·π/2`). From `Carg_I` (`arg(i) = π/2`). -/
theorem ClogUpper_I_im (kn : Nat) (hkn : Qlt (Qbound kn) ((cnormSq I).seq kn))
    (k : Nat) (hk : Qlt (Qbound k) (I.im.seq k))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv I.re I.im k hk).seq n)) ρ) :
    Req (ClogUpper I kn hkn k hk ρ hρ0 hρd hρlt hb).im Rpi_half :=
  Carg_I k hk ρ hρ0 hρd hρlt hb

end Multiplicity.UOR.Bridge.F1Square.Analysis
