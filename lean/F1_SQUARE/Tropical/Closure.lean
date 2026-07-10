/-
F1 square — tropical (max-plus) matrix closure (Thrust A), as kernel-checked theorems.

Companion `characteristic_1_constructions.md` R2 (the Kleene star is idempotent: `W* ⊗ W* = W*`) and
the canonical form `W*` of §1. Pure Lean 4, no Mathlib, no `sorry`. Matrices are `List (List T)`
over the characteristic-1 scalar `T = Option Int` (reused from `CharOne`); `List` is used so that
matrix equality is decidable without Mathlib's `Fintype`.

Running example (companion §0): edges 0→1:−3, 0→3:−7, 1→2:−2, 2→0:−5, 2→3:−1, 3→2:−4.
-/

import F1Square.CharOne

namespace UOR.Bridge.F1Square.Tropical

open UOR.Bridge.F1Square.CharOne

/-- An `n×n` tropical matrix as a list of rows. -/
abbrev Mat : Type := List (List T)

/-- Entry access (out-of-range ⇒ `−∞`). -/
def getE (m : Mat) (i j : Nat) : T := (m.getD i []).getD j none

/-- Tropical matrix product `(A ⊗ B)_{ij} = ⊕_k A_{ik} ⊗ B_{kj}` for `n×n` matrices. -/
def mulN (n : Nat) (a b : Mat) : Mat :=
  (List.range n).map (fun i =>
    (List.range n).map (fun j =>
      (List.range n).foldl (fun acc k => tAdd acc (tMul (getE a i k) (getE b k j))) none))

/-- Elementwise tropical sum `A ⊕ B`. -/
def addM (a b : Mat) : Mat := List.zipWith (fun ra rb => List.zipWith tAdd ra rb) a b

/-- The tropical identity: `0` on the diagonal, `−∞` off it. -/
def idN (n : Nat) : Mat :=
  (List.range n).map (fun i => (List.range n).map (fun j => if i = j then some 0 else none))

/-- The `−∞` matrix. -/
def zeroN (n : Nat) : Mat :=
  (List.range n).map (fun _ => (List.range n).map (fun _ => none))

/-- Matrix power `A^k` (tropical). -/
def powN (n : Nat) (a : Mat) : Nat → Mat
  | 0     => idN n
  | k + 1 => mulN n (powN n a k) a

/-- The Kleene star `W* = ⊕_{k=0}^{n-1} W^k` (the closure, valid in the stable regime where simple
    paths suffice). -/
def starN (n : Nat) (a : Mat) : Mat :=
  ((List.range n).map (fun k => powN n a k)).foldl addM (zeroN n)

/-- The running example's weighted adjacency `W`. -/
def W : Mat :=
  [[none,      some (-3), none,      some (-7)],
   [none,      none,      some (-2), none],
   [some (-5), none,      none,      some (-1)],
   [none,      none,      some (-4), none]]

/-- The closure `W*` matches the companion's stated canonical form (sanity check of `starN`). -/
theorem star_matches :
    starN 4 W =
      [[some 0,   some (-3),  some (-5),  some (-6)],
       [some (-7), some 0,    some (-2),  some (-3)],
       [some (-5), some (-8), some 0,     some (-1)],
       [some (-9), some (-12), some (-4), some 0]] := by decide

/-- **R2.** The Kleene star is idempotent: `W* ⊗ W* = W*` — `W*` is the canonical (content-address)
    form of the weighted relation. -/
theorem R2_kleene_idempotent : mulN 4 (starN 4 W) (starN 4 W) = starN 4 W := by decide

end UOR.Bridge.F1Square.Tropical
