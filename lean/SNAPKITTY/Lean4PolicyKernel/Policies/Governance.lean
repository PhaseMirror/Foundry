import Lean

namespace Lean4PolicyKernel.Policies

/-- A simple risk level enum used by the Sedona Spine. -/
inductive RiskLevel where
  | Critical
  | High
  | Medium
  | Low
  deriving Repr, DecidableEq

/-- Policy configuration (normally generated from YAML). -/
structure PolicyConfig where
  maxRetentionDays : Nat
  minPreservationLevel : RiskLevel
  deriving Repr

/-- Compute the preservation risk for a given ESI record. -/
def evaluateRisk (config : PolicyConfig) (sizeBytes : Nat) (daysSinceCapture : Nat) : RiskLevel :=
  if daysSinceCapture > config.maxRetentionDays then
    RiskLevel.Critical
  else if sizeBytes > 10^9 then
    RiskLevel.High
  else if daysSinceCapture > config.maxRetentionDays / 2 then
    RiskLevel.Medium
  else
    RiskLevel.Low

/-- Example default policy – the real values should be generated from YAML. -/
def defaultPolicy : PolicyConfig :=
  { maxRetentionDays := 365, minPreservationLevel := RiskLevel.Medium }

end Lean4PolicyKernel.Policies
