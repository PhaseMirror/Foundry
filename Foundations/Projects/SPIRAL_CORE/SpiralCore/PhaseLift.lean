import Init
import SpiralCore.Core

namespace SpiralCore.PhaseLift

def rotate90 (p : Int × Int) : Int × Int :=
  (-p.2, p.1)

def sqNorm (p : Int × Int) : Int :=
  p.1 * p.1 + p.2 * p.2

def StateVector := List Int

def orthogonalPhaseLift (v : StateVector) : StateVector :=
  v.foldl (fun acc x =>
    match acc with
    | [] => [x]
    | y :: ys => (-y) :: x :: ys
  ) [] |>.reverse

def helicityProxy (rhoPrev rhoCurr : Int) (gammaDelta : Nat := 22) : Int :=
  (gammaDelta * (rhoCurr - rhoPrev)) / 100

def polarityInversion (sigma : Bool) : Bool := !sigma

theorem rotate90_four_times (p : Int × Int) :
    rotate90 (rotate90 (rotate90 (rotate90 p))) = p := by
  dsimp [rotate90]
  ext <;> simp

theorem rotate90_preserves_norm (p : Int × Int) :
    sqNorm (rotate90 p) = sqNorm p := by
  dsimp [rotate90, sqNorm]
  have h : -p.2 * -p.2 = p.2 * p.2 := by rw [Int.neg_mul_neg]
  rw [h]
  rw [Int.add_comm]

end SpiralCore.PhaseLift
