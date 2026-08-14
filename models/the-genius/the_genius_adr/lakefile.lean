import Lake

open Lake DSL

require sedona_spine_core from "../../../lean"
package «the_genius_adr» where

  buildType := .release
  moreLeancArgs := #["-fPIC"]

lean_lib «TheGeniusAdr» where

@[default_target]
lean_exe «the_genius_adr» where
  root := `Main
