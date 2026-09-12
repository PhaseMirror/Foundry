/-!
# Custom Natural Numbers from Peano Axioms

A self-contained reconstruction of `ℕ` starting from Peano's axioms,
expressed as a concrete inductive datatype and proved entirely by
explicit induction. No use of the built-in `Nat` arithmetic library and
no mathlib: every law below is a theorem proved from the recursive
structure of the datatype.

Names avoid collision with the built-in `Nat` by living in the
`Foundations.PeanoN` namespace.
-/

namespace Foundations.PeanoN

/-- The natural numbers, built from `zero` and `succ`. -/
inductive Nat where
  | zero : Nat
  | succ : Nat → Nat

namespace Nat

/-- One is the successor of zero. -/
def one : Nat := succ zero
def two : Nat := succ one
def three : Nat := succ two
def four : Nat := succ three
def five : Nat := succ four

instance : OfNat Nat 0 := ⟨zero⟩
instance : OfNat Nat 1 := ⟨one⟩
instance : OfNat Nat 2 := ⟨two⟩
instance : OfNat Nat 3 := ⟨three⟩
instance : OfNat Nat 4 := ⟨four⟩
instance : OfNat Nat 5 := ⟨five⟩

/-! ## Peano Axioms -/

/-- **P1**: Zero is not the successor of any number. -/
theorem zero_ne_succ (n : Nat) : zero ≠ succ n := by
  intro h
  cases h

/-- **P2**: Successor is injective. -/
theorem succ_inj {m n : Nat} (h : succ m = succ n) : m = n := by
  cases h
  rfl

/-- **P5 (induction)**: The induction principle, restated in Prop form. -/
theorem induction_law (P : Nat → Prop)
    (h0 : P zero) (hS : ∀ n, P n → P (succ n)) : ∀ n, P n := by
  intro n
  induction n with
  | zero => exact h0
  | succ n ih => exact hS n ih

/-! ## Addition -/

/-- Addition, recursing on the second argument. -/
def add (m : Nat) : Nat → Nat
  | zero => m
  | succ n => succ (add m n)

instance : HAdd Nat Nat Nat := ⟨fun a b => add a b⟩

/-- `m + zero = m`. -/
theorem add_zero (m : Nat) : add m zero = m := by rfl

/-- `m + succ n = succ (m + n)`. -/
theorem add_succ (m n : Nat) : add m (succ n) = succ (add m n) := by rfl

/-- `zero + n = n`. -/
theorem zero_add (n : Nat) : add zero n = n := by
  induction n with
  | zero => rfl
  | succ n ih => calc
      add zero (succ n) = succ (add zero n) := by rfl
      _ = succ n := by rw [ih]

/-- `succ m + n = succ (m + n)`. -/
theorem succ_add (m n : Nat) : add (succ m) n = succ (add m n) := by
  induction n with
  | zero => rfl
  | succ n ih => calc
      add (succ m) (succ n) = succ (add (succ m) n) := by rfl
      _ = succ (succ (add m n)) := by rw [ih]

/-- Addition is associative. -/
theorem add_assoc (m n k : Nat) : add (add m n) k = add m (add n k) := by
  induction k with
  | zero => rfl
  | succ k ih => calc
      add (add m n) (succ k) = succ (add (add m n) k) := by rfl
      _ = succ (add m (add n k)) := by rw [ih]
      _ = add m (succ (add n k)) := by rfl
      _ = add m (add n (succ k)) := by rfl

/-- Addition is commutative. -/
theorem add_comm (m n : Nat) : add m n = add n m := by
  induction n with
  | zero =>
      symm
      exact zero_add m
  | succ n ih => calc
      add m (succ n) = succ (add m n) := by rfl
      _ = succ (add n m) := by rw [ih]
      _ = add (succ n) m := by rw [succ_add]

/-- Left cancellation for addition: `k + m = k + n → m = n`. -/
theorem add_left_cancel {m n k : Nat} (h : add k m = add k n) : m = n := by
  induction k with
  | zero =>
      rw [zero_add, zero_add] at h
      exact h
  | succ k ih =>
      rw [succ_add, succ_add] at h
      exact ih (succ_inj h)

/-- Right cancellation for addition: `m + k = n + k → m = n`. -/
theorem add_right_cancel {m n k : Nat} (h : add m k = add n k) : m = n := by
  apply add_left_cancel (k := k)
  calc
    add k m = add m k := by rw [add_comm]
    _ = add n k := h
    _ = add k n := by rw [add_comm]

/-- If the sum of two numbers is zero, both are zero. -/
theorem add_eq_zero {a b : Nat} (h : add a b = zero) : a = zero ∧ b = zero := by
  induction a with
  | zero =>
      constructor
      · rfl
      · rw [zero_add] at h
        exact h
  | succ a' =>
      rw [succ_add] at h
      exact absurd h.symm (zero_ne_succ (add a' b))

/-- `m + k = m` forces `k = zero`. -/
theorem add_eq_self_right {m k : Nat} (h : add m k = m) : k = zero := by
  have h0 : add m zero = add m k := by rw [add_zero]; exact h.symm
  have hk : zero = k := add_left_cancel (m := zero) (n := k) (k := m) h0
  exact hk.symm

/-! ## Multiplication -/

/-- Multiplication, recursing on the second argument. -/
def mul (m : Nat) : Nat → Nat
  | zero => zero
  | succ n => add (mul m n) m

/-- `m * zero = zero`. -/
theorem mul_zero (m : Nat) : mul m zero = zero := by rfl

/-- `m * succ n = m * n + m`. -/
theorem mul_succ (m n : Nat) : mul m (succ n) = add (mul m n) m := by rfl

/-- `zero * n = zero`. -/
theorem zero_mul (n : Nat) : mul zero n = zero := by
  induction n with
  | zero => rfl
  | succ n ih => calc
      mul zero (succ n) = add (mul zero n) zero := by rfl
      _ = add zero zero := by rw [ih]
      _ = zero := by rfl

/-- `one * n = n`. -/
theorem one_mul (n : Nat) : mul one n = n := by
  induction n with
  | zero => rfl
  | succ n ih => calc
      mul one (succ n) = add (mul one n) one := by rfl
      _ = add n one := by rw [ih]
      _ = succ n := by
          rw [add_comm, one, succ_add, zero_add]

/-- `succ m * n = m * n + n`. -/
theorem succ_mul (m n : Nat) : mul (succ m) n = add (mul m n) n := by
  induction n with
  | zero => rfl
  | succ n ih => calc
      mul (succ m) (succ n) = add (mul (succ m) n) (succ m) := by rfl
      _ = add (add (mul m n) n) (succ m) := by rw [ih]
      _ = add (mul m n) (add n (succ m)) := by rw [add_assoc]
      _ = succ (add (mul m n) (add m n)) := by
          rw [show add n (succ m) = succ (add m n) by
            rw [show add n (succ m) = succ (add n m) by rfl]
            rw [add_comm n m]]
          rfl
      _ = add (mul m n) (add m (succ n)) := by
          rw [show add m (succ n) = succ (add m n) by rfl]
          rfl
      _ = add (add (mul m n) m) (succ n) := by rw [← add_assoc]
      _ = add (mul m (succ n)) (succ n) := by rw [mul_succ]

/-- Commutative shift: `(a + b) + (c + d) = (a + c) + (b + d)`. -/
theorem add_add_add_comm (a b c d : Nat) :
    add (add a b) (add c d) = add (add a c) (add b d) := by
  calc
    add (add a b) (add c d) = add a (add b (add c d)) := by rw [add_assoc]
    _ = add a (add (add b c) d) := by rw [add_assoc]
    _ = add a (add (add c b) d) := by rw [add_comm b c]
    _ = add a (add c (add b d)) := by rw [add_assoc]
    _ = add (add a c) (add b d) := by rw [← add_assoc]

/-- Addition distributes over multiplication on the right: `(m + n) * k = m*k + n*k`. -/
theorem add_mul (m n k : Nat) : mul (add m n) k = add (mul m k) (mul n k) := by
  induction k with
  | zero => rfl
  | succ k ih => calc
      mul (add m n) (succ k) = add (mul (add m n) k) (add m n) := by rfl
      _ = add (add (mul m k) (mul n k)) (add m n) := by rw [ih]
      _ = add (add (mul m k) m) (add (mul n k) n) := by rw [add_add_add_comm]
      _ = add (mul m (succ k)) (mul n (succ k)) := by rw [← mul_succ, ← mul_succ]

/-- Addition distributes over multiplication on the left: `m * (a + b) = m*a + m*b`. -/
theorem mul_add (m a b : Nat) : mul m (add a b) = add (mul m a) (mul m b) := by
  induction b with
  | zero => rfl
  | succ b ih => calc
      mul m (add a (succ b)) = mul m (succ (add a b)) := by rw [add_succ]
      _ = add (mul m (add a b)) m := by rw [mul_succ]
      _ = add (add (mul m a) (mul m b)) m := by rw [ih]
      _ = add (mul m a) (add (mul m b) m) := by rw [add_assoc]
      _ = add (mul m a) (mul m (succ b)) := by rw [mul_succ]

/-- Multiplication is commutative. -/
theorem mul_comm (m n : Nat) : mul m n = mul n m := by
  induction n with
  | zero =>
      rw [mul_zero, zero_mul]
  | succ n ih => calc
      mul m (succ n) = add (mul m n) m := by rfl
      _ = add (mul n m) m := by rw [ih]
      _ = mul (succ n) m := by rw [← succ_mul]

/-- Multiplication is associative. -/
theorem mul_assoc (m n k : Nat) : mul (mul m n) k = mul m (mul n k) := by
  induction k with
  | zero => rfl
  | succ k ih => calc
      mul (mul m n) (succ k) = add (mul (mul m n) k) (mul m n) := by rfl
      _ = add (mul m (mul n k)) (mul m n) := by rw [ih]
      _ = mul m (add (mul n k) n) := by rw [mul_add]
      _ = mul m (mul n (succ k)) := by rw [mul_succ]

/-! ## Ordering -/

/-- `m ≤ n` means `n` is reachable by adding to `m`. -/
def Le (m n : Nat) : Prop := ∃ k, add m k = n

/-- `m < n` means `succ m ≤ n`. -/
def Lt (m n : Nat) : Prop := Le (succ m) n

/-- Reflexivity of `≤`. -/
theorem le_refl (m : Nat) : Le m m := ⟨zero, by rfl⟩

/-- Transitivity of `≤`. -/
theorem le_trans {a b c : Nat} (h1 : Le a b) (h2 : Le b c) : Le a c := by
  rcases h1 with ⟨k, hk⟩
  rcases h2 with ⟨l, hl⟩
  refine ⟨add k l, ?_⟩
  calc
    add a (add k l) = add (add a k) l := by rw [add_assoc]
    _ = add b l := by rw [hk]
    _ = c := hl

/-- `0 ≤ n` for all `n`. -/
theorem zero_le (n : Nat) : Le zero n := ⟨n, by rw [zero_add]⟩

/-- `m ≤ n` implies `succ m ≤ succ n`, and conversely. -/
theorem le_succ_succ {m n : Nat} (h : Le m n) : Le (succ m) (succ n) := by
  rcases h with ⟨k, hk⟩
  refine ⟨k, ?_⟩
  calc
    add (succ m) k = succ (add m k) := by rw [succ_add]
    _ = succ n := by rw [hk]

/-- `m < n` implies `m ≤ n`. -/
theorem le_of_lt {m n : Nat} (h : Lt m n) : Le m n := by
  rcases h with ⟨k, hk⟩
  refine ⟨succ k, ?_⟩
  calc
    add m (succ k) = succ (add m k) := by rfl
    _ = add (succ m) k := by rw [succ_add]
    _ = n := hk

/-- `m ≤ b` implies `m ≤ succ b`. -/
theorem le_succ_of_le {m b : Nat} (h : Le m b) : Le m (succ b) := by
  rcases h with ⟨k, hk⟩
  refine ⟨succ k, ?_⟩
  calc
    add m (succ k) = succ (add m k) := by rfl
    _ = succ b := by rw [hk]

/-- `m < succ m`. -/
theorem lt_succ_self (m : Nat) : Lt m (succ m) := by
  unfold Lt Le
  exact ⟨zero, by rfl⟩

/-- `Le` is antisymmetric. -/
theorem le_antisymm {m n : Nat} (h1 : Le m n) (h2 : Le n m) : m = n := by
  rcases h1 with ⟨k, hk⟩
  rcases h2 with ⟨l, hl⟩
  have this_add : add m (add k l) = m := by
    calc
      add m (add k l) = add (add m k) l := by rw [add_assoc]
      _ = add n l := by rw [hk]
      _ = m := hl
  have hkl : add k l = zero := add_eq_self_right this_add
  have hk0 : k = zero := (add_eq_zero (a := k) (b := l) hkl).1
  have : add m zero = n := by
    calc
      add m zero = add m k := by rw [← hk0]
      _ = n := hk
  simpa [add] using this

/-- If `n ≤ 0` then `n = 0`. -/
theorem le_zero {n : Nat} (h : Le n zero) : n = zero := by
  rcases h with ⟨k, hk⟩
  have hkz : add n k = zero := by simpa [add] using hk
  exact (add_eq_zero (a := n) (b := k) hkz).1

/-- `succ m ≰ 0`. -/
theorem not_succ_le_zero (m : Nat) : ¬ Le (succ m) zero := by
  intro h
  rcases h with ⟨k, hk⟩
  have hkz : add (succ m) k = zero := by simpa [add] using hk
  have hs : succ m = zero := (add_eq_zero (a := succ m) (b := k) hkz).1
  exact absurd hs.symm (zero_ne_succ m)

/-- `Le` is total: for any `m n`, `m ≤ n ∨ n ≤ m`. -/
theorem le_total (m n : Nat) : Le m n ∨ Le n m := by
  induction m generalizing n with
  | zero => exact Or.inl (zero_le n)
  | succ m ih =>
      induction n with
      | zero => exact Or.inr (zero_le (succ m))
      | succ n ih_n =>
          rcases ih n with h1 | h2
          · left
            exact le_succ_succ h1
          · right
            exact le_succ_succ h2

end Nat

end Foundations.PeanoN
