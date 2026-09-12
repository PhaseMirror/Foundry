import Init
import AlphaFunction.Core
import AlphaFunction.SpecialFunctions
import AlphaFunction.Quadrature
import AlphaFunction.Diagnostics
import AlphaFunction.Kernels
import AlphaFunction.ACEIntegration
import AlphaFunction.PETC
import AlphaFunction.Examples
import AlphaFunction.Proofs
import AlphaFunction.Test
import AlphaFunction.Export

/-! # Alpha Function v0.1.0

Lean 4 formalization of the Alpha Function master definition.

Build: `lake build`
Test:  `lake exe AlphaFunctionTest`
-/

def main : IO Unit := AlphaFunction.Test.main
