import Std.Data.Real.Basic
import Std.Data.Rat.Basic

open Real

-- Import the Geometry state defined in Geometry.lean
import Geometry

/-- Compute the impedance ``omega`` and the kinematic drag ``drag`` for a given
    ``GeometryState``. The formulas mirror the `compute_impedance` method in
    `scalar_surface.py`. -/
noncomputable def computeImpedance (s : GeometryState) (λ : ℝ := Params.λ) : (ℝ × ℝ) :=
  let cxStar := s.stabilityThreshold
  let sEff   := s.effectiveStress
  -- rho_X = C_X* (1 - exp(-λ * S_eff))
  let rho    := cxStar * (1 - exp (-λ * sEff))
  -- ratio is capped at 0.999 to avoid division by zero / imaginary numbers
  let ratio  := min (rho / cxStar) 0.999
  -- omega_X = 1 / sqrt(1 - ratio^2)
  let omega  := 1 / sqrt (1 - ratio ^ 2)
  -- D_k,X = omega_X - 1
  let drag   := omega - 1
  (omega, drag)

/-- Convenient wrapper returning a structure with named fields. -/
structure ImpedanceMetrics where
  impedance : ℝ
  kinematicDrag : ℝ
  deriving Repr

noncomputable def impedanceMetrics (s : GeometryState) (λ : ℝ := Params.λ) : ImpedanceMetrics :=
  let (omega, drag) := computeImpedance s λ
  { impedance := omega, kinematicDrag := drag }
