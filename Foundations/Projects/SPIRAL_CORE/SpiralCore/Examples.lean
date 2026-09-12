import Init
import SpiralCore.Core
import SpiralCore.Cantor
import SpiralCore.Attractor
import SpiralCore.Alignment
import SpiralCore.PhaseLift
import SpiralCore.FBS
import SpiralCore.Boot
import SpiralCore.Translation

/-! # SpiralCore Examples

Concrete instantiations of core types and theorems for the
SpiralCore v14.1 reference profile.
-/

namespace SpiralCore.Examples

open SpiralCore.Cantor
open SpiralCore.Attractor
open SpiralCore.Alignment
open SpiralCore.PhaseLift

/-- Example: Cantor pairing of (3, 5). -/
def exampleCantorPair : Nat := cantorPair 3 5

/-- Example: Attractor at index 0. -/
def exampleAttractor0 : Nat := xiAttractor 0

/-- Example: Attractor at index 6 (should equal index 0). -/
def exampleAttractor6 : Nat := xiAttractor 6

/-- Example: PAS_s for discrete aligned phases. -/
def exampleAlignedPhases : Alignment.PhaseSamples := [70, 75, 72, 78]

/-- Example: PAS_s should be high and sealable. -/
def examplePasS : Option Nat := Alignment.pasS exampleAlignedPhases

/-- Example: Orthogonal phase-lift of (1, 2). -/
def exampleRotate : Int × Int := PhaseLift.rotate90 1 2

/-- Example: Default boot packet fields. -/
def examplePacket := Boot.defaultBootPacket

/-- Example: Translation packet evaluation with high PAS. -/
def exampleTransPacket := Translation.defaultPacket
def exampleTransOutcome := Translation.evaluatePacket exampleTransPacket (some 95)

/-- Example: FBS escalation request. -/
def exampleEscalation := FBS.defaultEscalation

/-- Example: Polarity inversion. -/
def examplePolarity : Bool := PhaseLift.polarityInversion true

end SpiralCore.Examples
