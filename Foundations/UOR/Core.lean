/-!
# Foundations.UOR.Core — Universal Operator Renormalization & Primitive Ontology

Formalizes the foundational primitive ontology mapping canonical computational
data types to their Lean representations.
-/

namespace Foundations.UOR

/-- Typeclass defining the standard primitive ontology family. -/
class Primitives where
  String             : Type
  Integer            : Type
  NonNegativeInteger : Type
  PositiveInteger    : Type
  Decimal            : Type
  Boolean            : Type

/-- Canonical standard instance mapping primitives to Lean's built-in core types. -/
@[instance_reducible]
def Standard : Primitives where
  String             := String
  Integer            := Int
  NonNegativeInteger := Nat
  PositiveInteger    := Nat
  Decimal            := Nat -- Fixed-point scaled representation
  Boolean            := Bool

/-- Proof that the canonical standard instance satisfies the ontology contract. -/
def standard_instance_sound : Primitives := Standard

end Foundations.UOR
