/-
F1 square — the reciprocal `1/x` of a positive real (part of the v0.12.0 multiplicative substrate;
the field-completing operation that `log` needs).

Positivity is **data** (Bishop): `Rinv` takes a witness `k` with `x_k > 1/(k+1)`. From it, `x` is
bounded below by a positive rational `L` on a computable tail, and the reciprocal is the (reindexed)
sequence of rational reciprocals, regular because `|1/x_a − 1/x_b| = |x_a − x_b|·(1/x_a)(1/x_b)`
is controlled once `x_a, x_b ≥ L`.

This file first builds the rational reciprocal `Qinv` (of a positive-numerator rational) and its laws.
Pure Lean 4, no Mathlib, no `sorry`.
-/

import F1Square.Analysis.ROrder

namespace UOR.Bridge.F1Square.Analysis

/-- The rational reciprocal of `a` (intended for `a.num > 0`): `1/(p/q) = q/p`. -/
def Qinv (a : Q) : Q := ⟨(a.den : Int), a.num.toNat⟩

/-- For a positive-numerator rational, the reciprocal has a positive denominator. -/
theorem Qinv_den_pos {a : Q} (ha : 0 < a.num) : 0 < (Qinv a).den := by
  show 0 < a.num.toNat
  omega

/-- For a positive-numerator rational with positive denominator, the reciprocal has a positive
    numerator. -/
theorem Qinv_num_pos {a : Q} (had : 0 < a.den) : 0 < (Qinv a).num := by
  show 0 < (a.den : Int)
  exact_mod_cast had

/-- The inverse law: `a · (1/a) ≈ 1` for a positive-numerator rational. -/
theorem Qmul_Qinv {a : Q} (ha : 0 < a.num) : Qeq (mul a (Qinv a)) ⟨1, 1⟩ := by
  unfold Qeq mul Qinv
  have ht : (a.num.toNat : Int) = a.num := by omega
  push_cast [ht]
  rw [Int.mul_one, Int.one_mul]
  exact Int.mul_comm a.num _

/-- The reciprocal is **antitone** on positive rationals: `c ≤ a` (both positive) ⟹ `1/a ≤ 1/c`. -/
theorem Qinv_antitone {a c : Q} (ha : 0 < a.num) (hc : 0 < c.num) (h : Qle c a) :
    Qle (Qinv a) (Qinv c) := by
  unfold Qinv Qle at *
  have hta : (a.num.toNat : Int) = a.num := by omega
  have htc : (c.num.toNat : Int) = c.num := by omega
  -- goal: a.den * c.num.toNat ≤ c.den * a.num.toNat ; h: c.num * a.den ≤ a.num * c.den
  push_cast [hta, htc]
  -- a.den * c.num ≤ c.den * a.num   from   c.num * a.den ≤ a.num * c.den
  have e1 : (a.den : Int) * c.num = c.num * (a.den : Int) := Int.mul_comm _ _
  have e2 : (c.den : Int) * a.num = a.num * (c.den : Int) := Int.mul_comm _ _
  rw [e1, e2]; exact h

-- The cross-multiplied polynomial identity behind the reciprocal difference (an explicit-ℤ lemma so
-- `ring_uor` sees a clean equality; `push_cast` leaves `mdata` that its frontend would otherwise reject).
private theorem qinv_sub_eq_core (an bn ad bd : Int) :
    (ad * bn + -bd * an) * (bd * ad * (an * bn))
      = (bn * ad + -an * bd) * (ad * bd) * (an * bn) := by ring_uor

/-- **The reciprocal difference identity**: `1/a − 1/b = (b − a)·(1/a)·(1/b)` (positive numerators). -/
theorem Qinv_sub_eq {a b : Q} (ha : 0 < a.num) (hb : 0 < b.num) :
    Qeq (Qsub (Qinv a) (Qinv b)) (mul (Qsub b a) (mul (Qinv a) (Qinv b))) := by
  have hta : (a.num.toNat : Int) = a.num := by omega
  have htb : (b.num.toNat : Int) = b.num := by omega
  simp only [Qeq, Qsub, Qinv, mul, add, neg]
  push_cast [hta, htb]
  exact qinv_sub_eq_core a.num b.num (a.den : Int) (b.den : Int)

-- ===========================================================================
-- The real reciprocal `Rinv` (positivity-as-data: the witness `k` with `x_k > 1/(k+1)`).
-- ===========================================================================

/-- The positive gap `δ = x_k − 1/(k+1)` from the positivity witness. -/
def Rdelta (x : Real) (k : Nat) : Q := Qsub (x.seq k) (Qbound k)

/-- The positive rational floor `L = δ/2` that `x` exceeds on the tail `m ≥ 2·δ.den`. -/
def RL (x : Real) (k : Nat) : Q := ⟨(Rdelta x k).num, 2 * (Rdelta x k).den⟩

/-- The gap has a positive numerator (this is exactly what the positivity witness says). -/
theorem Rdelta_num_pos {x : Real} {k : Nat} (hk : Qlt (Qbound k) (x.seq k)) : 0 < (Rdelta x k).num := by
  unfold Rdelta Qsub add neg Qbound
  unfold Qlt Qbound at hk
  push_cast at hk ⊢
  omega

/-- `δ` has a positive denominator. -/
theorem Rdelta_den_pos {x : Real} {k : Nat} : 0 < (Rdelta x k).den :=
  Qsub_den_pos (x.den_pos k) (Qbound_den_pos k)

/-- `L`'s numerator is positive. -/
theorem RL_num_pos {x : Real} {k : Nat} (hk : Qlt (Qbound k) (x.seq k)) : 0 < (RL x k).num :=
  Rdelta_num_pos hk

/-- `L`'s denominator is positive. -/
theorem RL_den_pos {x : Real} {k : Nat} : 0 < (RL x k).den := by
  show 0 < 2 * (Rdelta x k).den
  have := @Rdelta_den_pos x k; omega

-- The cross-multiplied inequality `δ/2 ≤ δ − 1/(m+1)` for `m ≥ 2δ.den` (nonlinear; explicit-ℤ core
-- so `omega` only sees linear facts about the normalized products).
private theorem RL_le_core (p q r : Int) (hp : 1 ≤ p) (hq : 0 ≤ q) (hr : 2 * q + 1 ≤ r) :
    p * (q * r) ≤ (p * r + (-1) * q) * (2 * q) := by
  have hrr : r ≤ p * r := by
    have h := Int.mul_le_mul_of_nonneg_right hp (by omega : (0 : Int) ≤ r)
    rwa [Int.one_mul] at h
  have h2qpr : 2 * q ≤ p * r := by omega
  have hqq : q * (2 * q) ≤ q * (p * r) := Int.mul_le_mul_of_nonneg_left h2qpr hq
  have e1 : p * (q * r) = q * (p * r) := by ring_uor
  have e2 : (p * r + (-1) * q) * (2 * q) = 2 * (q * (p * r)) - 2 * (q * q) := by ring_uor
  have e3 : q * (2 * q) = 2 * (q * q) := by ring_uor
  rw [e3] at hqq
  rw [e1, e2]
  omega

/-- **Bounded below by the witness**: for `m ≥ 2·δ.den`, `x_m ≥ L = δ/2 > 0`. -/
theorem Rinv_lb {x : Real} {k : Nat} (hk : Qlt (Qbound k) (x.seq k))
    {m : Nat} (hm : 2 * (Rdelta x k).den ≤ m) : Qle (RL x k) (x.seq m) := by
  have hδ : 0 < (Rdelta x k).num := Rdelta_num_pos hk
  -- step 2: x_m ≥ δ − 1/(m+1)
  have hreg : Qle (x.seq k) (add (x.seq m) (add (Qbound k) (Qbound m))) :=
    Qle_add_of_Qabs_sub (x.den_pos k) (x.den_pos m)
      (add_den_pos (Qbound_den_pos k) (Qbound_den_pos m)) (x.reg k m)
  have hreg2 : Qle (x.seq k) (add (add (Qbound k) (Qbound m)) (x.seq m)) :=
    Qle_congr_right (add_den_pos (x.den_pos m) (add_den_pos (Qbound_den_pos k) (Qbound_den_pos m)))
      (add_comm _ _) hreg
  have hsub : Qle (Qsub (x.seq k) (add (Qbound k) (Qbound m))) (x.seq m) :=
    Qsub_le_of_le_add (add_den_pos (Qbound_den_pos k) (Qbound_den_pos m)) (x.den_pos m) hreg2
  have heq : Qeq (Qsub (Rdelta x k) (Qbound m)) (Qsub (x.seq k) (add (Qbound k) (Qbound m))) := by
    simp only [Rdelta, Qeq, Qsub, add, neg, Qbound]; push_cast; ring_uor
  have step2 : Qle (Qsub (Rdelta x k) (Qbound m)) (x.seq m) :=
    Qle_congr_left (Qsub_den_pos (x.den_pos k) (add_den_pos (Qbound_den_pos k) (Qbound_den_pos m)))
      (Qeq_symm heq) hsub
  -- step 3: L ≤ δ − 1/(m+1)
  have hr : 2 * ((Rdelta x k).den : Int) + 1 ≤ ((m : Int) + 1) := by
    have : (2 * (Rdelta x k).den : Nat) ≤ m := hm
    have h2 : (2 * (Rdelta x k).den : Int) ≤ (m : Int) := by exact_mod_cast this
    push_cast at h2 ⊢; omega
  have step3 : Qle (RL x k) (Qsub (Rdelta x k) (Qbound m)) := by
    show (RL x k).num * ((Qsub (Rdelta x k) (Qbound m)).den : Int)
      ≤ (Qsub (Rdelta x k) (Qbound m)).num * ((RL x k).den : Int)
    unfold RL Qsub add neg Qbound
    push_cast
    exact RL_le_core (Rdelta x k).num ((Rdelta x k).den : Int) ((m : Int) + 1) hδ (Int.ofNat_nonneg _) hr
  exact Qle_trans (Qsub_den_pos (@Rdelta_den_pos x k) (Qbound_den_pos m)) step3 step2

/-- `|1/a| = 1/a` for a positive-numerator rational (the reciprocal is already non-negative). -/
theorem Qabs_Qinv (a : Q) : Qabs (Qinv a) = Qinv a := rfl

/-- At any reindexed point past the threshold, `x` has a positive numerator. -/
theorem Rinv_num_pos {x : Real} {k : Nat} (hk : Qlt (Qbound k) (x.seq k))
    {m : Nat} (hm : 2 * (Rdelta x k).den ≤ m) : 0 < (x.seq m).num := by
  have hle := Rinv_lb hk hm
  unfold Qle at hle
  have hpos : 0 < (RL x k).num * ((x.seq m).den : Int) :=
    Int.mul_pos (RL_num_pos hk) (by exact_mod_cast x.den_pos m)
  have hxnRLd : 0 < (x.seq m).num * ((RL x k).den : Int) := by omega
  have h0 : 0 * ((RL x k).den : Int) < (x.seq m).num * ((RL x k).den : Int) := by
    rw [Int.zero_mul]; exact hxnRLd
  exact Int.lt_of_mul_lt_mul_right h0 (Int.ofNat_nonneg _)

/-- The regularity reindex scaling `K = 4·δ.den²` (= an integer upper bound on `1/L²`). -/
def RinvK (x : Real) (k : Nat) : Nat := 4 * (Rdelta x k).den * (Rdelta x k).den

/-- The reindex `R n = K·(n+1) + 2δ.den`: far enough that `x ≥ L` *and* the reciprocal gaps shrink
    at rate `1/(n+1)`. -/
def RinvR (x : Real) (k : Nat) (n : Nat) : Nat := RinvK x k * (n + 1) + 2 * (Rdelta x k).den

theorem RinvR_ge {x : Real} {k : Nat} (n : Nat) : 2 * (Rdelta x k).den ≤ RinvR x k n := by
  unfold RinvR; omega

-- The reindex inequality `(1/L²)·(1/(R n+1)) ≤ 1/(n+1)`, cross-multiplied (explicit-ℤ; nonlinear).
private theorem Rinv_reindex_core (dd dn r mm : Int) (hdn : 1 ≤ dn) (hdd : 0 ≤ dd) (hmm : 0 ≤ mm)
    (hr : 4 * dd * dd * mm ≤ r) : (2 * dd) * (2 * dd) * mm ≤ r * (dn * dn) := by
  have e : (2 * dd) * (2 * dd) * mm = 4 * dd * dd * mm := by ring_uor
  have h4 : 0 ≤ 4 * dd * dd * mm :=
    Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg (by omega) hdd) hdd) hmm
  have hrnn : 0 ≤ r := Int.le_trans h4 hr
  have hdn2 : 1 ≤ dn * dn := by
    have h := Int.mul_le_mul hdn hdn (by omega) (by omega); omega
  have h2 := Int.mul_le_mul_of_nonneg_left hdn2 hrnn
  rw [Int.mul_one] at h2
  rw [e]; omega

/-- **The per-term reindex bound**: `(1/L²)·(1/(R m+1)) ≤ 1/(m+1)`. -/
theorem Rinv_perterm {x : Real} {k : Nat} (hk : Qlt (Qbound k) (x.seq k)) (m : Nat) :
    Qle (mul (Qbound (RinvR x k m)) (mul (Qinv (RL x k)) (Qinv (RL x k)))) (Qbound m) := by
  have hdn : 1 ≤ (Rdelta x k).num := Rdelta_num_pos hk
  have htn : ((Rdelta x k).num.toNat : Int) = (Rdelta x k).num := by omega
  show (mul (Qbound (RinvR x k m)) (mul (Qinv (RL x k)) (Qinv (RL x k)))).num * ((Qbound m).den : Int)
      ≤ (Qbound m).num * ((mul (Qbound (RinvR x k m)) (mul (Qinv (RL x k)) (Qinv (RL x k)))).den : Int)
  unfold mul Qbound Qinv RL
  push_cast [htn]
  simp only [Int.one_mul]
  have hr : 4 * ((Rdelta x k).den : Int) * ((Rdelta x k).den : Int) * ((m : Int) + 1)
      ≤ ((RinvR x k m : Nat) : Int) + 1 := by
    unfold RinvR RinvK; push_cast; omega
  exact Rinv_reindex_core ((Rdelta x k).den : Int) ((Rdelta x k).num) ((RinvR x k m : Int) + 1)
    ((m : Int) + 1) hdn (Int.ofNat_nonneg _) (by omega) hr

/-- `|a − b| = |b − a|` (the absolute value of a difference is symmetric). -/
theorem Qabs_Qsub_swap (a b : Q) : Qabs (Qsub a b) = Qabs (Qsub b a) := by
  unfold Qabs
  rw [Qsub_swap_num a b, Int.natAbs_neg, Qsub_swap_den a b]

/-- The reciprocal sequence `n ↦ 1/x_{R n}` is **regular**, so it defines a constructive real. -/
theorem RinvSeq_regular {x : Real} {k : Nat} (hk : Qlt (Qbound k) (x.seq k)) :
    IsRegular (fun n => Qinv (x.seq (RinvR x k n))) := by
  intro m n
  have hαpos : 0 < (x.seq (RinvR x k m)).num := Rinv_num_pos hk (RinvR_ge m)
  have hβpos : 0 < (x.seq (RinvR x k n)).num := Rinv_num_pos hk (RinvR_ge n)
  have hαlb : Qle (RL x k) (x.seq (RinvR x k m)) := Rinv_lb hk (RinvR_ge m)
  have hβlb : Qle (RL x k) (x.seq (RinvR x k n)) := Rinv_lb hk (RinvR_ge n)
  have hRLn : 0 < (RL x k).num := RL_num_pos hk
  have hαd : 0 < (x.seq (RinvR x k m)).den := x.den_pos _
  have hβd : 0 < (x.seq (RinvR x k n)).den := x.den_pos _
  have hQinvαnn : 0 ≤ (Qinv (x.seq (RinvR x k m))).num := Int.ofNat_nonneg _
  have hQinvβnn : 0 ≤ (Qinv (x.seq (RinvR x k n))).num := Int.ofNat_nonneg _
  -- Step A: |1/α − 1/β| = |α − β|·(1/α)·(1/β)
  have hStepA : Qeq (Qabs (Qsub (Qinv (x.seq (RinvR x k m))) (Qinv (x.seq (RinvR x k n)))))
      (mul (Qabs (Qsub (x.seq (RinvR x k n)) (x.seq (RinvR x k m))))
        (mul (Qinv (x.seq (RinvR x k m))) (Qinv (x.seq (RinvR x k n))))) := by
    have h1 := Qabs_Qeq (Qinv_sub_eq hαpos hβpos)
    rw [Qabs_mul, Qabs_mul, Qabs_Qinv, Qabs_Qinv] at h1
    exact h1
  -- Step B: ≤ (1/(Rm+1)+1/(Rn+1))·(1/L)·(1/L)
  have hcd : Qle (mul (Qinv (x.seq (RinvR x k m))) (Qinv (x.seq (RinvR x k n))))
      (mul (Qinv (RL x k)) (Qinv (RL x k))) :=
    Qmul_le_mul (Qinv_den_pos hαpos) (Qinv_den_pos hRLn) (Qinv_den_pos hβpos)
      hQinvαnn hQinvβnn (Qinv_antitone hαpos hRLn hαlb) (Qinv_antitone hβpos hRLn hβlb)
  have hab : Qle (Qabs (Qsub (x.seq (RinvR x k n)) (x.seq (RinvR x k m))))
      (add (Qbound (RinvR x k m)) (Qbound (RinvR x k n))) := by
    have hreg := x.reg (RinvR x k m) (RinvR x k n)
    rw [Qabs_Qsub_swap (x.seq (RinvR x k m)) (x.seq (RinvR x k n))] at hreg
    exact hreg
  have hStepB : Qle
      (mul (Qabs (Qsub (x.seq (RinvR x k n)) (x.seq (RinvR x k m))))
        (mul (Qinv (x.seq (RinvR x k m))) (Qinv (x.seq (RinvR x k n)))))
      (mul (add (Qbound (RinvR x k m)) (Qbound (RinvR x k n)))
        (mul (Qinv (RL x k)) (Qinv (RL x k)))) :=
    Qmul_le_mul (Qabs_den_pos (Qsub_den_pos hβd hαd))
      (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
      (Qmul_den_pos (Qinv_den_pos hαpos) (Qinv_den_pos hβpos))
      (Qabs_num_nonneg _) (Int.mul_nonneg hQinvαnn hQinvβnn) hab hcd
  -- Step C: ≤ 1/(m+1) + 1/(n+1)
  have hStepC : Qle
      (mul (add (Qbound (RinvR x k m)) (Qbound (RinvR x k n)))
        (mul (Qinv (RL x k)) (Qinv (RL x k))))
      (add (Qbound m) (Qbound n)) := by
    refine Qle_congr_left
      (add_den_pos (Qmul_den_pos (Qbound_den_pos _) (Qmul_den_pos (Qinv_den_pos hRLn) (Qinv_den_pos hRLn)))
        (Qmul_den_pos (Qbound_den_pos _) (Qmul_den_pos (Qinv_den_pos hRLn) (Qinv_den_pos hRLn))))
      (Qeq_symm (Qmul_add_right _ _ _))
      (Qadd_le_add (Rinv_perterm hk m) (Rinv_perterm hk n))
  -- assemble
  refine Qle_trans ?_ (Qeq_le hStepA) (Qle_trans ?_ hStepB hStepC)
  · exact Qmul_den_pos (Qabs_den_pos (Qsub_den_pos hβd hαd))
      (Qmul_den_pos (Qinv_den_pos hαpos) (Qinv_den_pos hβpos))
  · exact Qmul_den_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
      (Qmul_den_pos (Qinv_den_pos hRLn) (Qinv_den_pos hRLn))

/-- **The reciprocal `1/x`** of a positive real (positivity as the witness `k`): a constructive real. -/
def Rinv (x : Real) (k : Nat) (hk : Qlt (Qbound k) (x.seq k)) : Real where
  seq := fun n => Qinv (x.seq (RinvR x k n))
  reg := RinvSeq_regular hk
  den_pos := fun n => Qinv_den_pos (Rinv_num_pos hk (RinvR_ge n))

/-- Division `x / y` (with a positivity witness for `y`). -/
def Rdiv (x y : Real) (k : Nat) (hk : Qlt (Qbound k) (y.seq k)) : Real := Rmul x (Rinv y k hk)

end UOR.Bridge.F1Square.Analysis
