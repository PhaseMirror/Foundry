/-!
# Foundations.DigitalTwin.Core — Digital Twin Enforcement Multiplicity & Precedent Invariants

Formalizes prime label multiplicity mappings for digital twins, contractive legitimacy predicates,
and non-contamination invariants prohibiting bad precedent.
-/

namespace Foundations.DigitalTwin

/-- Conceptual prime labels for Digital Twin Multiplicity. -/
inductive PrimeLabel where
  | P_R     -- ruleset
  | P_C     -- context
  | P_S     -- strictness
  | P_B     -- boundary
  | P_V     -- visibility
  | P_T     -- triggers/ordering
  | P_M     -- twin-valid
  | P_PBD   -- bad precedent
  deriving DecidableEq, Repr

/-- EnforcementMultiplicity maps each conceptual prime label to an exponent count. -/
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

/-- Contractive legitimacy predicate: governed if all required axes are present and no bad precedent exists. -/
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
  dsimp [is_governed]
  simp [h]

end Foundations.DigitalTwin
