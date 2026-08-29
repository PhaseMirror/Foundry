import Lake
open Lake DSL

package «mqem» where
  srcDir := "."

@[default_target]
lean_lib MQEM where
  roots := #[
    `MQEM.Types,
    `MQEM.Dynamics,
    `MQEM.Observation,
    `MQEM.Weighting,
    `MQEM.Laplacian,
    `MQEM.Boundedness,
    `MQEM.Perturbation,
    `MQEM.Conservation,
    `MQEM
  ]

lean_exe «mqem_test» where
  root := `tests.MQEMTest
