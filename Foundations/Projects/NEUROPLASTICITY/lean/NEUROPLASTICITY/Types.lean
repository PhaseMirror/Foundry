/-!
# NEUROPLASTICITY.Types — Core Data Structures for Recursive Neuroplasticity

Formalizes core mathematical types:
- PrimeTensorComponent: (prime index p, amplitude θ_p, phase ϕ_p)
- CognitiveState: list of prime tensor components forming Ψ(t)
- RecursiveConfig: learning rate, CSL entropy threshold, stability margin
-/

namespace NEUROPLASTICITY

/-- Prime index identifying an orthogonal cognitive channel. -/
def PrimeIndex := Nat
deriving Repr, DecidableEq

/-- A single prime-indexed tensor component θ_p ⊗ e^{i ϕ_p}.
    Amplitude and Phase are represented in discrete scaled integers (scale = 1000). -/
structure PrimeTensorComponent where
  prime_p   : PrimeIndex
  amplitude : Nat  -- θ_p * 1000
  phase_deg : Nat  -- ϕ_p in degrees [0, 360)
  deriving Repr, DecidableEq

/-- Cognitive State Ψ(t) as a collection of active prime tensor components. -/
structure CognitiveState where
  components : List PrimeTensorComponent
  deriving Repr, DecidableEq

/-- Consciousness Stability Law & Neuroplasticity Configuration. -/
structure NeuroConfig where
  learning_rate_scaled : Nat  -- eta * 1000
  csl_entropy_bound    : Nat  -- ln(phi) * 1000 ≈ 481 (since ln(1.618033) ≈ 0.4812)
  stability_margin     : Nat
  deriving Repr, DecidableEq

end NEUROPLASTICITY
