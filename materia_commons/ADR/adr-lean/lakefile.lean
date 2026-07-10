import Lake
open Lake DSL

package adrLean where
  name := "adrLean"
  srcDir := "ADR"

require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "master"

lean_lib ADR where
  roots := #[``ADR]

@[default_target]
lean_exe export where
  root := `ADR.Export
  moreLinkArgs := #["-L", "src"]
