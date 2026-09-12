import Foundations.Peano.Peano
import Foundations.Nat.Order
import Foundations.Nat.Arith

namespace Foundations.Finset

def FinsetMem (s : List Nat) (a : Nat) : Prop := a ∈ s

def empty : List Nat := []
def singleton (a : Nat) : List Nat := [a]
def insert (a : Nat) (s : List Nat) : List Nat := a :: s

theorem empty_not_mem (a : Nat) : ¬ FinsetMem empty a := by
  intro h
  exact List.not_mem_nil h

theorem singleton_mem_self (a : Nat) : FinsetMem (singleton a) a := by
  exact List.mem_cons_self

def card (s : List Nat) : Nat := s.length

theorem card_empty : card empty = 0 := List.length_nil

theorem card_singleton (a : Nat) : card (singleton a) = 1 := by
  exact List.length_cons

def subset (s t : List Nat) : Prop := ∀ a, a ∈ s → a ∈ t
instance : HasSubset (List Nat) := ⟨subset⟩

theorem subset_empty (s : List Nat) : s ⊆ empty → s = empty := by
  intro h
  cases s with
  | nil => rfl
  | cons a as =>
    have h1 := h a List.mem_cons_self
    exact absurd h1 List.not_mem_nil

end Foundations.Finset
