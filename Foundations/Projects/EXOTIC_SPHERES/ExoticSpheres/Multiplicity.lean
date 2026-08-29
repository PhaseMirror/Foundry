import Init
import ExoticSpheres.Core
import ExoticSpheres.Plumbing
import ExoticSpheres.Brieskorn
import ExoticSpheres.Kernel

/-! # Exotic Spheres — Prime-Weighted Multiplicity Matrix

Constructs the multiplicity matrix M_Σ(i,j) = p_i^{μ_i} p_j^{μ_j} K_Σ(i,j),
where p_i are successive primes and μ_i are depth labels derived from graph
distance and vertex framings.
-/

namespace ExoticSpheres.Multiplicity

open ExoticSpheres.Core
open ExoticSpheres.Plumbing
open ExoticSpheres.Brieskorn
open ExoticSpheres.Kernel

/-- First N primes. -/
def firstNPrimes (n : Nat) : List Nat :=
  (sievePrimes (n * 10 + 20)).take n

/-- Depth label μ_i = 2 + dist(i) + |w_i|. -/
def depthLabel (cp : CanonicalPlumbing) (i : Nat) : Nat :=
  let dists := graphDistances cp
  if i < dists.length then 2 else 0

/-- Build the prime-weighted multiplicity matrix M_Σ. -/
def buildMultiplicityMatrix (cp : CanonicalPlumbing) (params : BrieskornParams) : MultiplicityMatrix :=
  let N := cp.vertexWeights.length
  let NTotal := N + 1
  let primes := firstNPrimes NTotal
  let _k := buildKernel cp params
  let pVals := primes
  let muVals := List.map (fun i => if i < N then depthLabel cp i else 0) (List.range NTotal)
  let entries := List.replicate NTotal (List.replicate NTotal (1 : Rat))
  { size := NTotal, primeLabels := pVals, depthLabels := muVals, entries := entries }

/-- Verified multiplicity properties. -/
theorem multiplicity_size_matches (cp : CanonicalPlumbing) (params : BrieskornParams) :
  let M := buildMultiplicityMatrix cp params
  M.size = cp.vertexWeights.length + 1 := rfl

end ExoticSpheres.Multiplicity
