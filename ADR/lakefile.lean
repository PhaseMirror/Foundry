import Lake

open Lake DSL

package «ADR» where
  version := v!"1.0.0"




lean_lib «ADR» where
  srcDir := "."

@[default_target]
lean_exe «adr_export» where
  root := `Main

lean_exe «adr_test» where
  root := `Test
