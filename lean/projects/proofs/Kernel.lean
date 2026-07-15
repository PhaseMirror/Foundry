/-!
# Projects.Kernel — No-Mathlib Proof Toolkit

This module is the shared, dependency-free foundation for every project formalization
under `proofs/`. It deliberately imports **nothing** from `Mathlib` (or any external
math library). All reasoning is over discrete types:

- `Nat`, `Int`, `Bool` for scaled-integer arithmetic (micro-units replace reals),
- `List` for collections and finite sums,
- `Fin n → Fin m → α` for small matrices / tensors,
- `Prop` for logical invariants.

## Rust / Kani replacement for `Mathlib`

Where a project needs genuine real / floating-point analysis (e.g. spectral radii,
ODE contractivity, zeta regularization), the *continuous* claim is certified by a
**Kani** Rust harness and surfaced here as an `axiom`/`constant` with a precise
specification (see `proofs/Kani.lean`). The Lean side proves the discrete invariant
that the Kani proof guarantees. This is the disciplined, auditable substitute for
pulling in a real-analysis library.

## Discipline

No `sorry`, no `admit`. Every `theorem` below has a complete proof using only the
core tactic set (`simp`, `omega`, `decide`, `induction`, `cases`, `refl`, `rw`).
-/
namespace proofs.Kernel

/-! ## Scaled-integer (micro-unit) arithmetic -/

/-- Micro-unit scale: 1 real unit = `Scale` discrete units. -/
def Scale : Nat := 1_000_000

/-- Map `num / den` (with `den ≠ 0`) to scaled micro-units. -/
def toScaled (num den : Nat) : Nat := (num * Scale) / den

/-- Saturate `x` to the closed interval `[0, cap]`. -/
def saturate (x cap : Nat) : Nat := if x ≤ cap then x else cap

theorem saturate_le (x cap : Nat) : saturate x cap ≤ cap := by
  unfold saturate
  split
  · assumption
  · exact Nat.le_refl cap

theorem saturate_of_le (x cap : Nat) (h : x ≤ cap) : saturate x cap = x := by
  unfold saturate
  simp [h]

/-- Clamp `x` to `[lo, hi]` (assuming `lo ≤ hi`). -/
def clamp (x lo hi : Nat) : Nat :=
  if x < lo then lo else if x > hi then hi else x

theorem clamp_lo (x lo hi : Nat) (h : lo ≤ hi) : lo ≤ clamp x lo hi := by
  unfold clamp
  by_cases h1 : x < lo <;> by_cases h2 : x > hi <;> simp [h1, h2] <;> omega

theorem clamp_hi (x lo hi : Nat) (h : lo ≤ hi) : clamp x lo hi ≤ hi := by
  unfold clamp
  by_cases h1 : x < lo <;> by_cases h2 : x > hi <;> simp [h1, h2] <;> omega

theorem clamp_fixes (x lo hi : Nat) (hlo : lo ≤ x) (hhi : x ≤ hi) :
    clamp x lo hi = x := by
  unfold clamp
  by_cases h1 : x < lo
  · exact False.elim (Nat.lt_irrefl x (Nat.lt_of_lt_of_le h1 hlo))
  · by_cases h2 : x > hi
    · exact False.elim (Nat.lt_irrefl hi (Nat.lt_of_lt_of_le h2 hhi))
    · simp [h1, h2]

/-! ## Primes -/

/-- Integer square root via binary search (logarithmic depth, `decide`-friendly). -/
def isqrt (n : Nat) : Nat :=
  let rec go (lo hi : Nat) : Nat :=
    if hi ≤ lo + 1 then lo
    else
      let mid := lo + (hi - lo) / 2
      if mid * mid ≤ n then go mid hi else go lo mid
  go 0 (n + 1)

/-- `divides a b` iff `a` is a non-zero divisor of `b`. -/
def divides (a b : Nat) : Bool := a ≠ 0 && b % a == 0

/-- Miller-style trial predicate: `n` has no divisor `d` with `2 ≤ d ≤ √n`. -/
def isPrime (n : Nat) : Bool :=
  if n < 2 then false
  else
    let lim := isqrt n + 1
    List.all (List.range lim) (fun d => d < 2 || !divides d n)

/-- A prime is at least 2. -/
theorem isPrime_ge_two (n : Nat) (h : isPrime n = true) : 2 ≤ n := by
  unfold isPrime at h
  by_cases hn : n < 2
  · simp [hn] at h
  · simp at hn
    exact hn

/-- `Mersenne n := 2^n - 1`. -/
def mersenne (n : Nat) : Nat := 2^n - 1

theorem mersenne_pos (n : Nat) (h : 1 ≤ n) : 0 < mersenne n := by
  unfold mersenne
  have : 1 < 2^n := by
    cases n with
    | zero => simp_all
    | succ m =>
      have : 1 < 2^m * 2 := by
        rw [Nat.mul_comm (2^m) 2]
        exact Nat.lt_of_lt_of_le (Nat.lt_succ_self 1) (Nat.mul_le_mul_left 2 (Nat.pow_pos (Nat.zero_lt_succ 1)))
      omega
  omega

/-! ## Finite matrices (functions `Fin m → Fin n → α`) -/

/-- An `m × n` matrix over `α` is a function of two finite indices. -/
def Matrix (m n : Nat) (α : Type) : Type := Fin m → Fin n → α

/-- Identity matrix of size `n`. -/
def Matrix.id (n : Nat) {α : Type} [One α] [Zero α] : Matrix n n α :=
  fun i j => if i = j then 1 else 0

/-! ## Lists / finite sums -/

/-- Sum of a list of naturals. -/
def lsum : List Nat → Nat := List.sum

theorem lsum_append (xs ys : List Nat) :
    lsum (xs ++ ys) = lsum xs + lsum ys := by
  simp [lsum, List.sum_append]

theorem lsum_cons (x : Nat) (xs : List Nat) :
    lsum (x :: xs) = x + lsum xs := by simp [lsum]

theorem lsum_nonneg (xs : List Nat) : 0 ≤ lsum xs := by
  simp [lsum]

/-! ## Metric spaces over `Nat` (discrete line) -/

/-- Distance on the natural line, `|a - b|`, expressed without `Int` sign. -/
def natDist (a b : Nat) : Nat := Nat.max a b - Nat.min a b

/-- The discrete line distance is symmetric. -/
theorem natDist_symm (a b : Nat) : natDist a b = natDist b a := by
  unfold natDist
  simp only [Nat.max_comm, Nat.min_comm]

/-- Self-distance is zero. -/
theorem natDist_self (a : Nat) : natDist a a = 0 := by
  unfold natDist
  simp only [Nat.max_self, Nat.min_self, Nat.sub_self]

end proofs.Kernel
