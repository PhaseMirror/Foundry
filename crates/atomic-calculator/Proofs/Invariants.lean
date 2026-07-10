import ADR.Validation
import ADR.Examples

open ADR
open ADR.Validation

theorem UAC_Qudit_invariant : Invariant (Examples.UAC_Qudit) := by
  apply mkADR_invariant
  all_goals (first | simp [Examples.UAC_Qudit] | trivial)
  constructor

theorem UAC_HSEC_invariant : Invariant (Examples.UAC_HSEC) := by
  apply mkADR_invariant
  all_goals (first | simp [Examples.UAC_HSEC] | trivial)
  constructor
