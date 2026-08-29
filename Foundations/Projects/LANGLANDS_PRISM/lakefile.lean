import Lake
open Lake DSL

package LanglandsPrismPkg

lean_lib LanglandsPrism

@[default_target]
lean_exe LanglandsPrismTest {
  root := `LanglandsPrism.Main
}
