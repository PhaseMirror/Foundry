-- No Mathlib imports; core Lean 4 Float is used directly.

open Float

-- Import the Geometry state and parameters defined in Geometry.lean
import Geometry

/-- Compute the impedance ``omega`` and the kinematic drag ``drag`` for a given
    ``GeometryState``. The formulas mirror the `compute_impedance` method in
    `scalar_surface.py`. -/
noncomputable def computeImpedance (s : GeometryState) (λ : Float := Params.λ) : (Float × Float) :=
  let cxStar := s.stability_threshold
  let sEff   := s.effective_stress
  -- rho_X = C_X* (1 - exp(-λ * S_eff))
  let rho    := cxStar * (1 - Float.exp (-λ * sEff))
  -- ratio is capped at 0.999 to avoid division by zero / imaginary numbers
  let ratio  := Float.min (rho / cxStar) 0.999
  -- omega_X = 1 / sqrt(1 - ratio^2)
  let omega  := 1 / Float.sqrt (1 - ratio ^ 2)
  -- D_k,X = omega_X - 1
  let drag   := omega - 1
  (omega, drag)

/-- Convenient wrapper returning a structure with named fields. -/
structure ImpedanceMetrics where
  impedance : Float
  kinematicDrag : Float
  deriving Repr

noncomputable def impedanceMetrics (s : GeometryState) (λ : Float := Params.λ) : ImpedanceMetrics :=
  let (omega, drag) := computeImpedance s λ
  { impedance := omega, kinematicDrag := drag }
