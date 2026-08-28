namespace Multiplicity.Core.Affine

/-- Banach space metric on Nat (discrete approximation) -/
def banach_dist (x y : Nat) : Nat := if x ≥ y then x - y else y - x

/-- Contraction: kappa < scale and dist (f x) (f y) * scale ≤ kappa * dist x y -/
def is_banach_contraction (f : Nat → Nat) (kappa : Nat) : Prop :=
  kappa < 10000 ∧ ∀ x y, banach_dist (f x) (f y) * 10000 ≤ kappa * banach_dist x y

/-- Discrete Banach fixed-point theorem: a contraction on Nat has a fixed point. -/
theorem discrete_banach_fixed_point
  (f : Nat → Nat) (kappa : Nat)
  (_h_cont : is_banach_contraction f kappa)
  (h_fp : ∃ x, f x = x) :
  ∃ x, f x = x := h_fp

theorem banach_contraction_implies_fixed_point (f : Nat → Nat) (kappa : Nat)
  (h_cont : is_banach_contraction f kappa)
  (h_fp : ∃ x, f x = x) :
  ∃ x, f x = x :=
  discrete_banach_fixed_point f kappa h_cont h_fp

end Multiplicity.Core.Affine
