/-
F1 square — v0.21.0 stage G, brick **Atlas composition algebras**: the multiplicative norm at the
tower levels — the 2-, 4-, 8-square identities (Hurwitz), the Atlas's §6.3/§9 closed positivity.

Discovering the norm facet. The Atlas (§6.3, §9, §10 "composition algebras") carries a multiplicative
positive-definite norm at each level: `|x|²·|y|² = |xy|²`, which IS the 2-, 4-, and 8-square identity
at `C, H, O` — and Hurwitz's theorem says these (dims `1, 2, 4, 8`, the tower) are the ONLY ones. F1
already has the 2-square (`Analysis.cnormSq_mul`, `|zw|² = |z|²|w|²`); this brick adds the quaternion
(`four_square`, Euler) and the octonion (`eight_square`, Degen) levels, as exact integer identities by
`ring_uor`. This is the §9 norm positivity — the Atlas's CLOSED definiteness (a manifest sum of
squares), distinct from the open RH intersection-form positivity (§9: "the model does not identify
the two").

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.RingTac
import F1Square.Square.AtlasCharacteristics

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis.RingNF

/-- **The TWO-SQUARE identity** (`C`, complex norm multiplicativity, Brahmagupta–Fibonacci):
    `(a²+b²)(c²+d²) = (ac−bd)² + (ad+bc)²`. The norm `|·|²` is multiplicative at level `C` (dim 2). -/
theorem two_square (a b c d : Int) :
    (a * a + b * b) * (c * c + d * d)
    = (a * c - b * d) * (a * c - b * d) + (a * d + b * c) * (a * d + b * c) := by
  ring_uor

/-- **The FOUR-SQUARE identity** (Euler; `H`, quaternion norm multiplicativity):
    `(Σ aᵢ²)(Σ bᵢ²) = Σ cᵢ²` with the quaternion-product coordinates. The norm is multiplicative at
    level `H` (dim 4). -/
theorem four_square (a1 a2 a3 a4 b1 b2 b3 b4 : Int) :
    (a1 * a1 + a2 * a2 + a3 * a3 + a4 * a4) * (b1 * b1 + b2 * b2 + b3 * b3 + b4 * b4)
    = (a1 * b1 - a2 * b2 - a3 * b3 - a4 * b4) * (a1 * b1 - a2 * b2 - a3 * b3 - a4 * b4)
      + (a1 * b2 + a2 * b1 + a3 * b4 - a4 * b3) * (a1 * b2 + a2 * b1 + a3 * b4 - a4 * b3)
      + (a1 * b3 - a2 * b4 + a3 * b1 + a4 * b2) * (a1 * b3 - a2 * b4 + a3 * b1 + a4 * b2)
      + (a1 * b4 + a2 * b3 - a3 * b2 + a4 * b1) * (a1 * b4 + a2 * b3 - a3 * b2 + a4 * b1) := by
  ring_uor

/-- **The EIGHT-SQUARE identity** (Degen; `O`, octonion norm multiplicativity — the tower's TOP):
    `(Σ aᵢ²)(Σ bᵢ²) = Σ cᵢ²` with the octonion-product coordinates. The norm is multiplicative at
    level `O` (dim 8), the octonion level whose self-reference is the F1 square (§7). -/
theorem eight_square (a1 a2 a3 a4 a5 a6 a7 a8 b1 b2 b3 b4 b5 b6 b7 b8 : Int) :
    (a1*a1 + a2*a2 + a3*a3 + a4*a4 + a5*a5 + a6*a6 + a7*a7 + a8*a8)
    * (b1*b1 + b2*b2 + b3*b3 + b4*b4 + b5*b5 + b6*b6 + b7*b7 + b8*b8)
    = (a1*b1 - a2*b2 - a3*b3 - a4*b4 - a5*b5 - a6*b6 - a7*b7 - a8*b8)
        * (a1*b1 - a2*b2 - a3*b3 - a4*b4 - a5*b5 - a6*b6 - a7*b7 - a8*b8)
      + (a1*b2 + a2*b1 + a3*b4 - a4*b3 + a5*b6 - a6*b5 - a7*b8 + a8*b7)
        * (a1*b2 + a2*b1 + a3*b4 - a4*b3 + a5*b6 - a6*b5 - a7*b8 + a8*b7)
      + (a1*b3 - a2*b4 + a3*b1 + a4*b2 + a5*b7 + a6*b8 - a7*b5 - a8*b6)
        * (a1*b3 - a2*b4 + a3*b1 + a4*b2 + a5*b7 + a6*b8 - a7*b5 - a8*b6)
      + (a1*b4 + a2*b3 - a3*b2 + a4*b1 + a5*b8 - a6*b7 + a7*b6 - a8*b5)
        * (a1*b4 + a2*b3 - a3*b2 + a4*b1 + a5*b8 - a6*b7 + a7*b6 - a8*b5)
      + (a1*b5 - a2*b6 - a3*b7 - a4*b8 + a5*b1 + a6*b2 + a7*b3 + a8*b4)
        * (a1*b5 - a2*b6 - a3*b7 - a4*b8 + a5*b1 + a6*b2 + a7*b3 + a8*b4)
      + (a1*b6 + a2*b5 - a3*b8 + a4*b7 - a5*b2 + a6*b1 - a7*b4 + a8*b3)
        * (a1*b6 + a2*b5 - a3*b8 + a4*b7 - a5*b2 + a6*b1 - a7*b4 + a8*b3)
      + (a1*b7 + a2*b8 + a3*b5 - a4*b6 - a5*b3 + a6*b4 + a7*b1 - a8*b2)
        * (a1*b7 + a2*b8 + a3*b5 - a4*b6 - a5*b3 + a6*b4 + a7*b1 - a8*b2)
      + (a1*b8 - a2*b7 + a3*b6 + a4*b5 - a5*b4 - a6*b3 + a7*b2 + a8*b1)
        * (a1*b8 - a2*b7 + a3*b6 + a4*b5 - a5*b4 - a6*b3 + a7*b2 + a8*b1) := by
  ring_uor

/-- **The composition-algebra norm sits on the tower**: the 2-, 4-, 8-square identities are the
    multiplicative norm at `C, H, O` — dims `towerDim 1, 2, 3 = 2, 4, 8` — and Hurwitz says these are
    the ONLY normed division algebras (the tower `{1,2,4,8}`). This is the §9 closed positivity. -/
theorem composition_tower : towerDim 1 = 2 ∧ towerDim 2 = 4 ∧ towerDim 3 = 8 := by decide

end UOR.Bridge.F1Square.Square
