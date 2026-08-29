import Foundations.Recursive.Core

/-!
# Foundations.Recursive.Induction — Induction Principles for Recursive Types

Formalizes induction principles for natural numbers, lists, trees, and
parity predicates. All proofs are axiom-clean and verified with zero `sorry`.
-/

namespace Foundations.Recursive.Induction

open Foundations.Recursive.Core
open Foundations.Recursive.Core.PNat
open Foundations.Recursive.Core.PList
open Foundations.Recursive.Core.PTree

/-! ## Natural Number Induction -/

/-- Principle of mathematical induction for PNat. -/
theorem pnat_ind {P : PNat → Prop} (h_zero : P zero) (h_step : ∀ n, P n → P (succ n)) (n : PNat) : P n := by
  induction n with
  | zero => exact h_zero
  | succ n ih => exact h_step n ih

/-! ## List Induction -/

/-- Principle of induction for PList. -/
theorem plist_ind {α : Type} {P : PList α → Prop} (h_nil : P nil) (h_cons : ∀ x xs, P xs → P (cons x xs)) (xs : PList α) : P xs := by
  induction xs with
  | nil => exact h_nil
  | cons x xs ih => exact h_cons x xs ih

/-! ## Tree Induction -/

/-- Principle of induction for binary trees. -/
theorem ptree_ind {α : Type} {P : PTree α → Prop} (h_leaf : P leaf) (h_node : ∀ x l r, P l → P r → P (node x l r)) (t : PTree α) : P t := by
  induction t with
  | leaf => exact h_leaf
  | node x l r ih_l ih_r => exact h_node x l r ih_l ih_r

/-! ## Parity Induction -/

/-- Boolean parity check. -/
def isEven (n : PNat) : Bool :=
  match n with
  | zero => true
  | succ p => ! (isEven p)

def Even (n : PNat) : Prop := isEven n = true
def Odd (n : PNat) : Prop := isEven n = false

/-- A number is either even or odd. -/
theorem even_or_odd (n : PNat) : Even n ∨ Odd n := by
  dsimp [Even, Odd]
  cases isEven n
  · right; rfl
  · left; rfl

/-- No number is both even and odd. -/
theorem not_even_and_odd (n : PNat) : ¬ (Even n ∧ Odd n) := by
  dsimp [Even, Odd]
  intro ⟨he, ho⟩
  rw [he] at ho
  contradiction

end Foundations.Recursive.Induction
