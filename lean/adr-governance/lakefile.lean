import Lake
open Lake DSL

package ADR {
  -- add package configuration options here
}

@[default_target]
lean_lib ADR {
  -- add library configuration options here
}

@[test_runner]
lean_exe adr_test {
  root := `ADR.Test
}
