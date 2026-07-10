import F1Square.Tropical.IntersectionPositivity

namespace F1Square.Tropical.PIRTMBridge

open F1Square.Tropical.IntersectionPositivity

/--
  Experimental bridge. Prime-gated / contraction-controlled intersection 
  multiplicities in the tropical model. Provides a decidable laboratory for 
  PIRTM-style gating on intersection data. Does not construct or imply the 
  corresponding structure on `Spec ℤ ×_{𝔽₁} Spec ℤ`. Lift remains open.
-/

/-- A generic boolean gate on natural indices, representing e.g. prime-indexed gating. -/
def isGateActive (gate : ℕ → Bool) (p : ℕ) : Bool :=
  gate p

/-- 
  Gated tropical intersection multiplicity.
  Applies a sequence-indexed gate (e.g., prime gating) to the structural intersection.
-/
def gatedMult (gate : ℕ → Bool) (p : ℕ) (e1 e2 : WeightedRay) : ℕ :=
  if isGateActive gate p then stableIntersectionMult e1 e2 else 0

/-- Gated multiplicity preserves the fundamental characteristic-1 positivity. -/
theorem gatedMult_nonneg (gate : ℕ → Bool) (p : ℕ) (e1 e2 : WeightedRay) :
  gatedMult gate p e1 e2 ≥ 0 := by
  exact Nat.zero_le _

/-- When the gate is trivial (always active), we recover the original structural multiplicity. -/
theorem gatedMult_trivial_recovers (p : ℕ) (e1 e2 : WeightedRay) :
  gatedMult (fun _ => true) p e1 e2 = stableIntersectionMult e1 e2 := by
  rfl

/-- 
  Interface for a Contraction Operator on the tropical plane.
  Models the scaling of intersection weights under dynamical viability rules.
-/
structure ContractionOperator where
  scale : ℕ → ℕ
  is_contractive : ∀ n, scale n ≤ n

/-- Contraction-controlled intersection multiplicity. -/
def contractedMult (C : ContractionOperator) (e1 e2 : WeightedRay) : ℕ :=
  C.scale (stableIntersectionMult e1 e2)

/-- The contracted multiplicity never exceeds the structural multiplicity. -/
theorem contractedMult_le_stable (C : ContractionOperator) (e1 e2 : WeightedRay) :
  contractedMult C e1 e2 ≤ stableIntersectionMult e1 e2 := by
  exact C.is_contractive _

end F1Square.Tropical.PIRTMBridge
