import Lake
open Lake DSL

package «west_east» where
  srcDir := "."

@[default_target]
lean_lib WestEast where
  roots := #[
    `WestEast.Types,
    `WestEast.CSC,
    `WestEast.LogFloquet,
    `WestEast.ConsciousnessCoupling,
    `WestEast.Compositionality,
    `WestEast
  ]

lean_exe «we_test» where
  root := `tests.WestEastTest
