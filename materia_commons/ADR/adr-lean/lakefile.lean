import Lake
open Lake DSL

package adrLean where
  name := "adrLean"
  srcDir := "ADR"

-- Mathlib removed to comply with axiom-clean mandate

lean_lib ADR where
  roots := #[``ADR]

@[default_target]
lean_exe export where
  root := `ADR.Export
  moreLinkArgs := #["-L", "src"]
