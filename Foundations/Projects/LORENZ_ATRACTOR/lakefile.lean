import Lake
open Lake DSL

package LorenzAttractorPkg

lean_lib LorenzAttractor

@[default_target]
lean_exe LorenzAttractorTest {
  root := `LorenzAttractor.Main
}
