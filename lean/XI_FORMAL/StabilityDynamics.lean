namespace XI_FORMAL

/-- Scale for discrete integer math: 10000 = 1.0 -/
def scale : Nat := 10000

/-- 
  The absolute difference distance metric over `Nat`.
  Used to replace the abstract `MetricSpace` axiom.
-/
def dist (x y : Nat) : Nat :=
  if x ≥ y then x - y else y - x

/-- 
  Discrete definition of a Banach contraction.
  Instead of `kappa < 1.0` in `Float`, we use `kappa < scale`.
-/
def is_contraction (f : Nat → Nat) (kappa : Nat) : Prop :=
  kappa < scale ∧ ∀ x y : Nat, dist (f x) (f y) * scale ≤ kappa * dist x y

/-- 
  The Singular Attractor Property.
  An operator T is a stable attractor if it is a contraction on the discrete space.
-/
def is_stable_attractor (T : Nat → Nat) : Prop :=
  ∃ kappa, is_contraction T kappa

end XI_FORMAL
