import Foundations..BRA
import Foundations..Geometry
import Foundations..Impedance

/-- Top‑level namespace aggregating the genesis‑ode Lean artifacts. -/
namespace Multiplicity.GenesisOde

export BRA (wordLength externalCount commutatorDepth cost BRA)
export Geometry (GeometryState geomDist Params)
export Impedance (computeImpedance impedanceMetrics ImpedanceMetrics)

end Multiplicity.GenesisOde
