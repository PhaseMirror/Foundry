/-
F1 square — **symmetry of the rational Hilbert form** (`QHilbertSymm.lean`), completing the algebraic
foundation of brick 3 of the Hausdorff *sufficiency* arc (Gram–Schmidt orthogonalization). The
Hilbert matrix `1/(i+j+1)` is symmetric, so the form is:

  `qHil_comm` :  `qHil c c' d = qHil c' c d`.

Together with the bilinearity laws (`QHilbertBilinear.lean`) this makes `qHil` a symmetric bilinear
form — exactly what Parseval `‖Σ aₖ qₖ‖² = Σ aₖ² ⟨qₖ,qₖ⟩` and the *two-sided* orthogonality
`⟨qᵢ,qⱼ⟩ = 0 (i≠j)` need. The proof pulls the outer coefficient into the inner sum, applies a
**Fubini exchange for the double `qsumL`** (`qsumL_qsumL_swap`, an induction built here), then
refactors — using only `qsumL_smul`, `qsumL_congr`, and the denominator symmetry `i+j+1 = j+i+1`.

HONEST SCOPE. Symmetry of the *finite rational* Hilbert form only (plus the reusable `qsumL` Fubini).
This is NOT the orthogonal-polynomial construction, NOT positivity. Step 4 (band-coupling positivity)
is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.QHilbertBilinear

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Fubini for the double list sum.
-- ===========================================================================

/-- **Fubini for `qsumL`**: `Σ_{i∈A} Σ_{j∈B} G i j = Σ_{j∈B} Σ_{i∈A} G i j`. Induction on the outer
    list `A`; the cons step distributes the inner sum over `B` with `qsumL_add`. -/
theorem qsumL_qsumL_swap (G : Nat → Nat → Q) (hG : ∀ i j, 0 < (G i j).den) (B : List Nat) :
    ∀ A : List Nat, Qeq (qsumL (fun i => qsumL (fun j => G i j) B) A)
      (qsumL (fun j => qsumL (fun i => G i j) A) B)
  | [] => Qeq_symm (qsumL_zero (fun _ => Qeq_refl _) B)
  | (a :: rest) =>
      Qeq_trans (b := add (qsumL (fun j => G a j) B)
          (qsumL (fun j => qsumL (fun i => G i j) rest) B))
        (add_den_pos (qsumL_den _ (fun j => hG a j) B)
          (qsumL_den _ (fun j => qsumL_den _ (fun i => hG i j) rest) B))
        (Qadd_congr (Qeq_refl _) (qsumL_qsumL_swap G hG B rest))
        (Qeq_symm (qsumL_add (fun j => G a j) (fun j => qsumL (fun i => G i j) rest)
          (fun j => hG a j) (fun j => qsumL_den _ (fun i => hG i j) rest) B))

-- ===========================================================================
-- Symmetry.
-- ===========================================================================

/-- The denominator is symmetric: `1/(i+j+1) = 1/(j+i+1)`. -/
private theorem denEq (i j : Nat) : Qeq (⟨1, i + j + 1⟩ : Q) (⟨1, j + i + 1⟩ : Q) := by
  simp only [Qeq]; push_cast; ring_uor

/-- Denominator positivity of the double summand `c'_j · (c_i · 1/(i+j+1))`. -/
private theorem Gden (c c' : Nat → Q) (hc : ∀ i, 0 < (c i).den) (hc' : ∀ i, 0 < (c' i).den)
    (j i : Nat) : 0 < (mul (c' j) (mul (c i) (⟨1, i + j + 1⟩ : Q))).den :=
  Qmul_den_pos (hc' j) (Qmul_den_pos (hc i) (Nat.succ_pos (i + j)))

/-- Expand `qHil c c' d` into the double sum `Σ_j Σ_i c'_j·(c_i·1/(i+j+1))` (pull the outer
    coefficient into the inner sum). -/
private theorem qHil_expand (c c' : Nat → Q) (hc : ∀ i, 0 < (c i).den) (hc' : ∀ i, 0 < (c' i).den)
    (d : Nat) :
    Qeq (qHil c c' d)
      (qsumL (fun j => qsumL (fun i => mul (c' j) (mul (c i) (⟨1, i + j + 1⟩ : Q)))
        (List.range d)) (List.range d)) := by
  show Qeq (qsumL (fun j => mul (c' j) (innerHil c d j)) (List.range d)) _
  refine qsumL_congr (fun j => ?_) (List.range d)
  -- `c'_j · Σ_i (c_i·1/(i+j+1)) = Σ_i c'_j·(c_i·1/(i+j+1))`
  exact Qeq_symm (qsumL_smul (c' j) (fun i => mul (c i) (⟨1, i + j + 1⟩ : Q)) (hc' j)
    (fun i => Qmul_den_pos (hc i) (Nat.succ_pos (i + j))) (List.range d))

/-- Collapse the swapped double sum `Σ_i Σ_j c'_j·(c_i·1/(i+j+1))` back to `qHil c' c d`. -/
private theorem qHil_collapse (c c' : Nat → Q) (hc : ∀ i, 0 < (c i).den) (hc' : ∀ i, 0 < (c' i).den)
    (d : Nat) :
    Qeq (qsumL (fun i => qsumL (fun j => mul (c' j) (mul (c i) (⟨1, i + j + 1⟩ : Q)))
        (List.range d)) (List.range d))
      (qHil c' c d) := by
  show Qeq _ (qsumL (fun i => mul (c i) (innerHil c' d i)) (List.range d))
  refine qsumL_congr (fun i => ?_) (List.range d)
  -- inner over `j`: `Σ_j c'_j·(c_i·1/(i+j+1)) = c_i · Σ_j c'_j·1/(j+i+1) = c_i · innerHil c' d i`
  refine Qeq_trans (b := qsumL (fun j => mul (c i) (mul (c' j) (⟨1, i + j + 1⟩ : Q)))
      (List.range d))
    (qsumL_den _ (fun j => Qmul_den_pos (hc i) (Qmul_den_pos (hc' j) (Nat.succ_pos (i + j))))
      (List.range d))
    (qsumL_congr (fun j => Qmul_left_comm (c' j) (c i) (⟨1, i + j + 1⟩ : Q)) (List.range d)) ?_
  refine Qeq_trans (b := mul (c i) (qsumL (fun j => mul (c' j) (⟨1, i + j + 1⟩ : Q)) (List.range d)))
    (Qmul_den_pos (hc i) (qsumL_den _ (fun j => Qmul_den_pos (hc' j) (Nat.succ_pos (i + j)))
      (List.range d)))
    (qsumL_smul (c i) (fun j => mul (c' j) (⟨1, i + j + 1⟩ : Q)) (hc i)
      (fun j => Qmul_den_pos (hc' j) (Nat.succ_pos (i + j))) (List.range d))
    ?_
  -- reindex the denominator `i+j+1 → j+i+1` to land on `innerHil c' d i`
  refine Qmul_congr (Qeq_refl (c i)) ?_
  exact qsumL_congr (fun j => Qmul_congr (Qeq_refl (c' j)) (denEq i j)) (List.range d)

/-- **★ THE RATIONAL HILBERT FORM IS SYMMETRIC**: `qHil c c' d = qHil c' c d`. Expand the outer
    coefficient into the inner sum, exchange the two `qsumL` (Fubini), refactor the summand and
    reindex `i+j+1 = j+i+1` to recover `qHil c' c d`. -/
theorem qHil_comm (c c' : Nat → Q) (hc : ∀ i, 0 < (c i).den) (hc' : ∀ i, 0 < (c' i).den)
    (d : Nat) : Qeq (qHil c c' d) (qHil c' c d) :=
  Qeq_trans (b := qsumL (fun i => qsumL (fun j =>
        mul (c' j) (mul (c i) (⟨1, i + j + 1⟩ : Q))) (List.range d)) (List.range d))
    (qsumL_den _ (fun i => qsumL_den _ (fun j => Gden c c' hc hc' j i) (List.range d))
      (List.range d))
    (Qeq_trans
      (b := qsumL (fun j => qsumL (fun i => mul (c' j) (mul (c i) (⟨1, i + j + 1⟩ : Q)))
        (List.range d)) (List.range d))
      (qsumL_den _ (fun j => qsumL_den _ (fun i => Gden c c' hc hc' j i) (List.range d))
        (List.range d))
      (qHil_expand c c' hc hc' d)
      (qsumL_qsumL_swap (fun j i => mul (c' j) (mul (c i) (⟨1, i + j + 1⟩ : Q)))
        (fun j i => Gden c c' hc hc' j i) (List.range d) (List.range d)))
    (qHil_collapse c c' hc hc' d)

end Multiplicity.UOR.Bridge.F1Square.Square
