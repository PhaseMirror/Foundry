import Std.Data.Rat
import Std.Data.Int
import Std.Data.Real

/--
  ScalarCore implements the canonical ODE engine (Track A) for the Genesis ODE.
  It defines parameters and provides pure functions for impedance computation and
  ODE derivative evaluation. No external `Mathlib` imports or `sorry`s are used.
-/

structure SurfaceState where
  coherence : Real
  stabilityThreshold : Real
  effectiveStress : Real
  grounding : Real
  alignment : Real
  impedance : Real := 0.0
  kinematicDrag : Real := 0.0
  timestamp : Real := 0.0
  deriving Repr

structure ScalarCore where
  alpha : Real
  beta  : Real
  gamma : Real
  eta   : Real
  kappa : Real
  delta : Real
  lambdaParam : Real
  deriving Repr

namespace ScalarCore

  def mk (α β γ η κ δ λ : Real) : ScalarCore :=
    { alpha := α, beta := β, gamma := γ, eta := η, kappa := κ, delta := δ, lambdaParam := λ }

  /-- Validate that all parameters satisfy the Track‑A canonical bounds. -/
  def validate (self : ScalarCore) : Bool :=
    (self.alpha ≥ 0 ∧ self.alpha ≤ 1) ∧
    (self.beta  ≥ 0) ∧
    (self.gamma ≥ 0) ∧
    (self.eta   ≥ 0) ∧
    (self.delta ≥ 0) ∧
    (self.lambdaParam ≥ 0)

  /-- Compute impedance `omega` and kinematic drag from a given state. -/
  def computeImpedance (self : ScalarCore) (st : SurfaceState) : (Real × Real) :=
    let cxStar := st.stabilityThreshold
    let sEff   := st.effectiveStress
    -- rho = C* (1 - exp(-λ * S_eff))
    let rho    := cxStar * (1 - Real.exp (-(self.lambdaParam) * sEff))
    -- clamp ratio to avoid division by zero / sqrt of negative
    let ratio  := min (rho / cxStar) 0.999999
    let omega  := 1 / Real.sqrt (1 - ratio * ratio)
    let drag   := omega - 1
    (omega, drag)

  /-- Compute the scalar ODE derivative dC/dt. `externalCoupling` encodes the
      kappa‑weighted sum term that originates from other lanes. -/
  def derivative (self : ScalarCore) (st : SurfaceState) (externalCoupling : Real := 0) : Real :=
    let cx      := st.coherence
    let cxStar  := st.stabilityThreshold
    let gx      := st.grounding
    let sEff    := st.effectiveStress
    let ax      := st.alignment
    self.alpha * (cxStar - cx) +
    self.beta  * gx -
    self.gamma * sEff +
    self.eta   * ax +
    externalCoupling -
    self.delta

  /-- Perform a single explicit Euler step. Returns a new `SurfaceState`. -/
  def step (self : ScalarCore) (st : SurfaceState) (dt nextS : Real) (externalCoupling : Real := 0) : SurfaceState :=
    let dc     := self.derivative st externalCoupling
    let newC   := max 0.0 (min (st.coherence + dc * dt) st.stabilityThreshold)
    let newSt  := { st with coherence := newC, effectiveStress := nextS, timestamp := st.timestamp + dt }
    let (ω, drag) := self.computeImpedance newSt
    { newSt with impedance := ω, kinematicDrag := drag }

end ScalarCore
