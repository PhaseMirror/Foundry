import LeanTest
import ADR.Examples
import ADR.Proofs

open ADR

/-- Positive test: immutability of an accepted ADR without supersession. -/
theorem test_immutability : True := by
  have h := immutability_of_accepted example1 example1 rfl (by decide) rfl
  trivial

/-- Property‑based test: no circular supersession in the example set. -/
theorem test_no_cycles : (∀ a ∈ exampleSet, ¬ supersedesRel a a) ∧
                       (∀ a b c, supersedesRel a b → supersedesRel b c → ¬ supersedesRel c a) :=
  supersession_acyclic exampleSet

/-- Export sanity check – runs without error. -/
def _root_.runExport : IO Unit := do
  IO.println "Running documentation export..."
  ADR.Export.exportAll (← IO.getStdout) exampleSet

#eval runExport
