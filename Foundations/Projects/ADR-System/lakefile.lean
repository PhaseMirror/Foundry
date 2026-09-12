import Lake
open Lake DSL

package «adr-system» where

@[default_target]
lean_lib ADR where
  roots := #[`ADR.Attributes, `ADR.Core, `ADR.Formal, `ADR.Proofs, `ADR.Examples, `ADR.Export, `ADR.Test]

lean_exe adr_system where
  root := `Main

lean_exe test where
  root := `ADR.Test
