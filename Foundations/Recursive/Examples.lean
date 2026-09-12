import Foundations.Recursive.Core
import Foundations.Recursive.FixedPoint
import Foundations.Recursive.Induction
import Foundations.Recursive.Coinduction

/-!
# Foundations.Recursive.Examples — Verified Examples of Recursive Definitions

Provides verified examples of recursive definitions on lists, trees, and numbers.
All proofs are axiom-clean and verified with zero `sorry`.
-/

namespace Foundations.Recursive.Examples

open Foundations.Recursive.Core
open Foundations.Recursive.Core.PNat
open Foundations.Recursive.Core.PList
open Foundations.Recursive.Core.PTree
open Foundations.Recursive.FixedPoint

/-! ## Arithmetic Examples -/

/-- Factorial base case. -/
theorem fact_zero_eq : fact zero = succ zero := rfl

/-- Factorial step. -/
theorem fact_succ_eq (n : PNat) : fact (succ n) = mul (succ n) (fact n) := rfl

/-- Fibonacci base cases. -/
theorem fib_zero_eq : fib zero = zero := rfl

theorem fib_one_eq : fib (succ zero) = succ zero := rfl

/-! ## List Examples -/

/-- Reverse a list. -/
def reverse {α : Type} (xs : PList α) : PList α :=
  match xs with
  | nil => nil
  | cons x xs' => append (reverse xs') (cons x nil)

theorem reverse_nil {α : Type} : reverse (@nil α) = nil := rfl

theorem reverse_cons {α : Type} (x : α) (xs : PList α) :
    reverse (cons x xs) = append (reverse xs) (cons x nil) := rfl

/-! ## Tree Examples -/

/-- Inorder traversal of a binary tree. -/
def inorder {α : Type} (t : PTree α) : PList α :=
  match t with
  | leaf => nil
  | node x l r => append (inorder l) (cons x (inorder r))

theorem inorder_leaf {α : Type} : inorder (leaf : PTree α) = nil := rfl

theorem inorder_node {α : Type} (x : α) (l r : PTree α) :
    inorder (node x l r) = append (inorder l) (cons x (inorder r)) := rfl

/-- Mirror a binary tree. -/
def mirror {α : Type} (t : PTree α) : PTree α :=
  match t with
  | leaf => leaf
  | node x l r => node x (mirror r) (mirror l)

theorem mirror_leaf {α : Type} : mirror (leaf : PTree α) = leaf := rfl

theorem mirror_node {α : Type} (x : α) (l r : PTree α) :
    mirror (node x l r) = node x (mirror r) (mirror l) := rfl

theorem mirror_mirror {α : Type} (t : PTree α) : mirror (mirror t) = t := by
  induction t with
  | leaf => rfl
  | node x l r ih_l ih_r => simp [mirror, ih_l, ih_r]

end Foundations.Recursive.Examples
