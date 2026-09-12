import Foundations.Recursive.Core

/-!
# Foundations.Recursive.WellFounded — Well-Founded Recursion and Relations

Formalizes accessibility and well-founded induction principles in pure Lean 4.
All proofs are axiom-clean and verified with zero `sorry`.
-/

namespace Foundations.Recursive.WellFounded

open Foundations.Recursive.Core
open Foundations.Recursive.Core.PNat

/-- Accessibility relation: `x` is accessible if all predecessors are accessible. -/
inductive PAcc {α : Type} (r : α → α → Prop) : α → Prop where
  | intro (x : α) (h : ∀ y, r y x → PAcc r y) : PAcc r x

/-- A relation `r` is well-founded if every element is accessible. -/
def PWellFounded {α : Type} (r : α → α → Prop) : Prop :=
  ∀ x, PAcc r x

/-- Induction principle for accessible elements. -/
theorem acc_ind {α : Type} {r : α → α → Prop} {P : α → Prop}
    (h_step : ∀ x, (∀ y, r y x → P y) → P x) {x : α} (h_acc : PAcc r x) : P x := by
  induction h_acc with
  | intro x' _h ih => exact h_step x' ih

/-- Induction principle for well-founded relations. -/
theorem well_founded_ind {α : Type} {r : α → α → Prop} (h_wf : PWellFounded r) (P : α → Prop)
    (h_step : ∀ x, (∀ y, r y x → P y) → P x) (x : α) : P x := by
  exact acc_ind h_step (h_wf x)

/-- Primitive recursion on PNat. -/
def prim_rec {m : PNat → Type} (z : m zero) (s : ∀ n, m n → m (succ n)) (n : PNat) : m n :=
  match n with
  | zero => z
  | succ p => s p (prim_rec z s p)

theorem prim_rec_zero {m : PNat → Type} (z : m zero) (s : ∀ n, m n → m (succ n)) :
    prim_rec z s zero = z := rfl

theorem prim_rec_succ {m : PNat → Type} (z : m zero) (s : ∀ n, m n → m (succ n)) (p : PNat) :
    prim_rec z s (succ p) = s p (prim_rec z s p) := rfl

end Foundations.Recursive.WellFounded
