import Lake
open Lake DSL

package "ADR-Scaffold" {
  srcDir := "src"
  testDriver := "test"
}

lean_lib "ADR" {
  srcDir := "src"
}

lean_lib "Analytic" {
  srcDir := "src"
}
lean_exe test {
  root := `TestMain
  supportInterpreter := true
}
