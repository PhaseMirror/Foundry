/-
F1 square — **binomial coefficients and the factorial identity from scratch** (Lean core here has no
`Nat.choose` / `Nat.factorial` / `Nat.add_pow`). This is the foundational first piece of the v0.15.0
keystone: the exponential/trigonometric functional equation via the Cauchy product needs the binomial
identity `Σ_{i+j=k} (xⁱ/i!)(yʲ/j!) = (x+y)ᵏ/k!`, whose heart is `C(k,i)·i!·(k−i)! = k!`.

This module builds `choose` (Pascal's recurrence) and that factorial identity (the ℤ ring algebra is
discharged by `ring_uor`, the project's from-scratch `ring`). Pure Lean 4, no Mathlib, no `sorry`.
-/

import F1Square.Analysis.Exp
import F1Square.Analysis.ExpGen

namespace UOR.Bridge.F1Square.Analysis

/-- Binomial coefficients via Pascal's recurrence. -/
def choose : Nat → Nat → Nat
  | _, 0 => 1
  | 0, (_ + 1) => 0
  | (n + 1), (k + 1) => choose n k + choose n (k + 1)

@[simp] theorem choose_zero_right (n : Nat) : choose n 0 = 1 := by cases n <;> rfl
@[simp] theorem choose_zero_succ (k : Nat) : choose 0 (k + 1) = 0 := rfl
theorem choose_succ_succ (n k : Nat) : choose (n + 1) (k + 1) = choose n k + choose n (k + 1) := rfl

/-- `C(n,k) = 0` when `k > n`. -/
theorem choose_eq_zero_of_lt : ∀ {n k : Nat}, n < k → choose n k = 0
  | 0, 0, h => absurd h (by omega)
  | 0, (_ + 1), _ => rfl
  | (_ + 1), 0, h => absurd h (by omega)
  | (n + 1), (k + 1), h => by
      rw [choose_succ_succ, choose_eq_zero_of_lt (by omega : n < k),
        choose_eq_zero_of_lt (by omega : n < k + 1)]

/-- `C(n,n) = 1`. -/
theorem choose_self : ∀ n, choose n n = 1
  | 0 => rfl
  | (n + 1) => by
      rw [choose_succ_succ, choose_self n, choose_eq_zero_of_lt (Nat.lt_succ_self n)]

-- ===========================================================================
-- A finite inclusive sum `Σ_{i=0}^{k} f i` over ℚ, with the algebra lemmas the binomial
-- theorem's Pascal step needs (distribution, additivity, index shift).
-- ===========================================================================

/-- Finite inclusive sum `Σ_{i=0}^{k} f i`. -/
def Fsum (f : Nat → Q) : Nat → Q
  | 0 => f 0
  | (k + 1) => add (Fsum f k) (f (k + 1))

theorem Fsum_den_pos {f : Nat → Q} (hf : ∀ i, 0 < (f i).den) : ∀ k, 0 < (Fsum f k).den
  | 0 => hf 0
  | (k + 1) => add_den_pos (Fsum_den_pos hf k) (hf (k + 1))

/-- Pointwise-equal summands give equal sums. -/
theorem Fsum_congr {f g : Nat → Q} (h : ∀ i, Qeq (f i) (g i)) : ∀ k, Qeq (Fsum f k) (Fsum g k)
  | 0 => h 0
  | (k + 1) => Qadd_congr (Fsum_congr h k) (h (k + 1))

/-- Reassociation `(a+b)+(c+d) ≈ (a+c)+(b+d)`. -/
theorem Qadd_rearrange (a b c d : Q) : Qeq (add (add a b) (add c d)) (add (add a c) (add b d)) := by
  simp only [Qeq, add]; push_cast; ring_uor

/-- Distribution `c·(a+b) ≈ c·a + c·b`. -/
theorem Qmul_add_left (c a b : Q) : Qeq (mul c (add a b)) (add (mul c a) (mul c b)) := by
  simp only [Qeq, mul, add]; push_cast; ring_uor

/-- Sums add termwise. -/
theorem Fsum_add {f g : Nat → Q} (hf : ∀ i, 0 < (f i).den) (hg : ∀ i, 0 < (g i).den) :
    ∀ k, Qeq (Fsum (fun i => add (f i) (g i)) k) (add (Fsum f k) (Fsum g k))
  | 0 => Qeq_refl _
  | (k + 1) =>
      Qeq_trans
        (add_den_pos (add_den_pos (Fsum_den_pos hf k) (Fsum_den_pos hg k))
          (add_den_pos (hf (k + 1)) (hg (k + 1))))
        (Qadd_congr (Fsum_add hf hg k) (Qeq_refl (add (f (k + 1)) (g (k + 1)))))
        (Qadd_rearrange (Fsum f k) (Fsum g k) (f (k + 1)) (g (k + 1)))

/-- A constant factor pulls out of a sum. -/
theorem Fsum_mul_left {c : Q} {f : Nat → Q} (hcd : 0 < c.den) (hf : ∀ i, 0 < (f i).den) :
    ∀ k, Qeq (Fsum (fun i => mul c (f i)) k) (mul c (Fsum f k))
  | 0 => Qeq_refl _
  | (k + 1) =>
      Qeq_trans
        (add_den_pos (Qmul_den_pos hcd (Fsum_den_pos hf k)) (Qmul_den_pos hcd (hf (k + 1))))
        (Qadd_congr (Fsum_mul_left hcd hf k) (Qeq_refl (mul c (f (k + 1)))))
        (Qeq_symm (Qmul_add_left c (Fsum f k) (f (k + 1))))

/-- Index shift: `Σ_{i=0}^{k} f(i+1) ≈ (Σ_{i=0}^{k+1} f i) − f 0`. -/
theorem Fsum_shift {f : Nat → Q} (hf : ∀ i, 0 < (f i).den) :
    ∀ k, Qeq (Fsum (fun i => f (i + 1)) k) (Qsub (Fsum f (k + 1)) (f 0))
  | 0 => by
      show Qeq (f 1) (Qsub (add (f 0) (f 1)) (f 0))
      simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  | (k + 1) =>
      Qeq_trans
        (add_den_pos (Qsub_den_pos (Fsum_den_pos hf (k + 1)) (hf 0)) (hf (k + 1 + 1)))
        (Qadd_congr (Fsum_shift hf k) (Qeq_refl (f (k + 1 + 1))))
        (by
          show Qeq (add (Qsub (Fsum f (k + 1)) (f 0)) (f (k + 1 + 1)))
            (Qsub (add (Fsum f (k + 1)) (f (k + 1 + 1))) (f 0))
          simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor)

/-- `a + (b − a) ≈ b`. -/
theorem Qadd_sub_cancel_left (a b : Q) : Qeq (add a (Qsub b a)) b := by
  simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor

/-- `(X + c) − X ≈ c`. -/
theorem Qsub_add_left_cancel (X c : Q) : Qeq (Qsub (add X c) X) c := by
  simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor

/-- Front-peel: `Σ_{i=0}^{k+1} f i ≈ f 0 + Σ_{i=0}^{k} f (i+1)`. -/
theorem Fsum_front {f : Nat → Q} (hf : ∀ i, 0 < (f i).den) (k : Nat) :
    Qeq (Fsum f (k + 1)) (add (f 0) (Fsum (fun i => f (i + 1)) k)) :=
  Qeq_symm
    (Qeq_trans (add_den_pos (hf 0) (Qsub_den_pos (Fsum_den_pos hf (k + 1)) (hf 0)))
      (Qadd_congr (Qeq_refl (f 0)) (Fsum_shift hf k))
      (Qadd_sub_cancel_left (f 0) (Fsum f (k + 1))))

/-- Commutativity of `Q` multiplication (up to `≈`). -/
theorem Qmul_swap (a b : Q) : Qeq (mul a b) (mul b a) := by
  simp only [Qeq, mul]; push_cast; ring_uor

/-- Distribution `c·(a−b) ≈ c·a − c·b`. -/
theorem Qmul_sub_distrib (c a b : Q) : Qeq (mul c (Qsub a b)) (Qsub (mul c a) (mul c b)) := by
  simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor

/-- Congruence for `Q` negation. -/
theorem QnegCongr {a b : Q} (h : Qeq a b) : Qeq (neg a) (neg b) := by
  have h' : a.num * (b.den : Int) = b.num * (a.den : Int) := h
  show (-a.num) * (b.den : Int) = (-b.num) * (a.den : Int)
  calc (-a.num) * (b.den : Int) = -(a.num * (b.den : Int)) := by ring_uor
    _ = -(b.num * (a.den : Int)) := by rw [h']
    _ = (-b.num) * (a.den : Int) := by ring_uor

/-- Congruence for `Q` subtraction. -/
theorem QsubCongr {a b c d : Q} (hac : Qeq a c) (hbd : Qeq b d) : Qeq (Qsub a b) (Qsub c d) :=
  Qadd_congr hac (QnegCongr hbd)

/-- The general binomial summand `C(n,i)·xⁱ·yⁿ⁻ⁱ`. -/
def binTerm (x y : Q) (n i : Nat) : Q :=
  mul ⟨(choose n i : Int), 1⟩ (mul (qpow x i) (qpow y (n - i)))

theorem binTerm_den_pos {x y : Q} (hxd : 0 < x.den) (hyd : 0 < y.den) (n i : Nat) :
    0 < (binTerm x y n i).den :=
  Qmul_den_pos Nat.one_pos (Qmul_den_pos (qpow_den_pos hxd i) (qpow_den_pos hyd (n - i)))

/-- Top boundary: `y · binTerm n (n+1) ≈ 0` (since `C(n,n+1) = 0`). -/
theorem binTerm_top_zero (x y : Q) (n : Nat) : Qeq (mul y (binTerm x y n (n + 1))) ⟨0, 1⟩ := by
  have hc : choose n (n + 1) = 0 := choose_eq_zero_of_lt (by omega)
  show Qeq (mul y (mul ⟨(choose n (n + 1) : Int), 1⟩
    (mul (qpow x (n + 1)) (qpow y (n - (n + 1)))))) ⟨0, 1⟩
  rw [hc]; simp [Qeq, mul]

/-- Bottom boundary: `binTerm (n+1) 0 ≈ y · binTerm n 0` (both are `yⁿ⁺¹`). -/
theorem binTerm_zero_bot (x y : Q) (n : Nat) :
    Qeq (binTerm x y (n + 1) 0) (mul y (binTerm x y n 0)) := by
  show Qeq (mul ⟨(choose (n + 1) 0 : Int), 1⟩ (mul (qpow x 0) (qpow y (n + 1 - 0))))
    (mul y (mul ⟨(choose n 0 : Int), 1⟩ (mul (qpow x 0) (qpow y (n - 0)))))
  rw [choose_zero_right, choose_zero_right, Nat.sub_zero, Nat.sub_zero, qpow_succ]
  simp only [Qeq, mul]; push_cast; ring_uor

/-- `a + 0 ≈ a`. -/
theorem Qadd_zero_right (a : Q) : Qeq (add a ⟨0, 1⟩) a := by
  simp only [Qeq, add]; push_cast; ring_uor

/-- `a + (b + c) ≈ b + (a + c)`. -/
theorem Qadd_swap_left (a b c : Q) : Qeq (add a (add b c)) (add b (add a c)) := by
  simp only [Qeq, add]; push_cast; ring_uor

/-- Bounded congruence for `Fsum` (only needs equality up to the summation bound). -/
theorem Fsum_congr_le {f g : Nat → Q} : ∀ {k : Nat}, (∀ i, i ≤ k → Qeq (f i) (g i)) →
    Qeq (Fsum f k) (Fsum g k)
  | 0, h => h 0 (Nat.le_refl 0)
  | (k + 1), h =>
      Qadd_congr (Fsum_congr_le (fun i hik => h i (Nat.le_succ_of_le hik))) (h (k + 1) (Nat.le_refl _))

/-- **The per-term Pascal step** `binTerm (n+1) (i+1) ≈ x·binTerm n i + y·binTerm n (i+1)` (for `i ≤ n`;
    at `i = n` the second summand vanishes since `C(n,n+1) = 0`). -/
theorem binTerm_succ {x y : Q} (hxd : 0 < x.den) (hyd : 0 < y.den) (n : Nat) : ∀ {i : Nat}, i ≤ n →
    Qeq (binTerm x y (n + 1) (i + 1))
      (add (mul x (binTerm x y n i)) (mul y (binTerm x y n (i + 1)))) := by
  intro i hi
  rcases Nat.eq_or_lt_of_le hi with heq | hlt
  · -- i = n : the second summand is 0 (C(n,n+1) = 0)
    subst heq
    have htop := binTerm_top_zero x y i
    have hAB : Qeq (binTerm x y (i + 1) (i + 1)) (mul x (binTerm x y i i)) := by
      show Qeq (mul ⟨(choose (i + 1) (i + 1) : Int), 1⟩
          (mul (qpow x (i + 1)) (qpow y (i + 1 - (i + 1)))))
        (mul x (mul ⟨(choose i i : Int), 1⟩ (mul (qpow x i) (qpow y (i - i)))))
      rw [choose_self, choose_self, Nat.sub_self, Nat.sub_self, qpow_succ]
      simp only [Qeq, mul]; push_cast; ring_uor
    have hC0 : Qeq (add (mul x (binTerm x y i i)) (mul y (binTerm x y i (i + 1))))
        (mul x (binTerm x y i i)) :=
      Qeq_trans (add_den_pos (Qmul_den_pos hxd (binTerm_den_pos hxd hyd i i)) (by decide))
        (Qadd_congr (Qeq_refl (mul x (binTerm x y i i))) htop)
        (Qadd_zero_right (mul x (binTerm x y i i)))
    exact Qeq_trans (Qmul_den_pos hxd (binTerm_den_pos hxd hyd i i)) hAB (Qeq_symm hC0)
  · -- i < n : the generic Pascal identity
    show Qeq (mul ⟨(choose (n + 1) (i + 1) : Int), 1⟩ (mul (qpow x (i + 1)) (qpow y (n + 1 - (i + 1)))))
      (add (mul x (mul ⟨(choose n i : Int), 1⟩ (mul (qpow x i) (qpow y (n - i)))))
        (mul y (mul ⟨(choose n (i + 1) : Int), 1⟩ (mul (qpow x (i + 1)) (qpow y (n - (i + 1)))))))
    rw [show n + 1 - (i + 1) = n - i from by omega, choose_succ_succ, qpow_succ x i,
      show n - i = (n - (i + 1)) + 1 from by omega, qpow_succ y (n - (i + 1))]
    simp only [Qeq, mul, add]; push_cast; ring_uor

/-- **The factorial identity** `C(n,k)·k!·(n−k)! = n!` for `k ≤ n` — the divisibility heart of the
    binomial theorem. -/
theorem choose_mul_fct_mul_fct : ∀ {n k : Nat}, k ≤ n →
    choose n k * fct k * fct (n - k) = fct n
  | _, 0, _ => by simp [fct]
  | 0, (_ + 1), h => absurd h (by omega)
  | (n + 1), (k + 1), h => by
      rcases Nat.eq_or_lt_of_le (Nat.le_of_succ_le_succ h) with hkn | hkn
      · -- k = n : the corner term
        subst hkn
        rw [Nat.sub_self, choose_self]; simp [fct]
      · -- k < n : Pascal step (ℤ ring algebra via ring_uor)
        have ih1 := choose_mul_fct_mul_fct (Nat.le_of_lt hkn)
        have ih2 := choose_mul_fct_mul_fct hkn
        have hsub : n + 1 - (k + 1) = n - k := by omega
        -- cast the facts to ℤ, keeping each Nat subterm as an opaque atom
        have ih1Z : (↑(choose n k) : Int) * ↑(fct k) * ↑(fct (n - k)) = ↑(fct n) := by
          exact_mod_cast ih1
        have ih2Z : (↑(choose n (k + 1)) : Int) * ↑(fct (k + 1)) * ↑(fct (n - (k + 1))) = ↑(fct n) := by
          exact_mod_cast ih2
        have hFk1 : (↑(fct (k + 1)) : Int) = ↑(k + 1) * ↑(fct k) := by exact_mod_cast fct_succ k
        have hFnk_nat : fct (n - k) = (n - k) * fct (n - (k + 1)) := by
          rw [show n - k = (n - (k + 1)) + 1 from by omega, fct_succ]
        have hFnk : (↑(fct (n - k)) : Int) = ↑(n - k) * ↑(fct (n - (k + 1))) := by
          exact_mod_cast hFnk_nat
        have hFn1 : (↑(fct (n + 1)) : Int) = ↑(n + 1) * ↑(fct n) := by exact_mod_cast fct_succ n
        have hk1 : (↑(k + 1) : Int) + ↑(n - k) = ↑(n + 1) := by
          exact_mod_cast (show (k + 1) + (n - k) = n + 1 from by omega)
        have hterm1 : (↑(choose n k) : Int) * ↑(fct (k + 1)) * ↑(fct (n - k)) = ↑(k + 1) * ↑(fct n) := by
          rw [hFk1, ← ih1Z]; ring_uor
        have hterm2 : (↑(choose n (k + 1)) : Int) * ↑(fct (k + 1)) * ↑(fct (n - k))
            = ↑(n - k) * ↑(fct n) := by
          rw [hFnk, ← ih2Z]; ring_uor
        have keyZ : ((↑(choose n k) : Int) + ↑(choose n (k + 1))) * ↑(fct (k + 1)) * ↑(fct (n - k))
            = ↑(fct (n + 1)) :=
          calc ((↑(choose n k) : Int) + ↑(choose n (k + 1))) * ↑(fct (k + 1)) * ↑(fct (n - k))
              = (↑(choose n k) : Int) * ↑(fct (k + 1)) * ↑(fct (n - k))
                + ↑(choose n (k + 1)) * ↑(fct (k + 1)) * ↑(fct (n - k)) := by ring_uor
            _ = ↑(k + 1) * ↑(fct n) + ↑(n - k) * ↑(fct n) := by rw [hterm1, hterm2]
            _ = (↑(k + 1) + ↑(n - k)) * ↑(fct n) := by ring_uor
            _ = ↑(n + 1) * ↑(fct n) := by rw [hk1]
            _ = ↑(fct (n + 1)) := by rw [← hFn1]
        rw [hsub, choose_succ_succ]
        exact_mod_cast keyZ

/-- **The binomial theorem** `(x+y)ⁿ ≈ Σ_{i=0}^{n} C(n,i)·xⁱ·yⁿ⁻ⁱ`. -/
theorem binomial {x y : Q} (hxd : 0 < x.den) (hyd : 0 < y.den) :
    ∀ n, Qeq (qpow (add x y) n) (Fsum (binTerm x y n) n)
  | 0 => by show Qeq (⟨1, 1⟩ : Q) (mul ⟨1, 1⟩ (mul ⟨1, 1⟩ ⟨1, 1⟩)); decide
  | (n + 1) => by
      have hbtd : ∀ i, 0 < (binTerm x y n i).den := binTerm_den_pos hxd hyd n
      have hbt1 : ∀ i, 0 < (binTerm x y (n + 1) i).den := binTerm_den_pos hxd hyd (n + 1)
      have hSd : 0 < (Fsum (binTerm x y n) n).den := Fsum_den_pos hbtd n
      have hxbtd : ∀ i, 0 < (mul x (binTerm x y n i)).den := fun i => Qmul_den_pos hxd (hbtd i)
      have hybtd : ∀ i, 0 < (mul y (binTerm x y n i)).den := fun i => Qmul_den_pos hyd (hbtd i)
      -- the `mul x S` and `mul y S` denominators
      have hxSd : 0 < (mul x (Fsum (binTerm x y n) n)).den := Qmul_den_pos hxd hSd
      have hySd : 0 < (mul y (Fsum (binTerm x y n) n)).den := Qmul_den_pos hyd hSd
      -- `Σ x·binTerm n ≈ x·S` and the y-part `binTerm(n+1) 0 + Σ y·binTerm n (·+1) ≈ y·S`
      have h_x : Qeq (Fsum (fun i => mul x (binTerm x y n i)) n) (mul x (Fsum (binTerm x y n) n)) :=
        Fsum_mul_left hxd hbtd n
      have h_yfull : Qeq (Fsum (fun i => mul y (binTerm x y n i)) (n + 1)) (mul y (Fsum (binTerm x y n) n)) :=
        Qeq_trans (add_den_pos hySd (by decide))
          (Qadd_congr (Fsum_mul_left hyd hbtd n) (binTerm_top_zero x y n))
          (Qadd_zero_right (mul y (Fsum (binTerm x y n) n)))
      have h_ypart : Qeq (add (binTerm x y (n + 1) 0) (Fsum (fun i => mul y (binTerm x y n (i + 1))) n))
          (mul y (Fsum (binTerm x y n) n)) :=
        Qeq_trans (add_den_pos (hybtd 0) (Fsum_den_pos (fun i => hybtd (i + 1)) n))
          (Qadd_congr (binTerm_zero_bot x y n) (Qeq_refl _))
          (Qeq_trans (Fsum_den_pos hybtd (n + 1))
            (Qeq_symm (Fsum_front hybtd n)) h_yfull)
      -- the reindexed tail `Σ binTerm(n+1) (·+1) ≈ Σ x·binTerm n + Σ y·binTerm n (·+1)`
      have h_tail : Qeq (Fsum (fun i => binTerm x y (n + 1) (i + 1)) n)
          (add (Fsum (fun i => mul x (binTerm x y n i)) n)
            (Fsum (fun i => mul y (binTerm x y n (i + 1))) n)) :=
        Qeq_trans (Fsum_den_pos (fun i => add_den_pos (hxbtd i) (hybtd (i + 1))) n)
          (Fsum_congr_le (fun i hi => binTerm_succ hxd hyd n hi))
          (Fsum_add hxbtd (fun i => hybtd (i + 1)) n)
      -- assemble: front-peel, congr the tail, swap, then collapse each side to `· S`
      refine Qeq_trans (Qmul_den_pos (add_den_pos hxd hyd) hSd)
        (Qmul_congr (Qeq_refl (add x y)) (binomial hxd hyd n)) ?_
      -- goal: Qeq (mul (add x y) S) (Fsum (binTerm x y (n+1)) (n+1))  -- via Qeq_symm of the chain
      refine Qeq_symm (Qeq_trans (add_den_pos (hbt1 0) (Fsum_den_pos (fun i => hbt1 (i + 1)) n))
        (Fsum_front hbt1 n) ?_)
      refine Qeq_trans (add_den_pos (hbt1 0)
          (add_den_pos (Fsum_den_pos hxbtd n) (Fsum_den_pos (fun i => hybtd (i + 1)) n)))
        (Qadd_congr (Qeq_refl _) h_tail) ?_
      refine Qeq_trans (add_den_pos (Fsum_den_pos hxbtd n)
          (add_den_pos (hbt1 0) (Fsum_den_pos (fun i => hybtd (i + 1)) n)))
        (Qadd_swap_left (binTerm x y (n + 1) 0) (Fsum (fun i => mul x (binTerm x y n i)) n)
          (Fsum (fun i => mul y (binTerm x y n (i + 1))) n)) ?_
      -- goal: Qeq (add (Σ x·binTerm n) (add (binTerm(n+1) 0) (Σ y·binTerm n (·+1)))) (mul (add x y) S)
      refine Qeq_trans (add_den_pos hxSd hySd) (Qadd_congr h_x h_ypart) ?_
      -- goal: Qeq (add (mul x S) (mul y S)) (mul (add x y) S)
      exact Qeq_symm (Qmul_add_right x y (Fsum (binTerm x y n) n))

-- ===========================================================================
-- The per-degree convolution of the exponential series (the bridge to exp(x+y)=exp x·exp y).
-- ===========================================================================

/-- Per-term: `(1/k!)·binTerm k i ≈ (xⁱ/i!)·(yᵏ⁻ⁱ/(k−i)!)`, i.e. `C(k,i)/k! = 1/(i!·(k−i)!)`
    (the factorial identity, for `i ≤ k`). -/
theorem expTerm_conv_term {x y : Q} (k i : Nat) (hik : i ≤ k) :
    Qeq (mul ⟨1, fct k⟩ (binTerm x y k i)) (mul (expTerm x i) (expTerm y (k - i))) := by
  have hfidZ : (↑(fct k) : Int) = ↑(choose k i) * ↑(fct i) * ↑(fct (k - i)) := by
    exact_mod_cast (choose_mul_fct_mul_fct hik).symm
  show Qeq (mul ⟨1, fct k⟩ (mul ⟨(choose k i : Int), 1⟩ (mul (qpow x i) (qpow y (k - i)))))
    (mul (mul (qpow x i) ⟨1, fct i⟩) (mul (qpow y (k - i)) ⟨1, fct (k - i)⟩))
  simp only [Qeq, mul]
  push_cast [hfidZ]
  ring_uor

/-- **The exp convolution** `Σ_{i=0}^{k} (xⁱ/i!)·(yᵏ⁻ⁱ/(k−i)!) ≈ (x+y)ᵏ/k!` — the per-degree
    Cauchy-product identity for the exponential series. -/
theorem expTerm_conv {x y : Q} (hxd : 0 < x.den) (hyd : 0 < y.den) (k : Nat) :
    Qeq (Fsum (fun i => mul (expTerm x i) (expTerm y (k - i))) k) (expTerm (add x y) k) := by
  have hfk : 0 < fct k := fct_pos k
  have hbtd : ∀ i, 0 < (binTerm x y k i).den := binTerm_den_pos hxd hyd k
  refine Qeq_trans (Fsum_den_pos (fun i => Qmul_den_pos hfk (hbtd i)) k)
    (Qeq_symm (Fsum_congr_le (fun i hi => expTerm_conv_term k i hi))) ?_
  refine Qeq_trans (Qmul_den_pos hfk (Fsum_den_pos hbtd k)) (Fsum_mul_left hfk hbtd k) ?_
  refine Qeq_trans (Qmul_den_pos (Fsum_den_pos hbtd k) hfk)
    (Qmul_swap ⟨1, fct k⟩ (Fsum (binTerm x y k) k)) ?_
  exact Qmul_congr (Qeq_symm (binomial hxd hyd k)) (Qeq_refl (⟨1, fct k⟩ : Q))

/-- **The alternating binomial identity** `Σ_{i=0}^{n+1} C(n+1,i)·1ⁱ·(−1)ⁿ⁺¹⁻ⁱ ≈ 0` — i.e. `(1+(−1))ⁿ⁺¹ = 0`.
    (The coefficient-vanishing behind `cos² + sin² = 1`.) -/
theorem alternating_binomial (m : Nat) :
    Qeq (Fsum (binTerm ⟨1, 1⟩ ⟨-1, 1⟩ (m + 1)) (m + 1)) ⟨0, 1⟩ := by
  have hb := binomial (x := (⟨1, 1⟩ : Q)) (y := (⟨-1, 1⟩ : Q)) (by decide) (by decide) (m + 1)
  have hz : Qeq (qpow (add (⟨1, 1⟩ : Q) ⟨-1, 1⟩) (m + 1)) ⟨0, 1⟩ := by
    have hnum : (qpow (add (⟨1, 1⟩ : Q) ⟨-1, 1⟩) (m + 1)).num = 0 := qpow_zero_succ_num m
    simp only [Qeq]; rw [hnum]; simp
  exact Qeq_trans (qpow_den_pos (by decide) (m + 1)) (Qeq_symm hb) hz

/-- Associativity of `Q` addition (up to `≈`). -/
theorem Qadd_assoc3 (a b c : Q) : Qeq (add (add a b) c) (add a (add b c)) := by
  simp only [Qeq, add]; push_cast; ring_uor

/-- **Triangle reindex**: the low-triangle `Σ_{i≤M} Σ_{j≤M−i} gᵢⱼ` equals the antidiagonal form
    `Σ_{m≤M} Σ_{i≤m} gᵢ,ₘ₋ᵢ` (both are `Σ_{i+j≤M} gᵢⱼ`). Connects `Fsum_square_decomp` to the convolution. -/
theorem Fsum_triangle_reindex {g : Nat → Nat → Q} (hg : ∀ i j, 0 < (g i j).den) :
    ∀ M, Qeq (Fsum (fun i => Fsum (fun j => g i j) (M - i)) M)
      (Fsum (fun m => Fsum (fun i => g i (m - i)) m) M)
  | 0 => Qeq_refl _
  | (M + 1) => by
      have hrow : ∀ i, i ≤ M → Qeq (Fsum (fun j => g i j) (M + 1 - i))
          (add (Fsum (fun j => g i j) (M - i)) (g i (M + 1 - i))) := by
        intro i hi
        rw [show M + 1 - i = (M - i) + 1 from by omega]
        exact Qeq_refl _
      have hfirst : Qeq (Fsum (fun i => Fsum (fun j => g i j) (M + 1 - i)) M)
          (add (Fsum (fun i => Fsum (fun j => g i j) (M - i)) M)
            (Fsum (fun i => g i (M + 1 - i)) M)) :=
        Qeq_trans
          (Fsum_den_pos (fun i => add_den_pos (Fsum_den_pos (fun j => hg i j) (M - i)) (hg i (M + 1 - i))) M)
          (Fsum_congr_le hrow)
          (Fsum_add (fun i => Fsum_den_pos (fun j => hg i j) (M - i)) (fun i => hg i (M + 1 - i)) M)
      have hsub0 : M + 1 - (M + 1) = 0 := by omega
      show Qeq (add (Fsum (fun i => Fsum (fun j => g i j) (M + 1 - i)) M)
            (Fsum (fun j => g (M + 1) j) (M + 1 - (M + 1))))
        (add (Fsum (fun m => Fsum (fun i => g i (m - i)) m) M)
          (add (Fsum (fun i => g i (M + 1 - i)) M) (g (M + 1) (M + 1 - (M + 1)))))
      rw [hsub0]
      refine Qeq_trans
        (add_den_pos (add_den_pos
          (Fsum_den_pos (fun i => Fsum_den_pos (fun j => hg i j) (M - i)) M)
          (Fsum_den_pos (fun i => hg i (M + 1 - i)) M)) (Fsum_den_pos (fun j => hg (M + 1) j) 0))
        (Qadd_congr hfirst (Qeq_refl (Fsum (fun j => g (M + 1) j) 0))) ?_
      refine Qeq_trans
        (add_den_pos (add_den_pos
          (Fsum_den_pos (fun m => Fsum_den_pos (fun i => hg i (m - i)) m) M)
          (Fsum_den_pos (fun i => hg i (M + 1 - i)) M)) (Fsum_den_pos (fun j => hg (M + 1) j) 0))
        (Qadd_congr (Qadd_congr (Fsum_triangle_reindex hg M)
          (Qeq_refl (Fsum (fun i => g i (M + 1 - i)) M))) (Qeq_refl (Fsum (fun j => g (M + 1) j) 0))) ?_
      exact Qadd_assoc3 (Fsum (fun m => Fsum (fun i => g i (m - i)) m) M)
        (Fsum (fun i => g i (M + 1 - i)) M) (Fsum (fun j => g (M + 1) j) 0)

/-- **Square = low-triangle + high-corner**: split each row `i` of the `M×M` square at `j = M−i`.
    The low part is `Σ_{i+j≤M}` (the triangle); the high part is the corner `Σ_{i+j>M, j≤M}`. Exact. -/
theorem Fsum_square_decomp {g : Nat → Nat → Q} (hg : ∀ i j, 0 < (g i j).den) (M : Nat) :
    Qeq (Fsum (fun i => Fsum (fun j => g i j) M) M)
      (add (Fsum (fun i => Fsum (fun j => g i j) (M - i)) M)
        (Fsum (fun i => Qsub (Fsum (fun j => g i j) M) (Fsum (fun j => g i j) (M - i))) M)) := by
  have hlow : ∀ i, 0 < (Fsum (fun j => g i j) (M - i)).den := fun i => Fsum_den_pos (fun j => hg i j) (M - i)
  have hfull : ∀ i, 0 < (Fsum (fun j => g i j) M).den := fun i => Fsum_den_pos (fun j => hg i j) M
  have hhigh : ∀ i, 0 < (Qsub (Fsum (fun j => g i j) M) (Fsum (fun j => g i j) (M - i))).den :=
    fun i => Qsub_den_pos (hfull i) (hlow i)
  exact Qeq_trans (Fsum_den_pos (fun i => add_den_pos (hlow i) (hhigh i)) M)
    (Fsum_congr (fun i => Qeq_symm
      (Qadd_sub_cancel_left (Fsum (fun j => g i j) (M - i)) (Fsum (fun j => g i j) M))) M)
    (Fsum_add hlow hhigh M)

/-- **Fubini for finite sums**: `Σ_{i≤M} Σ_{j≤N} gᵢⱼ ≈ Σ_{j≤N} Σ_{i≤M} gᵢⱼ`. -/
theorem Fsum_swap {g : Nat → Nat → Q} (hg : ∀ i j, 0 < (g i j).den) (N : Nat) :
    ∀ M, Qeq (Fsum (fun i => Fsum (fun j => g i j) N) M)
      (Fsum (fun j => Fsum (fun i => g i j) M) N)
  | 0 => Fsum_congr (fun j => Qeq_refl (g 0 j)) N
  | (M + 1) =>
      Qeq_trans
        (add_den_pos (Fsum_den_pos (fun j => Fsum_den_pos (fun i => hg i j) M) N)
          (Fsum_den_pos (fun j => hg (M + 1) j) N))
        (Qadd_congr (Fsum_swap hg N M) (Qeq_refl (Fsum (fun j => g (M + 1) j) N)))
        (Qeq_symm (Fsum_add (fun j => Fsum_den_pos (fun i => hg i j) M) (fun j => hg (M + 1) j) N))

/-- **Range split**: `Σ_{i=0}^{K+1+d} fᵢ ≈ (Σ_{i=0}^{K} fᵢ) + (Σ_{i=0}^{d} f_{K+1+i})` — split a finite
    sum into a low block `[0,K]` and a high block `[K+1, K+1+d]` (reindexed). -/
theorem Fsum_split_add (f : Nat → Q) (hf : ∀ i, 0 < (f i).den) (K : Nat) :
    ∀ d, Qeq (Fsum f (K + 1 + d)) (add (Fsum f K) (Fsum (fun i => f (K + 1 + i)) d))
  | 0 => Qeq_refl _
  | (d + 1) => by
      show Qeq (add (Fsum f (K + 1 + d)) (f (K + 1 + (d + 1))))
        (add (Fsum f K) (add (Fsum (fun i => f (K + 1 + i)) d) (f (K + 1 + (d + 1)))))
      exact Qeq_trans
        (add_den_pos (add_den_pos (Fsum_den_pos hf K) (Fsum_den_pos (fun i => hf (K + 1 + i)) d))
          (hf (K + 1 + (d + 1))))
        (Qadd_congr (Fsum_split_add f hf K d) (Qeq_refl (f (K + 1 + (d + 1)))))
        (Qadd_assoc3 (Fsum f K) (Fsum (fun i => f (K + 1 + i)) d) (f (K + 1 + (d + 1))))

/-- Range split at the midpoint: `Σ_{i≤2K+1} fᵢ ≈ (Σ_{i≤K} fᵢ) + (Σ_{i≤K} f_{K+1+i})`. -/
theorem Fsum_split_at (f : Nat → Q) (hf : ∀ i, 0 < (f i).den) (K : Nat) :
    Qeq (Fsum f (2 * K + 1)) (add (Fsum f K) (Fsum (fun i => f (K + 1 + i)) K)) := by
  rw [show 2 * K + 1 = K + 1 + K from by omega]
  exact Fsum_split_add f hf K K

/-- A finite sum of non-negative terms grows with its length. -/
theorem Fsum_mono_len {f : Nat → Q} (hf0 : ∀ i, 0 ≤ (f i).num) (hfd : ∀ i, 0 < (f i).den)
    {M N : Nat} (hMN : M ≤ N) : Qle (Fsum f M) (Fsum f N) := by
  induction hMN with
  | refl => exact Qle_refl _
  | @step N' _ ih => exact Qle_trans (Fsum_den_pos hfd N') ih (Qle_self_add (hf0 (N' + 1)))

/-- Termwise-`≤` gives `≤` on the sums (up to the summation bound). -/
theorem Fsum_le_congr {f g : Nat → Q} :
    ∀ {k : Nat}, (∀ i, i ≤ k → Qle (f i) (g i)) → Qle (Fsum f k) (Fsum g k)
  | 0, h => h 0 (Nat.le_refl 0)
  | (k + 1), h =>
      Qadd_le_add (Fsum_le_congr (fun i hi => h i (Nat.le_succ_of_le hi))) (h (k + 1) (Nat.le_refl _))

/-- A finite sum of non-negative terms has non-negative numerator. -/
theorem Fsum_num_nonneg {f : Nat → Q} (hf0 : ∀ i, 0 ≤ (f i).num) : ∀ M, 0 ≤ (Fsum f M).num
  | 0 => hf0 0
  | (M + 1) => by
      show 0 ≤ (Fsum f M).num * ((f (M + 1)).den : Int) + (f (M + 1)).num * ((Fsum f M).den : Int)
      exact Int.add_nonneg
        (Int.mul_nonneg (Fsum_num_nonneg hf0 M) (by exact_mod_cast Nat.zero_le _))
        (Int.mul_nonneg (hf0 (M + 1)) (by exact_mod_cast Nat.zero_le _))

/-- Triangle inequality for finite sums: `|Σ fᵢ| ≤ Σ |fᵢ|`. -/
theorem Fsum_abs_le {f : Nat → Q} (hf : ∀ i, 0 < (f i).den) :
    ∀ M, Qle (Qabs (Fsum f M)) (Fsum (fun i => Qabs (f i)) M)
  | 0 => Qle_refl _
  | (M + 1) =>
      Qle_trans (add_den_pos (Qabs_den_pos (Fsum_den_pos hf M)) (Qabs_den_pos (hf (M + 1))))
        (Qabs_add_le (Fsum f M) (f (M + 1)))
        (Qadd_le_add (Fsum_abs_le hf M) (Qle_refl (Qabs (f (M + 1)))))

/-- A constant factor pulls out of a sum (on the right). -/
theorem Fsum_mul_const_right {a : Nat → Q} {c : Q} (hcd : 0 < c.den) (ha : ∀ i, 0 < (a i).den) :
    ∀ M, Qeq (mul (Fsum a M) c) (Fsum (fun i => mul (a i) c) M)
  | 0 => Qeq_refl _
  | (M + 1) =>
      Qeq_trans
        (add_den_pos (Qmul_den_pos (Fsum_den_pos ha M) hcd) (Qmul_den_pos (ha (M + 1)) hcd))
        (Qmul_add_right (Fsum a M) (a (M + 1)) c)
        (Qadd_congr (Fsum_mul_const_right hcd ha M) (Qeq_refl (mul (a (M + 1)) c)))

/-- **Product of two sums as a square double sum**: `(Σ_{i≤M} aᵢ)·(Σ_{j≤M} bⱼ) ≈ Σ_{i≤M} Σ_{j≤M} aᵢ·bⱼ`. -/
theorem Fsum_mul_square {a b : Nat → Q} (ha : ∀ i, 0 < (a i).den) (hb : ∀ j, 0 < (b j).den) (M : Nat) :
    Qeq (mul (Fsum a M) (Fsum b M)) (Fsum (fun i => Fsum (fun j => mul (a i) (b j)) M) M) :=
  Qeq_trans (Fsum_den_pos (fun i => Qmul_den_pos (ha i) (Fsum_den_pos hb M)) M)
    (Fsum_mul_const_right (Fsum_den_pos hb M) ha M)
    (Fsum_congr (fun i => Qeq_symm (Fsum_mul_left (ha i) hb M)) M)

/-- The exponential partial sum as an `Fsum` of its terms (bridge to the finite-sum library). -/
theorem expSum_eq_Fsum (q : Q) : ∀ N, Qeq (expSum q N) (Fsum (expTerm q) N)
  | 0 => by show Qeq (⟨1, 1⟩ : Q) (mul ⟨1, 1⟩ ⟨1, 1⟩); decide
  | (n + 1) => Qadd_congr (expSum_eq_Fsum q n) (Qeq_refl (expTerm q (n + 1)))

/-- **The diagonal sum of convolutions equals the `exp(x+y)` partial sum**:
    `Σ_{m=0}^{M} Σ_{i=0}^{m} (xⁱ/i!)·(yᵐ⁻ⁱ/(m−i)!) ≈ Σ_{m=0}^{M} (x+y)ᵐ/m!` — each inner convolution is the
    `m`-th term of `exp(x+y)` (`expTerm_conv`). This is the triangular part of the Cauchy product. -/
theorem Fsum_conv_expSum {x y : Q} (hxd : 0 < x.den) (hyd : 0 < y.den) (M : Nat) :
    Qeq (Fsum (fun m => Fsum (fun i => mul (expTerm x i) (expTerm y (m - i))) m) M)
      (expSum (add x y) M) :=
  Qeq_trans (Fsum_den_pos (fun m => expTerm_den_pos (add_den_pos hxd hyd) m) M)
    (Fsum_congr (fun m => expTerm_conv hxd hyd m) M)
    (Qeq_symm (expSum_eq_Fsum (add x y) M))

/-- **The square Cauchy decomposition** (generic): `(Σ_{i≤N} aᵢ)² ≈ Σ_{m≤N} (Σ_{i≤m} aᵢ·a_{m−i}) + corner`
    — the antidiagonal convolution sum plus the high corner. Generalizes `expSum_mul_eq` to any term
    sequence (used for the `cos²`/`sin²` Cauchy products). -/
theorem Fsum_sq_cauchy {a : Nat → Q} (ha : ∀ i, 0 < (a i).den) (N : Nat) :
    Qeq (mul (Fsum a N) (Fsum a N))
      (add (Fsum (fun m => Fsum (fun i => mul (a i) (a (m - i))) m) N)
        (Fsum (fun i => Qsub (Fsum (fun j => mul (a i) (a j)) N)
          (Fsum (fun j => mul (a i) (a j)) (N - i))) N)) := by
  have hg : ∀ i j, 0 < (mul (a i) (a j)).den := fun i j => Qmul_den_pos (ha i) (ha j)
  have hcorner : 0 < (Fsum (fun i => Qsub (Fsum (fun j => mul (a i) (a j)) N)
      (Fsum (fun j => mul (a i) (a j)) (N - i))) N).den :=
    Fsum_den_pos (fun i => Qsub_den_pos (Fsum_den_pos (fun j => hg i j) N)
      (Fsum_den_pos (fun j => hg i j) (N - i))) N
  refine Qeq_trans (Fsum_den_pos (fun i => Fsum_den_pos (fun j => hg i j) N) N)
    (Fsum_mul_square ha ha N) ?_
  refine Qeq_trans (add_den_pos (Fsum_den_pos (fun i => Fsum_den_pos (fun j => hg i j) (N - i)) N) hcorner)
    (Fsum_square_decomp hg N) ?_
  exact Qadd_congr (Fsum_triangle_reindex hg N) (Qeq_refl _)

/-- **The exact finite Cauchy product** `expSum x M · expSum y M ≈ expSum(x+y) M + corner`, where the
    corner is the high part `Σᵢ Σ_{M−i<j≤M} (xⁱ/i!)(yʲ/j!)`. Assembled from `Fsum_mul_square`,
    `Fsum_square_decomp`, `Fsum_triangle_reindex`, and `Fsum_conv_expSum`. -/
theorem expSum_mul_eq {x y : Q} (hxd : 0 < x.den) (hyd : 0 < y.den) (M : Nat) :
    Qeq (mul (expSum x M) (expSum y M))
      (add (expSum (add x y) M)
        (Fsum (fun i => Qsub (Fsum (fun j => mul (expTerm x i) (expTerm y j)) M)
          (Fsum (fun j => mul (expTerm x i) (expTerm y j)) (M - i))) M)) := by
  have ha : ∀ i, 0 < (expTerm x i).den := fun i => expTerm_den_pos hxd i
  have hb : ∀ j, 0 < (expTerm y j).den := fun j => expTerm_den_pos hyd j
  have hab : ∀ i j, 0 < (mul (expTerm x i) (expTerm y j)).den := fun i j => Qmul_den_pos (ha i) (hb j)
  have hcorner : 0 < (Fsum (fun i => Qsub (Fsum (fun j => mul (expTerm x i) (expTerm y j)) M)
      (Fsum (fun j => mul (expTerm x i) (expTerm y j)) (M - i))) M).den :=
    Fsum_den_pos (fun i => Qsub_den_pos (Fsum_den_pos (fun j => hab i j) M)
      (Fsum_den_pos (fun j => hab i j) (M - i))) M
  refine Qeq_trans (Qmul_den_pos (Fsum_den_pos ha M) (Fsum_den_pos hb M))
    (Qmul_congr (expSum_eq_Fsum x M) (expSum_eq_Fsum y M)) ?_
  refine Qeq_trans (Fsum_den_pos (fun i => Fsum_den_pos (fun j => hab i j) M) M)
    (Fsum_mul_square ha hb M) ?_
  refine Qeq_trans (add_den_pos (Fsum_den_pos (fun i => Fsum_den_pos (fun j => hab i j) (M - i)) M) hcorner)
    (Fsum_square_decomp hab M) ?_
  refine Qeq_trans (add_den_pos (Fsum_den_pos (fun m => Fsum_den_pos (fun i => hab i (m - i)) m) M) hcorner)
    (Qadd_congr (Fsum_triangle_reindex hab M) (Qeq_refl _)) ?_
  exact Qadd_congr (Fsum_conv_expSum hxd hyd M) (Qeq_refl _)

/-- The Cauchy-product corner factored per row: `Σᵢ (xⁱ/i!)·(Σ_{M−i<j≤M} yʲ/j!)`. -/
theorem expSum_corner_factored {x y : Q} (hxd : 0 < x.den) (hyd : 0 < y.den) (M : Nat) :
    Qeq (Fsum (fun i => Qsub (Fsum (fun j => mul (expTerm x i) (expTerm y j)) M)
          (Fsum (fun j => mul (expTerm x i) (expTerm y j)) (M - i))) M)
      (Fsum (fun i => mul (expTerm x i)
          (Qsub (Fsum (expTerm y) M) (Fsum (expTerm y) (M - i)))) M) := by
  have ha : ∀ i, 0 < (expTerm x i).den := fun i => expTerm_den_pos hxd i
  have hb : ∀ j, 0 < (expTerm y j).den := fun j => expTerm_den_pos hyd j
  refine Fsum_congr (fun i => ?_) M
  exact Qeq_trans
    (Qsub_den_pos (Qmul_den_pos (ha i) (Fsum_den_pos hb M)) (Qmul_den_pos (ha i) (Fsum_den_pos hb (M - i))))
    (QsubCongr (Fsum_mul_left (ha i) hb M) (Fsum_mul_left (ha i) hb (M - i)))
    (Qeq_symm (Qmul_sub_distrib (expTerm x i) (Fsum (expTerm y) M) (Fsum (expTerm y) (M - i))))

/-- **Square dominated by the doubled antidiagonal**: for non-negative `a, b`,
    `expSum a M · expSum b M ≤ expSum(a+b) (2M)`. Every square term `(i,j)` with `i,j ≤ M` lands in the
    antidiagonal `i+j ≤ 2M`; the extra terms are non-negative. Proved by extending each row to `2M−i`
    (`Fsum_mono_len`), then the outer sum to `2M`, then `Fsum_triangle_reindex` + `Fsum_conv_expSum`. -/
theorem expSum_mul_le {a b : Q} (ha0 : 0 ≤ a.num) (had : 0 < a.den) (hb0 : 0 ≤ b.num) (hbd : 0 < b.den)
    (M : Nat) : Qle (mul (expSum a M) (expSum b M)) (expSum (add a b) (2 * M)) := by
  have hax : ∀ i, 0 < (expTerm a i).den := fun i => expTerm_den_pos had i
  have hby : ∀ j, 0 < (expTerm b j).den := fun j => expTerm_den_pos hbd j
  have hg : ∀ i j, 0 < (mul (expTerm a i) (expTerm b j)).den := fun i j => Qmul_den_pos (hax i) (hby j)
  have hgnn : ∀ i j, 0 ≤ (mul (expTerm a i) (expTerm b j)).num := fun i j =>
    Int.mul_nonneg (expTerm_num_nonneg ha0 i) (expTerm_num_nonneg hb0 j)
  have hSQ : Qeq (mul (expSum a M) (expSum b M))
      (Fsum (fun i => Fsum (fun j => mul (expTerm a i) (expTerm b j)) M) M) :=
    Qeq_trans (Qmul_den_pos (Fsum_den_pos hax M) (Fsum_den_pos hby M))
      (Qmul_congr (expSum_eq_Fsum a M) (expSum_eq_Fsum b M))
      (Fsum_mul_square hax hby M)
  have hrows : Qle (Fsum (fun i => Fsum (fun j => mul (expTerm a i) (expTerm b j)) M) M)
      (Fsum (fun i => Fsum (fun j => mul (expTerm a i) (expTerm b j)) (2 * M - i)) M) :=
    Fsum_le_congr (fun i hi =>
      Fsum_mono_len (fun j => hgnn i j) (fun j => hg i j) (by omega))
  have houter : Qle (Fsum (fun i => Fsum (fun j => mul (expTerm a i) (expTerm b j)) (2 * M - i)) M)
      (Fsum (fun i => Fsum (fun j => mul (expTerm a i) (expTerm b j)) (2 * M - i)) (2 * M)) :=
    Fsum_mono_len (fun i => Fsum_num_nonneg (fun j => hgnn i j) (2 * M - i))
      (fun i => Fsum_den_pos (fun j => hg i j) (2 * M - i)) (by omega)
  have hmid : Qle (Fsum (fun i => Fsum (fun j => mul (expTerm a i) (expTerm b j)) M) M)
      (Fsum (fun i => Fsum (fun j => mul (expTerm a i) (expTerm b j)) (2 * M - i)) (2 * M)) :=
    Qle_trans (Fsum_den_pos (fun i => Fsum_den_pos (fun j => hg i j) (2 * M - i)) M) hrows houter
  have hTRI : Qeq (Fsum (fun i => Fsum (fun j => mul (expTerm a i) (expTerm b j)) (2 * M - i)) (2 * M))
      (expSum (add a b) (2 * M)) :=
    Qeq_trans (Fsum_den_pos (fun m => Fsum_den_pos (fun i => hg i (m - i)) m) (2 * M))
      (Fsum_triangle_reindex hg (2 * M)) (Fsum_conv_expSum had hbd (2 * M))
  exact Qle_congr_left
    (Fsum_den_pos (fun i => Fsum_den_pos (fun j => hg i j) M) M) (Qeq_symm hSQ)
    (Qle_congr_right
      (Fsum_den_pos (fun i => Fsum_den_pos (fun j => hg i j) (2 * M - i)) (2 * M)) hTRI hmid)

/-- **The Cauchy-product corner vanishes**: for `a, b ∈ [0,1]` with `a+b ≤ 1`, the corner is bounded by
    the `exp(a+b)` tail `2/(M+1)!`. Since `corner = expSum a M · expSum b M − expSum(a+b) M`
    (`expSum_mul_eq`) and `expSum a M · expSum b M ≤ expSum(a+b)(2M)` (`expSum_mul_le`), the corner is
    `≤ expSum(a+b)(2M) − expSum(a+b) M ≤ 2/(M+1)!` (`expdiff_bound`). -/
theorem expSum_corner_le {a b : Q} (ha0 : 0 ≤ a.num) (had : 0 < a.den) (hb0 : 0 ≤ b.num) (hbd : 0 < b.den)
    (hab1 : Qle (add a b) ⟨1, 1⟩) (M : Nat) :
    Qle (Fsum (fun i => Qsub (Fsum (fun j => mul (expTerm a i) (expTerm b j)) M)
          (Fsum (fun j => mul (expTerm a i) (expTerm b j)) (M - i))) M) ⟨2, fct (M + 1)⟩ := by
  have hg : ∀ i j, 0 < (mul (expTerm a i) (expTerm b j)).den :=
    fun i j => Qmul_den_pos (expTerm_den_pos had i) (expTerm_den_pos hbd j)
  have haddnn : 0 ≤ (add a b).num := by
    show 0 ≤ a.num * (b.den : Int) + b.num * (a.den : Int)
    exact Int.add_nonneg (Int.mul_nonneg ha0 (by exact_mod_cast Nat.zero_le _))
      (Int.mul_nonneg hb0 (by exact_mod_cast Nat.zero_le _))
  have hcd : 0 < (expSum (add a b) M).den := expSum_den_pos (add_den_pos had hbd) M
  have hmuld : 0 < (mul (expSum a M) (expSum b M)).den :=
    Qmul_den_pos (expSum_den_pos had M) (expSum_den_pos hbd M)
  have hcornerden : 0 < (Fsum (fun i => Qsub (Fsum (fun j => mul (expTerm a i) (expTerm b j)) M)
        (Fsum (fun j => mul (expTerm a i) (expTerm b j)) (M - i))) M).den :=
    Fsum_den_pos (fun i => Qsub_den_pos (Fsum_den_pos (fun j => hg i j) M)
      (Fsum_den_pos (fun j => hg i j) (M - i))) M
  have hco : Qeq (Qsub (mul (expSum a M) (expSum b M)) (expSum (add a b) M))
      (Fsum (fun i => Qsub (Fsum (fun j => mul (expTerm a i) (expTerm b j)) M)
          (Fsum (fun j => mul (expTerm a i) (expTerm b j)) (M - i))) M) :=
    Qeq_trans (Qsub_den_pos (add_den_pos hcd hcornerden) hcd)
      (QsubCongr (expSum_mul_eq had hbd M) (Qeq_refl (expSum (add a b) M)))
      (Qsub_add_left_cancel (expSum (add a b) M) _)
  have hbound : Qle (Qsub (mul (expSum a M) (expSum b M)) (expSum (add a b) M)) ⟨2, fct (M + 1)⟩ :=
    Qle_trans (Qsub_den_pos (expSum_den_pos (add_den_pos had hbd) (2 * M)) hcd)
      (Qsub_le_sub (expSum_mul_le ha0 had hb0 hbd M))
      (expdiff_bound haddnn (add_den_pos had hbd) hab1 (by omega : M ≤ 2 * M))
  exact Qle_congr_left (Qsub_den_pos hmuld hcd) hco hbound

end UOR.Bridge.F1Square.Analysis
