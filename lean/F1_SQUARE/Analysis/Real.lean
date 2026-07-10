/-
F1 square — the second analysis brick: constructive ℝ as Bishop regular sequences over our exact ℚ
(the v0.3.0 continuation of the analysis roadmap).

Per the standing directive, the analytic substrate is built from first principles the UOR way. Brick
one was exact ℚ (`Analysis.Rat`); this is brick two: the real numbers as **regular sequences of
rationals** (Bishop), the constructive encoding that bakes the modulus of convergence into the data
so no choice principle is needed:

  a sequence `x : ℕ → ℚ` is *regular* iff `|xₘ − xₙ| ≤ 1/(m+1) + 1/(n+1)` for all `m, n`.

The index *is* the modulus. A real number is a regular sequence; equality is the (undecidable, but
Prop-valued) Bishop relation `x ≈ y  ⟺  |xₙ − yₙ| ≤ 2/(n+1) ∀ n`; positivity is the witnessed
`∃ n, xₙ > 1/(n+1)`. This is the standard no-Mathlib encoding (cf. Bishop–Bridges; the Agda
constructive-analysis development arXiv:2205.08354).

Scope (v0.4.0 — ℝ as an ordered additive group): on top of the v0.3.0 type/setoid, this release adds
**ℝ arithmetic with full regularity proofs** — negation `Rneg` and the (reindexed) Bishop addition
`Radd` — built on the new ℚ ordered-field library (`Analysis.QOrder`) and the from-scratch `ring_uor`
tactic. The `Real` structure now also carries `den_pos` (every term has a positive denominator), which
the order arguments need. Multiplication, `≈`-transitivity (a genuine limiting/Archimedean argument),
ℂ = ℝ×ℝ, and the transcendentals are the v0.5.0 continuation. None of this is the crux: making ζ/λₙ
exact-bounded objects is statable here; proving `λₙ ≥ 0 ∀n` is RH.

Pure Lean 4, no Mathlib, no `sorry`.
-/

import F1Square.Analysis.QOrder

namespace UOR.Bridge.F1Square.Analysis

/-- The modulus rational `1/(n+1) > 0` — both the regularity bound and the positivity threshold. -/
def Qbound (n : Nat) : Q := ⟨1, n + 1⟩

/-- The modulus rational has a positive denominator. -/
theorem Qbound_den_pos (k : Nat) : 0 < (Qbound k).den := Nat.succ_pos k

/-- The numerator of `a − a` is `0` (exact cancellation; via the additive structure). -/
theorem Qsub_self_num (a : Q) : (Qsub a a).num = 0 := by
  simp only [Qsub, add, neg]; rw [Int.neg_mul]; omega

/-- `b − a` has the negated numerator of `a − b`. -/
theorem Qsub_swap_num (a b : Q) : (Qsub b a).num = -(Qsub a b).num := by
  simp only [Qsub, add, neg]; rw [Int.neg_mul, Int.neg_mul]; omega

/-- `b − a` and `a − b` share a denominator (it is `dₐ·d_b` either way). -/
theorem Qsub_swap_den (a b : Q) : (Qsub b a).den = (Qsub a b).den := by
  simp only [Qsub, add, neg]; exact Nat.mul_comm b.den a.den

/-- **Regularity** (Bishop): `|xₘ − xₙ| ≤ 1/(m+1) + 1/(n+1)` for all `m, n`. -/
def IsRegular (x : Nat → Q) : Prop :=
  ∀ m n : Nat, Qle (Qabs (Qsub (x m) (x n))) (add (Qbound m) (Qbound n))

/-- A **constructive real number**: a regular sequence of rationals, every term with a positive
    denominator (so the ℚ order/equality cross-multiplications behave). -/
structure Real where
  seq : Nat → Q
  reg : IsRegular seq
  den_pos : ∀ n, 0 < (seq n).den

/-- The constant sequence at `q` is regular (its gaps are `0 ≤` a positive bound). -/
theorem const_regular (q : Q) : IsRegular (fun _ => q) := by
  intro m n
  unfold Qle Qabs
  rw [Qsub_self_num]
  simp only [Int.natAbs_zero, Int.ofNat_zero, Int.zero_mul]
  -- 0 ≤ (1/(m+1) + 1/(n+1)).num · (denominator)
  have hden : (0 : Int) ≤ ((Qsub q q).den : Int) := Int.ofNat_nonneg _
  have hnum : (0 : Int) ≤ (add (Qbound m) (Qbound n)).num := by
    simp only [add, Qbound]; omega
  exact Int.mul_nonneg hnum hden

/-- The canonical embedding ℚ ↪ ℝ as the constant sequence (needs a positive denominator). -/
def ofQ (q : Q) (hq : 0 < q.den) : Real := ⟨fun _ => q, const_regular q, fun _ => hq⟩

/-- Zero and one in ℝ. -/
def zero : Real := ofQ ⟨0, 1⟩ (by decide)
def one : Real := ofQ ⟨1, 1⟩ (by decide)

/-- **Bishop equality** on ℝ: `x ≈ y ⟺ |xₙ − yₙ| ≤ 2/(n+1)` for all `n`. -/
def Req (x y : Real) : Prop :=
  ∀ n : Nat, Qle (Qabs (Qsub (x.seq n) (y.seq n))) ⟨2, n + 1⟩

/-- `≈` is reflexive. -/
theorem Req_refl (x : Real) : Req x x := by
  intro n
  unfold Qle Qabs
  rw [Qsub_self_num]
  simp only [Int.natAbs_zero, Int.ofNat_zero, Int.zero_mul]
  have hden : (0 : Int) ≤ ((Qsub (x.seq n) (x.seq n)).den : Int) := Int.ofNat_nonneg _
  omega

/-- `≈` is symmetric (`|xₙ − yₙ| = |yₙ − xₙ|`). -/
theorem Req_symm {x y : Real} (h : Req x y) : Req y x := by
  intro n
  have hnum := Qsub_swap_num (x.seq n) (y.seq n)
  have hden := Qsub_swap_den (x.seq n) (y.seq n)
  have hx := h n
  unfold Qle Qabs at hx ⊢
  rw [hnum, Int.natAbs_neg, hden]
  exact hx

/-- `≈` is transitive — the genuine limiting argument. For each index `n`, the gap `|xₙ − zₙ|` is
    bounded, *for every auxiliary index `m`*, by `2/(n+1) + 6/(m+1)` (four triangle steps through
    `xₘ, yₘ, zₘ` plus the regularity/equality bounds); the Archimedean lemma then kills the `6/(m+1)`
    tail. Together with `Req_refl`/`Req_symm`, Bishop equality on ℝ is an equivalence relation. -/
theorem Req_trans {x y z : Real} (hxy : Req x y) (hyz : Req y z) : Req x z := by
  intro n
  apply Qarch (Qabs_den_pos (Qsub_den_pos (x.den_pos n) (z.den_pos n))) (Nat.succ_pos n)
  intro m
  have hxn := x.den_pos n; have hxm := x.den_pos m
  have hym := y.den_pos m; have hzm := z.den_pos m; have hzn := z.den_pos n
  have h2m : 0 < (⟨2, m + 1⟩ : Q).den := Nat.succ_pos m
  -- three triangle steps: |xₙ−zₙ| ≤ |xₙ−zₘ|+|zₘ−zₙ| ≤ |xₙ−yₘ|+|yₘ−zₘ|+… ≤ |xₙ−xₘ|+|xₘ−yₘ|+…
  have h1 := Qabs_sub_triangle (a := x.seq n) (b := z.seq m) (c := z.seq n) hxn hzm hzn
  have h2 := Qabs_sub_triangle (a := x.seq n) (b := y.seq m) (c := z.seq m) hxn hym hzm
  have h3 := Qabs_sub_triangle (a := x.seq n) (b := x.seq m) (c := y.seq m) hxn hxm hym
  -- the four pieces' bounds
  have c3 := Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos hxn hxm))
      (Qabs_den_pos (Qsub_den_pos hxm hym))) h3 (Qadd_le_add (x.reg n m) (hxy m))
  have c2 := Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos hxn hym))
      (Qabs_den_pos (Qsub_den_pos hym hzm))) h2 (Qadd_le_add c3 (hyz m))
  have c1 := Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos hxn hzm))
      (Qabs_den_pos (Qsub_den_pos hzm hzn))) h1 (Qadd_le_add c2 (z.reg m n))
  -- the assembled bound equals 2/(n+1) + 6/(m+1)
  have hfin : Qle (add (add (add (add (Qbound n) (Qbound m)) ⟨2, m + 1⟩) ⟨2, m + 1⟩)
                      (add (Qbound m) (Qbound n))) (add ⟨2, n + 1⟩ ⟨6, m + 1⟩) := by
    apply Qeq_le; simp only [Qeq, add, Qbound]; push_cast; ring_uor
  exact Qle_trans (add_den_pos (add_den_pos (add_den_pos (add_den_pos
      (Qbound_den_pos n) (Qbound_den_pos m)) h2m) h2m) (add_den_pos (Qbound_den_pos m)
      (Qbound_den_pos n))) c1 hfin

/-- The embedding respects ℚ value-equality: `q = r` (as rationals) ⟹ `ofQ q ≈ ofQ r`. -/
theorem ofQ_respects {q r : Q} (hq : 0 < q.den) (hr : 0 < r.den) (h : Qeq q r) :
    Req (ofQ q hq) (ofQ r hr) := by
  intro n
  unfold Qle Qabs ofQ
  simp only
  -- |q − r| = 0 since q = r (value), so ≤ 2/(n+1)
  have h0 : (Qsub q r).num = 0 := by
    simp only [Qsub, add, neg]; rw [Int.neg_mul]
    have := h; unfold Qeq at this; omega
  rw [h0]
  simp only [Int.natAbs_zero, Int.ofNat_zero, Int.zero_mul]
  have hden : (0 : Int) ≤ ((Qsub q r).den : Int) := Int.ofNat_nonneg _
  omega

/-- **Positivity** (Bishop): `x > 0 ⟺ ∃ n, xₙ > 1/(n+1)`. -/
def Pos (x : Real) : Prop := ∃ n : Nat, Qlt (Qbound n) (x.seq n)

/-- `1/2`, as a constructive real. -/
def half : Real := ofQ ⟨1, 2⟩ (by decide)

/-- `half` is positive — witnessed at `n = 2` (`1/3 < 1/2`). -/
theorem Pos_half : Pos half := ⟨2, by decide⟩

-- ===========================================================================
-- v0.4.0 — ℝ arithmetic with regularity proofs (ℝ as an ordered additive group).
-- ===========================================================================

/-- `|(−a) − (−b)| = |a − b|` exactly, as rationals (numerator negated, denominator preserved). -/
theorem Qabs_Qsub_neg (a b : Q) : Qabs (Qsub (neg a) (neg b)) = Qabs (Qsub a b) := by
  simp only [Qabs, Qsub, add, neg]
  congr 1
  have e : (-a.num) * (b.den : Int) + (- -b.num) * (a.den : Int)
      = -(a.num * (b.den : Int) + (-b.num) * (a.den : Int)) := by ring_uor
  rw [e, Int.natAbs_neg]

/-- **Negation** of a constructive real: `(−x)ₙ := −(xₙ)`. Regular, since negation is an isometry. -/
def Rneg (x : Real) : Real where
  seq := fun n => neg (x.seq n)
  reg := by
    intro m n
    rw [Qabs_Qsub_neg]
    exact x.reg m n
  den_pos := fun n => neg_den_pos (x.den_pos n)

/-- **Addition** of constructive reals (Bishop): `(x ⊕ y)ₙ := x₍₂ₙ₊₁₎ + y₍₂ₙ₊₁₎`. The factor-2
    reindexing is exactly what restores regularity (`2·1/(2k+2) = 1/(k+1)`). -/
def Radd (x y : Real) : Real where
  seq := fun n => add (x.seq (2 * n + 1)) (y.seq (2 * n + 1))
  reg := by
    intro m n
    have hxm := x.den_pos (2 * m + 1); have hxn := x.den_pos (2 * n + 1)
    have hym := y.den_pos (2 * m + 1); have hyn := y.den_pos (2 * n + 1)
    -- triangle: split the difference of sums coordinatewise
    have htri := Qabs_sub_add4 (a := x.seq (2 * m + 1)) (b := y.seq (2 * m + 1))
        (c := x.seq (2 * n + 1)) (d := y.seq (2 * n + 1)) hxm hym hxn hyn
    -- each coordinate ≤ its regularity bound; sum them monotonically
    have hsum := Qadd_le_add (x.reg (2 * m + 1) (2 * n + 1)) (y.reg (2 * m + 1) (2 * n + 1))
    -- the doubled bound equals 1/(m+1) + 1/(n+1)
    have hbound : Qle (add (add (Qbound (2 * m + 1)) (Qbound (2 * n + 1)))
                          (add (Qbound (2 * m + 1)) (Qbound (2 * n + 1)))) (add (Qbound m) (Qbound n)) := by
      apply Qeq_le; simp only [Qeq, add, Qbound]; push_cast; ring_uor
    have hpos1 : 0 < (add (Qabs (Qsub (x.seq (2 * m + 1)) (x.seq (2 * n + 1))))
                        (Qabs (Qsub (y.seq (2 * m + 1)) (y.seq (2 * n + 1))))).den :=
      add_den_pos (Qabs_den_pos (Qsub_den_pos hxm hxn)) (Qabs_den_pos (Qsub_den_pos hym hyn))
    have hpos2 : 0 < (add (add (Qbound (2 * m + 1)) (Qbound (2 * n + 1)))
                        (add (Qbound (2 * m + 1)) (Qbound (2 * n + 1)))).den :=
      add_den_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
        (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
    exact Qle_trans hpos2 (Qle_trans hpos1 htri hsum) hbound
  den_pos := fun n => add_den_pos (x.den_pos (2 * n + 1)) (y.den_pos (2 * n + 1))

/-- `Rneg` is an involution on the underlying sequences (`−(−x) = x` pointwise in value). -/
theorem Rneg_Rneg_seq (x : Real) (n : Nat) : ((Rneg (Rneg x)).seq n).num = (x.seq n).num := by
  simp only [Rneg, neg]; omega

/-- Two reals are `≈` if their sequences agree in ℚ-value pointwise (the gap is exactly `0`). The
    workhorse for the pointwise additive-group laws below. -/
theorem Req_of_seq_Qeq {x y : Real} (h : ∀ n, Qeq (x.seq n) (y.seq n)) : Req x y := by
  intro n
  unfold Qle Qabs
  have h0 : (Qsub (x.seq n) (y.seq n)).num = 0 := by
    simp only [Qsub, add, neg]; rw [Int.neg_mul]; have := h n; unfold Qeq at this; omega
  rw [h0]
  simp only [Int.natAbs_zero, Int.ofNat_zero, Int.zero_mul]
  have hden : (0 : Int) ≤ ((Qsub (x.seq n) (y.seq n)).den : Int) := Int.ofNat_nonneg _
  omega

/-- A uniform integer bound on a regular sequence: `K_x := |x₀.num| + 2·x₀.den`, with `|xₙ| ≤ K_x`
    for all `n` (the canonical Bishop bound `|xₙ| ≤ |x₀| + 2`, cleared of denominators). -/
def xBound (x : Real) : Nat := (x.seq 0).num.natAbs + 2 * (x.seq 0).den

/-- The canonical bound holds at every index: `|xₙ| ≤ K_x`. -/
theorem canon_bound (x : Real) (n : Nat) : Qle (Qabs (x.seq n)) ⟨xBound x, 1⟩ := by
  have h0 := x.den_pos 0
  have t1 := Qabs_le_add (a := x.seq 0) (b := x.seq n) h0 (x.den_pos n)
  have hreg : Qle (Qabs (Qsub (x.seq n) (x.seq 0))) ⟨2, 1⟩ := by
    have hb : Qle (add (Qbound n) (Qbound 0)) ⟨2, 1⟩ := by
      simp only [Qle, add, Qbound]; push_cast; omega
    exact Qle_trans (add_den_pos (Qbound_den_pos n) (Qbound_den_pos 0)) (x.reg n 0) hb
  have t2 : Qle (add (Qabs (x.seq 0)) (Qabs (Qsub (x.seq n) (x.seq 0))))
                (add (Qabs (x.seq 0)) ⟨2, 1⟩) := Qadd_le_add (Qle_refl _) hreg
  have t3 : Qle (add (Qabs (x.seq 0)) ⟨2, 1⟩) ⟨xBound x, 1⟩ := by
    simp only [Qle, add, Qabs, xBound]; push_cast
    have hL : (0 : Int) ≤ ((x.seq 0).num.natAbs : Int) + 2 * ((x.seq 0).den : Int) := by omega
    have hD : (1 : Int) ≤ ((x.seq 0).den : Int) := by omega
    simpa using Int.mul_le_mul_of_nonneg_left hD hL
  exact Qle_trans
    (add_den_pos (Qabs_den_pos h0) (Qabs_den_pos (Qsub_den_pos (x.den_pos n) h0))) t1
    (Qle_trans (add_den_pos (Qabs_den_pos h0) Nat.one_pos) t2 t3)

/-- The common multiplication bound `K = max(K_x, K_y)`. -/
def RmulK (x y : Real) : Nat := max (xBound x) (xBound y)

/-- The canonical bound is positive. -/
theorem xBound_pos (x : Real) : 0 < xBound x := by
  unfold xBound; have := x.den_pos 0; omega

/-- `K = max(K_x, K_y)` is positive. -/
theorem RmulK_pos (x y : Real) : 0 < RmulK x y := by
  unfold RmulK; have := xBound_pos x; omega

/-- The multiplication reindex `r(n) = 2K(n+1) − 1`, chosen so that `r(n)+1 = 2K(n+1)`. -/
def Ridx (x y : Real) (n : Nat) : Nat := 2 * RmulK x y * (n + 1) - 1

/-- The defining property of the reindex: `r(n) + 1 = 2K(n+1)` (the `−1` is undone since `2K(n+1) ≥ 1`). -/
theorem Ridx_succ (x y : Real) (n : Nat) : Ridx x y n + 1 = 2 * RmulK x y * (n + 1) := by
  unfold Ridx
  have h : 0 < 2 * RmulK x y * (n + 1) :=
    Nat.mul_pos (Nat.mul_pos (by omega) (RmulK_pos x y)) (Nat.succ_pos n)
  omega

/-- **Multiplication** of constructive reals (Bishop): reindex both factors at `r(n) = 2K(n+1)−1`
    (with `K` bounding both `|xₙ|` and `|yₙ|`) and multiply. Regular because each factor is `≤ K` and
    the `2K` reindexing cancels it: `2K·(1/(2K(m+1)) + 1/(2K(n+1))) = 1/(m+1) + 1/(n+1)`. -/
def Rmul (x y : Real) : Real where
  seq := fun n => mul (x.seq (Ridx x y n)) (y.seq (Ridx x y n))
  reg := by
    intro m n
    have bxK : ∀ k, Qle (Qabs (x.seq k)) ⟨RmulK x y, 1⟩ := fun k =>
      Qle_trans Nat.one_pos (canon_bound x k)
        (by simp only [Qle, RmulK]; push_cast; omega)
    have byK : ∀ k, Qle (Qabs (y.seq k)) ⟨RmulK x y, 1⟩ := fun k =>
      Qle_trans Nat.one_pos (canon_bound y k)
        (by simp only [Qle, RmulK]; push_cast; omega)
    have hdiff := Qabs_mul_diff (xa := x.seq (Ridx x y m)) (ya := y.seq (Ridx x y m))
      (xb := x.seq (Ridx x y n)) (yb := y.seq (Ridx x y n))
      (x.den_pos _) (y.den_pos _) (x.den_pos _) (y.den_pos _)
    have t1 := Qmul_le_mul (a := Qabs (x.seq (Ridx x y m))) (b := ⟨RmulK x y, 1⟩)
      (c := Qabs (Qsub (y.seq (Ridx x y m)) (y.seq (Ridx x y n))))
      (d := add (Qbound (Ridx x y m)) (Qbound (Ridx x y n)))
      (Qabs_den_pos (x.den_pos _)) Nat.one_pos
      (Qabs_den_pos (Qsub_den_pos (y.den_pos _) (y.den_pos _)))
      (Qabs_num_nonneg _) (Qabs_num_nonneg _) (bxK _) (y.reg _ _)
    have t2 := Qmul_le_mul (a := Qabs (y.seq (Ridx x y n))) (b := ⟨RmulK x y, 1⟩)
      (c := Qabs (Qsub (x.seq (Ridx x y m)) (x.seq (Ridx x y n))))
      (d := add (Qbound (Ridx x y m)) (Qbound (Ridx x y n)))
      (Qabs_den_pos (y.den_pos _)) Nat.one_pos
      (Qabs_den_pos (Qsub_den_pos (x.den_pos _) (x.den_pos _)))
      (Qabs_num_nonneg _) (Qabs_num_nonneg _) (byK _) (x.reg _ _)
    have hsum := Qadd_le_add t1 t2
    have hbid : Qle (add (mul ⟨RmulK x y, 1⟩ (add (Qbound (Ridx x y m)) (Qbound (Ridx x y n))))
                         (mul ⟨RmulK x y, 1⟩ (add (Qbound (Ridx x y m)) (Qbound (Ridx x y n)))))
                    (add (Qbound m) (Qbound n)) := by
      apply Qeq_le
      simp only [Qeq, add, mul, Qbound]
      rw [Ridx_succ x y m, Ridx_succ x y n]
      push_cast
      ring_uor
    refine Qle_trans ?_ hdiff (Qle_trans ?_ hsum hbid)
    · exact add_den_pos
        (Qmul_den_pos (Qabs_den_pos (x.den_pos _))
          (Qabs_den_pos (Qsub_den_pos (y.den_pos _) (y.den_pos _))))
        (Qmul_den_pos (Qabs_den_pos (y.den_pos _))
          (Qabs_den_pos (Qsub_den_pos (x.den_pos _) (x.den_pos _))))
    · exact add_den_pos
        (Qmul_den_pos Nat.one_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)))
        (Qmul_den_pos Nat.one_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)))
  den_pos := fun n => Qmul_den_pos (x.den_pos _) (y.den_pos _)

/-- ℝ addition is commutative (up to `≈`): the summands commute coordinatewise in ℚ. -/
theorem Radd_comm (x y : Real) : Req (Radd x y) (Radd y x) :=
  Req_of_seq_Qeq (fun _ => add_comm _ _)

/-- The additive inverse law on ℝ (up to `≈`): `x ⊕ (−x) ≈ 0`. -/
theorem Radd_neg (x : Real) : Req (Radd x (Rneg x)) zero :=
  Req_of_seq_Qeq (fun _ => add_neg _)

/-- ℝ subtraction. -/
def Rsub (x y : Real) : Real := Radd x (Rneg y)

/-- The multiplication bound is symmetric (`max` is). -/
theorem RmulK_comm (x y : Real) : RmulK x y = RmulK y x := by unfold RmulK; omega

/-- The multiplication reindex is symmetric. -/
theorem Ridx_comm (x y : Real) (n : Nat) : Ridx x y n = Ridx y x n := by
  unfold Ridx; rw [RmulK_comm]

/-- ℝ multiplication is commutative (up to `≈`): the factors commute coordinatewise in ℚ (and the
    reindex is symmetric because `K = max(K_x,K_y)` is). -/
theorem Rmul_comm (x y : Real) : Req (Rmul x y) (Rmul y x) := by
  apply Req_of_seq_Qeq
  intro n
  simp only [Rmul]
  rw [Ridx_comm x y n]
  exact mul_comm _ _

-- ===========================================================================
-- v0.5.0 — operation-congruence over `≈` (so the operations are well-defined on the setoid, the
-- prerequisite for the ℂ ring laws). Negation and addition; multiplication-congruence is v0.6.0.
-- ===========================================================================

/-- Negation respects `≈` (it is an isometry, same index — no reindexing). -/
theorem Rneg_congr {x x' : Real} (h : Req x x') : Req (Rneg x) (Rneg x') := by
  intro n
  rw [show Qabs (Qsub ((Rneg x).seq n) ((Rneg x').seq n))
        = Qabs (Qsub (x.seq n) (x'.seq n)) from Qabs_Qsub_neg _ _]
  exact h n

/-- Addition respects `≈`: `x ≈ x', y ≈ y' ⟹ x ⊕ y ≈ x' ⊕ y'`. (Same `2n+1` reindex on both
    sides; the gap splits coordinatewise and `2/(2n+2) + 2/(2n+2) = 2/(n+1)`.) -/
theorem Radd_congr {x x' y y' : Real} (hx : Req x x') (hy : Req y y') :
    Req (Radd x y) (Radd x' y') := by
  intro n
  have hxn := x.den_pos (2 * n + 1); have hxn' := x'.den_pos (2 * n + 1)
  have hyn := y.den_pos (2 * n + 1); have hyn' := y'.den_pos (2 * n + 1)
  have htri := Qabs_sub_add4 (a := x.seq (2 * n + 1)) (b := y.seq (2 * n + 1))
      (c := x'.seq (2 * n + 1)) (d := y'.seq (2 * n + 1)) hxn hyn hxn' hyn'
  have hsum := Qadd_le_add (hx (2 * n + 1)) (hy (2 * n + 1))
  have hbound : Qle (add ⟨2, 2 * n + 1 + 1⟩ ⟨2, 2 * n + 1 + 1⟩) ⟨2, n + 1⟩ := by
    apply Qeq_le; simp only [Qeq, add]; push_cast; ring_uor
  refine Qle_trans ?_ htri (Qle_trans ?_ hsum hbound)
  · exact add_den_pos (Qabs_den_pos (Qsub_den_pos hxn hxn'))
      (Qabs_den_pos (Qsub_den_pos hyn hyn'))
  · exact add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)

/-- Subtraction respects `≈`. -/
theorem Rsub_congr {x x' y y' : Real} (hx : Req x x') (hy : Req y y') :
    Req (Rsub x y) (Rsub x' y') := Radd_congr hx (Rneg_congr hy)

-- ===========================================================================
-- v0.6.0 — the well-definedness engine and the ℝ/ℂ ring laws.
--
-- The reindex used by `Rmul` is tuned to make the *product* regular; it is NOT the same on two
-- `≈`-equal inputs, so multiplication-congruence (and associativity/distributivity) cannot be `rfl`.
-- The standard Bishop resolution is that a *linear* bound `|xₙ − yₙ| ≤ C/(n+1)` (any constant `C`,
-- not just `2`) already forces `x ≈ y`: route each target index through a large auxiliary index and
-- let the generalized Archimedean lemma (`Qarch_gen`) kill the tail. That criterion
-- (`Req_of_lin_bound`) turns every reindex-mismatch into a clean `≈` fact, and the product-gap
-- bound `|x_a y_a − x_b y_b| ≤ |x_a|·|y_a−y_b| + |y_b|·|x_a−x_b|` (with the canonical `|·| ≤ K`
-- bound) does the rest. This is the substrate synthesis: the literature gives the canonical-bound /
-- reindex product; the linear-bound criterion is our packaging of the ε-shift transitivity argument
-- into one reusable engine. None of this is the crux.
-- ===========================================================================

/-- The multiplication reindex never decreases the index: `n ≤ r(n)` (since `r(n)+1 = 2K(n+1) ≥ n+1`).
    This is what lets a regularity/equality gap at the reindexed positions be read at scale `1/(n+1)`. -/
theorem Ridx_ge (x y : Real) (n : Nat) : n ≤ Ridx x y n := by
  have hs := Ridx_succ x y n
  have hk := RmulK_pos x y
  have hmul : (n + 1) ≤ 2 * RmulK x y * (n + 1) :=
    Nat.le_trans (by omega) (Nat.mul_le_mul (show 1 ≤ 2 * RmulK x y by omega) (Nat.le_refl (n + 1)))
  omega

/-- Constant-fraction monotonicity in the numerator (denominators both `1`): `a ≤ b ⟹ a/1 ≤ b/1`. -/
theorem Qconst_le {a b : Nat} (h : a ≤ b) : Qle (⟨(a : Int), 1⟩ : Q) ⟨(b : Int), 1⟩ := by
  show (a : Int) * ((1 : Nat) : Int) ≤ (b : Int) * ((1 : Nat) : Int)
  have hab : (a : Int) ≤ (b : Int) := by exact_mod_cast h
  omega

/-- The regularity gap of one sequence, read at scale `1/(n+1)`: if both indices are `≥ n` then
    `|x_i − x_j| ≤ 2/(n+1)`. (Collapse the regularity bound `1/(i+1)+1/(j+1)` via `Qscale_le`.) -/
theorem Rgap_le (x : Real) {i j n : Nat} (hi : n ≤ i) (hj : n ≤ j) :
    Qle (Qabs (Qsub (x.seq i) (x.seq j))) ⟨2, n + 1⟩ := by
  have hmono : Qle (add (Qbound i) (Qbound j)) (add (Qbound n) (Qbound n)) :=
    Qadd_le_add (Qscale_le (by omega) (by omega) hi) (Qscale_le (by omega) (by omega) hj)
  have hcol : Qle (add (Qbound n) (Qbound n)) ⟨2, n + 1⟩ := by
    apply Qeq_le; simp only [Qeq, add, Qbound]; push_cast; ring_uor
  exact Qle_trans (add_den_pos (Qbound_den_pos i) (Qbound_den_pos j)) (x.reg i j)
    (Qle_trans (add_den_pos (Qbound_den_pos n) (Qbound_den_pos n)) hmono hcol)

/-- The cross gap of two `≈`-equal sequences, read at scale `1/(n+1)`: if both indices are `≥ n` then
    `|x_i − x'_j| ≤ 4/(n+1)` (route through `x'_i`: equality `2/(n+1)` + regularity `2/(n+1)`). -/
theorem Rcross_le {x x' : Real} (h : Req x x') {i j n : Nat} (hi : n ≤ i) (hj : n ≤ j) :
    Qle (Qabs (Qsub (x.seq i) (x'.seq j))) ⟨4, n + 1⟩ := by
  have htri := Qabs_sub_triangle (a := x.seq i) (b := x'.seq i) (c := x'.seq j)
    (x.den_pos i) (x'.den_pos i) (x'.den_pos j)
  have he : Qle (Qabs (Qsub (x.seq i) (x'.seq i))) ⟨2, n + 1⟩ :=
    Qle_trans (Nat.succ_pos i) (h i) (Qscale_le (by omega) (by omega) hi)
  have hr : Qle (Qabs (Qsub (x'.seq i) (x'.seq j))) ⟨2, n + 1⟩ := Rgap_le x' hi hj
  have hsum := Qadd_le_add he hr
  have hcol : Qle (add (⟨2, n + 1⟩ : Q) ⟨2, n + 1⟩) ⟨4, n + 1⟩ := by
    apply Qeq_le; simp only [Qeq, add]; push_cast; ring_uor
  refine Qle_trans ?_ htri (Qle_trans ?_ hsum hcol)
  · exact add_den_pos (Qabs_den_pos (Qsub_den_pos (x.den_pos i) (x'.den_pos i)))
      (Qabs_den_pos (Qsub_den_pos (x'.den_pos i) (x'.den_pos j)))
  · exact add_den_pos (Nat.succ_pos n) (Nat.succ_pos n)

/-- **The linear-bound criterion** (Lemma A, the v0.6.0 engine): if `|xₙ − yₙ| ≤ C/(n+1)` for every
    `n` (any fixed constant `C`), then `x ≈ y`. For each target index `k`, route `|x_k − y_k|`
    through an auxiliary `m`: `≤ |x_k − x_m| + |x_m − y_m| + |y_m − y_k| ≤ 2/(k+1) + (C+2)/(m+1)`;
    the generalized Archimedean lemma kills the `m`-tail. This converts every reindex-mismatch bound
    into a genuine `≈`. -/
theorem Req_of_lin_bound {x y : Real} {C : Nat}
    (hb : ∀ n, Qle (Qabs (Qsub (x.seq n) (y.seq n))) ⟨(C : Int), n + 1⟩) : Req x y := by
  intro k
  apply Qarch_gen (C := C + 2)
    (Qabs_den_pos (Qsub_den_pos (x.den_pos k) (y.den_pos k))) (Nat.succ_pos k)
  intro m
  have h1 := Qabs_sub_triangle (a := x.seq k) (b := x.seq m) (c := y.seq k)
    (x.den_pos k) (x.den_pos m) (y.den_pos k)
  have h2 := Qabs_sub_triangle (a := x.seq m) (b := y.seq m) (c := y.seq k)
    (x.den_pos m) (y.den_pos m) (y.den_pos k)
  have c2 := Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos (x.den_pos m) (y.den_pos m)))
      (Qabs_den_pos (Qsub_den_pos (y.den_pos m) (y.den_pos k)))) h2
      (Qadd_le_add (hb m) (y.reg m k))
  have c1 := Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos (x.den_pos k) (x.den_pos m)))
      (Qabs_den_pos (Qsub_den_pos (x.den_pos m) (y.den_pos k)))) h1
      (Qadd_le_add (x.reg k m) c2)
  have hfin : Qle (add (add (Qbound k) (Qbound m))
                      (add ⟨(C : Int), m + 1⟩ (add (Qbound m) (Qbound k))))
                  (add (⟨2, k + 1⟩ : Q) ⟨((C + 2 : Nat) : Int), m + 1⟩) := by
    apply Qeq_le; simp only [Qeq, add, Qbound]; push_cast; ring_uor
  exact Qle_trans (add_den_pos (add_den_pos (Qbound_den_pos k) (Qbound_den_pos m))
      (add_den_pos (Nat.succ_pos m) (add_den_pos (Qbound_den_pos m) (Qbound_den_pos k)))) c1 hfin

/-- **The product-gap lemma**: with both factors bounded by `L` and the factor gaps bounded by
    `s/(n+1)` and `t/(n+1)`, the product gap is bounded by `L(s+t)/(n+1)`. The binary engine for
    multiplication-congruence and the ring laws (`Qabs_mul_diff` + `Qmul_le_mul`). -/
theorem Rmul_gap {xa ya xb yb : Q} {L s t n : Nat}
    (hxa : 0 < xa.den) (hya : 0 < ya.den) (hxb : 0 < xb.den) (hyb : 0 < yb.den)
    (hxaB : Qle (Qabs xa) ⟨(L : Int), 1⟩) (hybB : Qle (Qabs yb) ⟨(L : Int), 1⟩)
    (hyd : Qle (Qabs (Qsub ya yb)) ⟨(s : Int), n + 1⟩)
    (hxd : Qle (Qabs (Qsub xa xb)) ⟨(t : Int), n + 1⟩) :
    Qle (Qabs (Qsub (mul xa ya) (mul xb yb))) ⟨(L * (s + t) : Nat), n + 1⟩ := by
  have hdiff := Qabs_mul_diff hxa hya hxb hyb
  have t1 := Qmul_le_mul (a := Qabs xa) (b := ⟨(L : Int), 1⟩) (c := Qabs (Qsub ya yb))
    (d := ⟨(s : Int), n + 1⟩) (Qabs_den_pos hxa) Nat.one_pos
    (Qabs_den_pos (Qsub_den_pos hya hyb)) (Qabs_num_nonneg _) (Qabs_num_nonneg _) hxaB hyd
  have t2 := Qmul_le_mul (a := Qabs yb) (b := ⟨(L : Int), 1⟩) (c := Qabs (Qsub xa xb))
    (d := ⟨(t : Int), n + 1⟩) (Qabs_den_pos hyb) Nat.one_pos
    (Qabs_den_pos (Qsub_den_pos hxa hxb)) (Qabs_num_nonneg _) (Qabs_num_nonneg _) hybB hxd
  have hid : Qle (add (mul (⟨(L : Int), 1⟩ : Q) ⟨(s : Int), n + 1⟩) (mul ⟨(L : Int), 1⟩ ⟨(t : Int), n + 1⟩))
                 ⟨(L * (s + t) : Nat), n + 1⟩ := by
    apply Qeq_le; simp only [Qeq, add, mul]; push_cast; ring_uor
  refine Qle_trans ?_ hdiff (Qle_trans ?_ (Qadd_le_add t1 t2) hid)
  · exact add_den_pos (Qmul_den_pos (Qabs_den_pos hxa) (Qabs_den_pos (Qsub_den_pos hya hyb)))
      (Qmul_den_pos (Qabs_den_pos hyb) (Qabs_den_pos (Qsub_den_pos hxa hxb)))
  · exact add_den_pos (Qmul_den_pos Nat.one_pos (Nat.succ_pos n))
      (Qmul_den_pos Nat.one_pos (Nat.succ_pos n))

/-- A two-term difference collapses to the sum of the coefficients: if `P − Q = d₁ + d₂` (as ℚ
    values) with `|d₁| ≤ p/(n+1)` and `|d₂| ≤ q/(n+1)`, then `|P − Q| ≤ (p+q)/(n+1)`. -/
theorem Qabs_two_diff_gen {A B d1 d2 : Q} {p q n : Nat}
    (hd1 : 0 < d1.den) (hd2 : 0 < d2.den)
    (hAB : Qeq (Qsub A B) (add d1 d2))
    (h1 : Qle (Qabs d1) ⟨(p : Int), n + 1⟩) (h2 : Qle (Qabs d2) ⟨(q : Int), n + 1⟩) :
    Qle (Qabs (Qsub A B)) ⟨(p + q : Nat), n + 1⟩ := by
  have step1 : Qle (Qabs (Qsub A B)) (Qabs (add d1 d2)) := Qeq_le (Qabs_Qeq hAB)
  have step4 : Qle (add (⟨(p : Int), n + 1⟩ : Q) ⟨(q : Int), n + 1⟩) ⟨(p + q : Nat), n + 1⟩ := by
    apply Qeq_le; simp only [Qeq, add]; push_cast; ring_uor
  exact Qle_trans (Qabs_den_pos (add_den_pos hd1 hd2)) step1
    (Qle_trans (add_den_pos (Qabs_den_pos hd1) (Qabs_den_pos hd2)) (Qabs_add_le d1 d2)
    (Qle_trans (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n)) (Qadd_le_add h1 h2) step4))

/-- A product of two canonically-bounded terms is bounded by the product of the bounds:
    `|x_i · y_j| ≤ (K_x·K_y)/1`. The bound needed for the *outer* factor in triple products. -/
theorem canon_bound_mul (x y : Real) (i j : Nat) :
    Qle (Qabs (mul (x.seq i) (y.seq j))) ⟨(xBound x * xBound y : Nat), 1⟩ := by
  rw [Qabs_mul]
  have hb := Qmul_le_mul (a := Qabs (x.seq i)) (b := ⟨(xBound x : Nat), 1⟩)
    (c := Qabs (y.seq j)) (d := ⟨(xBound y : Nat), 1⟩) (Qabs_den_pos (x.den_pos i)) Nat.one_pos
    (Qabs_den_pos (y.den_pos j)) (Qabs_num_nonneg _) (Qabs_num_nonneg _)
    (canon_bound x i) (canon_bound y j)
  have he : Qle (mul (⟨(xBound x : Nat), 1⟩ : Q) ⟨(xBound y : Nat), 1⟩)
                ⟨(xBound x * xBound y : Nat), 1⟩ := by
    apply Qeq_le; simp only [Qeq, mul]; push_cast; ring_uor
  exact Qle_trans (Qmul_den_pos Nat.one_pos Nat.one_pos) hb he

/-- The canonical bound relaxed to any `L ≥ K_x`: `|x_i| ≤ L/1`. -/
theorem canon_bound_le {x : Real} {L : Nat} (h : xBound x ≤ L) (i : Nat) :
    Qle (Qabs (x.seq i)) ⟨(L : Int), 1⟩ :=
  Qle_trans Nat.one_pos (canon_bound x i) (Qconst_le h)

/-- `one` is the constant-`1` sequence at every index (definitional). -/
theorem one_seq (k : Nat) : one.seq k = ⟨1, 1⟩ := rfl

-- The ℝ ring laws (up to `≈`), all via the linear-bound criterion + the product-gap engine.

/-- **ℝ multiplication is well-defined on the `≈`-setoid** — the headline v0.6.0 result (deferred from
    v0.5.0): `x ≈ x'`, `y ≈ y'` ⟹ `x·y ≈ x'·y'`. The reindexes `r = Ridx x y` and `r' = Ridx x' y'`
    differ, but the product gap `|x_r y_r − x'_{r'} y'_{r'}| ≤ |x_r|·|y_r − y'_{r'}| + |y'_{r'}|·|x_r − x'_{r'}|`
    is bounded by `8L/(n+1)` (canonical bounds `≤ L`, cross gaps `≤ 4/(n+1)`); the linear-bound
    criterion finishes. This is what makes the ring laws — and `Cmul` — `≈`-respecting. -/
theorem Rmul_congr {x x' y y' : Real} (hx : Req x x') (hy : Req y y') :
    Req (Rmul x y) (Rmul x' y') := by
  apply Req_of_lin_bound (C := max (xBound x) (xBound y') * (4 + 4))
  intro n
  exact Rmul_gap (x.den_pos _) (y.den_pos _) (x'.den_pos _) (y'.den_pos _)
    (canon_bound_le (Nat.le_max_left _ _) _) (canon_bound_le (Nat.le_max_right _ _) _)
    (Rcross_le hy (Ridx_ge x y n) (Ridx_ge x' y' n))
    (Rcross_le hx (Ridx_ge x y n) (Ridx_ge x' y' n))

/-- The multiplicative unit law on ℝ (up to `≈`): `x · 1 ≈ x`. The reindex `r = Ridx x one n ≥ n`
    moves the index, but `x_r · 1 = x_r` (ℚ) and `|x_r − x_n| ≤ 2/(n+1)` (regularity). -/
theorem Rmul_one (x : Real) : Req (Rmul x one) x := by
  intro n
  have hqe : Qeq (Qsub ((Rmul x one).seq n) (x.seq n))
                 (Qsub (x.seq (Ridx x one n)) (x.seq n)) := by
    show Qeq (Qsub (mul (x.seq (Ridx x one n)) (one.seq (Ridx x one n))) (x.seq n))
             (Qsub (x.seq (Ridx x one n)) (x.seq n))
    rw [one_seq]; simp only [Qeq, Qsub, add, neg, mul]; push_cast; ring_uor
  exact Qle_congr_left (Qabs_den_pos (Qsub_den_pos (x.den_pos _) (x.den_pos n)))
    (Qeq_symm (Qabs_Qeq hqe)) (Rgap_le x (Ridx_ge x one n) (Nat.le_refl n))

/-- Associativity of ℝ addition (up to `≈`). The two groupings read `x, y, z` at different reindexes
    (`4n+3` vs `2n+1`); the `y`-terms coincide and cancel, leaving `|x_{4n+3} − x_{2n+1}|` and
    `|z_{2n+1} − z_{4n+3}|`, each `≤ 2/(n+1)` (regularity). The linear-bound criterion finishes. -/
theorem Radd_assoc (x y z : Real) : Req (Radd (Radd x y) z) (Radd x (Radd y z)) := by
  apply Req_of_lin_bound (C := 4)
  intro n
  have hqe : Qeq (Qsub ((Radd (Radd x y) z).seq n) ((Radd x (Radd y z)).seq n))
                 (add (Qsub (x.seq (2 * (2 * n + 1) + 1)) (x.seq (2 * n + 1)))
                      (Qsub (z.seq (2 * n + 1)) (z.seq (2 * (2 * n + 1) + 1)))) := by
    simp only [Radd, Qeq, Qsub, add, neg]; push_cast; ring_uor
  exact Qabs_two_diff_gen (Qsub_den_pos (x.den_pos _) (x.den_pos _))
    (Qsub_den_pos (z.den_pos _) (z.den_pos _)) hqe
    (Rgap_le x (by omega) (by omega)) (Rgap_le z (by omega) (by omega))

/-- Left distributivity on ℝ (up to `≈`): `x·(y + z) ≈ x·y + x·z`. The difference splits into two
    binary product gaps `|x_a y_{2a+1} − x_b y_b|` and `|x_a z_{2a+1} − x_c z_c|` (all indices `≥ n`);
    each is bounded by `4M/(n+1)` via the product-gap engine; the criterion finishes with `C = 8M`. -/
theorem Rmul_distrib (x y z : Real) :
    Req (Rmul x (Radd y z)) (Radd (Rmul x y) (Rmul x z)) := by
  apply Req_of_lin_bound (C := max (xBound x) (max (xBound y) (xBound z)) * (2 + 2)
                            + max (xBound x) (max (xBound y) (xBound z)) * (2 + 2))
  intro n
  have ha := Ridx_ge x (Radd y z) n
  have hb := Ridx_ge x y (2 * n + 1)
  have hc := Ridx_ge x z (2 * n + 1)
  have hMy : xBound y ≤ max (xBound x) (max (xBound y) (xBound z)) :=
    Nat.le_trans (Nat.le_max_left _ _) (Nat.le_max_right _ _)
  have hMz : xBound z ≤ max (xBound x) (max (xBound y) (xBound z)) :=
    Nat.le_trans (Nat.le_max_right _ _) (Nat.le_max_right _ _)
  have hqe : Qeq (Qsub ((Rmul x (Radd y z)).seq n) ((Radd (Rmul x y) (Rmul x z)).seq n))
      (add (Qsub (mul (x.seq (Ridx x (Radd y z) n)) (y.seq (2 * Ridx x (Radd y z) n + 1)))
                 (mul (x.seq (Ridx x y (2 * n + 1))) (y.seq (Ridx x y (2 * n + 1)))))
           (Qsub (mul (x.seq (Ridx x (Radd y z) n)) (z.seq (2 * Ridx x (Radd y z) n + 1)))
                 (mul (x.seq (Ridx x z (2 * n + 1))) (z.seq (Ridx x z (2 * n + 1)))))) := by
    simp only [Rmul, Radd, Qeq, Qsub, add, neg, mul]; push_cast; ring_uor
  refine Qabs_two_diff_gen
    (Qsub_den_pos (Qmul_den_pos (x.den_pos _) (y.den_pos _)) (Qmul_den_pos (x.den_pos _) (y.den_pos _)))
    (Qsub_den_pos (Qmul_den_pos (x.den_pos _) (z.den_pos _)) (Qmul_den_pos (x.den_pos _) (z.den_pos _)))
    hqe ?_ ?_
  · exact Rmul_gap (x.den_pos _) (y.den_pos _) (x.den_pos _) (y.den_pos _)
      (canon_bound_le (Nat.le_max_left _ _) _) (canon_bound_le hMy _)
      (Rgap_le y (by omega) (by omega)) (Rgap_le x (by omega) (by omega))
  · exact Rmul_gap (x.den_pos _) (z.den_pos _) (x.den_pos _) (z.den_pos _)
      (canon_bound_le (Nat.le_max_left _ _) _) (canon_bound_le hMz _)
      (Rgap_le z (by omega) (by omega)) (Rgap_le x (by omega) (by omega))

/-- Associativity of ℝ multiplication (up to `≈`): `(x·y)·z ≈ x·(y·z)`. The two groupings read the
    three factors at *three* different reindexes, with the products associated oppositely. Re-associate
    in ℚ (`mul_assoc`, exact), then telescope the triple-product gap into nested binary product gaps:
    the inner gap `|x_ρ y_ρ − x_c y_σ|` is `≤ 4·max(K_x,K_y)/(n+1)`; the outer gap (with first factor
    bounded by `K_x·K_y` and `z`-gap `≤ 2/(n+1)`) collapses it; the criterion finishes. This completes
    ℝ as a commutative ring up to `≈`. -/
theorem Rmul_assoc (x y z : Real) :
    Req (Rmul (Rmul x y) z) (Rmul x (Rmul y z)) := by
  apply Req_of_lin_bound (C := max (xBound x * xBound y) (xBound z)
                            * (2 + max (xBound x) (xBound y) * (2 + 2)))
  intro n
  have ha := Ridx_ge (Rmul x y) z n
  have hρ := Ridx_ge x y (Ridx (Rmul x y) z n)
  have hc := Ridx_ge x (Rmul y z) n
  have hσ := Ridx_ge y z (Ridx x (Rmul y z) n)
  have hqe : Qeq (Qsub ((Rmul (Rmul x y) z).seq n) ((Rmul x (Rmul y z)).seq n))
      (Qsub (mul (mul (x.seq (Ridx x y (Ridx (Rmul x y) z n)))
                      (y.seq (Ridx x y (Ridx (Rmul x y) z n))))
                 (z.seq (Ridx (Rmul x y) z n)))
            (mul (mul (x.seq (Ridx x (Rmul y z) n))
                      (y.seq (Ridx y z (Ridx x (Rmul y z) n))))
                 (z.seq (Ridx y z (Ridx x (Rmul y z) n))))) := by
    simp only [Rmul, Qeq, Qsub, add, neg, mul]; push_cast; ring_uor
  have hinner : Qle (Qabs (Qsub
        (mul (x.seq (Ridx x y (Ridx (Rmul x y) z n)))
             (y.seq (Ridx x y (Ridx (Rmul x y) z n))))
        (mul (x.seq (Ridx x (Rmul y z) n))
             (y.seq (Ridx y z (Ridx x (Rmul y z) n))))))
      ⟨(max (xBound x) (xBound y) * (2 + 2) : Nat), n + 1⟩ :=
    Rmul_gap (x.den_pos _) (y.den_pos _) (x.den_pos _) (y.den_pos _)
      (canon_bound_le (Nat.le_max_left _ _) _) (canon_bound_le (Nat.le_max_right _ _) _)
      (Rgap_le y (by omega) (by omega)) (Rgap_le x (by omega) (by omega))
  have houter : Qle (Qabs (Qsub
        (mul (mul (x.seq (Ridx x y (Ridx (Rmul x y) z n)))
                  (y.seq (Ridx x y (Ridx (Rmul x y) z n))))
             (z.seq (Ridx (Rmul x y) z n)))
        (mul (mul (x.seq (Ridx x (Rmul y z) n))
                  (y.seq (Ridx y z (Ridx x (Rmul y z) n))))
             (z.seq (Ridx y z (Ridx x (Rmul y z) n))))))
      ⟨(max (xBound x * xBound y) (xBound z)
          * (2 + max (xBound x) (xBound y) * (2 + 2)) : Nat), n + 1⟩ :=
    Rmul_gap (Qmul_den_pos (x.den_pos _) (y.den_pos _)) (z.den_pos _)
      (Qmul_den_pos (x.den_pos _) (y.den_pos _)) (z.den_pos _)
      (Qle_trans Nat.one_pos (canon_bound_mul x y _ _) (Qconst_le (Nat.le_max_left _ _)))
      (canon_bound_le (Nat.le_max_right _ _) _)
      (Rgap_le z (by omega) (by omega)) hinner
  exact Qle_congr_left
    (Qabs_den_pos (Qsub_den_pos
      (Qmul_den_pos (Qmul_den_pos (x.den_pos _) (y.den_pos _)) (z.den_pos _))
      (Qmul_den_pos (Qmul_den_pos (x.den_pos _) (y.den_pos _)) (z.den_pos _))))
    (Qeq_symm (Qabs_Qeq hqe)) houter

-- Unit / zero laws and the pointwise additive rearrangements the ℂ ring laws reduce to.

/-- `zero` is the constant-`0` sequence at every index (definitional). -/
theorem zero_seq (k : Nat) : zero.seq k = ⟨0, 1⟩ := rfl

/-- The multiplicative zero law on ℝ (up to `≈`): `x · 0 ≈ 0` (the product value is `0` at every
    reindexed point). -/
theorem Rmul_zero (x : Real) : Req (Rmul x zero) zero := by
  apply Req_of_seq_Qeq
  intro n
  show Qeq (mul (x.seq (Ridx x zero n)) (zero.seq (Ridx x zero n))) (zero.seq n)
  simp [zero_seq, Qeq, mul]

/-- The additive unit law on ℝ (up to `≈`): `x + 0 ≈ x` (the `2n+1` reindex, value unchanged). -/
theorem Radd_zero (x : Real) : Req (Radd x zero) x := by
  intro n
  have hqe : Qeq (Qsub ((Radd x zero).seq n) (x.seq n)) (Qsub (x.seq (2 * n + 1)) (x.seq n)) := by
    show Qeq (Qsub (add (x.seq (2 * n + 1)) (zero.seq (2 * n + 1))) (x.seq n))
             (Qsub (x.seq (2 * n + 1)) (x.seq n))
    simp only [zero_seq, Qeq, Qsub, add, neg]; push_cast; ring_uor
  exact Qle_congr_left (Qabs_den_pos (Qsub_den_pos (x.den_pos _) (x.den_pos n)))
    (Qeq_symm (Qabs_Qeq hqe)) (Rgap_le x (by omega) (by omega))

/-- The subtractive unit law on ℝ (up to `≈`): `x − 0 ≈ x`. -/
theorem Rsub_zero (x : Real) : Req (Rsub x zero) x := by
  intro n
  have hqe : Qeq (Qsub ((Rsub x zero).seq n) (x.seq n)) (Qsub (x.seq (2 * n + 1)) (x.seq n)) := by
    show Qeq (Qsub (add (x.seq (2 * n + 1)) ((Rneg zero).seq (2 * n + 1))) (x.seq n))
             (Qsub (x.seq (2 * n + 1)) (x.seq n))
    simp only [Rneg, zero_seq, Qeq, Qsub, add, neg]; push_cast; ring_uor
  exact Qle_congr_left (Qabs_den_pos (Qsub_den_pos (x.den_pos _) (x.den_pos n)))
    (Qeq_symm (Qabs_Qeq hqe)) (Rgap_le x (by omega) (by omega))

/-- Right distributivity on ℝ (up to `≈`), via commutativity and left distributivity. -/
theorem Rmul_distrib_right (x y w : Real) :
    Req (Rmul (Radd x y) w) (Radd (Rmul x w) (Rmul y w)) :=
  Req_trans (Rmul_comm (Radd x y) w)
    (Req_trans (Rmul_distrib w x y) (Radd_congr (Rmul_comm w x) (Rmul_comm w y)))

/-- Additive rearrangement `(P+Q) − (R+S) ≈ (P−R) + (Q−S)` — pointwise (both groupings read the four
    summands at the same reindexed positions, so it is an exact ℚ identity at each index). -/
theorem Rsub_Radd_Radd (P Q R S : Real) :
    Req (Rsub (Radd P Q) (Radd R S)) (Radd (Rsub P R) (Rsub Q S)) := by
  apply Req_of_seq_Qeq
  intro n
  simp only [Rsub, Radd, Rneg, Qeq, add, neg]; push_cast; ring_uor

/-- Additive rearrangement `(P+Q) + (R+S) ≈ (P+R) + (Q+S)` — pointwise (middle-four swap). -/
theorem Radd_swap (P Q R S : Real) :
    Req (Radd (Radd P Q) (Radd R S)) (Radd (Radd P R) (Radd Q S)) := by
  apply Req_of_seq_Qeq
  intro n
  simp only [Radd, Qeq, add]; push_cast; ring_uor

-- Negation/multiplication interaction and subtractive distributivity (the v0.6.0 pieces that, with the
-- two re-association rearrangements below, complete ℂ multiplicative associativity).

/-- `(−x)·y ≈ −(x·y)`. The reindexes of `Rmul (Rneg x) y` and `Rmul x y` coincide (`Rneg` preserves
    the canonical bound), so the gap reduces to the product gap `|x_{r₂}y_{r₂} − x_{r₁}y_{r₁}|`; the
    linear-bound criterion finishes. -/
theorem Rmul_neg_left (x y : Real) : Req (Rmul (Rneg x) y) (Rneg (Rmul x y)) := by
  apply Req_of_lin_bound (C := max (xBound x) (xBound y) * (2 + 2))
  intro n
  have hqe : Qeq (Qsub ((Rmul (Rneg x) y).seq n) ((Rneg (Rmul x y)).seq n))
      (Qsub (mul (x.seq (Ridx x y n)) (y.seq (Ridx x y n)))
            (mul (x.seq (Ridx (Rneg x) y n)) (y.seq (Ridx (Rneg x) y n)))) := by
    show Qeq (Qsub (mul ((Rneg x).seq (Ridx (Rneg x) y n)) (y.seq (Ridx (Rneg x) y n)))
                   (neg (mul (x.seq (Ridx x y n)) (y.seq (Ridx x y n)))))
             (Qsub (mul (x.seq (Ridx x y n)) (y.seq (Ridx x y n)))
                   (mul (x.seq (Ridx (Rneg x) y n)) (y.seq (Ridx (Rneg x) y n))))
    simp only [Rneg, Qeq, Qsub, add, neg, mul]; push_cast; ring_uor
  have hgap : Qle (Qabs (Qsub (mul (x.seq (Ridx x y n)) (y.seq (Ridx x y n)))
        (mul (x.seq (Ridx (Rneg x) y n)) (y.seq (Ridx (Rneg x) y n)))))
      ⟨(max (xBound x) (xBound y) * (2 + 2) : Nat), n + 1⟩ :=
    Rmul_gap (x.den_pos _) (y.den_pos _) (x.den_pos _) (y.den_pos _)
      (canon_bound_le (Nat.le_max_left _ _) _) (canon_bound_le (Nat.le_max_right _ _) _)
      (Rgap_le y (Ridx_ge x y n) (Ridx_ge (Rneg x) y n))
      (Rgap_le x (Ridx_ge x y n) (Ridx_ge (Rneg x) y n))
  exact Qle_congr_left
    (Qabs_den_pos (Qsub_den_pos (Qmul_den_pos (x.den_pos _) (y.den_pos _))
      (Qmul_den_pos (x.den_pos _) (y.den_pos _))))
    (Qeq_symm (Qabs_Qeq hqe)) hgap

/-- `x·(−y) ≈ −(x·y)`, via commutativity. -/
theorem Rmul_neg_right (x y : Real) : Req (Rmul x (Rneg y)) (Rneg (Rmul x y)) :=
  Req_trans (Rmul_comm x (Rneg y))
    (Req_trans (Rmul_neg_left y x) (Rneg_congr (Rmul_comm y x)))

/-- Left distributivity over subtraction: `x·(y − z) ≈ x·y − x·z`. -/
theorem Rmul_sub_distrib (x y z : Real) :
    Req (Rmul x (Rsub y z)) (Rsub (Rmul x y) (Rmul x z)) :=
  Req_trans (Rmul_distrib x y (Rneg z)) (Radd_congr (Req_refl _) (Rmul_neg_right x z))

/-- Right distributivity over subtraction: `(x − y)·z ≈ x·z − y·z`. -/
theorem Rmul_sub_distrib_right (x y z : Real) :
    Req (Rmul (Rsub x y) z) (Rsub (Rmul x z) (Rmul y z)) :=
  Req_trans (Rmul_comm (Rsub x y) z)
    (Req_trans (Rmul_sub_distrib z x y) (Rsub_congr (Rmul_comm z x) (Rmul_comm z y)))

/-- Re-association for the real part of the triple product: `(P₁−P₄) − (P₂+P₃) ≈ (P₁−P₂) − (P₃+P₄)`
    (both equal `P₁−P₂−P₃−P₄`; pointwise). -/
theorem Rreassoc_sub (P1 P2 P3 P4 : Real) :
    Req (Rsub (Rsub P1 P4) (Radd P2 P3)) (Rsub (Rsub P1 P2) (Radd P3 P4)) := by
  apply Req_of_seq_Qeq
  intro n
  simp only [Rsub, Radd, Rneg, Qeq, add, neg]; push_cast; ring_uor

/-- Re-association for the imaginary part: `(Q₁−Q₄) + (Q₂+Q₃) ≈ (Q₁+Q₂) + (Q₃−Q₄)` (pointwise). -/
theorem Rreassoc_add (Q1 Q2 Q3 Q4 : Real) :
    Req (Radd (Rsub Q1 Q4) (Radd Q2 Q3)) (Radd (Radd Q1 Q2) (Rsub Q3 Q4)) := by
  apply Req_of_seq_Qeq
  intro n
  simp only [Rsub, Radd, Rneg, Qeq, add, neg]; push_cast; ring_uor

end UOR.Bridge.F1Square.Analysis
