import Init
import HCQA.Core
import HCQA.M3A

/-! # HCQA — Hardware Specifications

Formalizes the neutral-atom hardware requirements for UAC implementation:
optical traps, laser systems, coherence times, and control systems.
-/

namespace HCQA.Hardware

open HCQA.Core
open HCQA.M3A

/-- Hardware component specification. -/
structure HardwareSpec where
  component : String
  specification : String
  purpose : String
  deriving Repr

/-- Complete UAC hardware configuration. -/
structure UACHardware where
  atomicSpecies : List AtomSpecies
  opticalTraps : Nat
  laserSystems : List String
  coherenceTimes : List Float
  readoutFidelity : Float
  coProcessorLatency : Float
  deriving Repr

/-- Default UAC hardware configuration. -/
def defaultHardware : UACHardware := {
  atomicSpecies := [{ name := "Sr-87", nuclearSpin := 9 }, { name := "Yb-171", nuclearSpin := 1 }]
  opticalTraps := 100
  laserSystems := ["689nm", "698nm", "319nm"]
  coherenceTimes := [1.0, 0.0005]
  readoutFidelity := 0.995
  coProcessorLatency := 0.0001
}

/-- Verified hardware properties. -/
theorem optical_traps_sufficient : defaultHardware.opticalTraps >= 100 := by decide

end HCQA.Hardware
