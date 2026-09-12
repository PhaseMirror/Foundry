import Init
import LowComplexityAttractor.Core
import LowComplexityAttractor.Dynamics
import LowComplexityAttractor.ACE
import LowComplexityAttractor.PETC
import LowComplexityAttractor.Metrics
import LowComplexityAttractor.Statistics
import LowComplexityAttractor.ZK
import LowComplexityAttractor.Proofs

/-! # Low-Complexity Attractor — Examples

Concrete instantiations of states, dynamics, ACE certificates, PETC tensors,
metrics, statistical tests, and ZK proofs.
-/

namespace LowComplexityAttractor.Examples

open LowComplexityAttractor.Core
open LowComplexityAttractor.Dynamics
open LowComplexityAttractor.ACE
open LowComplexityAttractor.PETC
open LowComplexityAttractor.Metrics
open LowComplexityAttractor.Statistics
open LowComplexityAttractor.ZK

/-- Example: 3D state. -/
def exampleState3D : State := {
  dim := 3
  values := [1.0, 0.5, -0.3]
}

/-- Example: cubic repair parameters. -/
def exampleCubicParams : CubicRepairParams := {
  W3 := [[0.1], [0.1], [0.1]]
  W1 := [[0.5, 0.0, 0.0], [0.0, 0.5, 0.0], [0.0, 0.0, 0.5]]
  b := [0.0, 0.0, 0.0]
}

/-- Example: safety set. -/
def exampleSafety : SafetySet := {
  B := [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]]
  kappa := 1.0
  r := 2.0
}

/-- Example: ACE certificate. -/
def exampleCert : ACECertificate := aceCertificate exampleState3D exampleCubicParams exampleSafety

/-- Example: prime-encoded tensor. -/
def exampleTensor : PrimeEncodedTensor3 := buildPrimeTensor3 2 3 5

/-- Example: trajectory. -/
def exampleTrajectory : List State := [exampleState3D]

/-- Example: ZK witness. -/
def exampleWitness : ZKProximityWitness := {
  stateVec := [encodeQ211 1.0, encodeQ211 0.5, encodeQ211 (-0.3)]
  targetVec := [encodeQ211 0.9, encodeQ211 0.4, encodeQ211 (-0.2)]
  diffVec := [encodeQ211 0.1, encodeQ211 0.1, encodeQ211 (-0.1)]
  squaredDiffs := [encodeQ211 0.01, encodeQ211 0.01, encodeQ211 0.01]
  sumSqDiff := encodeQ211 0.03
  epsSq := encodeQ211 0.1
}

/-- Example: statistical test. -/
def examplePermTest : Float := permutationTest [1.0, 2.0, 3.0] [4.0, 5.0, 6.0] 100

end LowComplexityAttractor.Examples
