/-
F1 square — v0.22.0 Track 1, brick (argument axis): **the left-half-plane argument** `CargLeft`
(`Re z < 0`), via the `+π` shift — the `Re z < 0` quadrants of the full-plane `atan2`.

For `Re z < 0`, `−z` lies in the right half-plane and `arg(z) = arg(−z) + π`. So
`CargLeft z = Carg(Cneg z) + π` (`Cneg z` has `Re > 0`, read by the principal `Carg`), carrying the
genuine tangent `tan(CargLeft z) = Im(−z)/Re(−z) = Im z/Re z` (`CargLeft_tan`, from the value identity
on `−z`'s ratio + the π-shift `sin(A+π) = −sin A`, `cos(A+π) = −cos A`, which use `sin π = 0`,
`cos π = −1`). Together with the principal `Carg`, `CargUpper`, and `CargLower`, the argument is now
defined over the whole punctured plane near the four axes.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Analysis.ComplexArgUpper

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The left-half-plane argument** `CargLeft z = arg(−z) + π` for `Re z < 0` (so `−z` has
    `Re > 0`). Witness `k` for `Re(−z) = −Re z > 0`. -/
def CargLeft (z : Complex) (k : Nat) (hk : Qlt (Qbound k) ((Cneg z).re.seq k))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv (Cneg z).im (Cneg z).re k hk).seq n)) ρ) : Real :=
  Radd (Carg (Cneg z) k hk ρ hρ0 hρd hρlt hb) Rpi_full

set_option maxHeartbeats 1200000 in
/-- **★ the left-half argument has the right tangent**: `tan(CargLeft z) = Im(−z)/Re(−z)` (`= Im z/Re z`):
    `sin(CargLeft z) = (Im(−z)/Re(−z))·cos(CargLeft z)`. From the value identity on `arg(−z)`'s ratio
    (`RarctanR_value_eq`, `Carg(−z) = RarctanR(Im(−z)/Re(−z))`) and the π-shift (`sin(A+π) = −sin A`,
    `cos(A+π) = −cos A`): `tan(A+π) = tan A`. Confirms `CargLeft` is the genuine left-sector argument. -/
theorem CargLeft_tan (z : Complex) (k : Nat) (hk : Qlt (Qbound k) ((Cneg z).re.seq k))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv (Cneg z).im (Cneg z).re k hk).seq n)) ρ)
    (hlt16 : (mul ⟨16, 1⟩ ρ).num.toNat < (mul ⟨16, 1⟩ ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩) :
    Req (Rsin (CargLeft z k hk ρ hρ0 hρd hρlt hb))
      (Rmul (Rdiv (Cneg z).im (Cneg z).re k hk) (Rcos (CargLeft z k hk ρ hρ0 hρd hρlt hb))) := by
  -- value identity on (−z)'s ratio: sin(Carg(−z)) = (ratio)·cos(Carg(−z))
  have hval := RarctanR_value_eq (Rdiv (Cneg z).im (Cneg z).re k hk) ρ hρ0 hρd hρlt hb
    hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1
  show Req (Rsin (Radd (Carg (Cneg z) k hk ρ hρ0 hρd hρlt hb) Rpi_full))
    (Rmul (Rdiv (Cneg z).im (Cneg z).re k hk)
      (Rcos (Radd (Carg (Cneg z) k hk ρ hρ0 hρd hρlt hb) Rpi_full)))
  refine Req_trans (Rsin_add_pi (Carg (Cneg z) k hk ρ hρ0 hρd hρlt hb)) ?_
  refine Req_trans (Rneg_congr hval) ?_
  refine Req_trans (Req_symm (Rmul_neg_right (Rdiv (Cneg z).im (Cneg z).re k hk)
    (Rcos (Carg (Cneg z) k hk ρ hρ0 hρd hρlt hb)))) ?_
  exact Rmul_congr (Req_refl _) (Req_symm (Rcos_add_pi (Carg (Cneg z) k hk ρ hρ0 hρd hρlt hb)))

end Multiplicity.UOR.Bridge.F1Square.Analysis
