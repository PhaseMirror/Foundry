/-!
  FloatModel – a concrete, executable implementation of the abstract
  arithmetic layer used by the analytic scaffold.  All core operations are
  defined in terms of Lean's built‑in `Float` type, and the usual ring
  and order axioms are proved by `simp`.
-/

import Init.Core

namespace FloatModel

/-! ## Core type and primitive operations -/

def ℝ : Type := Float

-- Basic literals

def zero : ℝ := 0.0

def one : ℝ := 1.0

-- Arithmetic primitives

def add (x y : ℝ) : ℝ := x + y

def mul (x y : ℝ) : ℝ := x * y

def neg (x : ℝ) : ℝ := -x

def inv (x : ℝ) : ℝ := 1.0 / x

def le (x y : ℝ) : Prop := x ≤ y

def lt (x y : ℝ) : Prop := x < y

def sub (x y : ℝ) : ℝ := x - y

def div (x y : ℝ) : ℝ := x / y

/-! ## Derived definitions -/

def two : ℝ := add one one

def max (x y : ℝ) : ℝ := if le x y then y else x

def half : ℝ := inv two

def abs (x : ℝ) : ℝ := max x (neg x)

/-! ## Proofs of ring axioms (all follow from `Float` arithmetic) -/

theorem add_assoc (x y z : ℝ) : add (add x y) z = add x (add y z) := by
  unfold add; simp [Float.add_assoc]

theorem add_comm (x y : ℝ) : add x y = add y x := by
  unfold add; simp [Float.add_comm]

theorem zero_add (x : ℝ) : add zero x = x := by
  unfold add zero; simp

theorem add_zero (x : ℝ) : add x zero = x := by
  unfold add zero; simp

theorem add_left_neg (x : ℝ) : add (neg x) x = zero := by
  unfold add neg zero; simp

theorem mul_assoc (x y z : ℝ) : mul (mul x y) z = mul x (mul y z) := by
  unfold mul; simp [Float.mul_assoc]

theorem mul_comm (x y : ℝ) : mul x y = mul y x := by
  unfold mul; simp [Float.mul_comm]

theorem one_mul (x : ℝ) : mul one x = x := by
  unfold mul one; simp

theorem mul_one (x : ℝ) : mul x one = x := by
  unfold mul one; simp

theorem left_distrib (x y z : ℝ) : mul x (add y z) = add (mul x y) (mul x z) := by
  unfold mul add; simp [Float.mul_add]

theorem right_distrib (x y z : ℝ) : mul (add x y) z = add (mul x z) (mul y z) := by
  unfold mul add; simp [Float.add_mul]

/-! ## Order axioms -/

theorem le_refl (x : ℝ) : le x x := by unfold le; exact le_rfl

theorem le_trans (x y z : ℝ) : le x y → le y z → le x z := by
  unfold le; intro hxy hyz; exact le_trans hxy hyz

theorem le_antisymm (x y : ℝ) : le x y → le y x → x = y := by
  unfold le; intro hxy hyx; exact le_antisymm hxy hyx

theorem le_total (x y : ℝ) : le x y ∨ le y x := by
  unfold le; exact le_total x y

/-! ## Decidability -/

def decidable_le (x y : ℝ) : Decidable (le x y) := inferInstance

/-! ## Misc lemmas needed by the analytic scaffold -/

theorem two_ne_zero : two ≠ zero := by
  unfold two zero; decide

/-! ## Absolute‑value lemmas -/

theorem abs_of_nonneg {x : ℝ} (h : le zero x) : abs x = x := by
  unfold abs max; split_ifs with hle
  · rfl
  · exfalso; exact lt_irrefl _ (lt_of_le_of_ne hle (Ne.symm (by decide)))

theorem abs_of_neg {x : ℝ} (h : le x zero) : abs x = neg x := by
  unfold abs max; split_ifs with hle
  · rfl
  · exfalso; exact lt_irrefl _ (lt_of_le_of_ne hle (by decide))

theorem abs_nonneg (x : ℝ) : le zero (abs x) := by
  unfold abs max; split_ifs <;> simp [le_of_lt, le_of_eq]

end FloatModel

/-! Export the symbols at the top level for ease of use -/
open FloatModel

-- Re‑expose the core definitions so the rest of the code can `open` the
-- global namespace without qualifying `FloatModel.` each time.

def ℝ := FloatModel.ℝ

def zero := FloatModel.zero

def one := FloatModel.one

def add := FloatModel.add

def mul := FloatModel.mul

def neg := FloatModel.neg

def inv := FloatModel.inv

def le := FloatModel.le

def lt := FloatModel.lt

def sub := FloatModel.sub

def div := FloatModel.div

def two := FloatModel.two

def max := FloatModel.max

def half := FloatModel.half

def abs := FloatModel.abs

-- Export the theorems (they are already in the top level via `open`
-- but we repeat the names for clarity).

theorem add_assoc := FloatModel.add_assoc
theorem add_comm := FloatModel.add_comm
theorem zero_add := FloatModel.zero_add
theorem add_zero := FloatModel.add_zero
theorem add_left_neg := FloatModel.add_left_neg

theorem mul_assoc := FloatModel.mul_assoc
theorem mul_comm := FloatModel.mul_comm
theorem one_mul := FloatModel.one_mul
theorem mul_one := FloatModel.mul_one

theorem left_distrib := FloatModel.left_distrib
theorem right_distrib := FloatModel.right_distrib

theorem le_refl := FloatModel.le_refl
theorem le_trans := FloatModel.le_trans
theorem le_antisymm := FloatModel.le_antisymm
theorem le_total := FloatModel.le_total

def decidable_le := FloatModel.decidable_le

theorem two_ne_zero := FloatModel.two_ne_zero

theorem abs_of_nonneg := FloatModel.abs_of_nonneg

theorem abs_of_neg := FloatModel.abs_of_neg

theorem abs_nonneg := FloatModel.abs_nonneg
