import Lake
open Lake DSL

package "PV" {
  version := "0.1.0"
  keywords := #["phase-validation", "formal-methods", "hilbert-transform", "complex-analysis"]
}

lean_lib "PV" {
  srcDir := "src"
  roots := #[`PV, `PV.Core, `PV.M1_Complex, `PV.M2_Hilbert]
}

@[default_target]
lean_exe "pv-verify" {
  root := `PV
  supportInterpreter := true
}
