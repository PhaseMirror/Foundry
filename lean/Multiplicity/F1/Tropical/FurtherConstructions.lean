/-
F1 square — the last two of §8's "four further constructions" (**R12**, **R13**), kernel-checked —
completing the §8 stack in Lean (R10, R11 were already formalized in `Spectrum.lean`).

Companion `characteristic_1_constructions.md` §8.3–§8.4:

- **R12 — the reversal symmetry** (the tropical functional equation). `spectrum(W) = spectrum(Wᵀ)`:
  reversing every edge sends each simple cycle to its reverse, same length and same total weight, so
  the cycle-mean multiset is preserved. Verified here on the running example against its transpose,
  the reversed cycles carrying identical `(sum, length)` profiles — the tropical analogue of the zeta
  functional equation `ζ(t) = ζ_reverse(t)`.

- **R13 — tropical intersection-positivity is FREE** (Bézout). The stable intersection multiplicity of
  two curve-edges with primitive directions `u, v` and lattice weights `m_u, m_v` is
  `mult = m_u · m_v · |det(u,v)|`, a NON-NEGATIVE INTEGER by construction (`R13_intersection_nonneg`),
  and tropical Bézout holds term-by-term (`R13_bezout`: line ∩ line `= 1`, line ∩ conic `= 2`). This is
  the manifest characteristic-1 shadow of the Hodge intersection-positivity that confines the zeros —
  positivity that is automatic here (`|det| ≥ 0`, lattice determinants) and whose ℤ-analogue is exactly
  what is missing over ℚ (per the companion doc). NOTE — as §8.4 states, this is tropical
  multiplicity-positivity/Bézout ONLY; the full tropical Hodge index theorem is a separate,
  un-formalized result and is NOT claimed here.

HONEST SCOPE. Finite tropical/combinatorial realizations of the UOR content-addressing / cycle-dynamics
stack — RH-independent (no `λ`, no zeros, no `StieltjesEta`). R13's positivity is a manifest `Nat`/`|det|`
fact, the characteristic-1 SHADOW of the arithmetic positivity, NOT that positivity itself (which over ℚ
is RH). The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; `by decide`.
-/

import Multiplicity.F1.Tropical.Spectrum
import Multiplicity.F1.Tropical.Signature

namespace Multiplicity.UOR.Bridge.F1Square.Tropical

open UOR.Bridge.F1Square.CharOne

/-! ## R12 — the reversal symmetry (tropical functional equation) -/

/-- The transpose (all edges reversed): `Wᵀ[i][j] = W[j][i]`. -/
def transposeM (n : Nat) (m : Mat) : Mat :=
  (List.range n).map (fun i => (List.range n).map (fun j => getE m j i))

/-- **R12.** The reversal symmetry `spectrum(W) = spectrum(Wᵀ)` — the tropical functional equation.
    Each simple cycle of `W` maps to its reverse in `Wᵀ` with the same length and total weight, so the
    cycle-mean profiles coincide: the running example's cycles `(2,3), (0,3,2), (0,1,2)` and their
    reverses in the transpose `(2,3), (0,2,3), (0,2,1)` carry the identical `(sum, length)` multiset
    `[(-5,2), (-16,3), (-10,3)]`. -/
theorem R12_reversal_symmetry :
    spectrum (transposeM 4 W) [[2, 3], [0, 2, 3], [0, 2, 1]]
      = spectrum W [[2, 3], [0, 3, 2], [0, 1, 2]] := by decide

/-! ## R13 — tropical intersection-positivity is free (Bézout) -/

/-- The tropical **stable intersection multiplicity** of two curve-edges with primitive direction
    vectors `(u₁,u₂), (v₁,v₂)` and lattice weights `m_u, m_v`:
    `mult = m_u · m_v · |det(u,v)|` — a `Nat` by construction (a product of counts and an absolute
    determinant), so non-negative for free. -/
def imult (mu mv : Nat) (u1 u2 v1 v2 : Int) : Nat :=
  mu * mv * (Signature.det2 u1 u2 v1 v2).natAbs

/-- **R13 (positivity).** Tropical intersection-positivity is FREE: every stable intersection
    multiplicity is a non-negative integer, manifestly (its type is `Nat`; it is `m_u·m_v·|det|`). This
    is the computable characteristic-1 shadow of the Hodge intersection-positivity the ℚ-object lacks. -/
theorem R13_intersection_nonneg (mu mv : Nat) (u1 u2 v1 v2 : Int) :
    0 ≤ imult mu mv u1 u2 v1 v2 := Nat.zero_le _

/-- **R13 (Bézout).** Tropical Bézout, term-by-term: line ∩ line `= 1·1·|det((1,0),(0,1))| = 1`;
    line ∩ conic `= 1·2·|det((1,0),(0,1))| = 2` (the conic via a weight-2 edge). -/
theorem R13_bezout : imult 1 1 1 0 0 1 = 1 ∧ imult 1 2 1 0 0 1 = 2 := by decide

end Multiplicity.UOR.Bridge.F1Square.Tropical
