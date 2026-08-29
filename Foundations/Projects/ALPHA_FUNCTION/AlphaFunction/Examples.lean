import Init
import AlphaFunction.Core
import AlphaFunction.SpecialFunctions
import AlphaFunction.Quadrature
import AlphaFunction.Diagnostics
import AlphaFunction.Kernels
import AlphaFunction.ACEIntegration
import AlphaFunction.PETC

/-! # Alpha Function — Examples

Concrete instantiations and parameter sets.
-/

namespace AlphaFunction.Examples

open AlphaFunction.Core
open AlphaFunction.SpecialFunctions
open AlphaFunction.Quadrature
open AlphaFunction.Kernels
open AlphaFunction.ACEIntegration

/-- Example: Gamma slice parameters. -/
def gammaParams : AlphaParams := {
  K := 0,
  theta_0 := 2.0,
  lambda_L := 1.0,
  c_k := [],
  rho_k := []
}

/-- Example: Zeta slice parameters. -/
def zetaParams : AlphaParams := {
  K := 1,
  theta_0 := 0.0,
  lambda_L := 1.0,
  c_k := [],
  rho_k := [2.0]
}

/-- Example: evaluate alpha with G1 at x=1.0. -/
def exampleAlphaG1 : Float :=
  alphaMaster 1.0 gammaParams G1

/-- Example: zeta approximation at s=2. -/
def exampleZeta2 : Float :=
  zetaSlice 2.0 100

/-- Example: adaptive integral with G1. -/
def exampleAdaptiveIntegral : Float × Nat :=
  adaptiveIntegral 1.0 2.0 (fun _ => 1.0) 1e-10 64

/-- Example: ACE feature extraction. -/
def exampleFeatures : List Float :=
  let x_grid := [0.1, 0.5, 1.0, 2.0, 5.0]
  extractFeatures x_grid gammaParams G1

end AlphaFunction.Examples
