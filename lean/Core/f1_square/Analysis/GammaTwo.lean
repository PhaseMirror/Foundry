/-
F1 square — the **second Stieltjes constant `γ₂`** (the v0.20.0 frontier ingredient that, with
`γ`, `γ₁`, `log 4π`, `ζ(2)`, `ζ(3)`, gives the third Li coefficient `λ₃`).

`γ₂` is the limit of the **defining sequence**

    g₂(N) = S₂(N) − ⅓·(ln N)³,        S₂(N) = Σ_{k=1}^N (ln k)²/k,

i.e. `γ₂ = lim_{N→∞} [ Σ_{k=1}^N (ln k)²/k − ⅓(ln N)³ ] ≈ −0.00969`. Telescoping the `⅓(ln N)³` term,
`g₂(N) = Σ_{k=2}^N e_k` with `e_k = (ln k)²/k − ⅓[(ln k)³ − (ln(k−1))³]`; the leading `(ln k)²/k`
terms cancel against the cubic-log difference, leaving `e_k = O((ln k)²/k²)`, a convergent tail —
so `γ₂ := Rlim g₂Seq` is a genuine constructive real (the regularity is the analytic content
scoped on top of this substrate, mirroring `GammaOne` for `γ₁`).

THIS FILE (brick 1 of γ₂): the real substrate — the term `(ln k)²/k`, the partial sum `S₂(N)`, the
cube `(ln N)³`, and the sequence `g₂(N)`. The monotonicity/regularity layers and the certified
bracket follow (the γ₂ analogue of `GammaOne`'s dyadic-tail stack).

Pure Lean 4, no Mathlib, no `()`/`native_decide`, choice-free.
-/

import Core.f1_square.Analysis.GammaOne
import Core.f1_square.Analysis.RAddNF

namespace UOR.Bridge.F1Square.Analysis

/-- The squared-log harmonic term `(ln k)²/k` (for `k ≥ 1`), as a constructive real. -/
def lnSqOver (k : Nat) (hk : 1 ≤ k) : Real :=
  Rmul (Rmul (logN k hk) (logN k hk)) (ofQ ⟨1, k⟩ (by show 0 < k; omega))

/-- Each term `(ln k)²/k ≥ 0` (`(ln k)² ≥ 0` and `1/k > 0`). -/
theorem lnSqOver_nonneg (k : Nat) (hk : 1 ≤ k) : Rnonneg (lnSqOver k hk) :=
  Rnonneg_Rmul (Rnonneg_Rmul_self (logN k hk))
    (Rnonneg_ofQ (by show 0 < k; omega) (by show (0 : Int) ≤ 1; decide))

/-- The partial sum `S₂(N) = Σ_{k=1}^N (ln k)²/k`. -/
def lnSqSum : Nat → Real
  | 0 => zero
  | (n + 1) => Radd (lnSqSum n) (lnSqOver (n + 1) (by omega))

/-- `S₂(n) ≤ S₂(n+1)` (the new term is `≥ 0`). -/
theorem lnSqSum_step (n : Nat) : Rle (lnSqSum n) (lnSqSum (n + 1)) :=
  Rle_self_Radd_right (lnSqOver_nonneg (n + 1) (by omega))

/-- `S₂` is monotone (non-decreasing). -/
theorem lnSqSum_mono {a b : Nat} (hab : a ≤ b) : Rle (lnSqSum a) (lnSqSum b) := by
  induction hab with
  | refl => exact Rle_refl _
  | step _ ih => exact Rle_trans ih (lnSqSum_step _)

/-- The cube `(ln N)³` as a constructive real. -/
def logCube (N : Nat) (hN : 1 ≤ N) : Real :=
  Rmul (Rmul (logN N hN) (logN N hN)) (logN N hN)

/-- `(ln N)³ ≥ 0` for `N ≥ 1`. -/
theorem logCube_nonneg (N : Nat) (hN : 1 ≤ N) : Rnonneg (logCube N hN) :=
  Rnonneg_Rmul (Rnonneg_Rmul_self (logN N hN)) (Rnonneg_logN N hN)

/-- The **defining sequence** `g₂(j+1) = S₂(j+1) − ⅓·(ln (j+1))³` (indexed from `j = 0`).
    `γ₂ = Rlim g₂Seq`. -/
def g2Seq (j : Nat) : Real :=
  Rsub (lnSqSum (j + 1)) (Rmul (ofQ ⟨1, 3⟩ (by decide)) (logCube (j + 1) (by omega)))

-- ===========================================================================
-- The per-step difference `e_{p+1} = g₂(p+1) − g₂(p)` and its telescoping identity.
-- ===========================================================================

/-- `(a₁ − b₁) − (a₀ − b₀) ≈ (a₁ − a₀) − (b₁ − b₀)` — pointwise (all of `Rsub`/`Radd`/`Rneg`
    are pointwise on the regular sequences). -/
theorem Rsub_sub_sub (a₁ b₁ a₀ b₀ : Real) :
    Req (Rsub (Rsub a₁ b₁) (Rsub a₀ b₀)) (Rsub (Rsub a₁ a₀) (Rsub b₁ b₀)) := by
  apply Req_of_seq_Qeq; intro n
  simp only [Rsub, Radd, Rneg, neg, add, Qeq]; push_cast; ring_uor

/-- The per-step difference `e_{p+1} = g₂(p+1) − g₂(p) = (ln(p+1))²/(p+1) − ⅓((ln(p+1))³ − (ln p)³)`
    (`p ≥ 1`). -/
def e2Step (p : Nat) (hp : 1 ≤ p) : Real :=
  Rsub (lnSqOver (p + 1) (Nat.succ_pos p))
    (Rmul (ofQ ⟨1, 3⟩ (by decide))
      (Rsub (logCube (p + 1) (Nat.succ_pos p)) (logCube p hp)))

/-- **`g₂(j+1) − g₂(j) ≈ e_{j+1}`** — the consecutive difference is the per-step `e`. -/
theorem g2Seq_step_eq (j : Nat) :
    Req (Rsub (g2Seq (j + 1)) (g2Seq j)) (e2Step (j + 1) (Nat.succ_pos j)) := by
  -- the sum telescopes: S₂(j+2) − S₂(j+1) = (ln(j+2))²/(j+2)
  have hA : Req (Rsub (lnSqSum (j + 2)) (lnSqSum (j + 1)))
      (lnSqOver (j + 2) (Nat.succ_pos (j + 1))) := by
    show Req (Rsub (Radd (lnSqSum (j + 1)) (lnSqOver (j + 2) (by omega))) (lnSqSum (j + 1)))
             (lnSqOver (j + 2) (Nat.succ_pos (j + 1)))
    refine Req_trans (Rsub_congr (Radd_comm (lnSqSum (j + 1)) (lnSqOver (j + 2) (by omega)))
      (Req_refl _)) ?_
    refine Req_trans (Radd_assoc (lnSqOver (j + 2) (by omega)) (lnSqSum (j + 1))
      (Rneg (lnSqSum (j + 1)))) ?_
    exact Req_trans (Radd_congr (Req_refl _) (Radd_neg (lnSqSum (j + 1)))) (Radd_zero _)
  -- the cube term: ⅓C(j+2) − ⅓C(j+1) = ⅓(C(j+2) − C(j+1))
  have hB : Req (Rsub (Rmul (ofQ ⟨1, 3⟩ (by decide)) (logCube (j + 2) (by omega)))
        (Rmul (ofQ ⟨1, 3⟩ (by decide)) (logCube (j + 1) (by omega))))
      (Rmul (ofQ ⟨1, 3⟩ (by decide))
        (Rsub (logCube (j + 2) (by omega)) (logCube (j + 1) (by omega)))) :=
    Req_symm (Rmul_sub_distrib (ofQ ⟨1, 3⟩ (by decide)) (logCube (j + 2) (by omega))
      (logCube (j + 1) (by omega)))
  -- rearrange and combine
  refine Req_trans (Rsub_sub_sub (lnSqSum (j + 2))
    (Rmul (ofQ ⟨1, 3⟩ (by decide)) (logCube (j + 2) (by omega)))
    (lnSqSum (j + 1)) (Rmul (ofQ ⟨1, 3⟩ (by decide)) (logCube (j + 1) (by omega)))) ?_
  exact Rsub_congr hA hB

-- ===========================================================================
-- The cubic algebra: `a³ − b³ = (a−b)(a²+ab+b²)` and the cancellation identity.
-- ===========================================================================

/-- **`(a−b)(a² + ab + b²) ≈ a³ − b³`** — the difference-of-cubes factoring (the cubic analogue
    of `sq_diff_identity`), by distributing and telescoping the cross terms. -/
theorem cube_diff_identity (a b : Real) :
    Req (Rmul (Rsub a b) (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b)))
        (Rsub (Rmul (Rmul a a) a) (Rmul (Rmul b b) b)) := by
  -- (a−b)·S = a·S − b·S
  refine Req_trans (Rmul_sub_distrib_right a b
    (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b))) ?_
  -- expand a·S = a·a² + a·ab + a·b² and b·S = b·a² + b·ab + b·b²
  have haS : Req (Rmul a (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b)))
      (Radd (Radd (Rmul a (Rmul a a)) (Rmul a (Rmul a b))) (Rmul a (Rmul b b))) :=
    Req_trans (Rmul_distrib a (Radd (Rmul a a) (Rmul a b)) (Rmul b b))
      (Radd_congr (Rmul_distrib a (Rmul a a) (Rmul a b)) (Req_refl _))
  have hbS : Req (Rmul b (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b)))
      (Radd (Radd (Rmul b (Rmul a a)) (Rmul b (Rmul a b))) (Rmul b (Rmul b b))) :=
    Req_trans (Rmul_distrib b (Radd (Rmul a a) (Rmul a b)) (Rmul b b))
      (Radd_congr (Rmul_distrib b (Rmul a a) (Rmul a b)) (Req_refl _))
  refine Req_trans (Rsub_congr haS hbS) ?_
  -- now a pure Radd/Rneg/Rsub rearrangement on the six atoms (pointwise), modulo identifying
  -- the equal cross terms a·(a·b) = b·(a·a) and a·(b·b) = b·(a·b)
  have hx1 : Req (Rmul a (Rmul a b)) (Rmul b (Rmul a a)) := by
    refine Req_trans (Req_symm (Rmul_assoc a a b)) ?_
    refine Req_trans (Rmul_comm (Rmul a a) b) ?_
    exact Req_refl _
  have hx2 : Req (Rmul a (Rmul b b)) (Rmul b (Rmul a b)) := by
    refine Req_trans (Req_symm (Rmul_assoc a b b)) ?_
    refine Req_trans (Rmul_congr (Rmul_comm a b) (Req_refl b)) ?_
    refine Req_trans (Rmul_assoc b a b) ?_
    exact Req_refl _
  -- substitute the cross-term identifications, making the two middle pairs syntactically equal
  refine Req_trans (Rsub_congr (Radd_congr (Radd_congr (Req_refl _) hx1) hx2) (Req_refl _)) ?_
  -- telescope the matched atoms: (P + M₁ + M₂) − (M₁ + M₂ + Q) ≈ P − Q.  Done by Real algebra
  -- (assoc + `Radd_neg`), NOT pointwise: M₁,M₂ recur in both halves, so the cleared denominators
  -- would be squared and overrun `ring_uor`.
  have hcancel : ∀ P S Q : Real, Req (Rsub (Radd P S) (Radd S Q)) (Rsub P Q) := by
    intro P S Q
    refine Req_trans (Radd_congr (Req_refl (Radd P S)) (Rneg_Radd S Q)) ?_
    refine Req_trans (Radd_assoc P S (Radd (Rneg S) (Rneg Q))) ?_
    refine Req_trans (Radd_congr (Req_refl P) (Req_symm (Radd_assoc S (Rneg S) (Rneg Q)))) ?_
    refine Req_trans (Radd_congr (Req_refl P) (Radd_congr (Radd_neg S) (Req_refl (Rneg Q)))) ?_
    exact Radd_congr (Req_refl P)
      (Req_trans (Radd_comm zero (Rneg Q)) (Radd_zero (Rneg Q)))
  have htel : ∀ P M₁ M₂ Q : Real,
      Req (Rsub (Radd (Radd P M₁) M₂) (Radd (Radd M₁ M₂) Q)) (Rsub P Q) := fun P M₁ M₂ Q =>
    Req_trans (Rsub_congr (Radd_assoc P M₁ M₂) (Req_refl _)) (hcancel P (Radd M₁ M₂) Q)
  refine Req_trans (htel (Rmul a (Rmul a a)) (Rmul b (Rmul a a)) (Rmul b (Rmul a b))
    (Rmul b (Rmul b b))) ?_
  -- finally reorient P = a·a² → a²·a and Q = b·b² → b²·b
  exact Rsub_congr (Rmul_comm a (Rmul a a)) (Rmul_comm b (Rmul b b))

/-- **`(a²+ab+b²) + (a−b)(2a+b) ≈ 3a²`** — the quadratic identity behind the `e_k` decomposition,
    discharged by the RAddNF additive normalizer: expand `(a−b)(2a+b)`, flatten to a signed-atom
    list, then permute (decidably, via ℕ-indices) and cancel the `ab`/`b²` pairs. -/
theorem tri_sum_3a2 (a b : Real) :
    Req (Radd (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b))
          (Rmul (Rsub a b) (Radd (Radd a a) b)))
        (Radd (Radd (Rmul a a) (Rmul a a)) (Rmul a a)) := by
  -- expand X = (a−b)(2a+b) ≈ (a²+a²+ab) − (ab+ab+b²)
  have hX : Req (Rmul (Rsub a b) (Radd (Radd a a) b))
      (Rsub (Radd (Radd (Rmul a a) (Rmul a a)) (Rmul a b))
            (Radd (Radd (Rmul a b) (Rmul a b)) (Rmul b b))) := by
    refine Req_trans (Rmul_sub_distrib_right a b (Radd (Radd a a) b)) ?_
    refine Rsub_congr ?_ ?_
    · exact Req_trans (Rmul_distrib a (Radd a a) b) (Radd_congr (Rmul_distrib a a a) (Req_refl _))
    · refine Req_trans (Rmul_distrib b (Radd a a) b) (Radd_congr ?_ (Req_refl _))
      exact Req_trans (Rmul_distrib b a a) (Radd_congr (Rmul_comm b a) (Rmul_comm b a))
  -- flatten LHS to the canonical signed-atom list [0,1,2,0,0,1,3,3,4].map f
  refine Req_trans (Radd_congr (Radd_eq_RsumL3 (Rmul a a) (Rmul a b) (Rmul b b)) hX) ?_
  refine Req_trans (Radd_congr (Req_refl _)
    (Req_trans (Radd_congr (Radd_eq_RsumL3 (Rmul a a) (Rmul a a) (Rmul a b))
        (Req_trans (Rneg_congr (Radd_eq_RsumL3 (Rmul a b) (Rmul a b) (Rmul b b)))
          (RsumL_map_Rneg [Rmul a b, Rmul a b, Rmul b b])))
      (Req_symm (RsumL_append [Rmul a a, Rmul a a, Rmul a b]
        [Rneg (Rmul a b), Rneg (Rmul a b), Rneg (Rmul b b)])))) ?_
  refine Req_trans (Req_symm (RsumL_append [Rmul a a, Rmul a b, Rmul b b]
    [Rmul a a, Rmul a a, Rmul a b, Rneg (Rmul a b), Rneg (Rmul a b), Rneg (Rmul b b)])) ?_
  -- convert the RHS 3a² to canonical-list form
  refine Req_trans ?_ (Req_symm (Radd_eq_RsumL3 (Rmul a a) (Rmul a a) (Rmul a a)))
  -- now: RsumL [a²,ab,b²,a²,a²,ab,−ab,−ab,−b²]  ≈  RsumL [a²,a²,a²]
  -- cancel the three ± pairs at known positions (choice-free, no `decide` on `Perm`):
  --   ab (pos 1) ↔ −ab (pos 6); then ab (pos 4) ↔ −ab; then b² ↔ −b²
  refine Req_trans (RsumL_cancel_anywhere (Rmul a b) [Rmul a a]
    [Rmul b b, Rmul a a, Rmul a a, Rmul a b] [Rneg (Rmul a b), Rneg (Rmul b b)]) ?_
  refine Req_trans (RsumL_cancel_anywhere (Rmul a b) [Rmul a a, Rmul b b, Rmul a a, Rmul a a]
    [] [Rneg (Rmul b b)]) ?_
  exact RsumL_cancel_anywhere (Rmul b b) [Rmul a a] [Rmul a a, Rmul a a] []

/-- **`⅓·(Y+Y+Y) ≈ Y`** — the rational coefficient that closes the `e_k` decomposition
    (`⅓ · 3a² = a²`): distribute `⅓` over the threefold sum, factor back to `(⅓+⅓+⅓)·Y`, and
    `⅓+⅓+⅓ = 1`. -/
theorem Rmul_third_three (Y : Real) :
    Req (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) (Radd (Radd Y Y) Y)) Y := by
  have hdist : Req (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) (Radd (Radd Y Y) Y))
      (Rmul (Radd (Radd (ofQ (⟨1, 3⟩ : Q) (by decide)) (ofQ (⟨1, 3⟩ : Q) (by decide)))
        (ofQ (⟨1, 3⟩ : Q) (by decide))) Y) := by
    refine Req_trans (Rmul_distrib (ofQ (⟨1, 3⟩ : Q) (by decide)) (Radd Y Y) Y) ?_
    refine Req_trans (Radd_congr (Rmul_distrib (ofQ (⟨1, 3⟩ : Q) (by decide)) Y Y) (Req_refl _)) ?_
    refine Req_trans (Radd_congr
      (Req_symm (Rmul_distrib_right (ofQ (⟨1, 3⟩ : Q) (by decide)) (ofQ (⟨1, 3⟩ : Q) (by decide)) Y))
      (Req_refl _)) ?_
    exact Req_symm (Rmul_distrib_right (Radd (ofQ (⟨1, 3⟩ : Q) (by decide))
      (ofQ (⟨1, 3⟩ : Q) (by decide))) (ofQ (⟨1, 3⟩ : Q) (by decide)) Y)
  refine Req_trans hdist ?_
  have hcoef : Req (Radd (Radd (ofQ (⟨1, 3⟩ : Q) (by decide)) (ofQ (⟨1, 3⟩ : Q) (by decide)))
      (ofQ (⟨1, 3⟩ : Q) (by decide))) one := by
    refine Req_trans (Radd_congr (Radd_ofQ_ofQ (by decide) (by decide)) (Req_refl _)) ?_
    refine Req_trans (Radd_ofQ_ofQ (by decide) (by decide)) ?_
    exact Req_of_seq_Qeq (fun _ => by
      show Qeq (add (add (⟨1, 3⟩ : Q) ⟨1, 3⟩) ⟨1, 3⟩) ⟨1, 1⟩; decide)
  exact Req_trans (Rmul_congr hcoef (Req_refl Y)) (Rone_mul Y)

/-- **The e_k multiplicative core**: `a²(a−b) ≈ ⅓·(δ·W + δ²·(2a+b))`, `δ = a−b`,
    `W = a²+ab+b²` — combining `tri_sum_3a2` (`W + δ(2a+b) = 3a²`) and `Rmul_third_three`
    (`⅓·3a² = a²`). The identity that turns `e_k` into its bound-ready decomposition. -/
theorem e2_core (a b : Real) :
    Req (Rmul (Rmul a a) (Rsub a b))
        (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
          (Radd (Rmul (Rsub a b) (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b)))
                (Rmul (Rmul (Rsub a b) (Rsub a b)) (Radd (Radd a a) b)))) := by
  refine Req_symm ?_
  -- ⅓·(δW + δ²T) ≈ ⅓·(δW + δ(δT))
  refine Req_trans (Rmul_congr (Req_refl _) (Radd_congr (Req_refl _)
    (Rmul_assoc (Rsub a b) (Rsub a b) (Radd (Radd a a) b)))) ?_
  -- ≈ ⅓·(δ·(W + δT))
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_symm (Rmul_distrib (Rsub a b) (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b))
      (Rmul (Rsub a b) (Radd (Radd a a) b))))) ?_
  -- ≈ ⅓·(δ·3a²)   [tri_sum_3a2 on W + δT]
  refine Req_trans (Rmul_congr (Req_refl _)
    (Rmul_congr (Req_refl _) (tri_sum_3a2 a b))) ?_
  -- rearrange ⅓·(δ·3a²) ≈ δ·(⅓·3a²) ≈ δ·a² ≈ a²·δ
  refine Req_trans (Req_symm (Rmul_assoc (ofQ (⟨1, 3⟩ : Q) (by decide)) (Rsub a b)
    (Radd (Radd (Rmul a a) (Rmul a a)) (Rmul a a)))) ?_
  refine Req_trans (Rmul_congr (Rmul_comm (ofQ (⟨1, 3⟩ : Q) (by decide)) (Rsub a b))
    (Req_refl _)) ?_
  refine Req_trans (Rmul_assoc (Rsub a b) (ofQ (⟨1, 3⟩ : Q) (by decide))
    (Radd (Radd (Rmul a a) (Rmul a a)) (Rmul a a))) ?_
  refine Req_trans (Rmul_congr (Req_refl _) (Rmul_third_three (Rmul a a))) ?_
  exact Rmul_comm (Rsub a b) (Rmul a a)

private theorem Rneg_Rneg_g2 (x : Real) : Req (Rneg (Rneg x)) x :=
  Req_of_seq_Qeq (fun _ => by simp only [Rneg, Qeq, neg]; push_cast; ring_uor)

/-- **The e_k upper-bound identity**: `⅓δ²(2a+b) − e_k ≈ a²(δ−u)` (`δ = a−b`), the difference
    whose non-negativity (since `δ ≥ u = 1/(p+1)` and `a² ≥ 0`) gives `e_k ≤ ⅓δ²(2a+b)`. -/
theorem e2_ub_identity (a b u : Real) :
    Req (Rsub (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
              (Rmul (Rmul (Rsub a b) (Rsub a b)) (Radd (Radd a a) b)))
          (Rsub (Rmul (Rmul a a) u)
            (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
              (Rmul (Rsub a b) (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b))))))
        (Rmul (Rmul a a) (Rsub (Rsub a b) u)) := by
  -- quadUB − (Au − ⅓δW) ≈ (⅓δW + quadUB) − Au ≈ a²δ − Au ≈ a²(δ−u)
  refine Req_trans (Radd_congr (Req_refl _)
    (Req_trans (Rneg_Radd (Rmul (Rmul a a) u)
        (Rneg (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
          (Rmul (Rsub a b) (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b))))))
      (Radd_congr (Req_refl _) (Rneg_Rneg_g2 _)))) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Radd_comm _ _)) ?_
  refine Req_trans (Req_symm (Radd_assoc _ _ _)) ?_
  refine Req_trans (Radd_congr (Radd_comm _ _) (Req_refl _)) ?_
  refine Req_trans (Radd_congr
    (Req_trans (Req_symm (Rmul_distrib (ofQ (⟨1, 3⟩ : Q) (by decide))
        (Rmul (Rsub a b) (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b)))
        (Rmul (Rmul (Rsub a b) (Rsub a b)) (Radd (Radd a a) b))))
      (Req_symm (e2_core a b))) (Req_refl _)) ?_
  exact Req_symm (Rmul_sub_distrib (Rmul a a) (Rsub a b) u)

/-- **The e_k UPPER bound** `e_k ≤ ⅓·(a−b)²·(2a+b)` (`a = ln(p+1)`, `b = ln p`): from
    `e2_ub_identity` and `δ ≥ 1/(p+1)` (`deltaLog_lower`), `a² ≥ 0`. -/
theorem e2Step_le_quad (p : Nat) (hp : 1 ≤ p) :
    Rle (e2Step p hp)
        (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
          (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                      (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
                (Radd (Radd (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
                  (logN p hp)))) := by
  have he2 : Req (e2Step p hp)
      (Rsub (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
              (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
        (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
          (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Radd (Radd (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
                    (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rmul (logN p hp) (logN p hp)))))) := by
    show Req (Rsub (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
              (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
        (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
          (Rsub (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
                  (logN (p + 1) (Nat.succ_pos p)))
                (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp))))) _
    exact Rsub_congr (Req_refl _) (Rmul_congr (Req_refl _)
      (Req_symm (cube_diff_identity (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))
  have hub := e2_ub_identity (logN (p + 1) (Nat.succ_pos p)) (logN p hp)
    (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))
  have hnn : Rnonneg (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
      (Rsub (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))) :=
    Rnonneg_Rmul (Rnonneg_Rmul_self _) (Rnonneg_Rsub_of_Rle (deltaLog_lower p hp))
  exact Rle_of_Rnonneg_Rsub (Rnonneg_congr (Req_symm (Req_trans (Rsub_congr (Req_refl _) he2) hub)) hnn)

/-- **The e_k lower-bound identity**: `e_k − a²(u−δ) ≈ ⅓δ²(2a+b)` (`δ = a−b`), whose
    non-negativity (`⅓δ²(2a+b) ≥ 0`) gives `e_k ≥ a²(u−δ)`. -/
theorem e2_lb_identity (a b u : Real) :
    Req (Rsub (Rsub (Rmul (Rmul a a) u)
              (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
                (Rmul (Rsub a b) (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b)))))
          (Rmul (Rmul a a) (Rsub u (Rsub a b))))
        (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
          (Rmul (Rmul (Rsub a b) (Rsub a b)) (Radd (Radd a a) b))) := by
  -- (Au − ⅓δW) − (Au − Aδ) ≈ Aδ − ⅓δW ≈ quadUB
  refine Req_trans (Rsub_congr (Req_refl _) (Rmul_sub_distrib (Rmul a a) u (Rsub a b))) ?_
  refine Req_trans (Rsub_sub_sub (Rmul (Rmul a a) u)
    (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
      (Rmul (Rsub a b) (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b))))
    (Rmul (Rmul a a) u) (Rmul (Rmul a a) (Rsub a b))) ?_
  -- (Au−Au) − (⅓δW − Aδ)
  refine Req_trans (Rsub_congr (Radd_neg (Rmul (Rmul a a) u)) (Req_refl _)) ?_
  -- 0 − (⅓δW − Aδ) ≈ −(⅓δW − Aδ) ≈ Aδ − ⅓δW
  refine Req_trans (Req_trans (Radd_comm zero _) (Radd_zero _)) ?_
  refine Req_trans (Req_trans (Rneg_Radd _ _) (Radd_congr (Req_refl _) (Rneg_Rneg_g2 _))) ?_
  refine Req_trans (Radd_comm _ _) ?_
  -- Aδ − ⅓δW ≈ (⅓δW + quadUB) − ⅓δW ≈ quadUB
  refine Req_trans (Radd_congr
    (Req_trans (e2_core a b)
      (Rmul_distrib (ofQ (⟨1, 3⟩ : Q) (by decide))
        (Rmul (Rsub a b) (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b)))
        (Rmul (Rmul (Rsub a b) (Rsub a b)) (Radd (Radd a a) b)))) (Req_refl _)) ?_
  -- (⅓δW + quadUB) + (−⅓δW) ≈ quadUB
  refine Req_trans (Radd_congr (Radd_comm _ _) (Req_refl _)) ?_
  refine Req_trans (Radd_assoc _ _ _) ?_
  exact Req_trans (Radd_congr (Req_refl _) (Radd_neg _)) (Radd_zero _)

/-- **The e_k LOWER bound** `e_k ≥ a²(u−δ)` (`a = ln(p+1)`, `b = ln p`, `u = 1/(p+1)`): from
    `e2_lb_identity` and `⅓δ²(2a+b) ≥ 0`. -/
theorem e2Step_ge_quad (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
          (Rsub (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))
        (e2Step p hp) := by
  have he2 : Req (e2Step p hp)
      (Rsub (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
              (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
        (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
          (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Radd (Radd (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
                    (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rmul (logN p hp) (logN p hp)))))) := by
    show Req (Rsub (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
              (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
        (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
          (Rsub (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
                  (logN (p + 1) (Nat.succ_pos p)))
                (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp))))) _
    exact Rsub_congr (Req_refl _) (Rmul_congr (Req_refl _)
      (Req_symm (cube_diff_identity (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))
  have hlb := e2_lb_identity (logN (p + 1) (Nat.succ_pos p)) (logN p hp)
    (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))
  have hnn : Rnonneg (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
      (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                  (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
        (Radd (Radd (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
          (logN p hp)))) :=
    Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
      (Rnonneg_Rmul (Rnonneg_Rmul_self _)
        (Rnonneg_Radd (Rnonneg_Radd (Rnonneg_logN _ _) (Rnonneg_logN _ _)) (Rnonneg_logN _ _)))
  exact Rle_of_Rnonneg_Rsub
    (Rnonneg_congr (Req_symm (Req_trans (Rsub_congr he2 (Req_refl _)) hlb)) hnn)

/-- `c·(x·y) ≈ x·(c·y)` — pull a left factor inward. -/
private theorem Rmul_left_comm_g2 (c x y : Real) : Req (Rmul c (Rmul x y)) (Rmul x (Rmul c y)) :=
  Req_trans (Req_symm (Rmul_assoc c x y))
    (Req_trans (Rmul_congr (Rmul_comm c x) (Req_refl _)) (Rmul_assoc x c y))

/-- **The e_k numeric UPPER envelope** `e_k ≤ ln(p+1)/p²` — the summable bound: from
    `e_k ≤ ⅓δ²(2a+b)`, `⅓(2a+b) ≤ a` (`b ≤ a`), and `δ ≤ 1/p` (`deltaLog_upper`). -/
theorem e2Step_le_num (p : Nat) (hp : 1 ≤ p) :
    Rle (e2Step p hp)
        (Rmul (logN (p + 1) (Nat.succ_pos p)) (ofQ (⟨1, p * p⟩ : Q) (Nat.mul_pos hp hp))) := by
  have ha : Rnonneg (logN (p + 1) (Nat.succ_pos p)) := Rnonneg_logN (p + 1) (Nat.succ_pos p)
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hδub : Rle (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) (ofQ (⟨1, p⟩ : Q) hp) :=
    deltaLog_upper p hp
  have hofqnn : Rnonneg (ofQ (⟨1, p⟩ : Q) hp) :=
    @Rnonneg_ofQ (⟨1, p⟩ : Q) hp (by show (0 : Int) ≤ 1; decide)
  -- ⅓(2a+b) ≤ a
  have hT : Rle (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
        (Radd (Radd (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p))) (logN p hp)))
      (logN (p + 1) (Nat.succ_pos p)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
        (Radd_le_add (Rle_refl _) (logN_mono hp (Nat.le_succ p))))
      (Rle_of_Req (Rmul_third_three (logN (p + 1) (Nat.succ_pos p))))
  -- δ² ≤ 1/p²
  have hδsq : Rle (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                       (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
                 (ofQ (⟨1, p * p⟩ : Q) (Nat.mul_pos hp hp)) :=
    Rle_trans (Rle_trans (Rmul_le_Rmul_left hδnn hδub) (Rmul_le_Rmul_right hofqnn hδub))
      (Rle_of_Req (Req_trans (@Rmul_ofQ_ofQ (⟨1, p⟩ : Q) (⟨1, p⟩ : Q) hp hp)
        (@ofQ_congr (mul (⟨1, p⟩ : Q) ⟨1, p⟩) (⟨1, p * p⟩ : Q)
          (@Qmul_den_pos (⟨1, p⟩ : Q) (⟨1, p⟩ : Q) hp hp) (Nat.mul_pos hp hp)
          (by show Qeq (mul (⟨1, p⟩ : Q) ⟨1, p⟩) ⟨1, p * p⟩; simp only [mul, Qeq]; push_cast; ring_uor))))
  -- chain
  refine Rle_trans (e2Step_le_quad p hp) ?_
  -- ⅓·(δ²·(2a+b)) ≈ δ²·(⅓·(2a+b)) ≤ δ²·a ≤ (1/p²)·a ≈ a·(1/p²)
  refine Rle_trans (Rle_of_Req (Rmul_left_comm_g2 (ofQ (⟨1, 3⟩ : Q) (by decide))
    (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
    (Radd (Radd (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p))) (logN p hp)))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_Rmul_self _) hT) ?_
  refine Rle_trans (Rmul_le_Rmul_right ha hδsq) ?_
  exact Rle_of_Req (Rmul_comm (ofQ (⟨1, p * p⟩ : Q) (Nat.mul_pos hp hp))
    (logN (p + 1) (Nat.succ_pos p)))

/-- **The e_k numeric LOWER envelope** `e_k ≥ −ln(p+1)²/(p(p+1))` — the summable lower bound:
    from `e_k ≥ a²(u−δ)` and `δ ≤ 1/p` (`deltaLog_upper`, so `(u−δ)+1/(p(p+1)) = 1/p − δ ≥ 0`). -/
theorem e2Step_ge_num (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
          (Rneg (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p)))))
        (e2Step p hp) := by
  have hA : Rnonneg (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p))) :=
    Rnonneg_Rmul_self _
  -- (u − δ) + c ≈ (u + c) − δ with u + c = 1/p, and 1/p − δ ≥ 0
  have hsum : Req (Radd (Rsub (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))
        (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
      (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))))
      (Rsub (ofQ (⟨1, p⟩ : Q) hp) (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) := by
    refine Req_trans (Radd_assoc (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))
      (Rneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
      (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p)))) ?_
    refine Req_trans (Radd_congr (Req_refl _) (Radd_comm _ _)) ?_
    refine Req_trans (Req_symm (Radd_assoc _ _ _)) ?_
    exact Radd_congr (Req_trans (@Radd_ofQ_ofQ (⟨1, p + 1⟩ : Q) (⟨1, p * (p + 1)⟩ : Q)
        (Nat.succ_pos p) (Nat.mul_pos hp (Nat.succ_pos p)))
      (@ofQ_congr (add (⟨1, p + 1⟩ : Q) ⟨1, p * (p + 1)⟩) (⟨1, p⟩ : Q) _ hp
        (by show Qeq (add (⟨1, p + 1⟩ : Q) ⟨1, p * (p + 1)⟩) ⟨1, p⟩
            simp only [add, Qeq]; push_cast; ring_uor))) (Req_refl _)
  have hnn : Rnonneg (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
      (Radd (Rsub (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
        (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))))) :=
    Rnonneg_Rmul hA (Rnonneg_congr (Req_symm hsum) (Rnonneg_Rsub_of_Rle (deltaLog_upper p hp)))
  -- A(u−δ) − A(−c) ≈ A((u−δ)+c) ≥ 0, so A(−c) ≤ A(u−δ) ≤ e_k
  refine Rle_trans ?_ (e2Step_ge_quad p hp)
  refine Rle_of_Rnonneg_Rsub (Rnonneg_congr ?_ hnn)
  -- A·((u−δ)+c) ≈ A·(u−δ) − A·(−c)
  exact Req_trans (Rmul_congr (Req_refl _)
      (Radd_congr (Req_refl _) (Req_symm (Rneg_Rneg_g2 _))))
    (Rmul_sub_distrib _ _ _)

-- ===========================================================================
-- **γ₂ dyadic tail (Brick 4a): per-step block bounds.**  Both envelopes are log-bearing (unlike
-- `γ₁`, whose upper step was the clean `1/(2(j+1)²)`), so BOTH sides need the dyadic-block log cap
-- `logN(j+2) ≤ a+2` (for `j+2 ≤ 2^{a+2}`, `logN_le_block`). The upper step `≤ logN(j+2)/(j+1)²`
-- becomes `≤ 2(a+2)/((j+1)(j+2))` (cap + `1/(j+1)² ≤ 2/((j+1)(j+2))`); the lower step
-- `≥ −logN(j+2)²/((j+1)(j+2))` becomes `≥ −(a+2)²/((j+1)(j+2))` (squared cap). Both land on the
-- common `c/((j+1)(j+2))` denominator — the `γ₁` lower-block shape — so the inner telescoping reuses
-- the `Vsum`/`Wsum` antiderivative pattern (with quadratic coefficient on the lower outer sum).
-- ===========================================================================

/-- **Squared block-log cap** `logN(j+2)² ≤ (a+2)²` for `j+2 ≤ 2^{a+2}` (square the cap
    `logN_le_block`, both sides nonneg). -/
theorem logSq_le_block (a j : Nat) (hj : j + 2 ≤ 2 ^ (a + 2)) :
    Rle (Rmul (logN (j + 2) (by omega)) (logN (j + 2) (by omega)))
        (ofQ (⟨((a : Int) + 2) * ((a : Int) + 2), 1⟩ : Q) Nat.one_pos) := by
  have hcap : Rle (logN (j + 2) (by omega)) (ofQ (⟨(a + 2 : Int), 1⟩ : Q) Nat.one_pos) :=
    logN_le_block a j hj
  have hnn : Rnonneg (logN (j + 2) (by omega)) := Rnonneg_logN _ _
  have hcapnn : Rnonneg (ofQ (⟨(a + 2 : Int), 1⟩ : Q) Nat.one_pos) :=
    Rnonneg_ofQ Nat.one_pos (by show (0 : Int) ≤ (a : Int) + 2; have := Int.ofNat_nonneg a; omega)
  refine Rle_trans (Rmul_le_Rmul_right hnn hcap) ?_
  refine Rle_trans (Rmul_le_Rmul_left hcapnn hcap) ?_
  exact Rle_of_Req (Req_trans (Rmul_ofQ_ofQ Nat.one_pos Nat.one_pos)
    (ofQ_congr _ _ (by simp only [mul, Qeq])))

/-- `c/((j+1)²) ≤ 2c/((j+1)(j+2))` for `c ≥ 0` (difference `c(j+1)·j ≥ 0`) — the upper-step
    denominator relaxation `1/(j+1)² ≤ 2/((j+1)(j+2))`. -/
theorem Qblock_upper (c : Int) (hc : 0 ≤ c) (j : Nat) :
    Qle (⟨c, (j + 1) * (j + 1)⟩ : Q) ⟨2 * c, (j + 1) * (j + 2)⟩ := by
  simp only [Qle]; push_cast
  have hj : (0 : Int) ≤ (j : Int) := Int.ofNat_nonneg j
  have key : 2 * c * (((j : Int) + 1) * ((j : Int) + 1)) - c * (((j : Int) + 1) * ((j : Int) + 2))
      = c * ((j : Int) + 1) * (j : Int) := by ring_uor
  have hnn : 0 ≤ c * ((j : Int) + 1) * (j : Int) :=
    Int.mul_nonneg (Int.mul_nonneg hc (by omega)) hj
  omega

/-- **Per-step block UPPER bound** `g₂(j+1) − g₂(j) ≤ 2(a+2)/((j+1)(j+2))` for `j+2 ≤ 2^{a+2}`. -/
theorem g2Seq_step_le_block (a j : Nat) (hj : j + 2 ≤ 2 ^ (a + 2)) :
    Rle (Rsub (g2Seq (j + 1)) (g2Seq j))
        (ofQ (⟨(2 * ((a : Int) + 2)), (j + 1) * (j + 2)⟩ : Q)
          (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1)))) := by
  refine Rle_trans (Rle_of_Req (g2Seq_step_eq j)) ?_
  -- e_{j+1} ≤ logN(j+2)·(1/(j+1)²) ≤ (a+2)·(1/(j+1)²) ≤ 2(a+2)/((j+1)(j+2))
  refine Rle_trans (e2Step_le_num (j + 1) (Nat.succ_pos j)) ?_
  have hden : 0 < (⟨1, (j + 1) * (j + 1)⟩ : Q).den := Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos j)
  refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_ofQ hden (by show (0 : Int) ≤ 1; decide))
    (logN_le_block a j hj)) ?_
  refine Rle_trans (Rle_of_Req (Req_trans (Rmul_ofQ_ofQ Nat.one_pos hden)
    (@ofQ_congr (mul (⟨(a + 2 : Int), 1⟩ : Q) ⟨1, (j + 1) * (j + 1)⟩)
        (⟨(a + 2 : Int), (j + 1) * (j + 1)⟩ : Q) (Qmul_den_pos Nat.one_pos hden) hden
      (by simp only [mul, Qeq]; push_cast; ring_uor)))) ?_
  exact Rle_ofQ_ofQ _ _
    (Qblock_upper ((a : Int) + 2) (by show (0 : Int) ≤ (a : Int) + 2; have := Int.ofNat_nonneg a; omega) j)

/-- **Per-step block LOWER bound** `g₂(j+1) − g₂(j) ≥ −(a+2)²/((j+1)(j+2))` for `j+2 ≤ 2^{a+2}`. -/
theorem g2Seq_step_ge_block (a j : Nat) (hj : j + 2 ≤ 2 ^ (a + 2)) :
    Rle (Rneg (ofQ (⟨((a : Int) + 2) * ((a : Int) + 2), (j + 1) * (j + 2)⟩ : Q)
          (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1)))))
        (Rsub (g2Seq (j + 1)) (g2Seq j)) := by
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (g2Seq_step_eq j)))
  refine Rle_trans ?_ (e2Step_ge_num (j + 1) (Nat.succ_pos j))
  -- −(a+2)²/D ≤ logN(j+2)²·(−1/D), via squared cap multiplied by 1/D (≥0) then negated.
  have hden : 0 < (⟨1, (j + 1) * (j + 2)⟩ : Q).den :=
    Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1))
  have hofdnn : Rnonneg (ofQ (⟨1, (j + 1) * (j + 2)⟩ : Q) hden) :=
    Rnonneg_ofQ hden (by show (0 : Int) ≤ 1; decide)
  have hneg := Rle_Rneg (Rmul_le_Rmul_right hofdnn (logSq_le_block a j hj))
  refine Rle_trans (Rle_of_Req ?_) (Rle_trans hneg (Rle_of_Req ?_))
  · -- target LHS  −(a+2)²/D  ≈  −((a+2)²·(1/D))
    apply Rneg_congr
    refine Req_symm (Req_trans (Rmul_ofQ_ofQ Nat.one_pos hden) (ofQ_congr _ _ ?_))
    simp only [mul, Qeq]; push_cast; ring_uor
  · -- −(logN²·(1/D)) ≈ logN²·(−1/D)  (matches e2Step_ge_num's LHS)
    exact Req_symm (Rmul_neg_right _ _)

-- ===========================================================================
-- **γ₂ dyadic tail (Brick 4b): inner block telescoping.**  Both per-step block bounds land on the
-- `c/((p+1)(p+2))` denominator (`c` constant within a dyadic block), so a single coefficient-`c`
-- telescoping sum `Csum c` (the `γ₁` `Vsum` generalized to abstract `c`) drives BOTH the upper
-- (`c = 2(a+2)`) and lower (`c = (a+2)²`) inner bounds. `Csum c (N+d) − Csum c N = c/(N+1) −
-- c/(N+d+1)`.
-- ===========================================================================

/-- Coefficient-`c` inner block partial sum `Σ_{p<j} c/((p+1)(p+2))`. -/
def Csum (c : Int) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (j + 1) => add (Csum c j) ⟨c, (j + 1) * (j + 2)⟩

theorem Csum_den_pos (c : Int) : ∀ j, 0 < (Csum c j).den
  | 0 => Nat.one_pos
  | (j + 1) => add_den_pos (Csum_den_pos c j) (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1)))

/-- The `Csum` increment telescopes: `c/((m+1)(m+2)) = c/(m+1) − c/(m+2)`. -/
theorem Csum_step_eq (c : Int) (m : Nat) :
    Qeq (⟨c, (m + 1) * (m + 2)⟩ : Q) (Qsub (⟨c, m + 1⟩ : Q) ⟨c, m + 2⟩) := by
  simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor

/-- **Telescoped inner tail** `Csum c (N+d) − Csum c N ≤ c/(N+1) − c/(N+d+1)` (an equality; stated
    as `Qle` for the chain). Mirrors `γ₁`'s `Vsum_tail_le` with abstract coefficient. -/
theorem Csum_tail_le (c : Int) (N : Nat) (d : Nat) :
    Qle (Qsub (Csum c (N + d)) (Csum c N))
        (Qsub (⟨c, N + 1⟩ : Q) ⟨c, N + d + 1⟩) := by
  induction d with
  | zero =>
      simp only [Nat.add_zero]
      apply Qeq_le
      simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor
  | succ d ih =>
      have hA : 0 < (⟨c, (N + d + 1) * (N + d + 2)⟩ : Q).den :=
        Nat.mul_pos (Nat.succ_pos (N + d)) (Nat.succ_pos (N + d + 1))
      have hC : 0 < (Qsub (⟨c, N + 1⟩ : Q) ⟨c, N + d + 1⟩).den :=
        Qsub_den_pos (Nat.succ_pos N) (Nat.succ_pos (N + d))
      have hD : 0 < (Qsub (⟨c, N + d + 1⟩ : Q) ⟨c, N + d + 2⟩).den :=
        Qsub_den_pos (Nat.succ_pos (N + d)) (Nat.succ_pos (N + d + 1))
      have hB : 0 < (Qsub (Csum c (N + d)) (Csum c N)).den :=
        Qsub_den_pos (Csum_den_pos c (N + d)) (Csum_den_pos c N)
      have hstep : Qle (add (⟨c, (N + d + 1) * (N + d + 2)⟩ : Q)
            (Qsub (⟨c, N + 1⟩ : Q) ⟨c, N + d + 1⟩))
          (Qsub (⟨c, N + 1⟩ : Q) ⟨c, N + d + 2⟩) :=
        Qle_trans (add_den_pos hD hC)
          (Qadd_le_add (Qeq_le (Csum_step_eq c (N + d))) (Qle_refl _))
          (Qeq_le (Qadd_Qsub_telescope _ _ _))
      exact Qle_trans (add_den_pos hA hB)
        (Qeq_le (Qeq_symm (Qadd_Qsub_comm _ (Csum c (N + d)) (Csum c N))))
        (Qle_trans (add_den_pos hA hC) (Qadd_le_add (Qle_refl _) ih) hstep)

/-- **Inner block UPPER gap** (`d`-induction within block `a`): for `N+d+1 ≤ 2^{a+2}`,
    `g₂(N+d) − g₂(N) ≤ Csum (2(a+2)) (N+d) − Csum (2(a+2)) N`. Mirrors `γ₁`'s `gSeq_diff_le_U`,
    each step the per-step block bound `g2Seq_step_le_block`. -/
theorem g2Seq_diff_le_block (a N : Nat) : ∀ (d : Nat), N + d + 1 ≤ 2 ^ (a + 2) →
    Rle (Rsub (g2Seq (N + d)) (g2Seq N))
        (ofQ (Qsub (Csum (2 * ((a : Int) + 2)) (N + d)) (Csum (2 * ((a : Int) + 2)) N))
          (Qsub_den_pos (Csum_den_pos _ (N + d)) (Csum_den_pos _ N))) := by
  intro d
  induction d with
  | zero =>
      intro _
      simp only [Nat.add_zero]
      apply Rle_of_Req
      refine Req_trans (Radd_neg (g2Seq N)) (Req_symm ?_)
      apply Req_of_seq_Qeq; intro n
      simp only [ofQ, zero, Qsub, add, neg, Qeq]; push_cast; ring_uor
  | succ d ih =>
      intro hd
      have ihd := ih (by omega)
      exact Rle_trans
        (Rle_of_Req (Req_symm (Rsub_split (g2Seq (N + d + 1)) (g2Seq (N + d)) (g2Seq N))))
        (Rle_trans
          (Radd_le_add (g2Seq_step_le_block a (N + d) (by omega)) ihd)
          (Rle_of_Req (Req_trans (Radd_ofQ_ofQ _ _)
            (ofQ_congr _ _ (Qadd_Qsub_comm _ (Csum (2 * ((a : Int) + 2)) (N + d))
              (Csum (2 * ((a : Int) + 2)) N))))))

/-- **Inner block LOWER gap** (`d`-induction within block `a`): for `N+d+1 ≤ 2^{a+2}`,
    `g₂(N+d) − g₂(N) ≥ −(Csum ((a+2)²) (N+d) − Csum ((a+2)²) N)`. Mirrors `γ₁`'s `gSeq_diff_ge_block`,
    each step the per-step block bound `g2Seq_step_ge_block`. -/
theorem g2Seq_diff_ge_block (a N : Nat) : ∀ (d : Nat), N + d + 1 ≤ 2 ^ (a + 2) →
    Rle (Rneg (ofQ (Qsub (Csum (((a : Int) + 2) * ((a : Int) + 2)) (N + d))
            (Csum (((a : Int) + 2) * ((a : Int) + 2)) N))
          (Qsub_den_pos (Csum_den_pos _ (N + d)) (Csum_den_pos _ N))))
        (Rsub (g2Seq (N + d)) (g2Seq N)) := by
  intro d
  induction d with
  | zero =>
      intro _
      simp only [Nat.add_zero]
      apply Rle_of_Req
      refine Req_trans ?_ (Req_symm (Radd_neg (g2Seq N)))
      apply Req_of_seq_Qeq; intro n
      simp only [Rneg, ofQ, zero, Qsub, add, neg, Qeq]; push_cast; ring_uor
  | succ d ih =>
      intro hd
      have ihd := ih (by omega)
      have hstepd : 0 < (⟨((a : Int) + 2) * ((a : Int) + 2), (N + d + 1) * (N + d + 2)⟩ : Q).den :=
        Nat.mul_pos (Nat.succ_pos (N + d)) (Nat.succ_pos (N + d + 1))
      have hgapd : 0 < (Qsub (Csum (((a : Int) + 2) * ((a : Int) + 2)) (N + d))
          (Csum (((a : Int) + 2) * ((a : Int) + 2)) N)).den :=
        Qsub_den_pos (Csum_den_pos _ (N + d)) (Csum_den_pos _ N)
      have heq : Req (Rneg (ofQ (Qsub (Csum (((a : Int) + 2) * ((a : Int) + 2)) (N + d + 1))
              (Csum (((a : Int) + 2) * ((a : Int) + 2)) N))
            (Qsub_den_pos (Csum_den_pos _ (N + d + 1)) (Csum_den_pos _ N))))
          (Radd (Rneg (ofQ (⟨((a : Int) + 2) * ((a : Int) + 2),
                (N + d + 1) * (N + d + 2)⟩ : Q) hstepd))
                (Rneg (ofQ (Qsub (Csum (((a : Int) + 2) * ((a : Int) + 2)) (N + d))
                  (Csum (((a : Int) + 2) * ((a : Int) + 2)) N)) hgapd))) :=
        Req_trans (Rneg_congr (Req_trans
          (ofQ_congr _ _ (Qeq_symm (Qadd_Qsub_comm _ (Csum (((a : Int) + 2) * ((a : Int) + 2)) (N + d))
            (Csum (((a : Int) + 2) * ((a : Int) + 2)) N))))
          (Req_symm (Radd_ofQ_ofQ hstepd hgapd)))) (Rneg_Radd _ _)
      exact Rle_trans (Rle_of_Req heq)
        (Rle_trans (Radd_le_add (g2Seq_step_ge_block a (N + d) (by omega)) ihd)
          (Rle_of_Req (Rsub_split (g2Seq (N + d + 1)) (g2Seq (N + d)) (g2Seq N))))

-- ===========================================================================
-- **γ₂ dyadic tail (Brick 4b cont'd): per-full-block bounds** over `[2^a, 2^{a+1}]`, via the inner
-- gaps (`N = d = 2^a`) and the telescoped `Csum_tail_le`, the bound `c/(2^a+1) − c/(2^{a+1}+1) ≤
-- c/2^a` (`Qsub_block_le`). Upper coefficient `c = 2(a+2)`, lower `c = (a+2)²`.
-- ===========================================================================

/-- **Per-block UPPER bound** `g₂(2^{a+1}) − g₂(2^a) ≤ 2(a+2)/2^a`. -/
theorem g2Seq_block_le (a : Nat) :
    Rle (Rsub (g2Seq (2 ^ (a + 1))) (g2Seq (2 ^ a)))
        (ofQ (⟨2 * ((a : Int) + 2), 2 ^ a⟩ : Q) (Nat.pow_pos (by decide))) := by
  have e1 : (2 : Nat) ^ (a + 1) = 2 ^ a + 2 ^ a := by rw [Nat.pow_succ]; omega
  have e2 : (2 : Nat) ^ (a + 2) = 2 ^ (a + 1) + 2 ^ (a + 1) := by rw [Nat.pow_succ]; omega
  have hp1 : 1 ≤ (2 : Nat) ^ a := Nat.one_le_two_pow
  have hcon : 2 ^ a + 2 ^ a + 1 ≤ 2 ^ (a + 2) := by omega
  rw [e1]
  refine Rle_trans (g2Seq_diff_le_block a (2 ^ a) (2 ^ a) hcon) ?_
  have hmid : 0 < (Qsub (⟨2 * ((a : Int) + 2), 2 ^ a + 1⟩ : Q)
      ⟨2 * ((a : Int) + 2), 2 ^ a + 2 ^ a + 1⟩).den :=
    Qsub_den_pos (Nat.succ_pos (2 ^ a)) (Nat.succ_pos (2 ^ a + 2 ^ a))
  exact Rle_trans
    (Rle_ofQ_ofQ (Qsub_den_pos (Csum_den_pos _ (2 ^ a + 2 ^ a)) (Csum_den_pos _ (2 ^ a))) hmid
      (Csum_tail_le (2 * ((a : Int) + 2)) (2 ^ a) (2 ^ a)))
    (Rle_ofQ_ofQ hmid (Nat.pow_pos (by decide))
      (Qsub_block_le (2 * ((a : Int) + 2)) (by have := Int.ofNat_nonneg a; omega) (2 ^ a)))

/-- **Per-block LOWER bound** `g₂(2^{a+1}) − g₂(2^a) ≥ −(a+2)²/2^a`. -/
theorem g2Seq_block_ge (a : Nat) :
    Rle (Rneg (ofQ (⟨((a : Int) + 2) * ((a : Int) + 2), 2 ^ a⟩ : Q) (Nat.pow_pos (by decide))))
        (Rsub (g2Seq (2 ^ (a + 1))) (g2Seq (2 ^ a))) := by
  have e1 : (2 : Nat) ^ (a + 1) = 2 ^ a + 2 ^ a := by rw [Nat.pow_succ]; omega
  have e2 : (2 : Nat) ^ (a + 2) = 2 ^ (a + 1) + 2 ^ (a + 1) := by rw [Nat.pow_succ]; omega
  have hp1 : 1 ≤ (2 : Nat) ^ a := Nat.one_le_two_pow
  have hcon : 2 ^ a + 2 ^ a + 1 ≤ 2 ^ (a + 2) := by omega
  rw [e1]
  refine Rle_trans (Rle_Rneg ?_) (g2Seq_diff_ge_block a (2 ^ a) (2 ^ a) hcon)
  have hmid : 0 < (Qsub (⟨((a : Int) + 2) * ((a : Int) + 2), 2 ^ a + 1⟩ : Q)
      ⟨((a : Int) + 2) * ((a : Int) + 2), 2 ^ a + 2 ^ a + 1⟩).den :=
    Qsub_den_pos (Nat.succ_pos (2 ^ a)) (Nat.succ_pos (2 ^ a + 2 ^ a))
  exact Rle_trans
    (Rle_ofQ_ofQ (Qsub_den_pos (Csum_den_pos _ (2 ^ a + 2 ^ a)) (Csum_den_pos _ (2 ^ a))) hmid
      (Csum_tail_le (((a : Int) + 2) * ((a : Int) + 2)) (2 ^ a) (2 ^ a)))
    (Rle_ofQ_ofQ hmid (Nat.pow_pos (by decide))
      (Qsub_block_le (((a : Int) + 2) * ((a : Int) + 2))
        (Int.mul_nonneg (by have := Int.ofNat_nonneg a; omega) (by have := Int.ofNat_nonneg a; omega))
        (2 ^ a)))

-- ===========================================================================
-- **γ₂ dyadic tail (Brick 4b cont'd): outer dyadic sums.**  Chaining the per-block bounds over
-- consecutive blocks `[2^{A+i}, 2^{A+i+1})`.  Upper sum `Σ 2(m+2)/2^m` has antiderivative
-- `T_U(m) = (4m+12)/2^m`; lower sum `Σ (m+2)²/2^m` the QUADRATIC antiderivative
-- `T_L(m) = (2m²+12m+22)/2^m` (the new ingredient over `γ₁`, whose outer sum was linear).
-- ===========================================================================

/-- Outer UPPER sum `Σ_{i<e} 2(A+i+2)/2^{A+i}`. -/
def WUsum (A : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (e + 1) => add (WUsum A e) ⟨2 * ((↑(A + e) : Int) + 2), 2 ^ (A + e)⟩

theorem WUsum_den_pos (A : Nat) : ∀ e, 0 < (WUsum A e).den
  | 0 => Nat.one_pos
  | (e + 1) => add_den_pos (WUsum_den_pos A e) (Nat.pow_pos (by decide))

/-- Outer LOWER sum `Σ_{i<e} (A+i+2)²/2^{A+i}`. -/
def WLsum (A : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (e + 1) => add (WLsum A e) ⟨((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2), 2 ^ (A + e)⟩

theorem WLsum_den_pos (A : Nat) : ∀ e, 0 < (WLsum A e).den
  | 0 => Nat.one_pos
  | (e + 1) => add_den_pos (WLsum_den_pos A e) (Nat.pow_pos (by decide))

/-- **Outer UPPER bound** (`e`-induction over blocks): `g₂(2^{A+e}) − g₂(2^A) ≤ WUsum A e`. -/
theorem g2Seq_diff_le_outer (A : Nat) : ∀ e,
    Rle (Rsub (g2Seq (2 ^ (A + e))) (g2Seq (2 ^ A))) (ofQ (WUsum A e) (WUsum_den_pos A e)) := by
  intro e
  induction e with
  | zero =>
      apply Rle_of_Req
      refine Req_trans (Radd_neg (g2Seq (2 ^ A))) (Req_symm ?_)
      apply Req_of_seq_Qeq; intro n
      simp only [WUsum, ofQ, zero, Qeq]
  | succ e ih =>
      have hstepd : 0 < (⟨2 * ((↑(A + e) : Int) + 2), 2 ^ (A + e)⟩ : Q).den :=
        Nat.pow_pos (by decide)
      have hgapd : 0 < (WUsum A e).den := WUsum_den_pos A e
      have heq : Req (ofQ (WUsum A (e + 1)) (WUsum_den_pos A (e + 1)))
          (Radd (ofQ (⟨2 * ((↑(A + e) : Int) + 2), 2 ^ (A + e)⟩ : Q) hstepd)
                (ofQ (WUsum A e) hgapd)) :=
        Req_trans (ofQ_congr _ _ (by simp only [WUsum, Qeq, add]; push_cast; ring_uor))
          (Req_symm (Radd_ofQ_ofQ hstepd hgapd))
      exact Rle_trans
        (Rle_of_Req (Req_symm (Rsub_split (g2Seq (2 ^ (A + e + 1))) (g2Seq (2 ^ (A + e)))
          (g2Seq (2 ^ A)))))
        (Rle_trans (Radd_le_add (g2Seq_block_le (A + e)) ih) (Rle_of_Req (Req_symm heq)))

/-- **Outer LOWER bound** (`e`-induction over blocks): `g₂(2^{A+e}) − g₂(2^A) ≥ −WLsum A e`. -/
theorem g2Seq_diff_ge_outer (A : Nat) : ∀ e,
    Rle (Rneg (ofQ (WLsum A e) (WLsum_den_pos A e))) (Rsub (g2Seq (2 ^ (A + e))) (g2Seq (2 ^ A))) := by
  intro e
  induction e with
  | zero =>
      apply Rle_of_Req
      refine Req_trans ?_ (Req_symm (Radd_neg (g2Seq (2 ^ A))))
      apply Req_of_seq_Qeq; intro n
      simp only [Rneg, WLsum, ofQ, zero, neg, Qeq]; push_cast
  | succ e ih =>
      have hstepd : 0 < (⟨((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2), 2 ^ (A + e)⟩ : Q).den :=
        Nat.pow_pos (by decide)
      have hgapd : 0 < (WLsum A e).den := WLsum_den_pos A e
      have heq : Req (Rneg (ofQ (WLsum A (e + 1)) (WLsum_den_pos A (e + 1))))
          (Radd (Rneg (ofQ (⟨((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2), 2 ^ (A + e)⟩ : Q) hstepd))
                (Rneg (ofQ (WLsum A e) hgapd))) :=
        Req_trans (Rneg_congr (Req_trans
          (ofQ_congr _ _ (by simp only [WLsum, Qeq, add]; push_cast; ring_uor))
          (Req_symm (Radd_ofQ_ofQ hstepd hgapd)))) (Rneg_Radd _ _)
      exact Rle_trans (Rle_of_Req heq)
        (Rle_trans (Radd_le_add (g2Seq_block_ge (A + e)) ih)
          (Rle_of_Req (Rsub_split (g2Seq (2 ^ (A + e + 1))) (g2Seq (2 ^ (A + e))) (g2Seq (2 ^ A)))))

/-- **Upper antiderivative tail** `WUsum A e ≤ (4A+12)/2^A − (4(A+e)+12)/2^{A+e} ≤ (4A+12)/2^A`. -/
theorem WUsum_tail_le (A : Nat) : ∀ e,
    Qle (WUsum A e)
        (Qsub (⟨(4 * A + 12 : Int), 2 ^ A⟩ : Q) ⟨(4 * (A + e) + 12 : Int), 2 ^ (A + e)⟩)
  | 0 => by
      simp only [Nat.add_zero]
      apply Qeq_le
      simp only [WUsum, Qsub, add, neg, Qeq]; push_cast; ring_uor
  | (e + 1) => by
      have hT : 0 < (Qsub (⟨(4 * A + 12 : Int), 2 ^ A⟩ : Q) ⟨(4 * (A + e) + 12 : Int), 2 ^ (A + e)⟩).den :=
        Qsub_den_pos (Nat.pow_pos (by decide)) (Nat.pow_pos (by decide))
      have hS : 0 < (Qsub (⟨(4 * (A + e) + 12 : Int), 2 ^ (A + e)⟩ : Q)
          ⟨(4 * (A + e + 1) + 12 : Int), 2 ^ (A + e + 1)⟩).den :=
        Qsub_den_pos (Nat.pow_pos (by decide)) (Nat.pow_pos (by decide))
      have h2 : (2 : Nat) ^ (A + e + 1) = 2 * 2 ^ (A + e) := by rw [Nat.pow_succ]; omega
      have hinc : Qeq (⟨2 * ((↑(A + e) : Int) + 2), 2 ^ (A + e)⟩ : Q)
          (Qsub (⟨(4 * (A + e) + 12 : Int), 2 ^ (A + e)⟩ : Q)
            ⟨(4 * (A + e + 1) + 12 : Int), 2 ^ (A + e + 1)⟩) := by
        simp only [h2, Qsub, add, neg, Qeq]; push_cast; ring_uor
      exact Qle_trans (add_den_pos hT hS)
        (Qadd_le_add (WUsum_tail_le A e) (Qeq_le hinc))
        (Qeq_le (Qadd_Qsub_fwd _ _ _))

/-- **Lower antiderivative tail** `WLsum A e ≤ (2A²+12A+22)/2^A − (2(A+e)²+12(A+e)+22)/2^{A+e} ≤
    (2A²+12A+22)/2^A` (the quadratic discrete antiderivative). -/
theorem WLsum_tail_le (A : Nat) : ∀ e,
    Qle (WLsum A e)
        (Qsub (⟨(2 * A * A + 12 * A + 22 : Int), 2 ^ A⟩ : Q)
          ⟨(2 * (A + e) * (A + e) + 12 * (A + e) + 22 : Int), 2 ^ (A + e)⟩)
  | 0 => by
      simp only [Nat.add_zero]
      apply Qeq_le
      simp only [WLsum, Qsub, add, neg, Qeq]; push_cast; ring_uor
  | (e + 1) => by
      have hT : 0 < (Qsub (⟨(2 * A * A + 12 * A + 22 : Int), 2 ^ A⟩ : Q)
          ⟨(2 * (A + e) * (A + e) + 12 * (A + e) + 22 : Int), 2 ^ (A + e)⟩).den :=
        Qsub_den_pos (Nat.pow_pos (by decide)) (Nat.pow_pos (by decide))
      have hS : 0 < (Qsub (⟨(2 * (A + e) * (A + e) + 12 * (A + e) + 22 : Int), 2 ^ (A + e)⟩ : Q)
          ⟨(2 * (A + e + 1) * (A + e + 1) + 12 * (A + e + 1) + 22 : Int), 2 ^ (A + e + 1)⟩).den :=
        Qsub_den_pos (Nat.pow_pos (by decide)) (Nat.pow_pos (by decide))
      have h2 : (2 : Nat) ^ (A + e + 1) = 2 * 2 ^ (A + e) := by rw [Nat.pow_succ]; omega
      have hinc : Qeq (⟨((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2), 2 ^ (A + e)⟩ : Q)
          (Qsub (⟨(2 * (A + e) * (A + e) + 12 * (A + e) + 22 : Int), 2 ^ (A + e)⟩ : Q)
            ⟨(2 * (A + e + 1) * (A + e + 1) + 12 * (A + e + 1) + 22 : Int), 2 ^ (A + e + 1)⟩) := by
        simp only [h2, Qsub, add, neg, Qeq]; push_cast; ring_uor
      exact Qle_trans (add_den_pos hT hS)
        (Qadd_le_add (WLsum_tail_le A e) (Qeq_le hinc))
        (Qeq_le (Qadd_Qsub_fwd _ _ _))

-- ===========================================================================
-- **γ₂ dyadic tail (Brick 4b cont'd): reindex `M(j) = 2j+8` (reusing `γ₁`'s `gammaMidx`) and the
-- QUADRATIC domination** `(j+1)·(2M²+12M+22) ≤ 2^M`, so the antiderivative tails are `≤ 1/(j+1)`.
-- The quadratic (vs `γ₁`'s linear) needs `2M²+12M+22 ≤ 2^{j+8}` at `M=2j+8` (`8j²+88j+246 ≤ 2^{j+8}`).
-- ===========================================================================

/-- `16k+96 ≤ 2^{k+8}` (a linear-in-`k` exponential domination, the residual of the quadratic step). -/
theorem g2_lin2 (k : Nat) : 16 * k + 96 ≤ 2 ^ (k + 8) := by
  induction k with
  | zero => decide
  | succ m ih =>
      have hp : (2 : Nat) ^ (m + 1 + 8) = 2 ^ (m + 8) * 2 := by
        rw [show m + 1 + 8 = (m + 8) + 1 from by omega, Nat.pow_succ]
      omega

/-- `2(2j+8)²+12(2j+8)+22 ≤ 2^{j+8}` (i.e. `8j²+88j+246 ≤ 2^{j+8}`) — the quadratic-in-`j` block
    factor at the reindex, dominated by the exponential. -/
theorem g2_quad_lin (j : Nat) :
    2 * (2 * j + 8) * (2 * j + 8) + 12 * (2 * j + 8) + 22 ≤ 2 ^ (j + 8) := by
  induction j with
  | zero => decide
  | succ k ih =>
      have hp : (2 : Nat) ^ (k + 1 + 8) = 2 ^ (k + 8) * 2 := by
        rw [show k + 1 + 8 = (k + 8) + 1 from by omega, Nat.pow_succ]
      have hexp : 2 * (2 * (k + 1) + 8) * (2 * (k + 1) + 8) + 12 * (2 * (k + 1) + 8) + 22
          = (2 * (2 * k + 8) * (2 * k + 8) + 12 * (2 * k + 8) + 22) + (8 * (2 * k + 8) + 8 + 24) := by
        have hi : ((2 * (2 * (k + 1) + 8) * (2 * (k + 1) + 8) + 12 * (2 * (k + 1) + 8) + 22 : Nat) : Int)
            = (((2 * (2 * k + 8) * (2 * k + 8) + 12 * (2 * k + 8) + 22)
                + (8 * (2 * k + 8) + 8 + 24) : Nat) : Int) := by push_cast; ring_uor
        exact_mod_cast hi
      have hlin := g2_lin2 k
      rw [hp, hexp]
      omega

/-- **Reindex domination (lower)** `(2M²+12M+22)·(j+1) ≤ 2^M` for `M = 2j+8`. -/
theorem g2_domination (j : Nat) :
    (2 * (2 * j + 8) * (2 * j + 8) + 12 * (2 * j + 8) + 22) * (j + 1) ≤ 2 ^ (2 * j + 8) := by
  have h1 : j + 1 ≤ 2 ^ j := lt_two_pow j
  have h2 : 2 * (2 * j + 8) * (2 * j + 8) + 12 * (2 * j + 8) + 22 ≤ 2 ^ (j + 8) := g2_quad_lin j
  have h3 := Nat.mul_le_mul h2 h1
  have h4 : (2 : Nat) ^ (j + 8) * 2 ^ j = 2 ^ (2 * j + 8) := by rw [← Nat.pow_add]; congr 1; omega
  omega

/-- **Reindex domination (upper)** `(4M+12)·(j+1) ≤ 2^M` for `M = 2j+8` (`4M+12 ≤ 2M²+12M+22`). -/
theorem g2_domination_U (j : Nat) : (4 * (2 * j + 8) + 12) * (j + 1) ≤ 2 ^ (2 * j + 8) := by
  have h := g2_domination j
  have hle : 4 * (2 * j + 8) + 12 ≤ 2 * (2 * j + 8) * (2 * j + 8) + 12 * (2 * j + 8) + 22 := by omega
  have h2 := Nat.mul_le_mul_right (j + 1) hle
  omega

/-- **Lower antiderivative anchor** `T_L(M(j)) ≤ 1/(j+1)`. -/
theorem g2_T_le (j : Nat) :
    Qle (⟨(2 * gammaMidx j * gammaMidx j + 12 * gammaMidx j + 22 : Int), 2 ^ gammaMidx j⟩ : Q)
        ⟨1, j + 1⟩ := by
  simp only [Qle, gammaMidx]; push_cast
  have hcast : (((2 * (2 * j + 8) * (2 * j + 8) + 12 * (2 * j + 8) + 22) * (j + 1) : Nat) : Int)
      ≤ ((2 ^ (2 * j + 8) : Nat) : Int) := by exact_mod_cast g2_domination j
  push_cast at hcast
  omega

/-- **Upper antiderivative anchor** `T_U(M(j)) ≤ 1/(j+1)`. -/
theorem g2_TU_le (j : Nat) :
    Qle (⟨(4 * gammaMidx j + 12 : Int), 2 ^ gammaMidx j⟩ : Q) ⟨1, j + 1⟩ := by
  simp only [Qle, gammaMidx]; push_cast
  have hcast : (((4 * (2 * j + 8) + 12) * (j + 1) : Nat) : Int) ≤ ((2 ^ (2 * j + 8) : Nat) : Int) := by
    exact_mod_cast g2_domination_U j
  push_cast at hcast
  omega

/-- The reindexed `γ₂` defining sequence `g₂(2^{M(j)})`. -/
def g2SeqDyadic (j : Nat) : Real := g2Seq (2 ^ gammaMidx j)

/-- **Pairwise Cauchy (upper)**: for `j ≤ k`, `g2SeqDyadic k − g2SeqDyadic j ≤ 1/(j+1)`. -/
theorem g2_pair_le {j k : Nat} (hjk : j ≤ k) :
    Rle (Rsub (g2SeqDyadic k) (g2SeqDyadic j)) (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  simp only [g2SeqDyadic]
  obtain ⟨e, he⟩ := Nat.le.dest (gammaMidx_mono hjk)
  rw [← he]
  refine Rle_trans (g2Seq_diff_le_outer (gammaMidx j) e) ?_
  have hmid : 0 < (Qsub (⟨(4 * gammaMidx j + 12 : Int), 2 ^ gammaMidx j⟩ : Q)
      ⟨(4 * (gammaMidx j + e) + 12 : Int), 2 ^ (gammaMidx j + e)⟩).den :=
    Qsub_den_pos (Nat.pow_pos (by decide)) (Nat.pow_pos (by decide))
  have hmid2 : 0 < (⟨(4 * gammaMidx j + 12 : Int), 2 ^ gammaMidx j⟩ : Q).den :=
    Nat.pow_pos (by decide)
  exact Rle_trans (Rle_ofQ_ofQ (WUsum_den_pos _ _) hmid (WUsum_tail_le (gammaMidx j) e))
    (Rle_trans (Rle_ofQ_ofQ hmid hmid2 (Qsub_le_left _ _ (by
        have h : (0 : Int) ≤ (↑(gammaMidx j) : Int) + (↑e : Int) := by
          have := Int.ofNat_nonneg (gammaMidx j); have := Int.ofNat_nonneg e; omega
        have := Int.mul_nonneg (by decide : (0 : Int) ≤ 4) h
        omega) _ _))
      (Rle_ofQ_ofQ hmid2 (Nat.succ_pos j) (g2_TU_le j)))

/-- **Pairwise Cauchy (lower)**: for `j ≤ k`, `g2SeqDyadic k − g2SeqDyadic j ≥ −1/(j+1)`. -/
theorem g2_pair_ge {j k : Nat} (hjk : j ≤ k) :
    Rle (Rneg (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j))) (Rsub (g2SeqDyadic k) (g2SeqDyadic j)) := by
  simp only [g2SeqDyadic]
  obtain ⟨e, he⟩ := Nat.le.dest (gammaMidx_mono hjk)
  rw [← he]
  refine Rle_trans (Rle_Rneg ?_) (g2Seq_diff_ge_outer (gammaMidx j) e)
  have hmid : 0 < (Qsub (⟨(2 * gammaMidx j * gammaMidx j + 12 * gammaMidx j + 22 : Int),
        2 ^ gammaMidx j⟩ : Q)
      ⟨(2 * (gammaMidx j + e) * (gammaMidx j + e) + 12 * (gammaMidx j + e) + 22 : Int),
        2 ^ (gammaMidx j + e)⟩).den :=
    Qsub_den_pos (Nat.pow_pos (by decide)) (Nat.pow_pos (by decide))
  have hmid2 : 0 < (⟨(2 * gammaMidx j * gammaMidx j + 12 * gammaMidx j + 22 : Int),
      2 ^ gammaMidx j⟩ : Q).den :=
    Nat.pow_pos (by decide)
  exact Rle_trans (Rle_ofQ_ofQ (WLsum_den_pos _ _) hmid (WLsum_tail_le (gammaMidx j) e))
    (Rle_trans (Rle_ofQ_ofQ hmid hmid2
        (Qsub_le_left _ _ (by
          have h : (0 : Int) ≤ (↑(gammaMidx j) : Int) + (↑e : Int) := by
            have := Int.ofNat_nonneg (gammaMidx j); have := Int.ofNat_nonneg e; omega
          have h2 := Int.mul_nonneg (Int.mul_nonneg (by decide : (0 : Int) ≤ 2) h) h
          have h3 := Int.mul_nonneg (by decide : (0 : Int) ≤ 12) h
          omega) _ _))
      (Rle_ofQ_ofQ hmid2 (Nat.succ_pos j) (g2_T_le j)))

/-- **The reindexed `γ₂` sequence is regular** (`RReg`) — the input to Bishop's `Rlim`. -/
theorem g2SeqDyadic_RReg : RReg g2SeqDyadic := by
  refine RReg_of_real_bound _ (fun j k => add ⟨1, j + 1⟩ ⟨1, k + 1⟩)
    (fun j k => add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (fun j k => Qle_refl _) ?_
  intro j k
  rcases Nat.le_total j k with hjk | hkj
  · exact Rle_trans (Rle_of_Req (Req_symm (Rneg_Rsub (g2SeqDyadic k) (g2SeqDyadic j))))
      (Rle_trans (Rle_trans (Rle_Rneg (g2_pair_ge hjk)) (Rle_of_Req (Rneg_neg _)))
        (Rle_ofQ_ofQ (Nat.succ_pos _) (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
          (Qle_self_add (by show (0 : Int) ≤ 1; decide))))
  · exact Rle_trans (g2_pair_le hkj)
      (Rle_ofQ_ofQ (Nat.succ_pos _) (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
        (Qle_trans (b := add ⟨1, k + 1⟩ ⟨1, j + 1⟩)
          (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
          (Qle_self_add (p := ⟨1, j + 1⟩) (by show (0 : Int) ≤ 1; decide))
          (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))))

/-- **The second Stieltjes constant `γ₂`**, as a genuine constructive real: the Bishop limit of the
    reindexed defining sequence `g₂(2^{2j+8})`. `γ₂ ≈ −0.00969`. The regularity is the analytic
    content scoped on top of the `γ₂` substrate, mirroring `Rgamma1` for `γ₁`. -/
def Rgamma2 : Real := Rlim g2SeqDyadic g2SeqDyadic_RReg

end UOR.Bridge.F1Square.Analysis
