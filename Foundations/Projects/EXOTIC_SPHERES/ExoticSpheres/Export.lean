import Init
import ExoticSpheres.Core
import ExoticSpheres.Plumbing
import ExoticSpheres.Brieskorn
import ExoticSpheres.Kernel
import ExoticSpheres.Multiplicity
import ExoticSpheres.Graded
import ExoticSpheres.Invariants
import ExoticSpheres.Knots
import ExoticSpheres.Examples

/-! # Exotic Spheres — Export

Generates Markdown artifacts from the formal model.
-/

namespace ExoticSpheres.Export

open ExoticSpheres.Core
open ExoticSpheres.Plumbing
open ExoticSpheres.Brieskorn
open ExoticSpheres.Kernel
open ExoticSpheres.Multiplicity
open ExoticSpheres.Graded
open ExoticSpheres.Invariants
open ExoticSpheres.Examples

/-- Core constants table. -/
def coreConstantsToMd : String :=
  "# Exotic Spheres Constants\n\n" ++
  "| Symbol | Value |\n" ++
  "|--------|-------|\n" ++
  "| Toolbelt Triples | Σ(2,3,r), r∈{5,7,11,13,17,19} |\n" ++
  "| Smooth Scalar Modulus | 28 |\n" ++
  "| Primes for Grading | 2, 3 |\n" ++
  "| Max Tier | 2 |\n"

/-- Brieskorn summary. -/
def brieskornSummaryToMd : String :=
  "# Brieskorn Spheres Summary\n\n" ++
  "| r | μ(Σ) |\n" ++
  "|---|------|\n" ++
  "| 5 | 0 |\n" ++
  "| 7 | 8 |\n" ++
  "| 11 | 16 |\n" ++
  "| 13 | 4 |\n" ++
  "| 17 | 12 |\n" ++
  "| 19 | 20 |\n"

/-- Full export. -/
def fullExport : String :=
  coreConstantsToMd ++ "\n" ++
  brieskornSummaryToMd ++ "\n"

end ExoticSpheres.Export
