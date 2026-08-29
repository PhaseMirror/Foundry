import Lake
open Lake DSL

package "math_formalization" {
  -- No extra settings needed
}

require std from git "https://github.com/leanprover/std4" @ "main"
-- Intentionally not pulling in mathlib per request

lean_lib MathFormalization {
  srcDir := "src"
}
