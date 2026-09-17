import Lake
open Lake DSL

package «PhaseMirror-ADR» where
  version := v!"0.1.0"

lean_lib «ADR» where
  roots := #[`ADR.Core, `ADR.Proofs, `ADR.Examples, `ADR.Export, `ADR.Test]

@[default_target]
lean_exe «adr_export» where
  root := `Main
