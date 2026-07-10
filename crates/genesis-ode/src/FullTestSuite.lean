/-!
  FullTestSuite.lean
  Combined executable that runs both the three‑layer governance suite and the Kantian test suite.
  No external dependencies, no `sorry`s.
-/

import FullGovernanceTestDriver
import KantianTestSuite

/-- Run the two existing main drivers sequentially. -/
def main : IO Unit := do
  IO.println "=== Running Full Governance Tests ==="
  FullGovernanceTestDriver.main
  IO.println "=== Finished Full Governance Tests ===\n"
  IO.println "=== Running Kantian Test Suite ==="
  KantianTestSuite.main
  IO.println "=== Finished Kantian Test Suite ==="
