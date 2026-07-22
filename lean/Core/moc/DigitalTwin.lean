/-! DigitalTwin.lean - Digital Twin Enforcement Multiplicity -/

namespace DigitalTwin

/-- The conceptual prime labels for the Digital Twin Multiplicity -/
inductive PrimeLabel where
  | P_R     -- ruleset
  | P_C     -- context
  | P_S     -- strictness
  | P_B     -- boundary
  | P_V     -- visibility
  | P_T     -- triggers/ordering
  | P_M     -- twin-valid
  | P_PBD   -- bad precedent
  deriving DecidableEq

/-- 
  The EnforcementMultiplicity maps each conceptual prime label to an exponent (Nat).
-/
def EnforcementMultiplicity := PrimeLabel → Nat

def emptyMultiplicity : EnforcementMultiplicity := fun _ => 0

def inc (m : EnforcementMultiplicity) (p : PrimeLabel) (k : Nat := 1) : EnforcementMultiplicity :=
  fun x => if x = p then m x + k else m x

def get (m : EnforcementMultiplicity) (p : PrimeLabel) : Nat :=
  m p

def has_ruleset (m : EnforcementMultiplicity) : Bool := get m .P_R > 0
def has_context (m : EnforcementMultiplicity) : Bool := get m .P_C > 0
def has_strict (m : EnforcementMultiplicity) : Bool := get m .P_S > 0
def has_boundary (m : EnforcementMultiplicity) : Bool := get m .P_B > 0
def has_visibility (m : EnforcementMultiplicity) : Bool := get m .P_V > 0
def has_triggers (m : EnforcementMultiplicity) : Bool := get m .P_T > 0
def has_twin (m : EnforcementMultiplicity) : Bool := get m .P_M > 0
def has_bad_precedent (m : EnforcementMultiplicity) : Bool := get m .P_PBD > 0

/--
  Contractive legitimacy map F: multiplicity -> {governed, contaminated}.
  Governed if:
  - Twin has been compiled at least once (p_M >= 1).
  - Every required axis has occurred at least once: p_R, p_C, p_S, p_B, p_V.
  - No bad precedent has occurred: p_Pbad == 0.
-/
def is_governed (m : EnforcementMultiplicity) : Bool :=
  has_twin m &&
  has_ruleset m &&
  has_context m &&
  has_strict m &&
  has_boundary m &&
  has_visibility m &&
  not (has_bad_precedent m)

/-- Theorem: A multiplicity with a bad precedent is never governed. -/
theorem bad_precedent_not_governed (m : EnforcementMultiplicity) 
  (h : has_bad_precedent m = true) : is_governed m = false := by
  unfold is_governed
  simp [h]

end DigitalTwin
