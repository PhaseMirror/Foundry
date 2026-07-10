/-
F1 square — sibling carriers and the faceted content-address (Thrust A, R14–R16), kernel-checked.

Companion `characteristic_1_constructions.md` R14–R16: the same Kleene-closure machinery over
different closed semirings gives a *class* of relabeling-invariant content-addresses; composing them
yields a faceted address; and the facets are object-dependent (a facet carries information only where
the object has that structure). Here we realize the **boolean** (reachability) carrier alongside the
tropical one (`Spectrum.kappa`), compose them (R15), and exhibit the boolean facet's degeneracy on a
strongly-connected graph (R16). Min-plus is the same construction with `(min, +)` and is analogous.
Pure Lean 4, no Mathlib, no `sorry`.
-/

import F1Square.Tropical.Spectrum

namespace UOR.Bridge.F1Square.Tropical

/-! ## The boolean (reachability) carrier -/

/-- A boolean (reachability) matrix. -/
abbrev MatB : Type := List (List Bool)

/-- Entry access (out-of-range ⇒ `false`). -/
def getB (m : MatB) (i j : Nat) : Bool := (m.getD i []).getD j false

/-- Boolean matrix product `(A ⊗ B)_{ij} = ⋁_k A_{ik} ∧ B_{kj}`. -/
def bMulN (n : Nat) (a b : MatB) : MatB :=
  (List.range n).map (fun i =>
    (List.range n).map (fun j =>
      (List.range n).foldl (fun acc k => acc || (getB a i k && getB b k j)) false))

/-- Elementwise OR. -/
def bAddM (a b : MatB) : MatB := List.zipWith (fun ra rb => List.zipWith (· || ·) ra rb) a b

/-- Boolean identity (reflexive). -/
def bIdN (n : Nat) : MatB :=
  (List.range n).map (fun i => (List.range n).map (fun j => i == j))

/-- The all-`false` matrix. -/
def bZeroN (n : Nat) : MatB :=
  (List.range n).map (fun _ => (List.range n).map (fun _ => false))

/-- Boolean matrix power. -/
def bPowN (n : Nat) (a : MatB) : Nat → MatB
  | 0     => bIdN n
  | k + 1 => bMulN n (bPowN n a k) a

/-- Reflexive-transitive (reachability) closure `⊕_{k=0}^{n-1} Aᵏ`. -/
def bStarN (n : Nat) (a : MatB) : MatB :=
  ((List.range n).map (fun k => bPowN n a k)).foldl bAddM (bZeroN n)

/-- Insertion sort on `Nat` (canonical form for the boolean facet). -/
def insSortedNat (x : Nat) : List Nat → List Nat
  | [] => [x]
  | y :: ys => if x ≤ y then x :: y :: ys else y :: insSortedNat x ys

def isortNat : List Nat → List Nat
  | [] => []
  | x :: xs => insSortedNat x (isortNat xs)

/-- The boolean content-address: the sorted multiset of per-vertex out-reachability degrees of the
    closure — a relabeling-invariant summary of the reachability structure. -/
def kappaBool (n : Nat) (m : MatB) : List Nat :=
  isortNat ((List.range n).map (fun i =>
    ((List.range n).filter (fun j => i != j && getB (bStarN n m) i j)).length))

/-- Relabel a boolean matrix by `p`. -/
def applyPermB (n : Nat) (p : Nat → Nat) (m : MatB) : MatB :=
  (List.range n).map (fun i => (List.range n).map (fun j => getB m (p i) (p j)))

/-- The running example as a boolean adjacency (edge present?). Strongly connected. -/
def Wb : MatB :=
  [[false, true,  false, true],
   [false, false, true,  false],
   [true,  false, false, true],
   [false, false, true,  false]]

/-- A sparse DAG `0→1→2→3` (non-strongly-connected), where the boolean facet is discriminating. -/
def Wpath : MatB :=
  [[false, true,  false, false],
   [false, false, true,  false],
   [false, false, false, true],
   [false, false, false, false]]

/-- **R14 (boolean carrier).** The boolean content-address is relabeling-invariant — verified on the
    discriminating sparse object (degrees `[0,1,2,3]`, unchanged by the 4-cycle relabeling). -/
theorem R14_kappaBool_perm_invariant :
    kappaBool 4 (applyPermB 4 pcycle Wpath) = kappaBool 4 Wpath := by decide

/-- **R16.** On the strongly-connected example the boolean facet is DEGENERATE: every vertex reaches
    every other, so the reachability-degree multiset is uniform `[3,3,3,3]` — it carries nothing,
    while the tropical facet (`Spectrum.kappa`) is rich. Facets carry signal only where the object
    has that kind of structure. -/
theorem R16_boolean_facet_degenerate : kappaBool 4 Wb = [3, 3, 3, 3] := by decide

/-- **R15.** The faceted content-address composes the carriers: `(κ_tropical, κ_boolean)` addresses
    an object up to "same extremal AND same reachability structure," recoverable to either facet. -/
def facetedAddress (n : Nat) (mt : Mat) (mb : MatB) : List Int × List Nat :=
  (kappa n mt, kappaBool n mb)

/-- The composite address of the running example, computed (a witness-verifiable faceted label). -/
theorem R15_faceted_address :
    facetedAddress 4 W Wb = (kappa 4 W, [3, 3, 3, 3]) := by decide

end UOR.Bridge.F1Square.Tropical
