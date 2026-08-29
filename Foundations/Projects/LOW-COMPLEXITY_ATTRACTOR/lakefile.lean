import Lake
open Lake DSL

package LowComplexityAttractor

lean_lib LowComplexityAttractor

@[default_target]
lean_exe LowComplexityAttractorTest {
  root := `LowComplexityAttractor.Main
}
