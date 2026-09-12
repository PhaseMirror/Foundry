import Lake
open Lake DSL

package EchoBraidPkg

lean_lib EchoBraid

@[default_target]
lean_exe EchoBraidTest {
  root := `EchoBraid.Main
}
