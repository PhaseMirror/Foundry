import Std.Data.Real.Basic
import Std.Data.Rat.Basic

open Real

-- Geometry state used in the BRA framework. Mirrors the Python `SurfaceState`
structure GeometryState where
  coherence : ℝ               -- Cx
  stabilityThreshold : ℝ    -- Cx*
  effectiveStress : ℝ       -- S_eff
  grounding : ℝ              -- Gx
  alignment : ℝ              -- Ax
  timestamp : ℝ              -- simulation time
  deriving Repr

-- Euclidean‑style metric on `GeometryState`. Only the fields relevant to BRA are used.
def geomDist (s₁ s₂ : GeometryState) : ℝ :=
  let d_coh   := s₁.coherence - s₂.coherence
  let d_thr   := s₁.stabilityThreshold - s₂.stabilityThreshold
  let d_stress:= s₁.effectiveStress - s₂.effectiveStress
  let d_ground:= s₁.grounding - s₂.grounding
  let d_align := s₁.alignment - s₂.alignment
  Real.sqrt (d_coh ^ 2 + d_thr ^ 2 + d_stress ^ 2 + d_ground ^ 2 + d_align ^ 2)

namespace Params
  def α : ℝ := 0.1   -- recovery rate
  def β : ℝ := 0.05  -- grounding coefficient
  def γ : ℝ := 0.1   -- stress coupling
  def η : ℝ := 0.05  -- alignment coupling
  def κ : ℝ := 0.0   -- external coupling weight
  def δ : ℝ := 0.01  -- decay term
  def λ : ℝ := 0.1   -- impedance decay constant
end Params

-- Alias for the metric required by the `BRA` definition in `BRA.lean`.
parameter d : GeometryState → GeometryState → ℝ := geomDist

-- Placeholder for the reconstruction kernel `Π`. In the full development this will be
-- instantiated with the algebraic action on `GeometryState`.
parameter Π : List (Sum ℕ ℕ) → GeometryState → GeometryState

export Params (α β γ η κ δ λ)
