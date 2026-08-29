import Init
import ExoticSpheres.Core
import ExoticSpheres.Plumbing
import ExoticSpheres.Brieskorn
import ExoticSpheres.Kernel
import ExoticSpheres.Multiplicity
import ExoticSpheres.Graded
import ExoticSpheres.Invariants
import ExoticSpheres.Knots
import ExoticSpheres.Examples
import ExoticSpheres.Proofs
import ExoticSpheres.Test
import ExoticSpheres.Export

/-! # Exotic Spheres v0.1.0

Lean 4 formalization of prime-indexed multiplicity invariants for Brieskorn spheres,
including plumbing canonicalization, smooth-sensitive kernels, p-adic graded pieces,
and prime-tier invariants.

Build: `lake build`
Test:  `lake exe ExoticSpheresTest`
-/

def main : IO Unit := ExoticSpheres.Test.main
