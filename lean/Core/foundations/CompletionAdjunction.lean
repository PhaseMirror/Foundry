import Core.foundations.UniversalClosure
import Core.foundations.Completion

namespace Core.foundations.CompletionAdjunction

open Core.foundations.UniversalClosure
open Core.foundations.Completion

/-- Step 1: Generate the Raw Syntax (The Free Magma with Closure) -/
inductive UCTerm (X : Type u)
  | var : X → UCTerm X
  | compose : UCTerm X → UCTerm X → UCTerm X
  | close : UCTerm X → UCTerm X

/-- Step 2: Impose the Partial Relations (The Congruence) -/
inductive UCCongruence {X : Type u} (P : PartialUC X) : UCTerm X → UCTerm X → Prop
  -- 1. Composition Lawfulness
  | comp_lawful (x y z : X) : 
      P.compose_p x y = some z → 
      UCCongruence P (UCTerm.compose (UCTerm.var x) (UCTerm.var y)) (UCTerm.var z)
  -- 2. Closure Lawfulness
  | close_lawful (x y : X) : 
      P.closure_p x = some y → 
      UCCongruence P (UCTerm.close (UCTerm.var x)) (UCTerm.var y)
  -- 3. Idempotence of Closure (Enforced in quotient)
  | close_idempotent (t : UCTerm X) :
      UCCongruence P (UCTerm.close (UCTerm.close t)) (UCTerm.close t)
  -- 4. Equivalence Relation Properties
  | refl (t : UCTerm X) : UCCongruence P t t
  | symm (t₁ t₂ : UCTerm X) : UCCongruence P t₁ t₂ → UCCongruence P t₂ t₁
  | trans (t₁ t₂ t₃ : UCTerm X) : 
      UCCongruence P t₁ t₂ → UCCongruence P t₂ t₃ → UCCongruence P t₁ t₃
  -- 5. Congruence Properties
  | comp_congr (t₁ t₁' t₂ t₂' : UCTerm X) :
      UCCongruence P t₁ t₁' → UCCongruence P t₂ t₂' → 
      UCCongruence P (UCTerm.compose t₁ t₂) (UCTerm.compose t₁' t₂')
  | close_congr (t t' : UCTerm X) :
      UCCongruence P t t' → UCCongruence P (UCTerm.close t) (UCTerm.close t')

/-- 
The Quotient Setoid definition.
-/
def UCTerm.setoid {X : Type u} (P : PartialUC X) : Setoid (UCTerm X) where
  r := UCCongruence P
  iseqv := {
    refl := UCCongruence.refl
    symm := UCCongruence.symm _ _
    trans := UCCongruence.trans _ _ _
  }

/-- 
The Free Completion Space X*
-/
def FreeCompletion (P : PartialUC X) : Type u :=
  Quotient (UCTerm.setoid P)

end Core.foundations.CompletionAdjunction
