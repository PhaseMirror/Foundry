/-!
  EquivalenceProofs.lean
  Theorems proving that the three Kantian formulations agree on each test case.
  No external dependencies, no `sorry`s.
-/

import UniversalLawCheck
import HumanityCheck
import KingdomOfEndsCheck
import KantianTestSuite

/-- Helper lemma: all three checks return `PerfectDuty` for the lying case. -/
theorem lying_equivalence :
  (checkUniversalLaw lyingToMurderer = Verdict.PerfectDuty) ∧
  (checkHumanity lyingToMurderer = Verdict.PerfectDuty) ∧
  (checkKingdomOfEnds lyingToMurderer = Verdict.PerfectDuty) := by
  exact ⟨rfl, rfl, rfl⟩

/-- Helper lemma: all three checks return `Permitted` for the crying‑baby case. -/
theorem crying_baby_equivalence :
  (checkUniversalLaw cryingBabyToSaveGroup = Verdict.Permitted) ∧
  (checkHumanity cryingBabyToSaveGroup = Verdict.Permitted) ∧
  (checkKingdomOfEnds cryingBabyToSaveGroup = Verdict.Permitted) := by
  exact ⟨rfl, rfl, rfl⟩

/-- Helper lemma: all three checks return `Permitted` for the helping‑someone case. -/
theorem helping_equivalence :
  (checkUniversalLaw helpingSomeoneInNeed = Verdict.Permitted) ∧
  (checkHumanity helpingSomeoneInNeed = Verdict.Permitted) ∧
  (checkKingdomOfEnds helpingSomeoneInNeed = Verdict.Permitted) := by
  exact ⟨rfl, rfl, rfl⟩

/-- Helper lemma: all three checks return `Permitted` for the looped‑trolley case. -/
theorem looped_trolley_equivalence :
  (checkUniversalLaw loopedTrolley = Verdict.Permitted) ∧
  (checkHumanity loopedTrolley = Verdict.Permitted) ∧
  (checkKingdomOfEnds loopedTrolley = Verdict.Permitted) := by
  exact ⟨rfl, rfl, rfl⟩

/-- Helper lemma: all three checks return `Permitted` for the promise‑breaking case. -/
theorem promise_break_equivalence :
  (checkUniversalLaw promiseBreak = Verdict.Permitted) ∧
  (checkHumanity promiseBreak = Verdict.Permitted) ∧
  (checkKingdomOfEnds promiseBreak = Verdict.Permitted) := by
  exact ⟨rfl, rfl, rfl⟩

/-- Helper lemma: all three checks return `Permitted` for the double‑effect case. -/
theorem double_effect_equivalence :
  (checkUniversalLaw doubleEffect = Verdict.Permitted) ∧
  (checkHumanity doubleEffect = Verdict.Permitted) ∧
  (checkKingdomOfEnds doubleEffect = Verdict.Permitted) := by
  exact ⟨rfl, rfl, rfl⟩
