import Lake

open Lake DSL

require sedona_spine_core from "../../../lean"
package «echobraid_adr» where

  buildType := .release
  moreLeancArgs := #["-fPIC"]

lean_lib «EchobraidAdr» where

@[default_target]
lean_exe «echobraid_adr» where
  root := `Main
