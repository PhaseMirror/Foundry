/-
F1 square — the Bowen–Lanford closed-walk trace identity (**R6**), kernel-checked — completing another
realization of the UOR content-addressing / cycle-dynamics stack.

Companion `characteristic_1_constructions.md` §3: for the running example's **0/1 adjacency** `B` — the
support of the weighted `W` of `Closure.lean` (an edge exactly where `W` has a finite weight) — the
closed-walk counts under the ORDINARY (counting) matrix product,

    `N_m = tr(Bᵐ)`,    `N_1 .. N_8 = 0, 2, 6, 2, 10, 14, 14, 34`,

are the power sums of the adjacency eigenvalues (Bowen–Lanford trace identity), verified term-by-term.
This is the counting (characteristic-0) companion of the tropical (max-plus) closure `starN`/`κ`: the
same directed graph, read with ordinary `+`/`·` instead of `max`/`+`.

The R-series already in Lean: R2 (Kleene idempotent), R3 (κ permutation-invariant), R4 (cycle-mean
spectrum), R9/R10/R11 (κ ⊬ spectrum), R14/R15/R16 (boolean facet). This adds R6.

HONEST SCOPE. Finite tropical/combinatorial closed-walk counting — an embeddings-model realization,
independent of RH and of the ζ/Li stack (no `λ`, no zeros, no `StieltjesEta`). It completes a facet of
the UOR content-addressing formalization; it makes no claim about the crux, which stays `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; `by decide`.
-/

import Multiplicity.F1.Tropical.Closure

namespace Multiplicity.UOR.Bridge.F1Square.Tropical

open UOR.Bridge.F1Square.CharOne

/-- Ordinary (counting) matrix entry over `ℕ` (out-of-range ⇒ `0`). -/
def nGet (m : List (List Nat)) (i j : Nat) : Nat := (m.getD i []).getD j 0

/-- Ordinary `ℕ` matrix product `(A·B)_{ij} = Σ_k A_{ik}·B_{kj}` — the counting product (contrast the
    tropical `mulN`, which uses `max`/`+`). -/
def nMul (n : Nat) (a b : List (List Nat)) : List (List Nat) :=
  (List.range n).map (fun i =>
    (List.range n).map (fun j =>
      (List.range n).foldl (fun acc k => acc + nGet a i k * nGet b k j) 0))

/-- The `ℕ` identity matrix. -/
def nId (n : Nat) : List (List Nat) :=
  (List.range n).map (fun i => (List.range n).map (fun j => if i = j then 1 else 0))

/-- Ordinary `ℕ` matrix power `Aᵏ`. -/
def nPow (n : Nat) (a : List (List Nat)) : Nat → List (List Nat)
  | 0     => nId n
  | k + 1 => nMul n (nPow n a k) a

/-- The trace `Σ_i A_{ii}`. -/
def nTrace (n : Nat) (a : List (List Nat)) : Nat :=
  (List.range n).foldl (fun acc i => acc + nGet a i i) 0

/-- The **0/1 adjacency** of the running example — the SUPPORT of the weighted `W` (`Closure.lean`):
    an edge is present (`1`) exactly where `W` carries a finite weight (`some _`), absent (`0`) where
    `W` is `−∞` (`none`). This ties `B` to the same directed graph the tropical closure `κ` reads. -/
def adjOfW : List (List Nat) :=
  (List.range 4).map (fun i => (List.range 4).map (fun j =>
    match getE W i j with | none => 0 | some _ => 1))

/-- Sanity: the adjacency is the stated 0/1 pattern (edges `0→1, 0→3, 1→2, 2→0, 2→3, 3→2`). -/
theorem adjOfW_eq :
    adjOfW = [[0, 1, 0, 1], [0, 0, 1, 0], [1, 0, 0, 1], [0, 0, 1, 0]] := by decide

/-- **R6.** The Bowen–Lanford closed-walk trace identity: for the `0/1` adjacency `B = adjOfW`, the
    closed-walk counts `N_m = tr(Bᵐ)` (ordinary product) are `N_1 .. N_8 = 0, 2, 6, 2, 10, 14, 14, 34`
    — the power sums of the adjacency eigenvalues, verified term-by-term. The counting companion of the
    tropical cycle spectrum (R4); an RH-independent realization of the UOR cycle-dynamics stack. -/
theorem R6_closed_walk_counts :
    (List.range 8).map (fun m => nTrace 4 (nPow 4 adjOfW (m + 1)))
      = [0, 2, 6, 2, 10, 14, 14, 34] := by decide

end Multiplicity.UOR.Bridge.F1Square.Tropical
