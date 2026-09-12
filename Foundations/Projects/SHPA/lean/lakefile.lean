import Lake
open Lake DSL

package «shpa» where
  srcDir := "."

@[default_target]
lean_lib SHPA where
  roots := #[
    `SHPA.Types,
    `SHPA.BCS,
    `SHPA.TopologicalTree,
    `SHPA.H2P,
    `SHPA.GapAttestation,
    `SHPA
  ]

lean_exe «shpa_test» where
  root := `tests.SHPATest
