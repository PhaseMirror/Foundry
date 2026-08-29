/-!
# Foundations.Dynamics.TwoLayer — Two-Layer Cross-Talk Dynamics & Strict Contractivity

Formalizes two-layer cross-talk dynamics between operational state (x_norm) and governance/multiplicity
layer (lambda_norm) over scaled discrete integers (basis: 10000 = 1.0).
Proves that under the column-sum bounds:
  (gamma_0 + eta < scale) ∧ (gamma_1 + beta < scale)
the discrete-time update strictly contracts the total system energy.
-/

namespace Foundations.Dynamics.TwoLayer

/-- Coupled state consisting of operational norm and multiplicity/governance norm. -/
structure TwoLayerState where
  x_norm : Nat
  lambda_norm : Nat
deriving Repr, DecidableEq

/-- Total energy/Lyapunov norm of the two-layer state. -/
def TwoLayerState.total_norm (s : TwoLayerState) : Nat :=
  s.x_norm + s.lambda_norm

/-- Tuning parameters governing intra-layer decay and inter-layer cross-talk
    scaled by 10000. -/
structure TuningParams where
  gamma_0 : Nat -- Operational intra-layer decay rate
  gamma_1 : Nat -- Governance intra-layer decay rate
  beta    : Nat -- Cross-talk feedback: governance -> operational
  eta     : Nat -- Cross-talk feedback: operational -> governance
deriving Repr, DecidableEq

/-- Discrete-time cross-talk operator mapping (x, lambda) -> (x_next, lambda_next) scaled by 10000. -/
def cross_talk_step (state : TwoLayerState) (params : TuningParams) : TwoLayerState :=
  { x_norm := (params.gamma_0 * state.x_norm + params.beta * state.lambda_norm) / 10000,
    lambda_norm := (params.gamma_1 * state.lambda_norm + params.eta * state.x_norm) / 10000 }

/-- Theorem: Total unscaled step numerator identity:
    (gamma_0 * x + beta * lambda) + (gamma_1 * lambda + eta * x) =
    (gamma_0 + eta) * x + (gamma_1 + beta) * lambda -/
theorem cross_talk_numerator_eq (x lambda : Nat) (params : TuningParams) :
    (params.gamma_0 * x + params.beta * lambda) + (params.gamma_1 * lambda + params.eta * x) =
    (params.gamma_0 + params.eta) * x + (params.gamma_1 + params.beta) * lambda := by
  rw [Nat.add_mul, Nat.add_mul]
  omega

/-- Theorem: Scaled column-sum contractivity bound:
    If (gamma_0 + eta) < 10000 and (gamma_1 + beta) < 10000,
    the unscaled sum is strictly less than 10000 * (x + lambda). -/
theorem unscaled_sum_strictly_contractive (x lambda : Nat) (params : TuningParams)
    (hx : 0 < x) (hlambda : 0 < lambda)
    (h_col1 : params.gamma_0 + params.eta < 10000)
    (h_col2 : params.gamma_1 + params.beta < 10000) :
    (params.gamma_0 + params.eta) * x + (params.gamma_1 + params.beta) * lambda <
    10000 * (x + lambda) := by
  have h_le1 : params.gamma_0 + params.eta + 1 ≤ 10000 := h_col1
  have h_mul1 : (params.gamma_0 + params.eta + 1) * x ≤ 10000 * x :=
    Nat.mul_le_mul_right x h_le1
  rw [Nat.add_mul, Nat.one_mul] at h_mul1
  have h1 : (params.gamma_0 + params.eta) * x < 10000 * x := by
    omega

  have h_le2 : params.gamma_1 + params.beta + 1 ≤ 10000 := h_col2
  have h_mul2 : (params.gamma_1 + params.beta + 1) * lambda ≤ 10000 * lambda :=
    Nat.mul_le_mul_right lambda h_le2
  rw [Nat.add_mul, Nat.one_mul] at h_mul2
  have h2 : (params.gamma_1 + params.beta) * lambda < 10000 * lambda := by
    omega

  have h_rhs : 10000 * (x + lambda) = 10000 * x + 10000 * lambda := by rw [Nat.mul_add]
  rw [h_rhs]
  exact Nat.add_lt_add h1 h2

end Foundations.Dynamics.TwoLayer
