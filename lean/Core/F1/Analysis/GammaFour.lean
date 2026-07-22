/-
F1 square — the **fourth Stieltjes constant `γ₄` as a genuine constructive real** (`Rgamma4`), the
arithmetic-side prerequisite for the `n = 5` coupling rung (`λ₅`).

Mirror of `GammaThree.lean` (which built `γ₃`) one degree up: the EM-accelerated defining sequence
`g₄(j) = Σ_{k≤j+1}(ln k)⁴/k − (1/5)·(ln(j+1))⁵`, whose per-step difference `e₄` is the trapezoidal
residual, bounded in a summable envelope `e₄ ∈ [−a⁴/(p(p+1)), 4a³/(p(p+1))]` (`a = ln(p+1)`), then
dyadic-block-telescoped to a regular sequence `g₄SeqDyadic` (`RReg`) whose Bishop limit is `γ₄`.

The quintic factoring `a⁵ − b⁵ = (a−b)(a⁴+a³b+a²b²+ab³+b⁴)` is the centerpiece; the cubic/quartic
infrastructure (`logCube`, `logQuartic`, `quartic_diff_identity`, `W3_le_4a3`, `Csum`, the block caps)
is reused from `GammaThree`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import Core.F1.Analysis.GammaThree

namespace UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

-- ===========================================================================
-- Defs: the quartic-log harmonic term, its partial sum, the quintic `(ln)⁵`, and `g₄`.
-- ===========================================================================

/-- The quartic-log harmonic term `(ln k)⁴/k` (for `k ≥ 1`). -/
def lnQuartOver (k : Nat) (hk : 1 ≤ k) : Real :=
  Rmul (logQuartic k hk) (ofQ ⟨1, k⟩ (by show 0 < k; omega))

theorem lnQuartOver_nonneg (k : Nat) (hk : 1 ≤ k) : Rnonneg (lnQuartOver k hk) :=
  Rnonneg_Rmul (logQuartic_nonneg k hk)
    (Rnonneg_ofQ (by show 0 < k; omega) (by show (0 : Int) ≤ 1; decide))

/-- The partial sum `S₄(N) = Σ_{k=1}^N (ln k)⁴/k`. -/
def lnQuartSum : Nat → Real
  | 0 => zero
  | (n + 1) => Radd (lnQuartSum n) (lnQuartOver (n + 1) (by omega))

theorem lnQuartSum_step (n : Nat) : Rle (lnQuartSum n) (lnQuartSum (n + 1)) :=
  Rle_self_Radd_right (lnQuartOver_nonneg (n + 1) (by omega))

theorem lnQuartSum_mono {a b : Nat} (hab : a ≤ b) : Rle (lnQuartSum a) (lnQuartSum b) := by
  induction hab with
  | refl => exact Rle_refl _
  | step _ ih => exact Rle_trans ih (lnQuartSum_step _)

/-- The quintic `(ln N)⁵` as a constructive real (`= (ln N)⁴ · ln N`). -/
def logQuintic (N : Nat) (hN : 1 ≤ N) : Real :=
  Rmul (logQuartic N hN) (logN N hN)

theorem logQuintic_nonneg (N : Nat) (hN : 1 ≤ N) : Rnonneg (logQuintic N hN) :=
  Rnonneg_Rmul (logQuartic_nonneg N hN) (Rnonneg_logN N hN)

/-- The **defining sequence** `g₄(j+1) = S₄(j+1) − (1/5)·(ln (j+1))⁵`.  `γ₄ = Rlim g₄SeqDyadic`. -/
def g4Seq (j : Nat) : Real :=
  Rsub (lnQuartSum (j + 1)) (Rmul (ofQ ⟨1, 5⟩ (by decide)) (logQuintic (j + 1) (by omega)))

/-- The per-step difference `e₄ = (ln(p+1))⁴/(p+1) − (1/5)((ln(p+1))⁵ − (ln p)⁵)` (`p ≥ 1`). -/
def e4Step (p : Nat) (hp : 1 ≤ p) : Real :=
  Rsub (lnQuartOver (p + 1) (Nat.succ_pos p))
    (Rmul (ofQ ⟨1, 5⟩ (by decide))
      (Rsub (logQuintic (p + 1) (Nat.succ_pos p)) (logQuintic p hp)))

/-- **`g₄(j+1) − g₄(j) ≈ e₄`** (telescoping). -/
theorem g4Seq_step_eq (j : Nat) :
    Req (Rsub (g4Seq (j + 1)) (g4Seq j)) (e4Step (j + 1) (Nat.succ_pos j)) := by
  have hA : Req (Rsub (lnQuartSum (j + 2)) (lnQuartSum (j + 1)))
      (lnQuartOver (j + 2) (Nat.succ_pos (j + 1))) := by
    show Req (Rsub (Radd (lnQuartSum (j + 1)) (lnQuartOver (j + 2) (by omega))) (lnQuartSum (j + 1)))
             (lnQuartOver (j + 2) (Nat.succ_pos (j + 1)))
    refine Req_trans (Rsub_congr (Radd_comm (lnQuartSum (j + 1)) (lnQuartOver (j + 2) (by omega)))
      (Req_refl _)) ?_
    refine Req_trans (Radd_assoc (lnQuartOver (j + 2) (by omega)) (lnQuartSum (j + 1))
      (Rneg (lnQuartSum (j + 1)))) ?_
    exact Req_trans (Radd_congr (Req_refl _) (Radd_neg (lnQuartSum (j + 1)))) (Radd_zero _)
  have hB : Req (Rsub (Rmul (ofQ ⟨1, 5⟩ (by decide)) (logQuintic (j + 2) (by omega)))
        (Rmul (ofQ ⟨1, 5⟩ (by decide)) (logQuintic (j + 1) (by omega))))
      (Rmul (ofQ ⟨1, 5⟩ (by decide))
        (Rsub (logQuintic (j + 2) (by omega)) (logQuintic (j + 1) (by omega)))) :=
    Req_symm (Rmul_sub_distrib (ofQ ⟨1, 5⟩ (by decide)) (logQuintic (j + 2) (by omega))
      (logQuintic (j + 1) (by omega)))
  refine Req_trans (Rsub_sub_sub (lnQuartSum (j + 2))
    (Rmul (ofQ ⟨1, 5⟩ (by decide)) (logQuintic (j + 2) (by omega)))
    (lnQuartSum (j + 1)) (Rmul (ofQ ⟨1, 5⟩ (by decide)) (logQuintic (j + 1) (by omega)))) ?_
  exact Rsub_congr hA hB

-- ===========================================================================
-- The quintic factoring `a⁵ − b⁵ = (a−b)·(a⁴+a³b+a²b²+ab³+b⁴)`.
-- ===========================================================================

/-- **`a·(X·b) ≈ b·(X·a)`** — swap the two outer scalars around a common middle factor `X`. -/
theorem Rmul_swap_outer (a b X : Real) : Req (Rmul a (Rmul X b)) (Rmul b (Rmul X a)) :=
  Req_trans (Rmul_left_comm3 a X b)
    (Req_trans (Rmul_congr (Req_refl X) (Rmul_comm a b)) (Req_symm (Rmul_left_comm3 b X a)))

/-- **`(Y·x)·y ≈ (Y·y)·x`** — swap the last two factors of a left-nested product. -/
theorem Rmul_swap_last (Y x y : Real) : Req (Rmul (Rmul Y x) y) (Rmul (Rmul Y y) x) :=
  Req_trans (Rmul_assoc Y x y)
    (Req_trans (Rmul_congr (Req_refl Y) (Rmul_comm x y)) (Req_symm (Rmul_assoc Y y x)))

set_option maxHeartbeats 8000000 in
/-- **`(a−b)(a⁴ + a³b + a²b² + ab³ + b⁴) ≈ a⁵ − b⁵`** — the difference-of-quintics factoring
    (the quintic analogue of `quartic_diff_identity`), `a⁵ = ((((a·a)·a)·a)·a)`. -/
theorem quintic_diff_identity (a b : Real) :
    Req (Rmul (Rsub a b)
          (Radd (Radd (Radd (Radd (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul a a) a) b))
              (Rmul (Rmul (Rmul a a) b) b)) (Rmul (Rmul (Rmul a b) b) b))
            (Rmul (Rmul (Rmul b b) b) b)))
        (Rsub (Rmul (Rmul (Rmul (Rmul a a) a) a) a) (Rmul (Rmul (Rmul (Rmul b b) b) b) b)) := by
  refine Req_trans (Rmul_sub_distrib_right a b
    (Radd (Radd (Radd (Radd (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul a a) a) b))
        (Rmul (Rmul (Rmul a a) b) b)) (Rmul (Rmul (Rmul a b) b) b))
      (Rmul (Rmul (Rmul b b) b) b))) ?_
  -- a·W4 distributes
  have haS : Req (Rmul a (Radd (Radd (Radd (Radd (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul a a) a) b))
        (Rmul (Rmul (Rmul a a) b) b)) (Rmul (Rmul (Rmul a b) b) b)) (Rmul (Rmul (Rmul b b) b) b)))
      (Radd (Radd (Radd (Radd (Rmul a (Rmul (Rmul (Rmul a a) a) a)) (Rmul a (Rmul (Rmul (Rmul a a) a) b)))
        (Rmul a (Rmul (Rmul (Rmul a a) b) b))) (Rmul a (Rmul (Rmul (Rmul a b) b) b)))
        (Rmul a (Rmul (Rmul (Rmul b b) b) b))) :=
    Req_trans (Rmul_distrib a (Radd (Radd (Radd (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul a a) a) b))
          (Rmul (Rmul (Rmul a a) b) b)) (Rmul (Rmul (Rmul a b) b) b)) (Rmul (Rmul (Rmul b b) b) b))
      (Radd_congr (Req_trans (Rmul_distrib a (Radd (Radd (Rmul (Rmul (Rmul a a) a) a)
            (Rmul (Rmul (Rmul a a) a) b)) (Rmul (Rmul (Rmul a a) b) b)) (Rmul (Rmul (Rmul a b) b) b))
          (Radd_congr (Req_trans (Rmul_distrib a (Radd (Rmul (Rmul (Rmul a a) a) a)
                (Rmul (Rmul (Rmul a a) a) b)) (Rmul (Rmul (Rmul a a) b) b))
              (Radd_congr (Rmul_distrib a (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul a a) a) b))
                (Req_refl _))) (Req_refl _))) (Req_refl _))
  -- b·W4 distributes
  have hbS : Req (Rmul b (Radd (Radd (Radd (Radd (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul a a) a) b))
        (Rmul (Rmul (Rmul a a) b) b)) (Rmul (Rmul (Rmul a b) b) b)) (Rmul (Rmul (Rmul b b) b) b)))
      (Radd (Radd (Radd (Radd (Rmul b (Rmul (Rmul (Rmul a a) a) a)) (Rmul b (Rmul (Rmul (Rmul a a) a) b)))
        (Rmul b (Rmul (Rmul (Rmul a a) b) b))) (Rmul b (Rmul (Rmul (Rmul a b) b) b)))
        (Rmul b (Rmul (Rmul (Rmul b b) b) b))) :=
    Req_trans (Rmul_distrib b (Radd (Radd (Radd (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul a a) a) b))
          (Rmul (Rmul (Rmul a a) b) b)) (Rmul (Rmul (Rmul a b) b) b)) (Rmul (Rmul (Rmul b b) b) b))
      (Radd_congr (Req_trans (Rmul_distrib b (Radd (Radd (Rmul (Rmul (Rmul a a) a) a)
            (Rmul (Rmul (Rmul a a) a) b)) (Rmul (Rmul (Rmul a a) b) b)) (Rmul (Rmul (Rmul a b) b) b))
          (Radd_congr (Req_trans (Rmul_distrib b (Radd (Rmul (Rmul (Rmul a a) a) a)
                (Rmul (Rmul (Rmul a a) a) b)) (Rmul (Rmul (Rmul a a) b) b))
              (Radd_congr (Rmul_distrib b (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul a a) a) b))
                (Req_refl _))) (Req_refl _))) (Req_refl _))
  refine Req_trans (Rsub_congr haS hbS) ?_
  -- cross-term identifications: a·(a³b)=b·a⁴, a·(a²b²)=b·(a³b), a·(ab³)=b·(a²b²), a·b⁴=b·(ab³)
  have hx1 : Req (Rmul a (Rmul (Rmul (Rmul a a) a) b)) (Rmul b (Rmul (Rmul (Rmul a a) a) a)) :=
    Rmul_swap_outer a b (Rmul (Rmul a a) a)
  have hx2 : Req (Rmul a (Rmul (Rmul (Rmul a a) b) b)) (Rmul b (Rmul (Rmul (Rmul a a) a) b)) :=
    Req_trans (Rmul_swap_outer a b (Rmul (Rmul a a) b))
      (Rmul_congr (Req_refl b) (Rmul_swap_last (Rmul a a) b a))
  have hx3 : Req (Rmul a (Rmul (Rmul (Rmul a b) b) b)) (Rmul b (Rmul (Rmul (Rmul a a) b) b)) :=
    Req_trans (Rmul_swap_outer a b (Rmul (Rmul a b) b))
      (Rmul_congr (Req_refl b)
        (Req_trans (Rmul_swap_last (Rmul a b) b a)
          (Rmul_congr (Rmul_swap_last a b a) (Req_refl b))))
  have hx4 : Req (Rmul a (Rmul (Rmul (Rmul b b) b) b)) (Rmul b (Rmul (Rmul (Rmul a b) b) b)) :=
    Req_trans (Rmul_swap_outer a b (Rmul (Rmul b b) b))
      (Rmul_congr (Req_refl b)
        (Req_trans (Rmul_swap_last (Rmul b b) b a)
          (Rmul_congr (Req_trans (Rmul_swap_last b b a) (Rmul_congr (Rmul_comm b a) (Req_refl b)))
            (Req_refl b))))
  refine Req_trans (Rsub_congr
    (Radd_congr (Radd_congr (Radd_congr (Radd_congr (Req_refl _) hx1) hx2) hx3) hx4) (Req_refl _)) ?_
  -- telescope
  have hcancel : ∀ P S Q : Real, Req (Rsub (Radd P S) (Radd S Q)) (Rsub P Q) := by
    intro P S Q
    refine Req_trans (Radd_congr (Req_refl (Radd P S)) (Rneg_Radd S Q)) ?_
    refine Req_trans (Radd_assoc P S (Radd (Rneg S) (Rneg Q))) ?_
    refine Req_trans (Radd_congr (Req_refl P) (Req_symm (Radd_assoc S (Rneg S) (Rneg Q)))) ?_
    refine Req_trans (Radd_congr (Req_refl P) (Radd_congr (Radd_neg S) (Req_refl (Rneg Q)))) ?_
    exact Radd_congr (Req_refl P)
      (Req_trans (Radd_comm zero (Rneg Q)) (Radd_zero (Rneg Q)))
  have htel4 : ∀ P M₁ M₂ M₃ M₄ Q : Real,
      Req (Rsub (Radd (Radd (Radd (Radd P M₁) M₂) M₃) M₄)
          (Radd (Radd (Radd (Radd M₁ M₂) M₃) M₄) Q)) (Rsub P Q) := by
    intro P M₁ M₂ M₃ M₄ Q
    refine Req_trans (Rsub_congr ?_ (Req_refl _)) (hcancel P (Radd (Radd (Radd M₁ M₂) M₃) M₄) Q)
    refine Req_trans (Radd_congr ?_ (Req_refl M₄)) (Radd_assoc P (Radd (Radd M₁ M₂) M₃) M₄)
    refine Req_trans (Radd_assoc (Radd P M₁) M₂ M₃) (Req_trans (Radd_assoc P M₁ (Radd M₂ M₃)) ?_)
    exact Radd_congr (Req_refl P) (Req_symm (Radd_assoc M₁ M₂ M₃))
  refine Req_trans (htel4 (Rmul a (Rmul (Rmul (Rmul a a) a) a))
    (Rmul b (Rmul (Rmul (Rmul a a) a) a)) (Rmul b (Rmul (Rmul (Rmul a a) a) b))
    (Rmul b (Rmul (Rmul (Rmul a a) b) b)) (Rmul b (Rmul (Rmul (Rmul a b) b) b))
    (Rmul b (Rmul (Rmul (Rmul b b) b) b))) ?_
  exact Rsub_congr (Rmul_comm a (Rmul (Rmul (Rmul a a) a) a)) (Rmul_comm b (Rmul (Rmul (Rmul b b) b) b))

/-- **`(1/5)·((((Y+Y)+Y)+Y)+Y) ≈ Y`** — the rational coefficient closing the `e₄` decomposition
    (`(1/5)·5a⁴ = a⁴`). -/
theorem Rmul_fifth_five (Y : Real) :
    Req (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide)) (Radd (Radd (Radd (Radd Y Y) Y) Y) Y)) Y := by
  have hdist : Req (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide)) (Radd (Radd (Radd (Radd Y Y) Y) Y) Y))
      (Rmul (Radd (Radd (Radd (Radd (ofQ (⟨1, 5⟩ : Q) (by decide)) (ofQ (⟨1, 5⟩ : Q) (by decide)))
        (ofQ (⟨1, 5⟩ : Q) (by decide))) (ofQ (⟨1, 5⟩ : Q) (by decide))) (ofQ (⟨1, 5⟩ : Q) (by decide))) Y) := by
    refine Req_trans (Rmul_distrib (ofQ (⟨1, 5⟩ : Q) (by decide)) (Radd (Radd (Radd Y Y) Y) Y) Y) ?_
    refine Req_trans (Radd_congr (Rmul_distrib (ofQ (⟨1, 5⟩ : Q) (by decide)) (Radd (Radd Y Y) Y) Y)
      (Req_refl _)) ?_
    refine Req_trans (Radd_congr (Radd_congr (Rmul_distrib (ofQ (⟨1, 5⟩ : Q) (by decide)) (Radd Y Y) Y)
      (Req_refl _)) (Req_refl _)) ?_
    refine Req_trans (Radd_congr (Radd_congr (Radd_congr
      (Rmul_distrib (ofQ (⟨1, 5⟩ : Q) (by decide)) Y Y) (Req_refl _)) (Req_refl _)) (Req_refl _)) ?_
    refine Req_trans (Radd_congr (Radd_congr (Radd_congr
      (Req_symm (Rmul_distrib_right (ofQ (⟨1, 5⟩ : Q) (by decide)) (ofQ (⟨1, 5⟩ : Q) (by decide)) Y))
      (Req_refl _)) (Req_refl _)) (Req_refl _)) ?_
    refine Req_trans (Radd_congr (Radd_congr
      (Req_symm (Rmul_distrib_right (Radd (ofQ (⟨1, 5⟩ : Q) (by decide)) (ofQ (⟨1, 5⟩ : Q) (by decide)))
        (ofQ (⟨1, 5⟩ : Q) (by decide)) Y)) (Req_refl _)) (Req_refl _)) ?_
    refine Req_trans (Radd_congr
      (Req_symm (Rmul_distrib_right (Radd (Radd (ofQ (⟨1, 5⟩ : Q) (by decide)) (ofQ (⟨1, 5⟩ : Q) (by decide)))
        (ofQ (⟨1, 5⟩ : Q) (by decide))) (ofQ (⟨1, 5⟩ : Q) (by decide)) Y)) (Req_refl _)) ?_
    exact Req_symm (Rmul_distrib_right
      (Radd (Radd (Radd (ofQ (⟨1, 5⟩ : Q) (by decide)) (ofQ (⟨1, 5⟩ : Q) (by decide)))
        (ofQ (⟨1, 5⟩ : Q) (by decide))) (ofQ (⟨1, 5⟩ : Q) (by decide))) (ofQ (⟨1, 5⟩ : Q) (by decide)) Y)
  refine Req_trans hdist ?_
  have hcoef : Req (Radd (Radd (Radd (Radd (ofQ (⟨1, 5⟩ : Q) (by decide)) (ofQ (⟨1, 5⟩ : Q) (by decide)))
      (ofQ (⟨1, 5⟩ : Q) (by decide))) (ofQ (⟨1, 5⟩ : Q) (by decide))) (ofQ (⟨1, 5⟩ : Q) (by decide))) one := by
    refine Req_trans (Radd_congr (Radd_congr (Radd_congr (Radd_ofQ_ofQ (by decide) (by decide))
      (Req_refl _)) (Req_refl _)) (Req_refl _)) ?_
    refine Req_trans (Radd_congr (Radd_congr (Radd_ofQ_ofQ (by decide) (by decide)) (Req_refl _))
      (Req_refl _)) ?_
    refine Req_trans (Radd_congr (Radd_ofQ_ofQ (by decide) (by decide)) (Req_refl _)) ?_
    refine Req_trans (Radd_ofQ_ofQ (by decide) (by decide)) ?_
    exact Req_of_seq_Qeq (fun _ => by
      show Qeq (add (add (add (add (⟨1, 5⟩ : Q) ⟨1, 5⟩) ⟨1, 5⟩) ⟨1, 5⟩) ⟨1, 5⟩) ⟨1, 1⟩; decide)
  exact Req_trans (Rmul_congr hcoef (Req_refl Y)) (Rone_mul Y)

-- ===========================================================================
-- The `e₄` envelope bounds: `W₄ ∈ [5b⁴, 5a⁴]` ⟹ `(1/5)(a⁵−b⁵) ∈ [b⁴δ, a⁴δ]` ⟹ summable `e₄`.
-- ===========================================================================

/-- `b⁴ ≤ a⁴` for `0 ≤ b ≤ a` (quartic monotone). -/
theorem quartic_mono {a b : Real} (hb : Rnonneg b) (ha : Rnonneg a) (hab : Rle b a) :
    Rle (Rmul (Rmul (Rmul b b) b) b) (Rmul (Rmul (Rmul a a) a) a) :=
  Rle_trans (Rmul_le_Rmul_right hb (cube_mono hb ha hab))
    (Rmul_le_Rmul_left (Rnonneg_Rmul (Rnonneg_Rmul ha ha) ha) hab)

/-- `5b⁴ ≤ W₄` (each of the five terms of `W₄` is `≥ b⁴`, for `0 ≤ b ≤ a`). -/
theorem W4_ge_5b4 {a b : Real} (hb : Rnonneg b) (ha : Rnonneg a) (hab : Rle b a) :
    Rle (Radd (Radd (Radd (Radd (Rmul (Rmul (Rmul b b) b) b) (Rmul (Rmul (Rmul b b) b) b))
            (Rmul (Rmul (Rmul b b) b) b)) (Rmul (Rmul (Rmul b b) b) b)) (Rmul (Rmul (Rmul b b) b) b))
        (Radd (Radd (Radd (Radd (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul a a) a) b))
            (Rmul (Rmul (Rmul a a) b) b)) (Rmul (Rmul (Rmul a b) b) b)) (Rmul (Rmul (Rmul b b) b) b)) := by
  have h1 : Rle (Rmul (Rmul (Rmul b b) b) b) (Rmul (Rmul (Rmul a a) a) a) := quartic_mono hb ha hab
  have h2 : Rle (Rmul (Rmul (Rmul b b) b) b) (Rmul (Rmul (Rmul a a) a) b) :=
    Rmul_le_Rmul_right hb (cube_mono hb ha hab)
  have h3 : Rle (Rmul (Rmul (Rmul b b) b) b) (Rmul (Rmul (Rmul a a) b) b) :=
    Rmul_le_Rmul_right hb (Rmul_le_Rmul_right hb (Rle_trans (Rmul_le_Rmul_right hb hab)
      (Rmul_le_Rmul_left ha hab)))
  have h4 : Rle (Rmul (Rmul (Rmul b b) b) b) (Rmul (Rmul (Rmul a b) b) b) :=
    Rmul_le_Rmul_right hb (Rmul_le_Rmul_right hb (Rmul_le_Rmul_right hb hab))
  exact Radd_le_add (Radd_le_add (Radd_le_add (Radd_le_add h1 h2) h3) h4) (Rle_refl _)

/-- `W₄ ≤ 5a⁴` (each of the five terms of `W₄` is `≤ a⁴`, for `0 ≤ b ≤ a`). -/
theorem W4_le_5a4 {a b : Real} (hb : Rnonneg b) (ha : Rnonneg a) (hab : Rle b a) :
    Rle (Radd (Radd (Radd (Radd (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul a a) a) b))
            (Rmul (Rmul (Rmul a a) b) b)) (Rmul (Rmul (Rmul a b) b) b)) (Rmul (Rmul (Rmul b b) b) b))
        (Radd (Radd (Radd (Radd (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul a a) a) a))
            (Rmul (Rmul (Rmul a a) a) a)) (Rmul (Rmul (Rmul a a) a) a)) (Rmul (Rmul (Rmul a a) a) a)) := by
  have ha3 : Rnonneg (Rmul (Rmul a a) a) := Rnonneg_Rmul (Rnonneg_Rmul ha ha) ha
  have h2 : Rle (Rmul (Rmul (Rmul a a) a) b) (Rmul (Rmul (Rmul a a) a) a) := Rmul_le_Rmul_left ha3 hab
  have h3 : Rle (Rmul (Rmul (Rmul a a) b) b) (Rmul (Rmul (Rmul a a) a) a) :=
    Rle_trans (Rmul_le_Rmul_right hb (Rmul_le_Rmul_left (Rnonneg_Rmul ha ha) hab))
      (Rmul_le_Rmul_left ha3 hab)
  have h4 : Rle (Rmul (Rmul (Rmul a b) b) b) (Rmul (Rmul (Rmul a a) a) a) :=
    Rle_trans (Rmul_le_Rmul_right hb (Rmul_le_Rmul_right hb (Rmul_le_Rmul_left ha hab)))
      (Rle_trans (Rmul_le_Rmul_right hb (Rmul_le_Rmul_left (Rnonneg_Rmul ha ha) hab))
        (Rmul_le_Rmul_left ha3 hab))
  have h5 : Rle (Rmul (Rmul (Rmul b b) b) b) (Rmul (Rmul (Rmul a a) a) a) := quartic_mono hb ha hab
  exact Radd_le_add (Radd_le_add (Radd_le_add (Radd_le_add (Rle_refl _) h2) h3) h4) h5

/-- **`(1/5)(a⁵−b⁵) ≤ a⁴·δ`** (`a = ln(p+1)`, `b = ln p`, `δ = a−b`): from `quintic_diff_identity`,
    `W₄ ≤ 5a⁴` (`W4_le_5a4`), and `(1/5)·5a⁴ = a⁴` (`Rmul_fifth_five`). -/
theorem quint_diff_le (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide))
          (Rsub (logQuintic (p + 1) (Nat.succ_pos p)) (logQuintic p hp)))
        (Rmul (logQuartic (p + 1) (Nat.succ_pos p))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) := by
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl _)
    (Req_symm (quintic_diff_identity (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (Rmul_le_Rmul_left hδnn (W4_le_5a4 (Rnonneg_logN p hp) (Rnonneg_logN (p + 1) (Nat.succ_pos p))
      (logN_mono hp (Nat.le_succ p))))) ?_
  refine Rle_of_Req (Req_trans (Rmul_left_comm3 (ofQ (⟨1, 5⟩ : Q) (by decide))
    (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
    (Radd (Radd (Radd (Radd (Rmul (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p))
        (logN (p + 1) (Nat.succ_pos p))) (logN (p + 1) (Nat.succ_pos p))) (logN (p + 1) (Nat.succ_pos p)))
      (Rmul (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
        (logN (p + 1) (Nat.succ_pos p))) (logN (p + 1) (Nat.succ_pos p))))
      (Rmul (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
        (logN (p + 1) (Nat.succ_pos p))) (logN (p + 1) (Nat.succ_pos p))))
      (Rmul (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
        (logN (p + 1) (Nat.succ_pos p))) (logN (p + 1) (Nat.succ_pos p))))
      (Rmul (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
        (logN (p + 1) (Nat.succ_pos p))) (logN (p + 1) (Nat.succ_pos p)))))
    (Req_trans (Rmul_congr (Req_refl _)
      (Rmul_fifth_five (Rmul (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
        (logN (p + 1) (Nat.succ_pos p))) (logN (p + 1) (Nat.succ_pos p)))))
      (Rmul_comm (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (Rmul (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
          (logN (p + 1) (Nat.succ_pos p))) (logN (p + 1) (Nat.succ_pos p))))))

/-- **`e₄ ≥ −a⁴/(p(p+1))`** (`a = ln(p+1)`) — the summable LOWER envelope, via
    `e₄ = a⁴u − (1/5)(a⁵−b⁵) ≥ a⁴u − a⁴δ = a⁴(u−δ)` and `u − δ ≥ −1/(p(p+1))`. -/
theorem e4Step_ge_num (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (logQuartic (p + 1) (Nat.succ_pos p))
          (Rneg (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p)))))
        (e4Step p hp) := by
  have ha4nn : Rnonneg (logQuartic (p + 1) (Nat.succ_pos p)) := logQuartic_nonneg (p + 1) (Nat.succ_pos p)
  have hud : Rle (Rneg (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))))
      (Rsub (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))
        (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) := by
    have huvp : Req (Rneg (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))))
        (Rsub (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)) (ofQ (⟨1, p⟩ : Q) hp)) :=
      Req_of_seq_Qeq (fun n => by
        simp only [Rsub, Radd, Rneg, ofQ, Qeq, neg, add]; try push_cast <;> try ring_uor)
    exact Rle_trans (Rle_of_Req huvp)
      (Rsub_le_sub (Rle_refl _) (deltaLog_upper p hp))
  refine Rle_trans (Rmul_le_Rmul_left ha4nn hud) ?_
  refine Rle_trans (Rle_of_Req (Rmul_sub_distrib (logQuartic (p + 1) (Nat.succ_pos p))
    (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)) (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))) ?_
  exact Rsub_le_sub (Rle_refl _) (quint_diff_le p hp)

/-- **`b⁴·δ ≤ (1/5)(a⁵−b⁵)`** (`b = ln p`, `δ = a−b`): from `quintic_diff_identity`, `5b⁴ ≤ W₄`
    (`W4_ge_5b4`), and `(1/5)·5b⁴ = b⁴` (`Rmul_fifth_five`). -/
theorem quint_diff_ge (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (logQuartic p hp) (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
        (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide))
          (Rsub (logQuintic (p + 1) (Nat.succ_pos p)) (logQuintic p hp))) := by
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  refine Rle_trans (Rle_of_Req (Req_symm (Req_trans (Rmul_left_comm3 (ofQ (⟨1, 5⟩ : Q) (by decide))
    (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
    (Radd (Radd (Radd (Radd (Rmul (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp)) (logN p hp))
        (Rmul (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp)) (logN p hp)))
        (Rmul (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp)) (logN p hp)))
        (Rmul (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp)) (logN p hp)))
        (Rmul (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp)) (logN p hp))))
    (Req_trans (Rmul_congr (Req_refl _)
      (Rmul_fifth_five (Rmul (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp)) (logN p hp))))
      (Rmul_comm (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (Rmul (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp)) (logN p hp))))))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (Rmul_le_Rmul_left hδnn (W4_ge_5b4 (Rnonneg_logN p hp) (Rnonneg_logN (p + 1) (Nat.succ_pos p))
      (logN_mono hp (Nat.le_succ p))))) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl _)
    (quintic_diff_identity (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))

/-- **`X + X + X + X ≈ 4·X`** (repeated-add to scalar). -/
theorem Rfour_mul (X : Real) :
    Req (Radd (Radd (Radd X X) X) X) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) X) := by
  have hc : Req (ofQ (⟨4, 1⟩ : Q) (by decide))
      (Radd (Radd (Radd (ofQ (⟨1, 1⟩ : Q) (by decide)) (ofQ (⟨1, 1⟩ : Q) (by decide)))
        (ofQ (⟨1, 1⟩ : Q) (by decide))) (ofQ (⟨1, 1⟩ : Q) (by decide))) := by
    refine Req_symm (Req_trans (Radd_congr (Radd_congr (Radd_ofQ_ofQ (by decide) (by decide))
      (Req_refl _)) (Req_refl _)) ?_)
    refine Req_trans (Radd_congr (Radd_ofQ_ofQ (by decide) (by decide)) (Req_refl _)) ?_
    refine Req_trans (Radd_ofQ_ofQ (by decide) (by decide)) ?_
    exact ofQ_congr (by decide) (by decide)
      (by show Qeq (add (add (add (⟨1, 1⟩ : Q) ⟨1, 1⟩) ⟨1, 1⟩) ⟨1, 1⟩) ⟨4, 1⟩; decide)
  refine Req_symm (Req_trans (Rmul_congr hc (Req_refl X)) ?_)
  refine Req_trans (Rmul_distrib_right (Radd (Radd (ofQ (⟨1, 1⟩ : Q) (by decide))
    (ofQ (⟨1, 1⟩ : Q) (by decide))) (ofQ (⟨1, 1⟩ : Q) (by decide))) (ofQ (⟨1, 1⟩ : Q) (by decide)) X) ?_
  refine Radd_congr ?_ (Rone_mul X)
  refine Req_trans (Rmul_distrib_right (Radd (ofQ (⟨1, 1⟩ : Q) (by decide))
    (ofQ (⟨1, 1⟩ : Q) (by decide))) (ofQ (⟨1, 1⟩ : Q) (by decide)) X) ?_
  refine Radd_congr ?_ (Rone_mul X)
  exact Req_trans (Rmul_distrib_right (ofQ (⟨1, 1⟩ : Q) (by decide)) (ofQ (⟨1, 1⟩ : Q) (by decide)) X)
    (Radd_congr (Rone_mul X) (Rone_mul X))

set_option maxHeartbeats 8000000 in
/-- **`e₄ ≤ 4a³/(p(p+1))`** (`a = ln(p+1)`) — the summable UPPER envelope, via
    `e₄ = a⁴u − (1/5)(a⁵−b⁵) ≤ a⁴u − b⁴u = (a⁴−b⁴)u = δW₃u`, `δu ≤ 1/(p(p+1))`, `W₃ ≤ 4a³`. -/
theorem e4Step_le_num (p : Nat) (hp : 1 ≤ p) :
    Rle (e4Step p hp)
        (Rmul (ofQ (⟨4, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p)))
          (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
            (logN (p + 1) (Nat.succ_pos p)))) := by
  have ha3nn : Rnonneg (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
      (logN (p + 1) (Nat.succ_pos p))) := Rnonneg_Rmul (Rnonneg_Rmul_self _) (Rnonneg_logN _ _)
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hunn : Rnonneg (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)) :=
    Rnonneg_ofQ (Nat.succ_pos p) (by show (0 : Int) ≤ 1; decide)
  have hb4nn : Rnonneg (logQuartic p hp) := logQuartic_nonneg p hp
  -- W₃ ≤ 4a³
  have hW3le : Rle (Radd (Radd (Radd (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p))
          (logN (p + 1) (Nat.succ_pos p))) (logN (p + 1) (Nat.succ_pos p)))
        (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p))) (logN p hp)))
        (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) (logN p hp)))
        (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp)))
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide))
        (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
          (logN (p + 1) (Nat.succ_pos p)))) := by
    have hab : Rle (logN p hp) (logN (p + 1) (Nat.succ_pos p)) := logN_mono hp (Nat.le_succ p)
    have ha : Rnonneg (logN (p + 1) (Nat.succ_pos p)) := Rnonneg_logN (p + 1) (Nat.succ_pos p)
    have hb : Rnonneg (logN p hp) := Rnonneg_logN p hp
    refine Rle_trans (Radd_le_add (Radd_le_add (Radd_le_add (Rle_refl _)
      (Rmul_le_Rmul_left (Rnonneg_Rmul_self _) hab))
      (Rle_trans (Rmul_le_Rmul_right hb (Rmul_le_Rmul_left ha hab))
        (Rmul_le_Rmul_left (Rnonneg_Rmul ha ha) hab)))
      (Rle_trans (cube_mono hb ha hab) (Rle_refl _)))
      (Rle_of_Req (Rfour_mul (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p))
        (logN (p + 1) (Nat.succ_pos p))) (logN (p + 1) (Nat.succ_pos p)))))
  -- δ·u ≤ 1/(p(p+1))
  have hδu : Rle (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
      (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))) :=
    Rle_trans (Rmul_le_Rmul_right hunn (deltaLog_upper p hp))
      (Rle_of_Req (Req_trans (Rmul_ofQ_ofQ (a := (⟨1, p⟩ : Q)) (b := (⟨1, p + 1⟩ : Q)) hp (Nat.succ_pos p))
        (ofQ_congr (Qmul_den_pos (a := (⟨1, p⟩ : Q)) (b := (⟨1, p + 1⟩ : Q)) hp (Nat.succ_pos p))
          (Nat.mul_pos hp (Nat.succ_pos p))
          (by show Qeq (mul (⟨1, p⟩ : Q) ⟨1, p + 1⟩) ⟨1, p * (p + 1)⟩
              simp only [mul, Qeq]; try push_cast <;> try ring_uor))))
  refine Rle_trans (Rsub_le_sub (Rle_refl _) (quint_diff_ge p hp)) ?_
  refine Rle_trans (Rsub_le_sub (Rle_refl _)
    (Rmul_le_Rmul_left hb4nn (deltaLog_lower p hp))) ?_
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_sub_distrib_right (logQuartic (p + 1) (Nat.succ_pos p))
    (logQuartic p hp) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr
    (Req_symm (quartic_diff_identity (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) (Req_refl _))) ?_
  -- (δW₃)u ≈ (δu)W₃
  refine Rle_trans (Rle_of_Req (Req_trans (Rmul_assoc (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
      (Radd (Radd (Radd (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
          (logN (p + 1) (Nat.succ_pos p)))
        (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p))) (logN p hp)))
        (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) (logN p hp)))
        (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp)))
      (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
    (Req_trans (Rmul_congr (Req_refl _) (Rmul_comm _ (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
      (Req_symm (Rmul_assoc (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))
        (Radd (Radd (Radd (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
            (logN (p + 1) (Nat.succ_pos p)))
          (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p))) (logN p hp)))
          (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) (logN p hp)))
          (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp)))))))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_Rmul hδnn hunn) hW3le) ?_
  refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) ha3nn) hδu) ?_
  refine Rle_of_Req (Req_trans (Req_symm (Rmul_assoc
    (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p)))
    (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p))
      (logN (p + 1) (Nat.succ_pos p))) (logN (p + 1) (Nat.succ_pos p)))))
    (Rmul_congr (Req_trans (Rmul_ofQ_ofQ (Nat.mul_pos hp (Nat.succ_pos p)) (by decide))
      (ofQ_congr (Qmul_den_pos (Nat.mul_pos hp (Nat.succ_pos p)) (by decide))
        (Nat.mul_pos hp (Nat.succ_pos p))
        (by show Qeq (mul (⟨1, p * (p + 1)⟩ : Q) ⟨4, 1⟩) ⟨4, p * (p + 1)⟩
            simp only [mul, Qeq]; try push_cast <;> try ring_uor))) (Req_refl _)))

-- ===========================================================================
-- Brick 4: dyadic-block telescoping → regularity → `Rgamma4`.
-- ===========================================================================

/-- **Quartic block-log cap** `logN(j+2)⁴ ≤ (a+2)⁴` for `j+2 ≤ 2^{a+2}`. -/
theorem logQuart_le_block (a j : Nat) (hj : j + 2 ≤ 2 ^ (a + 2)) :
    Rle (logQuartic (j + 2) (by omega))
      (ofQ (⟨((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2), 1⟩ : Q)
        Nat.one_pos) := by
  have hcapnn : Rnonneg (ofQ (⟨((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2), 1⟩ : Q)
      Nat.one_pos) := by
    refine Rnonneg_ofQ Nat.one_pos ?_
    have := Int.ofNat_nonneg a
    exact Int.mul_nonneg (Int.mul_nonneg (by omega) (by omega)) (by omega)
  unfold logQuartic
  refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_logN _ _) (logCube_le_block a j hj)) ?_
  refine Rle_trans (Rmul_le_Rmul_left hcapnn (logN_le_block a j hj)) ?_
  exact Rle_of_Req (Req_trans (Rmul_ofQ_ofQ Nat.one_pos Nat.one_pos)
    (ofQ_congr _ _ (by simp only [mul, Qeq]; try push_cast <;> try ring_uor)))

/-- **Per-step block UPPER bound** `g₄(j+1) − g₄(j) ≤ 4(a+2)³/((j+1)(j+2))` for `j+2 ≤ 2^{a+2}`. -/
theorem g4Seq_step_le_block (a j : Nat) (hj : j + 2 ≤ 2 ^ (a + 2)) :
    Rle (Rsub (g4Seq (j + 1)) (g4Seq j))
        (ofQ (⟨4 * (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)), (j + 1) * (j + 2)⟩ : Q)
          (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1)))) := by
  refine Rle_trans (Rle_of_Req (g4Seq_step_eq j)) ?_
  refine Rle_trans (e4Step_le_num (j + 1) (Nat.succ_pos j)) ?_
  have hden : 0 < (⟨4, (j + 1) * (j + 2)⟩ : Q).den := Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1))
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hden (by show (0 : Int) ≤ 4; decide))
    (logCube_le_block a j hj)) ?_
  exact Rle_of_Req (Req_trans (Rmul_ofQ_ofQ hden Nat.one_pos)
    (ofQ_congr _ _ (by simp only [mul, Qeq]; try push_cast <;> try ring_uor)))

/-- **Per-step block LOWER bound** `g₄(j+1) − g₄(j) ≥ −(a+2)⁴/((j+1)(j+2))` for `j+2 ≤ 2^{a+2}`. -/
theorem g4Seq_step_ge_block (a j : Nat) (hj : j + 2 ≤ 2 ^ (a + 2)) :
    Rle (Rneg (ofQ (⟨((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2),
          (j + 1) * (j + 2)⟩ : Q) (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1)))))
        (Rsub (g4Seq (j + 1)) (g4Seq j)) := by
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (g4Seq_step_eq j)))
  refine Rle_trans ?_ (e4Step_ge_num (j + 1) (Nat.succ_pos j))
  have hden : 0 < (⟨1, (j + 1) * (j + 2)⟩ : Q).den :=
    Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1))
  have hofdnn : Rnonneg (ofQ (⟨1, (j + 1) * (j + 2)⟩ : Q) hden) :=
    Rnonneg_ofQ hden (by show (0 : Int) ≤ 1; decide)
  have hneg := Rle_Rneg (Rmul_le_Rmul_right hofdnn (logQuart_le_block a j hj))
  refine Rle_trans (Rle_of_Req ?_) (Rle_trans hneg (Rle_of_Req ?_))
  · apply Rneg_congr
    refine Req_symm (Req_trans (Rmul_ofQ_ofQ Nat.one_pos hden) (ofQ_congr _ _ ?_))
    simp only [mul, Qeq]; try push_cast <;> try ring_uor
  · exact Req_symm (Rmul_neg_right _ _)

/-- **Inner block UPPER gap** (`d`-induction): for `N+d+1 ≤ 2^{a+2}`,
    `g₄(N+d) − g₄(N) ≤ Csum (4(a+2)³) (N+d) − Csum (4(a+2)³) N`. -/
theorem g4Seq_diff_le_block (a N : Nat) : ∀ (d : Nat), N + d + 1 ≤ 2 ^ (a + 2) →
    Rle (Rsub (g4Seq (N + d)) (g4Seq N))
        (ofQ (Qsub (Csum (4 * (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2))) (N + d))
            (Csum (4 * (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2))) N))
          (Qsub_den_pos (Csum_den_pos _ (N + d)) (Csum_den_pos _ N))) := by
  intro d
  induction d with
  | zero =>
      intro _
      simp only [Nat.add_zero]
      apply Rle_of_Req
      refine Req_trans (Radd_neg (g4Seq N)) (Req_symm ?_)
      apply Req_of_seq_Qeq; intro n
      simp only [ofQ, zero, Qsub, add, neg, Qeq]; push_cast <;> try ring_uor
  | succ d ih =>
      intro hd
      have ihd := ih (by omega)
      exact Rle_trans
        (Rle_of_Req (Req_symm (Rsub_split (g4Seq (N + d + 1)) (g4Seq (N + d)) (g4Seq N))))
        (Rle_trans
          (Radd_le_add (g4Seq_step_le_block a (N + d) (by omega)) ihd)
          (Rle_of_Req (Req_trans (Radd_ofQ_ofQ _ _)
            (ofQ_congr _ _ (Qadd_Qsub_comm _
              (Csum (4 * (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2))) (N + d))
              (Csum (4 * (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2))) N))))))

/-- **Inner block LOWER gap** (`d`-induction): for `N+d+1 ≤ 2^{a+2}`,
    `g₄(N+d) − g₄(N) ≥ −(Csum ((a+2)⁴) (N+d) − Csum ((a+2)⁴) N)`. -/
theorem g4Seq_diff_ge_block (a N : Nat) : ∀ (d : Nat), N + d + 1 ≤ 2 ^ (a + 2) →
    Rle (Rneg (ofQ (Qsub (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) (N + d))
            (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) N))
          (Qsub_den_pos (Csum_den_pos _ (N + d)) (Csum_den_pos _ N))))
        (Rsub (g4Seq (N + d)) (g4Seq N)) := by
  intro d
  induction d with
  | zero =>
      intro _
      simp only [Nat.add_zero]
      apply Rle_of_Req
      refine Req_trans ?_ (Req_symm (Radd_neg (g4Seq N)))
      apply Req_of_seq_Qeq; intro n
      simp only [Rneg, ofQ, zero, Qsub, add, neg, Qeq]; push_cast <;> try ring_uor
  | succ d ih =>
      intro hd
      have ihd := ih (by omega)
      have hstepd : 0 < (⟨((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2),
          (N + d + 1) * (N + d + 2)⟩ : Q).den :=
        Nat.mul_pos (Nat.succ_pos (N + d)) (Nat.succ_pos (N + d + 1))
      have hgapd : 0 < (Qsub (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) (N + d))
          (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) N)).den :=
        Qsub_den_pos (Csum_den_pos _ (N + d)) (Csum_den_pos _ N)
      have heq : Req (Rneg (ofQ (Qsub (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) (N + d + 1))
              (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) N))
            (Qsub_den_pos (Csum_den_pos _ (N + d + 1)) (Csum_den_pos _ N))))
          (Radd (Rneg (ofQ (⟨((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2),
                (N + d + 1) * (N + d + 2)⟩ : Q) hstepd))
                (Rneg (ofQ (Qsub (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) (N + d))
                  (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) N)) hgapd))) :=
        Req_trans (Rneg_congr (Req_trans
          (ofQ_congr _ _ (Qeq_symm (Qadd_Qsub_comm _
            (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) (N + d))
            (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) N))))
          (Req_symm (Radd_ofQ_ofQ hstepd hgapd)))) (Rneg_Radd _ _)
      exact Rle_trans (Rle_of_Req heq)
        (Rle_trans (Radd_le_add (g4Seq_step_ge_block a (N + d) (by omega)) ihd)
          (Rle_of_Req (Rsub_split (g4Seq (N + d + 1)) (g4Seq (N + d)) (g4Seq N))))

/-- **Per-block UPPER bound** `g₄(2^{a+1}) − g₄(2^a) ≤ 4(a+2)³/2^a`. -/
theorem g4Seq_block_le (a : Nat) :
    Rle (Rsub (g4Seq (2 ^ (a + 1))) (g4Seq (2 ^ a)))
        (ofQ (⟨4 * (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)), 2 ^ a⟩ : Q)
          (Nat.pos_pow_of_pos a (by decide))) := by
  have e1 : (2 : Nat) ^ (a + 1) = 2 ^ a + 2 ^ a := by rw [Nat.pow_succ]; omega
  have hp1 : 1 ≤ (2 : Nat) ^ a := Nat.one_le_two_pow
  have hcon : 2 ^ a + 2 ^ a + 1 ≤ 2 ^ (a + 2) := by
    have e2 : (2 : Nat) ^ (a + 2) = 2 ^ (a + 1) + 2 ^ (a + 1) := by rw [Nat.pow_succ]; omega
    omega
  rw [e1]
  refine Rle_trans (g4Seq_diff_le_block a (2 ^ a) (2 ^ a) hcon) ?_
  have hmid : 0 < (Qsub (⟨4 * (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)), 2 ^ a + 1⟩ : Q)
      ⟨4 * (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)), 2 ^ a + 2 ^ a + 1⟩).den :=
    Qsub_den_pos (Nat.succ_pos (2 ^ a)) (Nat.succ_pos (2 ^ a + 2 ^ a))
  exact Rle_trans
    (Rle_ofQ_ofQ (Qsub_den_pos (Csum_den_pos _ (2 ^ a + 2 ^ a)) (Csum_den_pos _ (2 ^ a))) hmid
      (Csum_tail_le (4 * (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2))) (2 ^ a) (2 ^ a)))
    (Rle_ofQ_ofQ hmid (Nat.pos_pow_of_pos a (by decide))
      (Qsub_block_le (4 * (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)))
        (Int.mul_nonneg (by decide) (Int.mul_nonneg (Int.mul_nonneg
          (by have := Int.ofNat_nonneg a; omega) (by have := Int.ofNat_nonneg a; omega))
          (by have := Int.ofNat_nonneg a; omega))) (2 ^ a)))

/-- **Per-block LOWER bound** `g₄(2^{a+1}) − g₄(2^a) ≥ −(a+2)⁴/2^a`. -/
theorem g4Seq_block_ge (a : Nat) :
    Rle (Rneg (ofQ (⟨((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2), 2 ^ a⟩ : Q)
          (Nat.pos_pow_of_pos a (by decide))))
        (Rsub (g4Seq (2 ^ (a + 1))) (g4Seq (2 ^ a))) := by
  have e1 : (2 : Nat) ^ (a + 1) = 2 ^ a + 2 ^ a := by rw [Nat.pow_succ]; omega
  have hp1 : 1 ≤ (2 : Nat) ^ a := Nat.one_le_two_pow
  have hcon : 2 ^ a + 2 ^ a + 1 ≤ 2 ^ (a + 2) := by
    have e2 : (2 : Nat) ^ (a + 2) = 2 ^ (a + 1) + 2 ^ (a + 1) := by rw [Nat.pow_succ]; omega
    omega
  rw [e1]
  refine Rle_trans (Rle_Rneg ?_) (g4Seq_diff_ge_block a (2 ^ a) (2 ^ a) hcon)
  have hmid : 0 < (Qsub (⟨((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2), 2 ^ a + 1⟩ : Q)
      ⟨((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2), 2 ^ a + 2 ^ a + 1⟩).den :=
    Qsub_den_pos (Nat.succ_pos (2 ^ a)) (Nat.succ_pos (2 ^ a + 2 ^ a))
  exact Rle_trans
    (Rle_ofQ_ofQ (Qsub_den_pos (Csum_den_pos _ (2 ^ a + 2 ^ a)) (Csum_den_pos _ (2 ^ a))) hmid
      (Csum_tail_le (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) (2 ^ a) (2 ^ a)))
    (Rle_ofQ_ofQ hmid (Nat.pos_pow_of_pos a (by decide))
      (Qsub_block_le (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2))
        (Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg (by have := Int.ofNat_nonneg a; omega)
          (by have := Int.ofNat_nonneg a; omega)) (by have := Int.ofNat_nonneg a; omega))
          (by have := Int.ofNat_nonneg a; omega)) (2 ^ a)))

-- ===========================================================================
-- Reindex domination `M(j) = 2j+22` (more slack than `γ₃`'s `2j+14`, to dominate the QUARTIC tail).
-- Upper antiderivative `Q_U(m) = 8m³+72m²+264m+408`; lower `Q_L(m) = 2m⁴+24m³+132m²+408m+598`.
-- ===========================================================================

/-- γ₄ reindex `M(j) = 2j+22`. -/
def gamma4Midx (j : Nat) : Nat := 2 * j + 22

theorem gamma4Midx_mono {j k : Nat} (h : j ≤ k) : gamma4Midx j ≤ gamma4Midx k := by
  simp only [gamma4Midx]; omega

/-- `384k+5184 ≤ 2^{k+22}` (upper linear increment). -/
theorem g4_linU (k : Nat) : 384 * k + 5184 ≤ 2 ^ (k + 22) := by
  induction k with
  | zero => decide
  | succ m ih =>
      have hp : (2 : Nat) ^ (m + 1 + 22) = 2 ^ (m + 22) * 2 := by
        rw [show m + 1 + 22 = (m + 22) + 1 from by omega, Nat.pow_succ]
      omega

/-- `48(2k+22)²+384(2k+22)+880 ≤ 2^{k+22}` (upper quadratic increment). -/
theorem g4_quadincU (k : Nat) :
    48 * (2 * k + 22) * (2 * k + 22) + 384 * (2 * k + 22) + 880 ≤ 2 ^ (k + 22) := by
  induction k with
  | zero => decide
  | succ m ih =>
      have hp : (2 : Nat) ^ (m + 1 + 22) = 2 ^ (m + 22) * 2 := by
        rw [show m + 1 + 22 = (m + 22) + 1 from by omega, Nat.pow_succ]
      have hexp : 48 * (2 * (m + 1) + 22) * (2 * (m + 1) + 22) + 384 * (2 * (m + 1) + 22) + 880
          = (48 * (2 * m + 22) * (2 * m + 22) + 384 * (2 * m + 22) + 880) + (384 * m + 5184) := by
        have hi : ((48 * (2 * (m + 1) + 22) * (2 * (m + 1) + 22) + 384 * (2 * (m + 1) + 22) + 880 : Nat) : Int)
            = (((48 * (2 * m + 22) * (2 * m + 22) + 384 * (2 * m + 22) + 880) + (384 * m + 5184) : Nat) : Int) := by
          push_cast; ring_uor
        exact_mod_cast hi
      have hlin := g4_linU m
      rw [hp, hexp]; omega

/-- `8(2j+22)³+72(2j+22)²+264(2j+22)+408 ≤ 2^{j+22}` (Q_U at the reindex; cubic). -/
theorem g4_cube_linU (j : Nat) :
    8 * (2 * j + 22) * (2 * j + 22) * (2 * j + 22) + 72 * (2 * j + 22) * (2 * j + 22)
      + 264 * (2 * j + 22) + 408 ≤ 2 ^ (j + 22) := by
  induction j with
  | zero => decide
  | succ k ih =>
      have hp : (2 : Nat) ^ (k + 1 + 22) = 2 ^ (k + 22) * 2 := by
        rw [show k + 1 + 22 = (k + 22) + 1 from by omega, Nat.pow_succ]
      have hexp : 8 * (2 * (k + 1) + 22) * (2 * (k + 1) + 22) * (2 * (k + 1) + 22)
            + 72 * (2 * (k + 1) + 22) * (2 * (k + 1) + 22) + 264 * (2 * (k + 1) + 22) + 408
          = (8 * (2 * k + 22) * (2 * k + 22) * (2 * k + 22) + 72 * (2 * k + 22) * (2 * k + 22)
              + 264 * (2 * k + 22) + 408)
            + (48 * (2 * k + 22) * (2 * k + 22) + 384 * (2 * k + 22) + 880) := by
        have hi : ((8 * (2 * (k + 1) + 22) * (2 * (k + 1) + 22) * (2 * (k + 1) + 22)
              + 72 * (2 * (k + 1) + 22) * (2 * (k + 1) + 22) + 264 * (2 * (k + 1) + 22) + 408 : Nat) : Int)
            = (((8 * (2 * k + 22) * (2 * k + 22) * (2 * k + 22) + 72 * (2 * k + 22) * (2 * k + 22)
                + 264 * (2 * k + 22) + 408)
              + (48 * (2 * k + 22) * (2 * k + 22) + 384 * (2 * k + 22) + 880) : Nat) : Int) := by
          push_cast; ring_uor
        exact_mod_cast hi
      have hquad := g4_quadincU k
      rw [hp, hexp]; omega

/-- **Reindex domination (upper)** `Q_U(M)·(j+1) ≤ 2^M` for `M = 2j+22`. -/
theorem g4_domination_U (j : Nat) :
    (8 * (2 * j + 22) * (2 * j + 22) * (2 * j + 22) + 72 * (2 * j + 22) * (2 * j + 22)
      + 264 * (2 * j + 22) + 408) * (j + 1) ≤ 2 ^ (2 * j + 22) := by
  have h1 : j + 1 ≤ 2 ^ j := lt_two_pow j
  have h2 := g4_cube_linU j
  have h3 := Nat.mul_le_mul h2 h1
  have h4 : (2 : Nat) ^ (j + 22) * 2 ^ j = 2 ^ (2 * j + 22) := by rw [← Nat.pow_add]; congr 1; omega
  omega

/-- **Upper antiderivative anchor** `T_U(M(j)) ≤ 1/(j+1)`. -/
theorem g4_TU_le (j : Nat) :
    Qle (⟨(8 * gamma4Midx j * gamma4Midx j * gamma4Midx j + 72 * gamma4Midx j * gamma4Midx j
          + 264 * gamma4Midx j + 408 : Int), 2 ^ gamma4Midx j⟩ : Q) ⟨1, j + 1⟩ := by
  simp only [Qle, gamma4Midx]; push_cast
  have hcast : (((8 * (2 * j + 22) * (2 * j + 22) * (2 * j + 22) + 72 * (2 * j + 22) * (2 * j + 22)
        + 264 * (2 * j + 22) + 408) * (j + 1) : Nat) : Int) ≤ ((2 ^ (2 * j + 22) : Nat) : Int) := by
    exact_mod_cast g4_domination_U j
  push_cast at hcast; omega

/-- `768k+10752 ≤ 2^{k+22}` (lower linear increment). -/
theorem g4_linL (k : Nat) : 768 * k + 10752 ≤ 2 ^ (k + 22) := by
  induction k with
  | zero => decide
  | succ m ih =>
      have hp : (2 : Nat) ^ (m + 1 + 22) = 2 ^ (m + 22) * 2 := by
        rw [show m + 1 + 22 = (m + 22) + 1 from by omega, Nat.pow_succ]
      omega

/-- `96(2k+22)²+960(2k+22)+2656 ≤ 2^{k+22}` (lower quadratic increment). -/
theorem g4_quadincL (k : Nat) :
    96 * (2 * k + 22) * (2 * k + 22) + 960 * (2 * k + 22) + 2656 ≤ 2 ^ (k + 22) := by
  induction k with
  | zero => decide
  | succ m ih =>
      have hp : (2 : Nat) ^ (m + 1 + 22) = 2 ^ (m + 22) * 2 := by
        rw [show m + 1 + 22 = (m + 22) + 1 from by omega, Nat.pow_succ]
      have hexp : 96 * (2 * (m + 1) + 22) * (2 * (m + 1) + 22) + 960 * (2 * (m + 1) + 22) + 2656
          = (96 * (2 * m + 22) * (2 * m + 22) + 960 * (2 * m + 22) + 2656) + (768 * m + 10752) := by
        have hi : ((96 * (2 * (m + 1) + 22) * (2 * (m + 1) + 22) + 960 * (2 * (m + 1) + 22) + 2656 : Nat) : Int)
            = (((96 * (2 * m + 22) * (2 * m + 22) + 960 * (2 * m + 22) + 2656) + (768 * m + 10752) : Nat) : Int) := by
          push_cast; ring_uor
        exact_mod_cast hi
      have hlin := g4_linL m
      rw [hp, hexp]; omega

/-- `16(2k+22)³+192(2k+22)²+880(2k+22)+1568 ≤ 2^{k+22}` (lower cubic increment). -/
theorem g4_cubincL (k : Nat) :
    16 * (2 * k + 22) * (2 * k + 22) * (2 * k + 22) + 192 * (2 * k + 22) * (2 * k + 22)
      + 880 * (2 * k + 22) + 1568 ≤ 2 ^ (k + 22) := by
  induction k with
  | zero => decide
  | succ m ih =>
      have hp : (2 : Nat) ^ (m + 1 + 22) = 2 ^ (m + 22) * 2 := by
        rw [show m + 1 + 22 = (m + 22) + 1 from by omega, Nat.pow_succ]
      have hexp : 16 * (2 * (m + 1) + 22) * (2 * (m + 1) + 22) * (2 * (m + 1) + 22)
            + 192 * (2 * (m + 1) + 22) * (2 * (m + 1) + 22) + 880 * (2 * (m + 1) + 22) + 1568
          = (16 * (2 * m + 22) * (2 * m + 22) * (2 * m + 22) + 192 * (2 * m + 22) * (2 * m + 22)
              + 880 * (2 * m + 22) + 1568)
            + (96 * (2 * m + 22) * (2 * m + 22) + 960 * (2 * m + 22) + 2656) := by
        have hi : ((16 * (2 * (m + 1) + 22) * (2 * (m + 1) + 22) * (2 * (m + 1) + 22)
              + 192 * (2 * (m + 1) + 22) * (2 * (m + 1) + 22) + 880 * (2 * (m + 1) + 22) + 1568 : Nat) : Int)
            = (((16 * (2 * m + 22) * (2 * m + 22) * (2 * m + 22) + 192 * (2 * m + 22) * (2 * m + 22)
                + 880 * (2 * m + 22) + 1568)
              + (96 * (2 * m + 22) * (2 * m + 22) + 960 * (2 * m + 22) + 2656) : Nat) : Int) := by
          push_cast; ring_uor
        exact_mod_cast hi
      have hquad := g4_quadincL m
      rw [hp, hexp]; omega

/-- `2(2j+22)⁴+24(2j+22)³+132(2j+22)²+408(2j+22)+598 ≤ 2^{j+22}` (Q_L at the reindex; quartic). -/
theorem g4_quart_linL (j : Nat) :
    2 * (2 * j + 22) * (2 * j + 22) * (2 * j + 22) * (2 * j + 22)
      + 24 * (2 * j + 22) * (2 * j + 22) * (2 * j + 22) + 132 * (2 * j + 22) * (2 * j + 22)
      + 408 * (2 * j + 22) + 598 ≤ 2 ^ (j + 22) := by
  induction j with
  | zero => decide
  | succ k ih =>
      have hp : (2 : Nat) ^ (k + 1 + 22) = 2 ^ (k + 22) * 2 := by
        rw [show k + 1 + 22 = (k + 22) + 1 from by omega, Nat.pow_succ]
      have hexp : 2 * (2 * (k + 1) + 22) * (2 * (k + 1) + 22) * (2 * (k + 1) + 22) * (2 * (k + 1) + 22)
            + 24 * (2 * (k + 1) + 22) * (2 * (k + 1) + 22) * (2 * (k + 1) + 22)
            + 132 * (2 * (k + 1) + 22) * (2 * (k + 1) + 22) + 408 * (2 * (k + 1) + 22) + 598
          = (2 * (2 * k + 22) * (2 * k + 22) * (2 * k + 22) * (2 * k + 22)
              + 24 * (2 * k + 22) * (2 * k + 22) * (2 * k + 22) + 132 * (2 * k + 22) * (2 * k + 22)
              + 408 * (2 * k + 22) + 598)
            + (16 * (2 * k + 22) * (2 * k + 22) * (2 * k + 22) + 192 * (2 * k + 22) * (2 * k + 22)
              + 880 * (2 * k + 22) + 1568) := by
        have hi : ((2 * (2 * (k + 1) + 22) * (2 * (k + 1) + 22) * (2 * (k + 1) + 22) * (2 * (k + 1) + 22)
              + 24 * (2 * (k + 1) + 22) * (2 * (k + 1) + 22) * (2 * (k + 1) + 22)
              + 132 * (2 * (k + 1) + 22) * (2 * (k + 1) + 22) + 408 * (2 * (k + 1) + 22) + 598 : Nat) : Int)
            = (((2 * (2 * k + 22) * (2 * k + 22) * (2 * k + 22) * (2 * k + 22)
                + 24 * (2 * k + 22) * (2 * k + 22) * (2 * k + 22) + 132 * (2 * k + 22) * (2 * k + 22)
                + 408 * (2 * k + 22) + 598)
              + (16 * (2 * k + 22) * (2 * k + 22) * (2 * k + 22) + 192 * (2 * k + 22) * (2 * k + 22)
                + 880 * (2 * k + 22) + 1568) : Nat) : Int) := by
          push_cast; ring_uor
        exact_mod_cast hi
      have hcub := g4_cubincL k
      rw [hp, hexp]; omega

/-- **Reindex domination (lower)** `Q_L(M)·(j+1) ≤ 2^M` for `M = 2j+22`. -/
theorem g4_domination_L (j : Nat) :
    (2 * (2 * j + 22) * (2 * j + 22) * (2 * j + 22) * (2 * j + 22)
      + 24 * (2 * j + 22) * (2 * j + 22) * (2 * j + 22) + 132 * (2 * j + 22) * (2 * j + 22)
      + 408 * (2 * j + 22) + 598) * (j + 1) ≤ 2 ^ (2 * j + 22) := by
  have h1 : j + 1 ≤ 2 ^ j := lt_two_pow j
  have h2 := g4_quart_linL j
  have h3 := Nat.mul_le_mul h2 h1
  have h4 : (2 : Nat) ^ (j + 22) * 2 ^ j = 2 ^ (2 * j + 22) := by rw [← Nat.pow_add]; congr 1; omega
  omega

/-- **Lower antiderivative anchor** `T_L(M(j)) ≤ 1/(j+1)`. -/
theorem g4_TL_le (j : Nat) :
    Qle (⟨(2 * gamma4Midx j * gamma4Midx j * gamma4Midx j * gamma4Midx j
          + 24 * gamma4Midx j * gamma4Midx j * gamma4Midx j + 132 * gamma4Midx j * gamma4Midx j
          + 408 * gamma4Midx j + 598 : Int), 2 ^ gamma4Midx j⟩ : Q) ⟨1, j + 1⟩ := by
  simp only [Qle, gamma4Midx]; push_cast
  have hcast : (((2 * (2 * j + 22) * (2 * j + 22) * (2 * j + 22) * (2 * j + 22)
        + 24 * (2 * j + 22) * (2 * j + 22) * (2 * j + 22) + 132 * (2 * j + 22) * (2 * j + 22)
        + 408 * (2 * j + 22) + 598) * (j + 1) : Nat) : Int) ≤ ((2 ^ (2 * j + 22) : Nat) : Int) := by
    exact_mod_cast g4_domination_L j
  push_cast at hcast; omega

-- ===========================================================================
-- Outer telescoping → regularity → `Rgamma4`.
-- ===========================================================================

/-- Outer UPPER sum `Σ_{i<e} 4(A+i+2)³/2^{A+i}`. -/
def WUsum4 (A : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (e + 1) => add (WUsum4 A e)
      ⟨4 * (((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2)), 2 ^ (A + e)⟩

theorem WUsum4_den_pos (A : Nat) : ∀ e, 0 < (WUsum4 A e).den
  | 0 => Nat.one_pos
  | (e + 1) => add_den_pos (WUsum4_den_pos A e) (Nat.pos_pow_of_pos (A + e) (by decide))

/-- Outer LOWER sum `Σ_{i<e} (A+i+2)⁴/2^{A+i}`. -/
def WLsum4 (A : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (e + 1) => add (WLsum4 A e)
      ⟨((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2),
        2 ^ (A + e)⟩

theorem WLsum4_den_pos (A : Nat) : ∀ e, 0 < (WLsum4 A e).den
  | 0 => Nat.one_pos
  | (e + 1) => add_den_pos (WLsum4_den_pos A e) (Nat.pos_pow_of_pos (A + e) (by decide))

/-- **Outer UPPER bound**: `g₄(2^{A+e}) − g₄(2^A) ≤ WUsum4 A e`. -/
theorem g4Seq_diff_le_outer (A : Nat) : ∀ e,
    Rle (Rsub (g4Seq (2 ^ (A + e))) (g4Seq (2 ^ A))) (ofQ (WUsum4 A e) (WUsum4_den_pos A e)) := by
  intro e
  induction e with
  | zero =>
      apply Rle_of_Req
      refine Req_trans (Radd_neg (g4Seq (2 ^ A))) (Req_symm ?_)
      apply Req_of_seq_Qeq; intro n
      simp only [WUsum4, ofQ, zero, Qeq]
  | succ e ih =>
      have hstepd : 0 < (⟨4 * (((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2)),
          2 ^ (A + e)⟩ : Q).den := Nat.pos_pow_of_pos (A + e) (by decide)
      have hgapd : 0 < (WUsum4 A e).den := WUsum4_den_pos A e
      have heq : Req (ofQ (WUsum4 A (e + 1)) (WUsum4_den_pos A (e + 1)))
          (Radd (ofQ (⟨4 * (((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2)),
            2 ^ (A + e)⟩ : Q) hstepd) (ofQ (WUsum4 A e) hgapd)) :=
        Req_trans (ofQ_congr _ _ (by simp only [WUsum4, Qeq, add]; push_cast <;> try ring_uor))
          (Req_symm (Radd_ofQ_ofQ hstepd hgapd))
      exact Rle_trans
        (Rle_of_Req (Req_symm (Rsub_split (g4Seq (2 ^ (A + e + 1))) (g4Seq (2 ^ (A + e)))
          (g4Seq (2 ^ A)))))
        (Rle_trans (Radd_le_add (g4Seq_block_le (A + e)) ih) (Rle_of_Req (Req_symm heq)))

/-- **Outer LOWER bound**: `g₄(2^{A+e}) − g₄(2^A) ≥ −WLsum4 A e`. -/
theorem g4Seq_diff_ge_outer (A : Nat) : ∀ e,
    Rle (Rneg (ofQ (WLsum4 A e) (WLsum4_den_pos A e))) (Rsub (g4Seq (2 ^ (A + e))) (g4Seq (2 ^ A))) := by
  intro e
  induction e with
  | zero =>
      apply Rle_of_Req
      refine Req_trans ?_ (Req_symm (Radd_neg (g4Seq (2 ^ A))))
      apply Req_of_seq_Qeq; intro n
      simp only [Rneg, WLsum4, ofQ, zero, neg, Qeq]; push_cast
  | succ e ih =>
      have hstepd : 0 < (⟨((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2)
          * ((↑(A + e) : Int) + 2), 2 ^ (A + e)⟩ : Q).den := Nat.pos_pow_of_pos (A + e) (by decide)
      have hgapd : 0 < (WLsum4 A e).den := WLsum4_den_pos A e
      have heq : Req (Rneg (ofQ (WLsum4 A (e + 1)) (WLsum4_den_pos A (e + 1))))
          (Radd (Rneg (ofQ (⟨((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2)
                * ((↑(A + e) : Int) + 2), 2 ^ (A + e)⟩ : Q) hstepd)) (Rneg (ofQ (WLsum4 A e) hgapd))) :=
        Req_trans (Rneg_congr (Req_trans
          (ofQ_congr _ _ (by simp only [WLsum4, Qeq, add]; push_cast <;> try ring_uor))
          (Req_symm (Radd_ofQ_ofQ hstepd hgapd)))) (Rneg_Radd _ _)
      exact Rle_trans (Rle_of_Req heq)
        (Rle_trans (Radd_le_add (g4Seq_block_ge (A + e)) ih)
          (Rle_of_Req (Rsub_split (g4Seq (2 ^ (A + e + 1))) (g4Seq (2 ^ (A + e))) (g4Seq (2 ^ A)))))

/-- **Upper antiderivative tail** `WUsum4 A e ≤ Q_U(A)/2^A − Q_U(A+e)/2^{A+e}`,
    `Q_U(m)=8m³+72m²+264m+408`. -/
theorem WUsum4_tail_le (A : Nat) : ∀ e,
    Qle (WUsum4 A e)
        (Qsub (⟨(8 * A * A * A + 72 * A * A + 264 * A + 408 : Int), 2 ^ A⟩ : Q)
          ⟨(8 * (A + e) * (A + e) * (A + e) + 72 * (A + e) * (A + e) + 264 * (A + e) + 408 : Int),
            2 ^ (A + e)⟩)
  | 0 => by
      simp only [Nat.add_zero]; apply Qeq_le
      simp only [WUsum4, Qsub, add, neg, Qeq]; push_cast <;> try ring_uor
  | (e + 1) => by
      have hT : 0 < (Qsub (⟨(8 * A * A * A + 72 * A * A + 264 * A + 408 : Int), 2 ^ A⟩ : Q)
          ⟨(8 * (A + e) * (A + e) * (A + e) + 72 * (A + e) * (A + e) + 264 * (A + e) + 408 : Int),
            2 ^ (A + e)⟩).den :=
        Qsub_den_pos (Nat.pos_pow_of_pos A (by decide)) (Nat.pos_pow_of_pos (A + e) (by decide))
      have hS : 0 < (Qsub (⟨(8 * (A + e) * (A + e) * (A + e) + 72 * (A + e) * (A + e) + 264 * (A + e) + 408 : Int),
            2 ^ (A + e)⟩ : Q)
          ⟨(8 * (A + e + 1) * (A + e + 1) * (A + e + 1) + 72 * (A + e + 1) * (A + e + 1)
            + 264 * (A + e + 1) + 408 : Int), 2 ^ (A + e + 1)⟩).den :=
        Qsub_den_pos (Nat.pos_pow_of_pos (A + e) (by decide)) (Nat.pos_pow_of_pos (A + e + 1) (by decide))
      have h2 : (2 : Nat) ^ (A + e + 1) = 2 * 2 ^ (A + e) := by rw [Nat.pow_succ]; omega
      have hinc : Qeq (⟨4 * (((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2)), 2 ^ (A + e)⟩ : Q)
          (Qsub (⟨(8 * (A + e) * (A + e) * (A + e) + 72 * (A + e) * (A + e) + 264 * (A + e) + 408 : Int),
              2 ^ (A + e)⟩ : Q)
            ⟨(8 * (A + e + 1) * (A + e + 1) * (A + e + 1) + 72 * (A + e + 1) * (A + e + 1)
              + 264 * (A + e + 1) + 408 : Int), 2 ^ (A + e + 1)⟩) := by
        simp only [h2, Qsub, add, neg, Qeq]; push_cast <;> try ring_uor
      exact Qle_trans (add_den_pos hT hS)
        (Qadd_le_add (WUsum4_tail_le A e) (Qeq_le hinc)) (Qeq_le (Qadd_Qsub_fwd _ _ _))

/-- **Lower antiderivative tail** `WLsum4 A e ≤ Q_L(A)/2^A − Q_L(A+e)/2^{A+e}`,
    `Q_L(m)=2m⁴+24m³+132m²+408m+598` (the quartic discrete antiderivative). -/
theorem WLsum4_tail_le (A : Nat) : ∀ e,
    Qle (WLsum4 A e)
        (Qsub (⟨(2 * A * A * A * A + 24 * A * A * A + 132 * A * A + 408 * A + 598 : Int), 2 ^ A⟩ : Q)
          ⟨(2 * (A + e) * (A + e) * (A + e) * (A + e) + 24 * (A + e) * (A + e) * (A + e)
            + 132 * (A + e) * (A + e) + 408 * (A + e) + 598 : Int), 2 ^ (A + e)⟩)
  | 0 => by
      simp only [Nat.add_zero]; apply Qeq_le
      simp only [WLsum4, Qsub, add, neg, Qeq]; push_cast <;> try ring_uor
  | (e + 1) => by
      have hT : 0 < (Qsub (⟨(2 * A * A * A * A + 24 * A * A * A + 132 * A * A + 408 * A + 598 : Int), 2 ^ A⟩ : Q)
          ⟨(2 * (A + e) * (A + e) * (A + e) * (A + e) + 24 * (A + e) * (A + e) * (A + e)
            + 132 * (A + e) * (A + e) + 408 * (A + e) + 598 : Int), 2 ^ (A + e)⟩).den :=
        Qsub_den_pos (Nat.pos_pow_of_pos A (by decide)) (Nat.pos_pow_of_pos (A + e) (by decide))
      have hS : 0 < (Qsub (⟨(2 * (A + e) * (A + e) * (A + e) * (A + e) + 24 * (A + e) * (A + e) * (A + e)
            + 132 * (A + e) * (A + e) + 408 * (A + e) + 598 : Int), 2 ^ (A + e)⟩ : Q)
          ⟨(2 * (A + e + 1) * (A + e + 1) * (A + e + 1) * (A + e + 1) + 24 * (A + e + 1) * (A + e + 1) * (A + e + 1)
            + 132 * (A + e + 1) * (A + e + 1) + 408 * (A + e + 1) + 598 : Int), 2 ^ (A + e + 1)⟩).den :=
        Qsub_den_pos (Nat.pos_pow_of_pos (A + e) (by decide)) (Nat.pos_pow_of_pos (A + e + 1) (by decide))
      have h2 : (2 : Nat) ^ (A + e + 1) = 2 * 2 ^ (A + e) := by rw [Nat.pow_succ]; omega
      have hinc : Qeq (⟨((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2)
            * ((↑(A + e) : Int) + 2), 2 ^ (A + e)⟩ : Q)
          (Qsub (⟨(2 * (A + e) * (A + e) * (A + e) * (A + e) + 24 * (A + e) * (A + e) * (A + e)
              + 132 * (A + e) * (A + e) + 408 * (A + e) + 598 : Int), 2 ^ (A + e)⟩ : Q)
            ⟨(2 * (A + e + 1) * (A + e + 1) * (A + e + 1) * (A + e + 1) + 24 * (A + e + 1) * (A + e + 1) * (A + e + 1)
              + 132 * (A + e + 1) * (A + e + 1) + 408 * (A + e + 1) + 598 : Int), 2 ^ (A + e + 1)⟩) := by
        simp only [h2, Qsub, add, neg, Qeq]; push_cast <;> try ring_uor
      exact Qle_trans (add_den_pos hT hS)
        (Qadd_le_add (WLsum4_tail_le A e) (Qeq_le hinc)) (Qeq_le (Qadd_Qsub_fwd _ _ _))

/-- The reindexed `γ₄` defining sequence `g₄(2^{M(j)})`, `M(j) = 2j+22`. -/
def g4SeqDyadic (j : Nat) : Real := g4Seq (2 ^ gamma4Midx j)

/-- **Pairwise Cauchy (upper)**: for `j ≤ k`, `g4SeqDyadic k − g4SeqDyadic j ≤ 1/(j+1)`. -/
theorem g4_pair_le {j k : Nat} (hjk : j ≤ k) :
    Rle (Rsub (g4SeqDyadic k) (g4SeqDyadic j)) (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  simp only [g4SeqDyadic]
  obtain ⟨e, he⟩ := Nat.le.dest (gamma4Midx_mono hjk)
  rw [← he]
  refine Rle_trans (g4Seq_diff_le_outer (gamma4Midx j) e) ?_
  have hmid : 0 < (Qsub (⟨(8 * gamma4Midx j * gamma4Midx j * gamma4Midx j + 72 * gamma4Midx j * gamma4Midx j
        + 264 * gamma4Midx j + 408 : Int), 2 ^ gamma4Midx j⟩ : Q)
      ⟨(8 * (gamma4Midx j + e) * (gamma4Midx j + e) * (gamma4Midx j + e)
        + 72 * (gamma4Midx j + e) * (gamma4Midx j + e) + 264 * (gamma4Midx j + e) + 408 : Int),
        2 ^ (gamma4Midx j + e)⟩).den :=
    Qsub_den_pos (Nat.pos_pow_of_pos _ (by decide)) (Nat.pos_pow_of_pos _ (by decide))
  have hmid2 : 0 < (⟨(8 * gamma4Midx j * gamma4Midx j * gamma4Midx j + 72 * gamma4Midx j * gamma4Midx j
      + 264 * gamma4Midx j + 408 : Int), 2 ^ gamma4Midx j⟩ : Q).den := Nat.pos_pow_of_pos _ (by decide)
  exact Rle_trans (Rle_ofQ_ofQ (WUsum4_den_pos _ _) hmid (WUsum4_tail_le (gamma4Midx j) e))
    (Rle_trans (Rle_ofQ_ofQ hmid hmid2 (Qsub_le_left _ _ (by
        have h : (0 : Int) ≤ (↑(gamma4Midx j) : Int) + (↑e : Int) := by
          have := Int.ofNat_nonneg (gamma4Midx j); have := Int.ofNat_nonneg e; omega
        have hcb := Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg (by decide : (0 : Int) ≤ 8) h) h) h
        have hqd := Int.mul_nonneg (Int.mul_nonneg (by decide : (0 : Int) ≤ 72) h) h
        have hln := Int.mul_nonneg (by decide : (0 : Int) ≤ 264) h
        omega) _ _))
      (Rle_ofQ_ofQ hmid2 (Nat.succ_pos j) (g4_TU_le j)))

/-- **Pairwise Cauchy (lower)**: for `j ≤ k`, `g4SeqDyadic k − g4SeqDyadic j ≥ −1/(j+1)`. -/
theorem g4_pair_ge {j k : Nat} (hjk : j ≤ k) :
    Rle (Rneg (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j))) (Rsub (g4SeqDyadic k) (g4SeqDyadic j)) := by
  simp only [g4SeqDyadic]
  obtain ⟨e, he⟩ := Nat.le.dest (gamma4Midx_mono hjk)
  rw [← he]
  refine Rle_trans (Rle_Rneg ?_) (g4Seq_diff_ge_outer (gamma4Midx j) e)
  have hmid : 0 < (Qsub (⟨(2 * gamma4Midx j * gamma4Midx j * gamma4Midx j * gamma4Midx j
        + 24 * gamma4Midx j * gamma4Midx j * gamma4Midx j + 132 * gamma4Midx j * gamma4Midx j
        + 408 * gamma4Midx j + 598 : Int), 2 ^ gamma4Midx j⟩ : Q)
      ⟨(2 * (gamma4Midx j + e) * (gamma4Midx j + e) * (gamma4Midx j + e) * (gamma4Midx j + e)
        + 24 * (gamma4Midx j + e) * (gamma4Midx j + e) * (gamma4Midx j + e)
        + 132 * (gamma4Midx j + e) * (gamma4Midx j + e) + 408 * (gamma4Midx j + e) + 598 : Int),
        2 ^ (gamma4Midx j + e)⟩).den :=
    Qsub_den_pos (Nat.pos_pow_of_pos _ (by decide)) (Nat.pos_pow_of_pos _ (by decide))
  have hmid2 : 0 < (⟨(2 * gamma4Midx j * gamma4Midx j * gamma4Midx j * gamma4Midx j
      + 24 * gamma4Midx j * gamma4Midx j * gamma4Midx j + 132 * gamma4Midx j * gamma4Midx j
      + 408 * gamma4Midx j + 598 : Int), 2 ^ gamma4Midx j⟩ : Q).den := Nat.pos_pow_of_pos _ (by decide)
  exact Rle_trans (Rle_ofQ_ofQ (WLsum4_den_pos _ _) hmid (WLsum4_tail_le (gamma4Midx j) e))
    (Rle_trans (Rle_ofQ_ofQ hmid hmid2 (Qsub_le_left _ _ (by
        have h : (0 : Int) ≤ (↑(gamma4Midx j) : Int) + (↑e : Int) := by
          have := Int.ofNat_nonneg (gamma4Midx j); have := Int.ofNat_nonneg e; omega
        have hq4 := Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg
          (Int.mul_nonneg (by decide : (0 : Int) ≤ 2) h) h) h) h
        have hcb := Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg (by decide : (0 : Int) ≤ 24) h) h) h
        have hqd := Int.mul_nonneg (Int.mul_nonneg (by decide : (0 : Int) ≤ 132) h) h
        have hln := Int.mul_nonneg (by decide : (0 : Int) ≤ 408) h
        omega) _ _))
      (Rle_ofQ_ofQ hmid2 (Nat.succ_pos j) (g4_TL_le j)))

/-- **The reindexed `γ₄` sequence is regular** (`RReg`) — the input to Bishop's `Rlim`. -/
theorem g4SeqDyadic_RReg : RReg g4SeqDyadic := by
  refine RReg_of_real_bound _ (fun j k => add ⟨1, j + 1⟩ ⟨1, k + 1⟩)
    (fun j k => add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (fun j k => Qle_refl _) ?_
  intro j k
  rcases Nat.le_total j k with hjk | hkj
  · exact Rle_trans (Rle_of_Req (Req_symm (Rneg_Rsub (g4SeqDyadic k) (g4SeqDyadic j))))
      (Rle_trans (Rle_trans (Rle_Rneg (g4_pair_ge hjk)) (Rle_of_Req (Rneg_neg _)))
        (Rle_ofQ_ofQ (Nat.succ_pos _) (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
          (Qle_self_add (by show (0 : Int) ≤ 1; decide))))
  · exact Rle_trans (g4_pair_le hkj)
      (Rle_ofQ_ofQ (Nat.succ_pos _) (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
        (Qle_trans (b := add ⟨1, k + 1⟩ ⟨1, j + 1⟩)
          (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
          (Qle_self_add (p := ⟨1, j + 1⟩) (by show (0 : Int) ≤ 1; decide))
          (Qeq_le (by simp only [Qeq, add]; push_cast <;> try ring_uor))))

/-- **The fourth Stieltjes constant `γ₄`**, as a genuine constructive real: the Bishop limit of the
    reindexed defining sequence `g₄(2^{2j+22})`.  `γ₄ ≈ +0.00723`. -/
def Rgamma4 : Real := Rlim g4SeqDyadic g4SeqDyadic_RReg

end UOR.Bridge.F1Square.Analysis
