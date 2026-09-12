import Lake
open Lake DSL

package «zetacell» where
  srcDir := "."

@[default_target]
lean_lib ZetaCell where
  roots := #[
    `ZetaCell.Types,
    `ZetaCell.Bridge,
    `ZetaCell.Constitutional,
    `ZetaCell.Contraction,
    `ZetaCell
  ]

lean_exe «zeta_test» where
  root := `tests.ZetaCellTest
