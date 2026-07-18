/-!
Multiplicity Core formalization.
Defines prime labeling, interaction product, and multiplicity space.
-/

namespace Core.MultiplicityCore

/-- Prime labeling: assign a unique prime to each entity index. -/
class PrimeLabel (Idx : Type) where
  prime : Idx → Nat
  prime_injective : Function.Injective prime

/-- Interaction product between two entities using their primes. -/
structure Interaction (Idx : Type) [PrimeLabel Idx] where
  src : Idx
  dst : Idx
  weight : ℕ := 1
  prod : Nat := (PrimeLabel.prime src) * (PrimeLabel.prime dst) * weight

/-- Multiplicity space: formal sums of interaction products. -/
inductive MultiplicityTerm (Idx : Type) [PrimeLabel Idx] : Type
| base (i : Interaction Idx) : MultiplicityTerm
| add (t₁ t₂ : MultiplicityTerm) : MultiplicityTerm

/-- The space as a multiset of terms. -/
abbrev MultiplicitySpace (Idx : Type) [PrimeLabel Idx] := List (MultiplicityTerm Idx)

/-- Convert a term to its numeric representation (product of primes). -/
def term_value {Idx : Type} [PrimeLabel Idx] : MultiplicityTerm Idx → Nat
| (MultiplicityTerm.base i) => i.prod
| (MultiplicityTerm.add t₁ t₂) => term_value t₁ + term_value t₂

end Core.MultiplicityCore
