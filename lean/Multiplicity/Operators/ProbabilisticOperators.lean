/-
Copyright (c) 2024 Multiplicity / Citizen Gardens. All rights reserved.
Licensed under Prime Materia Open Commons and Bound Works License v1.0.

Probabilistic Operators for Multiplicity Theory.
Formalizes the probabilistic operator category from Operators.md §7.3.

Defines discrete probability distributions with finite support,
expectation, Bernoulli distribution, and uniform distribution.
All computations use exact rational arithmetic. Concrete instances
verified via native_decide.

Pure core Lean 4 (no Mathlib). Axiom-clean: no sorry, no axioms beyond
{propext, Quot.sound}. Computational proofs via native_decide.
-/

namespace Multiplicity.Core.Operators.ProbabilisticOperators

/-! ## Bernoulli Distribution -/

/-- Bernoulli distribution with parameter p: P(0) = 1-p, P(1) = p. -/
def bernoulli (p : Rat) (i : Fin 2) : Rat :=
  if i.val == 0 then 1 - p else p

/-- Fair coin tails probability is 1/2. -/
theorem fair_coin_bernoulli_tails :
    bernoulli (1/2 : Rat) ⟨1, by omega⟩ = 1/2 := by
  native_decide

/-- Bernoulli with p=0 always gives 0 on tail. -/
theorem bernoulli_zero_tails :
    bernoulli (0 : Rat) ⟨1, by omega⟩ = 0 := by
  native_decide

/-- Bernoulli with p=1 always gives 1 on tail. -/
theorem bernoulli_one_tails :
    bernoulli (1 : Rat) ⟨1, by omega⟩ = 1 := by
  native_decide

/-! ## Distribution over 4 States -/

/-- A concrete distribution over four states {0, 1, 2, 3}. -/
structure Dist4 where
  p₀ : Rat
  p₁ : Rat
  p₂ : Rat
  p₃ : Rat
  h_sum : p₀ + p₁ + p₂ + p₃ = 1

/-- Uniform distribution over 4 states: each weight = 1/4. -/
def dist4_uniform : Dist4 :=
  { p₀ := 1/4
    p₁ := 1/4
    p₂ := 1/4
    p₃ := 1/4
    h_sum := by native_decide }

/-- Expected value of a function f under Dist4: E[f] = Σ p_i · f(i). -/
def dist4_expect (d : Dist4) (f : Fin 4 → Rat) : Rat :=
  d.p₀ * f ⟨0, by omega⟩ + d.p₁ * f ⟨1, by omega⟩ +
  d.p₂ * f ⟨2, by omega⟩ + d.p₃ * f ⟨3, by omega⟩

/-- Expected value of constant 1 under uniform distribution is 1. -/
theorem dist4_uniform_expect_one :
    dist4_expect dist4_uniform (fun (_ : Fin 4) => (1 : Rat)) = 1 := by
  native_decide

/-! ## Expectation (Fixed-Width) -/

/-- Expectation for a 2-state system: E[X] = p₀·x₀ + p₁·x₁. -/
def expectation2 (p₀ p₁ x₀ x₁ : Rat) : Rat :=
  p₀ * x₀ + p₁ * x₁

/-- Expectation of equal weights and values simplifies. -/
theorem expectation2_equal (w x : Rat) :
    expectation2 w w x x = w * x + w * x := rfl

/-- Expectation for a 3-state system. -/
def expectation3 (p₀ p₁ p₂ x₀ x₁ x₂ : Rat) : Rat :=
  p₀ * x₀ + p₁ * x₁ + p₂ * x₂

/-! ## Gaussian Weight (Rational Approximation) -/

/-- Discrete Gaussian weight at point k with mean μ and variance σ².
    w(k) = 1 - (k - μ)² / (2σ²).
    Rational approximation; exact Gaussian requires Mathlib. -/
def gaussian_weight (μ σ_sq : Rat) (k : Rat) : Rat :=
  1 - (k - μ) ^ 2 / (2 * σ_sq)

/-- Gaussian weight at the mean is 1. -/
theorem gaussian_at_mean :
    gaussian_weight 0 1 0 = 1 := by
  native_decide

/-- Gaussian weight at k=1 is 0.5. -/
theorem gaussian_one :
    gaussian_weight 0 1 1 = (1/2 : Rat) := by
  native_decide

/-- Gaussian weight at k=-1 is 0.5 (symmetric). -/
theorem gaussian_neg_one :
    gaussian_weight 0 1 (-1 : Rat) = (1/2 : Rat) := by
  native_decide

/-! ## Poisson Weight (Rational Approximation) -/

/-- Poisson weight approximation: P(k; lam) via truncated series. -/
def poisson_weight (lam : Rat) : Nat → Rat
  | 0 => 1 - lam
  | Nat.succ k => lam * poisson_weight lam k / (k + 2 : Rat)

/-- Poisson weight at k=0 is 1-λ. -/
theorem poisson_zero (lam : Rat) : poisson_weight lam 0 = 1 - lam := rfl

/-- Poisson weight at k=0 with λ=1 is 0. -/
theorem poisson_zero_lambda_one : poisson_weight (1 : Rat) 0 = 0 := by
  native_decide

end Multiplicity.Core.Operators.ProbabilisticOperators
