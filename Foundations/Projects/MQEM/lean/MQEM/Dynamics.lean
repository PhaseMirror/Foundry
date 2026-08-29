import MQEM.Types

/-!
# MQEM.Dynamics — Network-Coupled Delayed State-Space Update

Formalizes the core difference equation from M³EM Eq. (1):
  x_v(t+1) = x_v(t) + Δt [ F(x_v(t), u_v(t)) + ∑_{w ∈ N(v)} a_{vw} (x_w(t-τ) - x_v(t)) ] + Σ ξ_v(t)

Under discrete integer scaling (scale = 1000).
-/

namespace MQEM

/-- Discrete Lotka-Volterra growth drift function F(x, r, k). -/
def lotka_volterra_drift (x : Int) (growth_rate : Int) (carrying_capacity : Int) : Int :=
  if carrying_capacity = 0 then 0
  else (x * growth_rate * (carrying_capacity - x)) / carrying_capacity

/-- Dispersal coupling term: a_vw * (x_w_delayed - x_v). -/
def dispersal_flux (weight : Int) (x_w_delayed : Int) (x_v : Int) : Int :=
  weight * (x_w_delayed - x_v)

/-- Total dispersal drift at node v from all neighbors. -/
def total_dispersal_drift : List (Int × Int) → Int → Int
  | [], _ => 0
  | (w, x_w_delayed) :: rest, x_v =>
    dispersal_flux w x_w_delayed x_v + total_dispersal_drift rest x_v

/-- Core deterministic update step for a single state component:
    x_next = x + (dt * (F(x) + Dispersal)) / 1000. -/
def step_component (x_v : Int) (drift : Int) (dispersal : Int) (dt : Int) : Int :=
  x_v + (dt * (drift + dispersal)) / 1000

/-- Theorem: When drift and dispersal are zero, state component remains exactly constant. -/
theorem zero_drift_preserves_state (x_v dt : Int) :
    step_component x_v 0 0 dt = x_v := by
  dsimp [step_component]
  simp

/-- Theorem: Zero time step (dt = 0) preserves state unconditionally. -/
theorem zero_dt_preserves_state (x_v drift dispersal : Int) :
    step_component x_v drift dispersal 0 = x_v := by
  dsimp [step_component]
  simp

end MQEM
