import Lake
open Lake DSL

package PIRTMFormal where
  -- no extra packages

@[default_target]
lean_lib PIRTM where
  srcDir := "src"
  roots := #[`PIRTM]

lean_exe tests where
  root := `tests.AllTests
  supportInterpreter := true