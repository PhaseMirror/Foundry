import Lake
open Lake DSL

package GodelianTruthPkg

lean_lib GodelianTruth

@[default_target]
lean_exe GodelianTruthTest {
  root := `GodelianTruth.Main
}
