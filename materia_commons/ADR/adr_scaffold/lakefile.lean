import Lake
open Lake DSL

package adr_scaffold {
  name := "adr_scaffold"
  version := "0.1.0"
  srcDir := "src"
  docDir := "docs"
}

-- Mathlib removed to comply with axiom-clean mandate

lean_lib ADR {
  roots := #[`src/ADR]
}
