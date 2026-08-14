import Lake

open Lake DSL

require sedona_spine_core from "../../../lean"
package «coding_commander_adr» where

  buildType := .release
  moreLeancArgs := #["-fPIC"]

lean_lib «CodingCommanderAdr» where

@[default_target]
lean_exe «coding_commander_adr» where
  root := `Main
