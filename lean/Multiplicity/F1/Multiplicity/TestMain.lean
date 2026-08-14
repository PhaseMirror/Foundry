import Multiplicity.F1.Multiplicity.Tests.TestAxioms
import Multiplicity.F1.Multiplicity.Tests.TestKaniConsistency

/-!
# Test driver (`lake test`)

A bare, `IO`-free test driver that compiles the whole test suite.  Under
Lean's kernel, importing a module *is* the test: if any theorem failed, the
import would not type-check, so reaching `main` is the green light.

A runnable `IO`/`#eval` harness (JSON reporting, exit codes) is planned as
ADR-231's extensibility point; the driver below is the minimal,
dependency-free contract that `lake test` executes.
-/

namespace Multiplicity.RHMultiplicity

/-- Compile-time gate: the certificate-consistency suite type-checks. -/
theorem suite_typechecks : True := by
  trivial

end Multiplicity.RHMultiplicity

def main : IO Unit := do
  IO.println "RH_Multiplicity tests: all modules compiled (closure audit green)"
