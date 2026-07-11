import Lake
open Lake DSL

package «adr-governance» {
  -- add package configuration options here
}

lean_lib «ADR» {
  -- add library configuration options here
}

@[default_target]
lean_exe «adr_export» {
  root := `ADR.Export
}

lean_exe «adr_test» {
  root := `ADR.Test
}
