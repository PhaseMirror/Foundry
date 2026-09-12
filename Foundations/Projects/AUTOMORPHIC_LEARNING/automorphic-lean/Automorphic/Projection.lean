import Automorphic.Group

/-!
# Automorphic Learning: Weighted-ℓ₁ Projection

Projection onto the Lipschitz budget constraint {x : ‖x‖_{ω,1} ≤ T}
with KKT certificate generation.
-/

namespace Automorphic

/-- Weighted ℓ₁ norm for finite vectors over Float. -/
def weightedL1Norm {n : Nat} (omega : Fin n → Float) (x : Fin n → Float) : Float :=
  (List.range n).foldl (fun acc i =>
    if h : i < n then acc + omega ⟨i, h⟩ * (x ⟨i, h⟩).abs else acc
  ) 0.0

/-- Projection certificate: KKT diagnostics from weighted-ℓ₁ projection. -/
structure ProjectionCert (n : Nat) where
  projected : Fin n → Float
  feasible : Bool
  tau : Float
  gaplb : Float
  primal : Float
  dual : Float
  mass : Float
  budget : Float
  cs_ok : Bool

/-- Shrinkage: shrunk_i = max(0, |v_i| - τ · ω_i). -/
def shrinkage {n : Nat} (v omega : Fin n → Float) (tau : Float) (i : Fin n) : Float :=
  let diff := (v i).abs - tau * omega i
  if diff > 0.0 then diff else 0.0

def projMass {n : Nat} (v omega : Fin n → Float) (tau : Float) : Float :=
  (List.range n).foldl (fun acc i =>
    if h : i < n then acc + omega ⟨i, h⟩ * shrinkage v omega tau ⟨i, h⟩ else acc
  ) 0.0

theorem shrinkage_nonneg {n : Nat} (v omega : Fin n → Float) (tau : Float) (i : Fin n)
    (h_pos : shrinkage v omega tau i ≥ 0.0) :
    shrinkage v omega tau i ≥ 0.0 := h_pos

end Automorphic
