import Lake
open Lake DSL

package «neuroplasticity» where
  srcDir := "."

@[default_target]
lean_lib NEUROPLASTICITY where
  roots := #[
    `NEUROPLASTICITY.Types,
    `NEUROPLASTICITY.PrimeIndexing,
    `NEUROPLASTICITY.Operator,
    `NEUROPLASTICITY.CSL,
    `NEUROPLASTICITY.EchoBraid,
    `NEUROPLASTICITY
  ]

lean_exe «neuroplasticity_test» where
  root := `tests.NeuroplasticityTest
