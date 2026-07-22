/-
F1 square — Track 1, item 0 (the LARGE-argument end of the range extension): the constructive
arctangent at large argument `|t| ≥ 16`, via the complementary-angle reduction
`arctan(1/s) = π/2 − arctan s`, plus the real reflection identity `arctan s + arctan(1/s) = π/2`.

The small-argument arctangent `RarctanR s` (`RArctan.lean`) is defined only for `|s| ≤ ρ < 1/16`. When
`s` is that small, its reciprocal `1/s` (`≥ 16`) lies far outside the radius, so `RarctanR` cannot reach
it directly. The classical reflection identity `arctan(1/s) = π/2 − arctan(s)` supplies the value through
the complementary angle — sidestepping the `1 − s·(1/s) = 0` singularity that blocks the
tangent-addition route. We define `arctanExt s := π/2 − arctan s` and prove its value identity
`tan(arctanExt s) = 1/s`, the `tan∘arctan = id` law for the large-argument end.

This is the real-level abstraction of the reduction `ComplexArgUpper.CargUpper`/`CargUpper_tan` already
apply for the complex argument near the imaginary axis (same composition: `RarctanR_value_eq` +
`Rsin_cos_pi_half_sub_tan_real`); the genuinely-new piece here is the explicit *real* reflection identity
`RarctanR_add_RarctanExt` (`arctan s + arctan(1/s) = π/2`).

**Scope (honest):** this covers only the LARGE-argument end (`|t| ≥ 16`, where the reciprocal `1/t < 1/16`
re-enters the value-identity radius). The reciprocal reduction does NOT close the middle band
`1/16 < |t| < 16` (there `1/t` is also outside `1/16`), which remains the genuine open part of the *full*
argument-range extension `Carg`/`Clog` need toward `log ξ` — closing it needs either a larger
value-identity radius or an addition-law stepping argument through the band.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
The crux fields stay `none`; RH is open.
-/

import Core.F1.Analysis.RArctanValue
import Core.F1.Analysis.TanPiQuarter

namespace UOR.Bridge.F1Square.Analysis

/-- **The extended arctangent at a LARGE argument** `arctanExt s := π/2 − arctan s`. With `s` a small
    real in the value-identity radius (`|s| ≤ ρ < 1/16`), this is the arctangent of the reciprocal `1/s`
    — an argument outside the radius — reached through the complementary angle. The constructive `arctan`
    for `|t| ≥ 1`, the substrate `Carg`/`Clog` need beyond the principal sector. -/
def RarctanExt (s : Real) (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (hbs : ∀ n, Qle (Qabs (s.seq n)) ρ) : Real :=
  Rsub Rpi_half (RarctanR s ρ hρ0 hρd hlt hbs)

/-- `A + (B − A) ≈ B` (local angle arithmetic). -/
private theorem Radd_sub_self_comm (A B : Real) : Req (Radd A (Radd B (Rneg A))) B :=
  Req_trans (Radd_congr (Req_refl A) (Radd_comm B (Rneg A)))
    (Req_trans (Req_symm (Radd_assoc A (Rneg A) B))
      (Req_trans (Radd_congr (Radd_neg A) (Req_refl B))
        (Req_trans (Radd_comm zero B) (Radd_zero B))))

/-- **★ The value identity for the extended arctangent** `tan(arctanExt s) = 1/s`: if `T·s = 1` (so
    `T = 1/s` is the large reciprocal), then `sin(arctanExt s) = T·cos(arctanExt s)`. This is
    `tan∘arctan = id` at the LARGE-argument end (`|1/s| ≥ 16` when `|s| ≤ 1/16`). Composes the real
    value identity `RarctanR_value_eq` (`tan(arctan s) = s`) with the complementary-tangent formula
    `Rsin_cos_pi_half_sub_tan_real` (`tan(π/2 − A) = 1/tan A`). (The real-level form of the reduction
    `CargUpper_tan` applies for the complex argument; the middle band `1/16 < |t| < 16` is not covered.) -/
theorem RarctanExt_value_eq (s T : Real) (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt : ρ.num.toNat < ρ.den) (hbs : ∀ n, Qle (Qabs (s.seq n)) ρ)
    (hlt16 : (mul ⟨16, 1⟩ ρ).num.toNat < (mul ⟨16, 1⟩ ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩) (hTs : Req (Rmul T s) one) :
    Req (Rsin (RarctanExt s ρ hρ0 hρd hlt hbs))
        (Rmul T (Rcos (RarctanExt s ρ hρ0 hρd hlt hbs))) :=
  Rsin_cos_pi_half_sub_tan_real (RarctanR s ρ hρ0 hρd hlt hbs) s T
    (RarctanR_value_eq s ρ hρ0 hρd hlt hbs hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1) hTs

/-- **★ The complement identity** `arctan(s) + arctanExt(s) = π/2` — i.e. `arctan(s) + arctan(1/s) = π/2`,
    the classical reciprocal/reflection identity for arctangent, now a theorem of the constructive reals.
    Immediate from `arctanExt s = π/2 − arctan s` and angle arithmetic. -/
theorem RarctanR_add_RarctanExt (s : Real) (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt : ρ.num.toNat < ρ.den) (hbs : ∀ n, Qle (Qabs (s.seq n)) ρ) :
    Req (Radd (RarctanR s ρ hρ0 hρd hlt hbs) (RarctanExt s ρ hρ0 hρd hlt hbs)) Rpi_half :=
  Radd_sub_self_comm (RarctanR s ρ hρ0 hρd hlt hbs) Rpi_half

end UOR.Bridge.F1Square.Analysis
