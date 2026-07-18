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

-- Mathlib removed to comply with axiom-clean mandate
