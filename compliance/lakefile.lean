import Lake
open Lake DSL

package Policy

@[default_target]
lean_lib Policy where
  roots := #[`Policy]

-- ADR formal governance test harness for the Policy package.
-- `lake test` builds and runs this executable, which exercises the
-- policy ADR registry invariants, lifecycle transitions, consequence
-- entailment, negative failure cases, and export determinism.
@[test_driver]
lean_exe policyAdrTest where root := `Policy.ADR.Test