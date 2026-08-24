/-
F1 square — **the pre-Hilbert layer, brick 57** (`CoSupportSubspace.lean`): **THE CO-SUPPORT
LEVELS ARE GENUINE LINEAR SUBSPACES** — closed under every linear operation the test algebra
has, not only under addition.

Brick 22's `hatVanishes_add` established closure under `+` at a shared decay constant. On
compact support the rest follows cleanly, because there the predicate *is* moment-vanishing
(`hatVanishes_of_moments`) and the moment map is linear:

    `HatVanishes (−φ) K`                (`hatVanishes_neg`)
    `HatVanishes (φ − ψ) K`             (`hatVanishes_sub`)
    `HatVanishes (k·φ) K`               (`hatVanishes_natScale`)
    `HatVanishes (φ + ψ) K`             (`hatVanishes_add_supp`, the compact restatement)

with the support side closed alongside (`unitSupported_neg`, `_add`, `_sub`; `natScale_supp` was
brick 35's).

WHY IT MATTERS (the Sonine route). The coupling step 4 would have to act on a *space*, so it
matters that each level is one — and that its realized inhabitants are not isolated points. The
payoff here is `combo345_in_level_three`: EVERY natural-coefficient combination
`a·deep3 + b·deep4 + c·deep5` lies in level `3`. With brick 55 (those three are independent as
far as the moment functionals at `3,4,5` see them) each realized level carries an infinite,
genuinely multi-dimensional family rather than one witness and its multiples.

HONEST SCOPE. Closure under the linear operations, on the compact-support branch where the decay
constant is `0`; the general shared-`C` statement is brick 22's addition only. Nothing here
touches the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.CoSupportDimension

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The support side.
-- ===========================================================================

/-- Negation preserves `[0,1]` support. -/
theorem unitSupported_neg (φ : L2Test) (h : UnitSupported φ) :
    UnitSupported (L2Test.neg φ) := by
  intro m x h0 h1
  exact Req_trans (Rneg_congr (h m x h0 h1)) Rneg_zero

/-- Addition preserves `[0,1]` support. -/
theorem unitSupported_add (φ ψ : L2Test) (hφ : UnitSupported φ) (hψ : UnitSupported ψ) :
    UnitSupported (L2Test.add φ ψ) := by
  intro m x h0 h1
  exact Req_trans (Radd_congr (hφ m x h0 h1) (hψ m x h0 h1)) (Radd_zero zero)

/-- Subtraction preserves `[0,1]` support. -/
theorem unitSupported_sub (φ ψ : L2Test) (hφ : UnitSupported φ) (hψ : UnitSupported ψ) :
    UnitSupported (L2Test.sub φ ψ) :=
  unitSupported_add φ (L2Test.neg ψ) hφ (unitSupported_neg ψ hψ)

-- ===========================================================================
-- The moment side, and the closure theorems.
-- ===========================================================================

/-- `zero` read as a rational constant (local: brick 55's copy is private). -/
private theorem zero_ofQ : Req zero (ofQ (⟨0, 1⟩ : Q) (by decide)) :=
  Req_of_seq_Qeq (fun _ => Qeq_refl _)

/-- **The level is closed under negation.** -/
theorem hatVanishes_neg (φ : L2Test) (K : Nat) (hsupp : UnitSupported φ)
    (h : HatVanishes φ K (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp φ hsupp)) :
    HatVanishes (L2Test.neg φ) K (C := (⟨0, 1⟩ : Q)) (by decide)
      (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp (L2Test.neg φ) (unitSupported_neg φ hsupp)) := by
  refine hatVanishes_of_moments (L2Test.neg φ) K (unitSupported_neg φ hsupp) (fun n hn => ?_)
  refine Req_trans (innerI_neg_left φ (powTest n)) ?_
  exact Req_trans (Rneg_congr ((hatVanishes_iff_orthogonal φ K hsupp).mp h n hn)) Rneg_zero

/-- **The level is closed under addition** (compact restatement of brick 22). -/
theorem hatVanishes_add_supp (φ ψ : L2Test) (K : Nat)
    (hφs : UnitSupported φ) (hψs : UnitSupported ψ)
    (hφ : HatVanishes φ K (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp φ hφs))
    (hψ : HatVanishes ψ K (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp ψ hψs)) :
    HatVanishes (L2Test.add φ ψ) K (C := (⟨0, 1⟩ : Q)) (by decide)
      (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp (L2Test.add φ ψ) (unitSupported_add φ ψ hφs hψs)) := by
  refine hatVanishes_of_moments (L2Test.add φ ψ) K
    (unitSupported_add φ ψ hφs hψs) (fun n hn => ?_)
  refine Req_trans (innerI_add_left φ ψ (powTest n)) ?_
  exact Req_trans (Radd_congr ((hatVanishes_iff_orthogonal φ K hφs).mp hφ n hn)
    ((hatVanishes_iff_orthogonal ψ K hψs).mp hψ n hn)) (Radd_zero zero)

/-- **The level is closed under subtraction.** -/
theorem hatVanishes_sub (φ ψ : L2Test) (K : Nat)
    (hφs : UnitSupported φ) (hψs : UnitSupported ψ)
    (hφ : HatVanishes φ K (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp φ hφs))
    (hψ : HatVanishes ψ K (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp ψ hψs)) :
    HatVanishes (L2Test.sub φ ψ) K (C := (⟨0, 1⟩ : Q)) (by decide)
      (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp (L2Test.sub φ ψ) (unitSupported_sub φ ψ hφs hψs)) :=
  hatVanishes_add_supp φ (L2Test.neg ψ) K hφs (unitSupported_neg ψ hψs) hφ
    (hatVanishes_neg ψ K hψs hψ)

/-- **The level is closed under integer scaling.** -/
theorem hatVanishes_natScale (φ : L2Test) (K k : Nat) (hsupp : UnitSupported φ)
    (h : HatVanishes φ K (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp φ hsupp)) :
    HatVanishes (natScale k φ) K (C := (⟨0, 1⟩ : Q)) (by decide)
      (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp (natScale k φ) (natScale_supp φ hsupp k)) := by
  refine hatVanishes_of_moments (natScale k φ) K (natScale_supp φ hsupp k) (fun n hn => ?_)
  have hz : Req (innerI φ (powTest n)) (ofQ (⟨0, 1⟩ : Q) (by decide)) :=
    Req_trans ((hatVanishes_iff_orthogonal φ K hsupp).mp h n hn) zero_ofQ
  refine Req_trans (pv_scale k (v := (⟨0, 1⟩ : Q)) (by decide) (by decide) hz
    (by show Qeq (mul (⟨(k : Int), 1⟩ : Q) (⟨0, 1⟩ : Q)) (⟨0, 1⟩ : Q)
        simp only [Qeq, mul]
        ring_uor)) ?_
  exact Req_symm zero_ofQ

-- ===========================================================================
-- The payoff: every combination of the constructed members stays in the level.
-- ===========================================================================

/-- `[0,1]` support of the three-member combination. -/
theorem combo345_supp (a b c : Nat) : UnitSupported (combo345 a b c) :=
  unitSupported_add _ _
    (unitSupported_add _ _ (natScale_supp deep3 deep3_supp a) (natScale_supp deep4 deep4_supp b))
    (natScale_supp deep5 deep5_supp c)

/-- **EVERY NATURAL-COEFFICIENT COMBINATION LIES IN LEVEL 3**: with brick 55's independence, the
    realized level carries an infinite, genuinely multi-dimensional family — not one witness and
    its multiples. -/
theorem combo345_in_level_three (a b c : Nat) :
    HatVanishes (combo345 a b c) 3 (C := (⟨0, 1⟩ : Q)) (by decide)
      (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp (combo345 a b c) (combo345_supp a b c)) :=
  hatVanishes_add_supp _ _ 3
    (unitSupported_add _ _ (natScale_supp deep3 deep3_supp a)
      (natScale_supp deep4 deep4_supp b))
    (natScale_supp deep5 deep5_supp c)
    (hatVanishes_add_supp _ _ 3 (natScale_supp deep3 deep3_supp a)
      (natScale_supp deep4 deep4_supp b)
      (hatVanishes_natScale deep3 3 a deep3_supp deep3_hatVanishes)
      (hatVanishes_natScale deep4 3 b deep4_supp
        (hatVanishes_mono (by decide) deep4_hatVanishes)))
    (hatVanishes_natScale deep5 3 c deep5_supp
      (hatVanishes_mono (by decide) deep5_hatVanishes))

end Multiplicity.UOR.Bridge.F1Square.Square
