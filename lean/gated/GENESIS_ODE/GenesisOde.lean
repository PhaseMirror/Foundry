import .BRA
import .Geometry
import .Impedance

/-- Top‑level namespace aggregating the genesis‑ode Lean artifacts. -/
namespace GenesisOde

export BRA (wordLength externalCount commutatorDepth cost BRA)
export Geometry (GeometryState geomDist Params)
export Impedance (computeImpedance impedanceMetrics ImpedanceMetrics)

end GenesisOde
