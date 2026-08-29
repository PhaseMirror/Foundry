import Lake
open Lake DSL

package «toy_contractivity» where
  srcDir := "."

@[default_target]
lean_lib ToyContractivity where
  roots := #[
    `ToyContractivity,
    `PedersenLemmas
  ]

lean_exe «toy_test» where
  root := `tests.ToyContractivityTest
