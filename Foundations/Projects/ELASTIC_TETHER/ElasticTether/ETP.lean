import Init
import ElasticTether.Core
import ElasticTether.CMT

/-! # Elastic Tether — Protocol Dynamics

Formalizes the Elastic Tether Protocol (ETP) with bifurcated Head/Tail agents,
tether lag L(t), safety parameters, and the elastic Lagrangian.
-/

namespace ElasticTether.ETP

open ElasticTether.Core
open ElasticTether.CMT

/-- Agent state at time t. -/
structure AgentState where
  headPos : Nat
  tailPos : Nat
  verifiedSet : VerifiedSet
  safetyParams : SafetyParams
  deriving Repr

/-- Current lag L(t) = x_head - x_tail. -/
def currentLag (state : AgentState) : Nat :=
  state.headPos - state.tailPos

/-- Check if agent is in lead region (lag > Δ_safe). -/
def inLeadRegion (state : AgentState) : Bool :=
  currentLag state > deltaSafe state.safetyParams

/-- Check if agent is in verified region (lag ≤ Δ_safe). -/
def inVerifiedRegion (state : AgentState) : Bool :=
  ¬inLeadRegion state

/-- Local average multiplicity from verified primes. -/
def localAvgMultiplicity (state : AgentState) (x : Nat) (windowSize : Nat) : Float :=
  let verified := state.verifiedSet.computed
  let inWindow := verified.filter (fun p => p >= x - windowSize ∧ p <= x + windowSize)
  if inWindow.length = 0 then 0.0
  else inWindow.foldl (fun acc _p => acc + 1.0) 0.0 / inWindow.length.toFloat

/-- Head velocity law (physics-based, no oracle). -/
def headVelocity (state : AgentState) (xHead : Nat) (muBar : Float) : Nat :=
  let L := xHead - state.tailPos
  let delta := deltaSafe state.safetyParams
  if L > delta then
    state.safetyParams.vMin
  else
    let bonus := (state.safetyParams.vMax - state.safetyParams.vMin).toFloat * muBar
    state.safetyParams.vMin + (bonus.floor.toUInt64.toNat)

/-- Tether potential V_tether = 0.5 * k * (L - Δ_safe)^2. -/
def tetherPotential (state : AgentState) (k : Float) : Float :=
  let L := currentLag state
  let delta := (deltaSafe state.safetyParams).toFloat
  0.5 * k * ((L.toFloat - delta) * (L.toFloat - delta))

/-- Throughput kinetic energy 0.5 * m * v_head^2. -/
def throughputKinetic (_state : AgentState) (vHead : Nat) (m : Float) : Float :=
  0.5 * m * (vHead.toFloat * vHead.toFloat)

/-- Witness revenue μ_verified(t). -/
def witnessRevenue (state : AgentState) : Float :=
  state.verifiedSet.computed.length.toFloat

/-- Elastic Lagrangian S_ETP = ∫ (T - V_tether + μ_verified) dt. -/
def elasticLagrangian (state : AgentState) (vHead : Nat) (k m : Float) : Float :=
  throughputKinetic state vHead m - tetherPotential state k + witnessRevenue state

/-- Update Head position based on velocity. -/
def updateHead (state : AgentState) (vHead : Nat) : AgentState :=
  { state with headPos := state.headPos + vHead }

/-- Update Tail position (interrogate next prime). -/
def updateTail (state : AgentState) : AgentState :=
  let nextPrime := state.verifiedSet.maxPrime + 1
  let newComputed := if isPrime nextPrime then nextPrime :: state.verifiedSet.computed else state.verifiedSet.computed
  { state with tailPos := nextPrime, verifiedSet := { state.verifiedSet with maxPrime := nextPrime, computed := newComputed } }

/-- Verified ETP properties. -/
theorem lag_nonnegative (state : AgentState) :
  currentLag state >= 0 := Nat.zero_le _

end ElasticTether.ETP
