import Lake
open Lake DSL

package «AdrGovernance» where
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩,
    ⟨`linter.unusedVariables, false⟩
  ]

@[default_target]
lean_lib «ADR» where
  roots := #[`ADR.Core, `ADR.Proofs, `ADR.Examples, `ADR.Test, `ADR.Export]

lean_exe test_adr where
  root := `ADR.Test
