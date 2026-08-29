import Init
import HCQA.Core
import HCQA.Qudit
import HCQA.MAVQE
import HCQA.HSEC
import HCQA.QCFI
import HCQA.M3A
import HCQA.Hardware
import HCQA.Examples
import HCQA.Proofs
import HCQA.Test
import HCQA.Export

/-! # HCQA v0.1.0

Lean 4 formalization of the Universal Atomic Calculator (UAC):
a hybrid classical-quantum architecture for atomic self-simulation.

Build: `lake build`
Test:  `lake exe HCQATest`
-/

def main : IO Unit := HCQA.Test.main
