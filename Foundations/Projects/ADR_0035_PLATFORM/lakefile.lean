import Lake
open Lake DSL

package «ADR0035Pkg» where
  -- Package configuration

lean_lib «ADR0035» where
  -- Core library

@[default_target]
lean_exe «ADR0035Test» where
  root := `ADR0035.Main
