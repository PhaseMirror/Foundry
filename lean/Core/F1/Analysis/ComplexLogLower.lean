/-
F1 square — Track 1, item-0 brick (argument axis): **the complex logarithm on the lower sector**
`ClogLower z = ½·log|z|² + i·CargLower z`, for `Im z < 0` and `|Re z / Im z| ≤ ρ < 1` — the conjugate
reflection of `ClogUpper`, completing the four-sector complex logarithm.

The principal `Clog` (`ComplexLog.lean`) covers `Re z > 0, |arg| < π/4`; `ClogUpper`
(`ComplexLogUpper.lean`) the upper sector `arg ∈ (π/4, π/2]`. ξ's zeros come in conjugate pairs, so the
logarithm is needed below the real axis too (the lower sector `arg ∈ [−π/2, −π/4)`, `−Im z` dominating).
Its imaginary part is the genuine lower-sector argument `CargLower` (`ComplexArgLower.lean`,
`CargLower_tan : tan(CargLower z) = Im/Re`); its real part is the same modulus log `½·log|z|²` as the
principal `Clog`.

The characterization `ClogLower z = conj(ClogUpper z̄)` (`ClogLower_eq_conj_ClogUpper`) is the
`log(z̄) = conj(log z)` relation specialized to the sector swap: the imaginary part is definitional
(`CargLower z = −CargUpper z̄`), and the modulus part `½·log|z|² = ½·log|z̄|²` is carried as the same
cheap `hre` congruence `ClogConj` uses (`|z̄|² = |z|²`, `cnormSq_Cconj`, off the seam).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Core.F1.Analysis.ComplexLogUpper
import Core.F1.Analysis.ComplexArgLower

namespace UOR.Bridge.F1Square.Analysis

/-- **The complex logarithm on the lower sector**: `ClogLower z = ½·log|z|² + i·CargLower z`, for
    `Im z < 0` (witness `k` for `(z̄).im = −Im z > 0`) and `|Re z / Im z| ≤ ρ < 1`. The conjugate
    reflection of `ClogUpper`, extending `Clog` below the real axis near the imaginary axis. -/
def ClogLower (z : Complex) (kn : Nat) (hkn : Qlt (Qbound kn) ((cnormSq z).seq kn))
    (k : Nat) (hk : Qlt (Qbound k) ((Cconj z).im.seq k))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv (Cconj z).re (Cconj z).im k hk).seq n)) ρ) : Complex :=
  ⟨Rmul half (RlogPos (cnormSq z) kn hkn), CargLower z k hk ρ hρ0 hρd hρlt hb⟩

/-- The real part of `ClogLower z` is `½·log|z|²` (definitional) — the same modulus log as `Clog`. -/
theorem ClogLower_re (z : Complex) (kn : Nat) (hkn : Qlt (Qbound kn) ((cnormSq z).seq kn))
    (k : Nat) (hk : Qlt (Qbound k) ((Cconj z).im.seq k))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv (Cconj z).re (Cconj z).im k hk).seq n)) ρ) :
    (ClogLower z kn hkn k hk ρ hρ0 hρd hρlt hb).re = Rmul half (RlogPos (cnormSq z) kn hkn) := rfl

/-- The imaginary part of `ClogLower z` is the lower-sector argument `CargLower z` (definitional). -/
theorem ClogLower_im (z : Complex) (kn : Nat) (hkn : Qlt (Qbound kn) ((cnormSq z).seq kn))
    (k : Nat) (hk : Qlt (Qbound k) ((Cconj z).im.seq k))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv (Cconj z).re (Cconj z).im k hk).seq n)) ρ) :
    (ClogLower z kn hkn k hk ρ hρ0 hρd hρlt hb).im = CargLower z k hk ρ hρ0 hρd hρlt hb := rfl

/-- **`ClogLower z = conj(ClogUpper z̄)`** — the lower-sector log is the conjugate of the upper-sector
    log of `z̄` (the `log(z̄) = conj log z` relation across the sector swap). The imaginary part is
    definitional (`CargLower z = −CargUpper z̄`, matched by `Cconj`'s sign flip on `ClogUpper z̄`'s
    `CargUpper z̄`); the modulus part `½·log|z|² = ½·log|z̄|²` is the cheap `hre` congruence (`|z̄|² = |z|²`,
    `cnormSq_Cconj`), carried as a hypothesis exactly as `Clog_conj` does. -/
theorem ClogLower_eq_conj_ClogUpper (z : Complex)
    (kn : Nat) (hkn : Qlt (Qbound kn) ((cnormSq z).seq kn))
    (knc : Nat) (hknc : Qlt (Qbound knc) ((cnormSq (Cconj z)).seq knc))
    (k : Nat) (hk : Qlt (Qbound k) ((Cconj z).im.seq k))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv (Cconj z).re (Cconj z).im k hk).seq n)) ρ)
    (hre : Req (RlogPos (cnormSq z) kn hkn) (RlogPos (cnormSq (Cconj z)) knc hknc)) :
    Ceq (ClogLower z kn hkn k hk ρ hρ0 hρd hρlt hb)
        (Cconj (ClogUpper (Cconj z) knc hknc k hk ρ hρ0 hρd hρlt hb)) :=
  ⟨Rmul_congr (Req_refl half) hre, Req_refl _⟩

end UOR.Bridge.F1Square.Analysis
