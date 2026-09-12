import Init
import GodelianTruth.Core
import GodelianTruth.Gamma
import GodelianTruth.Contraction
import GodelianTruth.Godel
import GodelianTruth.PrimeSieved
import GodelianTruth.LawfulSchedules
import GodelianTruth.Conservative
import GodelianTruth.Examples
import GodelianTruth.Test
import GodelianTruth.Export

/-! # Godelian Truth v0.1.0

Lean 4 formalization of a fixed-point semantics for Gödel sentences
with prime-sieved variants.

Build: `lake build`
Test:  `lake exe GodelianTruthTest`
-/

def main : IO Unit := GodelianTruth.Test.main
