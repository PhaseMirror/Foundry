/-
F1 square — the **third Stieltjes constant `γ₃`** (the `n = 4` arithmetic ingredient that, with
`γ, γ₁, γ₂` and `ζ(2), ζ(3), ζ(4), log 4π`, gives the fourth Li coefficient `λ₄`).

`γ₃` is the limit of the **defining sequence**

    g₃(N) = S₃(N) − ¼·(ln N)⁴,        S₃(N) = Σ_{k=1}^N (ln k)³/k,

i.e. `γ₃ = lim_{N→∞} [ Σ_{k=1}^N (ln k)³/k − ¼(ln N)⁴ ] ≈ +0.00205`. Telescoping the `¼(ln N)⁴` term,
`g₃(N) = Σ_{k=2}^N e_k` with `e_k = (ln k)³/k − ¼[(ln k)⁴ − (ln(k−1))⁴]`; the leading `(ln k)³/k`
terms cancel against the quartic-log difference, leaving `e_k = O((ln k)³/k²)`, a convergent tail —
so `γ₃ := Rlim g₃Seq` is a genuine constructive real (the regularity is the analytic content scoped
on top of this substrate, mirroring `GammaTwo` for `γ₂`).

THIS FILE (brick 1 of γ₃): the real substrate — the term `(ln k)³/k` (reusing `GammaTwo.logCube`
`= (ln k)³`), the partial sum `S₃(N)`, the quartic `(ln N)⁴`, the sequence `g₃(N)`, the per-step
difference `e₃`, and the telescoping identity `g₃(j+1) − g₃(j) ≈ e₃`. The monotonicity/regularity
layers and the certified bracket follow (the γ₃ analogue of `GammaTwo`'s dyadic-tail stack).

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.GammaTwo

namespace UOR.Bridge.F1Square.Analysis

/-- The cubed-log harmonic term `(ln k)³/k` (for `k ≥ 1`), as a constructive real
    (reuses `logCube k = (ln k)³`). -/
def lnCubeOver (k : Nat) (hk : 1 ≤ k) : Real :=
  Rmul (logCube k hk) (ofQ ⟨1, k⟩ (by show 0 < k; omega))

/-- Each term `(ln k)³/k ≥ 0` (`(ln k)³ ≥ 0` and `1/k > 0`). -/
theorem lnCubeOver_nonneg (k : Nat) (hk : 1 ≤ k) : Rnonneg (lnCubeOver k hk) :=
  Rnonneg_Rmul (logCube_nonneg k hk)
    (Rnonneg_ofQ (by show 0 < k; omega) (by show (0 : Int) ≤ 1; decide))

/-- The partial sum `S₃(N) = Σ_{k=1}^N (ln k)³/k`. -/
def lnCubeSum : Nat → Real
  | 0 => zero
  | (n + 1) => Radd (lnCubeSum n) (lnCubeOver (n + 1) (by omega))

/-- `S₃(n) ≤ S₃(n+1)` (the new term is `≥ 0`). -/
theorem lnCubeSum_step (n : Nat) : Rle (lnCubeSum n) (lnCubeSum (n + 1)) :=
  Rle_self_Radd_right (lnCubeOver_nonneg (n + 1) (by omega))

/-- `S₃` is monotone (non-decreasing). -/
theorem lnCubeSum_mono {a b : Nat} (hab : a ≤ b) : Rle (lnCubeSum a) (lnCubeSum b) := by
  induction hab with
  | refl => exact Rle_refl _
  | step _ ih => exact Rle_trans ih (lnCubeSum_step _)

/-- The quartic `(ln N)⁴` as a constructive real (`= (ln N)³ · ln N`). -/
def logQuartic (N : Nat) (hN : 1 ≤ N) : Real :=
  Rmul (logCube N hN) (logN N hN)

/-- `(ln N)⁴ ≥ 0` for `N ≥ 1`. -/
theorem logQuartic_nonneg (N : Nat) (hN : 1 ≤ N) : Rnonneg (logQuartic N hN) :=
  Rnonneg_Rmul (logCube_nonneg N hN) (Rnonneg_logN N hN)

/-- The **defining sequence** `g₃(j+1) = S₃(j+1) − ¼·(ln (j+1))⁴` (indexed from `j = 0`).
    `γ₃ = Rlim g₃Seq`. -/
def g3Seq (j : Nat) : Real :=
  Rsub (lnCubeSum (j + 1)) (Rmul (ofQ ⟨1, 4⟩ (by decide)) (logQuartic (j + 1) (by omega)))

-- ===========================================================================
-- The per-step difference `e_{p+1} = g₃(p+1) − g₃(p)` and its telescoping identity.
-- ===========================================================================

/-- The per-step difference `e_{p+1} = g₃(p+1) − g₃(p) = (ln(p+1))³/(p+1) − ¼((ln(p+1))⁴ − (ln p)⁴)`
    (`p ≥ 1`). -/
def e3Step (p : Nat) (hp : 1 ≤ p) : Real :=
  Rsub (lnCubeOver (p + 1) (Nat.succ_pos p))
    (Rmul (ofQ ⟨1, 4⟩ (by decide))
      (Rsub (logQuartic (p + 1) (Nat.succ_pos p)) (logQuartic p hp)))

/-- **`g₃(j+1) − g₃(j) ≈ e_{j+1}`** — the consecutive difference is the per-step `e` (telescoping). -/
theorem g3Seq_step_eq (j : Nat) :
    Req (Rsub (g3Seq (j + 1)) (g3Seq j)) (e3Step (j + 1) (Nat.succ_pos j)) := by
  -- the sum telescopes: S₃(j+2) − S₃(j+1) = (ln(j+2))³/(j+2)
  have hA : Req (Rsub (lnCubeSum (j + 2)) (lnCubeSum (j + 1)))
      (lnCubeOver (j + 2) (Nat.succ_pos (j + 1))) := by
    show Req (Rsub (Radd (lnCubeSum (j + 1)) (lnCubeOver (j + 2) (by omega))) (lnCubeSum (j + 1)))
             (lnCubeOver (j + 2) (Nat.succ_pos (j + 1)))
    refine Req_trans (Rsub_congr (Radd_comm (lnCubeSum (j + 1)) (lnCubeOver (j + 2) (by omega)))
      (Req_refl _)) ?_
    refine Req_trans (Radd_assoc (lnCubeOver (j + 2) (by omega)) (lnCubeSum (j + 1))
      (Rneg (lnCubeSum (j + 1)))) ?_
    exact Req_trans (Radd_congr (Req_refl _) (Radd_neg (lnCubeSum (j + 1)))) (Radd_zero _)
  -- the quartic term: ¼Q(j+2) − ¼Q(j+1) = ¼(Q(j+2) − Q(j+1))
  have hB : Req (Rsub (Rmul (ofQ ⟨1, 4⟩ (by decide)) (logQuartic (j + 2) (by omega)))
        (Rmul (ofQ ⟨1, 4⟩ (by decide)) (logQuartic (j + 1) (by omega))))
      (Rmul (ofQ ⟨1, 4⟩ (by decide))
        (Rsub (logQuartic (j + 2) (by omega)) (logQuartic (j + 1) (by omega)))) :=
    Req_symm (Rmul_sub_distrib (ofQ ⟨1, 4⟩ (by decide)) (logQuartic (j + 2) (by omega))
      (logQuartic (j + 1) (by omega)))
  -- rearrange and combine
  refine Req_trans (Rsub_sub_sub (lnCubeSum (j + 2))
    (Rmul (ofQ ⟨1, 4⟩ (by decide)) (logQuartic (j + 2) (by omega)))
    (lnCubeSum (j + 1)) (Rmul (ofQ ⟨1, 4⟩ (by decide)) (logQuartic (j + 1) (by omega)))) ?_
  exact Rsub_congr hA hB

-- ===========================================================================
-- The quartic algebra: `a⁴ − b⁴ = (a−b)(a³+a²b+ab²+b³)` and the cancellation identity.
-- ===========================================================================

/-- `c·(x·y) ≈ x·(c·y)` — pull a left factor inward. -/
theorem Rmul_left_comm3 (c x y : Real) : Req (Rmul c (Rmul x y)) (Rmul x (Rmul c y)) :=
  Req_trans (Req_symm (Rmul_assoc c x y))
    (Req_trans (Rmul_congr (Rmul_comm c x) (Req_refl y)) (Rmul_assoc x c y))

set_option maxHeartbeats 1000000 in
/-- **`(a−b)(a³ + a²b + ab² + b³) ≈ a⁴ − b⁴`** — the difference-of-quartics factoring
    (the quartic analogue of `cube_diff_identity`), with `a⁴ = ((a·a)·a)·a`, `b⁴ = ((b·b)·b)·b`. -/
theorem quartic_diff_identity (a b : Real) :
    Req (Rmul (Rsub a b)
          (Radd (Radd (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)) (Rmul (Rmul a b) b))
            (Rmul (Rmul b b) b)))
        (Rsub (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul b b) b) b)) := by
  refine Req_trans (Rmul_sub_distrib_right a b
    (Radd (Radd (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)) (Rmul (Rmul a b) b))
      (Rmul (Rmul b b) b))) ?_
  have haS : Req (Rmul a (Radd (Radd (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)) (Rmul (Rmul a b) b))
        (Rmul (Rmul b b) b)))
      (Radd (Radd (Radd (Rmul a (Rmul (Rmul a a) a)) (Rmul a (Rmul (Rmul a a) b)))
        (Rmul a (Rmul (Rmul a b) b))) (Rmul a (Rmul (Rmul b b) b))) :=
    Req_trans (Rmul_distrib a (Radd (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)) (Rmul (Rmul a b) b))
        (Rmul (Rmul b b) b))
      (Radd_congr (Req_trans (Rmul_distrib a (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) b))
            (Rmul (Rmul a b) b))
          (Radd_congr (Rmul_distrib a (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)) (Req_refl _)))
        (Req_refl _))
  have hbS : Req (Rmul b (Radd (Radd (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)) (Rmul (Rmul a b) b))
        (Rmul (Rmul b b) b)))
      (Radd (Radd (Radd (Rmul b (Rmul (Rmul a a) a)) (Rmul b (Rmul (Rmul a a) b)))
        (Rmul b (Rmul (Rmul a b) b))) (Rmul b (Rmul (Rmul b b) b))) :=
    Req_trans (Rmul_distrib b (Radd (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)) (Rmul (Rmul a b) b))
        (Rmul (Rmul b b) b))
      (Radd_congr (Req_trans (Rmul_distrib b (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) b))
            (Rmul (Rmul a b) b))
          (Radd_congr (Rmul_distrib b (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)) (Req_refl _)))
        (Req_refl _))
  refine Req_trans (Rsub_congr haS hbS) ?_
  -- cross-term identifications: a·A2B = b·A3, a·AB2 = b·A2B, a·B3 = b·AB2
  have hx1 : Req (Rmul a (Rmul (Rmul a a) b)) (Rmul b (Rmul (Rmul a a) a)) :=
    Req_trans (Rmul_left_comm3 a (Rmul a a) b)
      (Req_trans (Rmul_congr (Req_refl _) (Rmul_comm a b)) (Rmul_left_comm3 (Rmul a a) b a))
  have hx2 : Req (Rmul a (Rmul (Rmul a b) b)) (Rmul b (Rmul (Rmul a a) b)) :=
    Req_trans (Rmul_left_comm3 a (Rmul a b) b)
      (Req_trans
        (Req_trans (Rmul_left_comm3 (Rmul a b) a b)
          (Req_trans (Rmul_congr (Req_refl a) (Rmul_assoc a b b))
            (Req_symm (Rmul_assoc a a (Rmul b b)))))
        (Req_symm (Rmul_left_comm3 b (Rmul a a) b)))
  have hx3 : Req (Rmul a (Rmul (Rmul b b) b)) (Rmul b (Rmul (Rmul a b) b)) :=
    Req_trans (Rmul_left_comm3 a (Rmul b b) b)
      (Req_trans (Rmul_comm (Rmul b b) (Rmul a b)) (Req_symm (Rmul_left_comm3 b (Rmul a b) b)))
  refine Req_trans (Rsub_congr
    (Radd_congr (Radd_congr (Radd_congr (Req_refl _) hx1) hx2) hx3) (Req_refl _)) ?_
  -- telescope: (((P+M₁)+M₂)+M₃) − (((M₁+M₂)+M₃)+Q) ≈ P − Q
  have hcancel : ∀ P S Q : Real, Req (Rsub (Radd P S) (Radd S Q)) (Rsub P Q) := by
    intro P S Q
    refine Req_trans (Radd_congr (Req_refl (Radd P S)) (Rneg_Radd S Q)) ?_
    refine Req_trans (Radd_assoc P S (Radd (Rneg S) (Rneg Q))) ?_
    refine Req_trans (Radd_congr (Req_refl P) (Req_symm (Radd_assoc S (Rneg S) (Rneg Q)))) ?_
    refine Req_trans (Radd_congr (Req_refl P) (Radd_congr (Radd_neg S) (Req_refl (Rneg Q)))) ?_
    exact Radd_congr (Req_refl P)
      (Req_trans (Radd_comm zero (Rneg Q)) (Radd_zero (Rneg Q)))
  have htel3 : ∀ P M₁ M₂ M₃ Q : Real,
      Req (Rsub (Radd (Radd (Radd P M₁) M₂) M₃) (Radd (Radd (Radd M₁ M₂) M₃) Q)) (Rsub P Q) := by
    intro P M₁ M₂ M₃ Q
    refine Req_trans (Rsub_congr ?_ (Req_refl _)) (hcancel P (Radd (Radd M₁ M₂) M₃) Q)
    refine Req_trans (Radd_assoc (Radd P M₁) M₂ M₃) ?_
    refine Req_trans (Radd_assoc P M₁ (Radd M₂ M₃)) ?_
    exact Radd_congr (Req_refl P) (Req_symm (Radd_assoc M₁ M₂ M₃))
  refine Req_trans (htel3 (Rmul a (Rmul (Rmul a a) a)) (Rmul b (Rmul (Rmul a a) a))
    (Rmul b (Rmul (Rmul a a) b)) (Rmul b (Rmul (Rmul a b) b)) (Rmul b (Rmul (Rmul b b) b))) ?_
  exact Rsub_congr (Rmul_comm a (Rmul (Rmul a a) a)) (Rmul_comm b (Rmul (Rmul b b) b))

/-- **`¼·(((Y+Y)+Y)+Y) ≈ Y`** — the rational coefficient closing the `e₃` decomposition
    (`¼·4a³ = a³`): distribute `¼`, factor to `(((¼+¼)+¼)+¼)·Y`, and `¼·4 = 1`. -/
theorem Rmul_fourth_four (Y : Real) :
    Req (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) (Radd (Radd (Radd Y Y) Y) Y)) Y := by
  have hdist : Req (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) (Radd (Radd (Radd Y Y) Y) Y))
      (Rmul (Radd (Radd (Radd (ofQ (⟨1, 4⟩ : Q) (by decide)) (ofQ (⟨1, 4⟩ : Q) (by decide)))
        (ofQ (⟨1, 4⟩ : Q) (by decide))) (ofQ (⟨1, 4⟩ : Q) (by decide))) Y) := by
    refine Req_trans (Rmul_distrib (ofQ (⟨1, 4⟩ : Q) (by decide)) (Radd (Radd Y Y) Y) Y) ?_
    refine Req_trans (Radd_congr (Rmul_distrib (ofQ (⟨1, 4⟩ : Q) (by decide)) (Radd Y Y) Y)
      (Req_refl _)) ?_
    refine Req_trans (Radd_congr (Radd_congr
      (Rmul_distrib (ofQ (⟨1, 4⟩ : Q) (by decide)) Y Y) (Req_refl _)) (Req_refl _)) ?_
    refine Req_trans (Radd_congr (Radd_congr
      (Req_symm (Rmul_distrib_right (ofQ (⟨1, 4⟩ : Q) (by decide)) (ofQ (⟨1, 4⟩ : Q) (by decide)) Y))
      (Req_refl _)) (Req_refl _)) ?_
    refine Req_trans (Radd_congr
      (Req_symm (Rmul_distrib_right (Radd (ofQ (⟨1, 4⟩ : Q) (by decide)) (ofQ (⟨1, 4⟩ : Q) (by decide)))
        (ofQ (⟨1, 4⟩ : Q) (by decide)) Y)) (Req_refl _)) ?_
    exact Req_symm (Rmul_distrib_right
      (Radd (Radd (ofQ (⟨1, 4⟩ : Q) (by decide)) (ofQ (⟨1, 4⟩ : Q) (by decide)))
        (ofQ (⟨1, 4⟩ : Q) (by decide))) (ofQ (⟨1, 4⟩ : Q) (by decide)) Y)
  refine Req_trans hdist ?_
  have hcoef : Req (Radd (Radd (Radd (ofQ (⟨1, 4⟩ : Q) (by decide)) (ofQ (⟨1, 4⟩ : Q) (by decide)))
      (ofQ (⟨1, 4⟩ : Q) (by decide))) (ofQ (⟨1, 4⟩ : Q) (by decide))) one := by
    refine Req_trans (Radd_congr (Radd_congr (Radd_ofQ_ofQ (by decide) (by decide)) (Req_refl _))
      (Req_refl _)) ?_
    refine Req_trans (Radd_congr (Radd_ofQ_ofQ (by decide) (by decide)) (Req_refl _)) ?_
    refine Req_trans (Radd_ofQ_ofQ (by decide) (by decide)) ?_
    exact Req_of_seq_Qeq (fun _ => by
      show Qeq (add (add (add (⟨1, 4⟩ : Q) ⟨1, 4⟩) ⟨1, 4⟩) ⟨1, 4⟩) ⟨1, 1⟩; decide)
  exact Req_trans (Rmul_congr hcoef (Req_refl Y)) (Rone_mul Y)

-- ===========================================================================
-- The `e₃` envelope bounds: `W₃ ∈ [4b³, 4a³]` ⟹ `¼(a⁴−b⁴) ∈ [b³δ, a³δ]` ⟹ summable `e₃`.
-- ===========================================================================

/-- `b·b·b ≤ a·a·a` for `0 ≤ b ≤ a` (cube monotone), with the `((·)·)·` association. -/
theorem cube_mono {a b : Real} (hb : Rnonneg b) (ha : Rnonneg a) (hab : Rle b a) :
    Rle (Rmul (Rmul b b) b) (Rmul (Rmul a a) a) :=
  Rle_trans (Rmul_le_Rmul_right hb (Rle_trans (Rmul_le_Rmul_right hb hab) (Rmul_le_Rmul_left ha hab)))
    (Rmul_le_Rmul_left (Rnonneg_Rmul ha ha) hab)

/-- `4b³ ≤ W₃` (each of the four terms of `W₃` is `≥ b³`, for `0 ≤ b ≤ a`). -/
theorem W3_ge_4b3 {a b : Real} (hb : Rnonneg b) (ha : Rnonneg a) (hab : Rle b a) :
    Rle (Radd (Radd (Radd (Rmul (Rmul b b) b) (Rmul (Rmul b b) b)) (Rmul (Rmul b b) b))
          (Rmul (Rmul b b) b))
        (Radd (Radd (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)) (Rmul (Rmul a b) b))
          (Rmul (Rmul b b) b)) := by
  have h1 : Rle (Rmul (Rmul b b) b) (Rmul (Rmul a a) a) := cube_mono hb ha hab
  have h2 : Rle (Rmul (Rmul b b) b) (Rmul (Rmul a a) b) :=
    Rmul_le_Rmul_right hb (Rle_trans (Rmul_le_Rmul_right hb hab) (Rmul_le_Rmul_left ha hab))
  have h3 : Rle (Rmul (Rmul b b) b) (Rmul (Rmul a b) b) :=
    Rmul_le_Rmul_right hb (Rmul_le_Rmul_right hb hab)
  exact Radd_le_add (Radd_le_add (Radd_le_add h1 h2) h3) (Rle_refl _)

/-- `W₃ ≤ 4a³` (each of the four terms of `W₃` is `≤ a³`, for `0 ≤ b ≤ a`). -/
theorem W3_le_4a3 {a b : Real} (hb : Rnonneg b) (ha : Rnonneg a) (hab : Rle b a) :
    Rle (Radd (Radd (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)) (Rmul (Rmul a b) b))
          (Rmul (Rmul b b) b))
        (Radd (Radd (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) a)) (Rmul (Rmul a a) a))
          (Rmul (Rmul a a) a)) := by
  have h2 : Rle (Rmul (Rmul a a) b) (Rmul (Rmul a a) a) := Rmul_le_Rmul_left (Rnonneg_Rmul ha ha) hab
  have h3 : Rle (Rmul (Rmul a b) b) (Rmul (Rmul a a) a) :=
    Rle_trans (Rmul_le_Rmul_right hb (Rmul_le_Rmul_left ha hab)) (Rmul_le_Rmul_left (Rnonneg_Rmul ha ha) hab)
  have h4 : Rle (Rmul (Rmul b b) b) (Rmul (Rmul a a) a) := cube_mono hb ha hab
  exact Radd_le_add (Radd_le_add (Radd_le_add (Rle_refl _) h2) h3) h4

/-- **`¼(a⁴−b⁴) ≤ a³·δ`** (`a = ln(p+1)`, `b = ln p`, `δ = a−b`): from `quartic_diff_identity`,
    `W₃ ≤ 4a³` (`W3_le_4a3`), and `¼·4a³ = a³` (`Rmul_fourth_four`). -/
theorem quarter_diff_le (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
          (Rsub (logQuartic (p + 1) (Nat.succ_pos p)) (logQuartic p hp)))
        (Rmul (logCube (p + 1) (Nat.succ_pos p))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) := by
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl _)
    (Req_symm (quartic_diff_identity (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (Rmul_le_Rmul_left hδnn (W3_le_4a3 (Rnonneg_logN p hp) (Rnonneg_logN (p + 1) (Nat.succ_pos p))
      (logN_mono hp (Nat.le_succ p))))) ?_
  refine Rle_of_Req (Req_trans (Rmul_left_comm3 (ofQ (⟨1, 4⟩ : Q) (by decide))
    (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
    (Radd (Radd (Radd (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
      (logN (p + 1) (Nat.succ_pos p))) (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p))
      (logN (p + 1) (Nat.succ_pos p))) (logN (p + 1) (Nat.succ_pos p))))
      (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
        (logN (p + 1) (Nat.succ_pos p))))
      (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
        (logN (p + 1) (Nat.succ_pos p)))))
    (Req_trans (Rmul_congr (Req_refl _)
      (Rmul_fourth_four (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
        (logN (p + 1) (Nat.succ_pos p)))))
      (Rmul_comm (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
          (logN (p + 1) (Nat.succ_pos p))))))

/-- **`e₃ ≥ −a³/(p(p+1))`** (`a = ln(p+1)`) — the summable LOWER envelope, via
    `e₃ = a³u − ¼(a⁴−b⁴) ≥ a³u − a³δ = a³(u−δ)` and `u − δ ≥ −1/(p(p+1))` (`δ ≤ 1/p`). -/
theorem e3Step_ge_num (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (logCube (p + 1) (Nat.succ_pos p))
          (Rneg (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p)))))
        (e3Step p hp) := by
  have ha3nn : Rnonneg (logCube (p + 1) (Nat.succ_pos p)) := logCube_nonneg (p + 1) (Nat.succ_pos p)
  -- u − δ ≥ −1/(p(p+1))
  have hud : Rle (Rneg (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))))
      (Rsub (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))
        (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) := by
    have huvp : Req (Rneg (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))))
        (Rsub (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)) (ofQ (⟨1, p⟩ : Q) hp)) :=
      Req_of_seq_Qeq (fun n => by
        simp only [Rsub, Radd, Rneg, ofQ, Qeq, neg, add]; try push_cast <;> try ring_uor)
    exact Rle_trans (Rle_of_Req huvp)
      (Rsub_le_sub (Rle_refl _) (deltaLog_upper p hp))
  refine Rle_trans (Rmul_le_Rmul_left ha3nn hud) ?_
  refine Rle_trans (Rle_of_Req (Rmul_sub_distrib (logCube (p + 1) (Nat.succ_pos p))
    (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)) (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))) ?_
  exact Rsub_le_sub (Rle_refl _) (quarter_diff_le p hp)

/-- **`b³·δ ≤ ¼(a⁴−b⁴)`** (`b = ln p`, `δ = a−b`): from `quartic_diff_identity`, `4b³ ≤ W₃`
    (`W3_ge_4b3`), and `¼·4b³ = b³` (`Rmul_fourth_four`). -/
theorem quarter_diff_ge (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (logCube p hp) (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
        (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
          (Rsub (logQuartic (p + 1) (Nat.succ_pos p)) (logQuartic p hp))) := by
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  refine Rle_trans (Rle_of_Req (Req_symm (Req_trans (Rmul_left_comm3 (ofQ (⟨1, 4⟩ : Q) (by decide))
    (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
    (Radd (Radd (Radd (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp))
      (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp)))
      (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp)))
      (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp))))
    (Req_trans (Rmul_congr (Req_refl _)
      (Rmul_fourth_four (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp))))
      (Rmul_comm (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp))))))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (Rmul_le_Rmul_left hδnn (W3_ge_4b3 (Rnonneg_logN p hp) (Rnonneg_logN (p + 1) (Nat.succ_pos p))
      (logN_mono hp (Nat.le_succ p))))) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl _)
    (quartic_diff_identity (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))

/-- **`X + X + X ≈ 3·X`** (repeated-add to scalar). -/
theorem Rthree_mul (X : Real) :
    Req (Radd (Radd X X) X) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) X) := by
  have hc : Req (ofQ (⟨3, 1⟩ : Q) (by decide))
      (Radd (Radd (ofQ (⟨1, 1⟩ : Q) (by decide)) (ofQ (⟨1, 1⟩ : Q) (by decide)))
        (ofQ (⟨1, 1⟩ : Q) (by decide))) := by
    refine Req_symm (Req_trans (Radd_congr (Radd_ofQ_ofQ (by decide) (by decide)) (Req_refl _)) ?_)
    refine Req_trans (Radd_ofQ_ofQ (by decide) (by decide)) ?_
    exact ofQ_congr (by decide) (by decide)
      (by show Qeq (add (add (⟨1, 1⟩ : Q) ⟨1, 1⟩) ⟨1, 1⟩) ⟨3, 1⟩; decide)
  refine Req_symm (Req_trans (Rmul_congr hc (Req_refl X)) ?_)
  refine Req_trans (Rmul_distrib_right (Radd (ofQ (⟨1, 1⟩ : Q) (by decide))
    (ofQ (⟨1, 1⟩ : Q) (by decide))) (ofQ (⟨1, 1⟩ : Q) (by decide)) X) ?_
  exact Radd_congr (Req_trans (Rmul_distrib_right (ofQ (⟨1, 1⟩ : Q) (by decide))
    (ofQ (⟨1, 1⟩ : Q) (by decide)) X) (Radd_congr (Rone_mul X) (Rone_mul X))) (Rone_mul X)

set_option maxHeartbeats 1000000 in
/-- **`e₃ ≤ 3a²/(p(p+1))`** (`a = ln(p+1)`) — the summable UPPER envelope, via
    `e₃ = a³u − ¼(a⁴−b⁴) ≤ a³u − b³u = (a³−b³)u = δW₂u`, `δu ≤ 1/(p(p+1))`, `W₂ ≤ 3a²`. -/
theorem e3Step_le_num (p : Nat) (hp : 1 ≤ p) :
    Rle (e3Step p hp)
        (Rmul (ofQ (⟨3, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p)))
          (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))) := by
  have ha2nn : Rnonneg (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p))) :=
    Rnonneg_Rmul_self _
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hunn : Rnonneg (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)) :=
    Rnonneg_ofQ (Nat.succ_pos p) (by show (0 : Int) ≤ 1; decide)
  have hb3nn : Rnonneg (logCube p hp) := logCube_nonneg p hp
  -- W₂ ≤ 3a²
  have hW2le : Rle (Radd (Radd (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
        (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) (Rmul (logN p hp) (logN p hp)))
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide))
        (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))) := by
    have hab : Rle (logN p hp) (logN (p + 1) (Nat.succ_pos p)) := logN_mono hp (Nat.le_succ p)
    have ha : Rnonneg (logN (p + 1) (Nat.succ_pos p)) := Rnonneg_logN (p + 1) (Nat.succ_pos p)
    have hb : Rnonneg (logN p hp) := Rnonneg_logN p hp
    refine Rle_trans (Radd_le_add (Radd_le_add (Rle_refl _)
      (Rmul_le_Rmul_left ha hab)) (Rle_trans (Rmul_le_Rmul_right hb hab) (Rmul_le_Rmul_left ha hab)))
      (Rle_of_Req (Rthree_mul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))))
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
  -- chain: e₃ ≤ Rsub(a³u)(b³δ) ≤ Rsub(a³u)(b³u) ≈ (a³−b³)u ≈ (δW₂)u ≈ (δu)W₂ ≤ (δu)(3a²) ≤ (1/(p(p+1)))(3a²) ≈ target
  refine Rle_trans (Rsub_le_sub (Rle_refl _) (quarter_diff_ge p hp)) ?_
  refine Rle_trans (Rsub_le_sub (Rle_refl _)
    (Rmul_le_Rmul_left hb3nn (deltaLog_lower p hp))) ?_
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_sub_distrib_right (logCube (p + 1) (Nat.succ_pos p))
    (logCube p hp) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr
    (Req_symm (cube_diff_identity (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) (Req_refl _))) ?_
  -- (δW₂)u ≈ (δu)W₂
  refine Rle_trans (Rle_of_Req (Req_trans (Rmul_assoc (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
      (Radd (Radd (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
          (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) (Rmul (logN p hp) (logN p hp)))
      (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
    (Req_trans (Rmul_congr (Req_refl _) (Rmul_comm _ (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
      (Req_symm (Rmul_assoc (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))
        (Radd (Radd (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
          (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) (Rmul (logN p hp) (logN p hp)))))))) ?_
  -- (δu)W₂ ≤ (δu)(3a²) ≤ (1/(p(p+1)))(3a²) ≈ target
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_Rmul hδnn hunn) hW2le) ?_
  refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) ha2nn) hδu) ?_
  refine Rle_of_Req (Req_trans (Req_symm (Rmul_assoc
    (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p)))
    (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))))
    (Rmul_congr (Req_trans (Rmul_ofQ_ofQ (Nat.mul_pos hp (Nat.succ_pos p)) (by decide))
      (ofQ_congr (Qmul_den_pos (Nat.mul_pos hp (Nat.succ_pos p)) (by decide))
        (Nat.mul_pos hp (Nat.succ_pos p))
        (by show Qeq (mul (⟨1, p * (p + 1)⟩ : Q) ⟨3, 1⟩) ⟨3, p * (p + 1)⟩
            simp only [mul, Qeq]; try push_cast <;> try ring_uor))) (Req_refl _)))

-- ===========================================================================
-- Brick 4: dyadic-block telescoping → regularity → `Rgamma3`.
-- ===========================================================================

/-- **Cubed block-log cap** `logN(j+2)³ ≤ (a+2)³` for `j+2 ≤ 2^{a+2}`. -/
theorem logCube_le_block (a j : Nat) (hj : j + 2 ≤ 2 ^ (a + 2)) :
    Rle (logCube (j + 2) (by omega)) (ofQ (⟨((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2), 1⟩ : Q)
      Nat.one_pos) := by
  have hcapnn : Rnonneg (ofQ (⟨((a : Int) + 2) * ((a : Int) + 2), 1⟩ : Q) Nat.one_pos) := by
    refine Rnonneg_ofQ Nat.one_pos ?_
    have := Int.ofNat_nonneg a
    exact Int.mul_nonneg (by omega) (by omega)
  refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_logN _ _) (logSq_le_block a j hj)) ?_
  refine Rle_trans (Rmul_le_Rmul_left hcapnn (logN_le_block a j hj)) ?_
  exact Rle_of_Req (Req_trans (Rmul_ofQ_ofQ Nat.one_pos Nat.one_pos)
    (ofQ_congr _ _ (by simp only [mul, Qeq]; try push_cast <;> try ring_uor)))

/-- **Per-step block UPPER bound** `g₃(j+1) − g₃(j) ≤ 3(a+2)²/((j+1)(j+2))` for `j+2 ≤ 2^{a+2}`. -/
theorem g3Seq_step_le_block (a j : Nat) (hj : j + 2 ≤ 2 ^ (a + 2)) :
    Rle (Rsub (g3Seq (j + 1)) (g3Seq j))
        (ofQ (⟨3 * (((a : Int) + 2) * ((a : Int) + 2)), (j + 1) * (j + 2)⟩ : Q)
          (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1)))) := by
  refine Rle_trans (Rle_of_Req (g3Seq_step_eq j)) ?_
  refine Rle_trans (e3Step_le_num (j + 1) (Nat.succ_pos j)) ?_
  have hden : 0 < (⟨3, (j + 1) * (j + 2)⟩ : Q).den := Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1))
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hden (by show (0 : Int) ≤ 3; decide))
    (logSq_le_block a j hj)) ?_
  exact Rle_of_Req (Req_trans (Rmul_ofQ_ofQ hden Nat.one_pos)
    (ofQ_congr _ _ (by simp only [mul, Qeq]; try push_cast <;> try ring_uor)))

/-- **Per-step block LOWER bound** `g₃(j+1) − g₃(j) ≥ −(a+2)³/((j+1)(j+2))` for `j+2 ≤ 2^{a+2}`. -/
theorem g3Seq_step_ge_block (a j : Nat) (hj : j + 2 ≤ 2 ^ (a + 2)) :
    Rle (Rneg (ofQ (⟨((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2), (j + 1) * (j + 2)⟩ : Q)
          (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1)))))
        (Rsub (g3Seq (j + 1)) (g3Seq j)) := by
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (g3Seq_step_eq j)))
  refine Rle_trans ?_ (e3Step_ge_num (j + 1) (Nat.succ_pos j))
  have hden : 0 < (⟨1, (j + 1) * (j + 2)⟩ : Q).den :=
    Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1))
  have hofdnn : Rnonneg (ofQ (⟨1, (j + 1) * (j + 2)⟩ : Q) hden) :=
    Rnonneg_ofQ hden (by show (0 : Int) ≤ 1; decide)
  have hneg := Rle_Rneg (Rmul_le_Rmul_right hofdnn (logCube_le_block a j hj))
  refine Rle_trans (Rle_of_Req ?_) (Rle_trans hneg (Rle_of_Req ?_))
  · apply Rneg_congr
    refine Req_symm (Req_trans (Rmul_ofQ_ofQ Nat.one_pos hden) (ofQ_congr _ _ ?_))
    simp only [mul, Qeq]; try push_cast <;> try ring_uor
  · exact Req_symm (Rmul_neg_right _ _)


/-- **Inner block UPPER gap** (`d`-induction): for `N+d+1 ≤ 2^{a+2}`,
    `g₃(N+d) − g₃(N) ≤ Csum (3(a+2)²) (N+d) − Csum (3(a+2)²) N`. -/
theorem g3Seq_diff_le_block (a N : Nat) : ∀ (d : Nat), N + d + 1 ≤ 2 ^ (a + 2) →
    Rle (Rsub (g3Seq (N + d)) (g3Seq N))
        (ofQ (Qsub (Csum (3 * (((a : Int) + 2) * ((a : Int) + 2))) (N + d))
            (Csum (3 * (((a : Int) + 2) * ((a : Int) + 2))) N))
          (Qsub_den_pos (Csum_den_pos _ (N + d)) (Csum_den_pos _ N))) := by
  intro d
  induction d with
  | zero =>
      intro _
      simp only [Nat.add_zero]
      apply Rle_of_Req
      refine Req_trans (Radd_neg (g3Seq N)) (Req_symm ?_)
      apply Req_of_seq_Qeq; intro n
      simp only [ofQ, zero, Qsub, add, neg, Qeq]; push_cast <;> try ring_uor
  | succ d ih =>
      intro hd
      have ihd := ih (by omega)
      exact Rle_trans
        (Rle_of_Req (Req_symm (Rsub_split (g3Seq (N + d + 1)) (g3Seq (N + d)) (g3Seq N))))
        (Rle_trans
          (Radd_le_add (g3Seq_step_le_block a (N + d) (by omega)) ihd)
          (Rle_of_Req (Req_trans (Radd_ofQ_ofQ _ _)
            (ofQ_congr _ _ (Qadd_Qsub_comm _ (Csum (3 * (((a : Int) + 2) * ((a : Int) + 2))) (N + d))
              (Csum (3 * (((a : Int) + 2) * ((a : Int) + 2))) N))))))

/-- **Inner block LOWER gap** (`d`-induction): for `N+d+1 ≤ 2^{a+2}`,
    `g₃(N+d) − g₃(N) ≥ −(Csum ((a+2)³) (N+d) − Csum ((a+2)³) N)`. -/
theorem g3Seq_diff_ge_block (a N : Nat) : ∀ (d : Nat), N + d + 1 ≤ 2 ^ (a + 2) →
    Rle (Rneg (ofQ (Qsub (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) (N + d))
            (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) N))
          (Qsub_den_pos (Csum_den_pos _ (N + d)) (Csum_den_pos _ N))))
        (Rsub (g3Seq (N + d)) (g3Seq N)) := by
  intro d
  induction d with
  | zero =>
      intro _
      simp only [Nat.add_zero]
      apply Rle_of_Req
      refine Req_trans ?_ (Req_symm (Radd_neg (g3Seq N)))
      apply Req_of_seq_Qeq; intro n
      simp only [Rneg, ofQ, zero, Qsub, add, neg, Qeq]; push_cast <;> try ring_uor
  | succ d ih =>
      intro hd
      have ihd := ih (by omega)
      have hstepd : 0 < (⟨((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2),
          (N + d + 1) * (N + d + 2)⟩ : Q).den :=
        Nat.mul_pos (Nat.succ_pos (N + d)) (Nat.succ_pos (N + d + 1))
      have hgapd : 0 < (Qsub (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) (N + d))
          (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) N)).den :=
        Qsub_den_pos (Csum_den_pos _ (N + d)) (Csum_den_pos _ N)
      have heq : Req (Rneg (ofQ (Qsub (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) (N + d + 1))
              (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) N))
            (Qsub_den_pos (Csum_den_pos _ (N + d + 1)) (Csum_den_pos _ N))))
          (Radd (Rneg (ofQ (⟨((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2),
                (N + d + 1) * (N + d + 2)⟩ : Q) hstepd))
                (Rneg (ofQ (Qsub (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) (N + d))
                  (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) N)) hgapd))) :=
        Req_trans (Rneg_congr (Req_trans
          (ofQ_congr _ _ (Qeq_symm (Qadd_Qsub_comm _
            (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) (N + d))
            (Csum (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) N))))
          (Req_symm (Radd_ofQ_ofQ hstepd hgapd)))) (Rneg_Radd _ _)
      exact Rle_trans (Rle_of_Req heq)
        (Rle_trans (Radd_le_add (g3Seq_step_ge_block a (N + d) (by omega)) ihd)
          (Rle_of_Req (Rsub_split (g3Seq (N + d + 1)) (g3Seq (N + d)) (g3Seq N))))



/-- **Per-block UPPER bound** `g₃(2^{a+1}) − g₃(2^a) ≤ 3(a+2)²/2^a`. -/
theorem g3Seq_block_le (a : Nat) :
    Rle (Rsub (g3Seq (2 ^ (a + 1))) (g3Seq (2 ^ a)))
        (ofQ (⟨3 * (((a : Int) + 2) * ((a : Int) + 2)), 2 ^ a⟩ : Q) (Nat.pos_pow_of_pos a (by decide))) := by
  have e1 : (2 : Nat) ^ (a + 1) = 2 ^ a + 2 ^ a := by rw [Nat.pow_succ]; omega
  have hp1 : 1 ≤ (2 : Nat) ^ a := Nat.one_le_two_pow
  have hcon : 2 ^ a + 2 ^ a + 1 ≤ 2 ^ (a + 2) := by
    have e2 : (2 : Nat) ^ (a + 2) = 2 ^ (a + 1) + 2 ^ (a + 1) := by rw [Nat.pow_succ]; omega
    omega
  rw [e1]
  refine Rle_trans (g3Seq_diff_le_block a (2 ^ a) (2 ^ a) hcon) ?_
  have hmid : 0 < (Qsub (⟨3 * (((a : Int) + 2) * ((a : Int) + 2)), 2 ^ a + 1⟩ : Q)
      ⟨3 * (((a : Int) + 2) * ((a : Int) + 2)), 2 ^ a + 2 ^ a + 1⟩).den :=
    Qsub_den_pos (Nat.succ_pos (2 ^ a)) (Nat.succ_pos (2 ^ a + 2 ^ a))
  exact Rle_trans
    (Rle_ofQ_ofQ (Qsub_den_pos (Csum_den_pos _ (2 ^ a + 2 ^ a)) (Csum_den_pos _ (2 ^ a))) hmid
      (Csum_tail_le (3 * (((a : Int) + 2) * ((a : Int) + 2))) (2 ^ a) (2 ^ a)))
    (Rle_ofQ_ofQ hmid (Nat.pos_pow_of_pos a (by decide))
      (Qsub_block_le (3 * (((a : Int) + 2) * ((a : Int) + 2)))
        (Int.mul_nonneg (by decide) (Int.mul_nonneg (by have := Int.ofNat_nonneg a; omega)
          (by have := Int.ofNat_nonneg a; omega))) (2 ^ a)))

/-- **Per-block LOWER bound** `g₃(2^{a+1}) − g₃(2^a) ≥ −(a+2)³/2^a`. -/
theorem g3Seq_block_ge (a : Nat) :
    Rle (Rneg (ofQ (⟨((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2), 2 ^ a⟩ : Q)
          (Nat.pos_pow_of_pos a (by decide))))
        (Rsub (g3Seq (2 ^ (a + 1))) (g3Seq (2 ^ a))) := by
  have e1 : (2 : Nat) ^ (a + 1) = 2 ^ a + 2 ^ a := by rw [Nat.pow_succ]; omega
  have hp1 : 1 ≤ (2 : Nat) ^ a := Nat.one_le_two_pow
  have hcon : 2 ^ a + 2 ^ a + 1 ≤ 2 ^ (a + 2) := by
    have e2 : (2 : Nat) ^ (a + 2) = 2 ^ (a + 1) + 2 ^ (a + 1) := by rw [Nat.pow_succ]; omega
    omega
  rw [e1]
  refine Rle_trans (Rle_Rneg ?_) (g3Seq_diff_ge_block a (2 ^ a) (2 ^ a) hcon)
  have hmid : 0 < (Qsub (⟨((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2), 2 ^ a + 1⟩ : Q)
      ⟨((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2), 2 ^ a + 2 ^ a + 1⟩).den :=
    Qsub_den_pos (Nat.succ_pos (2 ^ a)) (Nat.succ_pos (2 ^ a + 2 ^ a))
  exact Rle_trans
    (Rle_ofQ_ofQ (Qsub_den_pos (Csum_den_pos _ (2 ^ a + 2 ^ a)) (Csum_den_pos _ (2 ^ a))) hmid
      (Csum_tail_le (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2)) (2 ^ a) (2 ^ a)))
    (Rle_ofQ_ofQ hmid (Nat.pos_pow_of_pos a (by decide))
      (Qsub_block_le (((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2))
        (Int.mul_nonneg (Int.mul_nonneg (by have := Int.ofNat_nonneg a; omega)
          (by have := Int.ofNat_nonneg a; omega)) (by have := Int.ofNat_nonneg a; omega)) (2 ^ a)))



/-- γ₃ reindex `M(j) = 2j+14` (more slack than `γ₂`'s `2j+8`, to dominate the CUBIC lower tail). -/
def gamma3Midx (j : Nat) : Nat := 2 * j + 14

theorem gamma3Midx_mono {j k : Nat} (h : j ≤ k) : gamma3Midx j ≤ gamma3Midx k := by
  simp only [gamma3Midx]; omega

/-- `48k+432 ≤ 2^{k+14}` (upper linear increment). -/
theorem g3_linU (k : Nat) : 48 * k + 432 ≤ 2 ^ (k + 14) := by
  induction k with
  | zero => decide
  | succ m ih =>
      have hp : (2 : Nat) ^ (m + 1 + 14) = 2 ^ (m + 14) * 2 := by
        rw [show m + 1 + 14 = (m + 14) + 1 from by omega, Nat.pow_succ]
      omega

/-- `6(2j+14)²+36(2j+14)+66 ≤ 2^{j+14}` (Q_U at the reindex). -/
theorem g3_quad_lin (j : Nat) :
    6 * (2 * j + 14) * (2 * j + 14) + 36 * (2 * j + 14) + 66 ≤ 2 ^ (j + 14) := by
  induction j with
  | zero => decide
  | succ k ih =>
      have hp : (2 : Nat) ^ (k + 1 + 14) = 2 ^ (k + 14) * 2 := by
        rw [show k + 1 + 14 = (k + 14) + 1 from by omega, Nat.pow_succ]
      have hexp : 6 * (2 * (k + 1) + 14) * (2 * (k + 1) + 14) + 36 * (2 * (k + 1) + 14) + 66
          = (6 * (2 * k + 14) * (2 * k + 14) + 36 * (2 * k + 14) + 66) + (48 * k + 432) := by
        have hi : ((6 * (2 * (k + 1) + 14) * (2 * (k + 1) + 14) + 36 * (2 * (k + 1) + 14) + 66 : Nat) : Int)
            = (((6 * (2 * k + 14) * (2 * k + 14) + 36 * (2 * k + 14) + 66) + (48 * k + 432) : Nat) : Int) := by
          push_cast; ring_uor
        exact_mod_cast hi
      have hlin := g3_linU k
      rw [hp, hexp]; omega

/-- **Reindex domination (upper)** `Q_U(M)·(j+1) ≤ 2^M` for `M = 2j+14`. -/
theorem g3_domination_U (j : Nat) :
    (6 * (2 * j + 14) * (2 * j + 14) + 36 * (2 * j + 14) + 66) * (j + 1) ≤ 2 ^ (2 * j + 14) := by
  have h1 : j + 1 ≤ 2 ^ j := lt_two_pow j
  have h2 := g3_quad_lin j
  have h3 := Nat.mul_le_mul h2 h1
  have h4 : (2 : Nat) ^ (j + 14) * 2 ^ j = 2 ^ (2 * j + 14) := by rw [← Nat.pow_add]; congr 1; omega
  omega

/-- **Upper antiderivative anchor** `T_U(M(j)) ≤ 1/(j+1)`. -/
theorem g3_TU_le (j : Nat) :
    Qle (⟨(6 * gamma3Midx j * gamma3Midx j + 36 * gamma3Midx j + 66 : Int), 2 ^ gamma3Midx j⟩ : Q)
        ⟨1, j + 1⟩ := by
  simp only [Qle, gamma3Midx]; push_cast
  have hcast : (((6 * (2 * j + 14) * (2 * j + 14) + 36 * (2 * j + 14) + 66) * (j + 1) : Nat) : Int)
      ≤ ((2 ^ (2 * j + 14) : Nat) : Int) := by exact_mod_cast g3_domination_U j
  push_cast at hcast; omega

/-- `96k+912 ≤ 2^{k+14}` (lower linear increment). -/
theorem g3_linL (k : Nat) : 96 * k + 912 ≤ 2 ^ (k + 14) := by
  induction k with
  | zero => decide
  | succ m ih =>
      have hp : (2 : Nat) ^ (m + 1 + 14) = 2 ^ (m + 14) * 2 := by
        rw [show m + 1 + 14 = (m + 14) + 1 from by omega, Nat.pow_succ]
      omega

/-- `48k²+864k+3916 ≤ 2^{k+14}` (lower quadratic increment). -/
theorem g3_quadincL (k : Nat) : 48 * k * k + 864 * k + 3916 ≤ 2 ^ (k + 14) := by
  induction k with
  | zero => decide
  | succ m ih =>
      have hp : (2 : Nat) ^ (m + 1 + 14) = 2 ^ (m + 14) * 2 := by
        rw [show m + 1 + 14 = (m + 14) + 1 from by omega, Nat.pow_succ]
      have hexp : 48 * (m + 1) * (m + 1) + 864 * (m + 1) + 3916
          = (48 * m * m + 864 * m + 3916) + (96 * m + 912) := by
        have hi : ((48 * (m + 1) * (m + 1) + 864 * (m + 1) + 3916 : Nat) : Int)
            = (((48 * m * m + 864 * m + 3916) + (96 * m + 912) : Nat) : Int) := by push_cast; ring_uor
        exact_mod_cast hi
      have hlin := g3_linL m
      rw [hp, hexp]; omega

/-- `2(2j+14)³+18(2j+14)²+66(2j+14)+102 ≤ 2^{j+14}` (Q_L at the reindex; cubic). -/
theorem g3_cube_lin (j : Nat) :
    2 * (2 * j + 14) * (2 * j + 14) * (2 * j + 14) + 18 * (2 * j + 14) * (2 * j + 14)
      + 66 * (2 * j + 14) + 102 ≤ 2 ^ (j + 14) := by
  induction j with
  | zero => decide
  | succ k ih =>
      have hp : (2 : Nat) ^ (k + 1 + 14) = 2 ^ (k + 14) * 2 := by
        rw [show k + 1 + 14 = (k + 14) + 1 from by omega, Nat.pow_succ]
      have hexp : 2 * (2 * (k + 1) + 14) * (2 * (k + 1) + 14) * (2 * (k + 1) + 14)
            + 18 * (2 * (k + 1) + 14) * (2 * (k + 1) + 14) + 66 * (2 * (k + 1) + 14) + 102
          = (2 * (2 * k + 14) * (2 * k + 14) * (2 * k + 14) + 18 * (2 * k + 14) * (2 * k + 14)
              + 66 * (2 * k + 14) + 102) + (48 * k * k + 864 * k + 3916) := by
        have hi : ((2 * (2 * (k + 1) + 14) * (2 * (k + 1) + 14) * (2 * (k + 1) + 14)
              + 18 * (2 * (k + 1) + 14) * (2 * (k + 1) + 14) + 66 * (2 * (k + 1) + 14) + 102 : Nat) : Int)
            = (((2 * (2 * k + 14) * (2 * k + 14) * (2 * k + 14) + 18 * (2 * k + 14) * (2 * k + 14)
                + 66 * (2 * k + 14) + 102) + (48 * k * k + 864 * k + 3916) : Nat) : Int) := by
          push_cast; ring_uor
        exact_mod_cast hi
      have hquad := g3_quadincL k
      rw [hp, hexp]; omega

/-- **Reindex domination (lower)** `Q_L(M)·(j+1) ≤ 2^M` for `M = 2j+14`. -/
theorem g3_domination_L (j : Nat) :
    (2 * (2 * j + 14) * (2 * j + 14) * (2 * j + 14) + 18 * (2 * j + 14) * (2 * j + 14)
      + 66 * (2 * j + 14) + 102) * (j + 1) ≤ 2 ^ (2 * j + 14) := by
  have h1 : j + 1 ≤ 2 ^ j := lt_two_pow j
  have h2 := g3_cube_lin j
  have h3 := Nat.mul_le_mul h2 h1
  have h4 : (2 : Nat) ^ (j + 14) * 2 ^ j = 2 ^ (2 * j + 14) := by rw [← Nat.pow_add]; congr 1; omega
  omega

/-- **Lower antiderivative anchor** `T_L(M(j)) ≤ 1/(j+1)`. -/
theorem g3_TL_le (j : Nat) :
    Qle (⟨(2 * gamma3Midx j * gamma3Midx j * gamma3Midx j + 18 * gamma3Midx j * gamma3Midx j
          + 66 * gamma3Midx j + 102 : Int), 2 ^ gamma3Midx j⟩ : Q) ⟨1, j + 1⟩ := by
  simp only [Qle, gamma3Midx]; push_cast
  have hcast : (((2 * (2 * j + 14) * (2 * j + 14) * (2 * j + 14) + 18 * (2 * j + 14) * (2 * j + 14)
        + 66 * (2 * j + 14) + 102) * (j + 1) : Nat) : Int) ≤ ((2 ^ (2 * j + 14) : Nat) : Int) := by
    exact_mod_cast g3_domination_L j
  push_cast at hcast; omega



/-- Outer UPPER sum `Σ_{i<e} 3(A+i+2)²/2^{A+i}`. -/
def WUsum3 (A : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (e + 1) => add (WUsum3 A e) ⟨3 * (((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2)), 2 ^ (A + e)⟩

theorem WUsum3_den_pos (A : Nat) : ∀ e, 0 < (WUsum3 A e).den
  | 0 => Nat.one_pos
  | (e + 1) => add_den_pos (WUsum3_den_pos A e) (Nat.pos_pow_of_pos (A + e) (by decide))

/-- Outer LOWER sum `Σ_{i<e} (A+i+2)³/2^{A+i}`. -/
def WLsum3 (A : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (e + 1) => add (WLsum3 A e)
      ⟨((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2), 2 ^ (A + e)⟩

theorem WLsum3_den_pos (A : Nat) : ∀ e, 0 < (WLsum3 A e).den
  | 0 => Nat.one_pos
  | (e + 1) => add_den_pos (WLsum3_den_pos A e) (Nat.pos_pow_of_pos (A + e) (by decide))

/-- **Outer UPPER bound**: `g₃(2^{A+e}) − g₃(2^A) ≤ WUsum3 A e`. -/
theorem g3Seq_diff_le_outer (A : Nat) : ∀ e,
    Rle (Rsub (g3Seq (2 ^ (A + e))) (g3Seq (2 ^ A))) (ofQ (WUsum3 A e) (WUsum3_den_pos A e)) := by
  intro e
  induction e with
  | zero =>
      apply Rle_of_Req
      refine Req_trans (Radd_neg (g3Seq (2 ^ A))) (Req_symm ?_)
      apply Req_of_seq_Qeq; intro n
      simp only [WUsum3, ofQ, zero, Qeq]
  | succ e ih =>
      have hstepd : 0 < (⟨3 * (((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2)), 2 ^ (A + e)⟩ : Q).den :=
        Nat.pos_pow_of_pos (A + e) (by decide)
      have hgapd : 0 < (WUsum3 A e).den := WUsum3_den_pos A e
      have heq : Req (ofQ (WUsum3 A (e + 1)) (WUsum3_den_pos A (e + 1)))
          (Radd (ofQ (⟨3 * (((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2)), 2 ^ (A + e)⟩ : Q) hstepd)
                (ofQ (WUsum3 A e) hgapd)) :=
        Req_trans (ofQ_congr _ _ (by simp only [WUsum3, Qeq, add]; push_cast <;> try ring_uor))
          (Req_symm (Radd_ofQ_ofQ hstepd hgapd))
      exact Rle_trans
        (Rle_of_Req (Req_symm (Rsub_split (g3Seq (2 ^ (A + e + 1))) (g3Seq (2 ^ (A + e)))
          (g3Seq (2 ^ A)))))
        (Rle_trans (Radd_le_add (g3Seq_block_le (A + e)) ih) (Rle_of_Req (Req_symm heq)))

/-- **Outer LOWER bound**: `g₃(2^{A+e}) − g₃(2^A) ≥ −WLsum3 A e`. -/
theorem g3Seq_diff_ge_outer (A : Nat) : ∀ e,
    Rle (Rneg (ofQ (WLsum3 A e) (WLsum3_den_pos A e))) (Rsub (g3Seq (2 ^ (A + e))) (g3Seq (2 ^ A))) := by
  intro e
  induction e with
  | zero =>
      apply Rle_of_Req
      refine Req_trans ?_ (Req_symm (Radd_neg (g3Seq (2 ^ A))))
      apply Req_of_seq_Qeq; intro n
      simp only [Rneg, WLsum3, ofQ, zero, neg, Qeq]; push_cast
  | succ e ih =>
      have hstepd : 0 < (⟨((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2),
          2 ^ (A + e)⟩ : Q).den := Nat.pos_pow_of_pos (A + e) (by decide)
      have hgapd : 0 < (WLsum3 A e).den := WLsum3_den_pos A e
      have heq : Req (Rneg (ofQ (WLsum3 A (e + 1)) (WLsum3_den_pos A (e + 1))))
          (Radd (Rneg (ofQ (⟨((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2),
                2 ^ (A + e)⟩ : Q) hstepd)) (Rneg (ofQ (WLsum3 A e) hgapd))) :=
        Req_trans (Rneg_congr (Req_trans
          (ofQ_congr _ _ (by simp only [WLsum3, Qeq, add]; push_cast <;> try ring_uor))
          (Req_symm (Radd_ofQ_ofQ hstepd hgapd)))) (Rneg_Radd _ _)
      exact Rle_trans (Rle_of_Req heq)
        (Rle_trans (Radd_le_add (g3Seq_block_ge (A + e)) ih)
          (Rle_of_Req (Rsub_split (g3Seq (2 ^ (A + e + 1))) (g3Seq (2 ^ (A + e))) (g3Seq (2 ^ A)))))

/-- **Upper antiderivative tail** `WUsum3 A e ≤ Q_U(A)/2^A − Q_U(A+e)/2^{A+e}`, `Q_U(m)=6m²+36m+66`. -/
theorem WUsum3_tail_le (A : Nat) : ∀ e,
    Qle (WUsum3 A e)
        (Qsub (⟨(6 * A * A + 36 * A + 66 : Int), 2 ^ A⟩ : Q)
          ⟨(6 * (A + e) * (A + e) + 36 * (A + e) + 66 : Int), 2 ^ (A + e)⟩)
  | 0 => by
      simp only [Nat.add_zero]; apply Qeq_le
      simp only [WUsum3, Qsub, add, neg, Qeq]; push_cast <;> try ring_uor
  | (e + 1) => by
      have hT : 0 < (Qsub (⟨(6 * A * A + 36 * A + 66 : Int), 2 ^ A⟩ : Q)
          ⟨(6 * (A + e) * (A + e) + 36 * (A + e) + 66 : Int), 2 ^ (A + e)⟩).den :=
        Qsub_den_pos (Nat.pos_pow_of_pos A (by decide)) (Nat.pos_pow_of_pos (A + e) (by decide))
      have hS : 0 < (Qsub (⟨(6 * (A + e) * (A + e) + 36 * (A + e) + 66 : Int), 2 ^ (A + e)⟩ : Q)
          ⟨(6 * (A + e + 1) * (A + e + 1) + 36 * (A + e + 1) + 66 : Int), 2 ^ (A + e + 1)⟩).den :=
        Qsub_den_pos (Nat.pos_pow_of_pos (A + e) (by decide)) (Nat.pos_pow_of_pos (A + e + 1) (by decide))
      have h2 : (2 : Nat) ^ (A + e + 1) = 2 * 2 ^ (A + e) := by rw [Nat.pow_succ]; omega
      have hinc : Qeq (⟨3 * (((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2)), 2 ^ (A + e)⟩ : Q)
          (Qsub (⟨(6 * (A + e) * (A + e) + 36 * (A + e) + 66 : Int), 2 ^ (A + e)⟩ : Q)
            ⟨(6 * (A + e + 1) * (A + e + 1) + 36 * (A + e + 1) + 66 : Int), 2 ^ (A + e + 1)⟩) := by
        simp only [h2, Qsub, add, neg, Qeq]; push_cast <;> try ring_uor
      exact Qle_trans (add_den_pos hT hS)
        (Qadd_le_add (WUsum3_tail_le A e) (Qeq_le hinc)) (Qeq_le (Qadd_Qsub_fwd _ _ _))

/-- **Lower antiderivative tail** `WLsum3 A e ≤ Q_L(A)/2^A − Q_L(A+e)/2^{A+e}`,
    `Q_L(m)=2m³+18m²+66m+102` (the cubic discrete antiderivative). -/
theorem WLsum3_tail_le (A : Nat) : ∀ e,
    Qle (WLsum3 A e)
        (Qsub (⟨(2 * A * A * A + 18 * A * A + 66 * A + 102 : Int), 2 ^ A⟩ : Q)
          ⟨(2 * (A + e) * (A + e) * (A + e) + 18 * (A + e) * (A + e) + 66 * (A + e) + 102 : Int),
            2 ^ (A + e)⟩)
  | 0 => by
      simp only [Nat.add_zero]; apply Qeq_le
      simp only [WLsum3, Qsub, add, neg, Qeq]; push_cast <;> try ring_uor
  | (e + 1) => by
      have hT : 0 < (Qsub (⟨(2 * A * A * A + 18 * A * A + 66 * A + 102 : Int), 2 ^ A⟩ : Q)
          ⟨(2 * (A + e) * (A + e) * (A + e) + 18 * (A + e) * (A + e) + 66 * (A + e) + 102 : Int),
            2 ^ (A + e)⟩).den :=
        Qsub_den_pos (Nat.pos_pow_of_pos A (by decide)) (Nat.pos_pow_of_pos (A + e) (by decide))
      have hS : 0 < (Qsub (⟨(2 * (A + e) * (A + e) * (A + e) + 18 * (A + e) * (A + e)
            + 66 * (A + e) + 102 : Int), 2 ^ (A + e)⟩ : Q)
          ⟨(2 * (A + e + 1) * (A + e + 1) * (A + e + 1) + 18 * (A + e + 1) * (A + e + 1)
            + 66 * (A + e + 1) + 102 : Int), 2 ^ (A + e + 1)⟩).den :=
        Qsub_den_pos (Nat.pos_pow_of_pos (A + e) (by decide)) (Nat.pos_pow_of_pos (A + e + 1) (by decide))
      have h2 : (2 : Nat) ^ (A + e + 1) = 2 * 2 ^ (A + e) := by rw [Nat.pow_succ]; omega
      have hinc : Qeq (⟨((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2) * ((↑(A + e) : Int) + 2),
            2 ^ (A + e)⟩ : Q)
          (Qsub (⟨(2 * (A + e) * (A + e) * (A + e) + 18 * (A + e) * (A + e) + 66 * (A + e) + 102 : Int),
              2 ^ (A + e)⟩ : Q)
            ⟨(2 * (A + e + 1) * (A + e + 1) * (A + e + 1) + 18 * (A + e + 1) * (A + e + 1)
              + 66 * (A + e + 1) + 102 : Int), 2 ^ (A + e + 1)⟩) := by
        simp only [h2, Qsub, add, neg, Qeq]; push_cast <;> try ring_uor
      exact Qle_trans (add_den_pos hT hS)
        (Qadd_le_add (WLsum3_tail_le A e) (Qeq_le hinc)) (Qeq_le (Qadd_Qsub_fwd _ _ _))

/-- The reindexed `γ₃` defining sequence `g₃(2^{M(j)})`, `M(j) = 2j+14`. -/
def g3SeqDyadic (j : Nat) : Real := g3Seq (2 ^ gamma3Midx j)

/-- **Pairwise Cauchy (upper)**: for `j ≤ k`, `g3SeqDyadic k − g3SeqDyadic j ≤ 1/(j+1)`. -/
theorem g3_pair_le {j k : Nat} (hjk : j ≤ k) :
    Rle (Rsub (g3SeqDyadic k) (g3SeqDyadic j)) (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  simp only [g3SeqDyadic]
  obtain ⟨e, he⟩ := Nat.le.dest (gamma3Midx_mono hjk)
  rw [← he]
  refine Rle_trans (g3Seq_diff_le_outer (gamma3Midx j) e) ?_
  have hmid : 0 < (Qsub (⟨(6 * gamma3Midx j * gamma3Midx j + 36 * gamma3Midx j + 66 : Int),
        2 ^ gamma3Midx j⟩ : Q)
      ⟨(6 * (gamma3Midx j + e) * (gamma3Midx j + e) + 36 * (gamma3Midx j + e) + 66 : Int),
        2 ^ (gamma3Midx j + e)⟩).den :=
    Qsub_den_pos (Nat.pos_pow_of_pos _ (by decide)) (Nat.pos_pow_of_pos _ (by decide))
  have hmid2 : 0 < (⟨(6 * gamma3Midx j * gamma3Midx j + 36 * gamma3Midx j + 66 : Int),
      2 ^ gamma3Midx j⟩ : Q).den := Nat.pos_pow_of_pos _ (by decide)
  exact Rle_trans (Rle_ofQ_ofQ (WUsum3_den_pos _ _) hmid (WUsum3_tail_le (gamma3Midx j) e))
    (Rle_trans (Rle_ofQ_ofQ hmid hmid2 (Qsub_le_left _ _ (by
        have h : (0 : Int) ≤ (↑(gamma3Midx j) : Int) + (↑e : Int) := by
          have := Int.ofNat_nonneg (gamma3Midx j); have := Int.ofNat_nonneg e; omega
        have h2 := Int.mul_nonneg (Int.mul_nonneg (by decide : (0 : Int) ≤ 6) h) h
        have h3 := Int.mul_nonneg (by decide : (0 : Int) ≤ 36) h
        omega) _ _))
      (Rle_ofQ_ofQ hmid2 (Nat.succ_pos j) (g3_TU_le j)))

/-- **Pairwise Cauchy (lower)**: for `j ≤ k`, `g3SeqDyadic k − g3SeqDyadic j ≥ −1/(j+1)`. -/
theorem g3_pair_ge {j k : Nat} (hjk : j ≤ k) :
    Rle (Rneg (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j))) (Rsub (g3SeqDyadic k) (g3SeqDyadic j)) := by
  simp only [g3SeqDyadic]
  obtain ⟨e, he⟩ := Nat.le.dest (gamma3Midx_mono hjk)
  rw [← he]
  refine Rle_trans (Rle_Rneg ?_) (g3Seq_diff_ge_outer (gamma3Midx j) e)
  have hmid : 0 < (Qsub (⟨(2 * gamma3Midx j * gamma3Midx j * gamma3Midx j
        + 18 * gamma3Midx j * gamma3Midx j + 66 * gamma3Midx j + 102 : Int), 2 ^ gamma3Midx j⟩ : Q)
      ⟨(2 * (gamma3Midx j + e) * (gamma3Midx j + e) * (gamma3Midx j + e)
        + 18 * (gamma3Midx j + e) * (gamma3Midx j + e) + 66 * (gamma3Midx j + e) + 102 : Int),
        2 ^ (gamma3Midx j + e)⟩).den :=
    Qsub_den_pos (Nat.pos_pow_of_pos _ (by decide)) (Nat.pos_pow_of_pos _ (by decide))
  have hmid2 : 0 < (⟨(2 * gamma3Midx j * gamma3Midx j * gamma3Midx j
      + 18 * gamma3Midx j * gamma3Midx j + 66 * gamma3Midx j + 102 : Int), 2 ^ gamma3Midx j⟩ : Q).den :=
    Nat.pos_pow_of_pos _ (by decide)
  exact Rle_trans (Rle_ofQ_ofQ (WLsum3_den_pos _ _) hmid (WLsum3_tail_le (gamma3Midx j) e))
    (Rle_trans (Rle_ofQ_ofQ hmid hmid2 (Qsub_le_left _ _ (by
        have h : (0 : Int) ≤ (↑(gamma3Midx j) : Int) + (↑e : Int) := by
          have := Int.ofNat_nonneg (gamma3Midx j); have := Int.ofNat_nonneg e; omega
        have h2 := Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg (by decide : (0 : Int) ≤ 2) h) h) h
        have h3 := Int.mul_nonneg (Int.mul_nonneg (by decide : (0 : Int) ≤ 18) h) h
        have h4 := Int.mul_nonneg (by decide : (0 : Int) ≤ 66) h
        omega) _ _))
      (Rle_ofQ_ofQ hmid2 (Nat.succ_pos j) (g3_TL_le j)))

/-- **The reindexed `γ₃` sequence is regular** (`RReg`) — the input to Bishop's `Rlim`. -/
theorem g3SeqDyadic_RReg : RReg g3SeqDyadic := by
  refine RReg_of_real_bound _ (fun j k => add ⟨1, j + 1⟩ ⟨1, k + 1⟩)
    (fun j k => add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (fun j k => Qle_refl _) ?_
  intro j k
  rcases Nat.le_total j k with hjk | hkj
  · exact Rle_trans (Rle_of_Req (Req_symm (Rneg_Rsub (g3SeqDyadic k) (g3SeqDyadic j))))
      (Rle_trans (Rle_trans (Rle_Rneg (g3_pair_ge hjk)) (Rle_of_Req (Rneg_neg _)))
        (Rle_ofQ_ofQ (Nat.succ_pos _) (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
          (Qle_self_add (by show (0 : Int) ≤ 1; decide))))
  · exact Rle_trans (g3_pair_le hkj)
      (Rle_ofQ_ofQ (Nat.succ_pos _) (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
        (Qle_trans (b := add ⟨1, k + 1⟩ ⟨1, j + 1⟩)
          (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
          (Qle_self_add (p := ⟨1, j + 1⟩) (by show (0 : Int) ≤ 1; decide))
          (Qeq_le (by simp only [Qeq, add]; push_cast <;> try ring_uor))))

/-- **The third Stieltjes constant `γ₃`**, as a genuine constructive real: the Bishop limit of the
    reindexed defining sequence `g₃(2^{2j+14})`. `γ₃ ≈ +0.00205`. -/
def Rgamma3 : Real := Rlim g3SeqDyadic g3SeqDyadic_RReg


end UOR.Bridge.F1Square.Analysis
