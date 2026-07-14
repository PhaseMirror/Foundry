import Lake
open Lake DSL

package "mtpi_commons" {
  -- add package configuration options here
}

-- We use local dependencies to avoid full mathlib cloning if possible, but the ADR specified mathlib.
-- Actually, the user's workspace might have mathlib. But let's follow the standard.
require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @ "master"

@[default_target]
lean_lib «MTPI» {
  srcDir := "src"
}

lean_lib «SemanticArithmetic» {
  srcDir := "src"
}

lean_exe «mtpi_test» {
  root := `tests.Test
  supportInterpreter := true
}

lean_exe «semantic_test» {
  root := `tests.TestSemantic
  supportInterpreter := true
}
