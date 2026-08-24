/-
F1 square — **the pre-Hilbert layer, brick 61** (`MomentDefinite.lean`): **POLARIZATION AND THE
NULL SPACE** — the two facts that turn bricks 49–59's positive-semi-definite pairing into an
inner product with a *characterized* kernel:

    `⟪φ,ψ⟫ + ⟪φ,ψ⟫ + (⟪φ,ψ⟫ + ⟪φ,ψ⟫)  ≈  ‖(φ+ψ)^‖² − ‖(φ−ψ)^‖²`  (`momentL2Sq_polarization`)
    `‖φ̂‖² ≈ 0   ↔   ∀ n, ⟨φ, xⁿ⟩ ≈ 0`                             (`momentL2Sq_zero_iff`)

Polarization says the pairing carries no information the energy does not: the bilinear form is
recovered from its own diagonal, so bricks 40–47 and 49–59 are not two constructions but one
quadratic functional (brick 59 gave the forward expansion; this is its inverse). It is stated
multiplication-free — `4X` as `(X + X) + (X + X)` — since the substrate has no scalar action on
`Real`.

The null-space law is the direction brick 45 opened and never closed. Brick 42 gave
`all moments zero ⟹ energy zero`; the converse needs to pass from `x² ≈ 0` to `x ≈ 0` **without
extracting a square root**, which `Rle_of_Rsq_le` supplies: squaring reflects the order on the
non-negatives, so `|x|² ≤ 0·0` gives `|x| ≤ 0` outright, and `|x| ≥ 0` closes it by antisymmetry
(`Req_zero_of_sq_zero`). Cauchy–Schwarz (brick 51) then pushes the same step one step further:
a null test annihilates the *whole* space, `⟪φ,ψ⟫ ≈ 0` for every `ψ` (`crossMomL2_zero_of_null`),
so the null space is a genuine radical and the pairing descends to a definite form on the
quotient.

HONEST SCOPE. This CHARACTERIZES the null space as the moment-null tests; it does not show that
space is trivial. Whether a nonzero bounded-Lipschitz test on `[0,1]` can have every moment
vanish is the determinacy question, and it stays untouched here — as does everything about the
Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MomentQuadratic
import Multiplicity.F1.Square.MomentEnergyDetect
import Multiplicity.F1.Square.CoSupportEnergy
import Multiplicity.F1.Analysis.SqrtRealCmp

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The square-root-free vanishing step.
-- ===========================================================================

/-- **NO NILPOTENTS, WITHOUT A SQUARE ROOT**: `x² ≈ 0 ⟹ x ≈ 0`.

    The root is never extracted. `Rle_of_Rsq_le` reflects the order through squaring on the
    non-negatives, so `|x|·|x| ≈ 0 ≈ 0·0` already forces `|x| ≤ 0`; with `|x| ≥ 0` that pins
    `|x| ≈ 0`, and `−|x| ≤ x ≤ |x|` pins `x`. -/
theorem Req_zero_of_sq_zero (x : Real) (h : Req (Rmul x x) zero) : Req x zero := by
  -- `|x|² ≈ 0`
  have habs : Req (Rmul (Rabs x) (Rabs x)) zero :=
    Req_trans (Req_symm (Rabs_Rmul x x)) (Req_trans (Rabs_congr h) Rabs_zero)
  have hzz : Req (Rmul zero zero) zero := Rmul_zero zero
  have hsq : Rle (Rmul (Rabs x) (Rabs x)) (Rmul zero zero) :=
    Rle_of_Req (Req_trans habs (Req_symm hzz))
  have hle : Rle (Rabs x) zero := Rle_of_Rsq_le (Rnonneg_Rabs x) Rnonneg_zero hsq
  have hz : Req (Rabs x) zero := Rle_antisymm hle (Rle_zero_of_Rnonneg (Rnonneg_Rabs x))
  refine Rle_antisymm (Rle_trans (Rle_Rabs_self x) (Rle_of_Req hz)) ?_
  -- the lower side: `−x ≤ |−x| = |x| ≈ 0`, then flip
  have hneg : Rle (Rneg x) zero :=
    Rle_trans (Rle_Rabs_self (Rneg x))
      (Rle_of_Req (Req_trans (Rabs_Rneg x) hz))
  refine Rle_trans (Rle_of_Req (Req_symm Rneg_zero)) ?_
  exact Rle_trans (Rle_Rneg hneg) (Rle_of_Req (Rneg_neg x))

-- ===========================================================================
-- The null space.
-- ===========================================================================

/-- **A NULL ENERGY KILLS EVERY MOMENT**: the converse of brick 42's full-co-support law, via
    brick 45's `⟨φ,xⁿ⟩² ≤ ‖φ̂‖²`. -/
theorem moments_zero_of_momentL2Sq_zero (φ : L2Test) (h : Req (momentL2Sq φ) zero) (n : Nat) :
    Req (mellinMoment φ n) zero := by
  refine Req_zero_of_sq_zero (mellinMoment φ n) ?_
  refine Rle_antisymm ?_ (Rle_zero_of_Rnonneg (Rnonneg_Rmul_self (mellinMoment φ n)))
  exact Rle_trans (mellinMoment_sq_le_momentL2Sq φ n) (Rle_of_Req h)

/-- **THE NULL SPACE IS EXACTLY THE MOMENT-NULL TESTS.** -/
theorem momentL2Sq_zero_iff (φ : L2Test) :
    Req (momentL2Sq φ) zero ↔ ∀ n : Nat, Req (mellinMoment φ n) zero :=
  ⟨moments_zero_of_momentL2Sq_zero φ, momentL2Sq_zero_of_moments φ⟩

/-- **A NULL TEST ANNIHILATES THE WHOLE SPACE**: `‖φ̂‖² ≈ 0 ⟹ ⟪φ,ψ⟫ ≈ 0` for every `ψ`. So the
    null space is a radical, and the pairing descends to a definite form on the quotient. -/
theorem crossMomL2_zero_of_null (φ ψ : L2Test) (h : Req (momentL2Sq φ) zero) :
    Req (crossMomL2 φ ψ) zero := by
  refine Req_zero_of_sq_zero (crossMomL2 φ ψ) ?_
  refine Rle_antisymm ?_ (Rle_zero_of_Rnonneg (Rnonneg_Rmul_self (crossMomL2 φ ψ)))
  refine Rle_trans (crossMomL2_sq_le φ ψ) (Rle_of_Req ?_)
  refine Req_trans (Rmul_congr h (Req_refl (momentL2Sq ψ))) ?_
  exact Req_trans (Rmul_comm zero (momentL2Sq ψ)) (Rmul_zero (momentL2Sq ψ))

/-- Full co-support in the limit annihilates every pairing — the co-support form of the same
    statement, read through brick 42. -/
theorem crossMomL2_zero_of_moments (φ ψ : L2Test)
    (h : ∀ n : Nat, Req (mellinMoment φ n) zero) : Req (crossMomL2 φ ψ) zero :=
  crossMomL2_zero_of_null φ ψ (momentL2Sq_zero_of_moments φ h)

-- ===========================================================================
-- Polarization.
-- ===========================================================================

/-- Negation distributed through the difference's expansion. -/
private theorem neg_expand (A B X : Real) :
    Req (Rneg (Radd (Radd A (Rneg X)) (Radd (Rneg X) B)))
      (Radd (Radd (Rneg A) X) (Radd X (Rneg B))) := by
  refine Req_trans (Rneg_Radd _ _) (Radd_congr ?_ ?_)
  · exact Req_trans (Rneg_Radd A (Rneg X)) (Radd_congr (Req_refl _) (Rneg_neg X))
  · exact Req_trans (Rneg_Radd (Rneg X) B) (Radd_congr (Rneg_neg X) (Req_refl _))

/-- The additive-group core of polarization: `((A+X)+(X+B)) + ((−A+X)+(X+−B)) ≈ (X+X)+(X+X)`.
    Both `A` and `B` cancel against their negations in place, so no permutation is needed. -/
private theorem polar_cancel (A B X : Real) :
    Req (Radd (Radd (Radd A X) (Radd X B)) (Radd (Radd (Rneg A) X) (Radd X (Rneg B))))
      (Radd (Radd X X) (Radd X X)) := by
  have f2 : ∀ u v : Real, Req (Radd u v) (RsumL [u, v]) := Radd_eq_RsumL
  have f4 : ∀ u v w z : Real,
      Req (Radd (Radd u v) (Radd w z)) (RsumL ([u, v] ++ [w, z])) := by
    intro u v w z
    refine Req_trans (Radd_congr (f2 u v) (f2 w z)) ?_
    exact Req_symm (RsumL_append [u, v] [w, z])
  have hL : Req (Radd (Radd (Radd A X) (Radd X B)) (Radd (Radd (Rneg A) X) (Radd X (Rneg B))))
      (RsumL ([A, X, X, B] ++ [Rneg A, X, X, Rneg B])) := by
    refine Req_trans (Radd_congr (f4 A X X B) (f4 (Rneg A) X X (Rneg B))) ?_
    exact Req_symm (RsumL_append [A, X, X, B] [Rneg A, X, X, Rneg B])
  refine Req_trans hL (Req_trans ?_ (Req_symm (f4 X X X X)))
  show Req (RsumL [A, X, X, B, Rneg A, X, X, Rneg B]) (RsumL [X, X, X, X])
  refine Req_trans (RsumL_cancel_anywhere A [] [X, X, B] [X, X, Rneg B]) ?_
  exact RsumL_cancel_anywhere B [X, X] [X, X] []

/-- **THE POLARIZATION IDENTITY**: the pairing is recovered from the energy —
    `4·⟪φ,ψ⟫ ≈ ‖(φ+ψ)^‖² − ‖(φ−ψ)^‖²`, written multiplication-free. -/
theorem momentL2Sq_polarization (φ ψ : L2Test) :
    Req (Rsub (momentL2Sq (L2Test.add φ ψ)) (momentL2Sq (L2Test.sub φ ψ)))
      (Radd (Radd (crossMomL2 φ ψ) (crossMomL2 φ ψ))
            (Radd (crossMomL2 φ ψ) (crossMomL2 φ ψ))) := by
  show Req (Radd (momentL2Sq (L2Test.add φ ψ)) (Rneg (momentL2Sq (L2Test.sub φ ψ)))) _
  refine Req_trans (Radd_congr (momentL2Sq_add φ ψ)
    (Rneg_congr (momentL2Sq_sub φ ψ))) ?_
  refine Req_trans (Radd_congr (Req_refl _)
    (neg_expand (momentL2Sq φ) (momentL2Sq ψ) (crossMomL2 φ ψ))) ?_
  exact polar_cancel (momentL2Sq φ) (momentL2Sq ψ) (crossMomL2 φ ψ)

/-- **THE ENERGY DETERMINES THE PAIRING**: two tests with the same sum- and difference-energies
    against `ψ` have the same pairing with it — polarization read as a rigidity statement. -/
theorem crossMomL2_congr_of_energies (φ ψ χ : L2Test)
    (hadd : Req (momentL2Sq (L2Test.add φ χ)) (momentL2Sq (L2Test.add ψ χ)))
    (hsub : Req (momentL2Sq (L2Test.sub φ χ)) (momentL2Sq (L2Test.sub ψ χ))) :
    Req (Radd (Radd (crossMomL2 φ χ) (crossMomL2 φ χ))
              (Radd (crossMomL2 φ χ) (crossMomL2 φ χ)))
        (Radd (Radd (crossMomL2 ψ χ) (crossMomL2 ψ χ))
              (Radd (crossMomL2 ψ χ) (crossMomL2 ψ χ))) :=
  Req_trans (Req_symm (momentL2Sq_polarization φ χ))
    (Req_trans (Rsub_congr hadd hsub) (momentL2Sq_polarization ψ χ))

-- ===========================================================================
-- The realized instance: the constructed members are NOT null.
-- ===========================================================================

/-- `0` is not strictly positive (local: the copy in `LambdaGap` is off this import chain). -/
private theorem zero_not_Pos : ¬ Pos zero := by
  intro ⟨n, hn⟩
  simp only [Qlt, Qbound, zero_seq] at hn
  omega

/-- The `K = 3` member is not in the null space — brick 45's certified positive energy, read as
    a non-membership statement. -/
theorem deep3_not_null : ¬ Req (momentL2Sq deep3) zero := fun h =>
  zero_not_Pos (Pos_congr h momentL2Sq_deep3_pos)

/-- **THE NULL SPACE IS A PROPER SUBSPACE OF THE CONSTRUCTED CLASS**: `deep3` has a moment apart
    from zero, so it is not moment-null — the characterization, realized on a built test. -/
theorem deep3_moment_not_all_zero : ¬ (∀ n : Nat, Req (mellinMoment deep3 n) zero) := fun h =>
  deep3_not_null (momentL2Sq_zero_of_moments deep3 h)

end Multiplicity.UOR.Bridge.F1Square.Square
