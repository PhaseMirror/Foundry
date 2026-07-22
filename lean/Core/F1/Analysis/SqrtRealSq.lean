/-
F1 square — constructive square root, the defining identity components: the squeeze scaffolding for
`(Rsqrt q)² = q`.

`Rsqrt q` is bracketed by the bisection endpoints `lo_n ↑ √q ↓ hi_n` with `lo² ≤ q ≤ hi²` and width
`→ 0`. The defining identity follows by squeezing `(Rsqrt q)²` and `q` between `lo_n²` and `hi_n²`.
This file builds the order components: `Qle_of_sq_le` (√ monotone on `Q`), the cross-bracket
`lo_a ≤ hi_b`, the telescoping `genSum (sqrtTerm) M ≈ ofQ (lo_M)`, `Rsqrt ≥ 0`, and the upper bracket
`Rsqrt ≤ ofQ (hi_n)`. (The lower bracket — a monotone-limit fact — and the final squeeze are the
remaining step.)

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.SqrtReal
import Core.F1.Analysis.ThetaFunction

namespace UOR.Bridge.F1Square.Analysis

/-- **`√` is monotone on `Q`₊**: `0 ≤ x, 0 ≤ y, x² ≤ y² ⟹ x ≤ y`. Constructive (factor
    `y² − x² = (y−x)(y+x)`, split on the sign of `y+x`). -/
theorem Qle_of_sq_le {x y : Q} (hx : 0 ≤ x.num) (hy : 0 ≤ y.num)
    (h : Qle (mul x x) (mul y y)) : Qle x y := by
  simp only [Qle, mul] at h ⊢
  push_cast at h
  have hxd : (0 : Int) ≤ (x.den : Int) := Int.ofNat_nonneg _
  have hyd : (0 : Int) ≤ (y.den : Int) := Int.ofNat_nonneg _
  have hna : 0 ≤ x.num * (y.den : Int) := Int.mul_nonneg hx hyd
  have hnb : 0 ≤ y.num * (x.den : Int) := Int.mul_nonneg hy hxd
  have hsq : (x.num * (y.den : Int)) * (x.num * (y.den : Int))
      ≤ (y.num * (x.den : Int)) * (y.num * (x.den : Int)) := by
    have e1 : (x.num * (y.den : Int)) * (x.num * (y.den : Int))
        = x.num * x.num * ((y.den : Int) * (y.den : Int)) := by ring_uor
    have e2 : (y.num * (x.den : Int)) * (y.num * (x.den : Int))
        = y.num * y.num * ((x.den : Int) * (x.den : Int)) := by ring_uor
    rw [e1, e2]; exact h
  have hprod : (0 : Int) ≤ ((y.num * (x.den : Int)) - (x.num * (y.den : Int)))
      * ((y.num * (x.den : Int)) + (x.num * (y.den : Int))) := by
    have e : ((y.num * (x.den : Int)) - (x.num * (y.den : Int)))
          * ((y.num * (x.den : Int)) + (x.num * (y.den : Int)))
        = (y.num * (x.den : Int)) * (y.num * (x.den : Int))
          - (x.num * (y.den : Int)) * (x.num * (y.den : Int)) := by ring_uor
    rw [e]; omega
  rcases Int.lt_trichotomy 0 ((y.num * (x.den : Int)) + (x.num * (y.den : Int))) with hlt | heq | hgt
  · have hh : (0 : Int) * ((y.num * (x.den : Int)) + (x.num * (y.den : Int)))
        ≤ ((y.num * (x.den : Int)) - (x.num * (y.den : Int)))
          * ((y.num * (x.den : Int)) + (x.num * (y.den : Int))) := by simpa using hprod
    have hcancel := Int.le_of_mul_le_mul_right hh hlt
    omega
  · omega
  · omega

/-- `0 ≤ x.num` from `0/1 ≤ x`. -/
private theorem qnum_nonneg_of_le {x : Q} (h : Qle (⟨0, 1⟩ : Q) x) : 0 ≤ x.num := by
  simp only [Qle] at h; omega

/-- **Cross-bracket**: every lower endpoint is below every upper endpoint, `lo_a ≤ hi_b` (both
    bracket `√q`, via `Qle_of_sq_le` on `lo_a² ≤ q ≤ hi_b²`). -/
theorem sqLo_le_sqHi_cross (q : Q) (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) (a b : Nat) :
    Qle (sqLo q a) (sqHi q b) := by
  obtain ⟨hloa, _, _, hposa⟩ := sqrtBisect_inv q hqd hq a
  obtain ⟨_, hhib, hleb, hposb⟩ := sqrtBisect_inv q hqd hq b
  have hlonn : 0 ≤ (sqLo q a).num := qnum_nonneg_of_le hposa
  have hhinn : 0 ≤ (sqHi q b).num :=
    qnum_nonneg_of_le (Qle_trans (sqrtBisect_den_pos q hqd b).1 hposb hleb)
  exact Qle_of_sq_le hlonn hhinn (Qle_trans hqd hloa hhib)

/-- **Telescoping**: `Σ_{k<M} Δ_k ≈ lo_M` (the increments sum to the lower endpoint, `lo_0 = 0`). -/
theorem genSum_sqrtTerm_eq (q : Q) (hqd : 0 < q.den) : ∀ M,
    Req (genSum (sqrtTerm q hqd) M) (ofQ (sqLo q M) (sqrtBisect_den_pos q hqd M).1)
  | 0 => Req_symm (Req_of_seq_Qeq (fun _ => Qeq_refl _))
  | (M + 1) => by
    refine Req_trans (Radd_congr (genSum_sqrtTerm_eq q hqd M) (Req_refl _)) ?_
    refine Req_trans (Radd_ofQ_ofQ (sqrtBisect_den_pos q hqd M).1
      (Qsub_den_pos (sqrtBisect_den_pos q hqd (M + 1)).1 (sqrtBisect_den_pos q hqd M).1)) ?_
    exact ofQ_congr _ (sqrtBisect_den_pos q hqd (M + 1)).1
      (by simp only [Qeq, add, Qsub, neg]; push_cast; ring_uor)

/-- Each increment is non-negative. -/
private theorem sqrtTerm_nonneg (q : Q) (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) (k : Nat) :
    Rnonneg (sqrtTerm q hqd k) :=
  Rnonneg_ofQ _ (by have h := Qsub_nonneg_of_le (sqLo_mono q hqd hq k); simp only [Qle] at h; omega)

/-- **`Rsqrt q ≥ 0`** (limit of non-negative partial sums). -/
theorem Rsqrt_nonneg (q : Q) (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) :
    Rnonneg (Rsqrt q hqd hq) :=
  Rnonneg_Rlim_seq _ (fun j => genSum_nonneg (fun k => sqrtTerm_nonneg q hqd hq k)
    (digammaMidx (sqrtK q) j))

/-- **Upper bracket**: `Rsqrt q ≤ hi_n` for every `n` (the limit of the `lo`'s, each `≤ hi_n` by the
    cross-bracket). -/
theorem Rsqrt_le_sqHi (q : Q) (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) (n : Nat) :
    Rle (Rsqrt q hqd hq) (ofQ (sqHi q n) (sqrtBisect_den_pos q hqd n).2) :=
  Rlim_le_ofQ _ (sqrtBisect_den_pos q hqd n).2 (fun j =>
    Rle_trans (Rle_of_Req (genSum_sqrtTerm_eq q hqd (digammaMidx (sqrtK q) j)))
      (Rle_ofQ_ofQ (sqrtBisect_den_pos q hqd (digammaMidx (sqrtK q) j)).1
        (sqrtBisect_den_pos q hqd n).2
        (sqLo_le_sqHi_cross q hqd hq (digammaMidx (sqrtK q) j) n)))

-- ===========================================================================
-- The lower bracket (monotone-limit) and squaring-monotonicity.
-- ===========================================================================

/-- One-sided ε-collapse (real order): `a − b ≤ C/(k+1)` for all `k` ⟹ `a ≤ b`. -/
theorem Rle_of_Rsub_le_eps {a b : Real} {C : Nat}
    (h : ∀ k, Rle (Rsub a b) (ofQ (⟨(C : Int), k + 1⟩ : Q) (Nat.succ_pos k))) : Rle a b := by
  intro n
  have hsub : Qle (Qsub (a.seq n) (b.seq n)) (⟨2, n + 1⟩ : Q) := by
    apply Qarch_gen (C := C) (Qsub_den_pos (a.den_pos n) (b.den_pos n)) (Nat.succ_pos n)
    intro k
    exact Qle_trans (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
      (seq_diff_le a b (⟨(C : Int), k + 1⟩ : Q) (Nat.succ_pos k) (h k) n)
      (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))
  have h2 : Qeq (a.seq n) (add (b.seq n) (Qsub (a.seq n) (b.seq n))) := by
    simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  exact Qle_congr_left (add_den_pos (b.den_pos n) (Qsub_den_pos (a.den_pos n) (b.den_pos n)))
    (Qeq_symm h2) (Qadd_le_add (Qle_refl _) hsub)

/-- From convergence, the difference `X m − L` is `≤ 2/(m+1)` (the upper rate; `Rsub` reindexes both
    terms together so no regularity slack is incurred). -/
theorem RTendsTo_Rsub_le {X : Nat → Real} {L : Real} (h : RTendsTo X L) (m : Nat) :
    Rle (Rsub (X m) L) (ofQ (⟨2, m + 1⟩ : Q) (Nat.succ_pos m)) := by
  intro n
  show Qle (add ((X m).seq (2 * n + 1)) (neg (L.seq (2 * n + 1))))
        (add (⟨2, m + 1⟩ : Q) (⟨2, n + 1⟩ : Q))
  refine Qle_trans (Qabs_den_pos (Qsub_den_pos ((X m).den_pos _) (L.den_pos _)))
    (Qle_self_Qabs (Qsub ((X m).seq (2 * n + 1)) (L.seq (2 * n + 1)))) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (h m (2 * n + 1)) ?_
  exact Qadd_le_add (Qle_refl _)
    (by show Qle (⟨2, (2 * n + 1) + 1⟩ : Q) (⟨2, n + 1⟩ : Q); simp only [Qle]; push_cast; omega)

/-- **A monotone sequence sits below its limit**: `X j ≤ lim X` (the lower-bracket engine). -/
theorem term_le_Rlim {X : Nat → Real} (hX : RReg X)
    (hmono : ∀ i j, i ≤ j → Rle (X i) (X j)) (J : Nat) : Rle (X J) (Rlim X hX) := by
  refine Rle_of_Rsub_le_eps (C := 2) (fun k => ?_)
  refine Rle_trans (Radd_le_add (hmono J (J + k) (Nat.le_add_right J k))
    (Rle_refl (Rneg (Rlim X hX)))) ?_
  refine Rle_trans (RTendsTo_Rsub_le (Rlim_tendsTo X hX) (J + k)) ?_
  exact Rle_ofQ_ofQ (Nat.succ_pos _) (Nat.succ_pos k) (by simp only [Qle]; push_cast; omega)

/-- Partial sums of non-negative terms are monotone in the upper limit. -/
theorem genSum_mono {T : Nat → Real} (hT : ∀ n, Rnonneg (T n)) (M : Nat) :
    ∀ d, Rle (genSum T M) (genSum T (M + d))
  | 0 => Rle_refl _
  | (d + 1) => by
    refine Rle_trans (genSum_mono hT M d) ?_
    refine Rle_trans (Rle_of_Req (Req_symm (Radd_zero (genSum T (M + d))))) ?_
    exact Radd_le_add (Rle_refl _) (Rle_zero_of_Rnonneg (hT (M + d)))

/-- The lower endpoints are monotone: `a ≤ b ⟹ lo_a ≤ lo_b`. -/
theorem sqLo_mono_le (q : Q) (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) (a : Nat) :
    ∀ d, Qle (sqLo q a) (sqLo q (a + d))
  | 0 => Qle_refl _
  | (d + 1) => Qle_trans (sqrtBisect_den_pos q hqd (a + d)).1
      (sqLo_mono_le q hqd hq a d) (sqLo_mono q hqd hq (a + d))

/-- **Lower bracket**: `lo_m ≤ Rsqrt q` for every `m` (monotone-limit). -/
theorem Rsqrt_ge_sqLo (q : Q) (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) (m : Nat) :
    Rle (ofQ (sqLo q m) (sqrtBisect_den_pos q hqd m).1) (Rsqrt q hqd hq) := by
  have hmidx : m ≤ digammaMidx (sqrtK q) m := by
    have : m + 1 ≤ digammaMidx (sqrtK q) m := by
      have h1 : 1 ≤ (sqrtK q).num.toNat + 1 := Nat.le_add_left 1 _
      calc m + 1 = 1 * (m + 1) := by omega
        _ ≤ ((sqrtK q).num.toNat + 1) * (m + 1) := Nat.mul_le_mul_right _ h1
    omega
  have hmono : ∀ i j, i ≤ j → Rle (genSum (sqrtTerm q hqd) (digammaMidx (sqrtK q) i))
      (genSum (sqrtTerm q hqd) (digammaMidx (sqrtK q) j)) := by
    intro i j hij
    obtain ⟨d, hd⟩ : ∃ d, digammaMidx (sqrtK q) j = digammaMidx (sqrtK q) i + d :=
      ⟨_, (Nat.add_sub_cancel' (digammaMidx_mono (sqrtK q) hij)).symm⟩
    rw [hd]
    exact genSum_mono (fun k => sqrtTerm_nonneg q hqd hq k) (digammaMidx (sqrtK q) i) d
  refine Rle_trans (Rle_ofQ_ofQ (sqrtBisect_den_pos q hqd m).1
    (sqrtBisect_den_pos q hqd (digammaMidx (sqrtK q) m)).1
    (by have := sqLo_mono_le q hqd hq m (digammaMidx (sqrtK q) m - m)
        rwa [Nat.add_sub_cancel' hmidx] at this)) ?_
  exact Rle_trans (Rle_of_Req (Req_symm (genSum_sqrtTerm_eq q hqd (digammaMidx (sqrtK q) m))))
    (term_le_Rlim _ hmono m)

/-- **Squaring is monotone on non-negatives**: `0 ≤ a ≤ b ⟹ a² ≤ b²`. -/
theorem Rsq_mono {a b : Real} (ha : Rnonneg a) (hb : Rnonneg b) (h : Rle a b) :
    Rle (Rmul a a) (Rmul b b) :=
  Rle_trans (Rmul_le_Rmul_left ha h) (Rmul_le_Rmul_right hb h)

-- ===========================================================================
-- The defining identity (Rsqrt q)² = q, by squeezing both sides into [lo², hi²].
-- ===========================================================================

/-- `Rsub` is monotone (increasing in the minuend, decreasing in the subtrahend). -/
theorem Rsub_le_mono {a a' c c' : Real} (ha : Rle a a') (hc : Rle c' c) :
    Rle (Rsub a c) (Rsub a' c') := Radd_le_add ha (Rle_Rneg hc)

/-- The upper endpoints decrease: `hi_{m+1} ≤ hi_m`. -/
theorem sqHi_mono (q : Q) (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) (m : Nat) :
    Qle (sqHi q (m + 1)) (sqHi q m) := by
  obtain ⟨_, _, hle, _⟩ := sqrtBisect_inv q hqd hq m
  obtain ⟨_, hh⟩ := sqrtBisect_den_pos q hqd m
  simp only [sqLo, sqHi, sqrtBisect]
  split
  · exact Qle_refl _
  · exact Qavg_le_right hh hle

/-- `hi_n ≤ q+1` (the upper endpoint never exceeds the initial bracket top). -/
theorem sqHi_le_init (q : Q) (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) (n : Nat) :
    Qle (sqHi q n) (add q (⟨1, 1⟩ : Q)) := by
  have key : ∀ d, Qle (sqHi q (0 + d)) (sqHi q 0) := by
    intro d
    induction d with
    | zero => exact Qle_refl _
    | succ d ih => exact Qle_trans (sqrtBisect_den_pos q hqd (0 + d)).2 (sqHi_mono q hqd hq (0 + d)) ih
  have := key n
  rwa [Nat.zero_add] at this

/-- `0 ≤ (sqHi q n).num`. -/
private theorem sqHi_num_nonneg (q : Q) (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) (n : Nat) :
    0 ≤ (sqHi q n).num := by
  obtain ⟨_, _, hle, hpos⟩ := sqrtBisect_inv q hqd hq n
  exact qnum_nonneg_of_le (Qle_trans (sqrtBisect_den_pos q hqd n).1 hpos hle)

/-- The squared-width numerator constant `C = 2(q.num+q.den)²` is non-negative. -/
private theorem sqK_nonneg (q : Q) (hq : Qle (⟨0, 1⟩ : Q) q) :
    0 ≤ 2 * (q.num + (q.den : Int)) * (q.num + (q.den : Int)) := by
  have hqn : 0 ≤ q.num := by have := hq; simp only [Qle] at this; simpa using this
  have ha : 0 ≤ q.num + (q.den : Int) := by have := Int.ofNat_nonneg q.den; omega
  exact Int.mul_nonneg (Int.mul_nonneg (by decide) ha) ha

/-- **The squared bracket width vanishes**: `hi_k² − lo_k² ≤ C/(k+1)`, `C = 2(q.num+q.den)²`. -/
theorem sqrt_sq_width_le (q : Q) (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) (k : Nat) :
    Qle (Qsub (mul (sqHi q k) (sqHi q k)) (mul (sqLo q k) (sqLo q k)))
        (⟨((2 * (q.num + q.den) * (q.num + q.den)).toNat : Int), k + 1⟩ : Q) := by
  obtain ⟨_, _, hle, _⟩ := sqrtBisect_inv q hqd hq k
  obtain ⟨hl, hh⟩ := sqrtBisect_den_pos q hqd k
  have hqn : 0 ≤ q.num := by have := hq; simp only [Qle] at this; simpa using this
  have ha : 0 ≤ q.num + (q.den : Int) := by have := Int.ofNat_nonneg q.den; omega
  have hM0 := sqK_nonneg q hq
  have hwnn : 0 ≤ (Qsub (sqHi q k) (sqLo q k)).num := by
    have := Qsub_nonneg_of_le hle; simp only [Qle] at this; omega
  have hsqnn : ∀ a : Int, 0 ≤ a * a := by
    intro a
    rcases Int.le_total 0 a with h | h
    · exact Int.mul_nonneg h h
    · have e : (-a) * (-a) = a * a := by ring_uor
      have h2 : 0 ≤ (-a) * (-a) := Int.mul_nonneg (by omega) (by omega)
      omega
  have hAn : 0 ≤ (add q (⟨1, 1⟩ : Q)).num := by simp only [add]; push_cast; omega
  have hAnn : 0 ≤ (mul (⟨2, 1⟩ : Q) (mul (add q (⟨1, 1⟩ : Q)) (add q (⟨1, 1⟩ : Q)))).num :=
    Int.mul_nonneg (by decide) (hsqnn _)
  have hc2 : 0 ≤ (add (add q (⟨1, 1⟩ : Q)) (add q (⟨1, 1⟩ : Q))).num :=
    Int.add_nonneg (Int.mul_nonneg hAn (Int.ofNat_nonneg _))
      (Int.mul_nonneg hAn (Int.ofNat_nonneg _))
  have hCeq : ((2 * (q.num + q.den) * (q.num + q.den)).toNat : Int)
      = 2 * (q.num + (q.den : Int)) * (q.num + (q.den : Int)) := by have := hM0; omega
  -- denominators for the chain
  have dW : 0 < (Qsub (sqHi q k) (sqLo q k)).den := Qsub_den_pos hh hl
  have dHL : 0 < (add (sqHi q k) (sqLo q k)).den := add_den_pos hh hl
  have d2q : 0 < (add (add q (⟨1, 1⟩ : Q)) (add q (⟨1, 1⟩ : Q))).den :=
    add_den_pos (add_den_pos hqd (by decide)) (add_den_pos hqd (by decide))
  have dwid : 0 < (mul (add q (⟨1, 1⟩ : Q)) (⟨1, 2 ^ k⟩ : Q)).den :=
    Qmul_den_pos (add_den_pos hqd (by decide)) Nat.one_le_two_pow
  have dsq : 0 < (mul (⟨2, 1⟩ : Q) (mul (add q (⟨1, 1⟩ : Q)) (add q (⟨1, 1⟩ : Q)))).den :=
    Qmul_den_pos (by decide) (Qmul_den_pos (add_den_pos hqd (by decide)) (add_den_pos hqd (by decide)))
  -- the identities
  have hA : Qeq (Qsub (mul (sqHi q k) (sqHi q k)) (mul (sqLo q k) (sqLo q k)))
      (mul (Qsub (sqHi q k) (sqLo q k)) (add (sqHi q k) (sqLo q k))) := by
    simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor
  have hB : Qle (add (sqHi q k) (sqLo q k)) (add (add q (⟨1, 1⟩ : Q)) (add q (⟨1, 1⟩ : Q))) :=
    Qadd_le_add (sqHi_le_init q hqd hq k)
      (Qle_trans (sqrtBisect_den_pos q hqd k).2 hle (sqHi_le_init q hqd hq k))
  have hwidth := sqrtBisect_width q hqd k
  have hre : Qeq (mul (mul (add q (⟨1, 1⟩ : Q)) (⟨1, 2 ^ k⟩ : Q))
                  (add (add q (⟨1, 1⟩ : Q)) (add q (⟨1, 1⟩ : Q))))
      (mul (mul (⟨2, 1⟩ : Q) (mul (add q (⟨1, 1⟩ : Q)) (add q (⟨1, 1⟩ : Q)))) (⟨1, 2 ^ k⟩ : Q)) := by
    simp only [Qeq, mul, add]; push_cast; ring_uor
  have h2k : Qle (⟨1, 2 ^ k⟩ : Q) (⟨1, k + 1⟩ : Q) := by
    have henv : k + 1 ≤ 2 ^ k := Nat.lt_two_pow_self
    simp only [Qle]; omega
  have hd2 : (1 : Int) ≤ (q.den : Int) * (q.den : Int) := by
    have h1 : (1 : Int) ≤ (q.den : Int) := by exact_mod_cast hqd
    calc (1 : Int) = 1 * 1 := by omega
      _ ≤ (q.den : Int) * (q.den : Int) := Int.mul_le_mul h1 h1 (by omega) (by omega)
  have hfin : Qle (mul (mul (⟨2, 1⟩ : Q) (mul (add q (⟨1, 1⟩ : Q)) (add q (⟨1, 1⟩ : Q))))
                  (⟨1, k + 1⟩ : Q))
      (⟨((2 * (q.num + q.den) * (q.num + q.den)).toNat : Int), k + 1⟩ : Q) := by
    refine Qle_congr_left
      (a := (⟨2 * (q.num + (q.den : Int)) * (q.num + (q.den : Int)),
              (q.den * q.den) * (k + 1)⟩ : Q))
      (Nat.mul_pos (Nat.mul_pos hqd hqd) (Nat.succ_pos k))
      (by simp only [Qeq, mul, add]; push_cast; ring_uor) ?_
    show (2 * (q.num + (q.den : Int)) * (q.num + (q.den : Int))) * ((k + 1 : Nat) : Int)
      ≤ ((2 * (q.num + q.den) * (q.num + q.den)).toNat : Int)
        * (((q.den * q.den) * (k + 1) : Nat) : Int)
    rw [hCeq]; push_cast
    have hkstep : ((k : Int) + 1) ≤ ((q.den : Int) * (q.den : Int)) * ((k : Int) + 1) := by
      have hnn : 0 ≤ ((q.den : Int) * (q.den : Int) - 1) * ((k : Int) + 1) :=
        Int.mul_nonneg (by omega) (by omega)
      have he : ((q.den : Int) * (q.den : Int) - 1) * ((k : Int) + 1)
          = ((q.den : Int) * (q.den : Int)) * ((k : Int) + 1) - ((k : Int) + 1) := by ring_uor
      omega
    exact Int.mul_le_mul_of_nonneg_left hkstep hM0
  -- assemble the chain
  refine Qle_trans (Qmul_den_pos dW dHL) (Qeq_le hA) ?_
  refine Qle_trans (Qmul_den_pos dW d2q) (Qmul_le_mul_left hwnn hB) ?_
  refine Qle_trans (Qmul_den_pos dwid d2q) (Qmul_le_mul_right hc2 (Qeq_le hwidth)) ?_
  refine Qle_trans (Qmul_den_pos dsq Nat.one_le_two_pow) (Qeq_le hre) ?_
  exact Qle_trans (Qmul_den_pos dsq (Nat.succ_pos k)) (Qmul_le_mul_left hAnn h2k) hfin

/-- **The defining identity** `(Rsqrt q)² = q`. Both `(Rsqrt q)²` and `q` lie in `[lo_k², hi_k²]`,
    whose width vanishes (`sqrt_sq_width_le`); the real-level squeeze (`Req_of_Rle_ofQ_all`) closes.
    The constructive square root is now complete: `√q` exists and `(√q)² = q`. -/
theorem Rsqrt_sq (q : Q) (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) :
    Req (Rmul (Rsqrt q hqd hq) (Rsqrt q hqd hq)) (ofQ q hqd) := by
  refine Req_of_Rle_ofQ_all (C := (2 * (q.num + q.den) * (q.num + q.den)).toNat)
    (fun k => ?_) (fun k => ?_)
  · have hupper : Rle (Rmul (Rsqrt q hqd hq) (Rsqrt q hqd hq))
        (ofQ (mul (sqHi q k) (sqHi q k)) (Qmul_den_pos (sqrtBisect_den_pos q hqd k).2
          (sqrtBisect_den_pos q hqd k).2)) :=
      Rle_trans (Rsq_mono (Rsqrt_nonneg q hqd hq) (Rnonneg_ofQ _ (sqHi_num_nonneg q hqd hq k))
          (Rsqrt_le_sqHi q hqd hq k))
        (Rle_of_Req (Rmul_ofQ_ofQ (sqrtBisect_den_pos q hqd k).2 (sqrtBisect_den_pos q hqd k).2))
    have hqge : Rle (ofQ (mul (sqLo q k) (sqLo q k)) (Qmul_den_pos (sqrtBisect_den_pos q hqd k).1
        (sqrtBisect_den_pos q hqd k).1)) (ofQ q hqd) :=
      Rle_ofQ_ofQ _ hqd (sqrtBisect_inv q hqd hq k).1
    refine Rle_trans (Rsub_le_mono hupper hqge)
      (Rle_trans (Rle_of_Req (Rsub_ofQ_ofQ _ _)) (Rle_ofQ_ofQ _ (Nat.succ_pos k) ?_))
    exact sqrt_sq_width_le q hqd hq k
  · have hlonn : 0 ≤ (sqLo q k).num := qnum_nonneg_of_le (sqrtBisect_inv q hqd hq k).2.2.2
    have hlower : Rle (ofQ (mul (sqLo q k) (sqLo q k)) (Qmul_den_pos (sqrtBisect_den_pos q hqd k).1
        (sqrtBisect_den_pos q hqd k).1)) (Rmul (Rsqrt q hqd hq) (Rsqrt q hqd hq)) :=
      Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (sqrtBisect_den_pos q hqd k).1
        (sqrtBisect_den_pos q hqd k).1)))
        (Rsq_mono (Rnonneg_ofQ _ hlonn) (Rsqrt_nonneg q hqd hq) (Rsqrt_ge_sqLo q hqd hq k))
    have hqle : Rle (ofQ q hqd) (ofQ (mul (sqHi q k) (sqHi q k))
        (Qmul_den_pos (sqrtBisect_den_pos q hqd k).2 (sqrtBisect_den_pos q hqd k).2)) :=
      Rle_ofQ_ofQ hqd _ (sqrtBisect_inv q hqd hq k).2.1
    refine Rle_trans (Rsub_le_mono hqle hlower)
      (Rle_trans (Rle_of_Req (Rsub_ofQ_ofQ _ _)) (Rle_ofQ_ofQ _ (Nat.succ_pos k) ?_))
    exact sqrt_sq_width_le q hqd hq k

end UOR.Bridge.F1Square.Analysis
