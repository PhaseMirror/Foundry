/-
F1 square — **the `∫ log` layer, part 2a: the band clamp** (`BandClamp.lean`). The `log`
integrand `t ↦ log(c+t)` enters the certified gateway through `RlogPos`, whose Lipschitz and
congruence lemmas (`Rlog_abs_lipschitz_gen`, `RlogPos_congr`) are stated SEQ-WISE: they
consume per-index facts `0 < seqₙ.num`, `1 ≤ seqₙ`, `seqₙ ≤ B`. This file supplies the
totalizer that manufactures exactly those facts for an arbitrary real argument: the
per-index rational BAND clamp

    `qBandQ a b x`  with  `seqₙ = min(b, max(xₙ, a))`

— total, regular (both `Qmax` and the new `Qmin` are `1`-Lipschitz in their variable
argument), per-index inside `[a, b]` by construction, `1`-Lipschitz at the `Real` level,
`≈`-congruent, inert on the band (`a ≤ x ≤ b` pointwise ⟹ `qBandQ a b x ≈ x`), and with a
UNIFORM positivity witness (no data extracted from `x`) when `a ≥ 1` — the same design as
`qClampQ` (`ClampedInv.lean`), extended to a two-sided band. The ceiling is the new
half: `Qmin` and its suite mirror `RQmaxClamp.lean`'s `Qmax`, and `qCapQ b x`
(`seqₙ = min(xₙ, b)`) mirrors `qClampQ`; the band is the composition
`qBandQ a b x = qCapQ b (qClampQ a x)`.

HONEST SCOPE. Substrate for `riemannIntegral_logC` (part 2b) and the `W(t4)` campaign; no
integral, no positivity claim. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.ClampedInv

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- `Qmin` and its suite (the ceiling mirror of `RQmaxClamp`'s `Qmax`).
-- ===========================================================================

/-- Rational min via decidable `Qle`. -/
def Qmin (a b : Q) : Q := if Qle a b then a else b

theorem Qmin_eq_left {a b : Q} (h : Qle a b) : Qmin a b = a := if_pos h
theorem Qmin_eq_right {a b : Q} (h : ¬ Qle a b) : Qmin a b = b := if_neg h

theorem Qmin_den_pos {a b : Q} (ha : 0 < a.den) (hb : 0 < b.den) : 0 < (Qmin a b).den := by
  by_cases h : Qle a b
  · rw [Qmin_eq_left h]; exact ha
  · rw [Qmin_eq_right h]; exact hb

/-- `min a b ≤ a`. -/
theorem Qmin_le_left (a b : Q) : Qle (Qmin a b) a := by
  by_cases h : Qle a b
  · rw [Qmin_eq_left h]; exact Qle_refl a
  · rw [Qmin_eq_right h]
    rcases Qle_or_Qlt a b with h' | h'
    · exact absurd h' h
    · exact (by unfold Qle Qlt at *; omega : Qle b a)

/-- `min a b ≤ b`. -/
theorem Qmin_le_right (a b : Q) : Qle (Qmin a b) b := by
  by_cases h : Qle a b
  · rw [Qmin_eq_left h]; exact h
  · rw [Qmin_eq_right h]; exact Qle_refl b

/-- `c ≤ min a b` from `c ≤ a`, `c ≤ b`. -/
theorem Qle_Qmin {a b c : Q} (ha : Qle c a) (hb : Qle c b) : Qle c (Qmin a b) := by
  by_cases h : Qle a b
  · rw [Qmin_eq_left h]; exact ha
  · rw [Qmin_eq_right h]; exact hb

/-- `a ≤ b ⟹ −b ≤ −a` (local copy — the `RQmaxClamp` original is private). -/
private theorem bnd_neg_le {a b : Q} (h : Qle a b) : Qle (neg b) (neg a) := by
  unfold Qle neg at *; simp only [Int.neg_mul]; omega

/-- `|a − b| = |b − a|` (local structural copy). -/
private theorem bnd_abs_comm (a b : Q) : Qabs (Qsub a b) = Qabs (Qsub b a) := by
  unfold Qabs Qsub add neg
  congr 1
  · congr 1
    rw [show a.num * (b.den : Int) + -b.num * (a.den : Int)
          = -(b.num * (a.den : Int) + -a.num * (b.den : Int)) from by ring_uor, Int.natAbs_neg]
  · exact Nat.mul_comm a.den b.den

/-- Subtraction monotone (local copy). -/
private theorem bnd_sub_le {a a' b b' : Q} (ha : Qle a a') (hb : Qle b' b) :
    Qle (Qsub a b) (Qsub a' b') := Qadd_le_add ha (bnd_neg_le hb)

/-- The asymmetric Lipschitz step `min a c − min b c ≤ |a − b|` (cases on both guards). -/
private theorem qmin_lem (a b c : Q) (had : 0 < a.den) (hbd : 0 < b.den) (hcd : 0 < c.den) :
    Qle (Qsub (Qmin a c) (Qmin b c)) (Qabs (Qsub a b)) := by
  by_cases h : Qle a c
  · rw [Qmin_eq_left h]
    by_cases hb : Qle b c
    · rw [Qmin_eq_left hb]
      exact Qle_self_Qabs (Qsub a b)
    · rw [Qmin_eq_right hb]
      exact Qle_trans (Qsub_den_pos hcd hcd) (bnd_sub_le h (Qle_refl c))
        (Qsub_self_le_Qabs c (Qsub a b))
  · rw [Qmin_eq_right h]
    have hca : Qle c a := by
      rcases Qle_or_Qlt a c with h' | h'
      · exact absurd h' h
      · exact (by unfold Qle Qlt at *; omega : Qle c a)
    by_cases hb : Qle b c
    · rw [Qmin_eq_left hb]
      exact Qle_trans (Qsub_den_pos had hbd) (bnd_sub_le hca (Qle_refl b))
        (Qle_self_Qabs (Qsub a b))
    · rw [Qmin_eq_right hb]
      exact Qsub_self_le_Qabs c (Qsub a b)

/-- **`Qmin` is `1`-Lipschitz in the first argument**: `|min a c − min b c| ≤ |a − b|`. -/
theorem Qmin_const_lip (a b c : Q) (had : 0 < a.den) (hbd : 0 < b.den) (hcd : 0 < c.den) :
    Qle (Qabs (Qsub (Qmin a c) (Qmin b c))) (Qabs (Qsub a b)) := by
  refine Qabs_le_of_both (qmin_lem a b c had hbd hcd) ?_
  have key : Qle (Qsub (Qmin b c) (Qmin a c)) (Qabs (Qsub a b)) := by
    rw [bnd_abs_comm a b]; exact qmin_lem b a c hbd had hcd
  refine Qle_congr_left (Qsub_den_pos (Qmin_den_pos hbd hcd) (Qmin_den_pos had hcd)) ?_ key
  show (Qsub (Qmin b c) (Qmin a c)).num * ((neg (Qsub (Qmin a c) (Qmin b c))).den : Int)
      = (neg (Qsub (Qmin a c) (Qmin b c))).num * ((Qsub (Qmin b c) (Qmin a c)).den : Int)
  simp only [Qsub, add, neg]; push_cast; ring_uor

-- ===========================================================================
-- The per-index ceiling `qCapQ` (mirror of `qClampQ`).
-- ===========================================================================

/-- **The per-index rational ceiling at `b`**: `seqₙ = min(xₙ, b)` — `≤ b` at every index by
    construction, regular because `Qmin` is `1`-Lipschitz in its first argument. -/
def qCapQ (b : Q) (hbd : 0 < b.den) (x : Real) : Real where
  seq := fun n => Qmin (x.seq n) b
  reg := by
    intro m n
    exact Qle_trans
      (Qabs_den_pos (Qsub_den_pos (x.den_pos m) (x.den_pos n)))
      (Qmin_const_lip (x.seq m) (x.seq n) b (x.den_pos m) (x.den_pos n) hbd)
      (x.reg m n)
  den_pos := fun n => Qmin_den_pos (x.den_pos n) hbd

/-- The ceiling is `≤ b` per index — by construction. -/
theorem qCapQ_le (b : Q) (hbd : 0 < b.den) (x : Real) (n : Nat) :
    Qle ((qCapQ b hbd x).seq n) b :=
  Qmin_le_right (x.seq n) b

/-- The ceiling preserves per-index lower bounds: `a ≤ xₙ` and `a ≤ b` give
    `a ≤ min(xₙ, b)`. -/
theorem qCapQ_ge (b : Q) (hbd : 0 < b.den) (x : Real) {a : Q}
    (hax : ∀ n, Qle a (x.seq n)) (hab : Qle a b) (n : Nat) :
    Qle a ((qCapQ b hbd x).seq n) :=
  Qle_Qmin (hax n) hab

/-- The ceiling respects `≈`. -/
theorem qCapQ_congr (b : Q) (hbd : 0 < b.den) {x y : Real} (h : Req x y) :
    Req (qCapQ b hbd x) (qCapQ b hbd y) := by
  intro n
  exact Qle_trans (Qabs_den_pos (Qsub_den_pos (x.den_pos n) (y.den_pos n)))
    (Qmin_const_lip (x.seq n) (y.seq n) b (x.den_pos n) (y.den_pos n) hbd)
    (h n)

/-- **The ceiling is `1`-Lipschitz** at the `Real` level. -/
theorem qCapQ_lipschitz (b : Q) (hbd : 0 < b.den) (x y : Real) :
    Rle (Rabs (Rsub (qCapQ b hbd x) (qCapQ b hbd y))) (Rabs (Rsub x y)) := by
  intro n
  show Qle (Qabs (Qsub (Qmin (x.seq (2 * n + 1)) b) (Qmin (y.seq (2 * n + 1)) b)))
      (add (Qabs (Qsub (x.seq (2 * n + 1)) (y.seq (2 * n + 1)))) (⟨2, n + 1⟩ : Q))
  exact Qle_trans (Qabs_den_pos (Qsub_den_pos (x.den_pos _) (y.den_pos _)))
    (Qmin_const_lip (x.seq (2 * n + 1)) (y.seq (2 * n + 1)) b
      (x.den_pos _) (y.den_pos _) hbd)
    (Qle_self_add (by show (0 : Int) ≤ 2; decide))

/-- `|y| ≤ c` from `0 ≤ y.num` and `y ≤ c` (local copy). -/
private theorem bnd_abs_le_of_nonneg {y c : Q} (hy : 0 ≤ y.num) (h : Qle y c) :
    Qle (Qabs y) c := by
  show (↑y.num.natAbs : Int) * (c.den : Int) ≤ c.num * (y.den : Int)
  rw [Int.natAbs_of_nonneg hy]; exact h

/-- **The ceiling is inert on `(−∞, b]`**: where `x ≤ b` (Real-level), `qCapQ b x ≈ x`. -/
theorem qCapQ_eq_of_le {b : Q} {hbd : 0 < b.den} {x : Real}
    (hx : Rle x (ofQ b hbd)) : Req (qCapQ b hbd x) x := by
  refine Req_of_lin_bound (C := 2) ?_
  intro n
  show Qle (Qabs (Qsub (Qmin (x.seq n) b) (x.seq n))) (⟨(2 : Int), n + 1⟩ : Q)
  have hxn : Qle (x.seq n) (add b (⟨2, n + 1⟩ : Q)) := hx n
  by_cases h : Qle (x.seq n) b
  · rw [Qmin_eq_left h]
    have h0 : (Qsub (x.seq n) (x.seq n)).num = 0 := by simp only [Qsub, add, neg]; ring_uor
    refine bnd_abs_le_of_nonneg (by rw [h0]; exact Int.le_refl 0) ?_
    show (Qsub (x.seq n) (x.seq n)).num * ((n + 1 : Nat) : Int)
        ≤ (2 : Int) * ((Qsub (x.seq n) (x.seq n)).den : Int)
    rw [h0]; simp only [Int.zero_mul]
    exact Int.mul_nonneg (by omega) (Int.ofNat_nonneg _)
  · rw [Qmin_eq_right h]
    -- `b < xₙ ≤ b + 2/(n+1)`: the defect `|b − xₙ| = xₙ − b ≤ 2/(n+1)`… as `neg` form
    have hbx : Qle b (x.seq n) := by
      rcases Qle_or_Qlt (x.seq n) b with h' | h'
      · exact absurd h' h
      · exact (by unfold Qle Qlt at *; omega : Qle b (x.seq n))
    refine Qle_congr_left (Qabs_den_pos (Qsub_den_pos (x.den_pos n) hbd)) ?_ ?_
    · show (Qabs (Qsub (x.seq n) b)).num * ((Qabs (Qsub b (x.seq n))).den : Int)
        = (Qabs (Qsub b (x.seq n))).num * ((Qabs (Qsub (x.seq n) b)).den : Int)
      rw [bnd_abs_comm (x.seq n) b]
    · refine bnd_abs_le_of_nonneg ?_ (Qsub_le_of_le_add hbd (Nat.succ_pos n) hxn)
      have hh := hbx; simp only [Qle] at hh
      simp only [Qsub, add, neg]; push_cast at hh ⊢
      have hneg : -b.num * ((x.seq n).den : Int) = -(b.num * ((x.seq n).den : Int)) :=
        Int.neg_mul _ _
      omega

-- ===========================================================================
-- The band `qBandQ a b = qCapQ b ∘ qClampQ a`, with its seq-wise facts.
-- ===========================================================================

/-- **The band clamp**: `qBandQ a b x` has `seqₙ = min(b, max(xₙ, a))` — per-index inside
    `[a, b]`, total, `1`-Lipschitz, congruent, inert on the band. -/
def qBandQ (a b : Q) (had : 0 < a.den) (hbd : 0 < b.den) (x : Real) : Real :=
  qCapQ b hbd (qClampQ a had x)

/-- The band value is `≥ a` per index (needs `a ≤ b`). -/
theorem qBandQ_ge (a b : Q) (had : 0 < a.den) (hbd : 0 < b.den) (hab : Qle a b)
    (x : Real) (n : Nat) : Qle a ((qBandQ a b had hbd x).seq n) :=
  qCapQ_ge b hbd (qClampQ a had x) (fun m => qClampQ_ge a had x m) hab n

/-- The band value is `≤ b` per index. -/
theorem qBandQ_le (a b : Q) (had : 0 < a.den) (hbd : 0 < b.den) (x : Real) (n : Nat) :
    Qle ((qBandQ a b had hbd x).seq n) b :=
  qCapQ_le b hbd (qClampQ a had x) n

/-- The band value has positive numerator per index, at the unit floor (the instance
    the `log` integrand consumes). -/
theorem qBandQ_one_num_pos (b : Q) (hbd : 0 < b.den) (h1b : Qle (⟨1, 1⟩ : Q) b)
    (x : Real) (n : Nat) : 0 < ((qBandQ ⟨1, 1⟩ b (by decide) hbd x).seq n).num := by
  have h := qBandQ_ge ⟨1, 1⟩ b (by decide) hbd h1b x n
  have hd := (qBandQ ⟨1, 1⟩ b (by decide) hbd x).den_pos n
  simp only [Qle] at h; push_cast at h; omega

/-- **The uniform positivity witness** (no data extracted from `x`): at index `2·a.den`
    the band value exceeds `Qbound (2·a.den)`, for every `x` (needs `a ≤ b`). -/
theorem qBandQ_witness (a b : Q) (han : 0 < a.num) (had : 0 < a.den) (hbd : 0 < b.den)
    (hab : Qle a b) (x : Real) :
    Qlt (Qbound (2 * a.den)) ((qBandQ a b had hbd x).seq (2 * a.den)) :=
  Qlt_of_Qlt_Qle had ((qBandQ a b had hbd x).den_pos (2 * a.den))
    (Qbound_lt_pos han had) (qBandQ_ge a b had hbd hab x (2 * a.den))

/-- The band respects `≈`. -/
theorem qBandQ_congr (a b : Q) (had : 0 < a.den) (hbd : 0 < b.den) {x y : Real}
    (h : Req x y) : Req (qBandQ a b had hbd x) (qBandQ a b had hbd y) :=
  qCapQ_congr b hbd (qClampQ_congr a had h)

/-- **The band is `1`-Lipschitz** at the `Real` level. -/
theorem qBandQ_lipschitz (a b : Q) (had : 0 < a.den) (hbd : 0 < b.den) (x y : Real) :
    Rle (Rabs (Rsub (qBandQ a b had hbd x) (qBandQ a b had hbd y))) (Rabs (Rsub x y)) :=
  Rle_trans (qCapQ_lipschitz b hbd (qClampQ a had x) (qClampQ a had y))
    (qClampQ_lipschitz a had x y)

/-- **The band is inert on `[a, b]`**: where `a ≤ x ≤ b` (Real-level),
    `qBandQ a b x ≈ x`. -/
theorem qBandQ_eq_of_band {a b : Q} {had : 0 < a.den} {hbd : 0 < b.den} {x : Real}
    (hax : Rle (ofQ a had) x) (hxb : Rle x (ofQ b hbd)) :
    Req (qBandQ a b had hbd x) x := by
  have hclamp : Req (qClampQ a had x) x := qClampQ_eq_of_ge hax
  refine Req_trans (qCapQ_congr b hbd hclamp) ?_
  exact qCapQ_eq_of_le hxb

end Multiplicity.UOR.Bridge.F1Square.Analysis
