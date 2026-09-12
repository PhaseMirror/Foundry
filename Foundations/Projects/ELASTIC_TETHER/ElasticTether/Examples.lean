import Init
import ElasticTether.Core
import ElasticTether.CMT
import ElasticTether.ETP
import ElasticTether.Axioms
import ElasticTether.Validation
import ElasticTether.Applications
import ElasticTether.Proofs

/-! # Elastic Tether — Examples

Concrete instantiations of CMT navigation, ETP dynamics, and validation protocols.
-/

namespace ElasticTether.Examples

open ElasticTether.Core
open ElasticTether.CMT
open ElasticTether.ETP
open ElasticTether.Validation
open ElasticTether.Applications

/-- Example: accessible states up to 30. -/
def exampleAccessible30 : List Nat := accessibleStates 30

/-- Example: CMT gap reduction for N=1000. -/
def exampleCmtGap1000 : Nat := maxCmtGap 1000

/-- Example: mean CMT gap for N=1000. -/
def exampleMeanCmtGap1000 : Float := meanCmtGap 1000

/-- Example: safety parameters. -/
def exampleSafetyParams : SafetyParams := {
  costInterrogate := 10,
  vMax := 100,
  vMin := 1
}

/-- Example: agent state. -/
def exampleAgentState : AgentState := {
  headPos := 5000,
  tailPos := 2000,
  verifiedSet := { maxPrime := 2000, computed := [2, 3, 5, 7, 11] },
  safetyParams := exampleSafetyParams
}

/-- Example: current lag. -/
def exampleLag : Nat := currentLag exampleAgentState

/-- Example: head velocity. -/
def exampleVelocity : Nat := headVelocity exampleAgentState 5000 0.5

/-- Example: tether potential. -/
def exampleTetherPotential : Float := tetherPotential exampleAgentState 1.0

/-- Example: Phase 4 result. -/
def examplePhase4 : Phase4Result := {
  riskReductionPassed := true,
  temporalConsistencyPassed := true,
  epoch1Adapted := true,
  epoch2TransitionPassed := true,
  oracleFailed := true
}

/-- Example: Phase 4 passed. -/
def examplePhase4Passed : Bool := phase4_passed examplePhase4

end ElasticTether.Examples
