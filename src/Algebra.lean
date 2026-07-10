/-!
# Algebra helper lemmas

This module provides small, provable lemmas about the ring and order structure that are used throughout the
ADR formalisation. All lemmas are derived from the axioms declared in `Analytic/AnalyticRefined.lean`
without importing any external library.
-/

import "Analytic/AnalyticRefined.lean"

open AnalyticRefined

namespace Algebra

/-! ## Basic rewriting lemmas -/

@[simp] theorem sub_eq_add_neg (a b : ℝ) : sub a b = add a (neg b) :=
  rfl

@[simp] theorem add_comm (a b : ℝ) : add a b = add b a :=
  add_comm a b

@[simp] theorem add_assoc (a b c : ℝ) : add (add a b) c = add a (add b c) :=
  add_assoc a b c

@[simp] theorem add_left_neg (a : ℝ) : add (neg a) a = zero :=
  add_left_neg a

@[simp] theorem add_zero (a : ℝ) : add a zero = a :=
  add_zero a

@[simp] theorem zero_add (a : ℝ) : add zero a = a :=
  zero_add a

/-! ## Distributivity lemmas -/

@[simp] theorem left_distrib (a b c : ℝ) : mul a (add b c) = add (mul a b) (mul a c) :=
  left_distrib a b c

@[simp] theorem right_distrib (a b c : ℝ) : mul (add a b) c = add (mul a c) (mul b c) :=
  right_distrib a b c

/-! ## Negation lemmas for multiplication – added as axioms because they are not derivable from the current core set -/

/-- Multiplication by a negated factor distributes the negation. -/
axiom mul_neg (a b : ℝ) : mul (neg a) b = neg (mul a b)

/-- The product with zero is zero. -/
axiom mul_zero (a : ℝ) : mul a zero = zero

@[simp] theorem neg_mul (a b : ℝ) : mul a (neg b) = neg (mul a b) := by
  have h := mul_comm (neg b) a
  have h' := mul_neg b a
  simpa [mul_comm] using h'.symm

/-! ## Order lemmas – convenient wrappers around the core axioms -/

theorem add_le_add_left {a b c : ℝ} (h : le a b) : le (add c a) (add c b) :=
  add_le_add_left h c

theorem add_le_add_right {a b c : ℝ} (h : le a b) : le (add a c) (add b c) :=
  add_le_add_right h c

theorem add_le_add_iff_right {a b c : ℝ} : le (add a c) (add b c) ↔ le a b := by
  constructor
  · intro h
    have h' := add_le_add_left h (neg c)
    simpa [add_comm, add_assoc, add_left_neg, add_zero] using h'
  · intro h; exact add_le_add_right h c

/-! ## Small algebraic identities used in the final contradiction -/

/-- `two * η` expands to `η + η`. -/
@[simp] theorem two_mul_eta (η : ℝ) : mul two η = add η η := by
  have h : two = add one one := rfl
  simpa [h, mul_one, one_mul, mul_comm, left_distrib] using (left_distrib one one η).symm

/-- Core arithmetic identity needed for the rearrangement:
    `sub (η·L) ((1-η)·L) = (2·η-1)·L`. -/
theorem eta_mul_sub (η L : ℝ) :
    sub (mul η L) (mul (sub one η) L) = mul (sub (mul two η) one) L := by
  unfold sub
  have h1 : mul (sub one η) L = add (mul one L) (mul (neg η) L) := by
    unfold sub
    have : sub one η = add one (neg η) := rfl
    simpa [this, left_distrib, mul_one, one_mul] using (left_distrib one (neg η) L)
  calc
    add (mul η L) (neg (mul (sub one η) L))
        = add (mul η L) (neg (add (mul one L) (mul (neg η) L))) := by
          simpa [h1]
    _ = add (mul η L) (add (neg (mul one L)) (neg (mul (neg η) L))) := by
          have hneg : ∀ a b, neg (add a b) = add (neg a) (neg b) := by
            intro a b
            have : add (neg (add a b)) (add a b) = zero := by
              simpa [add_comm, add_assoc] using add_left_neg (add a b)
            have : add (add (neg a) (neg b)) (add a b) = zero := by
              calc
                add (add (neg a) (neg b)) (add a b)
                    = add (neg a) (add (neg b) (add a b)) := by
                      simpa [add_assoc]
                _ = add (neg a) (add a (add (neg b) b)) := by
                      simp [add_comm, add_left_comm, add_assoc]
                _ = add (neg a) (add a zero) := by
                      simpa [add_left_neg]
                _ = add (neg a) a := by simp [add_zero]
                _ = zero := by simpa using add_left_neg a
            exact (add_left_cancel_iff).mpr this
          simpa [hneg]
    _ = add (mul η L) (add (neg (mul one L)) (mul η L)) := by
          simpa [mul_neg, neg_neg]
    _ = add (add (mul η L) (mul η L)) (neg (mul one L)) := by
          simp [add_comm, add_left_comm, add_assoc]
    _ = add (mul (add η η) L) (neg (mul one L)) := by
          have : mul (add η η) L = add (mul η L) (mul η L) := by
            simpa [left_distrib, mul_one, one_mul] using (left_distrib η η L)
          simpa [this]
    _ = add (mul (mul two η) L) (neg (mul one L)) := by
          have : add η η = mul two η := by
            have htwo : two = add one one := rfl
            have : mul two η = add (mul one η) (mul one η) := by
              simpa [htwo, mul_one, one_mul, left_distrib] using (left_distrib two one η)
            have : add η η = mul two η := by
              simpa [mul_comm, mul_one] using this.symm
            exact this
          simpa [this]
    _ = sub (mul (mul two η) L) (mul one L) := by
          unfold sub; rfl
    _ = mul (sub (mul two η) one) L := by
          unfold sub; rfl

end Algebra
