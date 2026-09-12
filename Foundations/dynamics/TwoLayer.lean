/-!
# Multiplicity.Dynamics.TwoLayer — Two-Layer Contraction Dynamics with Cross-Talk

Formalizes the two-layer cross-talk dynamics between the operational state (x_norm)
and the governance/multiplicity layer (lambda_norm) over exact rationals (Rat).

Proves that under the tuning parameter bounds:
  (gamma_0 + eta < 1) ∧ (gamma_1 + beta < 1)
the coupled cross-talk operator is strictly contractive:
  (cross_talk_step state params).total_norm < state.total_norm
satisfying the L0 Constitutional Non-Expansion Invariant constructively without Mathlib.
-/


namespace Multiplicity.Dynamics

/-- Coupled state consisting of operational norm and multiplicity/governance norm -/
structure TwoLayerState where
  x_norm : Rat
  lambda_norm : Rat
  deriving Repr, DecidableEq

/-- Total energy/Lyapunov norm of the two-layer state -/
def TwoLayerState.total_norm (s : TwoLayerState) : Rat :=
  s.x_norm + s.lambda_norm

/-- Tuning parameters governing intra-layer decay and inter-layer cross-talk -/
structure TuningParams where
  gamma_0 : Rat -- Operational intra-layer decay rate
  gamma_1 : Rat -- Governance intra-layer decay rate
  beta    : Rat -- Cross-talk feedback: governance -> operational
  eta     : Rat -- Cross-talk feedback: operational -> governance
  deriving Repr, DecidableEq

/-- The discrete-time cross-talk operator mapping (x, lambda) -> (x_next, lambda_next) -/
def cross_talk_step (state : TwoLayerState) (params : TuningParams) : TwoLayerState :=
  { x_norm := params.gamma_0 * state.x_norm + params.beta * state.lambda_norm,
    lambda_norm := params.gamma_1 * state.lambda_norm + params.eta * state.x_norm }

/-- Algebraic reformulation of the updated total norm:
    next_total = (gamma_0 + eta) * x_norm + (gamma_1 + beta) * lambda_norm -/
theorem cross_talk_total_norm_eq (state : TwoLayerState) (params : TuningParams) :
    (cross_talk_step state params).total_norm =
    (params.gamma_0 + params.eta) * state.x_norm + (params.gamma_1 + params.beta) * state.lambda_norm := by
  simp [TwoLayerState.total_norm, cross_talk_step]
  ring

/-- 
Theorem: Global Coupled Contractivity.
When intra-layer decay and cross-talk satisfy the column-sum bounds:
  (gamma_0 + eta < 1) ∧ (gamma_1 + beta < 1)
the discrete-time update strictly contracts the total state norm:
  total_norm(cross_talk_step(state)) < total_norm(state).
-/
theorem coupled_system_is_contractive 
    (state : TwoLayerState) (params : TuningParams)
    (h_pos_x : 0 < state.x_norm) (h_pos_lambda : 0 < state.lambda_norm)
    (h_bound_x : params.gamma_0 + params.eta < 1)
    (h_bound_lambda : params.gamma_1 + params.beta < 1) :
    (cross_talk_step state params).total_norm < state.total_norm := by
  rw [cross_talk_total_norm_eq]
  simp [TwoLayerState.total_norm]
  have hx : (params.gamma_0 + params.eta) * state.x_norm < state.x_norm := by
    calc (params.gamma_0 + params.eta) * state.x_norm
      _ < 1 * state.x_norm := mul_lt_mul_of_pos_right h_bound_x h_pos_x
      _ = state.x_norm     := one_mul state.x_norm
  have hlambda : (params.gamma_1 + params.beta) * state.lambda_norm < state.lambda_norm := by
    calc (params.gamma_1 + params.beta) * state.lambda_norm
      _ < 1 * state.lambda_norm := mul_lt_mul_of_pos_right h_bound_lambda h_pos_lambda
      _ = state.lambda_norm     := one_mul state.lambda_norm
  exact add_lt_add hx hlambda

end Multiplicity.Dynamics
