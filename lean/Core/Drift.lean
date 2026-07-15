-- lean/Core/Drift.lean
-- Production-grade formalisation of drift for square matrices.
import Core.matrix


open Multiplicity.Core

namespace Multiplicity.Core

def natAbsDiff (a b : Nat) : Nat :=
  if a ≤ b then b - a else a - b

@[simp] lemma natAbsDiff_eq_zero_iff {a b : Nat} : natAbsDiff a b = 0 ↔ a = b := by
  unfold natAbsDiff
  split_ifs with h
  · have : b - a = 0 := Nat.sub_eq_zero_of_le h
    simp [this]
  · have : a - b = 0 := Nat.sub_eq_zero_of_le (le_of_not_ge h)
    simp [this]

def drift {n : Nat} (A B : Matrix n) : Nat :=
  (Finset.univ.sup fun i => Finset.univ.sup fun j => natAbsDiff (A i j) (B i j))

@[simp] theorem drift_eq_zero_iff {n : Nat} {A B : Matrix n} : drift A B = 0 ↔ A = B := by
  constructor
  · intro h
    funext i j
    have hle : natAbsDiff (A i j) (B i j) ≤ drift A B := by
      have : (Finset.univ.sup fun i' => Finset.univ.sup fun j' => natAbsDiff (A i' j') (B i' j')) ≥
            natAbsDiff (A i j) (B i j) := by
        apply Finset.le_sup (Finset.mem_univ i)
        apply Finset.le_sup (Finset.mem_univ j)
      simpa [drift] using this
    have : natAbsDiff (A i j) (B i j) = 0 := by
      have : natAbsDiff (A i j) (B i j) ≤ 0 := by simpa [h] using hle
      exact Nat.le_antisymm this (Nat.zero_le _)
    exact (natAbsDiff_eq_zero_iff.mp this)
  · intro h
    subst h
    simp [drift]

@[simp] theorem drift_triangle {n : Nat} (A B C : Matrix n) : drift A C ≤ drift A B + drift B C := by
  dsimp [drift]
  apply Finset.sup_le_iff.mpr
  intro i _
  apply Finset.sup_le_iff.mpr
  intro j _
  have htri : natAbsDiff (A i j) (C i j) ≤
                natAbsDiff (A i j) (B i j) + natAbsDiff (B i j) (C i j) := by
    unfold natAbsDiff
    by_cases hAB : A i j ≤ B i j
    · by_cases hBC : B i j ≤ C i j
      · have hAC : A i j ≤ C i j := le_trans hAB hBC
        have : C i j - A i j ≤ (B i j - A i j) + (C i j - B i j) := by
          rw [← Nat.sub_add_sub_cancel hAB hBC]
          exact Nat.le_add_right _ _
        simpa [if_pos hAC, if_pos hAB, if_pos hBC] using this
      · have hCB : C i j ≤ B i j := le_of_not_ge hBC
        have : B i j - A i j ≤ (B i j - A i j) + (B i j - C i j) := Nat.le_add_right _ _
        have : C i j - A i j ≤ (B i j - A i j) + (B i j - C i j) := by
          have : C i j ≤ B i j := hCB
          have : C i j - A i j ≤ B i j - A i j := Nat.sub_le_sub_right this _
          exact Nat.le_trans this (Nat.le_of_eq rfl)
        simpa [if_pos hAB, if_neg hCB] using this
    · have hBA : B i j < A i j := Nat.lt_of_not_ge hAB
      by_cases hBC : B i j ≤ C i j
      · have hAC : C i j ≤ A i j := le_trans (le_of_lt hBA) hBC
        have : A i j - C i j ≤ (A i j - B i j) + (C i j - B i j) := by
          have : A i j - C i j = (A i j - B i j) + (B i j - C i j) := by
            have : B i j ≤ C i j := hBC
            calc
              A i j - C i j
                  = (A i j - B i j) + (B i j - C i j) := by
                    rw [Nat.sub_sub, Nat.sub_eq_iff_eq_add (le_of_lt hBA), Nat.add_comm]
          simpa [this] using Nat.le_add_right _ _
        simpa [if_neg hBA, if_pos hBC, if_pos hAC] using this
      · have hCB : C i j < B i j := Nat.lt_of_not_ge hBC
        have hAC : C i j ≤ A i j := le_trans (le_of_lt hCB) (le_of_lt hBA)
        have : A i j - C i j ≤ (A i j - B i j) + (B i j - C i j) := by
          have : A i j - C i j = (A i j - B i j) + (B i j - C i j) := by
            have : C i j ≤ B i j := le_of_lt hCB
            calc
              A i j - C i j
                  = (A i j - B i j) + (B i j - C i j) := by
                    rw [Nat.sub_sub, Nat.sub_eq_iff_eq_add (le_of_lt hBA), Nat.add_comm]
          simpa [this] using Nat.le_add_right _ _
        simpa [if_neg hBA, if_neg hCB, if_pos hAC] using this
  exact Nat.le_trans htri (Nat.le_add_right _ _)



end Multiplicity.Core
