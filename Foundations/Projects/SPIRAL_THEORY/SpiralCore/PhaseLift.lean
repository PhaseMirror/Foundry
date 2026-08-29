import Init
import SpiralCore.Core

/-! # Orthogonal Phase-Lift and Spin-to-Helicity (Discrete Representation)

Formalizes the 90-degree rotation surrogate and spin-to-helicity control proxy
as discrete operations (Section 5.4, 5.5).

Continuous trigonometric computation is delegated to Rust + Kani.
-/

namespace SpiralCore.PhaseLift

/-- Apply a 90-degree rotation to a discrete coordinate pair.
    Uses integer arithmetic: (x, y) -> (-y, x). -/
def rotate90 (x y : Int) : Int × Int :=
  (-y, x)

/-- A DIM-dimensional state vector as a list of Ints. -/
def StateVector := List Int

/-- Apply pairwise 90-degree rotation to a state vector.
    For odd DIM, the final unpaired coordinate is preserved. -/
def orthogonalPhaseLift (v : StateVector) : StateVector :=
  v.foldl (fun acc x =>
    match acc with
    | [] => [x]
    | y :: ys => (-y) :: x :: ys
  ) [] |>.reverse

/-- Spin-to-helicity control proxy (discrete finite difference). -/
def helicityProxy (rhoPrev rhoCurr : Int) (gammaDelta : Nat := 22) : Int :=
  (gammaDelta * (rhoCurr - rhoPrev)) / 100

/-- Discrete polarity inversion. -/
def polarityInversion (sigma : Bool) : Bool := !sigma

end SpiralCore.PhaseLift
