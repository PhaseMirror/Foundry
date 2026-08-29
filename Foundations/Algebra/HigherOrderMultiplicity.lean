import Foundations.Core.MultiplicityCore

/-!
# Higher-Order Multiplicity

This module formalizes multiplicities of multiplicity — the recursive,
self-referential structure where a multiplicity value itself carries
multiplicity information.
-/

namespace Foundations.Algebra.HigherOrder

open Foundations.Core.MultiplicityCore

inductive HigherOrderMultiplicity (Idx : Type) [PrimeLabel Idx] : Nat → Type
| zero : HigherOrderMultiplicity Idx 0
| firstOrder (m : MultiplicityTerm Idx) : HigherOrderMultiplicity Idx 1
| higherOrder (d : Nat) (inner : HigherOrderMultiplicity Idx d) (outer : MultiplicityTerm Idx) :
    HigherOrderMultiplicity Idx (d + 1)

namespace HigherOrderMultiplicity

def depth {d : Nat} {Idx : Type} [PrimeLabel Idx] (_h : HigherOrderMultiplicity Idx d) : Nat := d

def totalWeight {d : Nat} {Idx : Type} [PrimeLabel Idx] (h : HigherOrderMultiplicity Idx d) : Nat :=
  match h with
  | .zero => 0
  | .firstOrder t => term_value t
  | .higherOrder _ inner outer => totalWeight inner + term_value outer

def nestingDepth {d : Nat} {Idx : Type} [PrimeLabel Idx] (h : HigherOrderMultiplicity Idx d) : Nat :=
  match h with
  | .zero => 0
  | .firstOrder _ => 1
  | .higherOrder _ inner _ => 1 + nestingDepth inner

def contractionCoefficient {d : Nat} {Idx : Type} [PrimeLabel Idx]
    (lam : Float) (h : HigherOrderMultiplicity Idx d) : Float :=
  lam ^ (Float.ofNat h.nestingDepth)

def isContractive {d : Nat} {Idx : Type} [PrimeLabel Idx]
    (lam : Float) (h : HigherOrderMultiplicity Idx d) : Prop :=
  contractionCoefficient lam h < 1.0

end HigherOrderMultiplicity

def recursiveDepth {Idx : Type} [PrimeLabel Idx] :
    MultiplicityTerm Idx → Nat
  | MultiplicityTerm.base _ => 0
  | MultiplicityTerm.add t₁ t₂ => max (recursiveDepth t₁) (recursiveDepth t₂)

def atDepth {Idx : Type} [PrimeLabel Idx] (d : Nat) (t : MultiplicityTerm Idx) : Prop :=
  recursiveDepth t = d

theorem recursiveDepth_add {Idx : Type} [PrimeLabel Idx]
    (t₁ t₂ : MultiplicityTerm Idx) :
    recursiveDepth (MultiplicityTerm.add t₁ t₂) = max (recursiveDepth t₁) (recursiveDepth t₂) :=
  rfl

theorem recursiveDepth_base {Idx : Type} [PrimeLabel Idx]
    (i : Interaction Idx) :
    recursiveDepth (MultiplicityTerm.base i) = 0 :=
  rfl

end Foundations.Algebra.HigherOrder
