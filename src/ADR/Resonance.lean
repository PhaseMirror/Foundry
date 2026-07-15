import ADR.Core

/-!
# Resonance module

Defines resonance predicates and terms that can be attached to an ADR.
-/

namespace ADR

/-- Simple predicate over exponent lists. -/
inductive ResonancePredicate where
  | allZero   : ResonancePredicate   -- all exponents are zero
  | sumZero   : ResonancePredicate   -- sum of exponents is zero
  deriving Repr, DecidableEq

/-- A resonance term consists of a predicate and a signed integer factor. -/
structure ResonanceTerm where
  pred   : ResonancePredicate
  factor : Int
  deriving Repr

/-- Evaluate a resonance term on a list of integer exponents.
    Returns `true` iff the predicate holds for the list. -/
def evalResonance (rt : ResonanceTerm) (exps : List Int) : Bool :=
  match rt.pred with
  | ResonancePredicate.allZero => exps.all (· = 0)
  | ResonancePredicate.sumZero => (exps.foldl (· + ·) 0) = 0

/-- Applying a resonance term to a list of exponents multiplies each exponent by the factor.
    This models the multiplicity conservation property. -/
def applyResonance (rt : ResonanceTerm) (exps : List Int) : List Int :=
  exps.map (· * rt.factor)

/-- A resonance term can be attached to an ADR only if the ADR is Accepted.
    The predicate `attached_to_accepted` expresses this condition. -/
def attached_to_accepted (_ : ResonanceTerm) (a : ADR) : Prop :=
  a.status = ADRStatus.Accepted

@[simp] theorem attached_to_accepted_true (_ : ResonanceTerm) (a : ADR) (h : a.status = ADRStatus.Accepted) :
    attached_to_accepted rt a := by
  exact h

end ADR
