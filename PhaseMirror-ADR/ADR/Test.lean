/-!
# Test Harness
Runnable with `lake test`. Validates instances against proofs.
-/
import ADR.Examples
import ADR.Proofs

open ADR
open ADR.Proofs
open ADR.Examples

-- Positive Proof: adr1 is not self-superseding
theorem adr1_valid : NotSelfSuperseding adr1 := by
  apply check_not_self_superseding
  rfl

-- Positive Proof: consequence entailment for adr1
theorem adr1_entails : LogicalEntailment adr1 := ⟨by
  intro h
  simp [adr1]
⟩

-- Positive Proof: adr4 is not self-superseding
theorem adr4_valid : NotSelfSuperseding adr4 := by
  apply check_not_self_superseding
  rfl

-- Example of a failure case caught by type system:
-- Uncommenting the below will fail compilation because `adr2` supersedes 1, not itself.
/-
theorem adr2_fails_self_supersede : NotSelfSuperseding adr2 := by
  apply check_not_self_superseding
  -- Fails here because adr2.supersedes is not none.
-/

def main : IO Unit := do
  IO.println "All proofs verified successfully."
