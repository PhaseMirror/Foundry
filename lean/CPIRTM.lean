import MOC.Core
import PIRTM.Stability

namespace CPIRTM

/-- Fixed point scale: 10000 = 1.0 -/
def scale : Nat := 10000

/-- Absolute difference between two Nat values -/
def dist (x y : Nat) : Nat :=
  if x ≥ y then x - y else y - x

/-- Discrete Lipschitz Condition for Endomorphisms on MultiplicitySpace (Nat) -/
def LipschitzWith (κ : Nat) (f : Nat → Nat) : Prop :=
  ∀ x y : Nat, dist (f x) (f y) * scale ≤ κ * dist x y

/-- 
  Contractivity in CPIRTM maps exactly to PIRTM.is_contractive
  κ < 10000 ensures strict contraction in the scaled integer space.
--/
def is_contractive (f : Nat → Nat) (κ : Nat) : Prop :=
  PIRTM.is_contractive κ ∧ LipschitzWith κ f

end CPIRTM
