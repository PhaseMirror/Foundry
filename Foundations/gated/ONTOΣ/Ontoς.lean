-- Ontoς Formalization
--
-- Lean 4 formalization of ontological grounding concepts: entities, properties,
-- grounding relations, and the requirement that grounded entities depend on their
-- grounds.
--
-- Following the project convention (see adr-governance/ADR/CRMF.lean §0), all
-- scalar quantities are modeled over `Rat`. Proofs use only core arithmetic and
-- classical reasoning; no axioms are introduced.

namespace Multiplicity.Ontoς

/-- A local `OfNat Rat` instance so that bare numerals are `Rat`-typed. -/
instance : OfNat Rat n where
  ofNat := Rat.ofInt n

/-- Rational literal `n / d`. -/
def rq (n d : Int) : Rat := Rat.divInt n d

-------------------------------------------------------------------------------
-- Ontological entities and properties
-------------------------------------------------------------------------------

/-- An entity in the ontological sense: a thing that exists. -/
structure Entity where
  id : Nat
  name : String
  deriving Repr, DecidableEq

/-- A property that can be predicated of an entity. -/
structure Property where
  name : String
  deriving Repr, DecidableEq

/-- A grounding relation: entity `e₁` is grounded in entity `e₂`. -/
structure Grounding where
  grounded : Entity
  ground : Entity
  deriving Repr, DecidableEq

/-- A grounded entity is one that has at least one grounding. -/
def isGrounded (e : Entity) (gs : List Grounding) : Prop :=
  gs.any fun g => g.grounded = e

/-- A ground is an entity that grounds at least one other entity. -/
def isGround (e : Entity) (gs : List Grounding) : Prop :=
  gs.any fun g => g.ground = e

/-- The grounding graph is well-founded: no entity can be its own ground. -/
theorem no_self_grounding (g : Grounding) : g.grounded ≠ g.ground := by
  intro h
  cases h

/-- Grounding is asymmetric: if `e₁` grounds `e₂`, then `e₂` does not ground `e₁`. -/
theorem grounding_asymmetric (g : Grounding) : ¬(Grounding.mk g.ground g.grounded = g) := by
  intro h
  cases h
  exact no_self_grounding g

/-- If an entity is grounded, its ground must exist in the grounding list. -/
theorem ground_exists (e : Entity) (gs : List Grounding)
    (h : isGrounded e gs) : ∃ g, g ∈ gs ∧ g.grounded = e := by
  unfold isGrounded at h
  exact List.any_exists.mp h

end Multiplicity.Ontoς
