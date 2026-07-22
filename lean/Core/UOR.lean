/-
  title: "Core.UOR – Foundational Primitive Ontology"
  status: "Adopted"
  date: "2026-07-15"
-/

/- Core.UOR – the single source of truth for all primitive XSD types. -/
namespace Core.UOR

/-- Class describing the XSD primitive family. Concrete implementations choose
    concrete Lean types for each primitive. -/
class Primitives where
  String              : Type
  Integer             : Type
  NonNegativeInteger  : Type
  PositiveInteger     : Type
  Decimal             : Type
  Boolean             : Type

/-- Canonical instance mapping the primitives to Lean’s built‑in types. -/
@[reducible]
def Standard : Primitives where
  String              := String
  Integer             := Int
  NonNegativeInteger  := Nat
  PositiveInteger     := Nat
  Decimal             := Float
  Boolean             := Bool

/-- Proof that the canonical instance satisfies the class contract. -/
@[reducible]
def standard_instance_sound : Primitives := Standard

end Core.UOR
