/-
F1 square — **the pre-Hilbert layer, brick 67** (`CoSupportDimThree.lean`): **THE LEVEL IS AT
LEAST THREE-DIMENSIONAL** — brick 55 read the first two coefficients off the triangular moment
table and left the third open. This closes it:

    `a·deep3 + b·deep4 + c·deep5` has vanishing `x³`, `x⁴` and `x⁵` moments  ⟹  `a = b = c = 0`
      (`deep345_independent`).

The missing entry was the `x⁵` row, where all three members contribute
(`⟨deep3,x⁵⟩ = −1/924`, `⟨deep4,x⁵⟩ = 1/5544`, `⟨deep5,x⁵⟩ = −1/72072`) and the assembled
rational identity carries the product denominator `924·5544·72072 ≈ 3.7·10¹¹`. Brick 55 recorded
that as out of the elaborator's budget. **That record was wrong**: the assembled identity is
*linear* in the coefficients, so `ring_uor` normalises it in a single pass, and the step below
elaborates at the DEFAULT heartbeat budget with no `set_option` at all. Nothing conceptual and
nothing mechanical was in the way; brick 55's note is retracted here.

So the co-support level `3` contains three `ℕ`-independent constructed members, not two, and the
`ℕ`-parametrized family of brick 58 is genuinely three-parameter.

HONEST SCOPE. Independence over `ℕ` coefficients of the three constructed members, read off the
exact moment table — still not a dimension formula, and still says nothing about levels beyond
the realized ones. Nothing here touches the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.CoSupportDimension

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- With the first two coefficients gone, the `x⁵` moment sees only `deep5`: its value is
    `−c/72072`. The row all three members contribute to. -/
theorem combo345_moment_five (c : Nat) :
    Req (innerI (combo345 0 0 c) (powTest 5))
      (ofQ (⟨-(c : Int), 72072⟩ : Q) (by show (0:Nat) < 72072; decide)) :=
  combo345_moment (q3 := (⟨-1, 924⟩ : Q)) (q4 := (⟨1, 5544⟩ : Q)) (q5 := (⟨-1, 72072⟩ : Q))
    (w := (⟨-(c : Int), 72072⟩ : Q)) 0 0 c 5 (by decide) (by decide) (by decide)
    (by show (0:Nat) < 72072; decide)
    deep3_moment_five deep4_moment_five deep5_moment_five
    (by simp only [Qeq, add, mul]; push_cast; ring_uor)

/-- **THE LEVEL-3 FAMILY IS AT LEAST THREE-DIMENSIONAL**: the triangular table reads the three
    coefficients off one at a time — `x³` sees only `deep3`, then `x⁴` only `deep4`, then `x⁵`
    only `deep5`. -/
theorem deep345_independent (a b c : Nat)
    (h3 : Req (innerI (combo345 a b c) (powTest 3)) zero)
    (h4 : Req (innerI (combo345 0 b c) (powTest 4)) zero)
    (h5 : Req (innerI (combo345 0 0 c) (powTest 5)) zero) :
    a = 0 ∧ b = 0 ∧ c = 0 := by
  refine ⟨?_, ?_, ?_⟩
  · exact nat_eq_zero_of_ofQ_neg_zero (by show (0:Nat) < 2520; decide)
      (Req_trans (Req_symm (combo345_moment_three a b c)) h3)
  · exact nat_eq_zero_of_ofQ_zero (by show (0:Nat) < 13860; decide)
      (Req_trans (Req_symm (combo345_moment_four b c)) h4)
  · exact nat_eq_zero_of_ofQ_neg_zero (by show (0:Nat) < 72072; decide)
      (Req_trans (Req_symm (combo345_moment_five c)) h5)

end Multiplicity.UOR.Bridge.F1Square.Square
