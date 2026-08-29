import Lake
open Lake DSL

package HCQA

lean_lib HCQA

@[default_target]
lean_exe HCQATest {
  root := `HCQA.Main
}
