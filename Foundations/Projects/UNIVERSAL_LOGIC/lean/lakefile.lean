import Lake
open Lake DSL

package «universal_logic» where
  srcDir := "."

@[default_target]
lean_lib UniversalLogic where
  roots := #[
    `UniversalLogic.Types,
    `UniversalLogic.FTS,
    `UniversalLogic.TruthAlgebras,
    `UniversalLogic.CSP,
    `UniversalLogic.Fusion,
    `UniversalLogic
  ]

lean_exe «ul_test» where
  root := `tests.UniversalLogicTest
