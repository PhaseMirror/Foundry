/-
F1 square — **the pre-Hilbert layer, brick 59** (`MomentQuadratic.lean`): **THE MOMENT ENERGY IS
A QUADRATIC FORM, AND THE PAIRING IS ITS POLAR FORM** —

    `‖(φ+ψ)^‖² ≈ (‖φ̂‖² + ⟪φ,ψ⟫) + (⟪φ,ψ⟫ + ‖ψ̂‖²)`   (`momentL2Sq_add`)
    `‖(φ+ψ)^‖² + ‖(φ−ψ)^‖² ≈ (‖φ̂‖² + ‖ψ̂‖²) + (‖φ̂‖² + ‖ψ̂‖²)`   (`momentL2Sq_parallelogram`)

so the `ℓ²` moment energy of bricks 40–47 and the bilinear pairing of bricks 49–52, 56 are the
two faces of one object: the energy is the diagonal of the pairing (brick 49) and expands by the
pairing (here). That is exactly the structure a positivity argument acts on — a quadratic form
with a polar form — rather than two separately-constructed limits.

No new limit is constructed. Everything is derived from laws already in hand: the diagonal
identity `⟪φ,φ⟫ ≈ ‖φ̂‖²`, symmetry, and left-additivity, with symmetry supplying the right-slot
versions (`crossMomL2_add_right`, `crossMomL2_neg_right`). The parallelogram law then needs the
four cross terms `+X, +X, −X, −X` to cancel, which is an additive-group identity with
cancellation — precisely what the `RsumL` normalizer exists for, since `ring_uor` is `Int`/`Q`-only
and the pointwise `Req_of_seq_Qeq` route would clear denominators multiplicatively.

HONEST SCOPE. The quadratic-form laws for the `ℓ²` moment geometry of bounded-Lipschitz tests on
`[0,1]`. Nothing here touches the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.MomentPairingNeg
import Multiplicity.F1Square.Analysis.RAddNF

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The right-slot laws, from symmetry.
-- ===========================================================================

/-- **Additivity in the right slot**, from brick 50's symmetry. -/
theorem crossMomL2_add_right (φ ψ χ : L2Test) :
    Req (crossMomL2 φ (L2Test.add ψ χ))
      (Radd (crossMomL2 φ ψ) (crossMomL2 φ χ)) :=
  Req_trans (crossMomL2_symm φ (L2Test.add ψ χ))
    (Req_trans (crossMomL2_add_left ψ χ φ)
      (Radd_congr (crossMomL2_symm ψ φ) (crossMomL2_symm χ φ)))

/-- **Negation in the right slot**, from brick 50's symmetry. -/
theorem crossMomL2_neg_right (φ ψ : L2Test) :
    Req (crossMomL2 φ (L2Test.neg ψ)) (Rneg (crossMomL2 φ ψ)) :=
  Req_trans (crossMomL2_symm φ (L2Test.neg ψ))
    (Req_trans (crossMomL2_neg_left ψ φ) (Rneg_congr (crossMomL2_symm ψ φ)))

/-- The energy of a negated test is unchanged. -/
theorem momentL2Sq_neg (φ : L2Test) :
    Req (momentL2Sq (L2Test.neg φ)) (momentL2Sq φ) := by
  refine Req_trans (Req_symm (crossMomL2_diag (L2Test.neg φ))) ?_
  refine Req_trans (crossMomL2_neg_left φ (L2Test.neg φ)) ?_
  refine Req_trans (Rneg_congr (crossMomL2_neg_right φ φ)) ?_
  exact Req_trans (Rneg_neg (crossMomL2 φ φ)) (crossMomL2_diag φ)

-- ===========================================================================
-- The expansion law.
-- ===========================================================================

/-- **THE EXPANSION LAW**: the energy of a sum expands by the pairing —
    `‖(φ+ψ)^‖² ≈ (‖φ̂‖² + ⟪φ,ψ⟫) + (⟪φ,ψ⟫ + ‖ψ̂‖²)`. -/
theorem momentL2Sq_add (φ ψ : L2Test) :
    Req (momentL2Sq (L2Test.add φ ψ))
      (Radd (Radd (momentL2Sq φ) (crossMomL2 φ ψ))
            (Radd (crossMomL2 φ ψ) (momentL2Sq ψ))) := by
  refine Req_trans (Req_symm (crossMomL2_diag (L2Test.add φ ψ))) ?_
  refine Req_trans (crossMomL2_add_left φ ψ (L2Test.add φ ψ)) ?_
  refine Radd_congr ?_ ?_
  · -- `⟪φ, φ+ψ⟫ ≈ ‖φ̂‖² + ⟪φ,ψ⟫`
    exact Req_trans (crossMomL2_add_right φ φ ψ)
      (Radd_congr (crossMomL2_diag φ) (Req_refl _))
  · -- `⟪ψ, φ+ψ⟫ ≈ ⟪φ,ψ⟫ + ‖ψ̂‖²`
    refine Req_trans (crossMomL2_add_right ψ φ ψ) ?_
    exact Radd_congr (crossMomL2_symm ψ φ) (crossMomL2_diag ψ)

/-- **The difference expands with the sign flipped.** -/
theorem momentL2Sq_sub (φ ψ : L2Test) :
    Req (momentL2Sq (L2Test.sub φ ψ))
      (Radd (Radd (momentL2Sq φ) (Rneg (crossMomL2 φ ψ)))
            (Radd (Rneg (crossMomL2 φ ψ)) (momentL2Sq ψ))) := by
  refine Req_trans (momentL2Sq_add φ (L2Test.neg ψ)) ?_
  refine Radd_congr ?_ ?_
  · exact Radd_congr (Req_refl _) (crossMomL2_neg_right φ ψ)
  · exact Radd_congr (crossMomL2_neg_right φ ψ) (momentL2Sq_neg ψ)

-- ===========================================================================
-- The parallelogram law.
-- ===========================================================================

/-- The four-term cancellation `((A+X)+(X+B)) + ((A+(−X))+((−X)+B)) ≈ (A+B)+(A+B)`, discharged
    by the additive normalizer (the summands are permuted and the two `±X` pairs cancel). -/
private theorem quad_cancel (A B X : Real) :
    Req (Radd (Radd (Radd A X) (Radd X B)) (Radd (Radd A (Rneg X)) (Radd (Rneg X) B)))
      (Radd (Radd A B) (Radd A B)) := by
  -- flatten both sides through `RsumL_append`, built bottom-up from the binary pieces
  have f2 : ∀ u v : Real, Req (Radd u v) (RsumL [u, v]) := Radd_eq_RsumL
  have f4 : ∀ u v w z : Real,
      Req (Radd (Radd u v) (Radd w z)) (RsumL ([u, v] ++ [w, z])) := by
    intro u v w z
    refine Req_trans (Radd_congr (f2 u v) (f2 w z)) ?_
    exact Req_symm (RsumL_append [u, v] [w, z])
  have hL : Req (Radd (Radd (Radd A X) (Radd X B)) (Radd (Radd A (Rneg X)) (Radd (Rneg X) B)))
      (RsumL ([A, X, X, B] ++ [A, Rneg X, Rneg X, B])) := by
    refine Req_trans (Radd_congr (f4 A X X B) (f4 A (Rneg X) (Rneg X) B)) ?_
    exact Req_symm (RsumL_append [A, X, X, B] [A, Rneg X, Rneg X, B])
  have hR : Req (RsumL ([A, B] ++ [A, B])) (Radd (Radd A B) (Radd A B)) :=
    Req_trans (RsumL_append [A, B] [A, B]) (Req_symm (Radd_congr (f2 A B) (f2 A B)))
  refine Req_trans hL (Req_trans ?_ hR)
  show Req (RsumL [A, X, X, B, A, Rneg X, Rneg X, B]) (RsumL [A, B, A, B])
  -- no permutation is needed: `RsumL_cancel_anywhere` splits the list in place, twice
  refine Req_trans (RsumL_cancel_anywhere X [A] [X, B, A] [Rneg X, B]) ?_
  exact RsumL_cancel_anywhere X [A] [B, A] [B]


/-- **THE PARALLELOGRAM LAW** for the moment energy. -/
theorem momentL2Sq_parallelogram (φ ψ : L2Test) :
    Req (Radd (momentL2Sq (L2Test.add φ ψ)) (momentL2Sq (L2Test.sub φ ψ)))
      (Radd (Radd (momentL2Sq φ) (momentL2Sq ψ))
            (Radd (momentL2Sq φ) (momentL2Sq ψ))) :=
  Req_trans (Radd_congr (momentL2Sq_add φ ψ) (momentL2Sq_sub φ ψ))
    (quad_cancel (momentL2Sq φ) (momentL2Sq ψ) (crossMomL2 φ ψ))

end Multiplicity.UOR.Bridge.F1Square.Square
