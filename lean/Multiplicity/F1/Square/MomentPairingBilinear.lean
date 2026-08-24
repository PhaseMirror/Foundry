/-
F1 square — **the pre-Hilbert layer, brick 52** (`MomentPairingBilinear.lean`): **THE MOMENT
PAIRING IS BILINEAR** — the last inner-product law, and the one the substrate makes hardest:

    `⟪φ + ψ, χ⟫  ≈  ⟪φ, χ⟫ + ⟪ψ, χ⟫`   (`crossMomL2_add_left`).

At every *finite* truncation the identity is exact — the moment map is additive
(`innerI_add_left`), so the coefficient vectors add and `innerN_add_left` splits the sum. The
difficulty is entirely in the limit: `RReg` is not closed under addition in this substrate, and
the three pairings are `Rlim`s along three *different* rescale schedules, so there is no common
index at which to compare them termwise.

The fix is to stop comparing at the schedules and compare at a COMMON CUT. The window bound gives
more than convergence along the chosen schedule: *any* cut beyond the `j`-th scheduled one is
already within `1/(j+1)` of the scheduled read (`crossMomSum_dist_scheduled`), hence within
`3/(j+1)` of the limit (`crossMomSum_dist_limit`). So at the cut
`N_k = (c₁ + c₂ + c₃)·(k+1)` — beyond all three schedules at once — all three pairings are
within `3/(k+1)` of their partial sums, which satisfy the identity exactly. The total gap is
`9/(k+1)` for every `k`, and the Archimedean criterion closes both directions.

`crossMomSum_dist_limit` is the reusable half: it says the pairing may be read off *any*
sufficiently deep partial sum, not only the rescaled ones the construction happened to use.

HONEST SCOPE. Bilinearity in the left slot for the `ℓ²` pairing of moment sequences of
bounded-Lipschitz tests on `[0,1]`; with brick 50's symmetry it transfers to the right slot.
Nothing here touches the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MomentPairingCS

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `|a − b| = |b − a|` (local: the copies in bricks 49/51 are private). -/
private theorem abs_swap (a b : Real) : Req (Rabs (Rsub a b)) (Rabs (Rsub b a)) :=
  Req_trans (Req_symm (Rabs_Rneg (Rsub a b))) (Rabs_congr (Rneg_Rsub_flip a b))

/-- `|a − c| ≤ |a − b| + |b − c|`. -/
theorem Rabs_sub_triangle (a b c : Real) :
    Rle (Rabs (Rsub a c)) (Radd (Rabs (Rsub a b)) (Rabs (Rsub b c))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Radd_Rsub_Rsub b c a)))) ?_
  refine Rle_trans (Rabs_Radd (Rsub b c) (Rsub a b)) ?_
  exact Rle_of_Req (Radd_comm (Rabs (Rsub b c)) (Rabs (Rsub a b)))

/-- **Any deep cut agrees with the scheduled read**: beyond the `j`-th scheduled cut, a partial
    cross sum is within `1/(j+1)` of `crossIdx φ ψ j`. -/
theorem crossMomSum_dist_scheduled (φ ψ : L2Test) (j d : Nat) :
    Rle (Rabs (Rsub (crossMomSum φ ψ (crossScale φ ψ * (j + 1) + d)) (crossIdx φ ψ j)))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) :=
  Rle_trans (crossMomSum_diff_abs_le φ ψ (crossScale φ ψ * (j + 1)) d)
    (Rle_ofQ_ofQ _ (Nat.succ_pos j) (crossScale_bound φ ψ j))

/-- **THE PAIRING MAY BE READ OFF ANY DEEP CUT**: beyond the `j`-th scheduled cut, a partial
    cross sum is within `3/(j+1)` of `⟪φ, ψ⟫`. -/
theorem crossMomSum_dist_limit (φ ψ : L2Test) (j d : Nat) :
    Rle (Rabs (Rsub (crossMomSum φ ψ (crossScale φ ψ * (j + 1) + d)) (crossMomL2 φ ψ)))
      (ofQ (⟨3, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  refine Rle_trans (Rabs_sub_triangle _ (crossIdx φ ψ j) _) ?_
  refine Rle_trans (Radd_le_add (crossMomSum_dist_scheduled φ ψ j d)
    (crossMomL2_approx φ ψ j)) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (Nat.succ_pos j) (Nat.succ_pos j))) ?_
  exact Rle_ofQ_ofQ _ (Nat.succ_pos j) (by
    show (1 * ((j + 1 : Nat) : Int) + 2 * ((j + 1 : Nat) : Int)) * ((j + 1 : Nat) : Int)
        ≤ 3 * (((j + 1) * (j + 1) : Nat) : Int)
    push_cast
    have e : (1 * ((j : Int) + 1) + 2 * ((j : Int) + 1)) * ((j : Int) + 1)
        = 3 * (((j : Int) + 1) * ((j : Int) + 1)) := by ring_uor
    omega)

/-- The moment sequence of a sum is the sum of the moment sequences. -/
theorem momSeq_add (φ ψ : L2Test) (n : Nat) :
    Req (momSeq (L2Test.add φ ψ) n) (Radd (momSeq φ n) (momSeq ψ n)) :=
  innerI_add_left φ ψ (powTest n)

/-- **The finite identity is exact**: the cross partial sums are additive in the left slot. -/
theorem crossMomSum_add_left (φ ψ χ : L2Test) (N : Nat) :
    Req (crossMomSum (L2Test.add φ ψ) χ N)
      (Radd (crossMomSum φ χ N) (crossMomSum ψ χ N)) :=
  Req_trans
    (innerN_congr N (fun n _ => momSeq_add φ ψ n) (fun _ _ => Req_refl _))
    (innerN_add_left (momSeq φ) (momSeq ψ) (momSeq χ) N)

/-- Each pairing is within `3/(k+1)` of its partial sum at any cut beyond its own schedule. -/
private theorem tri_dist (φ ψ : L2Test) (c : Nat) (h : crossScale φ ψ ≤ c) (k : Nat) :
    Rle (Rabs (Rsub (crossMomSum φ ψ (c * (k + 1))) (crossMomL2 φ ψ)))
      (ofQ (⟨3, k + 1⟩ : Q) (Nat.succ_pos k)) := by
  obtain ⟨d, hd⟩ := Nat.le.dest (Nat.mul_le_mul_right (k + 1) h)
  rw [← hd]
  exact crossMomSum_dist_limit φ ψ k d

/-- **THE PAIRING IS BILINEAR IN THE LEFT SLOT**: `⟪φ + ψ, χ⟫ ≈ ⟪φ, χ⟫ + ⟪ψ, χ⟫`. -/
theorem crossMomL2_add_left (φ ψ χ : L2Test) :
    Req (crossMomL2 (L2Test.add φ ψ) χ)
      (Radd (crossMomL2 φ χ) (crossMomL2 ψ χ)) := by
  have hgap : ∀ k : Nat,
      Rle (Rabs (Rsub (crossMomL2 (L2Test.add φ ψ) χ)
        (Radd (crossMomL2 φ χ) (crossMomL2 ψ χ))))
        (ofQ (⟨((9 : Nat) : Int), k + 1⟩ : Q) (Nat.succ_pos k)) := by
    intro k
    -- the common cut, beyond all three schedules
    have hA : crossScale (L2Test.add φ ψ) χ
        ≤ crossScale (L2Test.add φ ψ) χ + crossScale φ χ + crossScale ψ χ :=
      Nat.le_trans (Nat.le_add_right _ _) (Nat.le_add_right _ _)
    have hB : crossScale φ χ
        ≤ crossScale (L2Test.add φ ψ) χ + crossScale φ χ + crossScale ψ χ :=
      Nat.le_trans (Nat.le_add_left _ _) (Nat.le_add_right _ _)
    have hC : crossScale ψ χ
        ≤ crossScale (L2Test.add φ ψ) χ + crossScale φ χ + crossScale ψ χ :=
      Nat.le_add_left _ _
    have dA := tri_dist (L2Test.add φ ψ) χ _ hA k
    have dB := tri_dist φ χ _ hB k
    have dC := tri_dist ψ χ _ hC k
    -- the second half: substitute the exact finite identity, then split
    have hsecond : Rle (Rabs (Rsub
        (crossMomSum (L2Test.add φ ψ) χ
          ((crossScale (L2Test.add φ ψ) χ + crossScale φ χ + crossScale ψ χ) * (k + 1)))
        (Radd (crossMomL2 φ χ) (crossMomL2 ψ χ))))
        (Radd (ofQ (⟨3, k + 1⟩ : Q) (Nat.succ_pos k))
              (ofQ (⟨3, k + 1⟩ : Q) (Nat.succ_pos k))) := by
      refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr
        (crossMomSum_add_left φ ψ χ _) (Req_refl _)))) ?_
      refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_Radd_Radd _ _ _ _))) ?_
      exact Rle_trans (Rabs_Radd _ _) (Radd_le_add dB dC)
    -- |L_A − (L_B+L_C)| ≤ |L_A − S_A| + |S_A − (L_B+L_C)|
    refine Rle_trans (Rabs_sub_triangle _
      (crossMomSum (L2Test.add φ ψ) χ
        ((crossScale (L2Test.add φ ψ) χ + crossScale φ χ + crossScale ψ χ) * (k + 1))) _) ?_
    refine Rle_trans (Radd_le_add (Rle_trans (Rle_of_Req (abs_swap _ _)) dA) hsecond) ?_
    refine Rle_trans (Rle_of_Req (Radd_congr (Req_refl _)
      (Radd_ofQ_ofQ (Nat.succ_pos k) (Nat.succ_pos k)))) ?_
    refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (Nat.succ_pos k)
      (add_den_pos (Nat.succ_pos k) (Nat.succ_pos k)))) ?_
    refine Rle_ofQ_ofQ _ (Nat.succ_pos k) ?_
    show (3 * (((k + 1) * (k + 1) : Nat) : Int) + (3 * ((k + 1 : Nat) : Int)
          + 3 * ((k + 1 : Nat) : Int)) * ((k + 1 : Nat) : Int)) * ((k + 1 : Nat) : Int)
        ≤ ((9 : Nat) : Int) * (((k + 1) * ((k + 1) * (k + 1)) : Nat) : Int)
    push_cast
    have e : (3 * (((k : Int) + 1) * ((k : Int) + 1))
          + (3 * ((k : Int) + 1) + 3 * ((k : Int) + 1)) * ((k : Int) + 1)) * ((k : Int) + 1)
        = 9 * (((k : Int) + 1) * (((k : Int) + 1) * ((k : Int) + 1))) := by ring_uor
    omega
  refine Rle_antisymm (Rle_of_Rsub_le_eps (C := 9) (fun k => ?_))
    (Rle_of_Rsub_le_eps (C := 9) (fun k => ?_))
  · exact Rle_of_Rabs_le (hgap k)
  · exact Rle_of_Rabs_le (Rle_trans (Rle_of_Req (abs_swap _ _)) (hgap k))

end Multiplicity.UOR.Bridge.F1Square.Square
