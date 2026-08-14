/-
F1 square — **the pre-Hilbert layer, brick 56** (`MomentPairingNeg.lean`): **THE PAIRING IS
LINEAR, AND HENCE CONTINUOUS IN THE TEST** — brick 52 gave additivity; this gives the remaining
half of linearity and reads off the consequence:

    `⟪−φ, ψ⟫ ≈ −⟪φ, ψ⟫`                       (`crossMomL2_neg_left`)
    `⟪φ − ψ, χ⟫ ≈ ⟪φ, χ⟫ − ⟪ψ, χ⟫`            (`crossMomL2_sub_left`)
    `|⟪φ, χ⟫ − ⟪ψ, χ⟫| ≤ 2·M_{φ−ψ}·M_χ`       (`crossMomL2_dist_le`)

The last is the pairing's modulus of continuity: two tests that are close in the bound `M` of
their difference have close pairings against every fixed `χ`. With bricks 49–52 the moment
pairing is now a symmetric, bilinear, Cauchy–Schwarz-obeying, continuous form.

Negation needs the same care as addition did: `⟪−φ, ψ⟫` and `⟪φ, ψ⟫` are `Rlim`s along
*different* rescale schedules (`crossScale (−φ) ψ` need not equal `crossScale φ ψ`), so there is
no termwise comparison. The fix is brick 52's: compare at a COMMON CUT, where
`crossMomSum_neg_left` makes the identity exact, and let brick 52's `crossMomSum_dist_limit` —
the pairing may be read off *any* deep partial sum — carry both sides. Subtraction is then free,
since `L2Test.sub φ ψ` is by definition `L2Test.add φ (L2Test.neg ψ)`.

HONEST SCOPE. Linearity in the left slot and continuity in the test, for the `ℓ²` pairing of
moment sequences of bounded-Lipschitz tests on `[0,1]`; with brick 50's symmetry both transfer to
the right slot. Nothing here touches the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.MomentPairingBilinear

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `|a − b| = |b − a|` (local: the copies in bricks 49/51/52 are private). -/
private theorem abs_flip (a b : Real) : Req (Rabs (Rsub a b)) (Rabs (Rsub b a)) :=
  Req_trans (Req_symm (Rabs_Rneg (Rsub a b))) (Rabs_congr (Rneg_Rsub_flip a b))

/-- Each pairing is within `3/(k+1)` of its partial sum at any cut beyond its own schedule
    (local copy of brick 52's private helper). -/
private theorem dist_at (φ ψ : L2Test) (c : Nat) (h : crossScale φ ψ ≤ c) (k : Nat) :
    Rle (Rabs (Rsub (crossMomSum φ ψ (c * (k + 1))) (crossMomL2 φ ψ)))
      (ofQ (⟨3, k + 1⟩ : Q) (Nat.succ_pos k)) := by
  obtain ⟨d, hd⟩ := Nat.le.dest (Nat.mul_le_mul_right (k + 1) h)
  rw [← hd]
  exact crossMomSum_dist_limit φ ψ k d

/-- `(−a) − (−b) ≈ b − a`. -/
private theorem sub_neg_neg (a b : Real) : Req (Rsub (Rneg a) (Rneg b)) (Rsub b a) :=
  Req_trans (Radd_congr (Req_refl (Rneg a)) (Rneg_neg b))
    (Radd_comm (Rneg a) b)

/-- The moment sequence of a negated test is the negated moment sequence. -/
theorem momSeq_neg (φ : L2Test) (n : Nat) :
    Req (momSeq (L2Test.neg φ) n) (Rneg (momSeq φ n)) :=
  innerI_neg_left φ (powTest n)

/-- **The finite identity is exact**: the cross partial sums negate in the left slot. -/
theorem crossMomSum_neg_left (φ ψ : L2Test) (N : Nat) :
    Req (crossMomSum (L2Test.neg φ) ψ N) (Rneg (crossMomSum φ ψ N)) :=
  Req_trans (innerN_congr N (fun n _ => momSeq_neg φ n) (fun _ _ => Req_refl _))
    (innerN_neg_left (momSeq φ) (momSeq ψ) N)

/-- **THE PAIRING NEGATES IN THE LEFT SLOT**: `⟪−φ, ψ⟫ ≈ −⟪φ, ψ⟫`. Compared at a common cut,
    since the two limits run along different rescale schedules. -/
theorem crossMomL2_neg_left (φ ψ : L2Test) :
    Req (crossMomL2 (L2Test.neg φ) ψ) (Rneg (crossMomL2 φ ψ)) := by
  have hgap : ∀ k : Nat,
      Rle (Rabs (Rsub (crossMomL2 (L2Test.neg φ) ψ) (Rneg (crossMomL2 φ ψ))))
        (ofQ (⟨((6 : Nat) : Int), k + 1⟩ : Q) (Nat.succ_pos k)) := by
    intro k
    have hA : crossScale (L2Test.neg φ) ψ ≤ crossScale (L2Test.neg φ) ψ + crossScale φ ψ :=
      Nat.le_add_right _ _
    have hB : crossScale φ ψ ≤ crossScale (L2Test.neg φ) ψ + crossScale φ ψ :=
      Nat.le_add_left _ _
    have dA := dist_at (L2Test.neg φ) ψ _ hA k
    have dB := dist_at φ ψ _ hB k
    -- the second half: the finite identity turns `S_A − (−L_B)` into `L_B − S_B`
    have hsecond : Rle (Rabs (Rsub
        (crossMomSum (L2Test.neg φ) ψ
          ((crossScale (L2Test.neg φ) ψ + crossScale φ ψ) * (k + 1)))
        (Rneg (crossMomL2 φ ψ))))
        (ofQ (⟨3, k + 1⟩ : Q) (Nat.succ_pos k)) := by
      refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr
        (crossMomSum_neg_left φ ψ _) (Req_refl _)))) ?_
      refine Rle_trans (Rle_of_Req (Rabs_congr (sub_neg_neg _ _))) ?_
      exact Rle_trans (Rle_of_Req (abs_flip _ _)) dB
    refine Rle_trans (Rabs_sub_triangle _
      (crossMomSum (L2Test.neg φ) ψ
        ((crossScale (L2Test.neg φ) ψ + crossScale φ ψ) * (k + 1))) _) ?_
    refine Rle_trans (Radd_le_add (Rle_trans (Rle_of_Req (abs_flip _ _)) dA) hsecond) ?_
    refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (Nat.succ_pos k) (Nat.succ_pos k))) ?_
    refine Rle_ofQ_ofQ _ (Nat.succ_pos k) ?_
    show (3 * ((k + 1 : Nat) : Int) + 3 * ((k + 1 : Nat) : Int)) * ((k + 1 : Nat) : Int)
        ≤ ((6 : Nat) : Int) * (((k + 1) * (k + 1) : Nat) : Int)
    push_cast
    have e : (3 * ((k : Int) + 1) + 3 * ((k : Int) + 1)) * ((k : Int) + 1)
        = 6 * (((k : Int) + 1) * ((k : Int) + 1)) := by ring_uor
    omega
  refine Rle_antisymm (Rle_of_Rsub_le_eps (C := 6) (fun k => ?_))
    (Rle_of_Rsub_le_eps (C := 6) (fun k => ?_))
  · exact Rle_of_Rabs_le (hgap k)
  · exact Rle_of_Rabs_le (Rle_trans (Rle_of_Req (abs_flip _ _)) (hgap k))

/-- **THE PAIRING SUBTRACTS IN THE LEFT SLOT**: `⟪φ − ψ, χ⟫ ≈ ⟪φ, χ⟫ − ⟪ψ, χ⟫`. Free from
    additivity and negation, since `L2Test.sub` is `add _ (neg _)` by definition. -/
theorem crossMomL2_sub_left (φ ψ χ : L2Test) :
    Req (crossMomL2 (L2Test.sub φ ψ) χ)
      (Rsub (crossMomL2 φ χ) (crossMomL2 ψ χ)) :=
  Req_trans (crossMomL2_add_left φ (L2Test.neg ψ) χ)
    (Radd_congr (Req_refl _) (crossMomL2_neg_left ψ χ))

/-- **THE PAIRING IS CONTINUOUS IN THE TEST**: `|⟪φ, χ⟫ − ⟪ψ, χ⟫| ≤ 2·M_{φ−ψ}·M_χ` — the
    modulus of continuity, read off brick 50's uniform bound at the difference test. -/
theorem crossMomL2_dist_le (φ ψ χ : L2Test) :
    Rle (Rabs (Rsub (crossMomL2 φ χ) (crossMomL2 ψ χ)))
      (ofQ (crossBound (L2Test.sub φ ψ) χ 0) (crossBound_den (L2Test.sub φ ψ) χ 0)) :=
  Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (crossMomL2_sub_left φ ψ χ))))
    (crossMomL2_abs_le (L2Test.sub φ ψ) χ)

end Multiplicity.UOR.Bridge.F1Square.Square
