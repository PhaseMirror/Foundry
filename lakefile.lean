import Lake
open Lake DSL

package "ADR-Scaffold" {
  srcDir := "src"
  testDriver := "test"
}

@[default_target]
lean_lib ADR {
  roots := #[
    `ADR.Core,
    `ADR.Proofs,
    `ADR.Examples,
    `ADR.Resonance,
    `ADR.PhaseMirror,
    `ADR.Export,
    `ADR.Dissonance,
    `ADR.LambdaProofBinding,
    `ADR.SocioAtomic,
    `ADR.Test,
    `Orf.Coherence,
    `Orf.Stratification,
    `Orf.Proofs, `MOC,  ]
}

lean_exe test {
  root := `TestMain
  supportInterpreter := true
}
