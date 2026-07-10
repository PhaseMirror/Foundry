/-
F1 square — the tropical content-address κ and the cycle-mean spectrum (Thrust A), kernel-checked.

Companion `characteristic_1_constructions.md`: R3 (κ is permutation-invariant), R4 (the cycle-mean
spectrum), and the headline R9/R10 (**κ does NOT determine the spectrum** — same content-address,
different dynamics) with R11 (the κ-fiber carries distinct spectra). Pure Lean 4, no Mathlib, no
`sorry`. κ is the tropical incarnation of the uor-addr content-address: the sorted off-diagonal
multiset of the Kleene closure `W*` (a relabeling-invariant canonical address).

Means are kept exact as `(sum, length)` pairs (the cycle profile); equality of profiles is the
decidable comparison used here — exact rational means (`Analysis/Rat.lean`) give the same verdicts.
-/

import F1Square.Tropical.Closure

namespace UOR.Bridge.F1Square.Tropical

open UOR.Bridge.F1Square.CharOne

/-! ## The content-address κ -/

/-- The finite off-diagonal entries of a matrix, as a plain `Int` list. -/
def offDiagEntries (n : Nat) (m : Mat) : List Int :=
  ((List.range n).map (fun i =>
    (List.range n).filterMap (fun j => if i = j then none else getE m i j))).flatten

/-- Insertion into a sorted list. -/
def insSorted (x : Int) : List Int → List Int
  | [] => [x]
  | y :: ys => if x ≤ y then x :: y :: ys else y :: insSorted x ys

/-- Insertion sort (gives κ a canonical, order-independent form). -/
def isort : List Int → List Int
  | [] => []
  | x :: xs => insSorted x (isort xs)

/-- The tropical content-address: the sorted off-diagonal multiset of the Kleene closure `W*`. -/
def kappa (n : Nat) (m : Mat) : List Int := isort (offDiagEntries n (starN n m))

/-- Relabel vertices by `p` (apply a permutation to rows and columns). -/
def applyPerm (n : Nat) (p : Nat → Nat) (m : Mat) : Mat :=
  (List.range n).map (fun i => (List.range n).map (fun j => getE m (p i) (p j)))

/-- The 4-cycle relabeling `0↦1↦2↦3↦0`. -/
def pcycle : Nat → Nat
  | 0 => 1
  | 1 => 2
  | 2 => 3
  | 3 => 0
  | k => k

/-- **R3.** κ is invariant under vertex relabeling — a genuine content-address. -/
theorem R3_kappa_perm_invariant : kappa 4 (applyPerm 4 pcycle W) = kappa 4 W := by decide

/-! ## The cycle-mean spectrum -/

/-- Edge weight (present edges only; `−∞` reads as `0`, unused for real cycles). -/
def edgeW (m : Mat) (i j : Nat) : Int := (getE m i j).getD 0

/-- Rotate a vertex list by one (to pair consecutive cycle edges with wrap-around). -/
def rot (vs : List Nat) : List Nat := vs.drop 1 ++ vs.take 1

/-- Total weight of a cycle given by its vertex sequence. -/
def cycleSum (m : Mat) (vs : List Nat) : Int :=
  ((List.zip vs (rot vs)).map (fun p => edgeW m p.1 p.2)).foldl (· + ·) 0

/-- A cycle's mean as the exact `(sum, length)` profile. -/
def cycleMean (m : Mat) (vs : List Nat) : Int × Nat := (cycleSum m vs, vs.length)

/-- The cycle-mean spectrum over a given list of (simple) cycles. -/
def spectrum (m : Mat) (cycles : List (List Nat)) : List (Int × Nat) := cycles.map (cycleMean m)

/-- **R4.** The cycle-mean spectrum of the running example: the three simple cycles
    `(2,3)`, `(0,3,2)`, `(0,1,2)` have profiles `(−5,2), (−16,3), (−10,3)` — means
    `−5/2, −16/3, −10/3`, matching the companion's `{−2.5, −10/3, −16/3}`. -/
theorem R4_cycle_spectrum :
    spectrum W [[2, 3], [0, 3, 2], [0, 1, 2]] = [(-5, 2), (-16, 3), (-10, 3)] := by decide

/-! ## R9/R10/R11 — κ does NOT determine the spectrum (the headline) -/

/-- Two 2-vertex weighted graphs differing only in the self-loop at vertex 0. -/
def WA : Mat := [[some (-1), some (-1)], [some (-1), some (-1)]]
def WB : Mat := [[some (-2), some (-1)], [some (-1), some (-1)]]

/-- The cycles of a 2-vertex graph: the two self-loops and the 2-cycle. -/
def cyc2 : List (List Nat) := [[0], [1], [0, 1]]

/-- **R9.** `WA` and `WB` have the SAME content-address κ. -/
theorem R9_same_kappa : kappa 2 WA = kappa 2 WB := by decide

/-- **R10.** …yet DIFFERENT cycle-mean spectra. So κ does not determine the spectrum: the
    content-address is strictly coarser than the dynamics. -/
theorem R10_diff_spectrum : spectrum WA cyc2 ≠ spectrum WB cyc2 := by decide

/-- **R11.** The κ-fiber (graphs sharing a κ) carries distinct spectra — extremally identical,
    cyclically different. -/
theorem R11_kappa_fiber :
    kappa 2 WA = kappa 2 WB ∧ spectrum WA cyc2 ≠ spectrum WB cyc2 :=
  ⟨R9_same_kappa, R10_diff_spectrum⟩

end UOR.Bridge.F1Square.Tropical
