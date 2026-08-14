/-
F1 square — **the pre-Hilbert layer, brick 47** (`MomentInvariant.lean`): **THE MOMENT ENERGY IS
A MOMENT-INVARIANT** — `momentL2Sq φ` depends only on the moment sequence, not on the particular
test that produced it:

    `(∀ n, ⟨φ, xⁿ⟩ ≈ ⟨ψ, xⁿ⟩)  ⟹  momentL2Sq φ ≈ momentL2Sq ψ`   (`momentL2Sq_congr`).

This is the well-definedness the `ℓ²` norm needs to be a norm *on the moment sequence* rather than
an artifact of the construction: the norm was built through an index rescale keyed to the test's
own bound `M_φ` (`momScale φ`), and a priori two tests with the same moments but different `M`
read their limits along different schedules. This brick shows the value is the same regardless —
the rescale is scaffolding, not content.

The proof is brick 45 used both ways. Equal moments give equal partial energies
(`momentSqSum_congr`, one `RsumN_congr`), so each rescaled read of `φ`'s energy equals a partial
energy of `ψ`'s, which brick 45 bounds by `momentL2Sq ψ`; `Rlim_le_const` then gives
`momentL2Sq φ ≤ momentL2Sq ψ`, and symmetry closes the equality. The capstone adds a second
certified nonzero energy: `bumpU = x(1−x)` has zeroth moment `1/6`, so `Pos (momentL2Sq bumpU)`.

HONEST SCOPE. Well-definedness of the `ℓ²` moment energy for bounded-Lipschitz tests on `[0,1]`,
nothing about the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.MomentEnergyDetect
import Multiplicity.F1Square.Square.CoSupportMember

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- Equal moments give equal partial energies. -/
theorem momentSqSum_congr {φ ψ : L2Test}
    (h : ∀ n, Req (mellinMoment φ n) (mellinMoment ψ n)) (N : Nat) :
    Req (momentSqSum φ N) (momentSqSum ψ N) :=
  RsumN_congr N (fun n _ => Rmul_congr (h n) (h n))

/-- One direction of the invariance: equal moments make `φ`'s energy `≤ ψ`'s energy. -/
theorem momentL2Sq_le_of_moments_eq {φ ψ : L2Test}
    (h : ∀ n, Req (mellinMoment φ n) (mellinMoment ψ n)) :
    Rle (momentL2Sq φ) (momentL2Sq ψ) :=
  Rlim_le_const (momentSqIdx_RReg φ) (fun k =>
    Rle_trans (Rle_of_Req (momentSqSum_congr h (momScale φ * (k + 1))))
      (momentSqSum_le_momentL2Sq ψ (momScale φ * (k + 1))))

/-- **THE MOMENT ENERGY IS A MOMENT-INVARIANT**: tests with the same moments have the same
    `ℓ²` energy, whatever their individual bounds `M`. -/
theorem momentL2Sq_congr {φ ψ : L2Test}
    (h : ∀ n, Req (mellinMoment φ n) (mellinMoment ψ n)) :
    Req (momentL2Sq φ) (momentL2Sq ψ) :=
  Rle_antisymm (momentL2Sq_le_of_moments_eq h)
    (momentL2Sq_le_of_moments_eq (fun n => Req_symm (h n)))

/-- **A SECOND CERTIFIED NONZERO ENERGY**: `bumpU = x(1−x)` has `⟨bumpU, x⁰⟩ = 1/6`, so its
    moment energy is apart from zero. -/
theorem momentL2Sq_bumpU_pos : Pos (momentL2Sq bumpU) := by
  refine momentL2Sq_pos_of_moment bumpU 0 ?_
  have hval : Req (Rmul (mellinMoment bumpU 0) (mellinMoment bumpU 0))
      (ofQ (⟨1, 36⟩ : Q) (by decide)) := by
    refine Req_trans (Rmul_congr mellinMoment_bumpU mellinMoment_bumpU) ?_
    refine Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) ?_
    exact ofQ_congr (by decide) (by decide) (by decide)
  exact Pos_congr (Req_symm hval)
    (Pos_of_Rle_ofQ (c := (⟨1, 36⟩ : Q)) (by decide) (by decide) (Rle_refl _))

end Multiplicity.UOR.Bridge.F1Square.Square
