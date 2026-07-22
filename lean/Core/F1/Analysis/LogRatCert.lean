/-
F1 square — **the `∫ log` layer, part 2c(i): the uniform small-radius certificate**
(`LogRatCert.lean`). The log-of-rational bridge (`RlogPos(ofQ q) ≈ logN a − logN d` for
`q = a/d`) runs through `RlogPos_eq_Rlog` at the presented modulus `B = q`, whose
small-radius certificate is

    `1/2 ≤ 1 − ρ²`,  `ρ = (a − d)/(a + d)`   ⟺   `2(a−d)² ≤ (a+d)²`.

The dyadic samples of `∫₀¹ log(c+t)` are `q = (c(N+1)+j)/(N+1) ∈ [1, c+1] ⊆ [1, 4]`
(`c ≤ 3`), UNBOUNDED in numerator and denominator separately — so the certificate must be
proven GENERAL in `a, d` from the band `d ≤ a ≤ 4d` alone. The witness identity is

    `(a+d)² − 2(a−d)² = (4d − a)(a − d) + ad + 3d²`      (each summand `≥ 0` on the band)

— kernel-checked by `ring_uor` plus `Int.mul_nonneg`, no `decide`, no bound on the size of
`a, d`. (`a ≤ 4d` is sharp-ish: at `a = 6d` the certificate fails — the presented-radius
design caps the band at `B ≤ 4`, which is exactly why the `gLog` instances stop at `c = 3`.)

HONEST SCOPE. A certificate factory for part 2c's bridge; no integral, no positivity claim.
The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ClampedInv

namespace UOR.Bridge.F1Square.Analysis

/-- The integer witness: `(A+D)² ≤ 2((A+D)² − (A−D)²)` on the band `D ≤ A ≤ 4D`
    (via `(A+D)² − 2(A−D)² = (4D−A)(A−D) + AD + 3D² ≥ 0`). -/
private theorem int_radius_key (A D : Int) (hD : 0 < D) (hDA : D ≤ A) (hA4 : A ≤ 4 * D) :
    (A + D) * (A + D) ≤ 2 * ((A + D) * (A + D) - (A - D) * (A - D)) := by
  have key : (A + D) * (A + D) - 2 * ((A - D) * (A - D))
      = (4 * D - A) * (A - D) + A * D + 3 * (D * D) := by ring_uor
  have h1 : 0 ≤ (4 * D - A) * (A - D) := Int.mul_nonneg (by omega) (by omega)
  have h2 : 0 ≤ A * D := Int.mul_nonneg (by omega) (by omega)
  have h3 : 0 ≤ D * D := Int.mul_nonneg (by omega) (by omega)
  omega

/-- **The uniform small-radius certificate**, general in the sample: for natural `d ≤ a ≤ 4d`
    (`0 < d`), the presented radius `ρ = (a−d)/(a+d)` of `B = a/d` satisfies `1/2 ≤ 1 − ρ²` —
    in the exact shape `RlogPos_eq_Rlog`/`RlogPos_congr` consume for
    `B = ⟨(a : Int), d⟩`. -/
theorem radius_half_of_le4 (a d : Nat) (hd : 0 < d) (hda : d ≤ a) (ha4 : a ≤ 4 * d) :
    Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩
      (mul ⟨((a : Nat) : Int) - ((d : Nat) : Int), a + d⟩
           ⟨((a : Nat) : Int) - ((d : Nat) : Int), a + d⟩)) := by
  show (1 : Int) * ((1 * ((a + d) * (a + d)) : Nat) : Int)
    ≤ ((1 : Int) * (((a + d) * (a + d) : Nat) : Int)
        + -((((a : Nat) : Int) - ((d : Nat) : Int)) * (((a : Nat) : Int) - ((d : Nat) : Int))) * 1) * 2
  have hkey := int_radius_key ((a : Nat) : Int) ((d : Nat) : Int)
    (by exact_mod_cast hd) (by exact_mod_cast hda) (by push_cast; omega)
  push_cast
  push_cast at hkey
  omega

/-- The certificate at the `gLog` bases' band shape `B = ⟨(a : Int), d⟩` with the
    `B.num.toNat + B.den` denominator (the literal projection form the `Rlog` lemmas
    state). -/
theorem radius_half_proj (a d : Nat) (hd : 0 < d) (hda : d ≤ a) (ha4 : a ≤ 4 * d) :
    Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩
      (mul ⟨(⟨((a : Nat) : Int), d⟩ : Q).num - ((⟨((a : Nat) : Int), d⟩ : Q).den : Int),
            (⟨((a : Nat) : Int), d⟩ : Q).num.toNat + (⟨((a : Nat) : Int), d⟩ : Q).den⟩
           ⟨(⟨((a : Nat) : Int), d⟩ : Q).num - ((⟨((a : Nat) : Int), d⟩ : Q).den : Int),
            (⟨((a : Nat) : Int), d⟩ : Q).num.toNat + (⟨((a : Nat) : Int), d⟩ : Q).den⟩)) := by
  have h : (⟨((a : Nat) : Int), d⟩ : Q).num.toNat = a := Int.toNat_ofNat a
  show Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩
    (mul ⟨((a : Nat) : Int) - ((d : Nat) : Int), (⟨((a : Nat) : Int), d⟩ : Q).num.toNat + d⟩
         ⟨((a : Nat) : Int) - ((d : Nat) : Int), (⟨((a : Nat) : Int), d⟩ : Q).num.toNat + d⟩))
  rw [h]
  exact radius_half_of_le4 a d hd hda ha4

/-- **The samples sit on the band**: `1 ≤ q ≤ B` for `q = ⟨a, d⟩` with `d ≤ a`,
    `a ≤ (c+1)·d` — the `hqge` side. -/
theorem sample_ge_one (a d : Nat) (hda : d ≤ a) :
    Qle (⟨1, 1⟩ : Q) (⟨((a : Nat) : Int), d⟩ : Q) := by
  show (1 : Int) * ((d : Nat) : Int) ≤ ((a : Nat) : Int) * 1
  push_cast; omega

end UOR.Bridge.F1Square.Analysis
