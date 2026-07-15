import Kernel

/-!
# UniversalLogic — structural rules of entailment

Formalizes the Universal Logic entailment primitives: the cut rule and weakening.
No `Mathlib`, no `sorry`.
-/
namespace UniversalLogic

open proofs.Kernel

/-- Local entailment `A ⊢ B` as the implication `A → B`. -/
def entails (A B : Prop) : Prop := A → B

/-- Cut rule: `A ⊢ B` and `B ⊢ C` imply `A ⊢ C`. -/
theorem cut {A B C : Prop} (hAB : entails A B) (hBC : entails B C) :
    entails A C := fun a => hBC (hAB a)

/-- Weakening: `A ⊢ B` implies `(A ∧ C) ⊢ B`. -/
theorem weakening {A B C : Prop} (h : entails A B) :
    entails (A ∧ C) B := fun hac => h hac.1

/-- Transitivity of entailment as a relation. -/
theorem entails_trans {A B C : Prop} (hAB : A → B) (hBC : B → C) (a : A) : C := hBC (hAB a)

end UniversalLogic
