import Lake

open Lake DSL

require sedona_spine_core from "../../../lean"
package «the_guardian_adr» where

  buildType := .release
  moreLeancArgs := #["-fPIC"]

lean_lib «TheGuardianAdr» where

@[default_target]
lean_exe «the_guardian_adr» where
  root := `Main
