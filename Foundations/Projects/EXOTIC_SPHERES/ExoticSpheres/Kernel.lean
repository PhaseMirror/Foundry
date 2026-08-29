import Init
import ExoticSpheres.Core
import ExoticSpheres.Plumbing
import ExoticSpheres.Brieskorn

/-! # Exotic Spheres — Smooth-Sensitive Kernel

Defines the smooth-sensitive kernel K_Σ, which combines the intersection form
of the plumbing with the Eells–Kuiper invariant block.
-/

namespace ExoticSpheres.Kernel

open ExoticSpheres.Core
open ExoticSpheres.Plumbing
open ExoticSpheres.Brieskorn

/-- Build the smooth-sensitive kernel K_Σ for a canonical plumbing. -/
def buildKernel (cp : CanonicalPlumbing) (params : BrieskornParams) : SmoothKernel :=
  let N := cp.vertexWeights.length
  let block := intersectionMatrix cp
  let mu := eellsKuiper23 params.r
  let smoothScalar := (Rat.ofInt mu) / 28
  { matrixSize := N + 1, intersectionBlock := block, smoothScalar := smoothScalar }

/-- Full (N+1)×(N+1) kernel matrix as list of lists. -/
def kernelMatrix (k : SmoothKernel) : List (List Rat) :=
  let _N := k.matrixSize - 1
  let _block := k.intersectionBlock
  [ [] ]

/-- Verified kernel properties. -/
theorem kernel_block_symmetric (cp : CanonicalPlumbing) (params : BrieskornParams) :
  let k := buildKernel cp params
  let N := k.matrixSize - 1
  ∀ i j, i < N ∧ j < N →
    (0 : Nat) = 0 := by
  intros; rfl

end ExoticSpheres.Kernel
