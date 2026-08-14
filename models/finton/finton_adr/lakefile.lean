import Lake

open Lake DSL

require sedona_spine_core from "../../../lean"
package «finton_adr» where

  -- Build as a static library for Rust FFI integration
  buildType := .release
  moreLeancArgs := #["-fPIC"]

lean_lib «FintonAdr» where
  -- Core module configurations

@[default_target]
lean_exe «finton_adr» where
  root := `Main
