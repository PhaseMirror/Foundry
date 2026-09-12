import Init
import HCQA.Core
import HCQA.Qudit
import HCQA.MAVQE
import HCQA.HSEC
import HCQA.QCFI
import HCQA.M3A
import HCQA.Hardware
import HCQA.Proofs

/-! # HCQA — Examples

Concrete instantiations of UAC components: Sr-87 qudits, MA-VQE parameters,
HSEC encodings, QCFI states, M³A arrays, and hardware configurations.
-/

namespace HCQA.Examples

open HCQA.Core
open HCQA.Qudit
open HCQA.MAVQE
open HCQA.HSEC
open HCQA.QCFI
open HCQA.M3A
open HCQA.Hardware

/-- Example: Sr-87 atom species. -/
def sr87 : AtomSpecies := { name := "Sr-87", nuclearSpin := 9 }
def yb171 : AtomSpecies := { name := "Yb-171", nuclearSpin := 1 }

/-- Example: qudit dimensions. -/
def sr87Dim : Nat := quditDim 9
def yb171Dim : Nat := quditDim 1

/-- Example: HSEC encoding for Sr-87. -/
def sr87Encoding : HSECEncoding := {
  quditDim := 38
  compLevels := 30
  synLevels := 8
}

/-- Example: MA-VQE parameters. -/
def exampleMAVQE : MAVQEParams := {
  theta := [0.1, 0.2, 0.3]
  partition := {
    totalDim := 38
    compDim := 30
    synDim := 8
  }
}

/-- Example: QCFI state. -/
def exampleQCFI : QCFIState := {
  variance := 0.005
  partition := {
    totalDim := 38
    compDim := 30
    synDim := 8
  }
  t2Times := [0.0006, 0.0007, 0.0008]
  shotCount := 1000
}

/-- Example: M³A module. -/
def exampleModule : M3AModule := {
  modType := ModuleType.computational sr87 6
  qudits := []
  encoding := sr87Encoding
}

/-- Example: default hardware. -/
def exampleHardware : UACHardware := defaultHardware

end HCQA.Examples
