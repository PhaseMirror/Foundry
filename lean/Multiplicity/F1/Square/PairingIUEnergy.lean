/-
# A uniform self-energy bound on a uniformly-L²-Cauchy sequence of tests

Given a sequence of `L2Test`s that is uniformly (ψ-free) squared-Cauchy — `L2CauchyU Φ`,
i.e. `d²(Φⱼ, Φₖ) ≤ (1/(j+1) + 1/(k+1))²` — this file proves a SINGLE, index-uniform bound on
each member's own L² energy:

    `⟨Φⱼ, Φⱼ⟩  ≤  2·selfBnd(Φ₀) + 8`     for EVERY `j`.

The proof is one bilinear (parallelogram) expansion.  With `x := Φⱼ`, `y := Φ₀`, and
`w := x − 2y`, the identity

    `2·d²(x,y) + 2·⟨y,y⟩ − ⟨x,x⟩  =  ⟨w,w⟩  ≥ 0`

gives `⟨x,x⟩ ≤ 2·d²(x,y) + 2·⟨y,y⟩`; then `d²(Φⱼ,Φ₀) ≤ 4` (from the Cauchy hypothesis at `k = 0`,
since `1/(j+1) + 1 ≤ 2`) and `⟨Φ₀,Φ₀⟩ ≤ selfBnd(Φ₀)` close the estimate.

## Honest scope
This is a *uniform bound* on the energies of an L²-Cauchy sequence — a completeness-side
book-keeping fact.  It is NOT a positivity, definiteness, or surjectivity statement, and it makes
no claim about RH: the crux (step 4, band-coupling positivity) has no fields here.

Pure Lean 4 core (no Mathlib), choice-free.  The only ring tactic used is `ring_uor` (ℚ/ℤ
equalities); all abstract-`Real` algebra is manual `Req`/`RsumL` rearrangement.  Additive
rearrangements go through the choice-free `RsumL` normal-form engine (flatten / `RsumL_perm` with
explicit `List.Perm` constructors / `RsumL_cancel_anywhere`) — never `decide` on `List.Perm`,
whose `Decidable` instance pulls `Classical.choice`.  Axiom-audited to `{propext, Quot.sound}` by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1.Square.L2Complete

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Additive flattening helpers (choice-free, from the `RsumL` engine in `RAddNF`).
-- ===========================================================================

/-- `(A+B)+(C+D) ≈ RsumL [A,B,C,D]` — quaternary (balanced) flattening. -/
private theorem add4_RsumL (A B C D : Real) :
    Req (Radd (Radd A B) (Radd C D)) (RsumL [A, B, C, D]) :=
  Req_trans (Radd_congr (Radd_eq_RsumL A B) (Radd_eq_RsumL C D))
    (Req_symm (RsumL_append [A, B] [C, D]))

/-- `(((x+y)+z)+w) ≈ RsumL [x,y,z,w]` — left-nested degree-4 flattening. -/
private theorem flat4L (x y z w : Real) :
    Req (Radd (Radd (Radd x y) z) w) (RsumL [x, y, z, w]) :=
  Req_trans (Radd_congr (Radd_eq_RsumL3 x y z) (RsumL_singleton w))
    (Req_symm (RsumL_append [x, y, z] [w]))

/-- Flatten the expanded distance tree: `(a − (b+b)) + c ≈ RsumL [a, −b, −b, c]`. -/
private theorem flatDexp (a b c : Real) :
    Req (Radd (Rsub a (Radd b b)) c) (RsumL [a, Rneg b, Rneg b, c]) :=
  Req_trans
    (Radd_congr
      (Req_trans (Radd_congr (Req_refl a) (Rneg_Radd b b))
        (Req_symm (Radd_assoc a (Rneg b) (Rneg b))))
      (Req_refl c))
    (flat4L a (Rneg b) (Rneg b) c)

/-- The pure additive identity behind the bilinear expansion:
    `(a − b) − (b − c) ≈ (a − (b+b)) + c`. -/
private theorem sub_sub_id (a b c : Real) :
    Req (Rsub (Rsub a b) (Rsub b c)) (Radd (Rsub a (Radd b b)) c) :=
  Req_trans
    (Req_trans
      (Radd_congr (Req_refl (Rsub a b))
        (Req_trans (Rneg_Radd b (Rneg c)) (Radd_congr (Req_refl (Rneg b)) (Rneg_neg c))))
      (add4_RsumL a (Rneg b) (Rneg b) c))
    (Req_symm (flatDexp a b c))

-- ===========================================================================
-- The bilinear expansion helper.
-- ===========================================================================

/-- Second-slot subtraction on the pairing (derived locally so this file needs only
    `L2Complete` in its header): `⟨φ, χ − ψ⟩ ≈ ⟨φ,χ⟩ − ⟨φ,ψ⟩`. -/
private theorem innerI_sub_right' (φ χ ψ : L2Test) :
    Req (innerI φ (L2Test.sub χ ψ)) (Rsub (innerI φ χ) (innerI φ ψ)) :=
  Req_trans (innerI_symm φ (L2Test.sub χ ψ))
    (Req_trans (innerI_sub_left χ ψ φ)
      (Rsub_congr (innerI_symm χ φ) (innerI_symm ψ φ)))

/-- **The self-pairing of a difference expands bilinearly**:
    `⟨A−B, A−B⟩ ≈ (⟨A,A⟩ − 2⟨A,B⟩) + ⟨B,B⟩`. -/
private theorem innerI_sub_self_expand (A B : L2Test) :
    Req (innerI (L2Test.sub A B) (L2Test.sub A B))
        (Radd (Rsub (innerI A A) (Radd (innerI A B) (innerI A B))) (innerI B B)) :=
  Req_trans
    (Req_trans (innerI_sub_left A B (L2Test.sub A B))
      (Rsub_congr (innerI_sub_right' A A B)
        (Req_trans (innerI_sub_right' B A B)
          (Rsub_congr (innerI_symm B A) (Req_refl (innerI B B))))))
    (sub_sub_id (innerI A A) (innerI A B) (innerI B B))

-- ===========================================================================
-- The parallelogram doubling bound on the energy.
-- ===========================================================================

/-- **THE DOUBLING BOUND**: `⟨φ,φ⟩ ≤ 2·d²(φ,ψ) + 2·⟨ψ,ψ⟩`.  From `⟨w,w⟩ ≥ 0` with
    `w := φ − 2ψ`: expanding `⟨w,w⟩ = ⟨φ,φ⟩ − 4⟨φ,ψ⟩ + 4⟨ψ,ψ⟩` and reorganising shows
    `2·d²(φ,ψ) + 2·⟨ψ,ψ⟩ − ⟨φ,φ⟩ ≈ ⟨w,w⟩`, which is non-negative. -/
private theorem energy_le_2dist_2self (φ ψ : L2Test) :
    Rle (innerI φ φ)
        (Radd (Radd (dist2I φ ψ) (dist2I φ ψ)) (Radd (innerI ψ ψ) (innerI ψ ψ))) := by
  -- Flatten the distance `d²(φ,ψ) = ⟨φ,φ⟩ − 2⟨φ,ψ⟩ + ⟨ψ,ψ⟩` to a canonical sum.
  have hDL : Req (dist2I φ ψ)
      (RsumL [innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ]) :=
    Req_trans (innerI_sub_self_expand φ ψ)
      (flatDexp (innerI φ φ) (innerI φ ψ) (innerI ψ ψ))
  -- `2·d²(φ,ψ)`.
  have hDD : Req (Radd (dist2I φ ψ) (dist2I φ ψ))
      (RsumL [innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ,
              innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ]) :=
    Req_trans (Radd_congr hDL hDL)
      (Req_symm (RsumL_append
        [innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ]
        [innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ]))
  -- `2·d²(φ,ψ) + 2·⟨ψ,ψ⟩`.
  have hM : Req (Radd (Radd (dist2I φ ψ) (dist2I φ ψ)) (Radd (innerI ψ ψ) (innerI ψ ψ)))
      (RsumL [innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ,
              innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ,
              innerI ψ ψ, innerI ψ ψ]) :=
    Req_trans (Radd_congr hDD (Radd_eq_RsumL (innerI ψ ψ) (innerI ψ ψ)))
      (Req_symm (RsumL_append
        [innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ,
         innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ]
        [innerI ψ ψ, innerI ψ ψ]))
  -- Subtract `⟨φ,φ⟩` (the `Rsub` shape forced by `Rle_of_Rnonneg_Rsub`).
  have hLHS : Req
      (Rsub (Radd (Radd (dist2I φ ψ) (dist2I φ ψ)) (Radd (innerI ψ ψ) (innerI ψ ψ))) (innerI φ φ))
      (RsumL [innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ,
              innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ,
              innerI ψ ψ, innerI ψ ψ, Rneg (innerI φ φ)]) :=
    Req_trans (Radd_congr hM (RsumL_singleton (Rneg (innerI φ φ))))
      (Req_symm (RsumL_append
        [innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ,
         innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ,
         innerI ψ ψ, innerI ψ ψ]
        [Rneg (innerI φ φ)]))
  -- Cancel the `⟨φ,φ⟩ + (−⟨φ,φ⟩)` pair.
  have hcancel : Req
      (RsumL [innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ,
              innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ,
              innerI ψ ψ, innerI ψ ψ, Rneg (innerI φ φ)])
      (RsumL [innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ,
              Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ, innerI ψ ψ, innerI ψ ψ]) :=
    RsumL_cancel_anywhere (innerI φ φ)
      [innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ]
      [Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ, innerI ψ ψ, innerI ψ ψ]
      []
  -- Reorder the canonical sum: gather the four `−⟨φ,ψ⟩` then the four `⟨ψ,ψ⟩` (two swaps).
  have hperm : Req
      (RsumL [innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ,
              Rneg (innerI φ ψ), Rneg (innerI φ ψ), innerI ψ ψ, innerI ψ ψ, innerI ψ ψ])
      (RsumL [innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), Rneg (innerI φ ψ),
              Rneg (innerI φ ψ), innerI ψ ψ, innerI ψ ψ, innerI ψ ψ, innerI ψ ψ]) :=
    RsumL_perm
      (List.Perm.cons (innerI φ φ)
        (List.Perm.cons (Rneg (innerI φ ψ))
          (List.Perm.cons (Rneg (innerI φ ψ))
            ((List.Perm.swap (Rneg (innerI φ ψ)) (innerI ψ ψ)
                [Rneg (innerI φ ψ), innerI ψ ψ, innerI ψ ψ, innerI ψ ψ]).trans
              (List.Perm.cons (Rneg (innerI φ ψ))
                (List.Perm.swap (Rneg (innerI φ ψ)) (innerI ψ ψ)
                  [innerI ψ ψ, innerI ψ ψ, innerI ψ ψ]))))))
  -- Expand `⟨w,w⟩ = ⟨φ,φ⟩ − 4⟨φ,ψ⟩ + 4⟨ψ,ψ⟩` for `w = φ − 2ψ`.
  have hWexp : Req
      (innerI (L2Test.sub φ (L2Test.add ψ ψ)) (L2Test.sub φ (L2Test.add ψ ψ)))
      (Radd (Rsub (innerI φ φ)
              (Radd (Radd (innerI φ ψ) (innerI φ ψ)) (Radd (innerI φ ψ) (innerI φ ψ))))
            (Radd (Radd (innerI ψ ψ) (innerI ψ ψ)) (Radd (innerI ψ ψ) (innerI ψ ψ)))) :=
    Req_trans (innerI_sub_self_expand φ (L2Test.add ψ ψ))
      (Radd_congr
        (Rsub_congr (Req_refl (innerI φ φ))
          (Radd_congr (innerI_add_right φ ψ ψ) (innerI_add_right φ ψ ψ)))
        (Req_trans (innerI_add_left ψ ψ (L2Test.add ψ ψ))
          (Radd_congr (innerI_add_right ψ ψ ψ) (innerI_add_right ψ ψ ψ))))
  -- Flatten `⟨φ,φ⟩ − 4⟨φ,ψ⟩` to `RsumL [⟨φ,φ⟩, −⟨φ,ψ⟩, −⟨φ,ψ⟩, −⟨φ,ψ⟩, −⟨φ,ψ⟩]`.
  have hL1 : Req
      (Rsub (innerI φ φ)
        (Radd (Radd (innerI φ ψ) (innerI φ ψ)) (Radd (innerI φ ψ) (innerI φ ψ))))
      (RsumL [innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ),
              Rneg (innerI φ ψ), Rneg (innerI φ ψ)]) :=
    Req_trans
      (Radd_congr (Req_refl (innerI φ φ))
        (Req_trans
          (Rneg_Radd (Radd (innerI φ ψ) (innerI φ ψ)) (Radd (innerI φ ψ) (innerI φ ψ)))
          (Radd_congr (Rneg_Radd (innerI φ ψ) (innerI φ ψ))
                      (Rneg_Radd (innerI φ ψ) (innerI φ ψ)))))
      (Radd_congr (Req_refl (innerI φ φ))
        (add4_RsumL (Rneg (innerI φ ψ)) (Rneg (innerI φ ψ))
                    (Rneg (innerI φ ψ)) (Rneg (innerI φ ψ))))
  -- Flatten `⟨w,w⟩` to `RsumL S_W`.
  have hWfull : Req
      (innerI (L2Test.sub φ (L2Test.add ψ ψ)) (L2Test.sub φ (L2Test.add ψ ψ)))
      (RsumL [innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ), Rneg (innerI φ ψ),
              Rneg (innerI φ ψ), innerI ψ ψ, innerI ψ ψ, innerI ψ ψ, innerI ψ ψ]) :=
    Req_trans hWexp
      (Req_trans
        (Radd_congr hL1
          (add4_RsumL (innerI ψ ψ) (innerI ψ ψ) (innerI ψ ψ) (innerI ψ ψ)))
        (Req_symm (RsumL_append
          [innerI φ φ, Rneg (innerI φ ψ), Rneg (innerI φ ψ),
           Rneg (innerI φ ψ), Rneg (innerI φ ψ)]
          [innerI ψ ψ, innerI ψ ψ, innerI ψ ψ, innerI ψ ψ])))
  -- Assemble: the residual `Rsub` equals `⟨w,w⟩`, hence is non-negative.
  have hEq : Req
      (innerI (L2Test.sub φ (L2Test.add ψ ψ)) (L2Test.sub φ (L2Test.add ψ ψ)))
      (Rsub (Radd (Radd (dist2I φ ψ) (dist2I φ ψ)) (Radd (innerI ψ ψ) (innerI ψ ψ)))
            (innerI φ φ)) :=
    Req_symm (Req_trans hLHS (Req_trans hcancel (Req_trans hperm (Req_symm hWfull))))
  exact Rle_of_Rnonneg_Rsub
    (Rnonneg_congr hEq (innerI_self_nonneg (L2Test.sub φ (L2Test.add ψ ψ))))

-- ===========================================================================
-- The uniform self-energy bound.
-- ===========================================================================

/-- **THE UNIFORM SELF-ENERGY BOUND**: on a uniformly-L²-Cauchy sequence, every member's energy is
    bounded by the same constant `2·selfBnd(Φ₀) + 8` — independent of the index `j`. -/
theorem innerI_self_le_uniform (Φ : Nat → L2Test) (h : L2CauchyU Φ) (j : Nat) :
    Rle (innerI (Φ j) (Φ j))
        (ofQ (⟨2 * ((selfBnd (Φ 0) : Nat) : Int) + 8, 1⟩ : Q) Nat.one_pos) := by
  -- `d²(Φⱼ,Φ₀) ≤ 4`, from the Cauchy bound `(1/(j+1) + 1)²` at `k = 0`.
  have hE2 : Qle (add (⟨1, j + 1⟩ : Q) (⟨1, 0 + 1⟩ : Q)) (⟨2, 1⟩ : Q) := by
    simp only [Qle, add]; push_cast; omega
  have hEnn : (0 : Int) ≤ (add (⟨1, j + 1⟩ : Q) (⟨1, 0 + 1⟩ : Q)).num :=
    Qadd_num_nonneg_loc (by show (0 : Int) ≤ 1; decide) (by show (0 : Int) ≤ 1; decide)
  have hEd : 0 < (add (⟨1, j + 1⟩ : Q) (⟨1, 0 + 1⟩ : Q)).den :=
    add_den_pos (Nat.succ_pos j) (Nat.succ_pos 0)
  have hQle : Qle (mul (add (⟨1, j + 1⟩ : Q) (⟨1, 0 + 1⟩ : Q))
                       (add (⟨1, j + 1⟩ : Q) (⟨1, 0 + 1⟩ : Q))) (⟨4, 1⟩ : Q) :=
    Qmul_le_mul hEd (by decide) hEd hEnn hEnn hE2 hE2
  have hD4 : Rle (dist2I (Φ j) (Φ 0)) (ofQ (⟨4, 1⟩ : Q) (by decide)) :=
    Rle_trans (h j 0) (Rle_ofQ_ofQ _ (by decide) hQle)
  -- `⟨Φ₀,Φ₀⟩ ≤ selfBnd(Φ₀)`.
  have hbb : Rle (innerI (Φ 0) (Φ 0))
      (ofQ (⟨((selfBnd (Φ 0) : Nat) : Int), 1⟩ : Q) Nat.one_pos) :=
    innerI_self_le_selfBnd (Φ 0)
  -- Push both bounds through `⟨Φⱼ,Φⱼ⟩ ≤ 2·d²(Φⱼ,Φ₀) + 2·⟨Φ₀,Φ₀⟩`.
  have hcomb : Rle
      (Radd (Radd (dist2I (Φ j) (Φ 0)) (dist2I (Φ j) (Φ 0)))
            (Radd (innerI (Φ 0) (Φ 0)) (innerI (Φ 0) (Φ 0))))
      (Radd (Radd (ofQ (⟨4, 1⟩ : Q) (by decide)) (ofQ (⟨4, 1⟩ : Q) (by decide)))
            (Radd (ofQ (⟨((selfBnd (Φ 0) : Nat) : Int), 1⟩ : Q) Nat.one_pos)
                  (ofQ (⟨((selfBnd (Φ 0) : Nat) : Int), 1⟩ : Q) Nat.one_pos))) :=
    Radd_le_add (Radd_le_add hD4 hD4) (Radd_le_add hbb hbb)
  -- Collapse the `ofQ` arithmetic: `4 + 4 + selfBnd + selfBnd = 2·selfBnd + 8`.
  have hQeq : Qeq
      (add (add (⟨4, 1⟩ : Q) (⟨4, 1⟩ : Q))
           (add (⟨((selfBnd (Φ 0) : Nat) : Int), 1⟩ : Q) (⟨((selfBnd (Φ 0) : Nat) : Int), 1⟩ : Q)))
      (⟨2 * ((selfBnd (Φ 0) : Nat) : Int) + 8, 1⟩ : Q) := by
    simp only [Qeq, add]; push_cast; ring_uor
  have hcollapse : Req
      (Radd (Radd (ofQ (⟨4, 1⟩ : Q) (by decide)) (ofQ (⟨4, 1⟩ : Q) (by decide)))
            (Radd (ofQ (⟨((selfBnd (Φ 0) : Nat) : Int), 1⟩ : Q) Nat.one_pos)
                  (ofQ (⟨((selfBnd (Φ 0) : Nat) : Int), 1⟩ : Q) Nat.one_pos)))
      (ofQ (⟨2 * ((selfBnd (Φ 0) : Nat) : Int) + 8, 1⟩ : Q) Nat.one_pos) :=
    Req_trans
      (Radd_congr (Radd_ofQ_ofQ (by decide) (by decide))
                  (Radd_ofQ_ofQ Nat.one_pos Nat.one_pos))
      (Req_trans
        (Radd_ofQ_ofQ (add_den_pos (by decide) (by decide))
                      (add_den_pos Nat.one_pos Nat.one_pos))
        (ofQ_congr
          (add_den_pos (add_den_pos (by decide) (by decide))
                       (add_den_pos Nat.one_pos Nat.one_pos))
          Nat.one_pos hQeq))
  exact Rle_trans (energy_le_2dist_2self (Φ j) (Φ 0))
    (Rle_trans hcomb (Rle_of_Req hcollapse))

end Multiplicity.UOR.Bridge.F1Square.Square
