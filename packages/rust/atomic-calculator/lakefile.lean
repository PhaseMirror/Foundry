import Lake
open Lake DSL

package adr_scaffold where
  -- add package configuration options

lean_lib ADR where
  -- minimal

lean_lib Test where
  -- test library

lean_lib Proofs where
  -- proof library

@[default_target]
lean_exe test_runner where
  root := `Test.Harness
