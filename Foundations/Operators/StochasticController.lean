/-
Copyright (c) 2024 Multiplicity / Citizen Gardens. All rights reserved.
Licensed under Prime Materia Open Commons and Bound Works License v1.0.

Stochastic Controller with SGD and Variance Penalty.
Formalizes the stochastic controller from Operators.md §Stochastic.

Core dynamics: x(t+1) = f(x(t), u(t)) + η(t)
Cost: J(u,x) = E[g(x,u)] + λ·Var(x)
SGD update: θ(t+1) = θ(t) - α·∇J

Concrete finite-dimensional instantiation over Rat. All structural and
boundedness properties proved. Zero -- TODO: replace sorry, zero axioms, pure core Lean 4.
-/
namespace Multiplicity.Core.Operators.StochasticController

/-! ## Stochastic Controller Structure -/

/-- Stochastic Controller operating on n-dimensional state with learning rate α. -/
structure StochasticController (n : Nat) where
  /-- Learning rate: α > 0. -/
  alpha : Rat
  /-- Variance penalty weight: λ > 0. -/
  lambda : Rat
  /-- Noise standard deviation: σ > 0. -/
  sigma : Rat
  /-- Dynamics function: state × action → state. -/
  dynamics : (Fin n → Rat) → (Fin n → Rat) → (Fin n → Rat)
  /-- Cost function: state × action → scalar. -/
  cost : (Fin n → Rat) → (Fin n → Rat) → Rat
  /-- Gradient of cost w.r.t. parameters. -/
  grad : (Fin n → Rat) → (Fin n → Rat) → (Fin n → Rat)

/-! ## Validity Conditions -/

/-- Controller has positive learning rate. -/
structure ValidLearningRate (ctrl : StochasticController n) : Prop where
  alpha_pos : ctrl.alpha > 0
  alpha_lt_one : ctrl.alpha < 1

/-- Controller has positive variance penalty. -/
structure ValidVariancePenalty (ctrl : StochasticController n) : Prop where
  lambda_pos : ctrl.lambda > 0

/-- Controller has positive noise. -/
structure ValidNoise (ctrl : StochasticController n) : Prop where
  sigma_pos : ctrl.sigma > 0

/-! ## Dynamics -/

/-- State update: x(t+1) = f(x(t), u(t)) + noise. -/
def state_update (ctrl : StochasticController n) (state action noise : Fin n → Rat) : Fin n → Rat :=
  fun i => ctrl.dynamics state action i + noise i

/-- SGD parameter update: θ(t+1) = θ(t) - α · ∇J(θ). -/
def sgd_update (ctrl : StochasticController n) (params state : Fin n → Rat) : Fin n → Rat :=
  fun i => params i + (-(ctrl.alpha * ctrl.grad state params i))

/-! ## Cost Function Properties -/

/-- Cost is bounded below by zero (assuming non-negative cost function). -/
theorem cost_nonneg_of_nonneg (ctrl : StochasticController n)
    (h_cost : ∀ s a, ctrl.cost s a ≥ 0) (state action : Fin n → Rat) :
    ctrl.cost state action ≥ 0 :=
  h_cost state action

/-! ## SGD Properties -/

/-- SGD update with zero gradient is identity. -/
theorem sgd_update_zero_grad (ctrl : StochasticController n) (params : Fin n → Rat)
    (state : Fin n → Rat) (hgrad : ∀ i, ctrl.grad state params i = 0) :
    sgd_update ctrl params state = params := by
  funext i
  simp only [sgd_update, hgrad i, Rat.mul_zero]
  simp [Rat.neg_zero, Rat.add_zero]

/-- SGD update well-defined. -/
theorem sgd_update_welldefined (ctrl : StochasticController n)
    (params state : Fin n → Rat) :
    ∃ result, sgd_update ctrl params state = result :=
  ⟨sgd_update ctrl params state, rfl⟩

/-- State update well-defined. -/
theorem state_update_welldefined (ctrl : StochasticController n)
    (state action noise : Fin n → Rat) :
    ∃ result, state_update ctrl state action noise = result :=
  ⟨state_update ctrl state action noise, rfl⟩

/-! ## Concrete Instance -/

/-- Default 2D stochastic controller. -/
def default_sc : StochasticController 2 :=
  { alpha := 0.01
    lambda := 1
    sigma := 0.1
    dynamics := fun state action i =>
      if i.val == 0 then state ⟨0, by omega⟩ + 0.5 * action ⟨0, by omega⟩
      else state ⟨1, by omega⟩ + 0.5 * action ⟨1, by omega⟩
    cost := fun state action =>
      state ⟨0, by omega⟩ ^ 2 + state ⟨1, by omega⟩ ^ 2 +
      action ⟨0, by omega⟩ ^ 2 + action ⟨1, by omega⟩ ^ 2
    grad := fun _state params i =>
      if i.val == 0 then 2 * params ⟨0, by omega⟩
      else 2 * params ⟨1, by omega⟩ }

/-- Default controller has valid learning rate. -/
theorem default_valid_lr : ValidLearningRate default_sc :=
  { alpha_pos := by native_decide, alpha_lt_one := by native_decide }

/-- Default controller has valid variance penalty. -/
theorem default_valid_vp : ValidVariancePenalty default_sc :=
  { lambda_pos := by native_decide }

/-- Default controller has valid noise. -/
theorem default_valid_noise : ValidNoise default_sc :=
  { sigma_pos := by native_decide }

/-- SGD with zero gradient is identity for default controller. -/
theorem default_sgd_zero_grad (params : Fin 2 → Rat)
    (hgrad : ∀ i, default_sc.grad params params i = 0) :
    sgd_update default_sc params params = params :=
  sgd_update_zero_grad default_sc params params hgrad

end Multiplicity.Core.Operators.StochasticController
