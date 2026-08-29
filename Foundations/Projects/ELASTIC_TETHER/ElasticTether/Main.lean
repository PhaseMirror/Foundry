import Init
import ElasticTether.Core
import ElasticTether.CMT
import ElasticTether.ETP
import ElasticTether.Axioms
import ElasticTether.Validation
import ElasticTether.Applications
import ElasticTether.Examples
import ElasticTether.Proofs
import ElasticTether.Test
import ElasticTether.Export

/-! # Elastic Tether v0.1.0

Lean 4 formalization of the Physics-Based Elastic Tether Protocol.

Build: `lake build`
Test:  `lake exe ElasticTetherTest`
-/

def main : IO Unit := ElasticTether.Test.main
