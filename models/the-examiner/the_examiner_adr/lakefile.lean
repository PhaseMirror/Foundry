import Lake

open Lake DSL

require sedona_spine_core from "../../../lean"
package «the_examiner_adr» where

  buildType := .release
  moreLeancArgs := #["-fPIC"]

lean_lib «TheExaminerAdr» where

@[default_target]
lean_exe «the_examiner_adr» where
  root := `Main
