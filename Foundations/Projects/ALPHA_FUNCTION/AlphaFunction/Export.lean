import Init
import AlphaFunction.Core
import AlphaFunction.SpecialFunctions
import AlphaFunction.Quadrature
import AlphaFunction.Diagnostics
import AlphaFunction.Kernels
import AlphaFunction.ACEIntegration
import AlphaFunction.PETC

/-! # Alpha Function — Export

Generates Markdown artifacts from the formal model.
-/

namespace AlphaFunction.Export

open AlphaFunction.Core
open AlphaFunction.SpecialFunctions
open AlphaFunction.Quadrature
open AlphaFunction.Diagnostics
open AlphaFunction.Kernels
open AlphaFunction.ACEIntegration
open AlphaFunction.PETC

/-- Core constants table. -/
def coreConstantsToMd : String :=
  "# Alpha Function Constants\n\n" ++
  "| Symbol | Value |\n" ++
  "|--------|-------|\n" ++
  "| FP_DEN | 100 |\n" ++
  "| U_MIN | -3.0 |\n" ++
  "| U_MAX | 7.0 |\n"

/-- Kernel summary. -/
def kernelSummaryToMd : String :=
  "# Kernel Summary\n\n" ++
  "| Kernel | Definition | Reference |\n" ++
  "|--------|------------|-----------|\n" ++
  "| G1 | G(t)=1 | Γ(s) x^{-s} |\n" ++
  "| G2 | G(t)=e^{at} | Γ(s) (x-a)^{-s} |\n" ++
  "| G3 | G(t)=(1+ct)^m | Σ binomial(m,k) c^k Γ(s+k) x^{-(s+k)} |\n"

/-- Full export. -/
def fullExport : String :=
  coreConstantsToMd ++ "\n" ++
  kernelSummaryToMd ++ "\n"

end AlphaFunction.Export
