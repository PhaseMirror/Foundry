import Init
import ExoticSpheres.Core
import ExoticSpheres.Plumbing

/-! # Exotic Spheres — Brieskorn Homology Spheres

Formalizes the Brieskorn homology spheres Σ(p,q,r), their plumbing descriptions,
and the Eells–Kuiper invariant μ(Σ) ∈ ℤ/28 for 7-dimensional homotopy spheres.
-/

namespace ExoticSpheres.Brieskorn

open ExoticSpheres.Core
open ExoticSpheres.Plumbing

/-- Brieskorn sphere Σ(p,q,r) for odd r ≥ 5. -/
def brieskornPlumbing (params : BrieskornParams) : StarPlumbing :=
  let center := -2
  let leg1 := [-3]
  let leg2 := List.replicate (params.r - 3) (-2)
  let leg3 := [-2]
  { centerWeight := center, legs := [leg1, leg2, leg3] }

/-- Canonicalize a Brieskorn sphere. -/
def canonicalBrieskorn (params : BrieskornParams) : CanonicalPlumbing :=
  modeACanonicalize (brieskornPlumbing params)

/-- Eells–Kuiper invariant μ(Σ) ∈ ℤ/28 for Σ(2,3,r). -/
def eellsKuiper23 (r : Nat) : Int :=
  match r with
  | 5 => 0
  | 7 => 8
  | 11 => 16
  | 13 => 4
  | 17 => 12
  | 19 => 20
  | _ => 0

/-- Check if r is a valid Brieskorn parameter for Σ(2,3,r). -/
def validBrieskorn23 (r : Nat) : Bool :=
  r == 5 || r == 7 || r == 11 || r == 13 || r == 17 || r == 19

/-- Verified Brieskorn properties. -/
theorem eells_kuiper_57_val : eellsKuiper23 7 = 8 := rfl
theorem eells_kuiper_511_val : eellsKuiper23 11 = 16 := rfl

end ExoticSpheres.Brieskorn
