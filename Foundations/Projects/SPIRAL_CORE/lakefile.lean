import Lake
open Lake DSL

package SpiralCorePkg

lean_lib SpiralCore

@[default_target]
lean_exe SpiralCoreTest {
  root := `SpiralCore.Main
}

lean_exe ADRTest {
  root := `SpiralCore.ADR.Test
}

lean_exe ADRExport {
  root := `SpiralCore.ADR.Export
}
