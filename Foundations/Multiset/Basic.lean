import Foundations.Peano.Peano
import Foundations.Nat.Order
import Foundations.Nat.Arith

namespace Foundations.Multiset

/-!
# Multisets

A multiset is a list (we work modulo permutation).
-/

abbrev Multiset := List Nat

def card (s : Multiset) : Nat := s.length

def count (a : Nat) (s : Multiset) : Nat :=
  s.count a

def empty : Multiset := []

theorem card_empty : card empty = 0 := rfl

def sum (s : Multiset) : Nat := s.sum

theorem sum_empty : (empty : Multiset).sum = 0 := rfl
theorem sum_cons (a : Nat) (s : Multiset) : (a :: s).sum = a + s.sum := by
  simp [sum, List.sum]

theorem elem_nonneg (s : Multiset) (a : Nat) (_h : a ∈ s) : 0 ≤ a := Nat.zero_le a

end Foundations.Multiset
