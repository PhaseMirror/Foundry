import Core.Spec.PartialUC
import Core.Spec.UniversalClosure

/-!
# Completion Spec — Definitions + Property Signatures

Pure spec. No proofs. No sorry. No Mathlib.
Property signatures are verified by Kani harnesses.
-/

namespace Completion

variable {X : Type} (P : PartialUC X)

inductive Term (X : Type) : Type where
  | var : X → Term X
  | compose : Term X → Term X → Term X
  | closure : Term X → Term X

inductive LawfulRel : Term X → Term X → Prop where
  | comp_defined : ∀ x y z,
      P.compose_p x y = some z →
      LawfulRel (Term.compose (Term.var x) (Term.var y)) (Term.var z)
  | closure_defined : ∀ x y,
      P.closure_p x = some y →
      LawfulRel (Term.closure (Term.var x)) (Term.var y)
  | refl : ∀ t, LawfulRel t t
  | symm : ∀ t₁ t₂, LawfulRel t₁ t₂ → LawfulRel t₂ t₁
  | trans : ∀ t₁ t₂ t₃, LawfulRel t₁ t₂ → LawfulRel t₂ t₃ → LawfulRel t₁ t₃
  | comp_congr : ∀ t₁ t₂ t₃ t₄,
      LawfulRel t₁ t₂ → LawfulRel t₃ t₄ →
      LawfulRel (Term.compose t₁ t₃) (Term.compose t₂ t₄)
  | closure_congr : ∀ t₁ t₂,
      LawfulRel t₁ t₂ →
      LawfulRel (Term.closure t₁) (Term.closure t₂)

def lawful_setoid : Setoid (Term X) :=
  ⟨LawfulRel P, ⟨LawfulRel.refl, @LawfulRel.symm _ P, @LawfulRel.trans _ P⟩⟩

def Carrier : Type := Quotient (lawful_setoid P)

def var_embed (P : PartialUC X) : X → Carrier P :=
  fun x => Quotient.mk (lawful_setoid P) (Term.var x)

def compose_q : Carrier P → Carrier P → Carrier P :=
  Quotient.lift₂
    (fun t₁ t₂ => Quotient.mk (lawful_setoid P) (Term.compose t₁ t₂))
    (by
      intro t₁ t₂ t₁' t₂' h₁ h₂
      apply Quotient.sound
      exact @LawfulRel.comp_congr _ P t₁ t₁' t₂ t₂' h₁ h₂)

def closure_q : Carrier P → Carrier P :=
  Quotient.lift
    (fun t => Quotient.mk (lawful_setoid P) (Term.closure t))
    (by
      intro t₁ t₂ h
      apply Quotient.sound
      exact @LawfulRel.closure_congr _ P t₁ t₂ h)

def completion (P : PartialUC X) : UC (Carrier P) :=
  ⟨compose_q P, closure_q P⟩

def forget (V : UC Y) : PartialUC Y :=
  { compose_p := fun x y => some (V.compose x y)
    closure_p := fun x => some (V.closure x) }

end Completion
