import Lake
open Lake DSL

package ExoticSpheres

lean_lib ExoticSpheres

@[default_target]
lean_exe ExoticSpheresTest {
  root := `ExoticSpheres.Main
}
