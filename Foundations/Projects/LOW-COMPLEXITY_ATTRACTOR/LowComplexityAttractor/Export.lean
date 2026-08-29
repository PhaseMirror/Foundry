import Init
import LowComplexityAttractor.Core
import LowComplexityAttractor.Dynamics
import LowComplexityAttractor.ACE
import LowComplexityAttractor.PETC
import LowComplexityAttractor.Metrics
import LowComplexityAttractor.Statistics
import LowComplexityAttractor.ZK
import LowComplexityAttractor.Examples

/-! # Low-Complexity Attractor — Export

Generates Markdown artifacts from the formal model.
-/

namespace LowComplexityAttractor.Export

open LowComplexityAttractor.Core
open LowComplexityAttractor.Dynamics
open LowComplexityAttractor.ACE
open LowComplexityAttractor.PETC
open LowComplexityAttractor.Metrics
open LowComplexityAttractor.Statistics
open LowComplexityAttractor.ZK
open LowComplexityAttractor.Examples

/-- Core constants table. -/
def coreConstantsToMd : String :=
  "# Low-Complexity Attractor Constants\n\n" ++
  "| Symbol | Value |\n" ++
  "|--------|-------|\n" ++
  "| φ (golden ratio) | " ++ toString phi ++ " |\n" ++
  "| e (Euler's number) | " ++ toString eulersE ++ " |\n" ++
  "| Default η | 0.05 |\n" ++
  "| Default σ | 0.02 |\n" ++
  "| ZK precision | Q2.11 (13-bit) |\n"

/-- Full export. -/
def fullExport : String :=
  coreConstantsToMd ++ "\n"

end LowComplexityAttractor.Export
