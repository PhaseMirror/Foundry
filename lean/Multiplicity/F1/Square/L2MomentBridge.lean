/-
F1 square — **the pre-Hilbert layer, brick 63** (`L2MomentBridge.lean`): **THE MOMENT GEOMETRY IS
AN L² INVARIANT** — the compatibility law between the two energies the layer now carries, the
function-space `⟨φ,φ⟩ = ∫₀¹ φ²` (bricks 9–14) and the `ℓ²` moment energy `‖φ̂‖²` (bricks 40–61):

    `⟨φ,φ⟩ ≈ 0   ⟹   every moment vanishes   ⟹   ‖φ̂‖² ≈ 0`
      (`moments_zero_of_innerI_self_zero`, `momentL2Sq_zero_of_innerI_self_zero`)
    `d²(φ,ψ) ≈ 0   ⟹   ⟨φ,xⁿ⟩ ≈ ⟨ψ,xⁿ⟩ ∀n   ⟹   ‖φ̂‖² ≈ ‖ψ̂‖²`
      (`mellinMoment_congr_of_dist2I`, `momentL2Sq_congr_of_dist2I`)

so the entire moment geometry — the moments, the `ℓ²` energy, and with brick 47 everything built
from them — **descends to the L² quotient**: it is a function of the L² class of a test, not of
the representative. That is exactly the compatibility the completion axis needs, since brick 62's
extended pairing is indexed by L²-Cauchy sequences while bricks 40–61 live on moment sequences.

Nothing new is constructed. The engine is brick 9's integral Cauchy–Schwarz supplying
`⟨φ,xⁿ⟩² ≤ ⟨φ,φ⟩·⟨xⁿ,xⁿ⟩`, fed through brick 61's square-root-free vanishing step: a bound by
zero on a square forces the root to vanish, with no root extracted. The same step makes the
L²-null tests a radical (`innerI_zero_of_innerI_self_zero`) — they pair to zero against
everything — mirroring brick 61's `crossMomL2_zero_of_null` one layer down.

The containment runs **one way only**, and that is the honest content: L²-null ⟹ moment-null. The
converse is the determinacy question (a nonzero test all of whose moments vanish), and this brick
does not touch it. The capstone reads the implication backwards on a built test: `deep3` has
certified nonzero *moment* energy (brick 45), hence certified nonzero *L²* energy
(`innerI_deep3_self_not_zero`) — the moment side proving something about the integral.

HONEST SCOPE. A one-way invariance law between two energies on the bounded-Lipschitz class on
`[0,1]`. Determinacy stays open; nothing here touches the Weil form. Step 4 is RH. The crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MomentDefinite
import Multiplicity.F1.Square.MomentInvariant
import Multiplicity.F1.Square.L2Complete

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `a − b ≈ 0 ⟹ a ≈ b`. -/
private theorem Req_of_Rsub_zero {a b : Real} (h : Req (Rsub a b) zero) : Req a b :=
  Req_trans (Req_symm (Radd_Rsub_cancel a b))
    (Req_trans (Radd_congr (Req_refl b) h) (Radd_zero b))

/-- A real that is squeezed below zero and above zero by its own square vanishes. -/
private theorem Req_zero_of_sq_le_zero {x : Real} (h : Rle (Rmul x x) zero) : Req x zero :=
  Req_zero_of_sq_zero x (Rle_antisymm h (Rle_zero_of_Rnonneg (Rnonneg_Rmul_self x)))

-- ===========================================================================
-- The L² null space is a radical, and it kills the moments.
-- ===========================================================================

/-- **AN L²-NULL TEST PAIRS TO ZERO WITH EVERYTHING**: `⟨φ,φ⟩ ≈ 0 ⟹ ⟨φ,ψ⟩ ≈ 0` — the L² mirror
    of brick 61's `crossMomL2_zero_of_null`, by the integral Cauchy–Schwarz and the same
    square-root-free vanishing step. -/
theorem innerI_zero_of_innerI_self_zero (φ ψ : L2Test) (h : Req (innerI φ φ) zero) :
    Req (innerI φ ψ) zero := by
  refine Req_zero_of_sq_le_zero ?_
  refine Rle_trans (innerI_cauchy_schwarz φ ψ) (Rle_of_Req ?_)
  exact Req_trans (Rmul_congr h (Req_refl (innerI ψ ψ)))
    (Req_trans (Rmul_comm zero (innerI ψ ψ)) (Rmul_zero (innerI ψ ψ)))

/-- **AN L²-NULL TEST HAS NO MOMENTS**: `⟨φ,φ⟩ ≈ 0 ⟹ ⟨φ, xⁿ⟩ ≈ 0` for every `n`. -/
theorem moments_zero_of_innerI_self_zero (φ : L2Test) (h : Req (innerI φ φ) zero) (n : Nat) :
    Req (mellinMoment φ n) zero :=
  innerI_zero_of_innerI_self_zero φ (powTest n) h

/-- **THE L² ENERGY DOMINATES THE `ℓ²` MOMENT ENERGY AT ZERO**: `⟨φ,φ⟩ ≈ 0 ⟹ ‖φ̂‖² ≈ 0`. The
    containment L²-null ⊆ moment-null; the converse is determinacy, and is NOT claimed. -/
theorem momentL2Sq_zero_of_innerI_self_zero (φ : L2Test) (h : Req (innerI φ φ) zero) :
    Req (momentL2Sq φ) zero :=
  momentL2Sq_zero_of_moments φ (moments_zero_of_innerI_self_zero φ h)

-- ===========================================================================
-- The moment data descends to the L² quotient.
-- ===========================================================================

/-- **THE MOMENTS ARE AN L² INVARIANT**: tests at L² distance zero have the same moments. -/
theorem mellinMoment_congr_of_dist2I (φ ψ : L2Test) (h : Req (dist2I φ ψ) zero) (n : Nat) :
    Req (mellinMoment φ n) (mellinMoment ψ n) := by
  refine Req_of_Rsub_zero ?_
  refine Req_trans (Req_symm (innerI_sub_left φ ψ (powTest n))) ?_
  exact moments_zero_of_innerI_self_zero (L2Test.sub φ ψ) h n

/-- **THE `ℓ²` MOMENT ENERGY IS AN L² INVARIANT** — through brick 47, which makes the energy
    depend on the moments alone. -/
theorem momentL2Sq_congr_of_dist2I (φ ψ : L2Test) (h : Req (dist2I φ ψ) zero) :
    Req (momentL2Sq φ) (momentL2Sq ψ) :=
  momentL2Sq_congr (mellinMoment_congr_of_dist2I φ ψ h)

/-- **THE CO-SUPPORT CONDITION IS AN L² INVARIANT**: vanishing of the moments below a depth
    transfers across L² distance zero, so the filtration levels are unions of L² classes. -/
theorem moments_vanish_congr_of_dist2I (φ ψ : L2Test) (h : Req (dist2I φ ψ) zero) (K : Nat)
    (hK : ∀ n : Nat, n < K → Req (mellinMoment φ n) zero) :
    ∀ n : Nat, n < K → Req (mellinMoment ψ n) zero :=
  fun n hn => Req_trans (Req_symm (mellinMoment_congr_of_dist2I φ ψ h n)) (hK n hn)

-- ===========================================================================
-- The capstone: the moment side certifies an integral.
-- ===========================================================================

/-- `0` is not strictly positive (local: the copy in `LambdaGap` is off this import chain). -/
private theorem zero_not_Pos' : ¬ Pos zero := by
  intro ⟨n, hn⟩
  simp only [Qlt, Qbound, zero_seq] at hn
  omega

/-- **THE MOMENT SIDE CERTIFIES AN INTEGRAL**: `∫₀¹ deep3² ` is apart from zero. Brick 45
    certified `Pos (momentL2Sq deep3)` from the exact rational third moment `−1/2520`; the
    containment above turns that into a statement about the L² energy of the constructed test —
    a fact about a certified integral, proved entirely on the moment side. -/
theorem innerI_deep3_self_not_zero : ¬ Req (innerI deep3 deep3) zero := fun h =>
  zero_not_Pos' (Pos_congr (momentL2Sq_zero_of_innerI_self_zero deep3 h) momentL2Sq_deep3_pos)

end Multiplicity.UOR.Bridge.F1Square.Square
