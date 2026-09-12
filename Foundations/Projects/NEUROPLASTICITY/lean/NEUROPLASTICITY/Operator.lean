import NEUROPLASTICITY.Types
import NEUROPLASTICITY.PrimeIndexing

/-!
# NEUROPLASTICITY.Operator — Recursive Operator Ξ(t) and State Evolution

Formalizes the recursive cognitive update from Eq. (1):
  Θ(t+1) = Ξ(Θ(t), Input)
Under bounded learning rates and decay constants.
-/

namespace NEUROPLASTICITY

/-- Single component recursive update step under sensory stimulus and homeostatic decay:
    θ_next = θ * (1000 - decay) / 1000 + (eta * stimulus) / 1000. -/
def recursive_step_amplitude (theta : Nat) (decay : Nat) (eta : Nat) (stimulus : Nat) : Nat :=
  let decayed := (theta * (1000 - decay.min 1000)) / 1000
  let learned := (eta * stimulus) / 1000
  decayed + learned

/-- Recursive phase shift under attention driving:
    ϕ_next = (ϕ + phase_velocity) % 360. -/
def recursive_step_phase (phase : Nat) (velocity : Nat) : Nat :=
  (phase + velocity) % 360

/-- Apply recursive operator Ξ to a single prime component. -/
def xi_step_component (c : PrimeTensorComponent) (decay eta stimulus velocity : Nat) : PrimeTensorComponent :=
  { prime_p   := c.prime_p,
    amplitude := recursive_step_amplitude c.amplitude decay eta stimulus,
    phase_deg := recursive_step_phase c.phase_deg velocity }

/-- Theorem: Zero decay and zero stimulus preserves amplitude exactly. -/
theorem zero_stimulus_zero_decay_preserves_amplitude (theta eta : Nat) :
    recursive_step_amplitude theta 0 eta 0 = theta := by
  dsimp [recursive_step_amplitude]
  have h_min : (0 : Nat).min 1000 = 0 := rfl
  rw [h_min]
  simp

/-- Theorem: Zero learning rate (eta = 0) produces pure exponential decay. -/
theorem zero_learning_rate_pure_decay (theta decay stimulus : Nat) :
    recursive_step_amplitude theta decay 0 stimulus = (theta * (1000 - decay.min 1000)) / 1000 := by
  dsimp [recursive_step_amplitude]
  simp

end NEUROPLASTICITY
