import Lake

open Lake DSL

require sedona_spine_core from "../../../lean"
package «ataraxia_adr» where

  buildType := .release
  moreLeancArgs := #["-fPIC"]

lean_lib «AtaraxiaAdr» where

@[default_target]
lean_exe «ataraxia_adr» where
  root := `Main
