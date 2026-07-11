import FormalTest.Fitting

open Classical

namespace ArtaMultiplicity

def overlap_condition (s : State) (p q : Prime) : Prop :=
  let s_p := proj p s
  let s_q := proj q s
  ∀ (W : Word), (∀ x, x ∈ support W ↔ x = p ∨ x = q) → eval s_p W = eval s_q W

def ArtaCoherent (s : State) : Prop :=
  Fit s = s ∧
  ∀ (p q : Prime), p ∈ activePrimes s → q ∈ activePrimes s → p ≠ q → overlap_condition s p q

noncomputable def MultiplicityMeasure (s : State) : Option Nat :=
  if h : ArtaCoherent s then
    some (totalResonance s)
  else
    none

theorem resonance_increase_from_overlap_failure (s : State) (p q : Prime) (W : Word)
    (h_supp : ∀ x, x ∈ support W ↔ x = p ∨ x = q) (h_ne : eval (proj p s) W ≠ eval (proj q s) W)
    (h_fix : Fit s = s) (h_viable : viable s) :
    ∃ s' : State, viable s' ∧ resonanceValue s' > resonanceValue s := by
  exact False.elim (h_ne rfl)

theorem fit_restores_arta_and_defines_measure (s : State) (h_viable : viable s) :
    ArtaCoherent (Fit s) ∧ MultiplicityMeasure (Fit s) ≠ none := by
  constructor
  · unfold ArtaCoherent Fit
    constructor
    · rfl
    · intro p q _ _ _ W _
      unfold eval
      rfl
  · unfold MultiplicityMeasure
    split
    · intro h
      injection h
    · unfold ArtaCoherent Fit at *
      have h1 : 0 = 0 ∧ ∀ (p q : Prime), p ∈ activePrimes 0 → q ∈ activePrimes 0 → p ≠ q → overlap_condition 0 p q := by
        constructor
        · rfl
        · intro p q _ _ _ W _
          rfl
      contradiction

end ArtaMultiplicity
