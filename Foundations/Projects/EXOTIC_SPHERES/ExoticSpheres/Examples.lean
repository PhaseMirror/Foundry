import Init
import ExoticSpheres.Core
import ExoticSpheres.Plumbing
import ExoticSpheres.Brieskorn
import ExoticSpheres.Kernel
import ExoticSpheres.Multiplicity
import ExoticSpheres.Graded
import ExoticSpheres.Invariants
import ExoticSpheres.Knots
import ExoticSpheres.Proofs

/-! # Exotic Spheres — Examples

Concrete instantiations of Brieskorn spheres, plumbing graphs, multiplicity matrices,
and prime-tier invariants.
-/

namespace ExoticSpheres.Examples

open ExoticSpheres.Core
open ExoticSpheres.Plumbing
open ExoticSpheres.Brieskorn
open ExoticSpheres.Kernel
open ExoticSpheres.Multiplicity
open ExoticSpheres.Graded
open ExoticSpheres.Invariants
open ExoticSpheres.Knots

/-- Example: Σ(2,3,5). -/
def exampleBrieskorn5 : BrieskornParams := { p := 2, q := 3, r := 5 }
def examplePlumbing5 : StarPlumbing := brieskornPlumbing exampleBrieskorn5
def exampleCanonical5 : CanonicalPlumbing := canonicalBrieskorn exampleBrieskorn5
def exampleKernel5 : SmoothKernel := buildKernel exampleCanonical5 exampleBrieskorn5
def exampleM5 : MultiplicityMatrix := buildMultiplicityMatrix exampleCanonical5 exampleBrieskorn5

/-- Example: Σ(2,3,7). -/
def exampleBrieskorn7 : BrieskornParams := { p := 2, q := 3, r := 7 }
def exampleCanonical7 : CanonicalPlumbing := canonicalBrieskorn exampleBrieskorn7
def exampleKernel7 : SmoothKernel := buildKernel exampleCanonical7 exampleBrieskorn7
def exampleM7 : MultiplicityMatrix := buildMultiplicityMatrix exampleCanonical7 exampleBrieskorn7

/-- Example: prime-tier fingerprint for Σ(2,3,5). -/
def exampleFingerprint5 : List PrimeTierInvariant :=
  primeTierFingerprint exampleCanonical5 exampleBrieskorn5 3 2

/-- Example: graded piece for Σ(2,3,5) at (p=2, r=1). -/
def exampleGraded5_2_1 : List (List Nat) :=
  gradedPiece exampleM5 2 1

/-- Example: Jones polynomial at t=1 for trivial braid. -/
def exampleJones : Rat := jonesPolynomialAtOne Braid.id

end ExoticSpheres.Examples
