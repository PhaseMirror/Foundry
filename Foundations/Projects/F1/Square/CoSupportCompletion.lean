/-
F1 square — **the pre-Hilbert layer, brick 48** (`CoSupportCompletion.lean`): **THE SKELETON'S
POSITIVITY FIRES ON THE COMPLETED `ℓ²` MEMBER** — the co-support result moves off finite moment
data and onto the truncation-uniform limit object the completion axis constructs.

`weil_psd_on_cosupport` (brick 29) fires the skeleton's unconditional positivity on `momSeq φ`,
the moment sequence read as a coefficient family. Bricks 43–44 then built that sequence as a
genuine completion: the quadratically rescaled moment cuts are `SqCauchyU`, their truncation-
uniform limit member exists, and it *is* `momSeq φ`. This brick draws the consequence —

    `Rnonneg (weilQuad (multForm burnolMult) (limMemberU (momIdx φ) _) N)`
      (`weil_psd_on_completed_cosupport`)

for every `[0,1]`-supported test whose transform vanishes at `0, 1`, at every truncation `N`.
The band hypothesis is discharged, not assumed: the completed member's band coordinate is the
test's first moment (brick 44), and the co-support condition kills it
(`limMemberU_momIdx_band_zero`).

WHY IT IS NOT A RESTATEMENT. `sonine_complement_complete` (brick 16) already carried the
skeleton's positivity through a completion, but for a *fixed-truncation* limit member of an
abstract band-vanishing Cauchy family. Here the family is not abstract — it is the moment data
of a constructed test — the member is *truncation-uniform*, the convergence is strong at every
truncation (`momIdx_converges_to_momSeq`), and, crucially, the member is not the zero sequence:
`deep3` has `Pos (momentL2Sq deep3)` (brick 45), so `completed_cosupport_nonzero` records that
the positivity here fires on completed data of certified nonzero `ℓ²` energy.

HONEST SCOPE. Still the discrete diagonal-multiplier form on moment data — now at the completion
level. It is NOT the Weil functional on the test space, and NOT positivity beyond the
complement: that is step 4, which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MomentMember
import Foundations.F1.Square.MomentEnergyDetect
import Foundations.F1.Square.CoSupportWeld
import Foundations.F1.Square.DeepMemberFour

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The completed member's band coordinate vanishes**: it is the test's first moment (brick
    44), which the co-support condition kills. -/
theorem limMemberU_momIdx_band_zero (φ : L2Test) (hsupp : UnitSupported φ)
    (h : HatVanishes φ 2 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp φ hsupp)) :
    Req (limMemberU (momIdx φ) (momIdx_sqCauchyU φ) 1) zero :=
  Req_trans (limMemberU_momIdx φ 1)
    ((hatVanishes_iff_orthogonal φ 2 hsupp).mp h 1 (by decide))

/-- **THE SKELETON'S POSITIVITY ON THE COMPLETED `ℓ²` MEMBER**: for a `[0,1]`-supported test
    whose constructed transform vanishes at the integer points `0, 1`, the discrete Weil
    multiplier form is nonnegative on the truncation-uniform completed member of its moment
    cuts, at every truncation. Unconditional — no RH. -/
theorem weil_psd_on_completed_cosupport (φ : L2Test) (hsupp : UnitSupported φ)
    (h : HatVanishes φ 2 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp φ hsupp)) (N : Nat) :
    Rnonneg (weilQuad (multForm burnolMult)
      (limMemberU (momIdx φ) (momIdx_sqCauchyU φ)) N) :=
  burnol_pairing_psd_on_sonine _ N (limMemberU_momIdx_band_zero φ hsupp h)

/-- The `K = 3` member's completed instance. -/
theorem weil_psd_completed_deep3 (N : Nat) :
    Rnonneg (weilQuad (multForm burnolMult)
      (limMemberU (momIdx deep3) (momIdx_sqCauchyU deep3)) N) :=
  weil_psd_on_completed_cosupport deep3 deep3_supp
    (hatVanishes_mono (by decide) deep3_hatVanishes) N

/-- The `K = 4` member's completed instance. -/
theorem weil_psd_completed_deep4 (N : Nat) :
    Rnonneg (weilQuad (multForm burnolMult)
      (limMemberU (momIdx deep4) (momIdx_sqCauchyU deep4)) N) :=
  weil_psd_on_completed_cosupport deep4 deep4_supp
    (hatVanishes_mono (by decide) deep4_hatVanishes) N

/-- **THE COMPLETED DATA IS NOT THE ZERO SEQUENCE**: the member that `weil_psd_completed_deep3`
    fires on carries certified nonzero `ℓ²` moment energy (brick 45), so the completion-level
    positivity is not vacuous. -/
theorem completed_cosupport_nonzero : Pos (momentL2Sq deep3) := momentL2Sq_deep3_pos

/-- **STRONG CONVERGENCE TO THE COMPLETED CO-SUPPORT MEMBER**: the rescaled moment cuts of the
    `K = 3` member converge to it in the squared distance at every truncation — the completion
    is effective, not merely asserted. -/
theorem deep3_momIdx_converges (N j : Nat) :
    Rle (dist2 (momIdx deep3 j) (momSeq deep3) N)
      (ofQ (mul (⟨(N : Int), 1⟩ : Q) (mul (⟨2, j + 1⟩ : Q) (⟨2, j + 1⟩ : Q)))
        (Qmul_den_pos Nat.one_pos (Qmul_den_pos (Nat.succ_pos j) (Nat.succ_pos j)))) :=
  momIdx_converges_to_momSeq deep3 N j

end Multiplicity.UOR.Bridge.F1Square.Square
