import Lake
open Lake DSL

package adr_scaffold {
  name := "adr_scaffold"
  version := "0.1.0"
  srcDir := "src"
  docDir := "docs"
}

require mathlib from git "https://github.com/leanprover-community/mathlib4.git" @ "master"

lean_lib ADR {
  roots := #[`src/ADR]
}
