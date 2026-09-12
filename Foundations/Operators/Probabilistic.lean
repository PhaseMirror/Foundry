/-!
# Foundations.Operators.Probabilistic — Discrete Rational Probability Distributions

Formalizes discrete Bernoulli, 4-state uniform distributions, expectation operators,
and rational approximations for Gaussian and Poisson weights.
-/

namespace Foundations.Operators.Probabilistic

/-- Bernoulli distribution with parameter $p$: $P(0) = 1-p, P(1) = p$. -/
def bernoulli (p : Rat) (i : Fin 2) : Rat :=
  if i.val == 0 then 1 - p else p

/-- Theorem: Fair coin tails probability is 1/2. -/
theorem fair_coin_bernoulli_tails :
    bernoulli (1/2 : Rat) ⟨1, by omega⟩ = 1/2 := by
  native_decide

/-- Concrete 4-state distribution. -/
structure Dist4 where
  p₀    : Rat
  p₁    : Rat
  p₂    : Rat
  p₃    : Rat
  h_sum : p₀ + p₁ + p₂ + p₃ = 1

/-- Uniform distribution over 4 states: $p_i = 1/4$. -/
def dist4_uniform : Dist4 :=
  { p₀ := 1/4
    p₁ := 1/4
    p₂ := 1/4
    p₃ := 1/4
    h_sum := by native_decide }

/-- Expectation of $f$ under `Dist4`: $\mathbb{E}[f] = \sum_i p_i f(i)$. -/
def dist4_expect (d : Dist4) (f : Fin 4 → Rat) : Rat :=
  d.p₀ * f ⟨0, by omega⟩ + d.p₁ * f ⟨1, by omega⟩ +
  d.p₂ * f ⟨2, by omega⟩ + d.p₃ * f ⟨3, by omega⟩

/-- Theorem: Expectation of constant 1 under uniform distribution is 1. -/
theorem dist4_uniform_expect_one :
    dist4_expect dist4_uniform (fun _ => 1) = 1 := by
  native_decide

/-- 2-state expectation: $\mathbb{E}[X] = p_0 x_0 + p_1 x_1$. -/
def expectation2 (p₀ p₁ x₀ x₁ : Rat) : Rat :=
  p₀ * x₀ + p₁ * x₁

/-- Discrete Gaussian weight at point $k$: $w(k) = 1 - (k - \mu)^2 / (2\sigma^2)$. -/
def gaussian_weight (μ σ_sq : Rat) (k : Rat) : Rat :=
  1 - (k - μ) ^ 2 / (2 * σ_sq)

/-- Theorem: Gaussian weight at mean is 1. -/
theorem gaussian_at_mean :
    gaussian_weight 0 1 0 = 1 := by
  native_decide

/-- Theorem: Gaussian weight at $k=1$ is $1/2$. -/
theorem gaussian_one :
    gaussian_weight 0 1 1 = (1/2 : Rat) := by
  native_decide

/-- Poisson weight approximation. -/
def poisson_weight (lam : Rat) : Nat → Rat
  | 0 => 1 - lam
  | Nat.succ k => lam * poisson_weight lam k / (k + 2 : Rat)

/-- Theorem: Poisson weight at zero is $1 - \lambda$. -/
theorem poisson_zero (lam : Rat) : poisson_weight lam 0 = 1 - lam := rfl

end Foundations.Operators.Probabilistic
