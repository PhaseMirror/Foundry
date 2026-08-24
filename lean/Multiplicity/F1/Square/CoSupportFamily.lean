/-
F1 square — **the pre-Hilbert layer, brick 58** (`CoSupportFamily.lean`): **THE POSITIVITY FIRES
ON AN INFINITE FAMILY OF NONZERO CO-SUPPORT MEMBERS** — bricks 29 and 48 fired the skeleton's
unconditional positivity at single constructed members; brick 57 made the levels linear
subspaces; this brick draws the consequence at the whole realized family at once.

For every `a, b, c : ℕ` the combination `combo345 a b c = a·deep3 + b·deep4 + c·deep5` lies in
level `3`, so:

    `Rnonneg (weilQuad (multForm burnolMult) (momSeq (combo345 a b c)) N)`
      (`combo345_weil_psd`)
    `Rnonneg (weilQuad (multForm burnolMult) (limMemberU (momIdx (combo345 a b c)) _) N)`
      (`combo345_weil_psd_completed`)

at every truncation — the second at the truncation-uniform *completed* `ℓ²` member.

The family is not vacuous, and it is not vacuous uniformly: whenever `a ≥ 1` the member carries
strictly positive moment energy (`combo345_energy_pos`), because brick 55's table reads the
third moment off the first coefficient exactly — `⟨combo345 a b c, x³⟩ = −a/2520` — and brick 45
turns a nonzero moment into `Pos` energy. So the positivity above fires on infinitely many
genuinely nonzero members, indexed faithfully by `a`, and not on a family that might collapse to
the zero sequence.

HONEST SCOPE. Still the discrete diagonal-multiplier form on moment data, now over a realized
infinite family rather than single instances. It is NOT the Weil functional on the test space,
and NOT positivity beyond the complement — that is step 4, which is RH. The crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.CoSupportSubspace
import Multiplicity.F1.Square.CoSupportCompletion
import Multiplicity.F1.Square.MomentEnergyDetect

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The skeleton's positivity on the whole level-3 family**, at every truncation. -/
theorem combo345_weil_psd (a b c : Nat) (N : Nat) :
    Rnonneg (weilQuad (multForm burnolMult) (momSeq (combo345 a b c)) N) :=
  weil_psd_on_cosupport (combo345 a b c) (combo345_supp a b c)
    (hatVanishes_mono (by decide) (combo345_in_level_three a b c)) N

/-- **The same at the completion level**: on the truncation-uniform completed `ℓ²` member of
    each family element. -/
theorem combo345_weil_psd_completed (a b c : Nat) (N : Nat) :
    Rnonneg (weilQuad (multForm burnolMult)
      (limMemberU (momIdx (combo345 a b c)) (momIdx_sqCauchyU (combo345 a b c))) N) :=
  weil_psd_on_completed_cosupport (combo345 a b c) (combo345_supp a b c)
    (hatVanishes_mono (by decide) (combo345_in_level_three a b c)) N

/-- The family member's third squared moment is `a²/6350400`. -/
theorem combo345_moment_three_sq (a b c : Nat) :
    Req (Rmul (mellinMoment (combo345 a b c) 3) (mellinMoment (combo345 a b c) 3))
      (ofQ (⟨(a : Int) * (a : Int), 6350400⟩ : Q) (by show (0:Nat) < 6350400; decide)) := by
  refine Req_trans (Rmul_congr (combo345_moment_three a b c)
    (combo345_moment_three a b c)) ?_
  refine Req_trans (Rmul_ofQ_ofQ (by show (0:Nat) < 2520; decide)
    (by show (0:Nat) < 2520; decide)) ?_
  refine ofQ_congr _ (by show (0:Nat) < 6350400; decide) ?_
  show Qeq (mul (⟨-(a : Int), 2520⟩ : Q) (⟨-(a : Int), 2520⟩ : Q))
    (⟨(a : Int) * (a : Int), 6350400⟩ : Q)
  simp only [Qeq, mul]
  push_cast
  ring_uor

/-- **THE FAMILY IS NONZERO WHEREVER `a ≥ 1`**: the member carries strictly positive moment
    energy, because its third moment is `−a/2520 ≠ 0` and brick 45 turns a nonzero moment into
    `Pos` energy. -/
theorem combo345_energy_pos (a b c : Nat) (ha : 1 ≤ a) :
    Pos (momentL2Sq (combo345 a b c)) := by
  refine momentL2Sq_pos_of_moment (combo345 a b c) 3 ?_
  refine Pos_congr (Req_symm (combo345_moment_three_sq a b c)) ?_
  refine Pos_of_Rle_ofQ (c := (⟨1, 6350400⟩ : Q)) (by decide)
    (by show (0:Nat) < 6350400; decide) ?_
  refine Rle_ofQ_ofQ (by show (0:Nat) < 6350400; decide)
    (by show (0:Nat) < 6350400; decide) ?_
  show (1 : Int) * ((6350400 : Nat) : Int)
      ≤ (a : Int) * (a : Int) * ((6350400 : Nat) : Int)
  have ha' : (1 : Int) ≤ (a : Int) := by exact_mod_cast ha
  have haa : (1 : Int) * 1 ≤ (a : Int) * (a : Int) :=
    Int.mul_le_mul ha' ha' (by decide) (by omega)
  have hc : (0 : Int) ≤ ((6350400 : Nat) : Int) := Int.ofNat_nonneg _
  have hstep : 1 * ((6350400 : Nat) : Int)
      ≤ ((a : Int) * (a : Int)) * ((6350400 : Nat) : Int) :=
    Int.mul_le_mul_of_nonneg_right (by omega) hc
  omega

end Multiplicity.UOR.Bridge.F1Square.Square
