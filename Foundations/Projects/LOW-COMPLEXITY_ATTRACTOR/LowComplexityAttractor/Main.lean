import Init
import LowComplexityAttractor.Core
import LowComplexityAttractor.Dynamics
import LowComplexityAttractor.ACE
import LowComplexityAttractor.PETC
import LowComplexityAttractor.Metrics
import LowComplexityAttractor.Statistics
import LowComplexityAttractor.ZK
import LowComplexityAttractor.Examples
import LowComplexityAttractor.Proofs
import LowComplexityAttractor.Test
import LowComplexityAttractor.Export

/-! # Low-Complexity Attractor v0.1.0

Lean 4 formalization of the low-complexity attractor study:
evaluating φ, e, and prime-indexed candidates under ACE-certified control
with PETC structure and ZK verification.

Build: `lake build`
Test:  `lake exe LowComplexityAttractorTest`
-/

def main : IO Unit := LowComplexityAttractor.Test.main
