import Lake
open Lake DSL

package AlphaFunction

lean_lib AlphaFunction

@[default_target]
lean_exe AlphaFunctionTest {
  root := `AlphaFunction.Main
}
