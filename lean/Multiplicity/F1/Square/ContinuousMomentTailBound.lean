/-
F1 square — **the pre-Hilbert layer, brick 108** (`ContinuousMomentTailBound.lean`): **THE FLOOR
DEFECT DECAYS LIKE `1/2^m`** — the compact Mellin moment at `s = 1` with the DYADIC floor `1/2^m`
differs from the integer Mellin moment by at most `2·M_φ · (1/2^m)`:

    `|compactMoment φ (1/2^m) 1  −  mellinMoment φ 1|  ≤  2·M_φ · (1/2^m)`
      (`compactMomentOne_sub_mellin_bound`).

WHY (the Sonine route, step 3, the a→0 Mellin limit). Brick 106 pins the two integrands together on
`[1/2^m, 1]`, so their difference `φ·(compactPow − clamp)` VANISHES there and is bounded by `2·M_φ`
on `[0, 1/2^m)`. Feeding that difference — realized as `innerI φ (compactPowTest −ₜ powTest 1)`
through the second-slot subtraction `innerI_sub_right` — into the dyadic tail bound (brick 107)
converts "the integrands agree above the floor" into the quantitative `2·M_φ/2^m` defect. As the
depth `m → ∞` the floor `1/2^m → 0` and the defect vanishes: this is the `a → 0` limit made
quantitative, with an explicit modulus of convergence.

The two supporting facts:
- `innerI_sub_right` — the second-slot subtraction `⟨φ, χ − ψ⟩ ≈ ⟨φ,χ⟩ − ⟨φ,ψ⟩`, derived from the
  full symmetry `innerI_symm` and the first-slot `innerI_sub_left` (absent from the repo; three lines).
- On the tail `[1/2^m, 1]` the difference integrand is `≈ 0`: `compactPow (1/2^m) 1 ≈ clamp01`
  (brick 106) and `(powTest 1).f = one · clamp01 ≈ clamp01` (`Rone_mul`), so the two cancel.

HONEST SCOPE. A quantitative floor-defect bound at `s = 1`, on the compact side. NOT the transform
pair, NOT inversion, NOT the continuous parameter as a limit object yet (that is brick 109). The
crux fields stay `none`; step 4 is RH.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.ContinuousMomentClamp
import Multiplicity.F1Square.Square.IntegralTailBound
import Multiplicity.F1Square.Analysis.IntegralCertIrrel

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Second-slot subtraction of the L² pairing**: `⟨φ, χ − ψ⟩ ≈ ⟨φ,χ⟩ − ⟨φ,ψ⟩` — the mirror of
    `innerI_sub_left`, via the full symmetry `innerI_symm`. -/
theorem innerI_sub_right (φ χ ψ : L2Test) :
    Req (innerI φ (L2Test.sub χ ψ)) (Rsub (innerI φ χ) (innerI φ ψ)) :=
  Req_trans (innerI_symm φ (L2Test.sub χ ψ))
    (Req_trans (innerI_sub_left χ ψ φ)
      (Rsub_congr (innerI_symm χ φ) (innerI_symm ψ φ)))

/-- **The compact power test at `s = 1` with the dyadic floor `1/2^m`**, as an `L2Test`. -/
def compactPowTestOne (m : Nat) : L2Test :=
  compactPowTest (⟨1, 2 ^ m⟩ : Q) (by show (0:Int) < 1; decide) (two_pow_pos m) (s := one) Rnonneg_one
    (⟨1, 1⟩ : Q) (by decide) (by decide) (Rle_refl one)

/-- **The compact Mellin moment at `s = 1` with the dyadic floor `1/2^m`**: `∫₀¹ φ(t)·t¹ dt` totalized
    at floor `1/2^m` — `compactMoment φ (1/2^m) 1`, a certified constructive real. -/
def compactMomentOne (φ : L2Test) (m : Nat) : Real := innerI φ (compactPowTestOne m)

set_option maxHeartbeats 1600000 in
/-- **★ THE FLOOR DEFECT DECAYS LIKE `1/2^m`**: `|compactMoment φ (1/2^m) 1 − mellinMoment φ 1| ≤
    2·M_φ·(1/2^m)`. The difference of the two integer/continuous moments is `innerI φ` of the
    difference test (via `innerI_sub_right`); its integrand vanishes on the dyadic tail `[1/2^m,1]`
    (brick 106) and is bounded by `2·M_φ` throughout, so the dyadic tail bound (brick 107) gives the
    geometric decay. -/
theorem compactMomentOne_sub_mellin_bound (φ : L2Test) (m : Nat) :
    Rle (Rabs (Rsub (compactMomentOne φ m) (mellinMoment φ 1)))
        (ofQ (mul (mul φ.M (⟨2, 1⟩ : Q)) (⟨1, 2 ^ m⟩ : Q))
          (Qmul_den_pos (Qmul_den_pos φ.hMd (by decide)) (two_pow_pos m))) := by
  have hale1 : Qle (⟨1, 2 ^ m⟩ : Q) (⟨1, 1⟩ : Q) := by
    have h1m : (1 : Nat) ≤ 2 ^ m := two_pow_pos m
    have hc : ((1 : Nat) : Int) ≤ ((2 ^ m : Nat) : Int) := Int.ofNat_le.mpr h1m
    simp only [Qle]
    omega
  -- The difference is `innerI φ (χ − ψ)`.
  have hdiff : Req (Rsub (compactMomentOne φ m) (mellinMoment φ 1))
      (innerI φ (L2Test.sub (compactPowTestOne m) (powTest 1))) :=
    Req_symm (innerI_sub_right φ (compactPowTestOne m) (powTest 1))
  -- The difference test is bounded by `2` (its `M` is `⟨2,1⟩`).
  have hsubbd : ∀ x, Rle (Rabs ((L2Test.sub (compactPowTestOne m) (powTest 1)).f x))
      (ofQ (⟨2, 1⟩ : Q) (by decide)) :=
    fun x => (L2Test.sub (compactPowTestOne m) (powTest 1)).hbd x
  -- The product integrand is bounded by `2·M_φ` everywhere.
  have hbd_prod : ∀ x, Rle (Rabs (Rmul (φ.f x)
      ((L2Test.sub (compactPowTestOne m) (powTest 1)).f x)))
      (ofQ (mul φ.M (⟨2, 1⟩ : Q)) (Qmul_den_pos φ.hMd (by decide))) := by
    intro x
    refine Rle_trans (Rle_of_Req (Rabs_Rmul (φ.f x) _)) ?_
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs _) (φ.hbd x)) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ φ.hMd φ.hMn) (hsubbd x)) ?_
    exact Rle_of_Req (Rmul_ofQ_ofQ φ.hMd (by decide))
  -- The product integrand vanishes on the dyadic tail `[1/2^m, 1]`.
  have htail_prod : ∀ x, Rle (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m)) x → Rle x one →
      Req (Rmul (φ.f x) ((L2Test.sub (compactPowTestOne m) (powTest 1)).f x)) zero := by
    intro x hx0 hx1
    have hc : Req ((compactPowTestOne m).f x) (clampTest.f x) :=
      compactPow_one_eq_clamp (⟨1, 2 ^ m⟩ : Q) (by show (0:Int) < 1; decide) (two_pow_pos m) hale1 x hx0 hx1
    have hp : Req ((powTest 1).f x) (clampTest.f x) := Rone_mul (clampTest.f x)
    have hsub0 : Req ((L2Test.sub (compactPowTestOne m) (powTest 1)).f x) zero :=
      Req_trans (Radd_congr hc (Rneg_congr hp)) (Radd_neg (clampTest.f x))
    exact Req_trans (Rmul_congr (Req_refl _) hsub0) (Rmul_zero (φ.f x))
  -- Apply the dyadic tail bound to `innerI φ (χ − ψ)`.
  have htb := riemannIntegral_dyadic_tail_bound (mul φ.M (⟨2, 1⟩ : Q))
    (Qmul_den_pos φ.hMd (by decide)) (Qmul_num_nonneg φ.hMn (by decide)) m
    (fun x => Rmul (φ.f x) ((L2Test.sub (compactPowTestOne m) (powTest 1)).f x))
    (l2L φ (L2Test.sub (compactPowTestOne m) (powTest 1)))
    (l2L_den φ (L2Test.sub (compactPowTestOne m) (powTest 1)))
    (l2L_num φ (L2Test.sub (compactPowTestOne m) (powTest 1)))
    (l2lip φ (L2Test.sub (compactPowTestOne m) (powTest 1)))
    (l2fc φ (L2Test.sub (compactPowTestOne m) (powTest 1)))
    hbd_prod htail_prod
  exact Rle_trans (Rle_of_Req (Rabs_congr hdiff)) htb

end Multiplicity.UOR.Bridge.F1Square.Square
