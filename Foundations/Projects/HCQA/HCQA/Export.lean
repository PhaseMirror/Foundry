import Init
import HCQA.Core
import HCQA.Qudit
import HCQA.MAVQE
import HCQA.HSEC
import HCQA.QCFI
import HCQA.M3A
import HCQA.Hardware
import HCQA.Examples

/-! # HCQA — Export

Generates Markdown artifacts from the formal model.
-/

namespace HCQA.Export

open HCQA.Core
open HCQA.Qudit
open HCQA.MAVQE
open HCQA.HSEC
open HCQA.QCFI
open HCQA.M3A
open HCQA.Hardware
open HCQA.Examples

/-- Core constants table. -/
def coreConstantsToMd : String :=
  "# HCQA Constants\n\n" ++
  "| Symbol | Value |\n" ++
  "|--------|-------|\n" ++
  "| Sr-87 Qudit Dim | 20 |\n" ++
  "| Yb-171 Qudit Dim | 4 |\n" ++
  "| Compression Factor (Sr-87) | 3.32 |\n" ++
  "| HSEC Overhead Reduction | ~5.4× |\n" ++
  "| Default Shot Count | 1000 |\n"

/-- Full export. -/
def fullExport : String :=
  coreConstantsToMd ++ "\n"

end HCQA.Export
