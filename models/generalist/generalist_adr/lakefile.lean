import Lake

open Lake DSL

require sedona_spine_core from "../../../lean"
package «generalist_adr» where

  buildType := .release
  moreLeancArgs := #["-fPIC"]

lean_lib «GeneralistAdr» where

@[default_target]
lean_exe «generalist_adr» where
  root := `Main
