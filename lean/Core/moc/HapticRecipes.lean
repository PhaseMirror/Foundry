/-! HapticRecipes.lean - Multiplicity Operator Calculus for Rhythm and Haptics -/

namespace MOC

/-- 
  The Anti-Coincidence Gate: (1 - [d|t])
  Returns 0 if d divides t, and 1 otherwise.
  This is used to prevent ornamental events from colliding with structural beats.
-/
def anti_coincidence_gate (d t : Nat) : Nat :=
  if d ∣ t then 0 else 1

/--
  Theorem: The anti-coincidence gate evaluates to 0 on structural beats.
-/
theorem anti_coincidence_on_beat (d k : Nat) (hd : d > 0) :
  anti_coincidence_gate d (d * k) = 0 := by
  unfold anti_coincidence_gate
  have h_div : d ∣ d * k := by exact Nat.dvd_mul_right d k
  simp [h_div]

/--
  Accent Operator A_{p^r}
  Models the scaling applied to a given event class.
  Returns 1 if p^r divides t (a structural accent tick).
-/
def accent_operator (p r t : Nat) : Nat :=
  if (p ^ r) ∣ t then 1 else 0

end MOC
