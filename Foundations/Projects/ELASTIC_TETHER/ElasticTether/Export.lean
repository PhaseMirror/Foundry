import Init
import ElasticTether.Core
import ElasticTether.CMT
import ElasticTether.Examples
import ElasticTether.ETP
import ElasticTether.Axioms
import ElasticTether.Validation
import ElasticTether.Applications

/-! # Elastic Tether — Export

Generates Markdown artifacts from the formal model.
-/

namespace ElasticTether.Export

open ElasticTether.Core
open ElasticTether.CMT
open ElasticTether.Examples
open ElasticTether.ETP
open ElasticTether.Axioms
open ElasticTether.Validation
open ElasticTether.Applications

/-- Core constants table. -/
def coreConstantsToMd : String :=
  "# Elastic Tether Constants\n\n" ++
  "| Symbol | Value |\n" ++
  "|--------|-------|\n" ++
  "| Toolbelt Primes | {2, 3, 5} |\n" ++
  "| Default Cost Interrogate | 10 |\n" ++
  "| Default vMax | 100 |\n" ++
  "| Default vMin | 1 |\n"

/-- CMT summary. -/
def cmtSummaryToMd : String :=
  "# CMT Summary\n\n" ++
  "| Metric | Value |\n" ++
  "|--------|-------|\n" ++
  "| Max Gap Reduction | 72 → 2 |\n" ++
  "| Mean Gap (N=1000) | " ++ toString exampleMeanCmtGap1000 ++ " |\n" ++
  "| Connectivity | Dense |\n"

/-- Full export. -/
def fullExport : String :=
  coreConstantsToMd ++ "\n" ++
  cmtSummaryToMd ++ "\n"

end ElasticTether.Export
