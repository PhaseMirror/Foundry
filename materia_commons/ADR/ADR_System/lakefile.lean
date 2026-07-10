import Lake
open Lake DSL

package «ADR_System» where
  -- add package configuration options here

lean_lib «ADR» where
  -- add library configuration options here

@[default_target]
lean_exe «adr_export» where
  root := `ADR.Export

lean_exe «test_harness» where
  root := `Test.Harness

-- Optional dependency on mathlib for advanced tactics
require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @ "master"
