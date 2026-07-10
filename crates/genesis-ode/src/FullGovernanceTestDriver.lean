/-!
  FullGovernanceTestDriver.lean
  Executable test suite for the three-layer governance surface.
  Imports the positive integration example and the negative test suite.
  No external dependencies, no `sorry`s.
-/

import BuilderAdmissionWithThreeLayer
import BuilderAdmissionNegativeTests
import KantianTestSuite

def main : IO Unit := do
  IO.println "=== Three-Layer Governance Test Suite ==="
  IO.println ""

  -- Positive case
  let positiveResult := exampleBuilderAdmission
  IO.println s!"Positive case (valid S-tier, resolved drift, internal BRA): {positiveResult}"
  IO.println "  Expected: true"

  IO.println ""

  -- Negative cases
  let neg1 := negative_insufficient_currency
  IO.println s!"Negative case 1 - Insufficient currency: {neg1}"
  IO.println "  Expected: true (admission blocked)"

  let neg2 := negative_unresolved_drift_note
  IO.println s!"Negative case 2 - Unresolved drift note (meta-review): {neg2}"
  IO.println "  Expected: true (admission blocked)"

  let neg3 := negative_bra_cost_violation
  IO.println s!"Negative case 3 - BRA cost violation (external overlay): {neg3}"
  IO.println "  Expected: true (admission blocked)"

  IO.println ""
  IO.println "=== Test Suite Complete ==="
KantianTestSuite.main

  -- Optional: assert all expected outcomes in CI mode
  if positiveResult && neg1 && neg2 && neg3 then
    IO.println "All tests passed as expected."
  else
    IO.println "WARNING: One or more tests did not match expected outcome."
