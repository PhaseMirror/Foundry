import Lake
open Lake DSL

package AZTFTC

lean_lib AZTFTC

@[default_target]
lean_exe AZTFTCTest {
  root := `AZTFTC.Main
}
