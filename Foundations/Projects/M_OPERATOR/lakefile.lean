import Lake
open Lake DSL

package MOperatorPkg

lean_lib MOperator

@[default_target]
lean_exe MOperatorTest {
  root := `MOperator.Main
}
