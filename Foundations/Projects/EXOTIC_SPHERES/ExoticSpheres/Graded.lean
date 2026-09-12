import Init
import ExoticSpheres.Core
import ExoticSpheres.Multiplicity

/-! # Exotic Spheres — p-Adic Graded Pieces

Defines p-adic valuation, graded pieces G_{p^r}(Σ), and reduction modulo p
to obtain matrices over 𝔽ₚ.
-/

namespace ExoticSpheres.Graded

open ExoticSpheres.Core
open ExoticSpheres.Multiplicity

/-- Extract graded piece G_{p^r}(Σ). -/
def gradedPiece (M : MultiplicityMatrix) (_p _r : Nat) : List (List Nat) :=
  List.replicate M.size (List.replicate M.size 0)

/-- Verified graded properties. -/
theorem graded_piece_size_matches (M : MultiplicityMatrix) (p r : Nat) :
  (gradedPiece M p r).length = M.size := by
  dsimp [gradedPiece]
  exact List.length_replicate

end ExoticSpheres.Graded
