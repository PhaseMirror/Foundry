import FormalTest.Fitting
import FormalTest.ArtaMultiplicity

open ArtaMultiplicity
open Classical

noncomputable def rtaDist (s₁ s₂ : State) : Int :=
  let d₁ := artaDefect s₁
  let d₂ := artaDefect s₂
  let defectDiff := if d₁ > d₂ then d₁ - d₂ else d₂ - d₁
  if h₁ : ArtaCoherent s₁ then
    if h₂ : ArtaCoherent s₂ then
      let m₁ := (MultiplicityMeasure s₁).getD 0
      let m₂ := (MultiplicityMeasure s₂).getD 0
      let mDiff := if m₁ > m₂ then m₁ - m₂ else m₂ - m₁
      defectDiff + mDiff
    else defectDiff
  else if h₂ : ArtaCoherent s₂ then defectDiff
  else defectDiff

theorem fit_reduces_defect (s : State) (h_viable : viable s) (h_not_arta : ¬ ArtaCoherent s) :
    artaDefect (Fit s) < artaDefect s := by
  sorry

theorem fit_preserves_coherent_and_increases_multiplicity (s : State) (h_arta : ArtaCoherent s) :
    ArtaCoherent (Fit s) ∧ (MultiplicityMeasure (Fit s)).getD 0 ≥ (MultiplicityMeasure s).getD 0 := by
  sorry

def bindu : State := 0
def R_max : Nat := 0

theorem fit_contracts_rta (s : State) (h_viable : viable s) :
    rtaDist (Fit s) bindu ≤ rtaDist s bindu ∧
    (rtaDist (Fit s) bindu = rtaDist s bindu → s = bindu) := by
  sorry

theorem bindu_is_unique_center : ArtaCoherent bindu ∧ MultiplicityMeasure bindu = some R_max ∧
    (∀ s, ArtaCoherent s → (MultiplicityMeasure s).getD 0 ≤ R_max) := by
  sorry
