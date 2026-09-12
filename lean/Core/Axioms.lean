/-!
  Axioms.lean – quarantine for temporary `sorry` axioms.
  This file is the **only** place where `sorry` is allowed.
  All other Lean files must compile without `sorry`.
-/

-- Example placeholder axiom (allowed to be a `sorry`).
axiom placeholder_axiom : True := by
  sorry
