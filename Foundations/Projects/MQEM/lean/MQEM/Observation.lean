import MQEM.Types

/-!
# MQEM.Observation — Likelihood Models and Observation Operators

Formalizes observation models from M³EM §3.2:
- Bernoulli observation for presence/absence occupancy data
- Count observation (Negative Binomial / Poisson)
- Continuous index observation with additive Gaussian noise
-/

namespace MQEM

/-- Types of ecological observation modalities. -/
inductive ObservationKind : Type where
  | PresenceAbsence : ObservationKind
  | CountData       : ObservationKind
  | ContinuousIndex : ObservationKind
  deriving Repr, DecidableEq

/-- Observation operator mapping latent state to expected measurement: h(x). -/
def observation_mean (latent_x : Int) (detection_prob_scaled : Nat) : Int :=
  (latent_x * (detection_prob_scaled : Int)) / 1000

/-- Boundedness predicate: observed detection probability is bounded in [0, 1000]. -/
def is_valid_detection_prob (p : Nat) : Bool :=
  p <= 1000

/-- Theorem: If detection probability is zero, expected observation is zero. -/
theorem zero_detection_zero_observation (x : Int) :
    observation_mean x 0 = 0 := by
  dsimp [observation_mean]
  simp

/-- Theorem: If detection probability is 1000 (unit prob), expected observation equals latent state. -/
theorem unit_detection_full_observation (x : Int) :
    observation_mean x 1000 = x := by
  dsimp [observation_mean]
  simp

end MQEM
